import 'package:flutter_test/flutter_test.dart';
import 'package:planact/features/inbox/application/inbox_use_cases.dart';
import 'package:planact/features/inbox/domain/inbox.dart';
import 'package:planact/features/inbox/domain/sms_currency_evidence.dart';

import '../fixtures/real_bank_sms.dart';

void main() {
  const parser = LocalSmsParser();
  // Reported Sina layouts, with the private account replaced. In particular,
  // preserve the trailing account whitespace and Arabic yeh from the source.
  final sinaReports = [
    (
      text: 'بانک سينا\nبرداشت از  123-456-1234567-1 \nمبلغ  38,470,144 ريال\nمانده 2,802,961 ريال\nزمان : 1405/7/23 ; 17:46:44',
      amount: 38470144,
      balance: 2802961,
      direction: TransactionDirection.outgoing,
      at: DateTime(2026, 10, 15, 17, 46, 44),
    ),
    (
      text: 'بانک سينا\nبرداشت از  123-456-1234567-1 \nمبلغ  700,000 ريال\nمانده 41,273,105 ريال\nزمان : 1405/7/23 ; 08:42:02',
      amount: 700000,
      balance: 41273105,
      direction: TransactionDirection.outgoing,
      at: DateTime(2026, 10, 15, 8, 42, 2),
    ),
    (
      text: 'بانک سينا\nواريز به  123-456-1234567-1 \nمبلغ  304,554 ريال\nمانده 49,973,525 ريال\nزمان : 1405/7/15 ; 19:03:47',
      amount: 304554,
      balance: 49973525,
      direction: TransactionDirection.incoming,
      at: DateTime(2026, 10, 7, 19, 3, 47),
    ),
  ];
  for (var i = 0; i < sinaReports.length; i++) {
    test('reported Sina message ${i + 1} retains amount, balance and date', () {
      final sample = sinaReports[i];
      final parsed = parser.parse(text: sample.text, currency: 'IRR');
      expect(parsed.amount.minorUnits, sample.amount);
      expect(parsed.amount.currency, 'IRR');
      expect(parsed.balance!.minorUnits, sample.balance);
      expect(parsed.direction, sample.direction);
      expect(parsed.bank, 'سینا');
      expect(parsed.accountHint, '123-456-1234567-1');
      expect(parsed.occurredAt, sample.at);
      expect(parsed.currencyEvidence!.detectedUnit, SmsMoneyUnit.rial);
      expect(parsed.currencyEvidence!.requiresSelection, isFalse);
      expect(parsed.isTransfer, isFalse);
      expect(parsed.quality, ParseQuality.high);
    });
  }
  test('Sina account bidi marks from Android do not block parsing', () {
    const body =
        'بانک سينا\n'
        'برداشت از \u202A111-222-3334444-5\u202C\n'
        'مبلغ  123,456 ريال\n'
        'مانده 7,654,321 ريال\n'
        'زمان : 1405/7/27 ; 07:18:24';
    final parsed = parser.parse(text: body, currency: 'IRR');

    expect(parsed.bank, 'سینا');
    expect(parsed.accountHint, '111-222-3334444-5');
    expect(parsed.amount.minorUnits, 123456);
    expect(parsed.direction, TransactionDirection.outgoing);
    expect(parsed.occurredAt, DateTime(2026, 10, 19, 7, 18, 24));
  });
  test('device bank transaction layouts remain conservative but readable', () {
    final cases =
        <
          ({
            String name,
            String text,
            int amount,
            TransactionDirection direction,
            String? bank,
            String? account,
            DateTime? occurredAt,
          })
        >[
          (
            name: 'رسالت با خطوط خالی',
            text: '12.3456789.0\n\n-98,765,432 \n\n07/18_20:20\n\nمانده: 12,345,678',
            amount: 98765432,
            direction: TransactionDirection.outgoing,
            bank: null,
            account: '12.3456789.0',
            occurredAt: null,
          ),
          (
            name: 'مهر ایران با ساعت تک‌رقمی',
            text: '\u202A123456789012345678\u202C\n43,210,000-\n1405/7/7-6:47\nمانده:98,765,432',
            amount: 43210000,
            direction: TransactionDirection.outgoing,
            bank: null,
            account: '123456789012345678',
            occurredAt: DateTime(2026, 9, 29, 6, 47),
          ),
          (
            name: 'ایران‌زمین با مانده پیش از تاریخ',
            text: '\u202A123-45-6789012-3\u202C\n+12,345,000\nمانده 98,765,432\n1405/7/5-19:47',
            amount: 12345000,
            direction: TransactionDirection.incoming,
            bank: null,
            account: '123-45-6789012-3',
            occurredAt: DateTime(2026, 9, 27, 19, 47),
          ),
          (
            name: 'پارسیان با تاریخ و ساعت جدا',
            text:
                '12345678901234\nمبلغ:12,345,678-\nمانده:8,765,432\n10/10\n17:26',
            amount: 12345678,
            direction: TransactionDirection.outgoing,
            bank: null,
            account: '12345678901234',
            occurredAt: null,
          ),
          (
            name: 'مسکن با پرداخت قسط',
            text: 'بانک مسکن\nواریز قسط به مبلغ:1234000ریال\nزمان:1405/07/09 09:16:16\nاز کارت:1111222233334444\nبه کارت:5555666677778888\nتعداد اقساط پرداختی :12\nمانده معوق :0\nمانده جریمه :0\nشماره پیگیری:54321',
            amount: 1234000,
            direction: TransactionDirection.outgoing,
            bank: 'مسکن',
            account: '1111222233334444',
            occurredAt: DateTime(2026, 10, 1, 9, 16, 16),
          ),
        ];
    for (final sample in cases) {
      final parsed = parser.tryParse(text: sample.text, currency: 'IRR');
      expect(parsed, isNotNull, reason: sample.name);
      final value = parsed!;
      expect(value.amount.minorUnits, sample.amount, reason: sample.name);
      expect(value.direction, sample.direction, reason: sample.name);
      expect(value.bank, sample.bank, reason: sample.name);
      expect(value.accountHint, sample.account, reason: sample.name);
      expect(value.occurredAt, sample.occurredAt, reason: sample.name);
    }
    expect(
      parser.tryParse(
        text: 'محرمانه\nخرید\nاسنپ\n600,000\nرمز:91968\n1405/07/26-14:21:51',
        currency: 'IRR',
      ),
      isNull,
    );
  });
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
