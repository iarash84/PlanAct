import 'package:flutter_test/flutter_test.dart';
import 'package:planact/features/inbox/application/inbox_use_cases.dart';
import 'package:planact/features/inbox/domain/inbox.dart';
import 'package:planact/features/inbox/domain/sms_currency_evidence.dart';

import '../fixtures/real_bank_sms.dart';

void main() {
  const parser = LocalSmsParser();
  for (var i = 0; i < realBankSms.length; i++) {
    test('redacted actual corpus ${i + 1}', () {
      final parsed = parser.parse(text: realBankSms[i], currency: 'USD');
      expect(parsed.amount.minorUnits, realBankAmounts[i]);
      expect(
        parsed.direction,
        realBankIncoming[i]
            ? TransactionDirection.incoming
            : TransactionDirection.outgoing,
      );
      expect(parsed.bank, realBankNames[i]);
      expect(parsed.accountHint, isNotEmpty);
      expect(parsed.isTransfer, i == 9);
      final fullDate = [0, 1, 12, 13, 14].contains(i);
      expect(parsed.occurredAt == null, !fullDate);
      expect(parsed.sourceDate, isNotEmpty);
      expect(parsed.sourceTime, isNotEmpty);
      final explicitUnit = fullDate || i == 15;
      expect(parsed.currencyEvidence!.requiresSelection, !explicitUnit);
      expect(parsed.balance == null, !explicitUnit);
    });
  }
  test('calendar conversion has independent Gregorian expectations', () {
    expect(
      parser.parse(text: realBankSms[0], currency: 'IRR').occurredAt,
      DateTime(2026, 9, 29, 18, 53, 40),
    );
    expect(
      parser.parse(text: realBankSms[13], currency: 'IRR').occurredAt,
      DateTime(2026, 7, 22, 17, 51, 48),
    );
    expect(
      parser.parse(text: realBankSms[2], currency: 'IRR').sourceDate,
      '05/07/05',
    );
  });
  test(
    'Arabic digits and letters, prefix/suffix signs and independent balance',
    () {
      final arabic = realBankSms[0].replaceAllMapped(
        RegExp('[0-9]'),
        (m) => String.fromCharCode(0x660 + int.parse(m[0]!)),
      );
      expect(
        parser.parse(text: arabic, currency: 'IRR').amount.minorUnits,
        700000,
      );
      final prefixed = realBankSms[8].replaceFirst('3,000,000-', '-3,000,000');
      expect(
        parser.parse(text: prefixed, currency: 'IRR').direction,
        TransactionDirection.outgoing,
      );
      final unitlessBalance = realBankSms[0].replaceFirst(
        '85,196,567 ريال',
        '85,196,567',
      );
      expect(
        parser
            .parse(text: unitlessBalance, currency: 'IRR')
            .balance!
            .minorUnits,
        85196567,
      );
      final balanceOnlyUnit = realBankSms[2].replaceFirst(
        'مانده92,586,708',
        'مانده92,586,708 ریال',
      );
      final parsed = parser.parse(text: balanceOnlyUnit, currency: 'IRR');
      expect(parsed.currencyEvidence!.requiresSelection, isTrue);
      expect(parsed.balance!.minorUnits, 92586708);
      final toman = parser.parse(
        text: realBankSms[0].replaceAll('ريال', 'تومان'),
        currency: 'IRR',
      );
      expect(toman.amount.minorUnits, 7000000);
      expect(toman.currencyEvidence!.detectedUnit, SmsMoneyUnit.toman);
    },
  );
  final rejected = <String>[
    '${realBankSms[0]}\nرمز یکبار مصرف 123456',
    '${realBankSms[0]}\nتراکنش ناموفق',
    '${realBankSms[0]}\nمبلغ 700,000 ریال',
    realBankSms[0].replaceFirst(
      'مبلغ  700,000 ريال',
      'مبلغ  700,000 ريال تومان',
    ),
    realBankSms[0].replaceFirst('700,000', '70,00'),
    realBankSms[0].replaceFirst('700,000', '9223372036854775808'),
    realBankSms[0].replaceFirst('700,000', '0'),
    realBankSms[0].replaceFirst('1405/7/7', '1405/7/31'),
    realBankSms[0].replaceFirst('1405/7/7', '1405/12/30'),
    realBankSms[0].replaceFirst('18:53:40', '24:53:40'),
    realBankSms[2].replaceFirst('05/07/05', '05/13/05'),
    realBankSms[8].replaceFirst('3,000,000-', '3,000,000+'),
    realBankSms[8].replaceFirst('3,000,000-', '-3,000,000-'),
    realBankSms[0].replaceFirst('برداشت از', 'واریز به برداشت از'),
    realBankSms[12].replaceFirst('واريز به', 'برداشت از'),
    realBankSms[0].replaceFirst(
      'مانده 85,196,567 ريال',
      'مانده 85,196,567 دلار',
    ),
    realBankSms[4].replaceFirst(
      'مانده: 208,461,111',
      'مانده: 922337203685477581',
    ),
  ];
  for (var i = 0; i < rejected.length; i++) {
    test('reject ambiguous/malformed counterexample $i', () {
      expect(parser.tryParse(text: rejected[i], currency: 'IRR'), isNull);
    });
  }
  test('old labelled grammar remains unchanged', () {
    const text =
        'amount: 25 toman; type: deposit; balance: 900 rial; date: 1405/07/07; time: 18:53';
    final prior = const GenericBankSmsParser().tryParse(
      text: text,
      currency: 'IRR',
    )!;
    final current = parser.parse(text: text, currency: 'IRR');
    expect(current.amount, prior.amount);
    expect(current.balance, prior.balance);
    expect(current.occurredAt, prior.occurredAt);
    expect(
      parser.tryParse(text: 'amount: 25; balance: 900', currency: 'IRR'),
      isNull,
    );
  });
}
