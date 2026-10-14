import 'package:planact/core/localization/persian_copy.g.dart';
import 'package:planact/core/localization/persian_numbers.dart';
import 'package:planact/core/time/jalali_date.dart';

abstract final class PersianDateFormatter {
  static const monthNames = <String>[
    PersianCopy.jalaliMonthFarvardin,
    PersianCopy.jalaliMonthOrdibehesht,
    PersianCopy.jalaliMonthKhordad,
    PersianCopy.jalaliMonthTir,
    PersianCopy.jalaliMonthMordad,
    PersianCopy.jalaliMonthShahrivar,
    PersianCopy.jalaliMonthMehr,
    PersianCopy.jalaliMonthAban,
    PersianCopy.jalaliMonthAzar,
    PersianCopy.jalaliMonthDey,
    PersianCopy.jalaliMonthBahman,
    PersianCopy.jalaliMonthEsfand,
  ];

  static const weekdayNames = <String>[
    PersianCopy.weekdaySaturday,
    PersianCopy.weekdaySunday,
    PersianCopy.weekdayMonday,
    PersianCopy.weekdayTuesday,
    PersianCopy.weekdayWednesday,
    PersianCopy.weekdayThursday,
    PersianCopy.weekdayFriday,
  ];

  // Distinct compact labels for a seven-column calendar; semantics use full names.
  static const compactWeekdayNames = <String>[
    PersianCopy.weekdayShortSaturday,
    PersianCopy.weekdayShortSunday,
    PersianCopy.weekdayShortMonday,
    PersianCopy.weekdayShortTuesday,
    PersianCopy.weekdayShortWednesday,
    PersianCopy.weekdayShortThursday,
    PersianCopy.weekdayShortFriday,
  ];

  static String month(JalaliDate date) =>
      '${monthNames[date.month - 1]} ${PersianNumbers.format(date.year)}';

  static String date(JalaliDate date) =>
      PersianCopy.persianDateFormatterDateMessage(
        (weekdayNames[date.weekDay - 1]).toString(),
        (PersianNumbers.format(date.day)).toString(),
        (monthNames[date.month - 1]).toString(),
      );

  static String shortDate(JalaliDate date) =>
      '${PersianNumbers.format(date.day)} ${monthNames[date.month - 1]}';

  static String relative(JalaliDate date, {JalaliDate? today}) {
    final reference = today ?? JalaliDate.now();
    final difference = date
        .toDateTime()
        .difference(reference.toDateTime())
        .inDays;
    if (difference == 0) return PersianCopy.commonToday;
    if (difference == 1) return PersianCopy.commonTomorrow;
    if (difference == -1) return PersianCopy.commonYesterday;
    return shortDate(date);
  }
}
