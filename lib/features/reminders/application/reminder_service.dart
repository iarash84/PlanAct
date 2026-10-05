import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/reminders/domain/reminder.dart';

abstract interface class ReminderRepository {
  Future<List<ReminderRule>> listRules();
  Future<List<ReminderInstance>> listInstances();
  Future<void> saveRule(ReminderRule rule);
  Future<void> saveInstance(ReminderInstance instance);
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
  }) async {
    await repository.saveRule(rule);
    final existing = await repository.listInstances();
    final scheduled = ReminderInstance.fromRule(
      rule: rule,
      occurrenceStart: occurrenceStart,
    );
    final duplicate = existing.where(
      (item) =>
          item.ruleId == rule.id &&
          item.occurrenceId == rule.occurrenceId &&
          item.scheduledAt.toUtc() == scheduled.scheduledAt.toUtc() &&
          item.status != ReminderInstanceStatus.cancelled,
    );
    if (duplicate.isNotEmpty) {
      // A previous platform attempt may have failed after the durable write.
      // Retrying must not mistake the persisted intent for delivered scheduling.
      if (rule.enabled) await platform.schedule(duplicate.first);
      return duplicate.first;
    }
    await repository.saveInstance(scheduled);
    if (rule.enabled) await platform.schedule(scheduled);
    return scheduled;
  }

  Future<void> cancel(ReminderInstance instance) async {
    if (instance.status == ReminderInstanceStatus.cancelled) return;
    final cancelled = instance.cancel();
    await repository.saveInstance(cancelled);
    await platform.cancel(instance);
  }

  Future<ReminderInstance> snooze(
    ReminderInstance instance,
    DateTime until,
  ) async {
    final snoozed = instance.snoozeUntil(until);
    await repository.saveInstance(snoozed);
    await platform.cancel(instance);
    await platform.schedule(snoozed);
    return snoozed;
  }

  /// Rebuilds platform notifications after restart and removes stale ones.
  ///
  /// The persisted UTC instant is the sole scheduling source of truth. The
  /// platform adapter only translates it into an Android alarm.
  Future<void> reconcile({required DateTime now}) async {
    final rules = await repository.listRules();
    final instances = await repository.listInstances();
    final enabledRuleIds = rules
        .where((rule) => rule.enabled)
        .map((rule) => rule.id)
        .toSet();
    for (final instance in instances) {
      final active =
          instance.status == ReminderInstanceStatus.scheduled ||
          instance.status == ReminderInstanceStatus.snoozed;
      final effectiveAt = instance.status == ReminderInstanceStatus.snoozed
          ? instance.snoozedUntil ?? instance.scheduledAt
          : instance.scheduledAt;
      if (!enabledRuleIds.contains(instance.ruleId) ||
          !active ||
          !effectiveAt.isAfter(now)) {
        final persisted = instance.cancel();
        await repository.saveInstance(persisted);
        await platform.cancel(instance);
      } else {
        await platform.schedule(instance);
      }
    }
  }
}
