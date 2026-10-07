import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/reminders/application/reminder_platform.dart';
import 'package:planact/features/reminders/domain/reminder.dart';

/// Run only with PLANACT_ISOLATED_VERIFICATION=true and the isolated debug ID.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final package = await PackageInfo.fromPlatform();
  if (package.packageName != 'com.iarash.planact.verification') {
    throw StateError(
      'Native verification requires the isolated application ID.',
    );
  }
  runApp(
    const MaterialApp(
      home: Scaffold(body: Center(child: Text('بررسی اعلان آزمایشی'))),
    ),
  );
  final plugin = FlutterLocalNotificationsPlugin();
  final adapter = AndroidReminderPlatformAdapter(plugin: plugin);
  final instance = ReminderInstance.fromRule(
    rule: ReminderRule.atOccurrence(occurrenceId: StableId.generate()),
    occurrenceStart: DateTime.now().toUtc().add(const Duration(seconds: 20)),
  );
  try {
    await adapter.initialize();
    if (!await adapter.notificationsEnabled() ||
        !await adapter.exactAlarmsEnabled()) {
      throw StateError(
        'Permissions unavailable; enable them explicitly and retry.',
      );
    }
    await adapter.schedule(instance);
    await adapter.schedule(instance);
    final pending = await plugin.pendingNotificationRequests();
    final owned = pending
        .where(
          (item) => item.payload == 'planact:reminder:${instance.id.value}',
        )
        .toList();
    if (owned.length != 1) {
      throw StateError('Retry duplicated the native alarm.');
    }
    final nativeId = owned.single.id;
    await Future<void>.delayed(const Duration(seconds: 25));
    final delivered = await plugin.getActiveNotifications();
    if (!delivered.any((item) => item.id == nativeId)) {
      throw StateError('Native notification was not delivered.');
    }
    await adapter.cancel(instance);
    if ((await plugin.getActiveNotifications()).any(
      (item) => item.id == nativeId,
    )) {
      throw StateError('Delivered notification survived cancellation.');
    }
    final future = instance.reschedule(
      DateTime.now().toUtc().add(const Duration(minutes: 5)),
    );
    await adapter.schedule(future);
    await adapter.removeOrphans({});
    if ((await plugin.pendingNotificationRequests()).any(
      (item) => item.id == nativeId,
    )) {
      throw StateError('Orphan alarm survived reconciliation.');
    }
    debugPrint(
      'PLANACT_NATIVE_REMINDER_PASS: exact delivery, retry deduplication, cancellation, orphan cleanup',
    );
  } catch (error) {
    debugPrint('PLANACT_NATIVE_REMINDER_FAIL: ${error.runtimeType}: $error');
    rethrow;
  } finally {
    await adapter.cancel(instance);
  }
}
