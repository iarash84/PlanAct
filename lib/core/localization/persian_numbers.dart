abstract final class PersianNumbers {
  static const _digits = '۰۱۲۳۴۵۶۷۸۹';
  static const _latinDigits = '0123456789';

  static String format(Object value) {
    return value.toString().split('').map((character) {
      final index = _latinDigits.indexOf(character);
      return index < 0 ? character : _digits[index];
    }).join();
  }
}
