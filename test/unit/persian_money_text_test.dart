import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/money/iranian_money_unit.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/core/presentation/persian_money_text.dart';

void main() {
  test('formats IRR using Persian grouped digits without converting units', () {
    expect(PersianMoneyText.amount(1234567, 'IRR'), '۱,۲۳۴,۵۶۷ ریال');
  });

  test(
    'isolates only the numeric run while retaining sign and exact precision',
    () {
      expect(
        PersianMoneyText.amount(-12341, 'IRR', isolateNumber: true),
        '\u2066-۱۲,۳۴۱\u2069 ریال',
      );
      expect(
        PersianMoneyText.money(
          Money(minorUnits: -12341, currency: 'IRR'),
          unit: IranianMoneyUnit.toman,
          isolateNumber: true,
        ),
        '\u2066-۱,۲۳۴٫۱\u2069 تومان',
      );
      expect(
        PersianMoneyText.amount(0, 'IRR', isolateNumber: true),
        '\u2066۰\u2069 ریال',
      );
      expect(
        PersianMoneyText.amount(-1200, 'USD', isolateNumber: true),
        '\u2066-۱,۲۰۰\u2069 USD',
      );
    },
  );

  test('retains legacy currency rather than silently treating it as IRR', () {
    expect(
      PersianMoneyText.money(Money(minorUnits: 1200, currency: 'تومان')),
      '۱,۲۰۰ تومان',
    );
  });
}
