import 'dart:math';

/// A stable UUIDv7 identifier independent of database row identifiers.
class StableId {
  StableId._(this.value);

  static final Random _random = Random.secure();
  static int _lastTimestamp = -1;
  static int _sequence = 0;

  factory StableId.generate({DateTime? timestamp}) {
    final milliseconds = (timestamp ?? DateTime.now())
        .toUtc()
        .millisecondsSinceEpoch;
    if (milliseconds < 0 || milliseconds > 0xffffffffffff) {
      throw RangeError.range(milliseconds, 0, 0xffffffffffff, 'timestamp');
    }

    if (milliseconds == _lastTimestamp) {
      _sequence = (_sequence + 1) & 0x0fff;
    } else {
      _lastTimestamp = milliseconds;
      _sequence = _random.nextInt(0x1000);
    }

    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    for (var index = 5; index >= 0; index--) {
      bytes[index] = (milliseconds >> ((5 - index) * 8)) & 0xff;
    }
    bytes[6] = 0x70 | ((_sequence >> 8) & 0x0f);
    bytes[7] = _sequence & 0xff;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    return StableId._(_format(bytes));
  }

  factory StableId.parse(String value) {
    final normalized = value.toLowerCase();
    if (!RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    ).hasMatch(normalized)) {
      throw FormatException('Invalid UUIDv7 stable ID', value);
    }
    return StableId._(normalized);
  }

  final String value;

  static String _format(List<int> bytes) {
    final hex = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }

  @override
  String toString() => value;

  @override
  bool operator ==(Object other) => other is StableId && other.value == value;

  @override
  int get hashCode => value.hashCode;
}
