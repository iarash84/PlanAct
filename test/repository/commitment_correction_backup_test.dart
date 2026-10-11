import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/features/backup/data/sqlite_backup_storage.dart';
import 'package:planact/features/commitments/application/commitment_correction.dart';
import 'package:planact/features/commitments/data/drift_commitment_correction_repository.dart';
import 'package:planact/features/sessions/data/drift_session_repositories.dart';
import 'package:planact/features/sessions/domain/entitlement.dart';
import 'package:sqlite3/sqlite3.dart';

import 'commitment_correction_test.dart' as fixtures;
import 'sqlite_backup_restore_test.dart' show Keys, Rebuild;

import 'package:planact/features/backup/application/backup_service.dart';
import 'package:planact/features/backup/data/secure_backup_keys.dart';
import 'package:planact/features/backup/domain/backup_encryption.dart';
import 'package:planact/features/backup/domain/backup_package.dart';

void main() {
  test(
    'signed correction and audit survive encrypted SQLite restore',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'correction-backup',
      );
      addTearDown(() => directory.delete(recursive: true));
      final live = File('${directory.path}/live.sqlite');
      final database = AppDatabase.forTesting(NativeDatabase(live));
      final fixture = await fixtures.seed(database, consumed: true);
      final repository = DriftCommitmentCorrectionRepository(database);
      final preview = await repository.preview(
        CommitmentCorrectionRequest(
          commitmentId: fixture.commitment.id,
          reason: 'package correction',
          creditDelta: -2,
        ),
        fixtures.now,
      );
      await repository.confirm(preview, fixtures.now);
      await database.close();
      final sql = sqlite3.open(live.path);
      final schema = SqliteBackupStorage.schema(sql);
      sql.close();
      final storage = SqliteBackupStorage(
        live: live,
        schemaVersion: 18,
        expectedSchema: schema,
        snapshot: live.readAsBytes,
        closeLive: () async {},
      );
      final service = BackupService(
        storage: storage,
        validator: BackupValidator(currentSchemaVersion: 18),
        rebuildHook: Rebuild(),
        keyStorage: Keys(),
        encryptor: AesGcmBackupEncryptor(),
        nonceGenerator: SecureBackupNonce(),
      );
      final package = await service.create(
        payload: await live.readAsBytes(),
        appVersion: 'test',
        createdAt: fixtures.now,
      );
      final mutate = sqlite3.open(live.path);
      mutate.execute(
        "UPDATE schema_metadata SET value='different' WHERE key LIKE 'commitment_correction_v1:%'",
      );
      mutate.close();
      await service.restore(BackupPackage.decode(package.encode()));
      final reopened = AppDatabase.forTesting(NativeDatabase(live));
      addTearDown(reopened.close);
      final entries = await DriftEntitlementLedgerRepository(reopened)
          .listByPlan(fixture.entitlement.id);
      expect(const EntitlementLedger().remaining(entries), 1);
      expect(entries.last.units, -2);
      expect(entries.last.note, 'package correction');
      final audit = (await reopened.select(reopened.schemaMetadata).get())
          .singleWhere((r) => r.key.startsWith('commitment_correction_v1:'));
      expect(audit.value, contains('package correction'));
      storage.validateFile(live);
    },
  );
}
