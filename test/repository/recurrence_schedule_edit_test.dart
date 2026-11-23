import 'dart:io';

import 'package:planact/features/actuals/data/drift_actual_repository.dart';
import 'package:planact/features/actuals/domain/actual.dart';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/core/errors/app_error.dart';
import 'package:planact/features/commitments/application/commitment_plan_use_case.dart';
import 'package:planact/features/commitments/data/drift_commitment_plan_repository.dart';
import 'package:planact/features/commitments/data/drift_commitment_repository.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/scheduling/application/edit_commitment_schedule.dart';
import 'package:planact/features/scheduling/application/series_editing.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';

Future<CommitmentPlan> seed(
  AppDatabase database,
  DriftCommitmentPlanRepository plans,
) =>
    CreateCommitmentPlan(
      commitments: DriftCommitmentRepository(database),
      plans: plans,
    )(
      title: 'کلاس',
      kind: CommitmentKind.recurring,
      startAt: DateTime(2027, 1, 2, 18),
      frequency: RecurrenceFrequency.daily,
    );

void main() {
  final now = DateTime(2027, 1, 1);
  RecurrenceScheduleEdit payload({int interval = 1, int? count}) =>
      RecurrenceScheduleEdit(
        rule: RecurrenceRule(
          frequency: RecurrenceFrequency.daily,
          interval: interval,
          dayOfMonth: 2,
          monthOfYear: 1,
          monthEndPolicy: MonthEndPolicy.clampToLastDay,
        ),
        totalCount: count,
      );

  test(
    'preview is read only; cold reopen retains IDs and forward Undo',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'recurrence-edit-',
      );
      final file = File('${directory.path}/app.sqlite');
      var database = AppDatabase.forTesting(NativeDatabase(file));
      try {
        var plans = DriftCommitmentPlanRepository(database);
        final plan = await seed(database, plans);
        final command = EditCommitmentSchedule(plans);
        final request = payload(interval: 2);
        final preview = await command.preview(
          commitmentId: plan.commitment.id,
          expected: plan.occurrences.first,
          scheduledAt: DateTime(2027, 1, 2, 20),
          scope: SeriesEditScope.thisAndFollowing,
          now: now,
          recurrenceEdit: request,
        );
        expect(
          (await plans.findByCommitmentId(plan.commitment.id))!
              .schedule
              .version,
          1,
        );
        expect(await plans.scheduleUndo(plan.commitment.id), isNull);
        expect(
          preview.occurrences[1].currentScheduledAt,
          DateTime(2027, 1, 4, 20),
        );
        await command(
          commitmentId: plan.commitment.id,
          expected: plan.occurrences.first,
          scheduledAt: DateTime(2027, 1, 2, 20),
          scope: SeriesEditScope.thisAndFollowing,
          now: now,
          recurrenceEdit: request,
          previewToken: preview.token,
        );
        await database.close();
        database = AppDatabase.forTesting(NativeDatabase(file));
        plans = DriftCommitmentPlanRepository(database);
        final restored = (await plans.findByCommitmentId(plan.commitment.id))!;
        expect(restored.schedule.version, 2);
        expect(
          restored.occurrences.map((o) => o.id).toSet(),
          plan.occurrences.map((o) => o.id).toSet(),
        );
        expect(
          await database.readMetadata(
            'reminder_reopen_v1:${plan.occurrences.first.id.value}',
          ),
          '1',
        );
        final undo = (await plans.scheduleUndo(plan.commitment.id))!;
        await plans.undoSchedule(plan.commitment.id, undo, now);
        final undone = (await plans.findByCommitmentId(plan.commitment.id))!;
        expect(undone.schedule.version, 3);
        expect(undone.schedule.recurrenceRule!.interval, 1);
        expect(
          undone.occurrences.first.currentScheduledAt,
          plan.occurrences.first.currentScheduledAt,
        );
        expect(
          await database.select(database.scheduleDefinitions).get(),
          hasLength(3),
        );
      } finally {
        await database.close();
        await directory.delete(recursive: true);
      }
    },
  );

  test(
    'token binds request, generation and append-only result history',
    () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      try {
        final plans = DriftCommitmentPlanRepository(database);
        final plan = await seed(database, plans);
        final command = EditCommitmentSchedule(plans);
        final request = payload(interval: 2);
        final preview = await command.preview(
          commitmentId: plan.commitment.id,
          expected: plan.occurrences.first,
          scheduledAt: DateTime(2027, 1, 2, 18),
          scope: SeriesEditScope.thisAndFollowing,
          now: now,
          recurrenceEdit: request,
        );
        Future<bool> save(RecurrenceScheduleEdit edit) => command(
          commitmentId: plan.commitment.id,
          expected: plan.occurrences.first,
          scheduledAt: DateTime(2027, 1, 2, 18),
          scope: SeriesEditScope.thisAndFollowing,
          now: now,
          recurrenceEdit: edit,
          previewToken: preview.token,
        );
        await expectLater(
          save(payload(interval: 3)),
          throwsA(isA<ValidationError>()),
        );
        await plans.extendRecurringSchedules(LocalDate(2027, 3, 1));
        await expectLater(save(request), throwsA(isA<ValidationError>()));
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

  test('manual movement, row removal, only-this recurrence and calendar changes reject', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    try {
      final plans = DriftCommitmentPlanRepository(database);
      final plan = await seed(database, plans);
      final command = EditCommitmentSchedule(plans);
      Future<Object> preview(
        RecurrenceScheduleEdit edit, {
        SeriesEditScope scope = SeriesEditScope.thisAndFollowing,
      }) => command.preview(
        commitmentId: plan.commitment.id,
        expected: plan.occurrences.first,
        scheduledAt: DateTime(2027, 1, 2, 18),
        scope: scope,
        now: now,
        recurrenceEdit: edit,
      );
      await expectLater(
        preview(payload(count: 2)),
        throwsA(isA<ValidationError>()),
      );
      await expectLater(
        preview(payload(), scope: SeriesEditScope.onlyThis),
        throwsA(isA<ValidationError>()),
      );
      await expectLater(
        preview(
          RecurrenceScheduleEdit(
            rule: RecurrenceRule(
              frequency: RecurrenceFrequency.monthly,
              calendar: RecurrenceCalendar.jalali,
            ),
          ),
        ),
        throwsA(isA<ValidationError>()),
      );
      await plans.saveOccurrence(
        plan.occurrences[2].reschedule(DateTime(2027, 1, 4, 19)),
      );
      await expectLater(
        preview(payload(interval: 2)),
        throwsA(isA<ValidationError>()),
      );
    } finally {
      await database.close();
    }
  });

  test(
    'result round trip rejects stale preview and fresh protected movement',
    () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      try {
        final plans = DriftCommitmentPlanRepository(database);
        final plan = await seed(database, plans);
        final command = EditCommitmentSchedule(plans);
        final request = payload(interval: 2);
        final proposed = await command.preview(
          commitmentId: plan.commitment.id,
          expected: plan.occurrences.first,
          scheduledAt: DateTime(2027, 1, 2, 18),
          scope: SeriesEditScope.thisAndFollowing,
          now: now,
          recurrenceEdit: request,
        );
        final actuals = DriftActualRepository(database);
        final resolved = await actuals.recordOccurrenceActual(
          expected: plan.occurrences[1],
          outcome: ActualOutcome.cancelled,
          recordedAt: now.toUtc(),
        );
        await actuals.recordOccurrenceActual(
          expected: resolved,
          outcome: ActualOutcome.reopened,
          recordedAt: now.toUtc(),
        );
        await expectLater(
          command(
            commitmentId: plan.commitment.id,
            expected: plan.occurrences.first,
            scheduledAt: DateTime(2027, 1, 2, 18),
            scope: SeriesEditScope.thisAndFollowing,
            now: now,
            recurrenceEdit: request,
            previewToken: proposed.token,
          ),
          throwsA(isA<ValidationError>()),
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

  test(
    'payment allocation protects movement and invalidates preview',
    () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      try {
        final plans = DriftCommitmentPlanRepository(database);
        final plan = await seed(database, plans);
        final command = EditCommitmentSchedule(plans);
        final request = payload(interval: 2);
        final proposed = await command.preview(
          commitmentId: plan.commitment.id,
          expected: plan.occurrences.first,
          scheduledAt: DateTime(2027, 1, 2, 18),
          scope: SeriesEditScope.thisAndFollowing,
          now: now,
          recurrenceEdit: request,
        );
        await database.customStatement(
          "INSERT INTO financial_accounts (id,name,currency,type,status) VALUES ('account','test','IRR',0,0)",
        );
        await database.customStatement(
          "INSERT INTO account_entries (id,account_id,type,minor_units,currency,occurred_at) VALUES ('entry','account',0,100,'IRR',0)",
        );
        await database.customStatement(
          "INSERT INTO transaction_matches (id,transaction_id,minor_units,currency,created_at,status) VALUES ('match','entry',100,'IRR',0,0)",
        );
        await database.customStatement(
          "INSERT INTO match_allocations (id,match_id,occurrence_id,minor_units,currency,type) VALUES ('allocation','match',?,100,'IRR',0)",
          [plan.occurrences[1].id.value],
        );
        await expectLater(
          command(
            commitmentId: plan.commitment.id,
            expected: plan.occurrences.first,
            scheduledAt: DateTime(2027, 1, 2, 18),
            scope: SeriesEditScope.thisAndFollowing,
            now: now,
            recurrenceEdit: request,
            previewToken: proposed.token,
          ),
          throwsA(isA<ValidationError>()),
        );
        final unchanged = payload();
        final fresh = await command.preview(
          commitmentId: plan.commitment.id,
          expected: plan.occurrences.first,
          scheduledAt: DateTime(2027, 1, 2, 18),
          scope: SeriesEditScope.thisAndFollowing,
          now: now,
          recurrenceEdit: unchanged,
        );
        await database.customStatement(
          "UPDATE transaction_matches SET status = 1 WHERE id = 'match'",
        );
        await expectLater(
          command(
            commitmentId: plan.commitment.id,
            expected: plan.occurrences.first,
            scheduledAt: DateTime(2027, 1, 2, 18),
            scope: SeriesEditScope.thisAndFollowing,
            now: now,
            recurrenceEdit: unchanged,
            previewToken: fresh.token,
          ),
          throwsA(isA<ValidationError>()),
        );
      } finally {
        await database.close();
      }
    },
  );

  test(
    'failure after version insert rolls back version rows intent and Undo',
    () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      try {
        final plans = DriftCommitmentPlanRepository(database);
        final plan = await seed(database, plans);
        final command = EditCommitmentSchedule(plans);
        final request = payload(interval: 2);
        final preview = await command.preview(
          commitmentId: plan.commitment.id,
          expected: plan.occurrences.first,
          scheduledAt: DateTime(2027, 1, 2, 18),
          scope: SeriesEditScope.thisAndFollowing,
          now: now,
          recurrenceEdit: request,
        );
        await database.customStatement(
          "CREATE TRIGGER fail_edit BEFORE UPDATE ON occurrences BEGIN SELECT RAISE(ABORT, 'injected'); END",
        );
        await expectLater(
          command(
            commitmentId: plan.commitment.id,
            expected: plan.occurrences.first,
            scheduledAt: DateTime(2027, 1, 2, 18),
            scope: SeriesEditScope.thisAndFollowing,
            now: now,
            recurrenceEdit: request,
            previewToken: preview.token,
          ),
          throwsA(anything),
        );
        expect(
          await database.select(database.scheduleDefinitions).get(),
          hasLength(1),
        );
        expect(await plans.scheduleUndo(plan.commitment.id), isNull);
        expect(
          await database.readMetadata(
            'reminder_reopen_v1:${plan.occurrences.first.id.value}',
          ),
          isNull,
        );
      } finally {
        await database.close();
      }
    },
  );
}
