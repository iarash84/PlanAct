import 'package:flutter_test/flutter_test.dart';
import 'package:planact/features/inbox/application/inbox_use_cases.dart';
import 'package:planact/features/inbox/domain/inbox.dart';
import 'package:planact/features/inbox/domain/sms_currency_evidence.dart';

void main() {
  const parser = LocalSmsParser();
  ParsedSms? parse(String text, {String? sender}) =>
      parser.tryParse(text: text, currency: 'IRR', sourceAddress: sender);

  test('explicit toman converts exactly; missing timestamp stays absent', () {
    final value = parse(
      'مبلغ 2,000,001 تومان واریز به حساب شما انجام شد.\nمانده: 3,000,002 تومان',
      sender: 'PARSIANBANK',
    )!;
    expect(value.amount.minorUnits, 20000010);
    expect(value.balance!.minorUnits, 30000020);
    expect(value.currencyEvidence!.sourceAmount, 2000001);
    expect(value.currencyEvidence!.detectedUnit, SmsMoneyUnit.toman);
    expect(value.direction, TransactionDirection.incoming);
    expect(value.occurredAt, isNull);
    expect(value.sourceDate, isNull);
    expect(value.sourceTime, isNull);
  });

  test('masked source and unsigned unit retain unresolved evidence', () {
    final value = parse(
      'بانک خاورمیانه\nانتقال از اینترنت بانک به\nکارت 9525\n-5,699,000\n0**/********5\nمانده **********\n07/01\n19:27',
    )!;
    expect(value.amount.minorUnits, 5699000);
    expect(value.balance, isNull);
    expect(value.accountHint, '0**/********5');
    expect(value.currencyEvidence!.requiresSelection, isTrue);
    expect(value.sourceDate, '07/01');
    expect(value.sourceTime, '19:27');
    expect(value.occurredAt, isNull);
    expect(value.direction, TransactionDirection.outgoing);
    expect(value.isTransfer, isTrue);
  });

  test(
    'transfer without a direction stays unknown and cannot become expense',
    () {
      final value = parse(
        'مبلغ 1,000,000 ریال انتقال یافت.\nمانده: 500,000 ریال',
        sender: 'MELLIBANK',
      )!;
      expect(value.direction, TransactionDirection.unknown);
      expect(value.isTransfer, isTrue);
    },
  );

  test('service fee is not mistaken for password', () {
    final value = parse(
      'بانک خاورمیانه\n0**/********5\n-660,000\n07/01\n15:09\nمانده **********\nکارمزد اطلاع رسانی پیامکی\nشش ماهه دوم سال 04',
    )!;
    expect(value.amount.minorUnits, 660000);
    expect(value.direction, TransactionDirection.outgoing);
    expect(value.isTransfer, isFalse);
  });

  const sepah =
      'بانک سپه\nواریز سود به: 01000000000001\nمبلغ: 87,450ریال\nزمان: 1405/6/11-20:16\nمانده: 9,876,543ریال';
  test('full Jalali stamp becomes date-time with exact amount and balance', () {
    final value = parse(sepah)!;
    expect(value.amount.minorUnits, 87450);
    expect(value.balance!.minorUnits, 9876543);
    expect(value.occurredAt, DateTime(2026, 9, 2, 20, 16));
    expect(value.direction, TransactionDirection.incoming);
  });

  test('invalid dates, times, signs, grouping and overflow are rejected', () {
    for (final text in [
      sepah.replaceFirst('1405/6/11', '1405/13/11'),
      sepah.replaceFirst('1405/6/11', '1405/12/30'),
      sepah.replaceFirst('20:16', '24:16'),
      sepah.replaceFirst('87,450', '-87,450'),
      sepah.replaceFirst('87,450', '87,45'),
      sepah.replaceFirst('87,450', '9223372036854775808'),
      '$sepah\nرمز پویا: 123456',
      '$sepah\nناموفق',
      '$sepah\nواریز: 500 ریال',
    ]) {
      expect(parse(text), isNull);
    }
  });

  test('authorization and purchase codes never prove completed payment', () {
    expect(
      parse(
        'بانک ملی (هشدار)\nشناسه تایید برداشت از حساب شما:78901\nمبلغ:78,456,123\nبه حساب:78**45',
        sender: 'Bank Melli',
      ),
      isNull,
    );
    expect(
      parse('خرید\nاسنپ\nمبلغ 234,901\nCode:23456789', sender: 'PARSIANBANK'),
      isNull,
    );
  });

  test('unverified sender cannot opt into sender-only prose grammar', () {
    const text =
        'مبلغ 1,500,000 ریال واریز به حساب شما انجام شد.\nمانده: 2,500,000 ریال';
    expect(parse(text, sender: 'UNKNOWN'), isNull);
    expect(parse(text, sender: '+98700717')!.amount.minorUnits, 1500000);
  });
}
