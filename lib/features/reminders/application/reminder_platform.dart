import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:planact/features/reminders/domain/reminder.dart';

/// Initializes Android notification delivery without making notifications a
/// dependency of the reminder domain.
class AndroidReminderPlatformAdapter implements ReminderPlatformAdapter {
  AndroidReminderPlatformAdapter({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    final localTimezone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(localTimezone.identifier));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(
      settings: const InitializationSettings(android: android),
    );
    _initialized = true;
  }

  /// Returns false when the user denies notifications. This is intentionally
  /// non-blocking: planning and persistence continue to work offline.
  Future<bool> requestPermission() async {
    await initialize();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return await android?.requestNotificationsPermission() ?? true;
  }

  @override
  Future<void> schedule(ReminderInstance instance) async {
    await initialize();
    final scheduledAt = instance.status == ReminderInstanceStatus.snoozed
        ? instance.snoozedUntil
        : instance.scheduledAt;
    if (scheduledAt == null || !scheduledAt.isAfter(DateTime.now().toUtc())) {
      return;
    }
    final id = _notificationId(instance);
    await _plugin.zonedSchedule(
      id: id,
      title: 'یادآوری پلن‌اکت',
      body: 'زمان انجام یک تعهد فرا رسیده است.',
      scheduledDate: tz.TZDateTime.from(scheduledAt, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'planact_reminders',
          'یادآوری‌ها',
          channelDescription: 'یادآوری تعهدهای پلن‌اکت',
          importance: Importance.high,
          priority: Priority.high,
          visibility: NotificationVisibility.private,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: instance.id.value,
    );
  }

  @override
  Future<void> cancel(ReminderInstance instance) async {
    await initialize();
    await _plugin.cancel(id: _notificationId(instance));
  }

  int _notificationId(ReminderInstance instance) =>
      instance.id.value.hashCode & 0x7fffffff;
}
