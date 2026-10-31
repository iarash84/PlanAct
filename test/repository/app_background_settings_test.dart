import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/app_settings.dart';
import 'package:planact/core/database/app_database.dart';
import 'package:planact/features/backup/data/sqlite_backup_snapshot.dart';

void main() {
  // This test intentionally opens several independent file-backed databases
  // during cold-reopen and restore checks.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  test('background selection persists across a cold database reopen', () async {
    final directory = await Directory.systemTemp.createTemp(
      'planact-background-',
    );
    final file = File('${directory.path}/state.sqlite');
    var database = AppDatabase(NativeDatabase(file));
    try {
      var settings = AppSettings(database);
      expect(await settings.readBackground(), AppBackground.none);
      await settings.writeBackground(AppBackground.persianWaves);
      await database.close();

      database = AppDatabase(NativeDatabase(file));
      settings = AppSettings(database);
      expect(await settings.readBackground(), AppBackground.persianWaves);

      final backup = File('${directory.path}/backup.sqlite');
      final bytes = await sqliteBackupSnapshot(
        database: database,
        target: backup,
        redact: true,
      );
      await backup.writeAsBytes(bytes, flush: true);
      final restored = AppDatabase(NativeDatabase(backup));
      try {
        expect(
          await AppSettings(restored).readBackground(),
          AppBackground.persianWaves,
        );
      } finally {
        await restored.close();
      }

      await database.writeMetadata('app_background_v1', 'unrecognized');
      expect(await settings.readBackground(), AppBackground.none);
    } finally {
      await database.close();
      await directory.delete(recursive: true);
    }
  });
}
