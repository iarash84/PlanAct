import 'package:planact/features/calendar/domain/annual_holiday_data.dart';
import 'package:planact/features/calendar/domain/iranian_holiday_data.dart';

/// Explicit reviewed years, never a min/max claim across missing years.
class HolidayCalendarCatalog {
  HolidayCalendarCatalog(Iterable<AnnualHolidayData> calendars) {
    final entries = <int, AnnualHolidayData>{};
    for (final calendar in calendars) {
      if (entries.containsKey(calendar.year)) {
        throw const FormatException('Duplicate bundled year');
      }
      entries[calendar.year] = calendar;
    }
    byYear = Map.unmodifiable(entries);
  }

  late final Map<int, AnnualHolidayData> byYear;

  List<int> get years => List.unmodifiable(byYear.keys.toList()..sort());

  static final bundled = HolidayCalendarCatalog(
    bundledIranianHolidayPayloads.map(AnnualHolidayData.parse),
  );
}
