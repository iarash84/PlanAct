import 'package:planact/core/application/command_gate.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/reminders/domain/reminder.dart';

import 'package:planact/app/app_settings.dart';
import 'package:planact/features/reminders/domain/morning_reminder.dart';

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

/// Native alarm controls may commit while Flutter is not running or is resuming.
abstract interface class ReminderFreshInstance {
  Future<ReminderInstance?> findInstance(StableId id);
}

/// Delivers the morning reminder after the native unlock trigger has admitted it.
///
/// Android receives the unlock broadcast in a native receiver so delivery does
/// not depend on a running Flutter engine.
abstract interface class MorningReminderPlatform {
  Future<bool> notificationsEnabled();
  Future<void> showMorningReminder();
}

abstract interface class ReminderIntentTransaction {
  Future<T> runReminderTransaction<T>(Future<T> Function() action);
}

/// Persistent adapters reject resolved occurrences and inactive owners/cycles.
abstract interface class ReminderOccurrenceEligibility {
  Future<bool> canRemind(StableId occurrenceId);
}

/// Rebuilds missing or stale reminder intent from the durable occurrence.
abstract interface class ReminderOccurrenceSchedule {
  Future<DateTime?> occurrenceStart(StableId occurrenceId);
}

abstract interface class ReminderOccurrenceReopeningIntent {
  Future<bool> hasPendingReopening(StableId occurrenceId);
  Future<void> finishReopening(StableId occurrenceId);
}

/// Application-facing seam for the daily, unlock-triggered reminder.
///
/// The production Android receiver performs the unlock-triggered claim directly
/// against the durable database. This seam remains useful for foreground
/// coordination and platform-independent tests.
abstract interface class MorningReminderStore {
  Future<bool> hasEligibleReminderForLocalDate(DateTime localDate);
  Future<bool> claimMorningReminder(String localDayKey);
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

class MorningReminderCoordinator {
  MorningReminderCoordinator({
    required this.settings,
    required this.store,
    required this.platform,
    this.now = DateTime.now,
  });

  final AppSettings settings;
  final MorningReminderStore store;
  final MorningReminderPlatform platform;
  final DateTime Function() now;

  Future<bool> onDeviceUnlocked() async {
    if (!await settings.readMorningReminderEnabled()) return false;
    final localNow = now().toLocal();
    final window = await settings.readMorningReminderWindow();
    if (!window.contains(localNow)) return false;
    if (!await platform.notificationsEnabled()) return false;
    final hasReminder = await store.hasEligibleReminderForLocalDate(localNow);
    if (!hasReminder) return false;
    final dayKey = morningReminderDayKey(localNow);
    if (!await store.claimMorningReminder(dayKey)) return false;
    await platform.showMorningReminder();
    return true;
  }
}

class ReminderService {
  ReminderService({required this.repository, required this.platform});

  final ReminderRepository repository;
  final ReminderPlatformAdapter platform;

  Future<ReminderInstance> schedule({
    required ReminderRule rule,
    required DateTime occurrenceStart,
  }) => CommandGate.runFor(repository, () async {
    final intent = await _persistIntent(
      () => _prepareSchedulingIntent(rule, occurrenceStart),
    );
    await _deliverSchedulingIntent(intent);
    return intent.instance;
  });

