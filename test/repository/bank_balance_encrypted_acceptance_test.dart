import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/features/backup/application/backup_service.dart';
import 'package:planact/features/backup/data/secure_backup_keys.dart';
import 'package:planact/features/backup/data/sqlite_backup_snapshot.dart';
import 'package:planact/features/backup/data/sqlite_backup_storage.dart';
import 'package:planact/features/backup/domain/backup_encryption.dart';
import 'package:planact/features/backup/domain/backup_package.dart';
import 'package:planact/features/backup/domain/backup_recovery_key.dart';
import 'package:planact/features/finance/data/drift_finance_repository.dart';
import 'package:sqlite3/sqlite3.dart';

import 'bank_recovery_test.dart' show account, chain;

class _Keys implements BackupKeyStorage {
  @override
  Future<Uint8List> loadKey(String keyId) =>
      throw StateError('No installation key available');
}

class _Rebuild implements BackupRebuildHook {
  _Rebuild(this.action);
  final Future<void> Function() action;
  @override
  Future<void> rebuild() => action();
}

List<String> _schema(File file) {
  final db = sqlite3.open(file.path, mode: OpenMode.readOnly);
  try {
    return SqliteBackupStorage.schema(db);
  } finally {
    db.close();
  }
}

Future<Map<String, Object?>> _rows(AppDatabase db) async {
  final tables = await db
      .customSelect(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name",
      )
      .get();
  return {
    for (final table in tables)
      table.read<String>('name'): [
        for (final row
            in await db
                .customSelect(
                  'SELECT * FROM "${table.read<String>('name')}" ORDER BY rowid',
                )
                .get())
          Map<String, Object?>.from(row.data),
      ],
  };
}

void main() {
  test('encrypted bank review and recovery history restores with strict validation and cold reopen', () async {
    final root = await Directory.systemTemp.createTemp('bank-encrypted-');
    final sourceFile = File('${root.path}/source.sqlite');
    final targetFile = File('${root.path}/target.sqlite');
    AppDatabase? source = AppDatabase(NativeDatabase(sourceFile));
    AppDatabase? target = AppDatabase(NativeDatabase(targetFile));
    final key = await BackupRecoveryKey.generate();
    final wrongKey = await BackupRecoveryKey.generate();
    try {
      final repo = DriftFinanceRepository(source);
      final a = account('حساب پذیرش');
      await chain(source, repo, a);
      await repo.recoverBankReconciliations(
        await repo.previewBankRecovery({a.id.value}),
      );
      final original = (await repo.bankBalance(a.id.value)).observations.first;
      await repo.reviewBankObservation(
        expected: original,
        accountId: a.id.value,
        sourceAmount: 350,
        sourceUnit: 'rial',
        transactionTime: original.transactionTime,
        active: true,
      );
      final expected = await _rows(source);
      final fingerprint = (await repo.bankBalance(a.id.value)).token;
      final sourceDb = source;
      final sourceStorage = SqliteBackupStorage(
        live: sourceFile,
        schemaVersion: source.schemaVersion,
        expectedSchema: _schema(sourceFile),
        snapshot: () => sqliteBackupSnapshot(
          database: sourceDb,
          target: File('${sourceFile.path}.snapshot'),
          redact: false,
        ),
        closeLive: sourceDb.close,
      );
      BackupService service(
        SqliteBackupStorage storage,
        BackupRebuildHook rebuild,
      ) => BackupService(
        storage: storage,
        validator: BackupValidator(
          currentSchemaVersion: sourceDb.schemaVersion,
        ),
        rebuildHook: rebuild,
        keyStorage: _Keys(),
        encryptor: AesGcmBackupEncryptor(),
        nonceGenerator: SecureBackupNonce(),
      );
      final payload = await sqliteBackupSnapshot(
        database: source,
        target: File('${sourceFile.path}.export'),
        redact: true,
      );
      await sourceStorage.validatePayload(payload);
      final package = await service(sourceStorage, _Rebuild(() async {}))
          .create(
            payload: payload,
            appVersion: 'bank-acceptance',
            createdAt: DateTime.utc(2026, 11, 16),
            recoveryKey: key.bytes,
          );
      expect(package.formatVersion, 2);
      final exported = File('${root.path}/bank.planactbackup');
      await exported.writeAsString(package.encode(), flush: true);
      expect(await exported.readAsString(), isNot(contains(key.text)));
      await source.close();
      source = null;
      await sourceFile.delete();
      await target.writeMetadata('acceptance-target', 'preserve-on-rejection');
      final before = await _rows(target);
      var rebuilds = 0;
      final storage = SqliteBackupStorage(
        live: targetFile,
        schemaVersion: target.schemaVersion,
        expectedSchema: _schema(targetFile),
        snapshot: () => sqliteBackupSnapshot(
          database: target!,
          target: File('${targetFile.path}.snapshot'),
          redact: false,
        ),
        closeLive: () async {
          await target!.close();
          target = null;
        },
      );
      final importer = service(
        storage,
        _Rebuild(() async {
          expect(target, isNull);
          target = AppDatabase(NativeDatabase(targetFile));
          rebuilds++;
        }),
      );
      final decoded = BackupPackage.decode(await exported.readAsString());
      await expectLater(
        importer.restore(decoded, recoveryKey: wrongKey.bytes),
        throwsException,
      );
      expect(await _rows(target!), before);
      expect(rebuilds, 0);
      await importer.restore(decoded, recoveryKey: key.bytes);
      expect(rebuilds, 1);
      expect(await _rows(target!), expected);
      storage.validateFile(targetFile);
      storage.validateFile(storage.safety);
      final safety = AppDatabase(NativeDatabase(storage.safety));
      try {
        expect(await _rows(safety), before);
      } finally {
        await safety.close();
      }
      await target!.close();
      target = AppDatabase(NativeDatabase(targetFile));
      expect(await _rows(target!), expected);
      final restored = DriftFinanceRepository(target!);
      expect((await restored.bankBalance(a.id.value)).token, fingerprint);
      expect(
        (await restored.bankBalance(a.id.value)).observations.first.revision,
        1,
      );
      expect(
        (await restored.previewBankRecovery({a.id.value})).decisions,
        isEmpty,
      );
      expect((await restored.listEntries()).length, 4);
    } finally {
      key.dispose();
      wrongKey.dispose();
      await source?.close();
      await target?.close();
      await root.delete(recursive: true);
    }
  });
}
