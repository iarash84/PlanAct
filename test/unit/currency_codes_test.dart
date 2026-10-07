import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/money/currency.dart';

void main() {
  test('normalizes currency codes without inventing a unit conversion', () {
    expect(CurrencyCodes.canonicalize(' irr '), CurrencyCodes.irr);
    expect(CurrencyCodes.same(' irr ', CurrencyCodes.irr), isTrue);
    expect(CurrencyCodes.same('تومان', CurrencyCodes.irr), isFalse);
    expect(CurrencyCodes.label(CurrencyCodes.irr), 'ریال');
    expect(CurrencyCodes.label('تومان'), 'تومان');
  });
}
