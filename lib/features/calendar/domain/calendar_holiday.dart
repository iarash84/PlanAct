import 'package:planact/core/time/jalali_date.dart';

enum CalendarHolidayKind { weekend, officialFixed, officialVariable, special }

class CalendarHoliday {
  const CalendarHoliday({
    required this.date,
    required this.title,
    this.kind = CalendarHolidayKind.weekend,
    this.source = 'Iranian weekly weekend rule',
    this.version = 'weekly-v1',
    this.scope = 'Iran',
  });

  final JalaliDate date;
  final String title;
  final CalendarHolidayKind kind;
  final String source;
  final String version;
  final String scope;
}
