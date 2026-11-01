import 'package:flutter_test/flutter_test.dart';
import 'package:planact/features/inbox/application/inbox_use_cases.dart';
import 'package:planact/features/inbox/domain/inbox.dart';

// Entirely synthetic; these are not captured bank messages or real identifiers.
const syntheticSms = '''بانک: نمونه
نوع: برداشت
مبلغ: ۱۲٬۵۰۰ ریال
مانده: ۹۹٬۰۰۰ ریال
تاریخ: ۱۴۰۵/۰۷/۱۹
ساعت: ۱۸:۲۳:۴۵
حساب: ****۱۲۳۴
پیگیری: TEST-42
پذیرنده: فروشگاه نمونه''';

void main() {
  const parser = LocalSmsParser();
  ParsedSms? parse(String text) => parser.tryParse(text: text, currency: 'IRR');

  test('synthetic Persian labelled extraction does not confuse balance', () {
    final result = parse(syntheticSms)!;
    expect(result.amount.minorUnits, 12500);
    expect(result.balance!.minorUnits, 99000);
    expect(result.bank, 'نمونه');
    expect(result.accountHint, '****1234');
    expect(result.reference, 'TEST-42');
    expect(result.merchant, 'فروشگاه نمونه');
    expect(result.direction, TransactionDirection.outgoing);
    expect(result.occurredAt, DateTime(2026, 10, 11, 18, 23, 45));
  });

  test('English labels Arabic digits and explicit Gregorian leap date', () {
    final result = parse(
      'type: deposit\namount: ٢,٥٠٠ toman\n'
      'date: 2024-02-29\ntime: 00:00',
    )!;
    expect(result.amount.minorUnits, 25000);
    expect(result.direction, TransactionDirection.incoming);
    expect(result.occurredAt, DateTime(2024, 2, 29));
  });

  test('unknown and transfer never infer income or expense', () {
    for (final operation in ['unknown', 'transfer', 'انتقال', 'کارت به کارت']) {
      final result = parse('type: $operation\namount: 100 rial')!;
      expect(result.direction, TransactionDirection.unknown);
    }
    expect(parse('amount: 100 rial')!.direction, TransactionDirection.unknown);
  });

  test('missing or conflicting unit remains ambiguous', () {
    for (final amount in ['100', 'rial 100 toman']) {
      expect(
        parse('amount: $amount')!.currencyEvidence!.requiresSelection,
        true,
      );
    }
  });

  test('missing time or date never invents midnight', () {
    expect(parse('amount: 100 rial\ndate: 2026-10-11')!.occurredAt, isNull);
    expect(parse('amount: 100 rial\ntime: 12:30')!.occurredAt, isNull);
  });

  test('all invalid dates are rejected', () {
    for (final date in [
      '2025-02-29',
      '2026-04-31',
      '2026-00-01',
      '1404/12/30',
      '1405/07/31',
      '1405/13/01',
      '26-10-11',
    ]) {
      expect(parse('amount: 100 rial\ndate: $date\ntime: 12:30'), isNull);
    }
  });
  test('all invalid times are rejected', () {
    for (final time in [
      '24:00',
      '12:60',
      '12:00:60',
      '1:2',
      '12:00 trailing',
    ]) {
      expect(parse('amount: 100 rial\ndate: 2026-10-11\ntime: $time'), isNull);
    }
  });
  for (final text in [
    'amount: 100 rial\namount: 200 rial',
    'amount: 100 rial\namount: 100 rial',
    'balance: 100 rial',
    'amount: 100 rial\nbalance: 900 rial\nbalance: 800 rial',
    'OTP amount: 100 rial',
    'نوع: رمز پویا\nمبلغ: 100 ریال',
    'type: failed\namount: 100 rial',
    'type: notification\namount: 100 rial',
    'خرید ناموفق مبلغ 100 ریال',
    'You could receive amount: 100 rial',
    'amount: 100 rial\nunknown field: deposit',
    'amount: 1,23 rial',
    'amount: 100.5 rial',
    'amount: 0 rial',
    'amount: 9223372036854775808 rial',
    'amount: 922337203685477581 toman',
    'amount: 100 rial\naccount: 1234 other text',
    'amount: 100 rial\nreference: ABC DEF',
    'amount: 100 rial\nbank: sample amount: 900 rial',
  ]) {
    test('unsupported/ambiguous synthetic fixture ${text.hashCode}', () {
      expect(parse(text), isNull);
    });
  }
  test('documented compact synthetic direction plus amount', () {
    expect(parse('برداشت مبلغ 1000')!.amount.minorUnits, 1000);
    expect(
      parse('واریز مبلغ: 1000 ریال')!.direction,
      TransactionDirection.incoming,
    );
  });
}
