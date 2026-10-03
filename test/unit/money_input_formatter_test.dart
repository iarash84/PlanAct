import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/money/money_input_formatter.dart';

void main() {
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
