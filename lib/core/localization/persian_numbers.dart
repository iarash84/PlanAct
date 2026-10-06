abstract final class PersianNumbers {
  static const _digits = '۰۱۲۳۴۵۶۷۸۹';
  static const _latinDigits = '0123456789';

  static String normalizeDigits(String value) =>
      value.split('').map((character) {
        final persian = _digits.indexOf(character);
        final arabic = '٠١٢٣٤٥٦٧٨٩'.indexOf(character);
        final index = persian >= 0 ? persian : arabic;
        return index < 0 ? character : _latinDigits[index];
      }).join();

  static String format(Object value) {
    return value.toString().split('').map((character) {
      final index = _latinDigits.indexOf(character);
      return index < 0 ? character : _digits[index];
    }).join();
  }
}
