import 'package:planact/core/localization/persian_numbers.dart';
import 'package:planact/core/money/currency.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/core/money/iranian_money_unit.dart';

/// Formats stored integer minor units for display without converting currency.
abstract final class PersianMoneyText {
  static String amount(
    int minorUnits,
    String currency, {
    IranianMoneyUnit unit = IranianMoneyUnit.rial,
  }) {
    final iranian = CurrencyCodes.same(currency, CurrencyCodes.irr);
    final raw = (iranian ? unit : IranianMoneyUnit.rial).inputText(minorUnits);
    final parts = raw.split('.');
    final grouped = parts.first.replaceAllMapped(
      RegExp(r'(?<=\d)(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
    final number = '$grouped${parts.length == 2 ? '٫${parts.last}' : ''}';
    return '${PersianNumbers.format(number)} ${iranian ? unit.label : currency}';
  }

  static String money(
    Money value, {
    IranianMoneyUnit unit = IranianMoneyUnit.rial,
  }) => amount(value.minorUnits, value.currency, unit: unit);
}
