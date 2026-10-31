import 'package:flutter_test/flutter_test.dart';
import 'package:planact/features/inbox/application/inbox_use_cases.dart';
import 'package:planact/features/inbox/application/real_bank_sms_parser.dart';
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
  test('parses a raw Sina corpus deposit with a starred header', () {
    final parsed = const RealBankSmsParser().tryParse(
      text:
          '*بانک سينا*\n'
          'واريز به \u202A901-678-3456789-7\u202C\n'
          'مبلغ  4,678,345 ريال\n'
          'مانده 90,678,345 ريال\n'
          'زمان : 1404/11/17 ; 11:05:35',
      currency: 'IRR',
      sourceAddress: 'Sina Bank',
    );
    expect(parsed, isNotNull);
    final value = parsed!;
    expect(value.amount.minorUnits, 4678345);
    expect(value.direction, TransactionDirection.incoming);
    expect(value.bank, 'سینا');
  });

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
  group('layered bank profiles', () {
    const layeredParser = RealBankSmsParser();

    test('parses Bank Refah signed withdrawal with partial timestamp', () {
      final parsed = layeredParser.tryParse(
        text:
            'بانک رفاه\n'
            'حساب317777142\n'
            'کارت30,018,000-\n'
            'مانده134,403,080\n'
            '07/08-16:29',
        currency: 'IRR',
        sourceAddress: 'بانک رفاه',
      );

      final result = parsed!;
      expect(result.bank, 'رفاه');
      expect(result.accountHint, '317777142');
      expect(result.amount.minorUnits, 30018000);
      expect(result.balance!.minorUnits, 134403080);
      expect(result.direction, TransactionDirection.outgoing);
      expect(result.sourceDate, '07/08');
      expect(result.sourceTime, '16:29');
      expect(result.occurredAt, isNull);
      expect(result.quality, ParseQuality.medium);
    });

    test('parses Bank Refah signed deposit with sender alias', () {
      final parsed = layeredParser.tryParse(
        text:
            'بانک رفاه\n'
            'حساب317777142\n'
            'کارت12,000,000+\n'
            'مانده164,421,080\n'
            '07/08-06:39',
        currency: 'IRR',
        sourceAddress: 'BANK REFAH',
      );

      final result = parsed!;
      expect(result.bank, 'رفاه');
      expect(result.amount.minorUnits, 12000000);
      expect(result.balance!.minorUnits, 164421080);
      expect(result.direction, TransactionDirection.incoming);
    });

    test('parses Bank Mellat four-line signed transaction', () {
      final parsed = layeredParser.tryParse(
        text:
            'حساب1234567890\n'
            'برداشت123,890-\n'
            'مانده123,890,567\n'
            '12/45/89-01:07',
        currency: 'IRR',
        sourceAddress: 'BANK MELLAT',
      );

      final result = parsed!;
      expect(result.bank, 'ملت');
      expect(result.accountHint, '1234567890');
      expect(result.amount.minorUnits, 123890);
      expect(result.balance!.minorUnits, 123890567);
      expect(result.direction, TransactionDirection.outgoing);
      expect(result.sourceDate, '12/45/89');
      expect(result.sourceTime, '01:07');
      expect(result.occurredAt, isNull);
    });

    test('parses National Bank deposit with compact date evidence', () {
      final parsed = layeredParser.tryParse(
        text:
            'بانك ملي ايران\n'
            'واریز:3,000,000+\n'
            'حساب:70008\n'
            'مانده:4,953,268\n'
            '0705-17:00',
        currency: 'IRR',
        sourceAddress: 'BANK MELLI',
      );

      final result = parsed!;
      expect(result.bank, 'ملی ایران');
      expect(result.accountHint, '70008');
      expect(result.amount.minorUnits, 3000000);
      expect(result.balance!.minorUnits, 4953268);
      expect(result.direction, TransactionDirection.incoming);
      expect(result.sourceDate, '0705');
      expect(result.sourceTime, '17:00');
      expect(result.occurredAt, isNull);
    });

    test('does not turn National Bank transfer into income', () {
      final text =
          'بانک ملی ایران\n'
          'انتقال:3,000,000-\n'
          'حساب:70008\n'
          'مانده:1,953,268\n'
          '0705-17:00';

      expect(
        layeredParser.tryParse(
          text: text,
          currency: 'IRR',
          sourceAddress: 'BANK MELLI',
        ),
        isNull,
      );
    });
  });

  group('additional bank message layouts', () {
    const parser = RealBankSmsParser();

    final samples =
        <
          ({
            String name,
            String text,
            String? bank,
            int amount,
            TransactionDirection direction,
            String? sourceAddress,
          })
        >[
          (
            name: 'National withdrawal',
            text:
                'بانك ملي ايران\n'
                'برداشت:3,000,000-\n'
                'حساب:70008\n'
                'مانده:4,953,268\n'
                '0705-17:00',
            bank: 'ملی ایران',
            amount: 3000000,
            direction: TransactionDirection.outgoing,
            sourceAddress: 'BANK MELLI',
          ),
          (
            name: 'National internet purchase',
            text:
                'بانك ملي ايران\n'
                'خريداينترنتي:75,000,000-\n'
                'حساب:70008\n'
                'مانده:310,452,489\n'
                '0612-19:57',
            bank: 'ملی ایران',
            amount: 75000000,
            direction: TransactionDirection.outgoing,
            sourceAddress: 'BANK MELLI',
          ),
          (
            name: 'National deposit',
            text:
                'بانك ملي ايران\n'
                'واريز:500,000,000+\n'
                'حساب:70008\n'
                'مانده:514,978,739\n'
                '0609-07:05',
            bank: 'ملی ایران',
            amount: 500000000,
            direction: TransactionDirection.incoming,
            sourceAddress: 'BANK MELLI',
          ),
          (
            name: 'City allowance',
            text:
                '*بانک شهر*\n'
                'واريز يارانه\n'
                'واريز به :7001000767658\n'
                'مبلغ:3,000,000ريال\n'
                'موجودي:8,092,213 ريال\n'
                '1405/06/30 21:32:32',
            bank: 'شهر',
            amount: 3000000,
            direction: TransactionDirection.incoming,
            sourceAddress: null,
          ),
          (
            name: 'City card purchase',
            text:
                '*بانک شهر*\n'
                'خريد با کارت\n'
                'برداشت از:7001000767658\n'
                'مبلغ:7,981,000ريال\n'
                'موجودي:2,114,257 ريال\n'
                '1405/04/31 17:51:48',
            bank: 'شهر',
            amount: 7981000,
            direction: TransactionDirection.outgoing,
            sourceAddress: null,
          ),
          (
            name: 'City bill payment',
            text:
                '*بانک شهر*\n'
                'پرداخت قبض\n'
                'برداشت از:7001000767658\n'
                'مبلغ:444,510ريال\n'
                'موجودي:4,077,940 ريال\n'
                '1405/03/15 22:06:08',
            bank: 'شهر',
            amount: 444510,
            direction: TransactionDirection.outgoing,
            sourceAddress: null,
          ),
          (
            name: 'Tourism labelled deposit',
            text:
                '*بانك گردشگری*\n'
                'فرشته\n'
                'واريز به: 154.9498.2400525.1\n'
                'مبلغ: 2,000,000 ريال\n'
                '05/06/02_12:05\n'
                'موجودي: 2,000,000 ريال',
            bank: 'گردشگری',
            amount: 2000000,
            direction: TransactionDirection.incoming,
            sourceAddress: null,
          ),
          (
            name: 'Tourism compact deposit',
            text:
                '777.888.18125929.1\n'
                '+41,000,000\n'
                '05/07_22:48\n'
                'مانده: 41,642,610',
            bank: null,
            amount: 41000000,
            direction: TransactionDirection.incoming,
            sourceAddress: null,
          ),
          (
            name: 'Tourism compact withdrawal',
            text:
                '777.888.18125929.1\n'
                '-34,537,910\n'
                '05/07_22:57\n'
                'مانده: 7,104,700',
            bank: null,
            amount: 34537910,
            direction: TransactionDirection.outgoing,
            sourceAddress: null,
          ),
        ];

    for (final sample in samples) {
      test('${sample.name} is recognized', () {
        final result = parser.tryParse(
          text: sample.text,
          currency: 'IRR',
          sourceAddress: sample.sourceAddress,
        );
        expect(result, isNotNull);
        expect(result!.bank, sample.bank);
        expect(result.amount.minorUnits, sample.amount);
        expect(result.direction, sample.direction);
      });
    }

    test(
      'National transfer remains a transfer and is not treated as income',
      () {
        final result = parser.tryParse(
          text:
              'بانك ملي ايران\n'
              'انتقال:3,000,000+\n'
              'حساب:70008\n'
              'مانده:310,543,489\n'
              '0612-20:22',
          currency: 'IRR',
          sourceAddress: 'BANK MELLI',
        );
        expect(result, isNull);
      },
    );
  });

  final resalatCompactMessages = [
    (
      text: '10.7291550.1\n-39,600\n08/03_20:14\nمانده: 335,232,811',
      amount: 39600,
      direction: TransactionDirection.outgoing,
      balance: 335232811,
    ),
    (
      text: '10.7291550.1\n-198,000,000\n08/03_20:14\nمانده: 335,272,411',
      amount: 198000000,
      direction: TransactionDirection.outgoing,
      balance: 335272411,
    ),
    (
      text: '10.7291550.1\n-90,000,000\n08/02_19:37\nمانده: 101,290,411',
      amount: 90000000,
      direction: TransactionDirection.outgoing,
      balance: 101290411,
    ),
    (
      text: '10.7291550.1\n-18,000\n08/02_19:37\nمانده: 101,272,411',
      amount: 18000,
      direction: TransactionDirection.outgoing,
      balance: 101272411,
    ),
    (
      text: '10.7291550.1\n-400,000,000\n08/02_19:35\nمانده: 191,370,411',
      amount: 400000000,
      direction: TransactionDirection.outgoing,
      balance: 191370411,
    ),
    (
      text: '10.7291550.1\n+538,300,000\n07/30_14:00\nمانده: 647,761,111',
      amount: 538300000,
      direction: TransactionDirection.incoming,
      balance: 647761111,
    ),
  ];
  for (var i = 0; i < resalatCompactMessages.length; i++) {
    test('Resalat compact message ${i + 1} is parsed independently', () {
      final sample = resalatCompactMessages[i];
      final parsed = parser.parse(
        text: sample.text,
        currency: 'IRR',
        sourceAddress: 'ResalatBank',
      );
      expect(parsed.bank, 'رسالت');
      expect(parsed.amount.minorUnits, sample.amount);
      expect(parsed.balance!.minorUnits, sample.balance);
      expect(parsed.direction, sample.direction);
      expect(parsed.accountHint, '10.7291550.1');
      expect(parsed.occurredAt, isNull);
      expect(parsed.sourceDate, isNotEmpty);
      expect(parsed.sourceTime, isNotEmpty);
      expect(parsed.quality, ParseQuality.medium);
    });
  }
  test(
    'Resalat compact SMS stages with sender-specific bank identity',
    () async {
      const message =
          '10.7291550.1\n'
          '+538,300,000\n'
          '07/30_14:00\n'
          'مانده: 647,761,111';
      final suggestion = await InboxUseCases(InMemoryInboxRepository())
          .stageSms(
            rawText: message,
            sourceKey: 'android-sms:resalat-compact-sample',
            sourceAddress: 'ResalatBank',
            currency: 'IRR',
            importedAt: DateTime.utc(2026, 10, 27, 10),
          );
      expect(suggestion.draft.bank, 'رسالت');
      expect(suggestion.draft.sourceAddress, 'ResalatBank');
      expect(suggestion.draft.direction, TransactionDirection.incoming);
      expect(suggestion.draft.amount.minorUnits, 538300000);
      expect(suggestion.draft.balance!.minorUnits, 647761111);
      expect(suggestion.draft.dateSource, TransactionDateSource.receipt);
      expect(suggestion.draft.occurredAt, DateTime.utc(2026, 10, 27, 10));
    },
  );
  final resalatHeaderVariants = [
    'بانک قرض‌الحسنه رسالت',
    'بانک قرض  الحسنه رسالت',
    'بانک قرض الحسنه رسالت',
    '*بانک قرض الحسنه رسالت*',
  ];
  for (var i = 0; i < resalatHeaderVariants.length; i++) {
    test('Resalat real sender header variant ${i + 1} is parsed', () {
      final message =
          '${resalatHeaderVariants[i]}\n'
          'برداشت از  321-654-9876543-2\n'
          'مبلغ: ۱۲۳٬۴۵۰ ریال\n'
          'موجودی: ۹۸۷٬۶۵۰ ریال\n'
          'زمان: 1405/7/23 - 08:42:02';
      final parsed = parser.parse(text: message, currency: 'IRR');
      expect(parsed.bank, 'رسالت');
      expect(parsed.amount.minorUnits, 123450);
      expect(parsed.balance!.minorUnits, 987650);
      expect(parsed.direction, TransactionDirection.outgoing);
      expect(parsed.accountHint, '321-654-9876543-2');
      expect(parsed.occurredAt, DateTime(2026, 10, 15, 8, 42, 2));
    });
  }
  test('Resalat account label is accepted without changing evidence', () {
    const message =
        'بانک قرض‌الحسنه رسالت\n'
        'واریز به حساب 321-654-9876543-2\n'
        'مبلغ: ۱۲۳٬۴۵۰ ریال\n'
        'مانده: ۹۸۷٬۶۵۰ ریال\n'
        'زمان: 1405/7/23 - 08:42:02';
    final parsed = parser.parse(text: message, currency: 'IRR');
    expect(parsed.bank, 'رسالت');
    expect(parsed.direction, TransactionDirection.incoming);
    expect(parsed.amount.minorUnits, 123450);
    expect(parsed.balance!.minorUnits, 987650);
  });
  final iranZaminMessages = [
    (
      text: '159-10-1812991-1\n+400,000,000\nمانده 475,306,009\n1405/8/2-19:35',
      amount: 400000000,
      balance: 475306009,
      direction: TransactionDirection.incoming,
    ),
    (
      text: '159-10-1812991-1\n-300,000,000\nمانده 75,366,009\n1405/7/30-9:04',
      amount: 300000000,
      balance: 75366009,
      direction: TransactionDirection.outgoing,
    ),
  ];
  for (var i = 0; i < iranZaminMessages.length; i++) {
    test('Iran Zamin real message ${i + 1} is sender-gated and parsed', () {
      final sample = iranZaminMessages[i];
      final parsed = parser.parse(
        text: sample.text,
        currency: 'IRR',
        sourceAddress: 'IZBANK',
      );
      expect(parsed.bank, 'ایران‌زمین');
      expect(parsed.amount.minorUnits, sample.amount);
      expect(parsed.balance!.minorUnits, sample.balance);
      expect(parsed.direction, sample.direction);
      expect(parsed.accountHint, '159-10-1812991-1');
      expect(parsed.sourceDate, isNotEmpty);
      expect(parsed.sourceTime, isNotEmpty);
      expect(parsed.occurredAt, isNotNull);
      expect(parsed.quality, ParseQuality.high);
    });
  }

  final mehrIranMessages = [
    (
      text:
          '302370012828479001\n90,000,000+\n1405/8/2-19:37\nمانده:102,559,660',
      amount: 90000000,
      balance: 102559660,
      direction: TransactionDirection.incoming,
    ),
    (
      text: '302370012828479001\n43,973,030-\n1405/7/7-6:47\nمانده:12,559,660',
      amount: 43973030,
      balance: 12559660,
      direction: TransactionDirection.outgoing,
    ),
  ];
  for (var i = 0; i < mehrIranMessages.length; i++) {
    test('Mehr Iran real message ${i + 1} is sender-gated and parsed', () {
      final sample = mehrIranMessages[i];
      final parsed = parser.parse(
        text: sample.text,
        currency: 'IRR',
        sourceAddress: 'B.QMEHRIRAN',
      );
      expect(parsed.bank, 'مهر ایران');
      expect(parsed.amount.minorUnits, sample.amount);
      expect(parsed.balance!.minorUnits, sample.balance);
      expect(parsed.direction, sample.direction);
      expect(parsed.accountHint, '302370012828479001');
      expect(parsed.sourceDate, isNotEmpty);
      expect(parsed.sourceTime, isNotEmpty);
      expect(parsed.occurredAt, isNotNull);
      expect(parsed.quality, ParseQuality.high);
    });
  }

  test('Iran Zamin and Mehr Iran grammars reject wrong senders and non-transaction SMS', () {
    const iranZamin =
        '159-10-1812991-1\n+400,000,000\nمانده 475,306,009\n1405/8/2-19:35';
    const mehrIran =
        '302370012828479001\n90,000,000+\n1405/8/2-19:37\nمانده:102,559,660';
    expect(
      parser.tryParse(
        text: iranZamin,
        currency: 'IRR',
        sourceAddress: 'B.QMEHRIRAN',
      ),
      isNull,
    );
    expect(
      parser.tryParse(text: mehrIran, currency: 'IRR', sourceAddress: 'IZBANK'),
      isNull,
    );
    expect(
      parser.tryParse(
        text: 'انتقال وجه پایا عادی\nاز: 302370012828479001\nبه: IR040590042481302335202001\nمبلغ 1,819,000,000 ريال',
        currency: 'IRR',
        sourceAddress: 'B.QMEHRIRAN',
      ),
      isNull,
    );
    expect(
      parser.tryParse(
        text: 'ورود به همراه بانک\n09:03:07-1405/07/30',
        currency: 'IRR',
        sourceAddress: 'IZBANK',
      ),
      isNull,
    );
  });

  test('Iran Zamin and Mehr Iran suggestions retain sender and stay staged', () async {
    const samples = [
      (
        text:
            '159-10-1812991-1\n+400,000,000\nمانده 475,306,009\n1405/8/2-19:35',
        sender: 'IZBANK',
        bank: 'ایران‌زمین',
      ),
      (
        text:
            '302370012828479001\n43,973,030-\n1405/7/7-6:47\nمانده:12,559,660',
        sender: 'B.QMEHRIRAN',
        bank: 'مهر ایران',
      ),
    ];
    for (final sample in samples) {
      final suggestion = await InboxUseCases(InMemoryInboxRepository())
          .stageSms(
            rawText: sample.text,
            sourceKey: 'android-sms:${sample.sender}',
            sourceAddress: sample.sender,
            currency: 'IRR',
            importedAt: DateTime.utc(2026, 10, 27),
          );
      expect(suggestion.draft.sourceAddress, sample.sender);
      expect(suggestion.draft.bank, sample.bank);
      expect(suggestion.draft.amount.minorUnits, greaterThan(0));
    }
  });

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
        640000,
      );
      final prefixed = realBankSms[8].replaceFirst('3,200,000-', '-3,200,000');
      expect(
        parser.parse(text: prefixed, currency: 'IRR').direction,
        TransactionDirection.outgoing,
      );
      final unitlessBalance = realBankSms[0].replaceFirst(
        '12,345,678 ريال',
        '12,345,678',
      );
      expect(
        parser
            .parse(text: unitlessBalance, currency: 'IRR')
            .balance!
            .minorUnits,
        12345678,
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
      expect(toman.amount.minorUnits, 6400000);
      expect(toman.currencyEvidence!.detectedUnit, SmsMoneyUnit.toman);
    },
  );
  final rejected = <String>[
    '${realBankSms[0]}\nرمز یکبار مصرف 654321',
    '${realBankSms[0]}\nتراکنش ناموفق',
    '${realBankSms[0]}\nمبلغ 640,000 ریال',
    realBankSms[0].replaceFirst(
      'مبلغ  640,000 ريال',
      'مبلغ  640,000 ريال تومان',
    ),
    realBankSms[0].replaceFirst('640,000', '64,00'),
    realBankSms[0].replaceFirst('640,000', '9223372036854775808'),
    realBankSms[0].replaceFirst('640,000', '0'),
    realBankSms[0].replaceFirst('1405/7/7', '1405/7/31'),
    realBankSms[0].replaceFirst('1405/7/7', '1405/12/30'),
    realBankSms[0].replaceFirst('18:53:40', '24:53:40'),
    realBankSms[2].replaceFirst('05/07/05', '05/13/05'),
    realBankSms[8].replaceFirst('3,200,000-', '3,200,000+'),
    realBankSms[8].replaceFirst('3,200,000-', '-3,200,000-'),
    realBankSms[0].replaceFirst('برداشت از', 'واریز به برداشت از'),
    realBankSms[12].replaceFirst('واريز به', 'برداشت از'),
    realBankSms[0].replaceFirst(
      'مانده 12,345,678 ريال',
      'مانده 12,345,678 دلار',
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
