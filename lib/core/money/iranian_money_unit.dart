/// Presentation/input units only. Durable Iranian amounts remain integer IRR.
enum IranianMoneyUnit {
  rial,
  toman;

  String get label => this == rial ? 'ریال' : 'تومان';

  String inputText(int rials) {
    final magnitude = BigInt.from(rials).abs();
    final sign = rials < 0 ? '-' : '';
    if (this == rial) return '$sign$magnitude';
    final remainder = magnitude % BigInt.from(10);
    return '$sign${magnitude ~/ BigInt.from(10)}${remainder == BigInt.zero ? '' : '.$remainder'}';
  }

  /// Null means malformed, excessive precision or outside SQLite signed int64.
  int? parse(String text) {
    final normalized = text
        .trim()
        .replaceAllMapped(RegExp('[۰-۹٠-٩]'), (m) {
          final c = m[0]!.codeUnitAt(0);
          return String.fromCharCode(c - (c >= 0x06f0 ? 0x06f0 : 0x0660) + 48);
        })
        .replaceAll('٫', '.')
        .replaceAll('−', '-');
    if (!RegExp(r'^[+-]?[0-9]+(?:[,٬][0-9]{3})*(?:\.[0-9])?$')
        .hasMatch(normalized)) {
      return null;
    }
    final raw = normalized.replaceAll(RegExp('[,٬]'), '');
    if (this == rial && raw.contains('.')) return null;
    final negative = raw.startsWith('-');
    final parts = raw.replaceFirst(RegExp(r'^[+-]'), '').split('.');
    var value = BigInt.parse(parts.first);
    if (this == toman) {
      value =
          value * BigInt.from(10) +
          BigInt.parse(parts.length == 2 ? parts.last : '0');
    }
    if (negative) value = -value;
    if (value < BigInt.parse('-9223372036854775808') ||
        value > BigInt.parse('9223372036854775807')) {
      return null;
    }
    return value.toInt();
  }
}
