import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/time/jalali_date.dart';
import 'package:planact/features/calendar/domain/holiday_provider.dart';
import 'package:planact/features/calendar/domain/iranian_holiday_data.dart';

void main() {
  const provider = IranianHolidayProvider();
  List<CalendarHoliday> official(JalaliDate date) => provider
      .holidaysFor(date)
      .where(
        (h) =>
            h.kind == CalendarHolidayKind.officialFixed ||
            h.kind == CalendarHolidayKind.officialVariable,
      )
      .toList();

  test('all verified years include ten fixed holiday dates', () {
    for (var year = 1400; year <= 1406; year++) {
      expect(provider.hasCompleteOfficialCoverage(year), isTrue);
      final fixed = [
        for (var month = 1; month <= 12; month++)
          ...provider
              .holidaysForMonth(year, month)
              .where((h) => h.kind == CalendarHolidayKind.officialFixed),
      ];
      expect(fixed.length, 10);
      expect(official(JalaliDate(year, 1, 1)).first.title, 'آغاز نوروز');
      expect(official(JalaliDate(year, 12, 29)), isNotEmpty);
    }
  });

  test('published Eid dates differ from generic lunar predictions', () {
    for (final date in [
      DateTime(2023, 4, 22),
      DateTime(2024, 4, 10),
      DateTime(2025, 3, 31),
    ]) {
      final jalali = JalaliDate.fromDateTime(date);
      expect(
        official(jalali).any((h) => h.title.contains('عید سعید فطر')),
        isTrue,
      );
      expect(
        official(jalali.addDays(1)).any((h) => h.title.contains('فطر')),
        isTrue,
      );
    }
  });

  test('Friday is separate and overlapping official reasons are retained', () {
    final friday = provider.holidaysFor(const JalaliDate(1404, 1, 1));
    expect(
      friday.map((h) => h.kind),
      containsAll([
        CalendarHolidayKind.weekend,
        CalendarHolidayKind.officialFixed,
      ]),
    );
    final prophetBirthday = provider.holidaysFor(
      JalaliDate.fromDateTime(DateTime(2024, 9, 21)),
    );
    expect(
      prophetBirthday
          .where((h) => h.kind == CalendarHolidayKind.officialVariable)
          .length,
      2,
    );
  });

  test('Safar end follows published month length, including 29-day month', () {
    // Calendar-center: 1443/2 starts September 8, 1443/3 October 8.
    final date = JalaliDate.fromDateTime(DateTime(2021, 10, 7));
    // The source also contains a 29-day Safar in 1442, outside public coverage.
    expect(
      iranianVariableHolidays.any(
        (row) =>
            row.$1 == 2020 &&
            row.$2 == 10 &&
            row.$3 == 17 &&
            row.$4.contains('رضا'),
      ),
      isTrue,
    );
    expect(
      iranianVariableHolidays.any(
        (row) =>
            row.$1 == 2020 &&
            row.$2 == 10 &&
            row.$3 == 18 &&
            row.$4.contains('رضا'),
      ),
      isFalse,
    );
    expect(official(date).any((h) => h.title.contains('رضا')), isTrue);
    expect(
      official(date.addDays(1)).any((h) => h.title.contains('رضا')),
      isFalse,
    );
  });

  test('leap boundaries, invalid dates and incomplete years are explicit', () {
    expect(
      provider.holidaysForMonth(1403, 12).every((h) => h.date.day <= 30),
      isTrue,
    );
    expect(
      () => provider.holidaysFor(const JalaliDate(1404, 12, 30)),
      throwsA(isA<Exception>()),
    );
    expect(provider.hasCompleteOfficialCoverage(1407), isFalse);
    expect(provider.hasCompleteOfficialCoverage(1399), isFalse);
    expect(official(const JalaliDate(1399, 1, 1)), isEmpty);
    expect(
      provider
          .holidaysForMonth(1407, 1)
          .where((h) => h.kind == CalendarHolidayKind.officialVariable),
      isEmpty,
    );
  });

  test('all 365 days of 1405 match the published monthly holiday markers', () {
    final snapshot = jsonDecode(
      File('third_party/iranian_holidays/time_ir_1405.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    for (final month in snapshot['months'] as List) {
      for (var day = 1; day <= month['day_count']; day++) {
        final date = JalaliDate(1405, month['month'] as int, day);
        expect(
          official(date).isNotEmpty,
          (month['official_days'] as List).contains(day),
          reason: '$date',
        );
      }
    }
    for (final row in snapshot['holidays'] as List) {
      final date = JalaliDate(
        1405,
        row['jalali_month'] as int,
        row['jalali_day'] as int,
      );
      final gregorian = date.toDateTime();
      expect(
        [gregorian.year, gregorian.month, gregorian.day],
        [row['gregorian_year'], row['gregorian_month'], row['gregorian_day']],
      );
      expect(
        official(date).any(
          (h) =>
              h.kind ==
              (row['base'] == 2
                  ? CalendarHolidayKind.officialVariable
                  : CalendarHolidayKind.officialFixed),
        ),
        isTrue,
      );
    }
  });

  test('1405 retains both Eid cycles, overlaps and exact 29-day Safar end', () {
    for (final date in [
      const JalaliDate(1405, 1, 1),
      const JalaliDate(1405, 12, 19),
    ]) {
      expect(official(date).any((h) => h.title.contains('فطر')), isTrue);
      expect(
        official(date.addDays(1)).any((h) => h.title.contains('فطر')),
        isTrue,
      );
    }
    expect(official(const JalaliDate(1405, 3, 14)).length, 2);
    expect(
      official(const JalaliDate(1405, 5, 22))
          .any((h) => h.title.contains('رضا')),
      isTrue,
    );
    expect(
      official(const JalaliDate(1405, 5, 23))
          .any((h) => h.title.contains('رضا')),
      isFalse,
    );
    // End-of-Safar must not be added to Arbaeen or Safar 28.
    for (final day in [13, 21]) {
      expect(
        official(JalaliDate(1405, 5, day)).any((h) => h.title.contains('رضا')),
        isFalse,
      );
    }
    expect(official(const JalaliDate(1405, 6, 8)).length, 2);
    final rebuilt = const IranianHolidayProvider().holidaysFor(
      const JalaliDate(1405, 12, 19),
    );
    expect(
      rebuilt.map((h) => h.title),
      provider.holidaysFor(const JalaliDate(1405, 12, 19)).map((h) => h.title),
    );
    expect(rebuilt.every((h) => h.source.contains('time.ir')), isTrue);
  });

  test('all 365 days and reasons of 1406 match the published source', () {
    final snapshot = jsonDecode(
      File('third_party/iranian_holidays/time_ir_1406.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final events = jsonDecode(
      File('third_party/iranian_holidays/events.json').readAsStringSync(),
    ) as List;
    expect(snapshot['year'], 1406);
    expect(
      (snapshot['months'] as List).map((m) => m['month']),
      List.generate(12, (i) => i + 1),
    );
    var daysChecked = 0;
    var officialDays = 0;
    for (final month in snapshot['months'] as List) {
      final monthIndex = month['month'] as int;
      final length = JalaliDate(1406, monthIndex, 1).monthLength;
      expect(month['day_count'], length);
      expect(month['response_sha256'], matches(RegExp(r'^[a-f0-9]{64}$')));
      for (var day = 1; day <= length; day++) {
        final date = JalaliDate(1406, monthIndex, day);
        final actual = official(date);
        expect(
          actual.isNotEmpty,
          (month['official_days'] as List).contains(day),
          reason: '$date',
        );
        final expectedReasons = <String>[];
        for (final row in snapshot['holidays'] as List) {
          if (row['jalali_month'] != monthIndex || row['jalali_day'] != day) {
            continue;
          }
          final gregorian = date.toDateTime();
          expect(
            [gregorian.year, gregorian.month, gregorian.day],
            [
              row['gregorian_year'],
              row['gregorian_month'],
              row['gregorian_day'],
            ],
          );
          final fixed = row['base'] == 0;
          for (final event in events) {
            if (event['calendar'] != (fixed ? 'Persian' : 'Hijri') ||
                event['month'] != row[fixed ? 'jalali_month' : 'hijri_month']) {
              continue;
            }
            if ((event['rule'] == 'end of month' &&
                    (row['hijri_day'] == 29 || row['hijri_day'] == 30)) ||
                event['day'] == row[fixed ? 'jalali_day' : 'hijri_day']) {
              final kind = fixed
                  ? CalendarHolidayKind.officialFixed
                  : CalendarHolidayKind.officialVariable;
              expectedReasons.add('${kind.name}:${event['title']}');
            }
          }
        }
        expect(
          actual.map((h) => '${h.kind.name}:${h.title}'),
          unorderedEquals(expectedReasons),
          reason: '$date',
        );
        expect(
          actual.every(
            (h) =>
                h.source == 'time.ir published calendar (2026-10-14)' &&
                h.version == IranianHolidayProvider.dataVersion,
          ),
          isTrue,
          reason: '$date provenance',
        );
        daysChecked++;
        if (actual.isNotEmpty) officialDays++;
      }
    }
    expect(daysChecked, 365);
    expect(officialDays, 27);
  });

  test('1406 exact lunar dates, Friday overlap and year boundary', () {
    for (final (month, day, title) in [
      (1, 14, 'صادق'),
      (2, 27, 'قربان'),
      (3, 4, 'غدیر'),
      (3, 25, 'تاسوعا'),
      (3, 26, 'عاشورا'),
      (5, 3, 'اربعین'),
      (5, 12, 'رضا'),
      (12, 8, 'فطر'),
      (12, 9, 'فطر'),
    ]) {
      expect(
        official(JalaliDate(1406, month, day))
            .any((h) => h.title.contains(title)),
        isTrue,
      );
    }
    expect(
      official(const JalaliDate(1406, 5, 13))
          .any((h) => h.title.contains('رضا')),
      isFalse,
    );
    for (final day in [3, 11]) {
      expect(
        official(JalaliDate(1406, 5, day)).any((h) => h.title.contains('رضا')),
        isFalse,
      );
    }
    expect(official(const JalaliDate(1406, 5, 29)).length, 2);
    expect(
      provider.holidaysFor(const JalaliDate(1406, 1, 13)).map((h) => h.kind),
      containsAll([
        CalendarHolidayKind.weekend,
        CalendarHolidayKind.officialFixed,
      ]),
    );
    expect(provider.hasCompleteOfficialCoverage(1406), isTrue);
    expect(provider.hasCompleteOfficialCoverage(1407), isFalse);
    expect(
      official(const JalaliDate(1407, 1, 1))
          .every((h) => h.kind == CalendarHolidayKind.officialFixed),
      isTrue,
    );
  });

  test(
    'versioned special closures coexist without altering official dates',
    () {
      const date = JalaliDate(1404, 1, 1);
      const special = CalendarHoliday(
        date: date,
        title: 'تعطیلی آزمون',
        kind: CalendarHolidayKind.special,
        source: 'test-fixture',
        version: 'fixture-v1',
        scope: 'آموزشگاه',
      );
      const overlay = IranianHolidayProvider(specialClosures: [special]);
      expect(
        overlay.holidaysFor(date).length,
        provider.holidaysFor(date).length + 1,
      );
      expect(
        overlay
            .holidaysFor(date.addDays(1))
            .any((h) => h.kind == CalendarHolidayKind.special),
        isFalse,
      );
      expect(() => provider.holidaysFor(date).clear(), throwsUnsupportedError);
      expect(
        overlay.holidaysFor(date).map((h) => h.title).toList(),
        overlay.holidaysFor(date).map((h) => h.title).toList(),
      );
      expect(
        const IranianHolidayProvider()
            .holidaysFor(date)
            .map((h) => h.title)
            .toList(),
        provider.holidaysFor(date).map((h) => h.title).toList(),
      );
    },
  );
}
