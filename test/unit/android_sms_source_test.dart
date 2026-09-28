import 'package:flutter_test/flutter_test.dart';
import 'package:planact/features/inbox/application/android_sms_source.dart';

void main() {
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
