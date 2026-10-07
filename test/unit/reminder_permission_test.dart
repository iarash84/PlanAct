import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/features/reminders/application/reminder_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const notifications = MethodChannel(
    'dexterous.com/flutter/local_notifications',
  );
  const settings = MethodChannel('planact/reminder-settings');
  const timezone = MethodChannel('flutter_timezone');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  var enabled = false;
  var grantPrompt = false;
  var grantSettings = false;
  var settingsCalls = 0;
  var prompts = 0;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    enabled = false;
    grantPrompt = false;
    grantSettings = false;
    settingsCalls = 0;
    prompts = 0;
    messenger.setMockMethodCallHandler(timezone, (_) async => 'Asia/Tehran');
    messenger.setMockMethodCallHandler(notifications, (call) async {
      switch (call.method) {
        case 'initialize':
          return true;
        case 'areNotificationsEnabled':
          return enabled;
        case 'requestNotificationsPermission':
          prompts++;
          enabled = grantPrompt;
          return grantPrompt;
        default:
          return null;
      }
    });
    messenger.setMockMethodCallHandler(settings, (call) async {
      expect(call.method, 'openNotificationSettings');
      settingsCalls++;
      enabled = grantSettings;
      return null;
    });
  });
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    messenger.setMockMethodCallHandler(notifications, null);
    messenger.setMockMethodCallHandler(settings, null);
    messenger.setMockMethodCallHandler(timezone, null);
  });

  test('already enabled avoids prompts and settings', () async {
    enabled = true;
    expect(await AndroidReminderPlatformAdapter().requestPermission(), isTrue);
    expect(prompts, 0);
    expect(settingsCalls, 0);
  });
  test('runtime grant avoids opening settings', () async {
    grantPrompt = true;
    expect(await AndroidReminderPlatformAdapter().requestPermission(), isTrue);
    expect(settingsCalls, 0);
  });
  test(
    'disabled notifications open settings and verify grant on return',
    () async {
      grantSettings = true;
      expect(
        await AndroidReminderPlatformAdapter().requestPermission(),
        isTrue,
      );
      expect(settingsCalls, 1);
    },
  );
  test('return without grant never reports success', () async {
    expect(await AndroidReminderPlatformAdapter().requestPermission(), isFalse);
    expect(settingsCalls, 1);
  });
}
