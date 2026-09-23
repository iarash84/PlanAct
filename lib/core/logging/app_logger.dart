import 'dart:developer' as developer;

typedef LogSink = void Function(String message, {String? name, int? level});

enum LogLevel { debug, info, warning, error }

/// Privacy-preserving application logger. Sensitive fields are redacted by default.
class AppLogger {
  const AppLogger({this.sink = _defaultSink});

  final LogSink sink;

  static void _defaultSink(String message, {String? name, int? level}) {
    developer.log(message, name: name ?? 'planact', level: level ?? 0);
  }

  void debug(String message, {Map<String, Object?> fields = const {}}) =>
      _write(LogLevel.debug, message, fields);

  void info(String message, {Map<String, Object?> fields = const {}}) =>
      _write(LogLevel.info, message, fields);

  void warning(String message, {Map<String, Object?> fields = const {}}) =>
      _write(LogLevel.warning, message, fields);

  void error(String message, {Map<String, Object?> fields = const {}}) =>
      _write(LogLevel.error, message, fields);

  void _write(LogLevel level, String message, Map<String, Object?> fields) {
    final safeFields = fields.map(
      (key, value) => MapEntry(key, _isSensitive(key) ? '[REDACTED]' : value),
    );
    final suffix = safeFields.isEmpty ? '' : ' $safeFields';
    sink('$message$suffix', name: 'planact', level: level.index + 1);
  }

  static bool _isSensitive(String key) {
    final normalized = key.toLowerCase();
    return normalized.contains('password') ||
        normalized.contains('secret') ||
        normalized.contains('token') ||
        normalized.contains('sms') ||
        normalized.contains('account') ||
        normalized.contains('private') ||
        normalized.contains('financial') ||
        normalized.contains('amount');
  }
}
