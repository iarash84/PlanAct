import 'package:shamsi_date/shamsi_date.dart';

/// Display-calendar boundary for Persian users. Domain instants remain DateTime.
class JalaliDate implements Comparable<JalaliDate> {
  const JalaliDate(this.year, this.month, this.day);

  factory JalaliDate.now() {
    final date = Jalali.now();
    return JalaliDate(date.year, date.month, date.day);
  }

  factory JalaliDate.fromDateTime(DateTime value) {
    final date = Jalali.fromDateTime(value);
    return JalaliDate(date.year, date.month, date.day);
  }

  final int year;
  final int month;
  final int day;

  DateTime toDateTime() => Jalali(year, month, day).toDateTime();

  int get monthLength => Jalali(year, month, day).monthLength;

  /// 1 = Saturday through 7 = Friday, matching the Persian calendar header.
  int get weekDay => Jalali(year, month, day).weekDay;

  JalaliDate addDays(int days) {
    final date = Jalali(year, month, day).addDays(days);
    return JalaliDate(date.year, date.month, date.day);
  }

  JalaliDate addMonths(int months) {
    final date = Jalali(year, month, 1).addMonths(months);
    return JalaliDate(date.year, date.month, 1);
  }

  @override
  int compareTo(JalaliDate other) => toDateTime().compareTo(other.toDateTime());

  @override
  bool operator ==(Object other) =>
      other is JalaliDate &&
      year == other.year &&
      month == other.month &&
      day == other.day;

  @override
  int get hashCode => Object.hash(year, month, day);
}
