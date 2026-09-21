import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/reminders/application/reminder_service.dart';
import 'package:planact/features/reminders/domain/reminder.dart';

class _RecordingAdapter implements ReminderPlatformAdapter {
  final scheduled = <ReminderInstance>[];
  final cancelled = <ReminderInstance>[];

  @override
  Future<void> schedule(ReminderInstance instance) async {
    scheduled.add(instance);
  }

  @override
  Future<void> cancel(ReminderInstance instance) async {
    cancelled.add(instance);
  }
}

void main() {
  test(
    'reconcile after restart rebuilds notifications from persisted state',
    () async {
      final repository = InMemoryReminderRepository();
      final firstAdapter = _RecordingAdapter();
      final firstService = ReminderService(
        repository: repository,
        platform: firstAdapter,
      );
      final rule = ReminderRule.beforeOccurrence(
        occurrenceId: StableId.generate(),
        offset: const Duration(hours: 1),
      );
      final instance = await firstService.schedule(
        rule: rule,
        occurrenceStart: DateTime.utc(2026, 2, 1, 18),
      );

      final restartedAdapter = _RecordingAdapter();
      final restartedService = ReminderService(
        repository: repository,
        platform: restartedAdapter,
      );
      await restartedService.reconcile(now: DateTime.utc(2026, 2, 1));

      expect(restartedAdapter.scheduled.single.id, instance.id);
      expect(restartedAdapter.scheduled.single.platformNotificationId, isNull);
    },
  );

  test('reschedule cancels the old platform operation before scheduling the new time', () async {
    final repository = InMemoryReminderRepository();
    final adapter = _RecordingAdapter();
    final service = ReminderService(repository: repository, platform: adapter);
    final rule = ReminderRule.atOccurrence(occurrenceId: StableId.generate());
    final original = await service.schedule(
      rule: rule,
      occurrenceStart: DateTime.utc(2026, 2, 1, 18),
    );

    final rescheduled = original.reschedule(DateTime.utc(2026, 2, 1, 19));
    await service.cancel(original);
    await service.schedule(
      rule: rule,
      occurrenceStart: DateTime.utc(2026, 2, 1, 19),
    );

    expect(adapter.cancelled.single.id, original.id);
    expect(adapter.scheduled.length, 2);
    expect(rescheduled.scheduledAt, DateTime.utc(2026, 2, 1, 19));
  });

  test('offline operation remains domain-persistable without a platform adapter call', () async {
    final repository = InMemoryReminderRepository();
    final adapter = _RecordingAdapter();
    final service = ReminderService(repository: repository, platform: adapter);
    final rule = ReminderRule.atOccurrence(occurrenceId: StableId.generate());
    final instance = await service.schedule(
      rule: rule,
      occurrenceStart: DateTime.utc(2026, 2, 1, 18),
    );

    expect((await repository.listRules()).single.id, rule.id);
    expect((await repository.listInstances()).single.id, instance.id);
    expect(adapter.scheduled, hasLength(1));
  });
}
