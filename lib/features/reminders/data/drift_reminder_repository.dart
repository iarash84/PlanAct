import 'package:planact/core/application/command_gate.dart';
import 'package:drift/drift.dart';
import 'package:planact/core/database/app_database.dart' as db;
import 'package:planact/features/reminders/application/reminder_service.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/reminders/domain/reminder.dart';
import 'package:planact/features/scheduling/domain/occurrence.dart';

class DriftReminderRepository
    implements
        CommandGateProvider,
        ReminderRepository,
        ReminderOccurrenceEligibility,
        ReminderOccurrenceSchedule,
        ReminderIntentTransaction {
  DriftReminderRepository(this.database);

  @override
  CommandGate? get commandGate => CommandGate.forOwner(database);
  final db.AppDatabase database;

  @override
  Future<T> runReminderTransaction<T>(Future<T> Function() action) =>
      CommandGate.runFor(this, () => database.transaction(action));

  @override
  Future<DateTime?> occurrenceStart(StableId occurrenceId) =>
      CommandGate.runFor(this, () async {
        final row = await (database.select(
          database.occurrences,
        )..where((row) => row.id.equals(occurrenceId.value))).getSingleOrNull();
        if (row == null) return null;
        final value = row.currentScheduledValue;
        if (value.startsWith('date:')) return null;
        if (value.startsWith('instant:')) {
          return DateTime.parse(value.substring(8)).toUtc();
        }
        final parts = value.substring(6).split('T');
        final date = parts[0].split('-').map(int.parse).toList();
        final time = parts[1].split(':');
        final seconds = time[2].split('.');
        return DateTime(
          date[0],
          date[1],
          date[2],
          int.parse(time[0]),
          int.parse(time[1]),
          int.parse(seconds[0]),
          int.parse(seconds[1]),
        );
      });

  @override
  Future<bool> canRemind(StableId occurrenceId) =>
      CommandGate.runFor(this, () async {
        final occurrence = await (database.select(
          database.occurrences,
        )..where((row) => row.id.equals(occurrenceId.value))).getSingleOrNull();
        if (occurrence == null) return false;
        final status = OccurrenceStatus.values[occurrence.status];
        return status != OccurrenceStatus.completed &&
            status != OccurrenceStatus.skipped &&
            status != OccurrenceStatus.cancelled;
      });

  @override
  Future<List<ReminderRule>> listRules() => CommandGate.runFor(this, () async {
    final rows = await database.select(database.reminderRules).get();
    return rows.map(_rule).toList(growable: false);
  });

  @override
  Future<List<ReminderInstance>> listInstances() =>
      CommandGate.runFor(this, () async {
        final rows = await database.select(database.reminderInstances).get();
        return rows.map(_instance).toList(growable: false);
      });

  @override
  Future<void> saveRule(ReminderRule rule) => CommandGate.runFor(
    this,
    () async => database
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
        ),
  );

  @override
  Future<void> saveInstance(ReminderInstance instance) =>
      CommandGate.runFor(this, () async {
        final scheduledAt = instance.scheduledAt.toUtc();
        await database.transaction(() async {
          final existing =
              await (database.select(database.reminderInstances)..where(
                    (table) =>
                        table.ruleId.equals(instance.ruleId.value) &
                        table.occurrenceId.equals(instance.occurrenceId.value) &
                        table.scheduledAt.equals(scheduledAt),
                  ))
                  .getSingleOrNull();
          final companion = db.ReminderInstancesCompanion(
            id: Value(existing?.id ?? instance.id.value),
            ruleId: Value(instance.ruleId.value),
            occurrenceId: Value(instance.occurrenceId.value),
            scheduledAt: Value(scheduledAt),
            status: Value(instance.status.index),
            snoozedUntil: Value(instance.snoozedUntil?.toUtc()),
            platformNotificationId: Value(instance.platformNotificationId),
          );
          if (existing == null) {
            await database.into(database.reminderInstances).insert(companion);
          } else {
            await (database.update(
              database.reminderInstances,
            )..where((table) => table.id.equals(existing.id))).write(companion);
          }
        });
      });

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
