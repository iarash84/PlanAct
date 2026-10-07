import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/database/app_database.dart';
import 'package:planact/features/backup/data/sqlite_backup_storage.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

import 'sqlite_backup_schema_compatibility_test.dart'
    show fixtures, createHistorical;

// Explicit opt-in regeneration uses actual AppDatabase migration output, never
// weakened or inferred declarations. Normal runs compare committed fixtures.
void main() {
  test('trusted v18 fixtures equal actual migration output', () async {
    final directory = await Directory.systemTemp.createTemp('review-fixtures-');
    try {
      for (final fixture in fixtures) {
        final file = File('${directory.path}/$fixture.sqlite');
        await createHistorical(file, fixture);
        final database = AppDatabase.forTesting(NativeDatabase(file));
        expect(await database.readMetadata('schema_version'), '18');
        await database.close();
        final raw = sqlite.sqlite3.open(file.path);
        final schema = SqliteBackupStorage.schema(raw);
        raw.close();
        final target = File('test/fixtures/backup_schema/$fixture-v18.json');
        if (Platform.environment['REGENERATE_REVIEW_FIXTURES'] == '1') {
          await target.writeAsString(
            '${const JsonEncoder.withIndent('  ').convert(schema)}\n',
          );
          // Public schema fingerprints contain no personal data.
          // ignore: avoid_print
          print('$fixture: ${sha256.convert(utf8.encode(schema.join('\n')))}');
        } else {
          expect(
            schema,
            (jsonDecode(await target.readAsString()) as List).cast<String>(),
          );
        }
      }
    } finally {
      await directory.delete(recursive: true);
    }
  });
}
