import 'dart:convert';
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
      final ledger = DriftEntitlementLedgerRepository(database);
      final beforeEntries = await ledger.listByPlan(fixture.entitlement.id);
      final adjustment = beforeEntries.singleWhere(
        (entry) => entry.type == EntitlementEntryType.adjustment,
      );
      expect(adjustment.planId, fixture.entitlement.id);
      expect(adjustment.units, -2);
      expect(adjustment.occurredAt, fixtures.now.toUtc());
      expect(adjustment.note, 'package correction');
      expect(adjustment.referenceId, isNotNull);
      final beforeLedger = {
        for (final entry in beforeEntries)
          entry.id.value: {
            'id': entry.id.value,
            'planId': entry.planId.value,
            'type': entry.type.index,
            'units': entry.units,
            'occurredAt': entry.occurredAt.toIso8601String(),
            'referenceId': entry.referenceId?.value,
            'note': entry.note,
          },
      };
      expect(beforeLedger, hasLength(3));
      final beforeAudit = {
        for (final row in await database.select(database.schemaMetadata).get())
          if (row.key.startsWith('commitment_correction_v1:'))
            row.key: row.value,
      };
      expect(beforeAudit, hasLength(1));
      expect(
        beforeAudit.keys.single,
        'commitment_correction_v1:${adjustment.referenceId!.value}',
      );
      expect(jsonDecode(beforeAudit.values.single), {
        'commitmentId': fixture.commitment.id.value,
        'cycleId': fixture.entitlement.cycleId.value,
        'at': fixtures.now.toUtc().toIso8601String(),
        'reason': 'package correction',
        'scope': 'independent-credit-adjustment',
        'beforeCount': 4,
        'afterCount': 4,
        'beforeRemaining': 3,
        'afterRemaining': 1,
        'scheduleId': null,
        'cancelledIds': <String>[],
      });
      await database.close();
      final sql = sqlite3.open(live.path);
      final schema = SqliteBackupStorage.schema(sql);
      sql.close();
      final storage = SqliteBackupStorage(
        live: live,
        schemaVersion: 19,
        expectedSchema: schema,
        snapshot: live.readAsBytes,
        closeLive: () async {},
      );
      final service = BackupService(
        storage: storage,
        validator: BackupValidator(currentSchemaVersion: 19),
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
      mutate.execute(
        'UPDATE entitlement_ledger_entries SET units=99, note=? WHERE id=?',
        ['different', adjustment.id.value],
      );
      mutate.close();
      await service.restore(BackupPackage.decode(package.encode()));
      // Verify both the restored file and a second independent cold reopen.
      for (var reopen = 0; reopen < 2; reopen++) {
        final reopened = AppDatabase.forTesting(NativeDatabase(live));
        try {
          final entries = await DriftEntitlementLedgerRepository(reopened)
              .listByPlan(fixture.entitlement.id);
          expect(const EntitlementLedger().remaining(entries), 1);
          expect(const EntitlementLedger().fold(entries).consumed, 1);
          expect({
            for (final entry in entries)
              entry.id.value: {
                'id': entry.id.value,
                'planId': entry.planId.value,
                'type': entry.type.index,
                'units': entry.units,
                'occurredAt': entry.occurredAt.toIso8601String(),
                'referenceId': entry.referenceId?.value,
                'note': entry.note,
              },
          }, beforeLedger);
          final restoredAdjustment = entries.singleWhere(
            (entry) => entry.id == adjustment.id,
          );
          expect(restoredAdjustment.type, EntitlementEntryType.adjustment);
          expect(restoredAdjustment.units, -2);
          expect({
            for (final row
                in await reopened.select(reopened.schemaMetadata).get())
              if (row.key.startsWith('commitment_correction_v1:'))
                row.key: row.value,
          }, beforeAudit);
        } finally {
          await reopened.close();
        }
      }
      storage.validateFile(live);
    },
  );
}
