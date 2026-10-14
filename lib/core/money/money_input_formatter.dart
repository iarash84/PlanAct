import 'package:flutter/services.dart';

/// Keeps the text representation of a monetary amount readable while leaving
/// the domain value as an integer parsed by the caller.
class MoneyInputFormatter extends TextInputFormatter {
  const MoneyInputFormatter({this.decimal = false});

  final bool decimal;

  static String groupText(String text) {
    final parts = text.split(".");
    return "${_group(parts.first)}${parts.length > 1 ? ".${parts.last}" : ""}";
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (decimal) {
      if (!newValue.composing.isCollapsed) return newValue;
      String normalize(String text) => text
          .replaceAllMapped(RegExp('[\u06f0-\u06f9\u0660-\u0669]'), (m) {
            final c = m[0]!.codeUnitAt(0);
            return String.fromCharCode(
              c - (c >= 0x06f0 ? 0x06f0 : 0x0660) + 48,
            );
          })
          .replaceAll('\u066b', '.')
          .replaceAll('\u2212', '-');
      final normalized = normalize(newValue.text);
      if (!RegExp(r'^[+-]?[0-9,\u066c]*(?:\.[0-9]*)?$').hasMatch(normalized)) {
        return newValue; // Keep invalid input visible for validation; never reinterpret it.
      }
      if (normalized != oldValue.text &&
          (oldValue.text.isEmpty ||
              newValue.text.length > oldValue.text.length + 1 ||
              (oldValue.selection.end - oldValue.selection.start).abs() > 1) &&
          normalized.contains(RegExp('[,\u066c]')) &&
          !RegExp(r'^[+-]?[0-9]{1,3}(?:[,\u066c][0-9]{3})+(?:\.[0-9]*)?$')
              .hasMatch(normalized)) {
        return newValue;
      }
      final raw = normalized.replaceAll(RegExp('[,\u066c]'), '');
      final formatted = groupText(raw);
      final offset = newValue.selection.extentOffset.clamp(
        0,
        newValue.text.length,
      );
      final before = normalize(newValue.text.substring(0, offset))
          .replaceAll(RegExp('[,\u066c]'), '')
          .length;
      var cursor = 0;
      var seen = 0;
      while (cursor < formatted.length && seen < before) {
        if (formatted[cursor] != ',') seen++;
        cursor++;
      }
      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: cursor),
      );
    }
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
