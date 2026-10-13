import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/money/iranian_money_unit.dart';
import 'package:planact/core/presentation/persian_money_text.dart';

void main() {
  test(
    'exact signed round trips include int64 limits and tenth remainders',
    () {
      for (final value in [
        -9223372036854775808,
        -12345,
        -9,
        -1,
        0,
        1,
        9,
        10,
        12345,
        9223372036854775807,
      ]) {
        for (final unit in IranianMoneyUnit.values) {
          expect(unit.parse(unit.inputText(value)), value);
        }
      }
      expect(IranianMoneyUnit.toman.inputText(-11), '-1.1');
      expect(IranianMoneyUnit.toman.parse('−۱٬۲۳۴٫۵'), -12345);
      expect(IranianMoneyUnit.rial.parse('١٢٣'), 123);
      expect(IranianMoneyUnit.toman.parse('922337203685477580.8'), isNull);
      expect(IranianMoneyUnit.rial.parse('-9223372036854775809'), isNull);
    },
  );
  test('invalid input cannot be silently stripped or rounded', () {
    for (final text in [
      '1.01',
      '1.99',
      '1e3',
      '1-2',
      'abc123',
      '12,34',
      '',
      '.',
      '1.',
    ]) {
      expect(IranianMoneyUnit.toman.parse(text), isNull, reason: text);
    }
    expect(IranianMoneyUnit.rial.parse('1.1'), isNull);
  });
  test(
    'display retains negative sign and exact remainder; legacy unchanged',
    () {
      expect(PersianMoneyText.amount(-12345, 'IRR'), '-۱۲,۳۴۵ ریال');
      expect(
        PersianMoneyText.amount(-12345, 'IRR', unit: IranianMoneyUnit.toman),
        '-۱,۲۳۴٫۵ تومان',
      );
      expect(
        PersianMoneyText.amount(12345, 'تومان', unit: IranianMoneyUnit.toman),
        '۱۲,۳۴۵ تومان',
      );
      expect(
        PersianMoneyText.amount(12345, 'USD', unit: IranianMoneyUnit.toman),
        '۱۲,۳۴۵ USD',
      );
    },
  );
}
