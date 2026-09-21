import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/errors/app_error.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/reminders/domain/reminder.dart';

void main() {
  final occurrenceId = StableId.generate();

  test('creates an occurrence-relative reminder at the configured offset', () {
    final rule = ReminderRule.beforeOccurrence(
      occurrenceId: occurrenceId,
      offset: const Duration(hours: 2),
    );
    final instance = ReminderInstance.fromRule(
      rule: rule,
      occurrenceStart: DateTime.utc(2026, 1, 10, 18),
    );

    expect(instance.scheduledAt, DateTime.utc(2026, 1, 10, 16));
    expect(instance.status, ReminderInstanceStatus.scheduled);
  });

  test('supports absolute reminders without changing the rule on snooze', () {
    final rule = ReminderRule(
      id: StableId.generate(),
      occurrenceId: occurrenceId,
      anchor: ReminderAnchor.absolute,
      absoluteAt: DateTime.utc(2026, 1, 10, 16),
    );
    final instance = ReminderInstance.fromRule(
      rule: rule,
      occurrenceStart: DateTime.utc(2026, 1, 10, 18),
    );
    final snoozed = instance.snoozeUntil(DateTime.utc(2026, 1, 10, 17));

    expect(instance.scheduledAt, DateTime.utc(2026, 1, 10, 16));
    expect(snoozed.status, ReminderInstanceStatus.snoozed);
    expect(snoozed.snoozedUntil, DateTime.utc(2026, 1, 10, 17));
    expect(rule.absoluteAt, DateTime.utc(2026, 1, 10, 16));
  });

  test('keeps cancellation and delivery as historical states', () {
    final rule = ReminderRule.atOccurrence(occurrenceId: occurrenceId);
    final instance = ReminderInstance.fromRule(
      rule: rule,
      occurrenceStart: DateTime.utc(2026, 1, 10, 18),
    );

    expect(instance.cancel().status, ReminderInstanceStatus.cancelled);
    expect(instance.deliver().status, ReminderInstanceStatus.delivered);
  });

  test('rejects invalid absolute and snooze configurations', () {
    expect(
      () => ReminderRule(
        id: StableId.generate(),
        occurrenceId: occurrenceId,
        anchor: ReminderAnchor.absolute,
      ),
      throwsA(isA<ValidationError>()),
    );
    expect(
      () => ReminderInstance(
        id: StableId.generate(),
        ruleId: StableId.generate(),
        occurrenceId: occurrenceId,
        scheduledAt: DateTime.utc(2026, 1, 10),
        snoozedUntil: DateTime.utc(2026, 1, 10, 1),
      ),
      throwsA(isA<ValidationError>()),
    );
  });
}
