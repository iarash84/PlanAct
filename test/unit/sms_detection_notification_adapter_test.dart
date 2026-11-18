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
    'generic-only channel ignores legacy disclosure and carries batch protocol',
    () async {
      final calls = <MethodCall>[];
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(
        AndroidSmsDetectionNotifications.channel,
        (call) async {
          calls.add(call);
          return call.method == 'show' ? false : true;
        },
      );
      addTearDown(
        () => messenger.setMockMethodCallHandler(
          AndroidSmsDetectionNotifications.channel,
          null,
        ),
      );
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final item = await InboxUseCases(DriftInboxRepository(db)).stageSms(
        rawText: 'برداشت مبلغ 1000',
        sourceKey: 'android-sms:1',
        currency: 'IRR',
        importedAt: DateTime.utc(2026),
      );
      final platform = AndroidSmsDetectionNotifications();
      await platform.show([item], showAmounts: true);
      expect(calls.last.arguments, {'batchId': item.id.value, 'silent': true});
      expect(
        await platform.showBatch(batchId: 'opaque', silent: false),
        isFalse,
      );
      expect(calls.last.arguments, {'batchId': 'opaque', 'silent': false});
      expect(await platform.dismissed(batchId: 'opaque'), isTrue);
      expect(calls.last.method, 'dismissed');
      await platform.dismiss(batchId: 'opaque');
      expect(calls.last.arguments, {'batchId': 'opaque'});
      await platform.cancel();
      expect(calls.last.method, 'cancel');
      expect(await platform.permitted(), isTrue);
      for (final call in calls) {
        final args = call.arguments;
        if (args is Map) {
          expect(
            args.keys.every((key) => ['batchId', 'silent'].contains(key)),
            isTrue,
          );
        }
      }
    },
  );
}
