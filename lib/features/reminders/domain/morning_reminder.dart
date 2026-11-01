import 'package:planact/features/reminders/domain/reminder.dart';

/// User-configurable local morning window. The end may be on the same day only.
class MorningReminderWindow {
  const MorningReminderWindow({
    required this.startMinutes,
    required this.endMinutes,
  }) : assert(startMinutes >= 0 && startMinutes < 1440),
       assert(endMinutes > 0 && endMinutes <= 1440),
       assert(startMinutes < endMinutes);

  static const defaultWindow = MorningReminderWindow(
    startMinutes: 6 * 60,
    endMinutes: 10 * 60,
  );

  final int startMinutes;
  final int endMinutes;

  bool contains(DateTime localTime) {
    final minutes = localTime.hour * 60 + localTime.minute;
    return minutes >= startMinutes && minutes < endMinutes;
  }

  String get storageValue => '$startMinutes:$endMinutes';

  static MorningReminderWindow parse(String? value) {
    if (value == null) return defaultWindow;
    final parts = value.split(':');
    if (parts.length != 2) return defaultWindow;
    final start = int.tryParse(parts[0]);
    final end = int.tryParse(parts[1]);
    if (start == null ||
        end == null ||
        start < 0 ||
        start >= end ||
        end > 1440) {
      return defaultWindow;
    }
    return MorningReminderWindow(startMinutes: start, endMinutes: end);
  }
}

/// Pure decision used by both the Flutter coordinator and unit tests.
bool shouldSendMorningReminder({
  required bool enabled,
  required bool alreadySentToday,
  required DateTime localNow,
  required MorningReminderWindow window,
  required bool hasEligibleTodayReminder,
}) =>
    enabled &&
    !alreadySentToday &&
    window.contains(localNow) &&
    hasEligibleTodayReminder;

String morningReminderDayKey(DateTime localDate) =>
    '${localDate.year.toString().padLeft(4, '0')}-'
    '${localDate.month.toString().padLeft(2, '0')}-'
    '${localDate.day.toString().padLeft(2, '0')}';

/// A reminder rule is eligible only when it is enabled and its materialized
/// instance is still scheduled for the requested local civil day.
bool isEligibleMorningReminder({
  required ReminderRule rule,
  required ReminderInstance instance,
  required DateTime localDate,
  required bool occurrenceCanRemind,
}) {
  if (!rule.enabled || !occurrenceCanRemind) return false;
  if (instance.ruleId != rule.id ||
      instance.occurrenceId != rule.occurrenceId) {
    return false;
  }
  if (instance.status != ReminderInstanceStatus.scheduled &&
      instance.status != ReminderInstanceStatus.snoozed) {
    return false;
  }
  final scheduled = instance.scheduledAt.toLocal();
  return scheduled.year == localDate.year &&
      scheduled.month == localDate.month &&
      scheduled.day == localDate.day;
}
