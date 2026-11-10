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
    bool isolateNumber = false,
  }) {
    final iranian = CurrencyCodes.same(currency, CurrencyCodes.irr);
    final raw = (iranian ? unit : IranianMoneyUnit.rial).inputText(minorUnits);
    final parts = raw.split('.');
    final grouped = parts.first.replaceAllMapped(
      RegExp(r'(?<=\d)(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
    final number = '$grouped${parts.length == 2 ? '٫${parts.last}' : ''}';
    final localized = PersianNumbers.format(number);
    // Isolate only the numeric run: Persian digits are weak bidi characters,
    // so an unisolated leading minus otherwise moves right in RTL paragraphs.
    final display = isolateNumber ? '\u2066$localized\u2069' : localized;
    return '$display ${iranian ? unit.label : currency}';
  }

  static String money(
    Money value, {
    IranianMoneyUnit unit = IranianMoneyUnit.rial,
    bool isolateNumber = false,
  }) => amount(
    value.minorUnits,
    value.currency,
    unit: unit,
    isolateNumber: isolateNumber,
  );
}
