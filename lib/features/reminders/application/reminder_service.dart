import 'package:planact/core/application/command_gate.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/reminders/domain/reminder.dart';

/// Optional platform inventory used to remove alarms with no durable owner.
abstract interface class ReminderPlatformInventory {
  Future<void> removeOrphans(Set<String> activeInstanceIds);
}

abstract interface class ReminderRepository {
  Future<List<ReminderRule>> listRules();
  Future<List<ReminderInstance>> listInstances();
  Future<void> saveRule(ReminderRule rule);
  Future<void> saveInstance(ReminderInstance instance);
}

/// Atomically commits reminder intent before any external platform effects.
abstract interface class ReminderIntentTransaction {
  Future<T> runReminderTransaction<T>(Future<T> Function() action);
}

/// Persistent adapters can reject reminders whose occurrence is resolved.
abstract interface class ReminderOccurrenceEligibility {
  Future<bool> canRemind(StableId occurrenceId);
}

/// Rebuilds missing or stale reminder intent from the durable occurrence.
abstract interface class ReminderOccurrenceSchedule {
  Future<DateTime?> occurrenceStart(StableId occurrenceId);
}

class InMemoryReminderRepository implements ReminderRepository {
  final Map<StableId, ReminderRule> _rules = {};
  final Map<StableId, ReminderInstance> _instances = {};

  @override
  Future<List<ReminderRule>> listRules() async =>
      List.unmodifiable(_rules.values);

  @override
  Future<List<ReminderInstance>> listInstances() async =>
      List.unmodifiable(_instances.values);

  @override
  Future<void> saveRule(ReminderRule rule) async => _rules[rule.id] = rule;

  @override
  Future<void> saveInstance(ReminderInstance instance) async =>
      _instances[instance.id] = instance;
}

class ReminderService {
  ReminderService({required this.repository, required this.platform});

  final ReminderRepository repository;
  final ReminderPlatformAdapter platform;

  Future<ReminderInstance> schedule({
    required ReminderRule rule,
    required DateTime occurrenceStart,
  }) => CommandGate.runFor(repository, () async {
    final existing = await repository.listInstances();
    final scheduled = ReminderInstance.fromRule(
      rule: rule,
      occurrenceStart: occurrenceStart,
    );
    final stale = existing
        .where(
          (item) =>
              item.ruleId == rule.id &&
              item.status != ReminderInstanceStatus.delivered &&
              (item.scheduledAt.toUtc() != scheduled.scheduledAt.toUtc() ||
                  !rule.enabled),
        )
        .toList();
    final duplicate = existing.where(
      (item) =>
          item.ruleId == rule.id &&
          item.occurrenceId == rule.occurrenceId &&
          item.scheduledAt.toUtc() == scheduled.scheduledAt.toUtc(),
    );
    final previous = duplicate.isEmpty ? scheduled : duplicate.first;
    final effective = previous.status == ReminderInstanceStatus.delivered
        ? previous
        : !rule.enabled
        ? previous.cancel()
        : previous.status == ReminderInstanceStatus.cancelled
        ? previous.reschedule(previous.scheduledAt)
        : previous;
    await _persistIntent(() async {
      await repository.saveRule(rule);
      for (final old in stale) {
        await repository.saveInstance(old.cancel());
      }
      await repository.saveInstance(effective);
    });
    for (final old in stale) {
      await platform.cancel(old);
    }
    if (rule.enabled && effective.status != ReminderInstanceStatus.delivered) {
      await platform.schedule(effective);
    }
    return effective;
  });

  Future<T> _persistIntent<T>(Future<T> Function() action) =>
      repository is ReminderIntentTransaction
      ? (repository as ReminderIntentTransaction).runReminderTransaction(action)
      : action();

  /// Synchronizes a user-edited occurrence using its durable rules.
  Future<void> synchronizeOccurrence({
    required StableId occurrenceId,
    required DateTime? occurrenceStart,
    required bool resolved,
  }) => CommandGate.runFor(repository, () async {
    if (resolved) {
      for (final instance in await repository.listInstances()) {
        if (instance.occurrenceId == occurrenceId &&
            instance.status != ReminderInstanceStatus.delivered) {
          await cancel(instance);
        }
      }
      return;
    }
    if (occurrenceStart == null) return;
    var denied = false;
    for (final rule in await repository.listRules()) {
      if (rule.occurrenceId != occurrenceId) continue;
      try {
        await schedule(rule: rule, occurrenceStart: occurrenceStart);
      } on ReminderPermissionUnavailable {
        denied = true;
      }
    }
    if (denied) throw const ReminderPermissionUnavailable();
  });