  Future<_ReminderSchedulingIntent> _prepareSchedulingIntent(
    ReminderRule rule,
    DateTime occurrenceStart,
  ) async {
    // Called inside writer admission, so eligibility uses fresh durable state.
    final eligible =
        repository is! ReminderOccurrenceEligibility ||
        await (repository as ReminderOccurrenceEligibility).canRemind(
          rule.occurrenceId,
        );
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
                  !rule.enabled ||
                  !eligible),
        )
        .toList();
    final duplicate = existing.where(
      (item) =>
          item.ruleId == rule.id &&
          item.occurrenceId == rule.occurrenceId &&
          item.scheduledAt.toUtc() == scheduled.scheduledAt.toUtc(),
    );
    final previous = duplicate.isEmpty ? scheduled : duplicate.first;
    if (previous.delivery != rule.delivery) {
      throw StateError(
        'Changing delivery requires a replacement reminder rule.',
      );
    }
    final effective = previous.status == ReminderInstanceStatus.delivered
        ? previous
        : !rule.enabled || !eligible
        ? previous.cancel()
        : previous.status == ReminderInstanceStatus.cancelled
        ? previous.reschedule(previous.scheduledAt)
        : previous;
    await repository.saveRule(rule);
    for (final old in stale) {
      await repository.saveInstance(old.cancel());
    }
    // A cancelled replacement at the new time would suppress normal recovery
    // when the owner is restored. Keep existing history and derive it on resume.
    if (eligible || duplicate.isNotEmpty) {
      await repository.saveInstance(effective);
    }
    return _ReminderSchedulingIntent(
      instance: effective,
      cancelled: [
        ...stale,
        // A delivered alarm may still be sounding. Stop its platform playback
        // after a time change without rewriting delivery history.
        ...existing.where(
          (item) =>
              item.ruleId == rule.id &&
              item.status == ReminderInstanceStatus.delivered &&
              (item.scheduledAt.toUtc() != scheduled.scheduledAt.toUtc() ||
                  !eligible ||
                  !rule.enabled),
        ),
      ],
      enabled: rule.enabled && eligible,
    );
  }

  Future<void> _deliverSchedulingIntent(
    _ReminderSchedulingIntent intent,
  ) async {
    for (final old in intent.cancelled) {
      await platform.cancel(old);
    }
    if (intent.enabled &&
        intent.instance.status != ReminderInstanceStatus.delivered) {
      await platform.schedule(intent.instance);
    }
  }

  Future<T> _persistIntent<T>(Future<T> Function() action) =>
      repository is ReminderIntentTransaction
      ? (repository as ReminderIntentTransaction).runReminderTransaction(action)
      : action();

  /// Replaces this occurrence's enabled rules without deleting delivery history.
  /// Returns true when durable changes succeeded but platform delivery is pending.
  Future<bool> editOccurrenceRules({
    required StableId occurrenceId,
    required List<ReminderRule> expected,
    required List<ReminderRule> selected,
    required DateTime now,
  }) => CommandGate.runFor(repository, () async {
    if (repository is! ReminderIntentTransaction ||
        repository is! ReminderOccurrenceSchedule ||
        repository is! ReminderOccurrenceEligibility) {
      throw StateError(
        'Durable reminder editing requires transactional storage.',
      );
    }
    await _persistIntent(() async {
      if (!await (repository as ReminderOccurrenceEligibility).canRemind(
        occurrenceId,
      )) {
        throw StateError('Resolved occurrences cannot receive reminder edits.');
      }
      final current = (await repository.listRules())
          .where((rule) => rule.occurrenceId == occurrenceId && rule.enabled)
          .toList();
      Object fingerprint(ReminderRule rule) => (
        rule.id,
        rule.occurrenceId,
        rule.anchor,
        rule.offset.inSeconds,
        rule.absoluteAt?.toUtc(),
        rule.title,
        rule.body,
        rule.enabled,
        rule.delivery,
      );
      final before = current.map(fingerprint).toSet();
      if (before.length != expected.length ||
          !before.containsAll(expected.map(fingerprint))) {
        throw StateError(
          'Reminder configuration changed; reload before saving.',
        );
      }
      final start = await (repository as ReminderOccurrenceSchedule)
          .occurrenceStart(occurrenceId);
      final allIds = (await repository.listRules())
          .map((rule) => rule.id)
          .toSet();
      final selectedIds = <StableId>{};
      for (final rule in selected) {
        if (rule.occurrenceId != occurrenceId ||
            !rule.enabled ||
            !selectedIds.add(rule.id) ||
            (allIds.contains(rule.id) && !before.contains(fingerprint(rule))) ||
            (start == null && rule.anchor == ReminderAnchor.occurrenceStart)) {
          throw StateError('Invalid reminder selection.');
        }
      }
      for (final rule in current) {
        if (!selectedIds.contains(rule.id)) {
          await repository.saveRule(rule.disable());
        }
      }
      final instances = await repository.listInstances();
      for (final instance in instances) {
        if (instance.occurrenceId == occurrenceId &&
            !selectedIds.contains(instance.ruleId) &&
            (instance.status == ReminderInstanceStatus.scheduled ||
                instance.status == ReminderInstanceStatus.snoozed)) {
          await repository.saveInstance(instance.cancel());
        }
      }
      for (final rule in selected) {
        await repository.saveRule(rule);
        if (!allIds.contains(rule.id)) {
          await repository.saveInstance(
            ReminderInstance.fromRule(
              rule: rule,
              occurrenceStart: start ?? rule.absoluteAt!,
            ),
          );
        }
      }
    });
    try {
      await reconcile(now: now);
      return false;
    } catch (_) {
      // The configuration is already committed; retry delivery on reconciliation.
      return true;
    }
  });

  /// Synchronizes a user-edited occurrence using its durable rules.
  Future<void> synchronizeOccurrence({
    required StableId occurrenceId,
    required DateTime? occurrenceStart,
    required bool resolved,
  }) => CommandGate.runFor(repository, () async {
    if (resolved) {
      for (final instance in await repository.listInstances()) {
        if (instance.occurrenceId == occurrenceId) {
          if (instance.status == ReminderInstanceStatus.delivered) {
            await platform.cancel(instance);
          } else {
            await cancel(instance);
          }
        }
      }
      return;
    }
    if (occurrenceStart == null) return;
    final intents = await _persistIntent(() async {
      final prepared = <_ReminderSchedulingIntent>[];
      for (final rule in await repository.listRules()) {
        if (rule.occurrenceId != occurrenceId) continue;
        prepared.add(await _prepareSchedulingIntent(rule, occurrenceStart));
      }
      // Consume recovery only with the complete durable replacement intent.
      // Platform failure afterward retries these rows, not the reopening event.
      if (repository case final ReminderOccurrenceReopeningIntent reopening) {
        if (repository is! ReminderOccurrenceEligibility ||
            await (repository as ReminderOccurrenceEligibility).canRemind(
              occurrenceId,
            )) {
          await reopening.finishReopening(occurrenceId);
        }
      }
      return prepared;
    });
    var denied = false;
    for (final intent in intents) {
      try {
        await _deliverSchedulingIntent(intent);
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
        final reopening = <StableId>{};
        if (repository case final ReminderOccurrenceSchedule source) {
          for (final rule in rules.where((rule) => rule.enabled)) {
            final eligible =
                repository is! ReminderOccurrenceEligibility ||
                await (repository as ReminderOccurrenceEligibility).canRemind(
                  rule.occurrenceId,
                );
            if (!eligible) continue;
            if (repository is ReminderOccurrenceReopeningIntent &&
                await (repository as ReminderOccurrenceReopeningIntent)
                    .hasPendingReopening(rule.occurrenceId)) {
              reopening.add(rule.occurrenceId);
            }
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
                (repository is ReminderOccurrenceReopeningIntent &&
                    await (repository as ReminderOccurrenceReopeningIntent)
                        .hasPendingReopening(rule.occurrenceId) &&
                    owned.every(
                      (item) => item.status == ReminderInstanceStatus.cancelled,
                    )) ||
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
        if (repository is ReminderOccurrenceReopeningIntent) {
          for (final id in reopening) {
            await (repository as ReminderOccurrenceReopeningIntent)
                .finishReopening(id);
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
      for (final snapshot in instances) {
        final decision = await _persistIntent(() async {
          final instance = repository is ReminderFreshInstance
              ? await (repository as ReminderFreshInstance).findInstance(
                  snapshot.id,
                )
              : snapshot;
          if (instance == null) return (snapshot, false);
          final active =
              instance.status == ReminderInstanceStatus.scheduled ||
              instance.status == ReminderInstanceStatus.snoozed;
          final effectiveAt = instance.status == ReminderInstanceStatus.snoozed
              ? instance.snoozedUntil ?? instance.scheduledAt
              : instance.scheduledAt;
          if (!active) return (instance, false);
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
            return (persisted, false);
          }
          return (instance, true);
        });
        final (instance, shouldSchedule) = decision;
        if (!shouldSchedule) {
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

/// Durable work is prepared completely before any external platform operation.
class _ReminderSchedulingIntent {
  const _ReminderSchedulingIntent({
    required this.instance,
    required this.cancelled,
    required this.enabled,
  });
  final ReminderInstance instance;
  final List<ReminderInstance> cancelled;
  final bool enabled;
}
