import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/database/app_database.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/commitments/application/commitment_plan_use_case.dart';
import 'package:planact/features/commitments/data/drift_commitment_plan_repository.dart';
import 'package:planact/features/commitments/data/drift_commitment_repository.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/finance/application/financial_expectation_use_cases.dart';
import 'package:planact/features/finance/data/drift_financial_expectation_repository.dart';
import 'package:planact/features/finance/domain/financial_expectation.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';

Future<CommitmentPlan> create(AppDatabase db) =>
    CreateCommitmentPlan(
      commitments: DriftCommitmentRepository(db),
      plans: DriftCommitmentPlanRepository(db),
      financialExpectations: FinancialExpectationUseCases(
        DriftFinancialExpectationRepository(db),
      ),
    )(
      title: 'اجاره',
      kind: CommitmentKind.recurring,
      startAt: DateTime(2000, 1, 31, 18),
      frequency: RecurrenceFrequency.monthly,
      reminderOffsets: const [Duration(minutes: 30), Duration(minutes: 60)],
      financialDirection: FinancialExpectationDirection.outgoing,
      financialAmount: 123456,
    );

Future<void> legacy(AppDatabase db) async {
  await db.customStatement('UPDATE financial_expectations SET currency = NULL');
  final row = await db.select(db.scheduleDefinitions).getSingle();
  final metadata = jsonDecode(row.recurrenceRule!) as Map<String, dynamic>;
  for (final key in [
    'formatVersion',
    'calendar',
    'monthOfYear',
    'generationReminderMinutes',
    'generationFinancialExpectation',
  ]) {
    metadata.remove(key);
  }
  await db.customStatement(
    'UPDATE schedule_definitions SET recurrence_rule = ?',
    [jsonEncode(metadata)],
  );
}

