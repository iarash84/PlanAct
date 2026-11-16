import 'package:flutter_test/flutter_test.dart';
import 'package:planact/features/inbox/application/inbox_use_cases.dart';
import 'package:planact/features/inbox/domain/sms_currency_evidence.dart';

import '../fixtures/real_bank_sms.dart';

void main() {
  const parser = LocalSmsParser();
  test('all accepted corpus messages with a balance preserve source amount evidence', () {
    var checked = 0;
    for (final text in realBankSms) {
      final parsed = parser.parse(text: text, currency: 'IRR');
      if (parsed.balance == null) continue;
      checked++;
      expect(
        parsed.reportedBalanceAmount,
        isNotNull,
        reason: 'Accepted balance must not disappear before confirmation',
      );
      if (parsed.reportedBalanceUnit case final unit?) {
        expect(
          parsed.balance!.minorUnits,
          parsed.reportedBalanceAmount == 0
              ? 0
              : unit.canonicalIrr(parsed.reportedBalanceAmount!),
        );
      }
    }
    expect(checked, greaterThan(5));
  });
  test('device grammar keeps balance unit independent and accepts zero', () {
    for (final unit in ['ریال', 'تومان', '']) {
      final parsed = parser.parse(
        text: 'بانک رفاه\nواریز مبلغ 100 ریال\nمانده: 0 $unit',
        currency: 'IRR',
      );
      expect(parsed.reportedBalanceAmount, 0);
      expect(
        parsed.reportedBalanceUnit,
        unit.isEmpty
            ? null
            : unit == 'ریال'
            ? SmsMoneyUnit.rial
            : SmsMoneyUnit.toman,
      );
    }
  });
  test('device grammar does not borrow transaction unit for balance', () {
    final parsed = parser.parse(
      text: 'بانک رفاه\nواریز مبلغ 100 ریال\nمانده: 25',
      currency: 'IRR',
    );
    expect(parsed.reportedBalanceAmount, 25);
    expect(parsed.reportedBalanceUnit, isNull);
    expect(parsed.occurredAt, isNull);
  });
}
