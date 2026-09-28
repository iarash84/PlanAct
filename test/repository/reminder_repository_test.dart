import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/database/app_database.dart' as db;
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/reminders/data/drift_reminder_repository.dart';
import 'package:planact/features/reminders/domain/reminder.dart';

void main() {
  late db.AppDatabase database;
  late DriftReminderRepository repository;

  setUp(() {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftReminderRepository(database);
  });

  tearDown(() => database.close());

  test('round-trips reminder rules and instances', () async {
    final cycleId = StableId.generate();
    final scheduleId = StableId.generate();
    final occurrenceId = StableId.generate();
    final commitment = Commitment.create(
      title: 'تعهد یادآوری',
      now: DateTime.utc(2026, 1, 1),
    );
    await database
        .into(database.commitments)
        .insert(
          db.CommitmentsCompanion.insert(
            id: commitment.id.value,
            title: commitment.title,
            createdAt: commitment.createdAt,
            status: commitment.status.index,
          ),
        );
    await database
        .into(database.commitmentCycles)
        .insert(
          db.CommitmentCyclesCompanion.insert(
            id: cycleId.value,
            commitmentId: commitment.id.value,
            cycleType: 0,
            startDate: DateTime.utc(2026, 1, 1),
            consumedUnits: 0,
            completionRule: 0,
            status: 0,
          ),
        );
    await database
        .into(database.scheduleDefinitions)
        .insert(
          db.ScheduleDefinitionsCompanion.insert(
            id: scheduleId.value,
            cycleId: cycleId.value,
            mode: 0,
            timeSemantics: 2,
            startDate: '2026-02-01',
            version: 1,
            effectiveFrom: '2026-02-01',
            generationHorizonDays: 90,
          ),
        );
    await database
        .into(database.occurrences)
        .insert(
          db.OccurrencesCompanion.insert(
            id: occurrenceId.value,
            cycleId: cycleId.value,
            scheduleDefinitionId: scheduleId.value,
            occurrenceKey: 'reminder-test',
            timeSemantics: 2,
            originalScheduledValue: 'instant:2026-02-01T18:00:00.000Z',
            currentScheduledValue: 'instant:2026-02-01T18:00:00.000Z',
            status: 0,
            isManualOverride: false,
          ),
        );
    final rule = ReminderRule.beforeOccurrence(
      occurrenceId: occurrenceId,
      offset: const Duration(minutes: 30),
      title: 'یادآوری جلسه',
    );
    final instance = ReminderInstance.fromRule(
      rule: rule,
      occurrenceStart: DateTime.utc(2026, 2, 1, 18),
    ).snoozeUntil(DateTime.utc(2026, 2, 1, 17, 45));

    await repository.saveRule(rule);
    await repository.saveInstance(instance);

    final storedRule = (await repository.listRules()).single;
    final storedInstance = (await repository.listInstances()).single;
    expect(storedRule.offset, const Duration(minutes: -30));
    expect(storedRule.title, 'یادآوری جلسه');
    expect(storedInstance.status, ReminderInstanceStatus.snoozed);
    expect(storedInstance.snoozedUntil, DateTime.utc(2026, 2, 1, 17, 45));
  });
}
