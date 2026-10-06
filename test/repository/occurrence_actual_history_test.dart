import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/core/errors/app_error.dart';
import 'package:planact/features/actuals/application/actual_use_cases.dart';
import 'package:planact/features/actuals/data/drift_actual_repository.dart';
import 'package:planact/features/actuals/domain/actual.dart';
import 'package:planact/features/commitments/application/commitment_plan_use_case.dart';
import 'package:planact/features/commitments/data/drift_commitment_plan_repository.dart';
import 'package:planact/features/commitments/data/drift_commitment_repository.dart';
import 'package:planact/features/scheduling/domain/occurrence.dart';

void main() {
  test(
    'result and explicit reopening survive restart without erasing history',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'actual-history-',
      );
      final file = File('${directory.path}/app.sqlite');
      var database = AppDatabase.forTesting(NativeDatabase(file));
      try {
        var plans = DriftCommitmentPlanRepository(database);
        final plan = await CreateCommitmentPlan(
          commitments: DriftCommitmentRepository(database),
          plans: plans,
        )(title: 'کلاس', startAt: DateTime(2027, 1, 2, 18));
        var actuals = DriftActualRepository(database);
        final completed = await actuals.recordOccurrenceActual(
          expected: plan.occurrences.single,
          outcome: ActualOutcome.completed,
          recordedAt: DateTime.utc(2026, 10, 5),
        );
        expect(completed.status, OccurrenceStatus.completed);
        await expectLater(
          actuals.recordOccurrenceActual(
            expected: plan.occurrences.single,
            outcome: ActualOutcome.completed,
            recordedAt: DateTime.utc(2026, 10, 5),
          ),
          throwsA(isA<ValidationError>()),
        );
        await actuals.recordOccurrenceActual(
          expected: completed,
          outcome: ActualOutcome.reopened,
          recordedAt: DateTime.utc(2026, 10, 5),
        );
        await database.close();
        database = AppDatabase.forTesting(NativeDatabase(file));
        plans = DriftCommitmentPlanRepository(database);
        actuals = DriftActualRepository(database);
        final restored = (await plans.findByCommitmentId(plan.commitment.id))!;
        final history = await actuals.list();
        expect(history.map((a) => a.outcome), [
          ActualOutcome.completed,
          ActualOutcome.reopened,
        ]);
        expect(restored.occurrences.single.status, OccurrenceStatus.scheduled);
        expect(
          const HistoryProjection()
              .build(occurrences: restored.occurrences, actuals: history)
              .single
              .isResolved,
          isFalse,
        );
        expect(
          await database.select(database.entitlementLedgerEntries).get(),
          isEmpty,
        );
        expect(await database.select(database.accountEntries).get(), isEmpty);
      } finally {
        await database.close();
        await directory.delete(recursive: true);
      }
    },
  );

  test('failure updating status rolls back the inserted actual', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    try {
      final plans = DriftCommitmentPlanRepository(database);
      final plan = await CreateCommitmentPlan(
        commitments: DriftCommitmentRepository(database),
        plans: plans,
      )(title: 'کلاس', startAt: DateTime(2027, 1, 2, 18));
      await database.customStatement(
        "CREATE TRIGGER reject_status BEFORE UPDATE ON occurrences BEGIN SELECT RAISE(ABORT, 'injected'); END",
      );
      final actuals = DriftActualRepository(database);
      await expectLater(
        actuals.recordOccurrenceActual(
          expected: plan.occurrences.single,
          outcome: ActualOutcome.completed,
          recordedAt: DateTime.utc(2026, 10, 5),
        ),
        throwsA(anything),
      );
      expect(await actuals.list(), isEmpty);
      expect(
        (await plans.findByCommitmentId(plan.commitment.id))!
            .occurrences
            .single
            .status,
        OccurrenceStatus.scheduled,
      );
    } finally {
      await database.close();
    }
  });
}
