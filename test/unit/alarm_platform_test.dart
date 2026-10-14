import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/reminders/application/reminder_platform.dart';
import 'package:planact/features/reminders/domain/reminder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const notifications = MethodChannel(
    'dexterous.com/flutter/local_notifications',
  );
  const alarms = MethodChannel('planact/alarms');
  const timezone = MethodChannel('flutter_timezone');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final ordinaryCalls = <String>[];
  final nativeCalls = <MethodCall>[];
  var available = true;
  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    ordinaryCalls.clear();
    nativeCalls.clear();
    available = true;
    messenger.setMockMethodCallHandler(timezone, (_) async => 'Asia/Tehran');
    messenger.setMockMethodCallHandler(notifications, (call) async {
      ordinaryCalls.add(call.method);
      return switch (call.method) {
        'initialize' ||
        'areNotificationsEnabled' ||
        'canScheduleExactNotifications' => true,
        'pendingNotificationRequests' => <Object>[],
        _ => null,
      };
    });
    messenger.setMockMethodCallHandler(alarms, (call) async {
      nativeCalls.add(call);
      return call.method == 'available'
          ? available
          : call.method == 'schedule'
          ? true
          : null;
    });
  });
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    for (final channel in [notifications, alarms, timezone]) {
      messenger.setMockMethodCallHandler(channel, null);
    }
  });
  ReminderInstance instance() => ReminderInstance.fromRule(
    rule: ReminderRule.atOccurrence(
      occurrenceId: StableId.generate(),
      delivery: ReminderDelivery.alarm,
    ),
    occurrenceStart: DateTime.utc(2040, 1, 1),
  );

  test(
    'alarm uses native durable owner and never schedules ordinary fallback',
    () async {
      final adapter = AndroidReminderPlatformAdapter();
      final alarm = instance();
      await adapter.schedule(alarm);
      expect(nativeCalls.map((c) => c.method), ['available', 'schedule']);
      expect((nativeCalls.last.arguments as Map)['id'], alarm.id.value);
      expect(
        (nativeCalls.last.arguments as Map)['at'],
        alarm.scheduledAt.millisecondsSinceEpoch ~/ 1000,
      );
      expect(ordinaryCalls, isNot(contains('zonedSchedule')));
      await adapter.cancel(alarm);
      expect(nativeCalls.last.method, 'cancel');
    },
  );
  test('disabled alarm channel leaves delivery pending without hidden substitution', () async {
    available = false;
    await expectLater(
      AndroidReminderPlatformAdapter().schedule(instance()),
      throwsA(isA<ReminderPermissionUnavailable>()),
    );
    expect(nativeCalls.map((c) => c.method), ['available']);
    expect(ordinaryCalls, isNot(contains('zonedSchedule')));
  });
  test('orphan cleanup shares the durable active ownership set with native inventory', () async {
    await AndroidReminderPlatformAdapter().removeOrphans({'owner'});
    expect(nativeCalls.single.method, 'removeOrphans');
    expect((nativeCalls.single.arguments as Map)['active'], ['owner']);
  });
}
