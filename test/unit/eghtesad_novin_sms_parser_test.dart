import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:planact/features/inbox/application/inbox_use_cases.dart';
import 'package:planact/features/inbox/domain/inbox.dart';
import 'package:planact/features/inbox/domain/sms_currency_evidence.dart';

void main() {
  const parser = LocalSmsParser();
  final bodies = File('test/fixtures/device_sms_corpus/ENBANK.txt')
      .readAsStringSync()
      .split(RegExp(r'(?=^Row:)', multiLine: true))
      .where((row) => row.startsWith('Row:'))
      .map(
        (row) => row
            .substring(row.indexOf('body=') + 5)
            .replaceFirst(RegExp(r', date=\d+\s*$'), ''),
      )
      .toList();

  test('all 15 synthetic Novin rows preserve exact evidence without inventing year', () {
    expect(bodies, hasLength(15));
    for (var index = 0; index < bodies.length; index++) {
      final i = index + 1;
      final parsed = parser.tryParse(
        text: bodies[index],
        currency: 'IRR',
        sourceAddress: 'NOVIN_SYNTHETIC',
      );
      expect(parsed, isNotNull, reason: 'synthetic row $i');
      expect(parsed!.amount.minorUnits, 345678 + i * 21347);
      expect(parsed.amount.currency, 'IRR');
      expect(parsed.balance!.minorUnits, 45678901 + i * 31973);
      expect(
        parsed.direction,
        {1, 12}.contains(i)
            ? TransactionDirection.incoming
            : TransactionDirection.outgoing,
      );
      expect(parsed.accountHint, '246-135-90246-8');
      expect(parsed.bank, 'اقتصاد نوین');
      expect(parsed.currencyEvidence!.sourceAmount, 345678 + i * 21347);
      expect(parsed.currencyEvidence!.detectedUnit, SmsMoneyUnit.rial);
      expect(parsed.currencyEvidence!.requiresSelection, isFalse);
      expect(parsed.sourceDate, '4/${i + 2}');
      expect(
        parsed.sourceTime,
        '${(6 + i % 12).toString().padLeft(2, '0')}:${(i * 11 % 60).toString().padLeft(2, '0')}',
      );
      expect(parsed.occurredAt, isNull);
      expect(parsed.quality, ParseQuality.medium);
      expect(parsed.isTransfer, isFalse);
    }
  });

  const incoming =
      'واريز: 246-135-90246-8 \n+367,025ريال\n'
      'مانده:45710874ريال\n4/3-07:11\nمرکزآواي نوين:02100000';

  test(
    'normalizes Arabic/Persian spelling and digits without sender guessing',
    () {
      final text = incoming
          .replaceAll('ي', 'ی')
          .replaceAll('367,025', '۳۶۷٬۰۲۵')
          .replaceAll('4/3', '۰۴/۰۳')
          .replaceAll('\n', '\r\n');
      final parsed = parser.tryParse(text: text, currency: 'IRR');
      expect(parsed, isNotNull);
      expect(parsed!.amount.minorUnits, 367025);
      expect(parsed.sourceDate, '04/03');
      expect(parsed.occurredAt, isNull);
    },
  );

  test('partial Esfand 30 is evidence, never a fabricated leap year', () {
    final parsed = parser.tryParse(
      text: incoming.replaceFirst('4/3', '12/30'),
      currency: 'IRR',
    );
    expect(parsed, isNotNull);
    expect(parsed!.sourceDate, '12/30');
    expect(parsed.occurredAt, isNull);
  });

  test('redacted corpus preserves eight-digit contact shape', () {
    for (final body in bodies) {
      expect(body.split('\n').last, 'مرکزآواي نوين:02100000');
    }
  });

  for (final contact in [
    '0',
    '12',
    '0210000',
    '02100000',
    '021000000',
    '0210000000',
    '02100000000',
    '021000000000',
    '12100000',
    '123456789012345678901234567890',
    '۰۲۱۰۰۰۰۰',
    '٠٢١٠٠٠٠٠',
    '۱۲۳۴۵',
    '١٢٣٤٥',
  ]) {
    test(
      'contact length and prefix do not change transaction evidence: $contact',
      () {
        for (final body in bodies) {
          final shortBody = body.replaceFirst('02100000', contact);
          final original = parser.tryParse(text: body, currency: 'IRR');
          final parsed = parser.tryParse(
            text: shortBody,
            currency: 'IRR',
            sourceAddress: 'ENBANK',
          );
          expect(parsed, isNotNull);
          expect(parsed!.amount.minorUnits, original!.amount.minorUnits);
          expect(parsed.balance!.minorUnits, original.balance!.minorUnits);
          expect(parsed.direction, original.direction);
          expect(parsed.accountHint, original.accountHint);
          expect(parsed.bank, 'اقتصاد نوین');
          expect(parsed.currencyEvidence!.detectedUnit, SmsMoneyUnit.rial);
          expect(parsed.sourceDate, original.sourceDate);
          expect(parsed.sourceTime, original.sourceTime);
          expect(parsed.occurredAt, isNull);
        }
      },
    );
  }

  for (final contact in ['021abc00', '', '02100000 مبلغ: 100 ریال']) {
    test('rejects malformed contact footer $contact', () {
      expect(
        parser.tryParse(
          text: incoming.replaceFirst('02100000', contact),
          currency: 'IRR',
          sourceAddress: 'ENBANK',
        ),
        isNull,
      );
    });
  }

  final invalid = <String, String>{
    'contradictory sign': incoming.replaceFirst('+367', '-367'),
    'contradictory heading': incoming.replaceFirst('واريز', 'برداشت'),
    'missing sign': incoming.replaceFirst('+', ''),
    'double sign': incoming.replaceFirst('+', '++'),
    'malformed account': incoming.replaceFirst('246-135-90246-8', '246--135'),
    'malformed grouping': incoming.replaceFirst('367,025', '36,70,25'),
    'zero': incoming.replaceFirst('367,025', '0'),
    'overflow': incoming.replaceFirst('367,025', '9223372036854775808'),
    'missing amount unit': incoming.replaceFirst('ريال', ''),
    'missing balance unit': incoming.replaceFirst('45710874ريال', '45710874'),
    'wrong unit': incoming.replaceFirst('ريال', 'تومان'),
    'bad month': incoming.replaceFirst('4/3', '13/3'),
    'zero day': incoming.replaceFirst('4/3', '4/0'),
    'bad day': incoming.replaceFirst('4/3', '7/31'),
    'bad hour': incoming.replaceFirst('07:11', '24:11'),
    'bad minute': incoming.replaceFirst('07:11', '07:60'),
    'missing brand': incoming.replaceFirst('مرکزآواي نوين', 'پشتیبانی'),
    'extra text': '$incoming\nپیشنهاد ویژه',
    'OTP': '$incoming\nرمز 123456',
    'failure': incoming.replaceFirst('واريز', 'واريز ناموفق'),
    'missing footer': incoming.substring(0, incoming.lastIndexOf('\n')),
  };
  for (final entry in invalid.entries) {
    test('rejects ${entry.key}', () {
      expect(
        parser.tryParse(
          text: entry.value,
          currency: 'IRR',
          sourceAddress: 'NOVIN_SYNTHETIC',
        ),
        isNull,
      );
    });
  }
}
