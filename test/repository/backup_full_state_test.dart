import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/database/app_database.dart';
import 'package:planact/features/backup/application/backup_service.dart';
import 'package:planact/features/backup/data/secure_backup_keys.dart';
import 'package:planact/features/backup/data/sqlite_backup_snapshot.dart';
import 'package:planact/features/backup/data/sqlite_backup_storage.dart';
import 'package:planact/features/backup/domain/backup_encryption.dart';
import 'package:planact/features/backup/domain/backup_package.dart';
import 'package:sqlite3/sqlite3.dart';

class _Keys implements BackupKeyStorage {
  @override
  Future<Uint8List> loadKey(String keyId) async =>
      Uint8List.fromList(List.filled(32, 7));
}

class _Rebuild implements BackupRebuildHook {
  bool failOnce = false;
  @override
  Future<void> rebuild() async {
    if (failOnce) {
      failOnce = false;
      throw StateError('injected rebuild failure');
    }
  }
}

// Explicit linked fixture: adding a persisted table requires extending this
// fixture rather than silently passing with an empty table.
const _rows = <String, List<String>>{
  'commitments': [
    "('c','کلاس موسیقی',1700000000,0,0,1,'violet','یادداشت','','')",
    "('archived','تاریخچه',1700000001,4,0,1,NULL,NULL,'','')",
  ],
  'commitment_cycles': ["('cycle','c',0,1700000000,NULL,NULL,4,1,0,0)"],
  'schedule_definitions': [
    "('schedule','cycle',0,0,'2026-10-05','18:00','Asia/Tehran',NULL,NULL,NULL,NULL,1,'2026-10-05',90)",
  ],
  'occurrences': [
    "('occ','cycle','schedule','first',0,'2026-10-05T18:00','2026-10-05T19:00',0,1)",
    "('done','cycle','schedule','second',0,'2026-10-06T18:00','2026-10-06T18:00',2,0)",
  ],
  'entitlement_plans': ["('plan','cycle',4,0,1700000000,NULL,1)"],
  'entitlement_ledger_entries': [
    "('grant','plan',0,4,1700000000,NULL,'خرید بسته')",
    "('consume','plan',1,1,1700000001,'done','حضور')",
    "('restore','plan',2,1,1700000002,'done','اصلاح')",
  ],
  'session_policies': ["('policy','cycle',0,24,1,1,2,0,1,1,NULL,0)"],
  'replacement_occurrences': [
    "('replacement','done',NULL,1700000003,0,0)",
    "('replacement-again','done','replacement',1700000004,0,1)",
  ],
  'reminder_rules': ["('rule','occ',0,-3600,NULL,'یادآوری','کلاس',1)"],
  'reminder_instances': [
    "('reminder','rule','occ',1700000005,0,1700000006,'1234')",
  ],
  'actuals': ["('actual','done',0,1700000001,'انجام شد')"],
  'evidences': ["('evidence','actual',0,'یادداشت حضور',1700000001)"],
  'financial_accounts': [
    "('bank','بانک','IRR',0,'bank-code',0)",
    "('wallet','کیف پول','IRR',1,NULL,0)",
    "('old-account','قدیمی','IRR',0,NULL,1)",
  ],
  'account_entries': [
    "('payment','bank',0,1500000,'IRR',1700000000,NULL,'پرداخت','آموزش',0,NULL)",
    "('transfer-out','bank',0,200000,'IRR',1700000001,NULL,NULL,NULL,0,'transfer')",
    "('transfer-in','wallet',1,200000,'IRR',1700000001,NULL,NULL,NULL,0,'transfer')",
    "('reversal','bank',1,1500000,'IRR',1700000002,'payment','اصلاح',NULL,0,NULL)",
  ],
  'transaction_matches': [
    "('match','payment',500000,'IRR',1700000000,0,NULL)",
    "('corrected','payment',400000,'IRR',1700000001,1,'match')",
  ],
  'match_allocations': [
    "('allocation','match','done',500000,'IRR',0)",
    "('corrected-allocation','corrected','done',400000,'IRR',0)",
  ],
  'relationship_reviews': [
    "('independent','payment',1,0,1500000,'IRR','active-fingerprint','history-fingerprint',1000000,1700000001)",
    "('reopened','payment',2,1,1500000,'IRR','active-fingerprint','history-fingerprint',1000000,1700000002)",
  ],
  'financial_expectations': [
    "('expectation','done',0,1500000,'IRR','bank',0,1700000000,1700000001)",
  ],
  'tags': ["('tag','آموزش','آموزش',1700000000)"],
  'commitment_tags': ["('c','tag')"],
  'account_entry_tags': ["('payment','tag')"],
  'staged_imports': [
    "('sms','PRIVATE_RAW_SMS','fingerprint',0,NULL,NULL,0,'source-key',1700000000,'test',0)",
  ],
  'inbox_suggestions': [
    "('suggestion','sms','draft',1500000,'IRR',1700000000,'expense','فروشنده','reference',0)",
  ],
};

