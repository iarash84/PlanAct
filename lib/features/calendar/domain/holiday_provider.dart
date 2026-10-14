import 'package:planact/core/localization/persian_copy.g.dart';
import 'package:planact/core/time/jalali_date.dart';
import 'package:planact/features/calendar/domain/calendar_holiday.dart';
import 'package:planact/features/calendar/domain/holiday_calendar_catalog.dart';

export 'calendar_holiday.dart';

/// Published calendar dates, not an approximate lunar-calendar calculation.
/// Additional special closures must have a versioned durable source.
class IranianHolidayProvider {
  const IranianHolidayProvider({
    this.specialClosures = const [],
    this.annualOverrides = const {},
    this.catalog,
  });

  /// Only validated complete packages are supplied by the application service.
  final Map<int, List<CalendarHoliday>> annualOverrides;
  final List<CalendarHoliday> specialClosures;
  final HolidayCalendarCatalog? catalog;

  HolidayCalendarCatalog get bundledCatalog =>
      catalog ?? HolidayCalendarCatalog.bundled;

  List<int> get coveredYears => List.unmodifiable(
    {...bundledCatalog.byYear.keys, ...annualOverrides.keys}.toList()..sort(),
  );

  bool hasCompleteOfficialCoverage(int year) =>
      annualOverrides.containsKey(year) ||
      bundledCatalog.byYear.containsKey(year);

  List<CalendarHoliday> holidaysForMonth(int year, int month) {
    final first = JalaliDate(year, month, 1);
    return List.unmodifiable([
      for (var day = 1; day <= first.monthLength; day++)
        ...holidaysFor(JalaliDate(year, month, day)),
    ]);
  }

  List<CalendarHoliday> holidaysFor(JalaliDate date) {
    final weekday = date.weekDay; // Validate even when there are no records.
    final result = <CalendarHoliday>[];
    if (weekday == 7) {
      result.add(
        CalendarHoliday(
          date: date,
          title: PersianCopy.holidayProviderHolidaysForTitle,
        ),
      );
    }
    final annual =
        annualOverrides[date.year] ??
        bundledCatalog.byYear[date.year]?.holidays;
    if (annual != null) {
      result.addAll(annual.where((h) => h.date == date));
    } else {
      // Preserve the existing incomplete-year fixed-rule fallback. It does not
      // establish annual coverage or predict any variable holiday.
      final years = bundledCatalog.years;
      if (years.isNotEmpty && date.year >= years.first) {
        final latest = bundledCatalog.byYear[years.last]!;
        for (final holiday in latest.holidays) {
          if (holiday.kind == CalendarHolidayKind.officialFixed &&
              holiday.date.month == date.month &&
              holiday.date.day == date.day) {
            result.add(
              CalendarHoliday(
                date: date,
                title: holiday.title,
                kind: holiday.kind,
                source: holiday.source,
                version: '${latest.version}-fixed-rules',
              ),
            );
          }
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
}
