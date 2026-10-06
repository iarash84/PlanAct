import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/core/errors/app_error.dart';
import 'package:planact/features/actuals/data/drift_actual_repository.dart';
import 'package:planact/features/actuals/domain/actual.dart';
import 'package:planact/features/commitments/application/commitment_plan_use_case.dart';
import 'package:planact/features/commitments/data/drift_commitment_plan_repository.dart';
import 'package:planact/features/commitments/data/drift_commitment_repository.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/scheduling/application/edit_commitment_schedule.dart';
import 'package:planact/features/scheduling/application/series_editing.dart';
import 'package:planact/features/scheduling/domain/occurrence.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';

void main() {
  test(
    'following edit preserves resolved and manual rows across restart',
    () async {
      final directory = await Directory.systemTemp.createTemp('schedule-edit-');
      final file = File('${directory.path}/app.sqlite');
      var database = AppDatabase.forTesting(NativeDatabase(file));
      try {
        var plans = DriftCommitmentPlanRepository(database);
        final plan =
            await CreateCommitmentPlan(
              commitments: DriftCommitmentRepository(database),
              plans: plans,
            )(
              title: 'کلاس',
              kind: CommitmentKind.recurring,
              startAt: DateTime(2027, 1, 2, 18),
              frequency: RecurrenceFrequency.daily,
            );
        final completed = plan.occurrences.first.withStatus(
          OccurrenceStatus.completed,
        );
        final manual = plan.occurrences[3].reschedule(DateTime(2027, 1, 5, 19));
        await plans.saveOccurrence(completed);
        await plans.saveOccurrence(manual);
        final anchor = plan.occurrences[1];
        await EditCommitmentSchedule(plans)(
          commitmentId: plan.commitment.id,
          expected: anchor,
          scheduledAt: DateTime(2027, 1, 3, 20),
          scope: SeriesEditScope.thisAndFollowing,
          now: DateTime(2027, 1, 1),
        );
        await database.close();
        database = AppDatabase.forTesting(NativeDatabase(file));
        plans = DriftCommitmentPlanRepository(database);
        final restored = (await plans.findByCommitmentId(plan.commitment.id))!;
        final rows = {for (final row in restored.occurrences) row.id: row};
        expect(restored.schedule.version, 2);
        expect(
          await database.select(database.scheduleDefinitions).get(),
          hasLength(2),
        );
        expect(rows[completed.id]!.status, OccurrenceStatus.completed);
        expect(rows[completed.id]!.scheduleDefinitionId, plan.schedule.id);
        expect(rows[manual.id]!.currentScheduledAt, manual.currentScheduledAt);
        expect(rows[manual.id]!.isManualOverride, isTrue);
        expect(
          rows[anchor.id]!.originalScheduledAt,
          anchor.originalScheduledAt,
        );
        expect(rows[anchor.id]!.currentScheduledAt, DateTime(2027, 1, 3, 20));
        expect(rows[anchor.id]!.scheduleDefinitionId, restored.schedule.id);
      } finally {
        await database.close();
        await directory.delete(recursive: true);
      }
    },
  );

  test('single edit rejects stale actual input and closed history', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    try {
      final plans = DriftCommitmentPlanRepository(database);
      final plan = await CreateCommitmentPlan(
        commitments: DriftCommitmentRepository(database),
        plans: plans,
      )(title: 'نوبت', startAt: DateTime(2027, 1, 2, 18));
      final original = plan.occurrences.single;
      final edit = EditCommitmentSchedule(plans);
      await edit(
        commitmentId: plan.commitment.id,
        expected: original,
        scheduledAt: DateTime(2027, 1, 2, 19),
        scope: SeriesEditScope.onlyThis,
        now: DateTime(2027, 1, 1),
      );
      final edited = (await plans.findByCommitmentId(plan.commitment.id))!
          .occurrences
          .single;
      await edit(
        commitmentId: plan.commitment.id,
        expected: edited,
        scheduledAt: DateTime(2027, 1, 2, 20),
        scope: SeriesEditScope.onlyThis,
        now: DateTime(2027, 1, 1),
      );
      final actuals = DriftActualRepository(database);
      await expectLater(
        actuals.recordOccurrenceActual(
          expected: edited,
          outcome: ActualOutcome.completed,
          recordedAt: DateTime.utc(2027, 1, 2),
        ),
        throwsA(isA<ValidationError>()),
      );
      expect(await actuals.list(), isEmpty);
      final current = (await plans.findByCommitmentId(plan.commitment.id))!
          .occurrences
          .single;
      final closed = await actuals.recordOccurrenceActual(
        expected: current,
        outcome: ActualOutcome.cancelled,
        recordedAt: DateTime.utc(2027, 1, 2),
      );
      await expectLater(
        edit(
          commitmentId: plan.commitment.id,
          expected: closed,
          scheduledAt: DateTime(2027, 1, 3, 18),
          scope: SeriesEditScope.onlyThis,
          now: DateTime(2027, 1, 1),
        ),
        throwsA(isA<ValidationError>()),
      );
    } finally {
      await database.close();
    }
  });

  test(
    'series transaction rolls back its new version on occurrence failure',
    () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      try {
        final plans = DriftCommitmentPlanRepository(database);
        final plan =
            await CreateCommitmentPlan(
              commitments: DriftCommitmentRepository(database),
              plans: plans,
            )(
              title: 'کلاس',
              kind: CommitmentKind.recurring,
              startAt: DateTime(2027, 1, 2, 18),
              frequency: RecurrenceFrequency.daily,
            );
        await database.customStatement(
          "CREATE TRIGGER reject_edit BEFORE UPDATE ON occurrences BEGIN SELECT RAISE(ABORT, 'injected'); END",
        );
        await expectLater(
          EditCommitmentSchedule(plans)(
            commitmentId: plan.commitment.id,
            expected: plan.occurrences.first,
            scheduledAt: DateTime(2027, 1, 2, 20),
            scope: SeriesEditScope.entireActiveCycle,
            now: DateTime(2027, 1, 1),
          ),
          throwsA(anything),
        );
        expect(
          await database.select(database.scheduleDefinitions).get(),
          hasLength(1),
        );
        expect(
          (await plans.findByCommitmentId(plan.commitment.id))!
              .schedule
              .version,
          1,
        );
      } finally {
        await database.close();
      }
    },
  );
}
