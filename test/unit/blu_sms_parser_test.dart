import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:planact/features/inbox/application/inbox_use_cases.dart';
import 'package:planact/features/inbox/domain/inbox.dart';
import 'package:planact/features/inbox/domain/sms_currency_evidence.dart';
import 'package:shamsi_date/shamsi_date.dart';

void main() {
  const parser = LocalSmsParser();
  final rows = File('test/fixtures/device_sms_corpus/Blu_synthetic.txt')
      .readAsStringSync()
      .split(RegExp(r'(?=^Row:)', multiLine: true))
      .where((row) => row.startsWith('Row:'))
      .toList();
  final bodies = rows
      .map(
        (row) => row
            .substring(row.indexOf('body=') + 5)
            .replaceFirst(RegExp(r', date=\d+\s*$'), ''),
      )
      .toList();

  test('all 21 anonymized Blu rows preserve exact financial and time evidence', () {
    expect(rows, hasLength(24));
    for (var index = 0; index < 21; index++) {
      final i = index + 1;
      final incoming = {3, 8, 15, 19}.contains(i);
      final parsed = parser.tryParse(
        text: bodies[index],
        currency: 'IRR',
        sourceAddress: 'BLU_SYNTHETIC',
      );
      expect(parsed, isNotNull, reason: 'synthetic row $i');
      expect(parsed!.amount.minorUnits, 123456 + i * 17321);
      expect(parsed.amount.currency, 'IRR');
      expect(parsed.balance!.minorUnits, 23456789 + i * 27139);
      expect(
        parsed.direction,
        incoming
            ? TransactionDirection.incoming
            : TransactionDirection.outgoing,
      );
      expect(parsed.bank, 'بلو');
      expect(parsed.accountHint, isNull);
      expect(parsed.isTransfer, isFalse);
      expect(parsed.currencyEvidence!.detectedUnit, SmsMoneyUnit.rial);
      expect(parsed.currencyEvidence!.requiresSelection, isFalse);
      expect(parsed.sourceDate, '1404.03.${i.toString().padLeft(2, '0')}');
      expect(
        parsed.sourceTime,
        '${(7 + i % 12).toString().padLeft(2, '0')}:${(i * 7 % 60).toString().padLeft(2, '0')}',
      );
      final date = Jalali(1404, 3, i).toGregorian();
      expect(
        parsed.occurredAt,
        DateTime(date.year, date.month, date.day, 7 + i % 12, i * 7 % 60),
      );
    }
  });

  test('three appended Blu rows preserve redacted name and one-digit hour', () {
    final expected = [
      (2500000, 488152, 22, 7, 28, TransactionDirection.outgoing),
      (3000000, 8151152, 20, 22, 14, TransactionDirection.outgoing),
      (70000000, 71087723, 18, 11, 49, TransactionDirection.incoming),
    ];
    for (var i = 0; i < expected.length; i++) {
      final (amount, balance, day, hour, minute, direction) = expected[i];
      final parsed = parser.parse(text: bodies[21 + i], currency: 'IRR');
      expect(parsed.amount.minorUnits, amount);
      expect(parsed.balance!.minorUnits, balance);
      expect(parsed.direction, direction);
      expect(parsed.currencyEvidence!.detectedUnit, SmsMoneyUnit.rial);
      final date = Jalali(1405, 3, day).toGregorian();
      expect(
        parsed.occurredAt,
        DateTime(date.year, date.month, date.day, hour, minute),
      );
      expect(parsed.accountHint, isNull);
    }
  });

  const outgoing =
      'بلو\nبرداشت پول\nنگار عزیز، 140,777ریال از حساب شما پرید.\n'
      'موجودی: 23,483,928 ریال\n۰۸:۰۷\n۱۴۰۴.۰۳.۰۱';

  test('header identifies layout without guessing an account or sender', () {
    // Git may check out the corpus with CRLF on Windows. Ignore only that
    // transport difference here; keep the original bodies as parser inputs.
    expect(bodies.first.replaceAll('\r\n', '\n'), outgoing);
    expect(parser.tryParse(text: outgoing, currency: 'IRR'), isNotNull);
    expect(
      parser.tryParse(
        text: outgoing
            .replaceAll('140,777', '۱۴۰٬۷۷۷')
            .replaceAll('\n', '\r\n'),
        currency: 'IRR',
      ),
      isNotNull,
    );
  });

  for (final lineEnding in ['\n', '\r\n']) {
    final label = lineEnding == '\n' ? 'LF' : 'CRLF';
    test(
      'preserves Blu financial and time evidence with $label line endings',
      () {
        final parsed = parser.parse(
          text: outgoing.replaceAll('\n', lineEnding),
          currency: 'IRR',
        );
        expect(parsed.amount.minorUnits, 140777);
        expect(parsed.balance!.minorUnits, 23483928);
        expect(parsed.direction, TransactionDirection.outgoing);
        expect(parsed.bank, 'بلو');
        expect(parsed.accountHint, isNull);
        expect(parsed.currencyEvidence!.detectedUnit, SmsMoneyUnit.rial);
        expect(parsed.sourceDate, '1404.03.01');
        expect(parsed.sourceTime, '08:07');
        final date = Jalali(1404, 3, 1).toGregorian();
        expect(
          parsed.occurredAt,
          DateTime(date.year, date.month, date.day, 8, 7),
        );
      },
    );
  }

  final invalid = <String, String>{
    'contradictory heading': outgoing.replaceFirst('برداشت پول', 'واریز پول'),
    'contradictory prose': outgoing.replaceFirst(
      'از حساب شما پرید.',
      'به حساب شما نشست.',
    ),
    'unknown header': outgoing.replaceFirst('بلو', 'فروشگاه'),
    'invalid grouping': outgoing.replaceFirst('140,777', '14,07,77'),
    'zero amount': outgoing.replaceFirst('140,777', '0'),
    'overflow': outgoing.replaceFirst('140,777', '9223372036854775808'),
    'missing unit': outgoing.replaceFirst('ریال', ''),
    'wrong unit': outgoing.replaceFirst('ریال', 'تومان'),
    'invalid hour': outgoing.replaceFirst('۰۸:۰۷', '۲۴:۰۷'),
    'invalid minute': outgoing.replaceFirst('۰۸:۰۷', '۰۸:۶۰'),
    'invalid day': outgoing.replaceFirst('۱۴۰۴.۰۳.۰۱', '۱۴۰۴.۰۷.۳۱'),
    'non-leap date': outgoing.replaceFirst('۱۴۰۴.۰۳.۰۱', '۱۴۰۴.۱۲.۳۰'),
    'partial date': outgoing.replaceFirst('۱۴۰۴.۰۳.۰۱', '۰۳.۰۱'),
    'extra prose': '$outgoing\nپیشنهاد ویژه',
    'OTP': '$outgoing\nرمز 123456',
    'failed': outgoing.replaceFirst('برداشت پول', 'برداشت ناموفق پول'),
    'missing balance': outgoing.replaceFirst('موجودی: 23,483,928 ریال\n', ''),
  };
  for (final entry in invalid.entries) {
    test('rejects ${entry.key}', () {
      expect(
        parser.tryParse(
          text: entry.value,
          currency: 'IRR',
          sourceAddress: 'BLU_SYNTHETIC',
        ),
        isNull,
      );
    });
  }
}
