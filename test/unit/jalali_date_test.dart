import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/time/jalali_date.dart';

void main() {
  test('converts Gregorian dates to the correct Jalali date', () {
    final date = JalaliDate.fromDateTime(DateTime(2026, 9, 22));

    expect(date.year, 1405);
    expect(date.month, 6);
    expect(date.day, 31);
  });

  test('uses Jalali month lengths and Persian week day numbering', () {
    final date = const JalaliDate(1405, 1, 1);

    expect(date.monthLength, 31);
    expect(date.weekDay, 1);
    expect(date.addMonths(1), const JalaliDate(1405, 2, 1));
    expect(date.addDays(31), const JalaliDate(1405, 2, 1));
  });
}
