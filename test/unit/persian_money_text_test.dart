import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/core/presentation/persian_money_text.dart';

void main() {
  test('formats IRR using Persian grouped digits without converting units', () {
    expect(PersianMoneyText.amount(1234567, 'IRR'), '۱,۲۳۴,۵۶۷ ریال');
  });

  test('retains legacy currency rather than silently treating it as IRR', () {
    expect(
      PersianMoneyText.money(Money(minorUnits: 1200, currency: 'تومان')),
      '۱,۲۰۰ تومان',
    );
  });
}
