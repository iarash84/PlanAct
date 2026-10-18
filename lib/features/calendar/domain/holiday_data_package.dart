import 'package:planact/core/localization/persian_copy.g.dart';

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:cryptography/cryptography.dart';
import 'package:planact/features/calendar/domain/annual_holiday_data.dart';
import 'package:planact/features/calendar/domain/holiday_provider.dart';

class HolidayPackageException implements Exception {
  const HolidayPackageException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// A signed, complete annual published calendar. Signature identity is only
/// trusted after explicit out-of-band fingerprint approval by the user.
class HolidayDataPackage {
  HolidayDataPackage._({
    required this.encoded,
    required this.year,
    required this.revision,
    required this.source,
    required this.publisherKey,
    required this.fingerprint,
    required this.holidays,
  });

  static const maxBytes = 256 * 1024;
  final String encoded;
  final int year;
  final int revision;
  final String source;
  final String publisherKey;
  final String fingerprint;
  final List<CalendarHoliday> holidays;

  static Future<HolidayDataPackage> verify(String encoded) async {
    try {
      if (utf8.encode(encoded).length > maxBytes) {
        throw const FormatException('size');
      }
      final envelope = jsonDecode(encoded) as Map<String, dynamic>;
      if (envelope['format'] != 'planact-holidays-v1') {
        throw const FormatException('format');
      }
      final payload = base64Decode(envelope['payload'] as String);
      final key = base64Decode(envelope['publicKey'] as String);
      final signature = base64Decode(envelope['signature'] as String);
      if (key.length != 32 ||
          signature.length != 64 ||
          !await Ed25519().verify(
            payload,
            signature: Signature(
              signature,
              publicKey: SimplePublicKey(key, type: KeyPairType.ed25519),
            ),
          )) {
        throw const FormatException('signature');
      }
      final data = AnnualHolidayData.parse(utf8.decode(payload));
      final fingerprint = sha256.convert(key).toString();
      return HolidayDataPackage._(
        encoded: encoded,
        year: data.year,
        revision: data.revision,
        source: data.source,
        publisherKey: base64Encode(key),
        fingerprint: fingerprint,
        holidays: data.holidays,
      );
    } catch (_) {
      throw const HolidayPackageException(
        PersianCopy.holidayDataPackageVerifyMessage,
      );
    }
  }
}
