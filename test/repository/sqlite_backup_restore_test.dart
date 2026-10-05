import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/database/app_database.dart';
import 'package:planact/features/backup/application/backup_service.dart';
import 'package:planact/features/backup/data/secure_backup_keys.dart';
import 'package:planact/features/backup/data/sqlite_backup_storage.dart';
import 'package:planact/features/backup/domain/backup_encryption.dart';
import 'package:planact/features/backup/domain/backup_package.dart';
import 'package:sqlite3/sqlite3.dart';

class Keys implements BackupKeyStorage {
  Keys([this.value = 1]);
  final int value;
  @override
  Future<Uint8List> loadKey(String _) async =>
      Uint8List.fromList(List.filled(32, value));
}

class Rebuild implements BackupRebuildHook {
  int calls = 0;
  bool failOnce = false;
  @override
  Future<void> rebuild() async {
    calls++;
    if (failOnce) {
      failOnce = false;
      throw StateError('injected rebuild');
    }
  }
}

void main() {
  late Directory directory;
  late File live;
  late SqliteBackupStorage storage;
  late BackupService service;
  late Rebuild rebuild;
  late Uint8List original;
  late int version;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('planact-backup-test-');
    live = File('${directory.path}/live.sqlite');
    final db = AppDatabase(NativeDatabase(live));
    await db.writeMetadata('test_state', 'original');
    version = db.schemaVersion;
    await db.close();
    final sql = sqlite3.open(live.path);
    final schema = SqliteBackupStorage.schema(sql);
    sql.close();
    original = await live.readAsBytes();
    storage = SqliteBackupStorage(
      live: live,
      schemaVersion: version,
      expectedSchema: schema,
      snapshot: live.readAsBytes,
      closeLive: () async {},
    );
    rebuild = Rebuild();
    service = BackupService(
      storage: storage,
      validator: BackupValidator(currentSchemaVersion: version),
      rebuildHook: rebuild,
      keyStorage: Keys(),
      encryptor: AesGcmBackupEncryptor(),
      nonceGenerator: SecureBackupNonce(),
    );
  });
  tearDown(() async => directory.delete(recursive: true));

  Future<Uint8List> changed(void Function(Database) change) async {
    final file = File('${directory.path}/candidate.sqlite');
    await file.writeAsBytes(original);
    final sql = sqlite3.open(file.path);
    try {
      change(sql);
    } finally {
      sql.close();
    }
    return file.readAsBytes();
  }

  Future<BackupPackage> package(Uint8List bytes) => service.create(
    payload: bytes,
    appVersion: 'test',
    createdAt: DateTime.utc(2026),
  );
  String state() {
    final db = sqlite3.open(live.path);
    try {
      return db
              .select(
                "SELECT value FROM schema_metadata WHERE key='test_state'",
              )
              .single['value']
          as String;
    } finally {
      db.close();
    }
  }

  test('real file encrypted restore repeated and cold reopen', () async {
    final bytes = await changed(
      (db) => db.execute(
        "UPDATE schema_metadata SET value='restored' WHERE key='test_state'",
      ),
    );
    final backup = BackupPackage.decode((await package(bytes)).encode());
    await service.restore(backup);
    expect(state(), 'restored');
    await service.restore(backup);
    final reopened = AppDatabase(NativeDatabase(live));
    expect(await reopened.readMetadata('test_state'), 'restored');
    await reopened.close();
    storage.validateFile(live);
    expect(await storage.marker.exists(), false);
  });

  test('wrong key leaves live bytes untouched', () async {
    final backup = await package(original);
    final wrong = BackupService(
      storage: storage,
      validator: service.validator,
      rebuildHook: rebuild,
      keyStorage: Keys(2),
      encryptor: service.encryptor,
      nonceGenerator: SecureBackupNonce(),
    );
    await expectLater(wrong.restore(backup), throwsException);
    expect(await live.readAsBytes(), original);
    expect(rebuild.calls, 0);
  });

  for (final kind in ['corrupt', 'schema', 'incomplete', 'foreign-key']) {
    test('$kind authenticated payload rejected before activation', () async {
      final bytes = kind == 'corrupt'
          ? Uint8List.fromList([1, 2, 3])
          : await changed((db) {
              if (kind == 'schema') db.execute('PRAGMA user_version=999');
              if (kind == 'incomplete') db.execute('DROP TABLE actuals');
              if (kind == 'foreign-key') {
                db.execute('PRAGMA foreign_keys=OFF');
                db.execute(
                  "INSERT INTO commitment_cycles VALUES ('orphan','missing',0,0,NULL,NULL,NULL,0,0,0)",
                );
              }
            });
      await expectLater(service.restore(await package(bytes)), throwsException);
      expect(await live.readAsBytes(), original);
      expect(rebuild.calls, 0);
    });
  }

  test('rebuild failure restores safety and rebinds rollback', () async {
    rebuild.failOnce = true;
    final bytes = await changed(
      (db) => db.execute(
        "UPDATE schema_metadata SET value='candidate' WHERE key='test_state'",
      ),
    );
    await expectLater(service.restore(await package(bytes)), throwsException);
    expect(state(), 'original');
    expect(rebuild.calls, 2);
    expect(await storage.marker.exists(), false);
  });

  test('crash after replacement recovers old data on fresh storage', () async {
    await storage.writeSafetySnapshot(original);
    final bytes = await changed(
      (db) => db.execute(
        "UPDATE schema_metadata SET value='candidate' WHERE key='test_state'",
      ),
    );
    await storage.writeTemporary(bytes);
    await storage.writeRecoveryMarker();
    await storage.replaceTemporary();
    expect(state(), 'candidate');
    final restarted = SqliteBackupStorage(
      live: live,
      schemaVersion: version,
      expectedSchema: storage.expectedSchema,
      snapshot: live.readAsBytes,
      closeLive: () async {},
    );
    await restarted.recoverIfNeeded();
    expect(state(), 'original');
    await restarted.recoverIfNeeded();
    expect(state(), 'original');
  });

  test('damaged safety preserves marker and current file', () async {
    await storage.writeSafetySnapshot(original);
    await storage.writeRecoveryMarker();
    await storage.safety.writeAsBytes([0]);
    await expectLater(storage.recoverIfNeeded(), throwsException);
    expect(await storage.marker.exists(), true);
    expect(await live.readAsBytes(), original);
  });
}
