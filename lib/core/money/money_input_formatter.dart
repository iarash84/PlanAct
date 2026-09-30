import 'package:flutter/services.dart';

/// Keeps the text representation of a monetary amount readable while leaving
/// the domain value as an integer parsed by the caller.
class MoneyInputFormatter extends TextInputFormatter {
  const MoneyInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final rawBeforeCursor = newValue.text.substring(
      0,
      newValue.selection.baseOffset.clamp(0, newValue.text.length),
    );
    final digitsBeforeCursor = _digits(rawBeforeCursor).length;
    final digits = _digits(newValue.text);
    if (digits.isEmpty) return const TextEditingValue();

    final formatted = _group(digits);
    var cursor = 0;
    var seenDigits = 0;
    for (final codeUnit in formatted.codeUnits) {
      if (codeUnit >= 48 && codeUnit <= 57) {
        seenDigits++;
        if (seenDigits == digitsBeforeCursor) {
          cursor++;
          break;
        }
      }
      cursor++;
    }
    if (digitsBeforeCursor == 0) cursor = 0;
    if (digitsBeforeCursor >= digits.length) cursor = formatted.length;

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursor),
    );
  }

  static String normalize(String value) => _digits(value);

  static String format(int value) => _group(value.abs().toString());

  static String _digits(String value) => value
      .replaceAllMapped(RegExp('[۰-۹]'), (match) {
        return String.fromCharCode(
          match.group(0)!.codeUnitAt(0) - 0x06f0 + 0x30,
        );
      })
      .replaceAllMapped(RegExp('[٠-٩]'), (match) {
        return String.fromCharCode(
          match.group(0)!.codeUnitAt(0) - 0x0660 + 0x30,
        );
      })
      .replaceAll(RegExp(r'[^0-9]'), '');

  static String _group(String digits) => digits.replaceAllMapped(
    RegExp(r'(?<=\d)(?=(\d{3})+(?!\d))'),
    (match) => ',',
  );
}
