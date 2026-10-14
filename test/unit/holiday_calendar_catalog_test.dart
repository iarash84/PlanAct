import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:planact/features/calendar/domain/annual_holiday_data.dart';
import 'package:planact/features/calendar/domain/holiday_calendar_catalog.dart';
import 'package:planact/features/calendar/domain/holiday_provider.dart';
import 'package:planact/core/time/jalali_date.dart';

import '../../tool/generate_iranian_holidays.dart' as generator;
import '../../tool/prepare_reviewed_holiday_packages.dart' as preparation;
import '../fixtures/holiday_package_fixture.dart';

Future<String> payload(
  int year, {
  void Function(Map<String, Object>)? mutate,
}) async {
  final envelope = jsonDecode(await holidayFixture(year: year, mutate: mutate));
  return utf8.decode(base64Decode(envelope['payload'] as String));
}

void main() {
  test(
    'coverage is exact for sparse catalog years; no implicit middle year',
    () async {
      final catalog = HolidayCalendarCatalog([
        AnnualHolidayData.parse(await payload(1400)),
        AnnualHolidayData.parse(await payload(1402)),
      ]);
      final provider = IranianHolidayProvider(catalog: catalog);
      expect(provider.coveredYears, [1400, 1402]);
      expect(provider.hasCompleteOfficialCoverage(1401), isFalse);
      expect(
        provider
            .holidaysForMonth(1401, 1)
            .where((h) => h.kind == CalendarHolidayKind.officialVariable),
        isEmpty,
      );
      expect(() => catalog.byYear.clear(), throwsUnsupportedError);
      expect(() => provider.coveredYears.add(1401), throwsUnsupportedError);
      expect(
        () => HolidayCalendarCatalog([
          catalog.byYear[1400]!,
          catalog.byYear[1400]!,
        ]),
        throwsFormatException,
      );
    },
  );

  test('v1 validator accepts leap Esfand 30 and rejects non-leap day counts', () async {
    final leap = AnnualHolidayData.parse(
      await payload(
        1403,
        mutate: (data) {
          ((data['months'] as List).first as Map)['officialDays'] = <int>[];
          ((data['months'] as List).last as Map)['officialDays'] = [30];
          for (final row in data['holidays'] as List) {
            row['month'] = 12;
            row['day'] = 30;
          }
        },
      ),
    );
    expect(leap.holidays.first.date, const JalaliDate(1403, 12, 30));
    // Identical malformed inputs must not slip through either import or bundle.
    await expectLater(
      holidayFixture(
        year: 1404,
        mutate: (data) {
          ((data['months'] as List).last as Map)['dayCount'] = 30;
        },
      ).then((encoded) {
        final envelope = jsonDecode(encoded);
        AnnualHolidayData.parse(utf8.decode(base64Decode(envelope['payload'])));
      }),
      throwsFormatException,
    );
  });

  test('catalog generation is reproducible and accepts new data without code edits', () async {
    final directory = await Directory.systemTemp.createTemp('holiday-catalog-');
    addTearDown(() => directory.delete(recursive: true));
    final reviewed = Directory('${directory.path}/reviewed')..createSync();
    final encoded = await payload(1407);
    File('${reviewed.path}/new-year.json').writeAsStringSync(encoded);
    final manifest = File('${directory.path}/catalog.json')
      ..writeAsStringSync(
        jsonEncode({
          'format': 'planact-holiday-catalog-v1',
          'calendars': ['reviewed/new-year.json'],
        }),
      );
    final generated = generator.renderHolidayCatalog(directory);
    expect(generated, contains('1407'));
    expect(generated, isNot(contains('1406')));
    manifest.writeAsStringSync(
      jsonEncode({
        'format': 'planact-holiday-catalog-v1',
        'calendars': ['reviewed/new-year.json', 'reviewed/new-year.json'],
      }),
    );
    expect(
      () => generator.renderHolidayCatalog(directory),
      throwsFormatException,
    );
    expect(
      File('lib/features/calendar/domain/iranian_holiday_data.dart')
          .readAsStringSync()
          .replaceAll('\r\n', '\n'),
      generator.renderHolidayCatalog(Directory('third_party/iranian_holidays')),
    );
  });

  test(
    'preparation preserves source markers, precise reasons and source evidence',
    () {
      final events = jsonDecode(
        File('third_party/iranian_holidays/events.json').readAsStringSync(),
      ) as List;
      for (final year in [1405, 1406]) {
        final raw = jsonDecode(
          File('third_party/iranian_holidays/time_ir_$year.json')
              .readAsStringSync(),
        ) as Map<String, dynamic>;
        final result = preparation.prepareReviewedAnnual(
          raw,
          events,
          year: year,
          revision: 2,
        );
        final actual = AnnualHolidayData.parse(jsonEncode(result));
        final expected = HolidayCalendarCatalog.bundled.byYear[year]!;
        expect(actual.revision, 2);
        expect((result['provenance'] as Map)['months'], hasLength(12));
        expect(
          actual.holidays.map(
            (h) => '${h.date.month}/${h.date.day}/${h.kind.name}/${h.title}',
          ),
          unorderedEquals(
            expected.holidays.map(
              (h) => '${h.date.month}/${h.date.day}/${h.kind.name}/${h.title}',
            ),
          ),
        );
        expect(
          () => preparation.prepareReviewedAnnual(
            raw,
            events,
            year: year + 1,
            revision: 2,
          ),
          throwsFormatException,
        );
        final month = (raw['months'] as List).first as Map;
        month['day_count'] = 30;
        expect(
          () => preparation.prepareReviewedAnnual(
            raw,
            events,
            year: year,
            revision: 2,
          ),
          throwsFormatException,
        );
      }
    },
  );
}
