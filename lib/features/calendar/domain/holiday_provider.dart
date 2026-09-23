import 'package:planact/core/time/jalali_date.dart';

class CalendarHoliday {
  const CalendarHoliday({required this.date, required this.title});

  final JalaliDate date;
  final String title;
}

/// Offline holiday seam. Friday is always treated as the weekly holiday;
/// official dates can be expanded through this versioned local dataset.
class IranianHolidayProvider {
  const IranianHolidayProvider();

  List<CalendarHoliday> holidaysForMonth(int year, int month) {
    final result = <CalendarHoliday>[];
    final first = JalaliDate(year, month, 1);
    for (var day = 1; day <= first.monthLength; day++) {
      final date = JalaliDate(year, month, day);
      if (date.weekDay == 7) {
        result.add(CalendarHoliday(date: date, title: 'تعطیلی هفتگی'));
      }
    }
    return result;
  }

  CalendarHoliday? holidayFor(JalaliDate date) {
    if (date.weekDay == 7) {
      return CalendarHoliday(date: date, title: 'تعطیلی هفتگی');
    }
    return null;
  }
}
