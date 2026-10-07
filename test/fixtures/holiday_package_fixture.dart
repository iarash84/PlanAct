import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:planact/core/time/jalali_date.dart';

// Synthetic data only: not a published Iranian calendar or production key.
Future<String> holidayFixture({
  int revision = 1,
  int publisher = 1,
  void Function(Map<String, Object>)? mutate,
}) async {
  final data = <String, Object>{
    'year': 1406,
    'revision': revision,
    'source': 'https://example.test/calendar',
    'months': List.generate(
      12,
      (i) => <String, Object>{
        'month': i + 1,
        'dayCount': JalaliDate(1406, i + 1, 1).monthLength,
        'officialDays': i == 0 ? [1] : <int>[],
      },
    ),
    'holidays': [
      {
        'month': 1,
        'day': 1,
        'title': 'تعطیلی آزمایشی',
        'kind': 'officialVariable',
      },
      {
        'month': 1,
        'day': 1,
        'title': 'دلیل هم‌زمان آزمایشی',
        'kind': 'officialFixed',
      },
    ],
  };
  mutate?.call(data);
  final algorithm = Ed25519();
  final key = await algorithm.newKeyPairFromSeed(List.filled(32, publisher));
  final payload = utf8.encode(jsonEncode(data));
  final signature = await algorithm.sign(payload, keyPair: key);
  return jsonEncode({
    'format': 'planact-holidays-v1',
    'payload': base64Encode(payload),
    'publicKey': base64Encode((await key.extractPublicKey()).bytes),
    'signature': base64Encode(signature.bytes),
  });
}
