import 'dart:convert';
import 'dart:io';

/// Generates pure-Dart legacy/default copy from the Persian ARB, without a
/// Flutter dependency in domain code or a second editable catalog.
/// Run with --check in CI. ICU plural/select belongs in presentation resources;
/// this companion accepts only existing preformatted String placeholders.
String render(Map<String, dynamic> catalog) {
  final lines = <String>[
    '// GENERATED CODE - DO NOT MODIFY BY HAND.',
    '// Source: lib/l10n/app_fa.arb. Run tool/generate_persian_copy.dart.',
    '// Pure Dart default copy; never imports Flutter or changes stored values.',
    '// ignore_for_file: lines_longer_than_80_chars, unnecessary_brace_in_string_interps',
    '// dart format off',
    '',
    'abstract final class PersianCopy {',
  ];
  final identifier = RegExp(r'^[a-z][a-zA-Z0-9]*$');
  for (final entry in catalog.entries) {
    final key = entry.key;
    if (key.startsWith('@')) continue;
    final metadata = catalog['@$key'] as Map<String, dynamic>? ?? const {};
    if (metadata['x-planact-default'] != true) continue;
    if (!identifier.hasMatch(key)) {
      throw FormatException('Invalid default message key: $key');
    }
    final value = entry.value as String;
    final placeholders =
        metadata['placeholders'] as Map<String, dynamic>? ?? const {};
    var encoded = jsonEncode(value).replaceAll(r'$', r'\$');
    if (placeholders.isEmpty) {
      lines.add('  static const $key = $encoded;');
      continue;
    }
    var stripped = value;
    for (final placeholder in placeholders.entries) {
      final name = placeholder.key;
      if (!identifier.hasMatch(name) || placeholder.value['type'] != 'String') {
        throw FormatException('Invalid default placeholder: $key.$name');
      }
      stripped = stripped.replaceAll('{$name}', '');
      encoded = encoded.replaceAll('{$name}', '\${$name}');
    }
    if (stripped.contains('{') || stripped.contains('}')) {
      throw FormatException('Unsupported ICU syntax in default message: $key');
    }
    final params = placeholders.keys.map((name) => 'String $name').join(', ');
    lines.add('  static String $key($params) => $encoded;');
  }
  lines.addAll(['}', '']);
  return lines.join('\n');
}

void main(List<String> args) {
  if (args.any((arg) => arg != '--check')) {
    stderr.writeln('Usage: dart run tool/generate_persian_copy.dart [--check]');
    exitCode = 64;
    return;
  }
  final root = File.fromUri(Platform.script).parent.parent;
  final catalog = File('${root.path}/lib/l10n/app_fa.arb');
  final output = File('${root.path}/lib/core/localization/persian_copy.g.dart');
  final expected = render(
    jsonDecode(catalog.readAsStringSync()) as Map<String, dynamic>,
  );
  if (args.contains('--check')) {
    if (!output.existsSync() ||
        output.readAsStringSync().replaceAll('\r\n', '\n') != expected) {
      stderr.writeln(
        'Persian copy is stale; run dart run tool/generate_persian_copy.dart',
      );
      exitCode = 1;
      return;
    }
    stdout.writeln('Persian default copy is current.');
    return;
  }
  output.writeAsStringSync(expected);
  stdout.writeln('Generated framework-independent Persian default copy.');
}
