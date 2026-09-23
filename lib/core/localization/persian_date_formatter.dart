import 'package:planact/core/localization/persian_numbers.dart';
import 'package:planact/core/time/jalali_date.dart';

abstract final class PersianDateFormatter {
  static const monthNames = <String>[
    'فروردین',
    'اردیبهشت',
    'خرداد',
    'تیر',
    'مرداد',
    'شهریور',
    'مهر',
    'آبان',
    'آذر',
    'دی',
    'بهمن',
    'اسفند',
  ];

  static const weekdayNames = <String>[
    'شنبه',
    'یکشنبه',
    'دوشنبه',
    'سه‌شنبه',
    'چهارشنبه',
    'پنجشنبه',
    'جمعه',
  ];

  static String month(JalaliDate date) =>
      '${monthNames[date.month - 1]} ${PersianNumbers.format(date.year)}';

  static String date(JalaliDate date) =>
      '${weekdayNames[date.weekDay - 1]}، ${PersianNumbers.format(date.day)} ${monthNames[date.month - 1]}';

  static String shortDate(JalaliDate date) =>
      '${PersianNumbers.format(date.day)} ${monthNames[date.month - 1]}';

  static String relative(JalaliDate date, {JalaliDate? today}) {
    final reference = today ?? JalaliDate.now();
    final difference = date
        .toDateTime()
        .difference(reference.toDateTime())
        .inDays;
    if (difference == 0) return 'امروز';
    if (difference == 1) return 'فردا';
    if (difference == -1) return 'دیروز';
    return shortDate(date);
  }
}
