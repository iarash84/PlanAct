import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/database/app_database.dart' as db;
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/reminders/application/drift_reminder_repository.dart';
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
    final rule = ReminderRule.beforeOccurrence(
      occurrenceId: StableId.generate(),
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