void main() {
  test('explicit empty reminders never infer from occurrence rules', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    try {
      await create(db);
      final row = await db.select(db.scheduleDefinitions).getSingle();
      final m = jsonDecode(row.recurrenceRule!) as Map<String, dynamic>;
      m['generationReminderMinutes'] = <int>[];
      await db.customStatement(
        'UPDATE schedule_definitions SET recurrence_rule = ?',
        [jsonEncode(m)],
      );
      final before = await db.select(db.reminderRules).get();
      await DriftCommitmentPlanRepository(db)
          .extendRecurringSchedules(LocalDate(2026, 1, 1));
      expect(await db.select(db.reminderRules).get(), before);
    } finally {
      await db.close();
    }
  });

  test(
    'manual inconsistent outlier is excluded without changing its history',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      try {
        await create(db);
        await legacy(db);
        final first = (await db.select(db.occurrences).get()).first;
        await db.customStatement(
          'UPDATE occurrences SET is_manual_override = 1 WHERE id = ?',
          [first.id],
        );
        await db.customStatement(
          'UPDATE reminder_rules SET offset_seconds = -120 WHERE occurrence_id = ?',
          [first.id],
        );
        await db.customStatement(
          'UPDATE financial_expectations SET minor_units = 1 WHERE occurrence_id = ?',
          [first.id],
        );
        final before = await db.select(db.financialExpectations).get();
        final inserted = await DriftCommitmentPlanRepository(db)
            .extendRecurringSchedules(LocalDate(2026, 1, 1));
        final after = await db.select(db.financialExpectations).get();
        expect(after.length, before.length + inserted);
        for (final item in before) {
          expect(after.singleWhere((r) => r.id == item.id), item);
        }
        final m = jsonDecode(
          (await db.select(db.scheduleDefinitions).getSingle()).recurrenceRule!,
        ) as Map<String, dynamic>;
        expect(m['generationReminderMinutes'], [30, 60]);
        expect((m['generationFinancialExpectation'] as Map)['amount'], 123456);
      } finally {
        await db.close();
      }
    },
  );

  test(
    'legacy financial account and currency copied but never a balance entry',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      try {
        await create(db);
        await legacy(db);
        final accountId = StableId.generate().value;
        await db.customStatement(
          "INSERT INTO financial_accounts (id, name, currency, type, status) VALUES (?, 'حساب', 'IRR', 0, 0)",
          [accountId],
        );
        await db.customStatement(
          "UPDATE financial_expectations SET currency = 'IRR', account_id = ?",
          [accountId],
        );
        final before = await db.select(db.financialExpectations).get();
        final inserted = await DriftCommitmentPlanRepository(db)
            .extendRecurringSchedules(LocalDate(2026, 1, 1));
        final after = await db.select(db.financialExpectations).get();
        expect(after.length, before.length + inserted);
        expect(
          after.every((r) => r.currency == 'IRR' && r.accountId == accountId),
          true,
        );
        expect(await db.select(db.accountEntries).get(), isEmpty);
      } finally {
        await db.close();
      }
    },
  );

  test('explicit financial template rolls without changing historical expectations', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    try {
      final plan = await create(db);
      final old = await db.select(db.financialExpectations).get();
      final repo = DriftCommitmentPlanRepository(db);
      final inserted = await repo.extendRecurringSchedules(
        LocalDate(2026, 1, 1),
      );
      expect(inserted, greaterThan(0));
      final all = await db.select(db.financialExpectations).get();
      expect(all.length, old.length + inserted);
      for (final row in old) {
        expect(all.singleWhere((r) => r.id == row.id), row);
      }
      expect(
        all.every((r) => r.minorUnits == 123456 && r.direction == 0),
        isTrue,
      );
      expect(
        (await repo.findByCommitmentId(plan.commitment.id))!
            .schedule
            .generationFinancialExpectation!
            .amount,
        123456,
      );
      expect(await repo.extendRecurringSchedules(LocalDate(2026, 1, 1)), 0);
      expect(await db.select(db.financialExpectations).get(), all);
    } finally {
      await db.close();
    }
  });

  test('consistent legacy templates persist and survive cold reopen', () async {
    final directory = await Directory.systemTemp.createTemp('templates-');
    final file = File('${directory.path}/live.sqlite');
    var db = AppDatabase.forTesting(NativeDatabase(file));
    try {
      final plan = await create(db);
      await legacy(db);
      final oldRules = await db.select(db.reminderRules).get();
      final oldExpectations = await db.select(db.financialExpectations).get();
      final inserted = await DriftCommitmentPlanRepository(db)
          .extendRecurringSchedules(LocalDate(2026, 1, 1));
      expect(inserted, greaterThan(0));
      final metadata = jsonDecode(
        (await db.select(db.scheduleDefinitions).getSingle()).recurrenceRule!,
      ) as Map<String, dynamic>;
      expect(metadata['generationReminderMinutes'], [30, 60]);
      expect(metadata['generationFinancialExpectation'], {
        'direction': 0,
        'amount': 123456,
        'currency': null,
        'accountId': null,
      });
      expect(metadata['legacyCalendarSemantics'], true);
      for (final rule in oldRules) {
        expect(
          (await db.select(db.reminderRules).get()).singleWhere(
            (r) => r.id == rule.id,
          ),
          rule,
        );
      }
      for (final expectation in oldExpectations) {
        expect(
          (await db.select(db.financialExpectations).get()).singleWhere(
            (r) => r.id == expectation.id,
          ),
          expectation,
        );
      }
      await db.close();
      db = AppDatabase.forTesting(NativeDatabase(file));
      final repo = DriftCommitmentPlanRepository(db);
      final restored = (await repo.findByCommitmentId(plan.commitment.id))!;
      expect(restored.schedule.recurrenceRule!.legacyCalendarSemantics, true);
      expect(restored.schedule.generationReminderOffsets, const [
        Duration(minutes: 30),
        Duration(minutes: 60),
      ]);
      expect(restored.schedule.generationFinancialExpectation!.amount, 123456);
      final before = await db.select(db.financialExpectations).get();
      final added = await repo.extendRecurringSchedules(LocalDate(2027, 1, 1));
      expect(added, greaterThan(0));
      expect(
        await db.select(db.financialExpectations).get(),
        hasLength(before.length + added),
      );
    } finally {
      await db.close();
      await directory.delete(recursive: true);
    }
  });

  for (final mutation in [
    'missing',
    'disabled',
    'absolute',
    'different',
    'seconds',
    'manual',
  ]) {
    test('legacy reminder inference rejects $mutation evidence', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      try {
        await create(db);
        await legacy(db);
        final first = (await db.select(db.occurrences).get()).first;
        switch (mutation) {
          case 'missing':
            await db.customStatement(
              'DELETE FROM reminder_rules WHERE occurrence_id = ?',
              [first.id],
            );
          case 'disabled':
            await db.customStatement(
              'UPDATE reminder_rules SET enabled = 0 WHERE occurrence_id = ?',
              [first.id],
            );
          case 'absolute':
            await db.customStatement(
              'UPDATE reminder_rules SET anchor = 1, absolute_at = 1000 WHERE occurrence_id = ?',
              [first.id],
            );
          case 'different':
            await db.customStatement(
              'UPDATE reminder_rules SET offset_seconds = offset_seconds - 60 WHERE occurrence_id = ?',
              [first.id],
            );
          case 'seconds':
            await db.customStatement(
              'UPDATE reminder_rules SET offset_seconds = offset_seconds - 1 WHERE occurrence_id = ?',
              [first.id],
            );
          case 'manual':
            await db.customStatement(
              'UPDATE occurrences SET is_manual_override = 1',
            );
        }
        final before = await db.select(db.reminderRules).get();
        await DriftCommitmentPlanRepository(db)
            .extendRecurringSchedules(LocalDate(2026, 1, 1));
        expect(await db.select(db.reminderRules).get(), before);
        final m = jsonDecode(
          (await db.select(db.scheduleDefinitions).getSingle()).recurrenceRule!,
        ) as Map<String, dynamic>;
        expect(m.containsKey('generationReminderMinutes'), false);
      } finally {
        await db.close();
      }
    });
  }

  for (final mutation in [
    'amount',
    'direction',
    'currency',
    'archived',
    'missing',
  ]) {
    test('legacy financial inference rejects $mutation evidence', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      try {
        await create(db);
        await legacy(db);
        final first = (await db.select(db.financialExpectations).get()).first;
        switch (mutation) {
          case 'amount':
            await db.customStatement(
              'UPDATE financial_expectations SET minor_units = 1 WHERE id = ?',
              [first.id],
            );
          case 'direction':
            await db.customStatement(
              'UPDATE financial_expectations SET direction = 1 WHERE id = ?',
              [first.id],
            );
          case 'currency':
            await db.customStatement(
              "UPDATE financial_expectations SET currency = 'USD' WHERE id = ?",
              [first.id],
            );
          case 'archived':
            await db.customStatement(
              'UPDATE financial_expectations SET status = 1 WHERE id = ?',
              [first.id],
            );
          case 'missing':
            await db.customStatement(
              'DELETE FROM financial_expectations WHERE id = ?',
              [first.id],
            );
        }
        final before = await db.select(db.financialExpectations).get();
        await DriftCommitmentPlanRepository(db)
            .extendRecurringSchedules(LocalDate(2026, 1, 1));
        expect(await db.select(db.financialExpectations).get(), before);
        final m = jsonDecode(
          (await db.select(db.scheduleDefinitions).getSingle()).recurrenceRule!,
        ) as Map<String, dynamic>;
        expect(m.containsKey('generationFinancialExpectation'), false);
      } finally {
        await db.close();
      }
    });
  }

  test('inference and dependent financial write roll back together', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    try {
      await create(db);
      await legacy(db);
      final schedules = await db.select(db.scheduleDefinitions).get();
      final occurrences = await db.select(db.occurrences).get();
      final rules = await db.select(db.reminderRules).get();
      await db.customStatement(
        "CREATE TRIGGER reject_expectation BEFORE INSERT ON financial_expectations BEGIN SELECT RAISE(ABORT, 'injected'); END",
      );
      final repo = DriftCommitmentPlanRepository(db);
      await expectLater(
        repo.extendRecurringSchedules(LocalDate(2026, 1, 1)),
        throwsA(anything),
      );
      expect(await db.select(db.scheduleDefinitions).get(), schedules);
      expect(await db.select(db.occurrences).get(), occurrences);
      expect(await db.select(db.reminderRules).get(), rules);
      await db.customStatement('DROP TRIGGER reject_expectation');
      expect(
        await repo.extendRecurringSchedules(LocalDate(2026, 1, 1)),
        greaterThan(0),
      );
    } finally {
      await db.close();
    }
  });
}