Map<String, List<Map<String, Object?>>> _logical(File file) {
  final db = sqlite3.open(file.path, mode: OpenMode.readOnly);
  try {
    return {
      for (final table in db.select(
        "SELECT name FROM sqlite_master WHERE type='table' "
        "AND name NOT LIKE 'sqlite_%' ORDER BY name",
      ))
        table['name'] as String: [
          for (final row in db.select(
            'SELECT * FROM "${table['name']}" ORDER BY rowid',
          ))
            Map<String, Object?>.from(row),
        ],
    };
  } finally {
    db.close();
  }
}

void main() {
  for (final rollback in [false, true]) {
    test(
      'every persisted table survives encrypted ${rollback ? 'rollback' : 'restore'} and cold restart',
      () async {
        final directory = await Directory.systemTemp.createTemp(
          'planact-full-backup-',
        );
        final live = File('${directory.path}/live.sqlite');
        final database = AppDatabase(NativeDatabase(live));
        try {
          await database.customSelect('SELECT 1').get();
          await database.transaction(() async {
            for (final table in _rows.entries) {
              for (final row in table.value) {
                await database.customStatement(
                  'INSERT INTO ${table.key} VALUES $row',
                );
              }
            }
            await database.writeMetadata('theme_mode', 'dark');
            await database.writeMetadata('holiday_policy', 'preserve');
          });
          final exported = await sqliteBackupSnapshot(
            database: database,
            target: File('${directory.path}/export.sqlite'),
            redact: true,
          );
          await database.close();
          final original = _logical(live);
          expect(original.keys.toSet(), {..._rows.keys, 'schema_metadata'});
          final expected = {
            for (final table in original.entries)
              table.key: [
                for (final row in table.value) Map<String, Object?>.from(row),
              ],
          };
          expected['staged_imports']!.single['raw_text'] = '';
          expected['reminder_instances']!.single['platform_notification_id'] =
              null;
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
          final rebuild = _Rebuild()..failOnce = rollback;
          final service = BackupService(
            storage: storage,
            validator: const BackupValidator(currentSchemaVersion: 18),
            rebuildHook: rebuild,
            keyStorage: _Keys(),
            encryptor: AesGcmBackupEncryptor(),
            nonceGenerator: SecureBackupNonce(),
          );
          final package = BackupPackage.decode(
            (await service.create(
              payload: exported,
              appVersion: 'test',
              createdAt: DateTime.utc(2026),
            )).encode(),
          );
          if (rollback) {
            await expectLater(service.restore(package), throwsException);
          } else {
            await service.restore(package);
          }
          final reopened = AppDatabase(NativeDatabase(live));
          try {
            expect(await reopened.readMetadata('theme_mode'), 'dark');
            expect(await reopened.readMetadata('holiday_policy'), 'preserve');
          } finally {
            await reopened.close();
          }
          storage.validateFile(live);
          expect(_logical(live), rollback ? original : expected);
          expect(await storage.marker.exists(), false);
        } finally {
          await database.close();
          await directory.delete(recursive: true);
        }
      },
    );
  }
}
