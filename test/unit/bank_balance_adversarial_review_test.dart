import 'package:flutter_test/flutter_test.dart';
import 'package:planact/features/inbox/application/inbox_use_cases.dart';
import 'package:planact/features/inbox/domain/sms_currency_evidence.dart';

void main() {
  const parser = LocalSmsParser();

  test(
    'fallback preserves explicit zero balance with independent toman unit',
    () {
      final parsed = parser.parse(
        text:
            'واریز به حساب: 12345678\nمبلغ: 100 ریال\n'
            'مانده: 0 تومان\nتاریخ: 1405/08/25\nساعت: 12:34',
        currency: 'IRR',
      );
      expect(parsed.balance!.minorUnits, 0);
      expect(parsed.reportedBalanceAmount, 0);
      expect(parsed.reportedBalanceUnit, SmsMoneyUnit.toman);
    },
  );

  test('zero transaction amount is still rejected', () {
    expect(
      () => parser.parse(
        text: 'نوع: واریز\nمبلغ: 0 ریال\nمانده: 0 ریال',
        currency: 'IRR',
      ),
      throwsA(isA<UnsupportedSmsFormat>()),
    );
  });

  test('overflowing toman balance is rejected rather than clamped', () {
    expect(
      () => parser.parse(
        text:
            'نوع: واریز\nمبلغ: 100 ریال\n'
            'مانده: 922337203685477581 تومان',
        currency: 'IRR',
      ),
      throwsA(isA<UnsupportedSmsFormat>()),
    );
  });

  test('labelled balance forwards independent amount and unit evidence', () {
    final parsed = parser.parse(
      text:
          'نوع: واریز\nحساب: 12345678\nمبلغ: 100 ریال\n'
          'مانده: 25 تومان\nتاریخ: 1405/08/25\nساعت: 12:34',
      currency: 'IRR',
    );
    expect(parsed.balance!.minorUnits, 250);
    expect(parsed.reportedBalanceAmount, 25);
    expect(parsed.reportedBalanceUnit, SmsMoneyUnit.toman);
  });

  test('unknown-layout fallback forwards independent balance evidence', () {
    final parsed = parser.parse(
      text:
          'واریز به حساب: 12345678\nمبلغ: 100 ریال\n'
          'مانده: 25 تومان\nتاریخ: 1405/08/25\nساعت: 12:34',
      currency: 'IRR',
    );
    expect(parsed.balance!.minorUnits, 250);
    expect(parsed.reportedBalanceAmount, 25);
    expect(parsed.reportedBalanceUnit, SmsMoneyUnit.toman);
  });

  test(
    'labelled zero bank balance is valid evidence, not a parser exception',
    () {
      final parsed = parser.parse(
        text:
            'نوع: برداشت\nمبلغ: 100 ریال\nمانده: 0 ریال\n'
            'تاریخ: 1405/08/25\nساعت: 12:34',
        currency: 'IRR',
      );
      expect(parsed.balance!.minorUnits, 0);
      expect(parsed.reportedBalanceAmount, 0);
      expect(parsed.reportedBalanceUnit, SmsMoneyUnit.rial);
    },
  );
}
