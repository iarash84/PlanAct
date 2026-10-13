import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/database/app_database.dart';
import 'package:planact/features/backup/data/sqlite_backup_snapshot.dart';
import 'package:planact/features/commitments/application/commitment_plan_use_case.dart';
import 'package:planact/features/commitments/data/drift_commitment_plan_repository.dart';
import 'package:planact/features/commitments/data/drift_commitment_repository.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/reminders/data/drift_reminder_repository.dart';
import 'package:planact/features/scheduling/application/extend_recurring_schedules.dart';
import 'package:planact/features/scheduling/domain/occurrence.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';
import 'package:shamsi_date/shamsi_date.dart';

DateTime at(int year, int month, int day) {
  final g = Jalali(year, month, day).toGregorian();
  return DateTime(g.year, g.month, g.day, 18, 35);
}

void main() {
  test(
    'cold reopen, rolling concurrency, history, reminders and snapshot',
    () async {
      final directory = await Directory.systemTemp.createTemp('rolling-');
      final file = File('${directory.path}/live.sqlite');
      var database = AppDatabase.forTesting(NativeDatabase(file));
      try {
        var plans = DriftCommitmentPlanRepository(database);
        final plan =
            await CreateCommitmentPlan(
              commitments: DriftCommitmentRepository(database),
              plans: plans,
            )(
              title: 'ماهانه',
              kind: CommitmentKind.recurring,
              startAt: at(1405, 7, 19),
              frequency: RecurrenceFrequency.monthly,
              recurrenceCalendar: RecurrenceCalendar.jalali,
              reminderOffsets: const [Duration(minutes: 30)],
            );
        final completed = plan.occurrences.first.withStatus(
          OccurrenceStatus.completed,
        );
        final moved = plan.occurrences[1].reschedule(at(1405, 9, 2));
        await plans.saveOccurrence(completed);
        await plans.saveOccurrence(moved);
        await database.close();
        database = AppDatabase.forTesting(NativeDatabase(file));
        plans = DriftCommitmentPlanRepository(database);
        final restored = (await plans.findByCommitmentId(plan.commitment.id))!;
        expect(
          restored.schedule.recurrenceRule!.calendar,
          RecurrenceCalendar.jalali,
        );
        expect(restored.schedule.localTime, LocalTime(18, 35));
        final command = ExtendRecurringSchedules(plans);
        final results = await Future.wait([
          command(at(1406, 7, 1)),
          command(at(1406, 7, 1)),
        ]);
        expect(results.reduce((a, b) => a + b), greaterThan(0));
        expect(await command(at(1406, 7, 1)), 0);
        final after = (await plans.findByCommitmentId(plan.commitment.id))!;
        expect(
          after.occurrences.map((o) => o.occurrenceKey).toSet().length,
          after.occurrences.length,
        );
        expect(
          after.occurrences.singleWhere((o) => o.id == completed.id).status,
          OccurrenceStatus.completed,
        );
        expect(
          after.occurrences
              .singleWhere((o) => o.id == moved.id)
              .currentScheduledAt,
          moved.currentScheduledAt,
        );
        expect(
          after.occurrences.any((o) => o.currentScheduledAt == at(1406, 7, 19)),
          isTrue,
        );
        final reminders = await DriftReminderRepository(database).listRules();
        final added = after.occurrences.where(
          (o) => !plan.occurrences.any((old) => old.id == o.id),
        );
        for (final row in added) {
          expect(
            reminders.where((r) => r.occurrenceId == row.id),
            hasLength(1),
          );
        }
        final beforeRead = after.occurrences.length;
        final week = await plans.loadWeek(
          LocalDate.fromDateTime(at(1406, 7, 19)),
        );
        expect(
          week[plan.commitment.id.value]!.any(
            (o) => o.currentScheduledAt == at(1406, 7, 19),
          ),
          isTrue,
        );
        expect(
          (await plans.findByCommitmentId(plan.commitment.id))!.occurrences,
          hasLength(beforeRead),
        );
        final snapshot = File('${directory.path}/snapshot.sqlite');
        final bytes = await sqliteBackupSnapshot(
          database: database,
          target: snapshot,
          redact: false,
        );
        await snapshot.writeAsBytes(bytes, flush: true);
        final backup = AppDatabase.forTesting(NativeDatabase(snapshot));
        try {
          final backupPlan = (await DriftCommitmentPlanRepository(backup)
              .findByCommitmentId(plan.commitment.id))!;
          expect(
            backupPlan.occurrences.map((o) => o.id).toSet(),
            after.occurrences.map((o) => o.id).toSet(),
          );
          expect(backupPlan.schedule.recurrenceRule!.dayOfMonth, 19);
          expect(backupPlan.schedule.generationReminderOffsets, const [
            Duration(minutes: 30),
          ]);
        } finally {
          await backup.close();
        }
      } finally {
        await database.close();
        await directory.delete(recursive: true);
      }
    },
  );

  test(
    'legacy JSON remains Gregorian and generation failure rolls back',
    () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      try {
        final plans = DriftCommitmentPlanRepository(database);
        final plan =
            await CreateCommitmentPlan(
              commitments: DriftCommitmentRepository(database),
              plans: plans,
            )(
              title: 'قدیمی',
              kind: CommitmentKind.recurring,
              startAt: at(1405, 7, 19),
              frequency: RecurrenceFrequency.monthly,
            );
        final row = await database
            .select(database.scheduleDefinitions)
            .getSingle();
        final json = jsonDecode(row.recurrenceRule!) as Map<String, dynamic>;
        json.remove('calendar');
        json.remove('monthOfYear');
        json.remove('formatVersion');
        json.remove('generationReminderMinutes');
        await database.customStatement(
          'UPDATE schedule_definitions SET recurrence_rule = ? WHERE id = ?',
          [jsonEncode(json), row.id],
        );
        expect(
          (await plans.findByCommitmentId(plan.commitment.id))!
              .schedule
              .recurrenceRule!
              .calendar,
          RecurrenceCalendar.gregorian,
        );
        final before = await database.select(database.occurrences).get();
        await database.customStatement(
          "CREATE TRIGGER reject_generation BEFORE INSERT ON occurrences BEGIN SELECT RAISE(ABORT, 'injected'); END",
        );
        await expectLater(
          ExtendRecurringSchedules(plans)(at(1406, 7, 1)),
          throwsA(anything),
        );
        expect(await database.select(database.occurrences).get(), before);
        await database.customStatement('DROP TRIGGER reject_generation');
        expect(
          await ExtendRecurringSchedules(plans)(at(1406, 7, 1)),
          greaterThan(0),
        );
      } finally {
        await database.close();
      }
    },
  );
}