  Future<void> cancel(ReminderInstance instance) =>
      CommandGate.runFor(repository, () async {
        if (instance.status != ReminderInstanceStatus.cancelled) {
          await repository.saveInstance(instance.cancel());
        }
        // A previous cancellation may have persisted but failed on Android.
        // Always retry the idempotent platform operation.
        await platform.cancel(instance);
      });

  Future<ReminderInstance> snooze(ReminderInstance instance, DateTime until) =>
      CommandGate.runFor(repository, () async {
        final snoozed = instance.snoozeUntil(until);
        await repository.saveInstance(snoozed);
        await platform.cancel(instance);
        await platform.schedule(snoozed);
        return snoozed;
      });

  /// Rebuilds platform notifications after restart and removes stale ones.
  ///
  /// The persisted UTC instant is the sole scheduling source of truth. The
  /// platform adapter only translates it into an Android alarm.
  Future<void> reconcile({required DateTime now}) => CommandGate.runFor(
    repository,
    () async {
      final rules = await repository.listRules();
      // A committed rule/occurrence may outlive an interrupted platform phase.
      // Repair missing and stale active intent before rebuilding Android state.
      await _persistIntent(() async {
        if (repository case final ReminderOccurrenceSchedule source) {
          for (final rule in rules.where((rule) => rule.enabled)) {
            final eligible =
                repository is! ReminderOccurrenceEligibility ||
                await (repository as ReminderOccurrenceEligibility).canRemind(
                  rule.occurrenceId,
                );
            if (!eligible) continue;
            final start = await source.occurrenceStart(rule.occurrenceId);
            if (start == null) continue;
            final expected = ReminderInstance.fromRule(
              rule: rule,
              occurrenceStart: start,
            );
            final owned = (await repository.listInstances()).where(
              (item) => item.ruleId == rule.id,
            );
            final needsRepair =
                owned.isEmpty ||
                (owned.every(
                      (item) => item.scheduledAt != expected.scheduledAt,
                    ) &&
                    owned.every(
                      (item) => item.status != ReminderInstanceStatus.delivered,
                    )) ||
                owned.any(
                  (item) =>
                      (item.status == ReminderInstanceStatus.scheduled ||
                          item.status == ReminderInstanceStatus.snoozed) &&
                      item.scheduledAt != expected.scheduledAt,
                );
            if (needsRepair) {
              // Platform errors are reported by the normal rebuild below.
              // Persist the complete target first, even if old cancellation fails.
              for (final old in owned.where(
                (item) =>
                    item.status != ReminderInstanceStatus.delivered &&
                    item.scheduledAt != expected.scheduledAt,
              )) {
                await repository.saveInstance(old.cancel());
              }
              final matching = owned.where(
                (item) => item.scheduledAt == expected.scheduledAt,
              );
              if (matching.isEmpty) {
                await repository.saveInstance(expected);
              } else if (matching.first.status ==
                  ReminderInstanceStatus.cancelled) {
                await repository.saveInstance(
                  matching.first.reschedule(expected.scheduledAt),
                );
              }
            }
          }
        }
      });
      final instances = await repository.listInstances();
      final enabledRuleIds = rules
          .where((rule) => rule.enabled)
          .map((rule) => rule.id)
          .toSet();
      final activeIds = <String>{};
      var permissionUnavailable = false;
      for (final instance in instances) {
        final active =
            instance.status == ReminderInstanceStatus.scheduled ||
            instance.status == ReminderInstanceStatus.snoozed;
        final effectiveAt = instance.status == ReminderInstanceStatus.snoozed
            ? instance.snoozedUntil ?? instance.scheduledAt
            : instance.scheduledAt;
        if (!active) {
          // Platform cleanup must not rewrite delivered notification history.
          await platform.cancel(instance);
          continue;
        }
        final eligible =
            repository is! ReminderOccurrenceEligibility ||
            await (repository as ReminderOccurrenceEligibility).canRemind(
              instance.occurrenceId,
            );
        if (!enabledRuleIds.contains(instance.ruleId) ||
            !eligible ||
            !effectiveAt.isAfter(now)) {
          final persisted = instance.cancel();
          await repository.saveInstance(persisted);
          await platform.cancel(instance);
        } else {
          activeIds.add(instance.id.value);
          try {
            await platform.schedule(instance);
          } on ReminderPermissionUnavailable {
            permissionUnavailable = true;
          }
        }
      }
      if (platform case final ReminderPlatformInventory inventory) {
        await inventory.removeOrphans(activeIds);
      }
      if (permissionUnavailable) {
        throw const ReminderPermissionUnavailable();
      }
    },
  );
}
