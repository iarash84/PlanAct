import 'dart:convert';
import 'dart:io';

import 'package:planact/features/calendar/domain/annual_holiday_data.dart';

/// Compile reviewed v1 payloads without a Flutter/runtime asset dependency.
/// The manifest is data: adding a year never changes this generator.
String renderHolidayCatalog(Directory directory) {
  final manifest = jsonDecode(
    File('${directory.path}/catalog.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  if (manifest['format'] != 'planact-holiday-catalog-v1') {
    throw const FormatException('Unknown catalog format');
  }
  final calendars = <int, String>{};
  for (final path in manifest['calendars'] as List) {
    if (path is! String ||
        !RegExp(r'^reviewed/[a-zA-Z0-9_-]+\.json$').hasMatch(path)) {
      throw const FormatException('Invalid relative calendar path');
    }
    final encoded = File('${directory.path}/$path').readAsStringSync();
    final calendar = AnnualHolidayData.parse(encoded);
    if (calendars.containsKey(calendar.year)) {
      throw const FormatException('Duplicate catalog year');
    }
    calendars[calendar.year] = jsonEncode(jsonDecode(encoded));
  }
  if (calendars.isEmpty) throw const FormatException('Empty catalog');
  final years = calendars.keys.toList()..sort();
  return [
    '// GENERATED CODE - DO NOT MODIFY BY HAND.',
    '// Source: third_party/iranian_holidays/catalog.json.',
    '// Run dart run tool/generate_iranian_holidays.dart.',
    '// dart format off',
    '',
    'const bundledIranianHolidayPayloads = <String>[',
    for (final year in years)
      '  ${jsonEncode(calendars[year]).replaceAll(r'$', r'\$')},',
    '];',
    '',
  ].join('\n');
}

void main(List<String> args) {
  try {
    if (args.any((arg) => arg != '--check')) {
      throw const FormatException(
        'Usage: generate_iranian_holidays.dart [--check]',
      );
    }
    final root = File.fromUri(Platform.script).parent.parent;
    final expected = renderHolidayCatalog(
      Directory('${root.path}/third_party/iranian_holidays'),
    );
    final file = File(
      '${root.path}/lib/features/calendar/domain/iranian_holiday_data.dart',
    );
    if (args.contains('--check')) {
      if (!file.existsSync() ||
          file.readAsStringSync().replaceAll('\r\n', '\n') != expected) {
        throw StateError('Bundled holiday data is stale; run the generator.');
      }
    } else {
      file.writeAsStringSync(expected);
    }
    stdout.writeln('Reviewed holiday catalog is current.');
  } catch (error) {
    stderr.writeln('Holiday catalog generation failed: $error');
    exitCode = 1;
  }
}
