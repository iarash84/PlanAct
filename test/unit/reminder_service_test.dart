import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/reminders/application/reminder_service.dart';
import 'package:planact/features/reminders/domain/reminder.dart';

class _FakeAdapter implements ReminderPlatformAdapter {
  final scheduled = <StableId>[];
  final cancelled = <StableId>[];
  bool failCancellation = false;

  @override
  Future<void> schedule(ReminderInstance instance) async {
    scheduled.add(instance.id);
  }

  @override
  Future<void> cancel(ReminderInstance instance) async {
    cancelled.add(instance.id);
    if (failCancellation) {
      failCancellation = false;
      throw StateError('injected platform cancellation failure');
    }
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
    'scheduling reuses the same platform notification ID on retry',
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
      // The platform schedules by stable ID; retry replaces the same alarm.
      expect(adapter.scheduled, [first.id, first.id]);
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
      expect(adapter.cancelled, [instance.id, instance.id]);
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

  test('reconcile persists cancellation for disabled reminders', () async {
    final disabledRule = ReminderRule.atOccurrence(occurrenceId: occurrenceId)
        .disable();
    final stale = await service.schedule(
      rule: disabledRule,
      occurrenceStart: DateTime.utc(2026, 1, 10, 18),
    );

    await service.reconcile(now: DateTime.utc(2026, 1, 9));

    final persisted = (await repository.listInstances()).single;
    expect(persisted.id, stale.id);
    expect(persisted.status, ReminderInstanceStatus.cancelled);
    expect(adapter.cancelled, [stale.id]);
  });

  test('reconcile keeps future snoozed reminders active', () async {
    final rule = ReminderRule.atOccurrence(occurrenceId: occurrenceId);
    final scheduled = await service.schedule(
      rule: rule,
      occurrenceStart: DateTime.utc(2026, 1, 10, 18),
    );
    final snoozed = await service.snooze(
      scheduled,
      DateTime.utc(2026, 1, 11, 9),
    );

    adapter.scheduled.clear();
    adapter.cancelled.clear();
    await service.reconcile(now: DateTime.utc(2026, 1, 10, 20));

    expect(adapter.scheduled, [snoozed.id]);
    expect(adapter.cancelled, isEmpty);
  });

  test(
    'cancel retries Android after a persisted cancellation failure',
    () async {
      final instance = await service.schedule(
        rule: ReminderRule.atOccurrence(occurrenceId: occurrenceId),
        occurrenceStart: DateTime.utc(2026, 1, 10),
      );
      adapter.failCancellation = true;
      await expectLater(service.cancel(instance), throwsStateError);
      final persisted = (await repository.listInstances()).single;
      expect(persisted.status, ReminderInstanceStatus.cancelled);
      await service.cancel(persisted);
      expect(adapter.cancelled, [instance.id, instance.id]);
    },
  );

  test(
    'changed delivery cancels the previous durable and platform intent',
    () async {
      final rule = ReminderRule.atOccurrence(occurrenceId: occurrenceId);
      final first = await service.schedule(
        rule: rule,
        occurrenceStart: DateTime.utc(2026, 1, 10),
      );
      final second = await service.schedule(
        rule: rule,
        occurrenceStart: DateTime.utc(2026, 1, 11),
      );
      expect(first.id, isNot(second.id));
      final instances = await repository.listInstances();
      expect(instances.first.status, ReminderInstanceStatus.cancelled);
      expect(instances.last.status, ReminderInstanceStatus.scheduled);
      expect(adapter.cancelled, [first.id]);
    },
  );

  test('disable then enable reuses durable identity', () async {
    final rule = ReminderRule.atOccurrence(occurrenceId: occurrenceId);
    final first = await service.schedule(
      rule: rule,
      occurrenceStart: DateTime.utc(2030, 1, 10),
    );
    final disabled = await service.schedule(
      rule: rule.disable(),
      occurrenceStart: first.scheduledAt,
    );
    expect(disabled.status, ReminderInstanceStatus.cancelled);
    final enabled = await service.schedule(
      rule: rule.enable(),
      occurrenceStart: first.scheduledAt,
    );
    expect(enabled.id, first.id);
    expect(enabled.status, ReminderInstanceStatus.scheduled);
    expect(await repository.listInstances(), hasLength(1));
  });

  test('delivered history is not rescheduled by a repeated command', () async {
    final rule = ReminderRule.atOccurrence(occurrenceId: occurrenceId);
    final first = await service.schedule(
      rule: rule,
      occurrenceStart: DateTime.utc(2030, 1, 10),
    );
    await repository.saveInstance(first.deliver());
    adapter.scheduled.clear();
    final repeated = await service.schedule(
      rule: rule,
      occurrenceStart: first.scheduledAt,
    );
    expect(repeated.status, ReminderInstanceStatus.delivered);
    expect(adapter.scheduled, isEmpty);
  });

  test('cancelling a snoozed reminder clears the snooze timestamp', () async {
    final rule = ReminderRule.atOccurrence(occurrenceId: occurrenceId);
    final scheduled = await service.schedule(
      rule: rule,
      occurrenceStart: DateTime.utc(2026, 1, 10, 18),
    );
    final snoozed = await service.snooze(
      scheduled,
      DateTime.utc(2026, 1, 11, 9),
    );

    final cancelled = snoozed.cancel();

    expect(cancelled.status, ReminderInstanceStatus.cancelled);
    expect(cancelled.snoozedUntil, isNull);
  });
}
