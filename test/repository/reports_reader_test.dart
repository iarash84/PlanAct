import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/database/app_database.dart' as db;
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/classification/application/tag_repository.dart';
import 'package:planact/features/classification/data/drift_tag_repository.dart';
import 'package:planact/features/commitments/application/commitment_plan_use_case.dart';
import 'package:planact/features/commitments/data/drift_commitment_repository.dart';
import 'package:planact/features/commitments/data/drift_commitment_plan_repository.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/finance/data/drift_finance_repository.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/reports/data/drift_reports_reader.dart';
import 'package:planact/features/reports/domain/personal_reports.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';
import 'package:planact/features/sessions/data/drift_session_repositories.dart';
import 'package:planact/features/sessions/domain/entitlement.dart';

void main() {
  test('SQLite snapshot survives cold reopen, reads older cycles and does not mutate any table', () async {
    final directory = await Directory.systemTemp.createTemp('planact-reports-');
    final file = File('${directory.path}/reports.sqlite');
    var database = db.AppDatabase.forTesting(NativeDatabase(file));
    try {
      final commitments = DriftCommitmentRepository(database);
      final plan =
          await CreateCommitmentPlan(
            commitments: commitments,
            plans: DriftCommitmentPlanRepository(database),
            entitlements: DriftEntitlementPlanRepository(database),
          )(
            title: 'ورزش',
            startAt: DateTime(2026, 10, 2, 18),
            entitlementUnits: 10,
          );
      final entitlement = (await DriftEntitlementPlanRepository(
        database,
      ).listByCycle(plan.cycle.id)).single;
      await DriftEntitlementLedgerRepository(database).append(
        EntitlementLedgerEntry.create(
          planId: entitlement.id,
          type: EntitlementEntryType.grant,
          units: 10,
          occurredAt: DateTime(2026, 10, 1),
        ),
      );
      final secondCycle = StableId.generate();
      // A historical second cycle must not make reporting depend on the existing
      // single-plan Details API's getSingleOrNull assumption.
      await database
          .into(database.commitmentCycles)
          .insert(
            db.CommitmentCyclesCompanion.insert(
              id: secondCycle.value,
              commitmentId: plan.commitment.id.value,
              cycleType: 0,
              startDate: DateTime(2025, 1),
              consumedUnits: 0,
              completionRule: 4,
              status: 2,
            ),
          );
      await commitments.save(plan.commitment.archive());
      final finance = DriftFinanceRepository(database);
      final account = FinancialAccount(
        id: StableId.generate(),
        name: 'نقدی',
        currency: 'IRR',
        type: FinancialAccountType.cash,
      );
      await finance.saveAccount(account);
      final entry = AccountEntry(
        id: StableId.generate(),
        accountId: account.id,
        type: AccountEntryType.expense,
        amount: const Money(minorUnits: 1200, currency: 'IRR'),
        occurredAt: DateTime(2026, 10, 31, 23, 59),
      );
      await finance.saveEntry(entry);
      final tags = DriftTagRepository(database),
          tag = await tags.getOrCreate('ورزش');
      await tags.attach(
        recordId: plan.commitment.id.value,
        tag: tag,
        type: TaggableType.commitment,
      );
      await tags.attach(
        recordId: entry.id.value,
        tag: tag,
        type: TaggableType.accountEntry,
      );
      Future<Map<String, List<Map<String, dynamic>>>> tables() async => {
        for (final table in database.allTables)
          table.actualTableName:
              (await database
                      .customSelect('SELECT * FROM ${table.actualTableName}')
                      .get())
                  .map((r) => r.data)
                  .toList(),
      };
      final before = await tables();
      final filter = ReportFilter(
        from: DateTime(2026, 10, 1),
        to: DateTime(2026, 10, 31),
        tags: {tag.id},
      );
      var snapshot = await DriftReportsReader(database)
          .read(filter, now: DateTime(2026, 10, 13));
      expect(snapshot.cycles.length, 2);
      var report = buildPersonalReport(
        snapshot,
        filter,
        kind: PersonalReportKind.topic,
        now: DateTime(2026, 10, 13),
      );
      expect(report.occurrences.length, 1);
      expect(report.cashTotals['IRR']!.outgoing, 1200);
      expect(report.packages.single.balance.remaining, 10);
      expect(await tables(), before);
      await database.close();
      database = db.AppDatabase.forTesting(NativeDatabase(file));
      snapshot = await DriftReportsReader(database)
          .read(filter, now: DateTime(2026, 10, 13));
      report = buildPersonalReport(
        snapshot,
        filter,
        kind: PersonalReportKind.topic,
        now: DateTime(2026, 10, 13),
      );
      expect(snapshot.cycles.length, 2);
      expect(report.cashTotals['IRR']!.outgoing, 1200);
      expect(report.packages.single.balance.remaining, 10);
      expect(await tables(), before);
    } finally {
      await database.close();
      await directory.delete(recursive: true);
    }
  });
  test('future preview crosses 31-day chunks beyond horizon without writing intent', () async {
    final database = db.AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final plan =
        await CreateCommitmentPlan(
          commitments: DriftCommitmentRepository(database),
          plans: DriftCommitmentPlanRepository(database),
        )(
          title: 'ماهانه',
          kind: CommitmentKind.recurring,
          startAt: DateTime(2026, 1, 2, 18),
          frequency: RecurrenceFrequency.monthly,
        );
    final before = (await database.select(database.occurrences).get())
        .map((o) => o.toJson())
        .toList();
    final snapshot = await DriftReportsReader(database).read(
      ReportFilter(from: DateTime(2027, 1, 1), to: DateTime(2027, 2, 28)),
      now: DateTime(2026, 10, 13),
      includePreviews: true,
    );
    expect(snapshot.previews.length, 2);
    expect(
      snapshot.previews.every((p) => p.commitmentId == plan.commitment.id),
      isTrue,
    );
    expect(
      (await database.select(database.occurrences).get())
          .map((o) => o.toJson())
          .toList(),
      before,
    );
    expect(
      await database.select(database.financialExpectations).get(),
      isEmpty,
    );
    expect(await database.select(database.reminderInstances).get(), isEmpty);
  });
}
