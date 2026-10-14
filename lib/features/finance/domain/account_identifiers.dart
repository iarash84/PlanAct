import 'package:planact/core/localization/persian_copy.g.dart';
import 'package:planact/core/errors/app_error.dart';
import 'package:planact/core/localization/persian_numbers.dart';

/// Informational identifiers only. Never credentials or a source of bank identity.
class AccountIdentifiers {
  const AccountIdentifiers._(this.cardNumber, this.iban, this.accountNumber);
  static const empty = AccountIdentifiers._(null, null, null);

  factory AccountIdentifiers({
    String? cardNumber,
    String? iban,
    String? accountNumber,
  }) {
    final card = normalize(cardNumber);
    final sheba = normalize(iban)?.toUpperCase();
    final number = normalize(accountNumber);
    if (cardError(card) != null ||
        ibanError(sheba) != null ||
        accountError(number) != null) {
      throw const ValidationError('Invalid account identifiers');
    }
    return AccountIdentifiers._(card, sheba, number);
  }

  final String? cardNumber;
  final String? iban;
  final String? accountNumber;

  static String? normalize(String? value) {
    final text = PersianNumbers.normalizeDigits(value ?? '').trim();
    return text.isEmpty ? null : text;
  }

  static String? cardError(String? input) {
    final value = normalize(input);
    if (value == null) return null;
    if (!RegExp(r'^\d{16}$').hasMatch(value)) {
      return PersianCopy.accountIdentifiersCardErrorMessage;
    }
    var sum = 0;
    for (var i = 0; i < value.length; i++) {
      var digit = int.parse(value[i]) * (i.isEven ? 2 : 1);
      if (digit > 9) digit -= 9;
      sum += digit;
    }
    return sum % 10 == 0 && !RegExp(r'^0+$').hasMatch(value)
        ? null
        : PersianCopy.accountIdentifiersCardErrorMessage2;
  }

  static String? ibanError(String? input) {
    final value = normalize(input)?.toUpperCase();
    if (value == null) return null;
    if (!RegExp(r'^IR\d{24}$').hasMatch(value)) {
      return PersianCopy.accountIdentifiersIbanErrorMessage;
    }
    final digits = '${value.substring(4)}1827${value.substring(2, 4)}';
    var remainder = 0;
    for (final digit in digits.split('')) {
      remainder = (remainder * 10 + int.parse(digit)) % 97;
    }
    return remainder == 1
        ? null
        : PersianCopy.accountIdentifiersIbanErrorMessage2;
  }

  static String? accountError(String? input) {
    final value = normalize(input);
    if (value == null) return null;
    return RegExp(r'^\d{1,30}$').hasMatch(value)
        ? null
        : PersianCopy.accountIdentifiersAccountErrorMessage;
  }

  static String masked(String value) =>
      value.length <= 4 ? '••••' : '•••• ${value.substring(value.length - 4)}';

  @override
  bool operator ==(Object other) =>
      other is AccountIdentifiers &&
      cardNumber == other.cardNumber &&
      iban == other.iban &&
      accountNumber == other.accountNumber;
  @override
  int get hashCode => Object.hash(cardNumber, iban, accountNumber);
}
