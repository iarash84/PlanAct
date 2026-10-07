import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/database/app_database.dart';
import 'package:planact/features/backup/data/sqlite_backup_snapshot.dart';
import 'package:planact/features/backup/data/sqlite_backup_storage.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  test('production snapshot preserves entities and redacts SMS without live mutation or free-page leakage', () async {
    final directory = await Directory.systemTemp.createTemp(
      'planact-snapshot-',
    );
    final live = File('${directory.path}/live.sqlite');
    final database = AppDatabase(NativeDatabase.createInBackground(live));
    try {
      await database.customSelect('SELECT 1').get();
      const private = 'PRIVATE_RAW_SMS_DO_NOT_EXPORT_123456';
      await database.customStatement(
        "INSERT INTO staged_imports (id,raw_text,fingerprint,source,source_key,imported_at,adapter_version,status) VALUES ('sms','$private','fingerprint',0,'source',0,'test',0)",
      );
      await database.customStatement(
        "INSERT INTO commitments (id,title,created_at,status) VALUES ('c','historical',0,4)",
      );
      await database.customStatement(
        "INSERT INTO financial_accounts (id,name,type,currency,status) VALUES ('a','wallet',0,'IRR',0)",
      );
      await database.writeMetadata('theme_mode', 'dark');
      final bytes = await sqliteBackupSnapshot(
        database: database,
        target: File('${directory.path}/export.sqlite'),
        redact: true,
      );
      expect(
        latin1.decode(bytes, allowInvalid: true),
        isNot(contains(private)),
      );
      final isolated = File('${directory.path}/inspect.sqlite');
      await isolated.writeAsBytes(bytes);
      final db = sqlite3.open(isolated.path);
      try {
        expect(
          db.select('SELECT raw_text FROM staged_imports').single['raw_text'],
          '',
        );
        expect(
          db.select('SELECT title FROM commitments').single['title'],
          'historical',
        );
        expect(
          db.select('SELECT name FROM financial_accounts').single['name'],
          'wallet',
        );
        expect(
          db
              .select(
                "SELECT value FROM schema_metadata WHERE key='theme_mode'",
              )
              .single['value'],
          'dark',
        );
        expect(db.select('PRAGMA integrity_check').single.values.single, 'ok');
        expect(db.select('PRAGMA foreign_key_check'), isEmpty);
        final storage = SqliteBackupStorage(
          live: live,
          schemaVersion: database.schemaVersion,
          expectedSchema: SqliteBackupStorage.schema(db),
          snapshot: live.readAsBytes,
          closeLive: () async {},
        );
        await storage.validatePayload(bytes);
      } finally {
        db.close();
      }
      expect(
        (await database
                .customSelect('SELECT raw_text FROM staged_imports')
                .getSingle())
            .read<String>('raw_text'),
        private,
      );
      final safety = await sqliteBackupSnapshot(
        database: database,
        target: File('${directory.path}/safety.sqlite'),
        redact: false,
      );
      expect(latin1.decode(safety), contains(private));
    } finally {
      await database.close();
      await directory.delete(recursive: true);
    }
  });
}
