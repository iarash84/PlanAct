import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/reminders/domain/morning_reminder.dart';
import 'package:planact/features/reminders/domain/reminder.dart';

ReminderRule defaultReminderRule({bool enabled = true}) => ReminderRule(
  id: StableId.generate(),
  occurrenceId: StableId.generate(),
  anchor: ReminderAnchor.absolute,
  offset: Duration.zero,
  absoluteAt: DateTime.utc(2026, 10, 25, 7),
  title: 'یادآوری',
  body: 'بدنه',
  enabled: enabled,
);

void main() {
  group('MorningReminderWindow', () {
    test('uses the documented 06:00–10:00 default window', () {
      const window = MorningReminderWindow.defaultWindow;

      expect(window.contains(DateTime(2026, 10, 25, 5, 59)), isFalse);
      expect(window.contains(DateTime(2026, 10, 25, 6)), isTrue);
      expect(window.contains(DateTime(2026, 10, 25, 9, 59)), isTrue);
      expect(window.contains(DateTime(2026, 10, 25, 10)), isFalse);
    });

    test('round-trips valid storage and falls back for invalid storage', () {
      const custom = MorningReminderWindow(startMinutes: 90, endMinutes: 240);

      expect(MorningReminderWindow.parse(custom.storageValue).startMinutes, 90);
      expect(MorningReminderWindow.parse(custom.storageValue).endMinutes, 240);
      expect(
        MorningReminderWindow.parse('invalid').storageValue,
        MorningReminderWindow.defaultWindow.storageValue,
      );
      expect(
        MorningReminderWindow.parse('600:600').storageValue,
        MorningReminderWindow.defaultWindow.storageValue,
      );
    });
  });

  group('morning reminder eligibility', () {
    test('requires enabled state, current-day scheduled instance and eligible occurrence', () {
      final rule = defaultReminderRule();
      final instance = ReminderInstance.fromRule(
        rule: rule,
        occurrenceStart: DateTime.utc(2026, 10, 25, 7),
      );
      final localDate = DateTime(2026, 10, 25, 8);

      expect(
        isEligibleMorningReminder(
          rule: rule,
          instance: instance,
          localDate: localDate,
          occurrenceCanRemind: true,
        ),
        isTrue,
      );
      expect(
        isEligibleMorningReminder(
          rule: rule,
          instance: instance,
          localDate: localDate,
          occurrenceCanRemind: false,
        ),
        isFalse,
      );
    });

    test('rejects disabled, historical, and different-day instances', () {
      final rule = defaultReminderRule();
      final instance = ReminderInstance.fromRule(
        rule: rule,
        occurrenceStart: DateTime.utc(2026, 10, 25, 7),
      );

      expect(
        isEligibleMorningReminder(
          rule: rule.disable(),
          instance: instance,
          localDate: DateTime(2026, 10, 25),
          occurrenceCanRemind: true,
        ),
        isFalse,
      );
      expect(
        isEligibleMorningReminder(
          rule: rule,
          instance: instance.deliver(),
          localDate: DateTime(2026, 10, 25),
          occurrenceCanRemind: true,
        ),
        isFalse,
      );
      expect(
        isEligibleMorningReminder(
          rule: rule,
          instance: instance,
          localDate: DateTime(2026, 10, 26),
          occurrenceCanRemind: true,
        ),
        isFalse,
      );
    });
  });

  group('morning reminder decision', () {
    test('sends only once when inside the configured window', () {
      const window = MorningReminderWindow.defaultWindow;
      final now = DateTime(2026, 10, 25, 8);

      expect(
        shouldSendMorningReminder(
          enabled: true,
          alreadySentToday: false,
          localNow: now,
          window: window,
          hasEligibleTodayReminder: true,
        ),
        isTrue,
      );
      expect(
        shouldSendMorningReminder(
          enabled: true,
          alreadySentToday: true,
          localNow: now,
          window: window,
          hasEligibleTodayReminder: true,
        ),
        isFalse,
      );
      expect(
        shouldSendMorningReminder(
          enabled: true,
          alreadySentToday: false,
          localNow: now,
          window: window,
          hasEligibleTodayReminder: false,
        ),
        isFalse,
      );
    });

    test('formats a stable local civil-day key', () {
      expect(morningReminderDayKey(DateTime(2026, 1, 2, 23, 59)), '2026-01-02');
    });
  });
}
