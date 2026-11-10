import 'package:flutter_test/flutter_test.dart';
import 'package:planact/features/inbox/application/inbox_use_cases.dart';
import 'package:planact/features/inbox/application/evidence_bank_sms_fallback.dart';
import 'package:planact/features/inbox/application/sms_parser_support.dart';
import 'package:planact/features/inbox/domain/inbox.dart';
import 'package:planact/features/inbox/domain/sms_currency_evidence.dart';

// Independent synthetic evidence grammar, not sampled personal messages.
const evidenceSms =
    'برداشت از حساب: ****0123\n'
    'مبلغ: ۱۲٬۵۰۱ تومان\nمانده: ۸۰٬۰۰۰ ریال';

void main() {
  const parser = LocalSmsParser();
  ParsedSms? parse(String text, {String? sender, String currency = 'IRR'}) =>
      parser.tryParse(text: text, currency: currency, sourceAddress: sender);

  test(
    'unknown sender supplies no identity; evidence yields exact review draft',
    () {
      final value = parse(evidenceSms, sender: 'UNVERIFIED')!;
      expect(value.amount.minorUnits, 125010);
      expect(value.balance!.minorUnits, 80000);
      expect(value.currencyEvidence!.sourceAmount, 12501);
      expect(value.currencyEvidence!.detectedUnit, SmsMoneyUnit.toman);
      expect(value.accountHint, '****0123');
      expect(value.bank, isNull);
      expect(value.direction, TransactionDirection.outgoing);
      expect(value.quality, ParseQuality.medium);
      expect(value.confidence, 60);
      expect(value.occurredAt, isNull);
      expect(value.sourceDate, isNull);
      expect(value.sourceTime, isNull);
    },
  );

  test('field order and shared Arabic/digit/punctuation normalization', () {
    final value = parse(
      'مانده： ۸۰٬۰۰۰ ريال\r'
      'مبلغ： ۱۲٬۵۰۱ تومان\r\u200fواريز به حساب： ****0123',
    )!;
    expect(value.amount.minorUnits, 125010);
    expect(value.direction, TransactionDirection.incoming);
    final labelled = parse('نوع： واريز\rمبلغ： ۱۲٬۵۰۱ ريال')!;
    expect(labelled.amount.minorUnits, 12501);
    expect(labelled.direction, TransactionDirection.incoming);
  });

  test('missing unit stays unresolved, balance never supplies amount unit', () {
    final value = parse(evidenceSms.replaceFirst(' تومان', ''))!;
    expect(value.amount.minorUnits, 12501);
    expect(value.currencyEvidence!.requiresSelection, isTrue);
  });

  test('validated source date and time stay independent', () {
    final dateOnly = parse('$evidenceSms\nتاریخ: 1405/07/19')!;
    expect(dateOnly.sourceDate, '1405/07/19');
    expect(dateOnly.sourceTime, isNull);
    expect(dateOnly.occurredAt, isNull);
    final full = parse('$evidenceSms\nتاریخ: 1405/07/19\nساعت: 18:23')!;
    expect(full.occurredAt, DateTime(2026, 10, 11, 18, 23));
    expect(full.quality, ParseQuality.medium);
  });

  test('transfer evidence remains explicit and directional', () {
    for (final label in ['انتقال از', 'انتقال به']) {
      final value = parse(evidenceSms.replaceFirst('برداشت از', label))!;
      expect(value.isTransfer, isTrue);
      expect(
        value.direction,
        label.endsWith('به')
            ? TransactionDirection.incoming
            : TransactionDirection.outgoing,
      );
    }
  });

  test('failed known-family messages do not enter weaker fallback', () {
    for (final sender in ['Bank Mellat', 'PARSIANBANK', 'IZBANK', '100025']) {
      expect(parse(evidenceSms, sender: sender), isNull);
      expect(parse('نوع: برداشت\nمبلغ: 1000 ریال', sender: sender), isNull);
    }
    expect(parse('بانک ملت\n$evidenceSms'), isNull);
    expect(parse(evidenceSms, currency: 'USD'), isNull);
  });

  final adversarial = <String>[
    '$evidenceSms\nمبلغ: ۱۲٬۵۰۱ تومان',
    '$evidenceSms\nموجودی: ۸۰٬۰۰۰ ریال',
    '$evidenceSms\nواریز به حساب: ****0123',
    '$evidenceSms\nرمز پویا: 123456',
    '$evidenceSms\nشناسه تایید برداشت: 123456',
    '$evidenceSms\nناموفق',
    '$evidenceSms\nپیشنهاد ویژه',
    '$evidenceSms\nکارمزد: 100 ریال',
    '$evidenceSms\nتاریخ: 1404/12/30',
    '$evidenceSms\nتاریخ: 07/19',
    '$evidenceSms\nساعت: 24:00',
    evidenceSms.replaceFirst('۱۲٬۵۰۱', '12,50'),
    evidenceSms.replaceFirst('۱۲٬۵۰۱', '0'),
    evidenceSms.replaceFirst('۱۲٬۵۰۱', '922337203685477581'),
    evidenceSms.replaceFirst('۱۲٬۵۰۱', '-12501'),
    evidenceSms.replaceFirst('۱۲٬۵۰۱', '+12501'),
    evidenceSms.replaceFirst('۱۲٬۵۰۱', '12.501'),
    evidenceSms.replaceFirst('۱۲٬۵۰۱', '12501 ریال 900'),
    evidenceSms.replaceFirst('برداشت از', 'امکان برداشت از'),
    evidenceSms.replaceFirst('برداشت از حساب: ****0123\n', ''),
    evidenceSms.replaceFirst('مانده: ۸۰٬۰۰۰ ریال', ''),
  ];
  for (var i = 0; i < adversarial.length; i++) {
    test('rejects independent adversarial case $i', () {
      final text = adversarial[i];
      expect(
        const EvidenceBankSmsFallback().parse(
          const SmsNormalizer().normalize(text: text, currency: 'IRR'),
        ),
        isNull,
      );
      if (i == 19) {
        // Existing labelled imports may retain an unknown direction for review;
        // this is not evidence-fallback recognition or permission to confirm.
        expect(parse(text)!.direction, TransactionDirection.unknown);
        expect(parse(text)!.accountHint, isNull);
      } else {
        expect(parse(text), isNull);
      }
    });
  }

  test('Parsian opaque tail cannot conceal another financial field', () {
    const base = '123456789012\nمبلغ:1000-\nمانده:9000\n07/19';
    expect(parse(base, sender: 'PARSIANBANK'), isNotNull);
    for (final tail in ['مبلغ:2000-', 'مانده:8000', 'واریز 500 ریال', '+500']) {
      expect(parse('$base\n$tail', sender: 'PARSIANBANK'), isNull);
    }
  });

  test('Mellat label/sign contradiction cannot become incoming', () {
    for (final operation in ['برداشت1000+', 'واریز1000-']) {
      expect(
        parse(
          'حساب12345678\n$operation\nمانده9000\n05/07/19-12:30',
          sender: 'Bank Mellat',
        ),
        isNull,
      );
    }
  });
}
