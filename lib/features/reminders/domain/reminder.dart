import 'package:planact/core/errors/app_error.dart';
import 'package:planact/core/ids/stable_id.dart';

/// The reference point used to calculate a reminder's delivery time.
enum ReminderAnchor { occurrenceStart, absolute }

enum ReminderInstanceStatus { scheduled, cancelled, delivered, snoozed }

class ReminderRule {
  ReminderRule({
    required this.id,
    required this.occurrenceId,
    required this.anchor,
    this.offset = Duration.zero,
    this.absoluteAt,
    this.title,
    this.body,
    this.enabled = true,
  }) {
    if (anchor == ReminderAnchor.absolute && absoluteAt == null) {
      throw const ValidationError('Absolute reminders require a delivery time');
    }
    if (anchor == ReminderAnchor.occurrenceStart && absoluteAt != null) {
      throw const ValidationError(
        'Occurrence reminders cannot have an absolute delivery time',
      );
    }
    if (title != null && title!.trim().isEmpty) {
      throw const ValidationError('Reminder title cannot be blank');
    }
  }

  factory ReminderRule.beforeOccurrence({
    required StableId occurrenceId,
    required Duration offset,
    String? title,
    String? body,
  }) => ReminderRule(
    id: StableId.generate(),
    occurrenceId: occurrenceId,
    anchor: ReminderAnchor.occurrenceStart,
    offset: -offset.abs(),
    title: title,
    body: body,
  );

  factory ReminderRule.atOccurrence({
    required StableId occurrenceId,
    String? title,
    String? body,
  }) => ReminderRule(
    id: StableId.generate(),
    occurrenceId: occurrenceId,
    anchor: ReminderAnchor.occurrenceStart,
    title: title,
    body: body,
  );

  final StableId id;
  final StableId occurrenceId;
  final ReminderAnchor anchor;
  final Duration offset;
  final DateTime? absoluteAt;
  final String? title;
  final String? body;
  final bool enabled;

  ReminderRule disable() => _copyWith(enabled: false);
  ReminderRule enable() => _copyWith(enabled: true);

  ReminderRule _copyWith({required bool enabled}) => ReminderRule(
    id: id,
    occurrenceId: occurrenceId,
    anchor: anchor,
    offset: offset,
    absoluteAt: absoluteAt,
    title: title,
    body: body,
    enabled: enabled,
  );
}

class ReminderInstance {
  ReminderInstance({
    required this.id,
    required this.ruleId,
    required this.occurrenceId,
    required this.scheduledAt,
    this.status = ReminderInstanceStatus.scheduled,
    this.snoozedUntil,
    this.platformNotificationId,
  }) {
    if (snoozedUntil != null && status != ReminderInstanceStatus.snoozed) {
      throw const ValidationError(
        'Only snoozed reminders can have a snooze time',
      );
    }
  }

  factory ReminderInstance.fromRule({
    required ReminderRule rule,
    required DateTime occurrenceStart,
  }) {
    final scheduledAt = rule.anchor == ReminderAnchor.absolute
        ? rule.absoluteAt!
        : occurrenceStart.add(rule.offset);
    return ReminderInstance(
      id: StableId.generate(timestamp: scheduledAt),
      ruleId: rule.id,
      occurrenceId: rule.occurrenceId,
      scheduledAt: scheduledAt.toUtc(),
    );
  }

  final StableId id;
  final StableId ruleId;
  final StableId occurrenceId;
  final DateTime scheduledAt;
  final ReminderInstanceStatus status;
  final DateTime? snoozedUntil;

  /// Platform-specific and not portable backup data.
  final String? platformNotificationId;

  ReminderInstance cancel() =>
      _copyWith(status: ReminderInstanceStatus.cancelled);

  ReminderInstance deliver() =>
      _copyWith(status: ReminderInstanceStatus.delivered);

  ReminderInstance snoozeUntil(DateTime instant) => _copyWith(
    status: ReminderInstanceStatus.snoozed,
    snoozedUntil: instant.toUtc(),
  );

  ReminderInstance reschedule(DateTime instant) => ReminderInstance(
    id: id,
    ruleId: ruleId,
    occurrenceId: occurrenceId,
    scheduledAt: instant.toUtc(),
    platformNotificationId: null,
  );

  ReminderInstance _copyWith({
    required ReminderInstanceStatus status,
    DateTime? snoozedUntil,
  }) => ReminderInstance(
    id: id,
    ruleId: ruleId,
    occurrenceId: occurrenceId,
    scheduledAt: scheduledAt,
    status: status,
    snoozedUntil: snoozedUntil,
    platformNotificationId: platformNotificationId,
  );
}

/// Platform-neutral notification operation. Implementations belong in adapters.
abstract interface class ReminderPlatformAdapter {
  Future<void> schedule(ReminderInstance instance);
  Future<void> cancel(ReminderInstance instance);
}
