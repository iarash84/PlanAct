import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';

import 'dart:async';

import 'package:planact/features/inbox/application/android_sms_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('planact/sms-permission-test');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test(
    'permission answer waits for native result; settings is a separate action',
    () async {
      final response = Completer<bool>();
      final calls = <String>[];
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call.method);
        if (call.method == 'requestAccess') return response.future;
        return null;
      });
      final source = AndroidSmsSource(channel: channel);
      var completed = false;
      final request = source.requestAccess().then((value) {
        completed = true;
        return value;
      });
      await Future<void>.delayed(Duration.zero);
      expect(completed, isFalse);
      response.complete(false);
      expect(await request, isFalse);
      expect(calls, ['requestAccess']);
      await source.openSettings();
      expect(calls, ['requestAccess', 'openSettings']);
    },
  );

  test('grant is returned and native settings failure propagates', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'requestAccess') return true;
      throw PlatformException(code: 'settings_unavailable');
    });
    final source = AndroidSmsSource(channel: channel);
    expect(await source.requestAccess(), isTrue);
    await expectLater(source.openSettings(), throwsA(isA<PlatformException>()));
  });

  test('rejects malformed platform SMS payloads', () {
    expect(
      () => AndroidSmsMessage.fromMap({
        'sourceKey': 'sms-1',
        'body': 'متن پیامک',
        'receivedAt': 'not-a-timestamp',
      }),
      throwsA(isA<AndroidSmsParseError>()),
    );

    expect(
      () => AndroidSmsMessage.fromMap({
        'sourceKey': '',
        'body': 'متن پیامک',
        'receivedAt': 1,
      }),
      throwsA(isA<AndroidSmsParseError>()),
    );
  });
}
