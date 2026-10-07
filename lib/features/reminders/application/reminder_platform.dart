import 'dart:convert';

import 'package:flutter/services.dart';

import 'package:crypto/crypto.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/reminders/application/reminder_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:planact/features/reminders/domain/reminder.dart';

/// Initializes Android notification delivery without making notifications a
/// dependency of the reminder domain.
class AndroidReminderPlatformAdapter
    implements ReminderPlatformAdapter, ReminderPlatformInventory {
  AndroidReminderPlatformAdapter({
    FlutterLocalNotificationsPlugin? plugin,
    MethodChannel? settingsChannel,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
       _settingsChannel =
           settingsChannel ?? const MethodChannel('planact/reminder-settings');

  final FlutterLocalNotificationsPlugin _plugin;
  final MethodChannel _settingsChannel;
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
    if (android == null) return false;
    if (await android.areNotificationsEnabled() ?? false) return true;
    await android.requestNotificationsPermission();
    if (await android.areNotificationsEnabled() ?? false) return true;
    // A runtime prompt cannot re-enable notifications disabled in Settings,
    // including Android <= 12 and permanently denied Android 13+ permission.
    // This method is invoked only after the user's explicit enable action.
    await _settingsChannel.invokeMethod<void>('openNotificationSettings');
    return await android.areNotificationsEnabled() ?? false;
  }

  Future<bool> notificationsEnabled() async {
    await initialize();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return await android?.areNotificationsEnabled() ?? false;
  }

  Future<bool> exactAlarmsEnabled() async {
    await initialize();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return await android?.canScheduleExactNotifications() ?? false;
  }

  Future<bool> requestExactAlarmPermission() async {
    await initialize();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return await android?.requestExactAlarmsPermission() ?? false;
  }

  @override
  Future<void> removeOrphans(Set<String> activeInstanceIds) async {
    await initialize();
    for (final pending in await _plugin.pendingNotificationRequests()) {
      final owner = _instanceOwner(pending.payload);
      if (owner != null && !activeInstanceIds.contains(owner)) {
        await _plugin.cancel(id: pending.id);
      }
    }
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
    // Do not invoke permission prompts during startup or background rebuild.
    // Keep durable intent available for an explicit user-approved retry.
    if (!await notificationsEnabled()) {
      throw const ReminderPermissionUnavailable();
    }
    if (!await exactAlarmsEnabled()) {
      throw const ReminderPermissionUnavailable();
    }
    final id = _notificationId(instance);
    for (final pending in await _plugin.pendingNotificationRequests()) {
      final owner = _instanceOwner(pending.payload);
      if (pending.id == id && owner != instance.id.value) {
        throw StateError('Notification identifier is already owned.');
      }
      // Remove pre-upgrade hash IDs and interrupted duplicate schedules.
      if (owner == instance.id.value && pending.id != id) {
        await _plugin.cancel(id: pending.id);
      }
    }
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
      payload: 'planact:reminder:${instance.id.value}',
    );
  }

  @override
  Future<void> cancel(ReminderInstance instance) async {
    await initialize();
    for (final pending in await _plugin.pendingNotificationRequests()) {
      if (_instanceOwner(pending.payload) == instance.id.value) {
        await _plugin.cancel(id: pending.id);
      }
    }
    await _plugin.cancel(id: _notificationId(instance));
  }

  String? _instanceOwner(String? payload) {
    if (payload == null) return null;
    const prefix = 'planact:reminder:';
    final value = payload.startsWith(prefix)
        ? payload.substring(prefix.length)
        : payload;
    try {
      // Bare UUIDv7 payloads are the legacy reminder ownership contract.
      return StableId.parse(value).value;
    } on FormatException {
      return null;
    }
  }

  int _notificationId(ReminderInstance instance) {
    final stored = int.tryParse(instance.platformNotificationId ?? '');
    if (stored != null && stored >= 0 && stored <= 0x7fffffff) return stored;
    // Dart hashCode is not a cross-process/platform persistence contract.
    final bytes = sha256.convert(utf8.encode(instance.id.value)).bytes;
    return ((bytes[0] << 24) | (bytes[1] << 16) | (bytes[2] << 8) | bytes[3]) &
        0x7fffffff;
  }
}
