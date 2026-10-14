import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/money/money_input_formatter.dart';

void main() {
  test('monetary editing preserves sign, fractions and invalid text', () {
    const formatter = MoneyInputFormatter(decimal: true);
    for (final pair in {
      '-1234567.8': '-1,234,567.8',
      '1234.': '1,234.',
      '\u06f1\u06f2\u06f3\u06f4\u066b\u06f5': '1,234.5',
      '1.99': '1.99',
      'abc123': 'abc123',
      '12,34': '12,34',
      '1-2': '1-2',
    }.entries) {
      final result = formatter.formatEditUpdate(
        const TextEditingValue(),
        TextEditingValue(
          text: pair.key,
          selection: TextSelection.collapsed(offset: pair.key.length),
        ),
      );
      expect(result.text, pair.value);
      expect(result.selection.extentOffset, pair.value.length);
    }
    final pasted = formatter.formatEditUpdate(
      const TextEditingValue(
        text: '1,000,000',
        selection: TextSelection(baseOffset: 0, extentOffset: 9),
      ),
      const TextEditingValue(
        text: '12,34',
        selection: TextSelection.collapsed(offset: 5),
      ),
    );
    expect(pasted.text, '12,34');
    expect(MoneyInputFormatter.groupText('-1234567.8'), '-1,234,567.8');
  });

  test('groups monetary values by thousands and normalizes locale digits', () {
    expect(MoneyInputFormatter.format(1000), '1,000');
    expect(MoneyInputFormatter.format(1250000), '1,250,000');
    expect(MoneyInputFormatter.normalize('۱,۲۵۰,۰۰۰'), '1250000');
    expect(MoneyInputFormatter.normalize('١٬٢٥٠٬٠٠٠'), '1250000');
  });

  test('keeps the cursor aligned after inserting a digit', () {
    const formatter = MoneyInputFormatter();
    final result = formatter.formatEditUpdate(
      const TextEditingValue(
        text: '1000',
        selection: TextSelection.collapsed(offset: 4),
      ),
      const TextEditingValue(
        text: '10000',
        selection: TextSelection.collapsed(offset: 5),
      ),
    );

    expect(result.text, '10,000');
    expect(result.selection.baseOffset, result.text.length);
  });
}
