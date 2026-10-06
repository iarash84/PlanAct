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
    for (var year = 1400; year <= 1404; year++) {
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
    expect(provider.hasCompleteOfficialCoverage(1405), isFalse);
    expect(provider.hasCompleteOfficialCoverage(1399), isFalse);
    expect(official(const JalaliDate(1399, 1, 1)), isEmpty);
    expect(
      provider
          .holidaysForMonth(1405, 1)
          .where((h) => h.kind == CalendarHolidayKind.officialVariable),
      isEmpty,
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
