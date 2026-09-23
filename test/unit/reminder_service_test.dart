import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/reminders/application/reminder_service.dart';
import 'package:planact/features/reminders/domain/reminder.dart';

class _FakeAdapter implements ReminderPlatformAdapter {
  final scheduled = <StableId>[];
  final cancelled = <StableId>[];

  @override
  Future<void> schedule(ReminderInstance instance) async {
    scheduled.add(instance.id);
  }

  @override
  Future<void> cancel(ReminderInstance instance) async {
    cancelled.add(instance.id);
  }
}

void main() {
  late InMemoryReminderRepository repository;
  late _FakeAdapter adapter;
  late ReminderService service;
  late StableId occurrenceId;

  setUp(() {
    repository = InMemoryReminderRepository();
    adapter = _FakeAdapter();
    service = ReminderService(repository: repository, platform: adapter);
    occurrenceId = StableId.generate();
  });

  test(
    'scheduling is idempotent and does not duplicate platform notifications',
    () async {
      final rule = ReminderRule.beforeOccurrence(
        occurrenceId: occurrenceId,
        offset: const Duration(hours: 1),
      );
      final start = DateTime.utc(2026, 1, 10, 18);

      final first = await service.schedule(rule: rule, occurrenceStart: start);
      final second = await service.schedule(rule: rule, occurrenceStart: start);

      expect(second.id, first.id);
      expect((await repository.listInstances()).length, 1);
      expect(adapter.scheduled, [first.id]);
    },
  );

  test(
    'cancel is idempotent and removes the active platform notification',
    () async {
      final rule = ReminderRule.atOccurrence(occurrenceId: occurrenceId);
      final instance = await service.schedule(
        rule: rule,
        occurrenceStart: DateTime.utc(2026, 1, 10, 18),
      );

      await service.cancel(instance);
      await service.cancel(instance.cancel());

      expect(
        (await repository.listInstances()).single.status,
        ReminderInstanceStatus.cancelled,
      );
      expect(adapter.cancelled, [instance.id]);
    },
  );

  test(
    'reconcile cancels stale instances and rebuilds active future ones',
    () async {
      final futureRule = ReminderRule.atOccurrence(occurrenceId: occurrenceId);
      final future = await service.schedule(
        rule: futureRule,
        occurrenceStart: DateTime.utc(2026, 1, 10, 18),
      );
      final pastRule = ReminderRule.atOccurrence(
        occurrenceId: StableId.generate(),
      );
      await service.schedule(
        rule: pastRule,
        occurrenceStart: DateTime.utc(2026, 1, 9, 18),
      );

      adapter.scheduled.clear();
      adapter.cancelled.clear();
      await service.reconcile(now: DateTime.utc(2026, 1, 10));

      expect(adapter.scheduled, [future.id]);
      expect(adapter.cancelled.length, 1);
    },
  );
}
