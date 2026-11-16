import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/features/inbox/application/inbox_use_cases.dart';
import 'package:planact/features/inbox/data/android_sms_detection_notifications.dart';
import 'package:planact/features/inbox/data/drift_inbox_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'notification channel uses review hints and never includes source SMS',
    () async {
      final calls = <MethodCall>[];
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(
        AndroidSmsDetectionNotifications.channel,
        (call) async {
          calls.add(call);
          return null;
        },
      );
      addTearDown(
        () => messenger.setMockMethodCallHandler(
          AndroidSmsDetectionNotifications.channel,
          null,
        ),
      );
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      final inbox = InboxUseCases(DriftInboxRepository(database));
      final item = await inbox.stageSms(
        rawText: 'برداشت مبلغ ۲۵۰۰',
        sourceKey: 'android-sms:1',
        currency: 'IRR',
        importedAt: DateTime.utc(2026),
      );
      final platform = AndroidSmsDetectionNotifications();
      await platform.show([item], showAmounts: true);
      var payload = calls.last.arguments as Map;
      expect(payload['target'], item.id.value);
      expect(payload['body'], isNot(contains('۲٬۵۰۰')));
      expect(payload['body'], isNot(contains('برداشت')));
      expect(payload['generic'], isNot(contains('۲۵۰۰')));
      await platform.show([item, item], showAmounts: true);
      payload = calls.last.arguments as Map;
      expect(payload['target'], 'pending');
      expect(payload['body'], isNot(contains('۲۵۰۰')));
      expect(calls.every((call) => call.method == 'show'), isTrue);
    },
  );
}
