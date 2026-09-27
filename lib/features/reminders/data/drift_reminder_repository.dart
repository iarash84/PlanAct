import 'package:drift/drift.dart';
import 'package:planact/core/database/app_database.dart' as db;
import 'package:planact/features/reminders/application/reminder_service.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/reminders/domain/reminder.dart';

class DriftReminderRepository implements ReminderRepository {
  DriftReminderRepository(this.database);
  final db.AppDatabase database;

  @override
  Future<List<ReminderRule>> listRules() async {
    final rows = await database.select(database.reminderRules).get();
    return rows.map(_rule).toList(growable: false);
  }

  @override
  Future<List<ReminderInstance>> listInstances() async {
    final rows = await database.select(database.reminderInstances).get();
    return rows.map(_instance).toList(growable: false);
  }

  @override
  Future<void> saveRule(ReminderRule rule) => database
      .into(database.reminderRules)
      .insertOnConflictUpdate(
        db.ReminderRulesCompanion(
          id: Value(rule.id.value),
          occurrenceId: Value(rule.occurrenceId.value),
          anchor: Value(rule.anchor.index),
          offsetSeconds: Value(rule.offset.inSeconds),
          absoluteAt: Value(rule.absoluteAt?.toUtc()),
          title: Value(rule.title),
          body: Value(rule.body),
          enabled: Value(rule.enabled),
        ),
      );

  @override
  Future<void> saveInstance(ReminderInstance instance) => database
      .into(database.reminderInstances)
      .insertOnConflictUpdate(
        db.ReminderInstancesCompanion(
          id: Value(instance.id.value),
          ruleId: Value(instance.ruleId.value),
          occurrenceId: Value(instance.occurrenceId.value),
          scheduledAt: Value(instance.scheduledAt.toUtc()),
          status: Value(instance.status.index),
          snoozedUntil: Value(instance.snoozedUntil?.toUtc()),
          platformNotificationId: Value(instance.platformNotificationId),
        ),
      );

  ReminderRule _rule(db.ReminderRule row) => ReminderRule(
    id: StableId.parse(row.id),
    occurrenceId: StableId.parse(row.occurrenceId),
    anchor: ReminderAnchor.values[row.anchor],
    offset: Duration(seconds: row.offsetSeconds),
    absoluteAt: row.absoluteAt?.toUtc(),
    title: row.title,
    body: row.body,
    enabled: row.enabled,
  );

  ReminderInstance _instance(db.ReminderInstance row) => ReminderInstance(
    id: StableId.parse(row.id),
    ruleId: StableId.parse(row.ruleId),
    occurrenceId: StableId.parse(row.occurrenceId),
    scheduledAt: row.scheduledAt.toUtc(),
    status: ReminderInstanceStatus.values[row.status],
    snoozedUntil: row.snoozedUntil?.toUtc(),
    platformNotificationId: row.platformNotificationId,
  );
}
