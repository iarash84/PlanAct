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
import 'package:planact/features/backup/domain/backup_recovery_key.dart';
import 'package:sqlite3/sqlite3.dart';

class _NoInstallationKeys implements BackupKeyStorage {
  @override
  Future<Uint8List> loadKey(String _) async =>
      throw StateError('No old install');
}

class _Rebuild implements BackupRebuildHook {
  @override
  Future<void> rebuild() async {}
}

void main() {
  test('independent directories restore offline with file and key only; failures preserve target', () async {
    final root = await Directory.systemTemp.createTemp('independent-recovery-');
    final key = await BackupRecoveryKey.generate();
    final wrong = await BackupRecoveryKey.generate();
    try {
      final source = File('${root.path}/source/live.sqlite');
      final target = File('${root.path}/fresh/live.sqlite');
      await source.parent.create();
      await target.parent.create();
      for (final file in [source, target]) {
        final db = AppDatabase(NativeDatabase(file));
        await db.writeMetadata(
          'independent',
          file == source ? 'source' : 'target',
        );
        await db.close();
      }
      BackupService service(File file) {
        final db = sqlite3.open(file.path);
        final schema = SqliteBackupStorage.schema(db);
        db.close();
        return BackupService(
          storage: SqliteBackupStorage(
            live: file,
            schemaVersion: 19,
            expectedSchema: schema,
            snapshot: file.readAsBytes,
            closeLive: () async {},
          ),
          validator: const BackupValidator(currentSchemaVersion: 19),
          rebuildHook: _Rebuild(),
          keyStorage: _NoInstallationKeys(),
          encryptor: AesGcmBackupEncryptor(),
          nonceGenerator: SecureBackupNonce(),
        );
      }

      final package = await service(source).create(
        payload: await source.readAsBytes(),
        appVersion: 'test',
        createdAt: DateTime.utc(2026),
        recoveryKey: key.bytes,
      );
      expect(package.formatVersion, 2);
      expect(package.encode(), isNot(contains(key.text)));
      final decoded = BackupPackage.decode(package.encode());
      final fresh = service(target);
      final original = await target.readAsBytes();
      await expectLater(fresh.restore(decoded), throwsException);
      await expectLater(
        fresh.restore(decoded, recoveryKey: wrong.bytes),
        throwsException,
      );
      expect(await target.readAsBytes(), original);
      // Recomputed checksum cannot defeat GCM authentication.
      final tampered = BackupPackage(
        formatVersion: 2,
        schemaVersion: decoded.schemaVersion,
        appVersion: decoded.appVersion,
        createdAt: decoded.createdAt,
        encryptionMetadata: decoded.encryptionMetadata,
        payload: Uint8List.fromList([...decoded.payload]..[0] ^= 1),
      );
      await expectLater(
        fresh.restore(tampered, recoveryKey: key.bytes),
        throwsException,
      );
      expect(await target.readAsBytes(), original);
      final text = key.text;
      await source.parent.delete(recursive: true);
      key.dispose();
      final entered = BackupRecoveryKey.parse(text);
      try {
        await fresh.restore(decoded, recoveryKey: entered.bytes);
      } finally {
        entered.dispose();
      }
      final reopened = AppDatabase(NativeDatabase(target));
      expect(await reopened.readMetadata('independent'), 'source');
      await reopened.close();
    } finally {
      key.dispose();
      wrong.dispose();
      await root.delete(recursive: true);
    }
  });

  test('keys are independent 256-bit canonical keys, not passwords', () async {
    final first = await BackupRecoveryKey.generate();
    final second = await BackupRecoveryKey.generate();
    expect(first.bytes.length, 32);
    expect(second.text, isNot(first.text));
    expect(BackupRecoveryKey.parse(first.text).bytes, first.bytes);
    for (final invalid in [
      '',
      'password',
      first.text.substring(1),
      '${first.text}!',
    ]) {
      expect(() => BackupRecoveryKey.parse(invalid), throwsException);
    }
    first.dispose();
    second.dispose();
  });
}
