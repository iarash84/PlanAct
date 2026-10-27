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
  final syntheticBankReports = [
    (
      bank: 'رسالت',
      text: 'بانک رسالت\nواریز به  321-654-9876543-2\nمبلغ: ۱۲۳٬۴۵۰ ریال\nموجودی: ۹۸۷٬۶۵۰ ریال\nزمان: 1405/7/23 - 08:42:02',
      amount: 123450,
      direction: TransactionDirection.incoming,
    ),
    (
      bank: 'ایران‌زمین',
      text: 'بانک ایران‌زمین\nواریز به  456-789-1234567-3\nمبلغ: ۲۵۰٬۰۰۰ تومان\nمانده: ۱٬۷۵۰٬۰۰۰ تومان\nزمان: 1405/7/24 - 09:15',
      amount: 2500000,
      direction: TransactionDirection.incoming,
    ),
  ];
  for (final sample in syntheticBankReports) {
    test(
      '${sample.bank} synthetic deposit is parsed without real SMS data',
      () {
        final parsed = parser.parse(text: sample.text, currency: 'IRR');
        expect(parsed.bank, sample.bank);
        expect(parsed.amount.minorUnits, sample.amount);
        expect(parsed.direction, sample.direction);
        expect(parsed.balance, isNotNull);
        expect(parsed.accountHint, contains('-'));
        expect(parsed.occurredAt, isNotNull);
      },
    );
  }
  test(
    'Sina account bidi controls still stage a bank transaction suggestion',
    () async {
      const message =
          'بانک سينا\r\n'
          'برداشت از  \u202a123-456-7890123-4\u202c \r\n'
          'مبلغ  123,450 ريال\r\n'
          'مانده 987,650 ريال\r\n'
          'زمان : 1405/7/23 ; 17:46:44';
      final parsed = parser.parse(text: message, currency: 'IRR');
      expect(parsed.amount.minorUnits, 123450);
      expect(parsed.balance!.minorUnits, 987650);
      expect(parsed.direction, TransactionDirection.outgoing);
      expect(parsed.bank, 'سینا');
      expect(parsed.accountHint, '123-456-7890123-4');
      expect(parsed.occurredAt, DateTime(2026, 10, 15, 17, 46, 44));
      expect(parsed.quality, ParseQuality.high);
      final suggestion = await InboxUseCases(InMemoryInboxRepository())
          .stageSms(
            rawText: message,
            sourceKey: 'synthetic-bidi-sina',
            currency: 'IRR',
            importedAt: DateTime.utc(2026, 10, 21),
          );
      expect(suggestion.draft.amount.minorUnits, 123450);
      expect(suggestion.draft.bank, 'سینا');
      expect(suggestion.draft.accountHint, '123-456-7890123-4');
      expect(suggestion.draft.direction, TransactionDirection.outgoing);
    },
  );
  test('one-line Sina deposit stages with explicit receipt-date fallback', () async {
    const message =
        'اعلام تراکنش مبلغ 200,000 ریال بابت واریز به حساب 1234567890 از بانک سینا ثبت شد.';
    final parsed = parser.parse(text: message, currency: 'IRR');
    expect(parsed.amount.minorUnits, 200000);
    expect(parsed.currencyEvidence!.sourceAmount, 200000);
    expect(parsed.currencyEvidence!.detectedUnit, SmsMoneyUnit.rial);
    expect(parsed.direction, TransactionDirection.incoming);
    expect(parsed.bank, 'سینا');
    expect(parsed.accountHint, isNull);
    expect(parsed.balance, isNull);
    expect(parsed.occurredAt, isNull);
    expect(parsed.sourceDate, isNull);
    expect(parsed.sourceTime, isNull);
    expect(parsed.quality, ParseQuality.medium);

    final suggestion = await InboxUseCases(InMemoryInboxRepository()).stageSms(
      rawText: message,
      sourceKey: 'synthetic-one-line-sina-deposit',
      currency: 'IRR',
      importedAt: DateTime.utc(2026, 10, 21, 8, 30),
    );
    expect(suggestion.draft.amount.minorUnits, 200000);
    expect(suggestion.draft.type, 'income');
    expect(suggestion.draft.bank, 'سینا');
    expect(suggestion.draft.accountHint, isNull);
    expect(suggestion.draft.dateSource, TransactionDateSource.receipt);
    expect(suggestion.draft.occurredAt, DateTime.utc(2026, 10, 21, 8, 30));
  });
  test('one-line Sina grammar rejects ambiguous and conflicting messages', () {
    const message =
        'اعلام تراکنش مبلغ 200,000 ریال بابت واریز به حساب 1234567890 از بانک سینا ثبت شد.';
    final invalidMessages = [
      message.replaceFirst('واریز به حساب', 'برداشت از حساب'),
      message.replaceFirst(' از بانک سینا', ''),
      message.replaceFirst(' ریال', ''),
      message.replaceFirst(' به حساب 1234567890', ' به'),
      message.replaceFirst(' ثبت شد.', ' و مبلغ 100 ریال ثبت شد.'),
    ];
    for (var i = 0; i < invalidMessages.length; i++) {
      expect(
        parser.tryParse(text: invalidMessages[i], currency: 'IRR'),
        isNull,
        reason: 'counterexample $i',
      );
    }
  });
  test('sender address is retained on the staged transaction draft', () async {
    const message =
        'بانک رسالت\nواریز به  321-654-9876543-2\nمبلغ: ۱۲۳٬۴۵۰ ریال\nموجودی: ۹۸۷٬۶۵۰ ریال\nزمان: 1405/7/23 - 08:42:02';
    final suggestion = await InboxUseCases(InMemoryInboxRepository()).stageSms(
      rawText: message,
      sourceKey: 'synthetic-resalat-address',
      sourceAddress: 'ResalatBank',
      currency: 'IRR',
      importedAt: DateTime.utc(2026, 10, 21),
    );
    expect(suggestion.draft.sourceAddress, 'ResalatBank');
    final review = suggestion.draft.toReviewJson();
    expect(review['sourceAddress'], 'ResalatBank');
    expect(
      TransactionDraft.fromReviewJson(review).sourceAddress,
      'ResalatBank',
    );
  });
  test(
    'identical SMS bodies with distinct provider keys remain separate',
    () async {
      final inbox = InboxUseCases(InMemoryInboxRepository());
      const message = 'برداشت مبلغ ۲۵۰۰';
      final receivedAt = DateTime.utc(2026, 10, 21, 8, 30);
      final first = await inbox.stageSms(
        rawText: message,
        sourceKey: 'android-sms:synthetic-1',
        currency: 'IRR',
        importedAt: receivedAt,
      );
      final second = await inbox.stageSms(
        rawText: message,
        sourceKey: 'android-sms:synthetic-2',
        currency: 'IRR',
        importedAt: receivedAt,
      );
      expect(second.id, isNot(first.id));
      expect(second.draft.id, isNot(first.draft.id));
    },
  );
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
