import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:cryptography/cryptography.dart';
import 'package:planact/core/time/jalali_date.dart';
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
      final data = jsonDecode(utf8.decode(payload)) as Map<String, dynamic>;
      final year = data['year'] as int;
      final revision = data['revision'] as int;
      final source = data['source'] as String;
      if (year < 1400 ||
          year > 1600 ||
          revision < 1 ||
          source.trim().isEmpty ||
          source.length > 500 ||
          !Uri.parse(source).hasAbsolutePath ||
          !['https', 'http'].contains(Uri.parse(source).scheme)) {
        throw const FormatException('metadata');
      }
      final months = data['months'] as List;
      if (months.length != 12) throw const FormatException('coverage');
      final markers = <String>{};
      for (var index = 0; index < 12; index++) {
        final month = months[index] as Map<String, dynamic>;
        final length = JalaliDate(year, index + 1, 1).monthLength;
        if (month['month'] != index + 1 || month['dayCount'] != length) {
          throw const FormatException('month');
        }
        final days = month['officialDays'] as List;
        final unique = <int>{};
        for (final day in days) {
          if (day is! int || day < 1 || day > length || !unique.add(day)) {
            throw const FormatException('day');
          }
          markers.add('${index + 1}/$day');
        }
      }
      final holidays = <CalendarHoliday>[];
      final dates = <String>{};
      final unique = <String>{};
      final rows = data['holidays'] as List;
      if (rows.isEmpty || rows.length > 200) {
        throw const FormatException('rows');
      }
      final fingerprint = sha256.convert(key).toString();
      for (final value in rows) {
        final row = value as Map<String, dynamic>;
        final month = row['month'] as int;
        final day = row['day'] as int;
        final title = row['title'] as String;
        final kind = switch (row['kind']) {
          'officialFixed' => CalendarHolidayKind.officialFixed,
          'officialVariable' => CalendarHolidayKind.officialVariable,
          _ => throw const FormatException('kind'),
        };
        if (month < 1 ||
            month > 12 ||
            day < 1 ||
            day > JalaliDate(year, month, 1).monthLength ||
            title.trim().isEmpty ||
            title.length > 180 ||
            title.runes.any(
              (r) =>
                  r < 32 ||
                  (r >= 0x202a && r <= 0x202e) ||
                  (r >= 0x2066 && r <= 0x2069),
            ) ||
            !unique.add('$month/$day/${kind.name}/$title')) {
          throw const FormatException('holiday');
        }
        dates.add('$month/$day');
        holidays.add(
          CalendarHoliday(
            date: JalaliDate(year, month, day),
            title: title,
            kind: kind,
            source: source,
            version: '$year-r$revision',
            scope: 'Iran',
          ),
        );
      }
      if (markers.length != dates.length || !markers.containsAll(dates)) {
        throw const FormatException('markers');
      }
      return HolidayDataPackage._(
        encoded: encoded,
        year: year,
        revision: revision,
        source: source,
        publisherKey: base64Encode(key),
        fingerprint: fingerprint,
        holidays: List.unmodifiable(holidays),
      );
    } catch (_) {
      throw const HolidayPackageException(
        'بسته معتبر نیست؛ امضا، ساختار یا پوشش کامل سال را بررسی کنید.',
      );
    }
  }
}
