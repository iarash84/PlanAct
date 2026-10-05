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
  @override
  Future<Uint8List> loadKey(String _) async => Uint8List(32);
}

class Rebuild implements BackupRebuildHook {
  @override
  Future<void> rebuild() async {}
}

class FailingStorage extends SqliteBackupStorage {
  FailingStorage({
    required super.live,
    required super.schemaVersion,
    required super.expectedSchema,
    required super.snapshot,
    required super.closeLive,
    required this.stage,
  });
  final String stage;
  bool failed = false;
  void fail(String current) {
    if (!failed && stage == current) {
      failed = true;
      throw FileSystemException('injected $current');
    }
  }

  @override
  Future<void> writeSafetySnapshot(Uint8List payload) async {
    fail('safety');
    await super.writeSafetySnapshot(payload);
  }

  @override
  Future<void> writeTemporary(Uint8List payload) async {
    fail('temporary');
    await super.writeTemporary(payload);
  }

  @override
  Future<void> flushTemporary() async {
    fail('flush');
    await super.flushTemporary();
  }

  @override
  Future<void> writeRecoveryMarker() async {
    fail('marker');
    await super.writeRecoveryMarker();
  }

  @override
  Future<void> replaceTemporary() async {
    fail('replace');
    await super.replaceTemporary();
  }

  @override
  Future<void> clearRecoveryMarker() async {
    fail('commit');
    await super.clearRecoveryMarker();
  }
}

void main() {
  for (final stage in [
    'safety',
    'temporary',
    'flush',
    'marker',
    'replace',
    'commit',
  ]) {
    test(
      '$stage failure preserves original file-backed state after restart',
      () async {
        final directory = await Directory.systemTemp.createTemp(
          'backup-failure-',
        );
        final live = File('${directory.path}/live.sqlite');
        final database = AppDatabase(NativeDatabase(live));
        await database.writeMetadata('state', 'original');
        final version = database.schemaVersion;
        await database.close();
        final sql = sqlite3.open(live.path);
        final schema = SqliteBackupStorage.schema(sql);
        sql.close();
        final original = await live.readAsBytes();
        final candidate = File('${directory.path}/candidate.sqlite');
        await candidate.writeAsBytes(original);
        final changed = sqlite3.open(candidate.path);
        changed.execute(
          "UPDATE schema_metadata SET value='candidate' WHERE key='state'",
        );
        changed.close();
        final storage = FailingStorage(
          live: live,
          schemaVersion: version,
          expectedSchema: schema,
          snapshot: live.readAsBytes,
          closeLive: () async {},
          stage: stage,
        );
        final service = BackupService(
          storage: storage,
          validator: BackupValidator(currentSchemaVersion: version),
          rebuildHook: Rebuild(),
          keyStorage: Keys(),
          encryptor: AesGcmBackupEncryptor(),
          nonceGenerator: SecureBackupNonce(),
        );
        try {
          // A prior snapshot must never be used if the current snapshot fails.
          await storage.safety.writeAsBytes(await candidate.readAsBytes());
          final package = await service.create(
            payload: await candidate.readAsBytes(),
            appVersion: 'test',
            createdAt: DateTime.utc(2026),
          );
          await expectLater(service.restore(package), throwsException);
          expect(storage.failed, true);
          final reopened = AppDatabase(NativeDatabase(live));
          expect(await reopened.readMetadata('state'), 'original');
          await reopened.close();
          storage.validateFile(live);
          expect(await storage.marker.exists(), false);
        } finally {
          await directory.delete(recursive: true);
        }
      },
    );
  }
}
