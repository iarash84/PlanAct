import 'package:planact/core/application/command_gate.dart';
import 'package:drift/drift.dart';
import 'package:planact/core/database/app_database.dart' as db;
import 'package:planact/features/reminders/application/reminder_service.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/reminders/domain/reminder.dart';
import 'package:planact/features/reminders/domain/morning_reminder.dart';
import 'package:planact/features/scheduling/domain/occurrence.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/commitments/domain/commitment_cycle.dart';

class DriftReminderRepository
    implements
        CommandGateProvider,
        ReminderRepository,
        ReminderFreshInstance,
        ReminderOccurrenceEligibility,
        ReminderOccurrenceSchedule,
        ReminderOccurrenceReopeningIntent,
        ReminderIntentTransaction,
        MorningReminderStore {
  DriftReminderRepository(this.database);

  @override
  CommandGate? get commandGate => CommandGate.forOwner(database);
  final db.AppDatabase database;

  @override
  Future<ReminderInstance?> findInstance(StableId id) =>
      CommandGate.runFor(this, () async {
        final row = await (database.select(
          database.reminderInstances,
        )..where((r) => r.id.equals(id.value))).getSingleOrNull();
        return row == null
            ? null
            : _instance(row, await _delivery('instance', row.id));
      });

  @override
  Future<bool> hasPendingReopening(StableId occurrenceId) => CommandGate.runFor(
    this,
    () async =>
        await database.readMetadata(
          'reminder_reopen_v1:${occurrenceId.value}',
        ) ==
        '1',
  );
  @override
  Future<void> finishReopening(StableId occurrenceId) => CommandGate.runFor(
    this,
    () =>
        database.writeMetadata('reminder_reopen_v1:${occurrenceId.value}', '0'),
  );

  @override
  Future<T> runReminderTransaction<T>(Future<T> Function() action) =>
      CommandGate.runFor(
        this,
        () => database.transaction(() async {
          await database.customStatement(
            'UPDATE schema_metadata SET value = value WHERE key = ?',
            ['schema_version'],
          );
          return action();
        }),
      );

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
  Future<bool> canRemind(StableId occurrenceId) => CommandGate.runFor(
    this,
    () async {
      final occurrence = await (database.select(
        database.occurrences,
      )..where((row) => row.id.equals(occurrenceId.value))).getSingleOrNull();
      if (occurrence == null) return false;
      final status = OccurrenceStatus.values[occurrence.status];
      final cycle = await (database.select(
        database.commitmentCycles,
      )..where((t) => t.id.equals(occurrence.cycleId))).getSingleOrNull();
      if (cycle == null || cycle.status != CommitmentCycleStatus.active.index) {
        return false;
      }
      final owner = await (database.select(
        database.commitments,
      )..where((t) => t.id.equals(cycle.commitmentId))).getSingleOrNull();
      if (owner == null || owner.status != CommitmentStatus.active.index) {
        return false;
      }
      return status != OccurrenceStatus.completed &&
          status != OccurrenceStatus.skipped &&
          status != OccurrenceStatus.cancelled;
    },
  );

  @override
  Future<bool> hasEligibleReminderForLocalDate(DateTime localDate) =>
      CommandGate.runFor(this, () async {
        final rules = await listRules();
        final instances = await listInstances();
        final occurrenceCanRemind = <StableId, bool>{};
        for (final instance in instances) {
          occurrenceCanRemind[instance.occurrenceId] = await canRemind(
            instance.occurrenceId,
          );
        }
        return rules.any((rule) {
          final matches = instances.where(
            (instance) => instance.ruleId == rule.id,
          );
          return matches.any(
            (instance) => isEligibleMorningReminder(
              rule: rule,
              instance: instance,
              localDate: localDate,
              occurrenceCanRemind:
                  occurrenceCanRemind[instance.occurrenceId] ?? false,
            ),
          );
        });
      });

  @override
  Future<bool> claimMorningReminder(String localDayKey) =>
      CommandGate.runFor(this, () async {
        return database.transaction(() async {
          await database.customStatement(
            'UPDATE schema_metadata SET value = value WHERE key = ?',
            ['schema_version'],
          );
          final existing = await database.readMetadata(
            'morning_reminder_sent_day_v1',
          );
          if (existing == localDayKey) return false;
          await database.writeMetadata(
            'morning_reminder_sent_day_v1',
            localDayKey,
          );
          return true;
        });
      });

  @override
  Future<List<ReminderRule>> listRules() => CommandGate.runFor(this, () async {
    final rows = await database.select(database.reminderRules).get();
    return Future.wait(
      rows.map((row) async => _rule(row, await _delivery('rule', row.id))),
    );
  });

  @override
  Future<List<ReminderInstance>> listInstances() =>
      CommandGate.runFor(this, () async {
        final rows = await database.select(database.reminderInstances).get();
        return Future.wait(
          rows.map(
            (row) async => _instance(row, await _delivery('instance', row.id)),
          ),
        );
      });

  @override
  Future<void> saveRule(ReminderRule rule) => CommandGate.runFor(
    this,
    () => database.transaction(() async {
      await database
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
      await database.writeMetadata(
        'reminder_delivery_v1:rule:${rule.id.value}',
        rule.delivery.name,
      );
    }),
  );

  @override
  Future<void> saveInstance(ReminderInstance instance) => CommandGate.runFor(
    this,
    () async {
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
        await database.writeMetadata(
          'reminder_delivery_v1:instance:${existing?.id ?? instance.id.value}',
          instance.delivery.name,
        );
      });
    },
  );

  Future<ReminderDelivery> _delivery(String kind, String id) async {
    final value = await database.readMetadata('reminder_delivery_v1:$kind:$id');
    return value == null
        ? ReminderDelivery.notification
        : ReminderDelivery.values.byName(value);
  }

  ReminderRule _rule(db.ReminderRule row, ReminderDelivery delivery) =>
      ReminderRule(
        id: StableId.parse(row.id),
        occurrenceId: StableId.parse(row.occurrenceId),
        anchor: ReminderAnchor.values[row.anchor],
        offset: Duration(seconds: row.offsetSeconds),
        absoluteAt: row.absoluteAt?.toUtc(),
        title: row.title,
        body: row.body,
        enabled: row.enabled,
        delivery: delivery,
      );

  ReminderInstance _instance(
    db.ReminderInstance row,
    ReminderDelivery delivery,
  ) => ReminderInstance(
    id: StableId.parse(row.id),
    ruleId: StableId.parse(row.ruleId),
    occurrenceId: StableId.parse(row.occurrenceId),
    scheduledAt: row.scheduledAt.toUtc(),
    status: ReminderInstanceStatus.values[row.status],
    snoozedUntil: row.snoozedUntil?.toUtc(),
    platformNotificationId: row.platformNotificationId,
    delivery: delivery,
  );
}
