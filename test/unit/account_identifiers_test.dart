import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/errors/app_error.dart';
import 'package:planact/features/finance/domain/account_identifiers.dart';

void main() {
  test('optional identifiers and blank fields are absent', () {
    expect(
      AccountIdentifiers(cardNumber: ' ', iban: '', accountNumber: null),
      AccountIdentifiers.empty,
    );
  });
  test('Persian and Arabic digits normalize and leading zeros survive', () {
    final identifiers = AccountIdentifiers(
      cardNumber: '۰۰۰۰۰۰۰۰۰۰۰۰۰۰۱۸',
      iban: 'ir۸۲۰۵۴۰۱۰۲۶۸۰۰۲۰۸۱۷۹۰۹۰۰۲',
      accountNumber: '٠٠٠١٢٣',
    );
    expect(identifiers.cardNumber, '0000000000000018');
    expect(identifiers.iban, 'IR820540102680020817909002');
    expect(identifiers.accountNumber, '000123');
  });
  test('field validation checks structure/checksum without bank inference', () {
    for (final value in [
      '123',
      '0000000000000000',
      '0000000000000019',
      '0000-0000-0000-0018',
    ]) {
      expect(AccountIdentifiers.cardError(value), isNotNull);
      expect(
        () => AccountIdentifiers(cardNumber: value),
        throwsA(isA<ValidationError>()),
      );
    }
    for (final value in [
      'DE820540102680020817909002',
      'IR810540102680020817909002',
      'IR12',
    ]) {
      expect(AccountIdentifiers.ibanError(value), isNotNull);
    }
    expect(AccountIdentifiers.accountError('0'), isNull);
    expect(AccountIdentifiers.accountError('0' * 30), isNull);
    for (final value in ['0' * 31, '12 34', '-12', '1.2', 'IR12']) {
      expect(AccountIdentifiers.accountError(value), isNotNull);
    }
  });
  test('mask never exposes entire short identifier', () {
    expect(AccountIdentifiers.masked('001'), '••••');
    expect(AccountIdentifiers.masked('00012345'), '•••• 2345');
  });
}
