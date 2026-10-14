import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/backup/data/sqlite_backup_snapshot.dart';
import 'package:planact/features/commitments/application/commitment_plan_use_case.dart';
import 'package:planact/features/commitments/data/drift_commitment_plan_repository.dart';
import 'package:planact/features/commitments/data/drift_commitment_repository.dart';
import 'package:planact/features/finance/application/finance_use_cases.dart';
import 'package:planact/features/finance/application/financial_expectation_use_cases.dart';
import 'package:planact/features/finance/data/drift_finance_repository.dart';
import 'package:planact/features/finance/data/drift_financial_expectation_repository.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/finance/domain/financial_expectation.dart';
import 'package:planact/features/reconciliation/application/contextual_reconciliation.dart';
import 'package:planact/features/reconciliation/application/reconciliation_use_cases.dart';
import 'package:planact/features/reconciliation/data/drift_reconciliation_repository.dart';
import 'package:planact/features/reconciliation/domain/relationship_review.dart';
import 'package:planact/features/reports/data/drift_reports_reader.dart';
import 'package:planact/features/reports/domain/personal_reports.dart';
import 'package:planact/features/today/application/attention_engine.dart';

void main() {
  late Directory directory;
  late File file;
  late AppDatabase database;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('reversal-settlement-');
    file = File('${directory.path}/state.sqlite');
    database = AppDatabase.forTesting(NativeDatabase(file));
  });
  tearDown(() async {
    await database.close();
    await directory.delete(recursive: true);
  });

  for (final type in [AccountEntryType.expense, AccountEntryType.income]) {
    for (final operation in ['void', 'correct', 'partial']) {
      test(
        '$operation ${type.name} restores unpaid remainder without changing match history, including reopen and backup',
        () async {
          final now = DateTime(2026, 10, 14);
          final direction = type == AccountEntryType.expense
              ? FinancialExpectationDirection.outgoing
              : FinancialExpectationDirection.incoming;
          final reason = type == AccountEntryType.expense
              ? AttentionReason.overdueUnpaidExpectation
              : AttentionReason.expectedIncomingMissing;
          final bank = FinancialAccount(
            id: StableId.generate(),
            name: 'synthetic bank',
            currency: 'IRR',
            type: FinancialAccountType.bank,
          );
          var finance = DriftFinanceRepository(database);
          await FinanceUseCases(finance).createAccount(bank);
          final plan = await CreateCommitmentPlan(
            commitments: DriftCommitmentRepository(database),
            plans: DriftCommitmentPlanRepository(database),
          )(title: 'synthetic payment', startAt: DateTime(2026, 10, 12, 18));
          final expectations = FinancialExpectationUseCases(
            DriftFinancialExpectationRepository(database),
          );
          await expectations.create(
            occurrenceId: plan.occurrences.single.id,
            direction: direction,
            amount: 100,
            currency: 'IRR',
            now: now,
          );

          Future<AccountEntry> pay(int amount) async {
            final entry = await FinanceUseCases(finance).record(
              account: bank,
              type: type,
              amount: Money(minorUnits: amount, currency: 'IRR'),
              occurredAt: DateTime(2026, 10, 12),
            );
            await ContextualReconciliation(
              finance: finance,
              commitments: DriftCommitmentRepository(database),
              plans: DriftCommitmentPlanRepository(database),
              reconciliation: ReconciliationUseCases(
                DriftReconciliationRepository(database),
              ),
            ).confirm(
              transactionId: entry.id,
              occurrenceId: plan.occurrences.single.id,
              minorUnits: amount,
            );
            return entry;
          }

          final original = await pay(operation == 'partial' ? 60 : 100);
          if (operation == 'partial') await pay(40);
          expect((await expectations.settled()).single.remainingMinorUnits, 0);
          final matchesBefore = allocationFingerprintFor(
            await DriftReconciliationRepository(database).list(),
          );
          AccountEntry? corrected;
          if (operation == 'correct') {
            corrected = await FinanceUseCases(finance).correctEntry(
              original: original,
              account: bank,
              type: type,
              amount: const Money(minorUnits: 60, currency: 'IRR'),
              occurredAt: now,
            );
          } else {
            await FinanceUseCases(finance)
                .voidEntry(original: original, account: bank, occurredAt: now);
          }

          Future<void> verify(int remaining) async {
            final repo = DriftFinancialExpectationRepository(database);
            final commands = FinancialExpectationUseCases(repo);
            expect(await commands.settled(), isEmpty);
            expect(
              (await commands.outstanding()).single.remainingMinorUnits,
              remaining,
            );
            final entriesBefore = await database
                .select(database.accountEntries)
                .get();
            final reader = DriftReportsReader(database);
            final snapshot = await reader.read(
              ReportFilter(from: DateTime(2026), to: DateTime(2026, 12, 31)),
              now: now,
            );
            final report = buildPersonalReport(
              snapshot,
              ReportFilter(from: DateTime(2026), to: DateTime(2026, 12, 31)),
              kind: PersonalReportKind.settlement,
              now: now,
            );
            expect(report.settlements.single.remaining, remaining);
            final center = const AttentionEngine().buildActionCenter(
              now: now,
              commitments: snapshot.commitments,
              plans: {plan.commitment.id: snapshot.occurrences},
              expectations: snapshot.expectations,
              matches: snapshot.matches,
              inboxSuggestions: const [],
              entries: snapshot.entries,
              accounts: snapshot.accounts,
            );
            final alert = center.attention.singleWhere(
              (a) => a.id.startsWith(
                reason == AttentionReason.overdueUnpaidExpectation
                    ? 'expectation:'
                    : 'incoming:',
              ),
            );
            expect(alert.attentionItem!.amountMinorUnits, remaining);
            expect(
              await database.select(database.accountEntries).get(),
              entriesBefore,
            );
          }

          final remaining = operation == 'partial' ? 60 : 100;
          await verify(remaining);
          expect(
            allocationFingerprintFor(
              await DriftReconciliationRepository(database).list(),
            ),
            matchesBefore,
          );
          await database.close();
          database = AppDatabase.forTesting(NativeDatabase(file));
          finance = DriftFinanceRepository(database);
          await verify(remaining);
          final bytes = await sqliteBackupSnapshot(
            database: database,
            target: File('${directory.path}/snapshot.sqlite'),
            redact: true,
          );
          await database.close();
          await file.writeAsBytes(bytes);
          database = AppDatabase.forTesting(NativeDatabase(file));
          finance = DriftFinanceRepository(database);
          await verify(remaining);
          expect(
            allocationFingerprintFor(
              await DriftReconciliationRepository(database).list(),
            ),
            matchesBefore,
          );
          if (corrected != null) {
            await ContextualReconciliation(
              finance: finance,
              commitments: DriftCommitmentRepository(database),
              plans: DriftCommitmentPlanRepository(database),
              reconciliation: ReconciliationUseCases(
                DriftReconciliationRepository(database),
              ),
            ).confirm(
              transactionId: corrected.id,
              occurrenceId: plan.occurrences.single.id,
              minorUnits: 60,
            );
            await verify(40);
          }
        },
      );
    }
  }
}
