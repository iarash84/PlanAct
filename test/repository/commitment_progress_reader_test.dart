import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/application/command_gate.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/commitments/data/drift_commitment_plan_repository.dart';
import 'package:planact/features/commitments/application/commitment_correction.dart';
import 'package:planact/features/commitments/data/drift_commitment_correction_repository.dart';
import 'package:planact/features/commitments/data/drift_commitment_progress_reader.dart';
import 'package:planact/features/commitments/data/drift_commitment_repository.dart';
import 'package:planact/features/commitments/domain/counted_commitment_progress.dart';
import 'package:planact/features/finance/data/drift_financial_expectation_repository.dart';
import 'package:planact/features/finance/data/drift_finance_repository.dart';
import 'package:planact/features/finance/application/financial_expectation_use_cases.dart';
import 'package:planact/features/finance/domain/financial_expectation.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/reconciliation/data/drift_reconciliation_repository.dart';
import 'package:planact/features/reconciliation/domain/reconciliation.dart';
import 'package:planact/features/scheduling/domain/occurrence.dart';

import '../fixtures/counted_commitment.dart';

void main() {
  test('confirmed count reduction keeps cancelled history outside the new progress target', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final now = DateTime.now();
    final plan = countedPlan(
      statuses: List.filled(4, OccurrenceStatus.scheduled),
    );
    await DriftCommitmentRepository(database).save(plan.commitment);
    await DriftCommitmentPlanRepository(database).save(plan);
    final corrections = DriftCommitmentCorrectionRepository(database);
    final preview = await corrections.preview(
      CommitmentCorrectionRequest(
        commitmentId: plan.commitment.id,
        reason: 'کاهش تعداد',
        scheduleCount: 3,
      ),
      now,
    );
    await corrections.confirm(preview, now);
    final result = (await DriftCommitmentProgressReader(database)
        .read(plan.commitment.id))!;
    expect(result.consistent, isTrue);
    expect(result.outcomes.total, 3);
    expect(result.outcomes.count(ProgressPart.remaining), 3);
    expect(result.excludedCancellations, 1);
    expect(
      (await DriftCommitmentPlanRepository(database)
              .findByCommitmentId(plan.commitment.id))!
          .occurrences,
      hasLength(4),
    );
  });
  test('cold reopen projects music and 50 payments without writes or materialization; reversals refresh', () async {
    final directory = await Directory.systemTemp.createTemp('progress-test-');
    final file = File('${directory.path}/progress.sqlite');
    var database = AppDatabase.forTesting(NativeDatabase(file));
    try {
      final music = countedPlan();
      final loan = countedPlan(
        target: 50,
        payments: true,
        statuses: List.filled(10, OccurrenceStatus.scheduled),
      );
      final commitments = DriftCommitmentRepository(database);
      final plans = DriftCommitmentPlanRepository(database);
      await commitments.save(music.commitment);
      await plans.save(music);
      await commitments.save(loan.commitment);
      await plans.save(loan);
      final finance = DriftFinanceRepository(database);
      final account = FinancialAccount(
        id: StableId.generate(),
        name: 'وام',
        currency: 'IRR',
        type: FinancialAccountType.bank,
      );
      await finance.saveAccount(account);
      final entries = <AccountEntry>[];
      for (final o in loan.occurrences) {
        await FinancialExpectationUseCases(
          DriftFinancialExpectationRepository(database),
        ).create(
          occurrenceId: o.id,
          direction: FinancialExpectationDirection.outgoing,
          amount: 1000,
          currency: 'IRR',
        );
        final entry = AccountEntry(
          id: StableId.generate(),
          accountId: account.id,
          type: AccountEntryType.expense,
          amount: const Money(minorUnits: 1000, currency: 'IRR'),
          occurredAt: DateTime.now(),
        );
        entries.add(entry);
        await finance.saveEntry(entry);
        final id = StableId.generate();
        await DriftReconciliationRepository(database).save(
          TransactionMatch(
            id: id,
            transactionId: entry.id,
            transactionAmount: entry.amount,
            createdAt: DateTime.now(),
            allocations: [
              MatchAllocation(
                id: StableId.generate(),
                matchId: id,
                occurrenceId: o.id,
                amount: entry.amount,
              ),
            ],
          ),
        );
      }
      await database.close();
      database = AppDatabase.forTesting(NativeDatabase(file));
      // Open and complete normal initialization before measuring read effects.
      await database.customSelect('SELECT 1').get();
      Future<int> changes() async =>
          (await database
                  .customSelect('SELECT total_changes() AS n')
                  .getSingle())
              .read<int>('n');
      final before = await changes();
      final reader = DriftCommitmentProgressReader(database);
      final musicProgress = (await reader.read(music.commitment.id))!;
      expect(musicProgress.outcomes.count(ProgressPart.completed), 2);
      expect(musicProgress.outcomes.count(ProgressPart.cancelled), 1);
      expect(musicProgress.outcomes.count(ProgressPart.remaining), 1);
      final loanProgress = (await reader.read(loan.commitment.id))!;
      expect(loanProgress.payments!.count(ProgressPart.completed), 10);
      expect(loanProgress.payments!.count(ProgressPart.remaining), 40);
      expect(loanProgress.payments!.percent(ProgressPart.completed), 20);
      expect(await changes(), before);
      expect(
        (await DriftCommitmentPlanRepository(database)
                .findByCommitmentId(loan.commitment.id))!
            .occurrences
            .length,
        10,
      );
      await DriftFinanceRepository(database).reverseEntry(
        expected: entries.first,
        accountId: account.id,
        occurredAt: DateTime.now(),
      );
      final refreshed = (await reader.read(loan.commitment.id))!;
      expect(refreshed.payments!.count(ProgressPart.completed), 9);
      expect(refreshed.payments!.count(ProgressPart.remaining), 41);
      final gate = CommandGate();
      CommandGate.bind(database, gate);
      await gate.retire();
      await expectLater(
        reader.read(loan.commitment.id),
        throwsA(isA<StaleApplicationCommand>()),
      );
    } finally {
      await database.close();
      await directory.delete(recursive: true);
    }
  });
}
