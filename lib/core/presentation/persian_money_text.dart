import 'package:planact/core/localization/persian_numbers.dart';
import 'package:planact/core/money/currency.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/core/money/money_input_formatter.dart';

/// Formats stored integer minor units for display without converting currency.
abstract final class PersianMoneyText {
  static String amount(int minorUnits, String currency) =>
      '${PersianNumbers.format(MoneyInputFormatter.format(minorUnits.abs()))} ${CurrencyCodes.label(currency)}';

  static String money(Money value) => amount(value.minorUnits, value.currency);
}
