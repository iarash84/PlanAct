import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/logging/app_logger.dart';

void main() {
  test('redacts sensitive fields before writing logs', () {
    final messages = <String>[];
    final logger = AppLogger(
      sink: (message, {name, level}) => messages.add(message),
    );

    logger.info(
      'Imported local record',
      fields: {
        'accountId': 'private-account',
        'amount': 1250,
        'source': 'local',
      },
    );

    expect(messages.single, contains('accountId: [REDACTED]'));
    expect(messages.single, contains('amount: [REDACTED]'));
    expect(messages.single, contains('source: local'));
    expect(messages.single, isNot(contains('private-account')));
  });
}
