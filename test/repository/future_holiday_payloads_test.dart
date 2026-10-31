import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/time/jalali_date.dart';
import 'package:planact/features/calendar/application/holiday_package_service.dart';
import 'package:planact/features/calendar/data/sqlite_holiday_package_store.dart';
import 'package:planact/features/calendar/domain/annual_holiday_data.dart';
import 'package:planact/features/calendar/domain/holiday_data_package.dart';
import 'package:planact/features/calendar/domain/holiday_provider.dart';

import '../../tool/prepare_reviewed_holiday_packages.dart' as preparation;
import '../fixtures/holiday_package_fixture.dart';

class _NoFiles implements HolidayPackageFileSource {
  @override
  Future<String?> pick() async => null;
}

String _payload(int year) =>
    File('third_party/iranian_holidays/reviewed/iran-$year-r1.json')
        .readAsStringSync()
        .replaceAll('\r\n', '\n');

void main() {
  // Frozen after review of every source month/day and exact delivered payload.
  // These are source-calendar snapshots, not independently verified official PDFs.
  const expectations = {
    1407: (
      days: 365,
      officialDates: 25,
      reasons: 29,
      endSafar: (5, 2),
      sha256:
          '980a1e27ac44748154959c1a070c6998951c5140096ce66e391d17bc6b9e12cb',
    ),
    1408: (
      days: 366,
      officialDates: 28,
      reasons: 29,
      endSafar: (4, 22),
      sha256:
          'ab3558531d08155dfe2a55ffa6153a5f7b1fe016937ffe0753c74f54c9682046',
    ),
    1409: (
      days: 365,
      officialDates: 27,
      reasons: 28,
      endSafar: (4, 10),
      sha256:
          '4d12c0b8c61f076d4a3060db94c4c0317d4692082147c0570d7b78272be49a53',
    ),
    1410: (
      days: 365,
      officialDates: 27,
      reasons: 28,
      endSafar: (3, 30),
      sha256:
          '04023af8b8c2160c81efb12fba9ff9e99173056cb5fe12d65df396b9bad9f3ca',
    ),
  };
  for (final entry in expectations.entries) {
    final year = entry.key;
    final expected = entry.value;
    test('$year reviewed payload, every source date/reason and v1 signature', () async {
      final encoded = _payload(year);
      expect(sha256.convert(utf8.encode(encoded)).toString(), expected.sha256);
      final annual = AnnualHolidayData.parse(encoded);
      final signed = await HolidayDataPackage.verify(
        await signHolidayPayload(encoded),
      );
      expect(annual.year, year);
      expect(signed.year, year);
      expect(signed.revision, 1);
      expect(signed.source, 'https://www.time.ir/');
      expect(signed.holidays.length, expected.reasons);
      final raw = jsonDecode(
        File('third_party/iranian_holidays/time_ir_$year.json')
            .readAsStringSync(),
      ) as Map<String, dynamic>;
      final events = jsonDecode(
        File('third_party/iranian_holidays/events.json').readAsStringSync(),
      ) as List;
      if (year == 1408) {
        // Source event 254 is explicit annual data, not an inferred leap rule.
        events.add({
          'calendar': 'Persian',
          'month': 12,
          'day': 30,
          'title': 'آخرین روز سال',
          'rule': 'simple',
        });
        expect(
          annual.holidays
              .where((h) => h.date == const JalaliDate(1408, 12, 30))
              .map((h) => h.title),
          contains('آخرین روز سال'),
        );
        expect(
          (jsonDecode(encoded)['provenance'] as Map)['reviewedAdditions'],
          hasLength(1),
        );
      }
      final prepared = AnnualHolidayData.parse(
        jsonEncode(
          preparation.prepareReviewedAnnual(
            raw,
            events,
            year: year,
            revision: 1,
          ),
        ),
      );
      String reason(CalendarHoliday h) =>
          '${h.date.month}/${h.date.day}/${h.kind.name}/${h.title}';
      expect(
        signed.holidays.map(reason),
        unorderedEquals(prepared.holidays.map(reason)),
      );
      final provider = IranianHolidayProvider(
        annualOverrides: {year: signed.holidays},
      );
      expect(
        const IranianHolidayProvider().hasCompleteOfficialCoverage(year),
        isFalse,
      );
      expect(provider.hasCompleteOfficialCoverage(year), isTrue);
      var days = 0;
      var markedDays = 0;
      for (var month = 1; month <= 12; month++) {
        final source = (raw['months'] as List)[month - 1] as Map;
        expect(source['month'], month);
        expect(source['day_count'], JalaliDate(year, month, 1).monthLength);
        expect(source['response_sha256'], matches(RegExp(r'^[a-f0-9]{64}$')));
        for (var day = 1; day <= source['day_count']; day++) {
          final date = JalaliDate(year, month, day);
          final holidays = provider.holidaysFor(date);
          final official = holidays.where(
            (h) => h.kind != CalendarHolidayKind.weekend,
          );
          expect(
            official.isNotEmpty,
            (source['official_days'] as List).contains(day),
            reason: '$year/$month/$day',
          );
          expect(
            holidays.any((h) => h.kind == CalendarHolidayKind.weekend),
            date.weekDay == 7,
          );
          days++;
          if (official.isNotEmpty) markedDays++;
        }
      }
      expect(days, expected.days);
      expect(markedDays, expected.officialDates);
      for (final row in raw['holidays'] as List) {
        final date = JalaliDate(
          year,
          row['jalali_month'] as int,
          row['jalali_day'] as int,
        );
        final gregorian = date.toDateTime();
        expect(
          [gregorian.year, gregorian.month, gregorian.day],
          [row['gregorian_year'], row['gregorian_month'], row['gregorian_day']],
        );
        if (row['base'] == 2 &&
            row['hijri_month'] == 2 &&
            row['hijri_day'] != 29) {
          expect(
            provider.holidaysFor(date).any((h) => h.title.contains('رضا')),
            isFalse,
          );
        }
      }
      expect(
        provider
            .holidaysFor(
              JalaliDate(year, expected.endSafar.$1, expected.endSafar.$2),
            )
            .any((h) => h.title.contains('رضا')),
        isTrue,
      );
    });
  }

  test(
    'independent annual installs and cold reopen preserve either order',
    () async {
      for (final years in [
        expectations.keys.toList(),
        expectations.keys.toList().reversed.toList(),
      ]) {
        final directory = await Directory.systemTemp.createTemp(
          'future-holidays-',
        );
        addTearDown(() => directory.delete(recursive: true));
        final file = File('${directory.path}/holidays.sqlite');
        HolidayPackageService create() =>
            HolidayPackageService(SqliteHolidayPackageStore(file), _NoFiles());
        var service = create();
        await service.load();
        for (final year in years) {
          final package = await HolidayDataPackage.verify(
            await signHolidayPayload(_payload(year)),
          );
          await service.install(
            package,
            publisherApproved: service.packages.isEmpty,
          );
          service = create();
          await service.load();
          expect(service.provider.hasCompleteOfficialCoverage(year), isTrue);
          expect(
            service.packages.any((p) => p.year == year && p.revision == 1),
            isTrue,
          );
        }
        expect(service.packages.map((p) => p.year), unorderedEquals(years));
        expect(
          service.calendars.where((c) => c.imported).map((c) => c.year),
          unorderedEquals(years),
        );
        expect(service.provider.hasCompleteOfficialCoverage(1411), isFalse);
      }
    },
  );
}
