import 'package:planact/core/time/jalali_date.dart';
import 'package:planact/features/calendar/domain/iranian_holiday_data.dart';

enum CalendarHolidayKind { weekend, officialFixed, officialVariable, special }

class CalendarHoliday {
  const CalendarHoliday({
    required this.date,
    required this.title,
    this.kind = CalendarHolidayKind.weekend,
    this.source = 'Iranian weekly weekend rule',
    this.version = IranianHolidayProvider.dataVersion,
    this.scope = 'Iran',
  });

  final JalaliDate date;
  final String title;
  final CalendarHolidayKind kind;
  final String source;
  final String version;
  final String scope;
}

/// Published calendar dates, not an approximate lunar-calendar calculation.
/// Additional special closures must be supplied from a versioned durable source;
/// this class does not create or persist user closures.
class IranianHolidayProvider {
  const IranianHolidayProvider({
    this.specialClosures = const [],
    this.annualOverrides = const {},
  });

  /// Only validated complete packages are supplied by the application service.
  final Map<int, List<CalendarHoliday>> annualOverrides;

  static const dataVersion = 'iran-1400-1405-v2';
  static const firstCoveredYear = 1400;
  static const lastCoveredYear = 1405;
  static const officialSource =
      'persian-calendar/events + qamari/calendar-center';
  final List<CalendarHoliday> specialClosures;

  bool hasCompleteOfficialCoverage(int year) =>
      annualOverrides.containsKey(year) ||
      (year >= firstCoveredYear && year <= lastCoveredYear);

  List<CalendarHoliday> holidaysForMonth(int year, int month) {
    final first = JalaliDate(year, month, 1);
    return List.unmodifiable([
      for (var day = 1; day <= first.monthLength; day++)
        ...holidaysFor(JalaliDate(year, month, day)),
    ]);
  }

  List<CalendarHoliday> holidaysFor(JalaliDate date) {
    // Force validation even when there are no matching official events.
    final weekday = date.weekDay;
    final result = <CalendarHoliday>[];
    if (weekday == 7) {
      result.add(CalendarHoliday(date: date, title: 'تعطیلی هفتگی (جمعه)'));
    }
    // Current fixed rules are not evidence for arbitrary historical years.
    if (annualOverrides[date.year] case final overrides?) {
      result.addAll(overrides.where((h) => h.date == date));
    }
    if (!annualOverrides.containsKey(date.year) &&
        date.year >= firstCoveredYear) {
      for (final (month, day, title) in iranianFixedHolidays) {
        if (date.month == month && date.day == day) {
          result.add(
            CalendarHoliday(
              date: date,
              title: title,
              kind: CalendarHolidayKind.officialFixed,
              source: officialSource,
            ),
          );
        }
      }
    }
    if (!annualOverrides.containsKey(date.year) &&
        hasCompleteOfficialCoverage(date.year)) {
      final gregorian = date.toDateTime();
      for (final (year, month, day, title) in iranianVariableHolidays) {
        if (gregorian.year == year &&
            gregorian.month == month &&
            gregorian.day == day) {
          result.add(
            CalendarHoliday(
              date: date,
              title: title,
              kind: CalendarHolidayKind.officialVariable,
              source: date.year == 1405
                  ? 'time.ir published calendar (2026-10-06)'
                  : officialSource,
            ),
          );
        }
      }
    }
    for (final closure in specialClosures) {
      if (closure.kind != CalendarHolidayKind.special ||
          closure.source.trim().isEmpty ||
          closure.version.trim().isEmpty ||
          closure.scope.trim().isEmpty ||
          closure.title.trim().isEmpty) {
        throw ArgumentError(
          'Special closures require explicit kind and provenance',
        );
      }
      if (closure.date == date) result.add(closure);
    }
    return List.unmodifiable(result);
  }

  /// Compatibility single-reason lookup; use holidaysFor to retain overlaps.
  CalendarHoliday? holidayFor(JalaliDate date) {
    final holidays = holidaysFor(date);
    return holidays.isEmpty ? null : holidays.first;
  }
}
