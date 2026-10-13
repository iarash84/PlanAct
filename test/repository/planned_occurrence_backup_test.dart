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
import 'package:planact/features/commitments/application/commitment_plan_use_case.dart';
import 'package:planact/features/commitments/data/drift_commitment_plan_repository.dart';
import 'package:planact/features/commitments/data/drift_commitment_repository.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/finance/application/financial_expectation_use_cases.dart';
import 'package:planact/features/finance/data/drift_financial_expectation_repository.dart';
import 'package:planact/features/finance/domain/financial_expectation.dart';
import 'package:planact/features/scheduling/application/planned_occurrences.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:sqlite3/sqlite3.dart';

class _NoKeys implements BackupKeyStorage {
  int reads = 0;
  @override
  Future<Uint8List> loadKey(String keyId) async {
    reads++;
    throw StateError('No source installation keys');
  }
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

Future<Map<String, List<Map<String, Object?>>>> _snapshot(
  AppDatabase db,
) async {
  final tables = await db
      .customSelect(
        "SELECT name FROM sqlite_master WHERE type='table' "
        "AND name NOT LIKE 'sqlite_%' ORDER BY name",
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

Map<String, Object> _projection(PlannedOccurrenceRange range) => {
  'recorded': {
    for (final entry in range.recorded.entries)
      entry.key: [
        for (final row in entry.value)
          [
            row.id.value,
            row.occurrenceKey,
            row.currentScheduledAt.toString(),
            row.status.index,
          ],
      ],
  },
  'preview': {
    for (final entry in range.preview.entries)
      entry.key: [
        for (final slot in entry.value)
          [
            slot.scheduleId.value,
            slot.occurrenceKey,
            slot.scheduledAt.toString(),
            slot.scheduleFingerprint,
          ],
      ],
  },
};

DateTime _jalali(int year, int month, int day) {
  final g = Jalali(year, month, day).toGregorian();
  return DateTime(g.year, g.month, g.day, 18, 35);
}

// Linked, populated historical/session/financial evidence, not empty invariants.
Future<void> _history(AppDatabase db, CommitmentPlan plan) async {
  final cycle = plan.cycle.id.value;
  final occurrence = plan.occurrences.first.id.value;
  await db.customStatement('UPDATE occurrences SET status = 2 WHERE id = ?', [
    occurrence,
  ]);
  final rows = <String, List<String>>{
    'actuals': ["('actual','$occurrence',0,1700000001,'حضور')"],
    'evidences': ["('evidence','actual',0,'سابقه',1700000001)"],
    'entitlement_plans': ["('entitlement','$cycle',4,0,1700000000,NULL,1)"],
    'entitlement_ledger_entries': [
      "('grant','entitlement',0,4,1700000000,NULL,'بسته')",
      "('consume','entitlement',1,1,1700000001,'$occurrence','حضور')",
      "('restore','entitlement',2,1,1700000002,'$occurrence','اصلاح')",
    ],
    'session_policies': ["('policy','$cycle',0,24,1,1,2,0,1,1,NULL,0)"],
    'replacement_occurrences': [
      "('replacement','$occurrence',NULL,1700000003,0,0)",
    ],
    'financial_accounts': ["('bank','بانک','IRR',0,NULL,0)"],
    'account_entries': [
      "('payment','bank',0,1500000,'IRR',1700000000,NULL,'پرداخت',NULL,0,NULL)",
      "('reversal','bank',1,1500000,'IRR',1700000002,'payment','اصلاح',NULL,0,NULL)",
    ],
    'transaction_matches': [
      "('match','payment',500000,'IRR',1700000000,0,NULL)",
      "('corrected','payment',400000,'IRR',1700000001,1,'match')",
    ],
    'match_allocations': [
      "('allocation','match','$occurrence',500000,'IRR',0)",
      "('corrected-allocation','corrected','$occurrence',400000,'IRR',0)",
    ],
    'relationship_reviews': [
      "('review','payment',1,0,1500000,'IRR','active','history',1000000,1700000001)",
    ],
  };
  await db.transaction(() async {
    for (final table in rows.entries) {
      for (final row in table.value) {
        await db.customStatement('INSERT INTO ${table.key} VALUES $row');
      }
    }
  });
  expect(await db.customSelect('PRAGMA foreign_key_check').get(), isEmpty);
}

void main() {
  test('encrypted hybrid restore preserves projection, durable rules and populated history through explicit preparation', () async {
    final root = await Directory.systemTemp.createTemp('hybrid-backup-');
    final sourceFile = File('${root.path}/source/live.sqlite');
    final targetFile = File('${root.path}/target/live.sqlite');
    await sourceFile.parent.create();
    await targetFile.parent.create();
    AppDatabase? source = AppDatabase(NativeDatabase(sourceFile));
    AppDatabase? target = AppDatabase(NativeDatabase(targetFile));
    final key = await BackupRecoveryKey.generate();
    final keys = _NoKeys();
    try {
      final db = source;
      final repo = DriftCommitmentPlanRepository(db);
      final create = CreateCommitmentPlan(
        commitments: DriftCommitmentRepository(db),
        plans: repo,
        financialExpectations: FinancialExpectationUseCases(
          DriftFinancialExpectationRepository(db),
        ),
      );
      final counted = await create(
        title: 'شصت ماه',
        kind: CommitmentKind.recurring,
        startAt: DateTime(2026, 1, 19, 18, 35),
        frequency: RecurrenceFrequency.monthly,
        recurrenceCalendar: RecurrenceCalendar.gregorian,
        occurrenceCount: 60,
        reminderOffsets: const [Duration(minutes: 30), Duration(minutes: 60)],
        financialDirection: FinancialExpectationDirection.outgoing,
        financialAmount: 123456,
      );
      final yearly = await create(
        title: 'سالانه',
        kind: CommitmentKind.recurring,
        startAt: _jalali(1403, 12, 30),
        frequency: RecurrenceFrequency.yearly,
        recurrenceCalendar: RecurrenceCalendar.jalali,
        occurrenceCount: 6,
        reminderOffsets: const [Duration(minutes: 15)],
      );
      final ended = await create(
        title: 'تا تاریخ',
        kind: CommitmentKind.recurring,
        startAt: DateTime(2026, 1, 19, 18, 35),
        frequency: RecurrenceFrequency.monthly,
        recurrenceCalendar: RecurrenceCalendar.gregorian,
        endDate: DateTime(2030, 1, 19),
      );
      await _history(db, counted);
      final today = LocalDate(2026, 1, 1);
      Future<PlannedOccurrenceRange> range(DriftCommitmentPlanRepository r) =>
          r.loadPlannedRange(
            LocalDate(2030, 1, 1),
            LocalDate(2030, 2, 1),
            today,
          );
      final before = await _snapshot(db);
      final projected = _projection(await range(repo));
      expect(
        (await range(repo)).preview[counted.commitment.id.value],
        hasLength(1),
      );
      expect(
        (await range(repo)).preview[ended.commitment.id.value],
        hasLength(1),
      );
      expect(await _snapshot(db), before, reason: 'Preview changes no table');
      final sqlSchema = _schema(sourceFile);
      final storage = SqliteBackupStorage(
        live: sourceFile,
        schemaVersion: db.schemaVersion,
        expectedSchema: sqlSchema,
        snapshot: () => sqliteBackupSnapshot(
          database: db,
          target: File('${sourceFile.path}.snapshot'),
          redact: false,
        ),
        closeLive: db.close,
      );
      final export = BackupService(
        storage: storage,
        validator: BackupValidator(currentSchemaVersion: db.schemaVersion),
        rebuildHook: _Rebuild(() async {}),
        keyStorage: keys,
        encryptor: AesGcmBackupEncryptor(),
        nonceGenerator: SecureBackupNonce(),
      );
      final payload = await sqliteBackupSnapshot(
        database: db,
        target: File('${sourceFile.path}.export'),
        redact: true,
      );
      await storage.validatePayload(payload);
      final package = await export.create(
        payload: payload,
        appVersion: 'hybrid-test',
        recoveryKey: key.bytes,
        createdAt: DateTime.utc(2026, 10, 12),
      );
      expect(package.formatVersion, 2);
      expect(package.payload, isNot(payload));
      final encoded = package.encode();
      expect(encoded, isNot(contains(key.text)));
      await db.close();
      source = null;
      await sourceFile.parent.delete(recursive: true);
      await target.writeMetadata('target', 'safety');
      var targetRepo = DriftCommitmentPlanRepository(target);
      final oldRepo = targetRepo;
      final targetStorage = SqliteBackupStorage(
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
      final restore = BackupService(
        storage: targetStorage,
        validator: BackupValidator(currentSchemaVersion: db.schemaVersion),
        rebuildHook: _Rebuild(() async {
          expect(target, isNull);
          target = AppDatabase(NativeDatabase(targetFile));
          targetRepo = DriftCommitmentPlanRepository(target!);
        }),
        keyStorage: keys,
        encryptor: AesGcmBackupEncryptor(),
        nonceGenerator: SecureBackupNonce(),
      );
      await restore.restore(
        BackupPackage.decode(encoded),
        recoveryKey: key.bytes,
      );
      expect(keys.reads, 0);
      expect(identical(oldRepo, targetRepo), false);
      targetStorage.validateFile(targetFile);
      targetStorage.validateFile(targetStorage.safety);
      expect(await _snapshot(target!), before);
      expect(_projection(await range(targetRepo)), projected);
      await target!.close();
      target = AppDatabase(NativeDatabase(targetFile));
      targetRepo = DriftCommitmentPlanRepository(target!);
      expect(await _snapshot(target!), before);
      expect(_projection(await range(targetRepo)), projected);
      final restoredYearly = (await targetRepo.findByCommitmentId(
        yearly.commitment.id,
      ))!;
      expect(restoredYearly.schedule.occurrenceCount, 6);
      expect(
        restoredYearly.schedule.recurrenceRule!.calendar,
        RecurrenceCalendar.jalali,
      );
      expect(restoredYearly.schedule.recurrenceRule!.monthOfYear, 12);
      expect(restoredYearly.schedule.recurrenceRule!.dayOfMonth, 30);
      final leap = LocalDate.fromDateTime(_jalali(1408, 12, 30));
      expect(
        (await targetRepo.loadPlannedRange(
          leap,
          leap.addDays(1),
          today,
        )).preview[yearly.commitment.id.value]!.single.date,
        leap,
      );
      expect(
        (await targetRepo.loadPlannedRange(
          LocalDate(2030, 2, 1),
          LocalDate(2030, 3, 1),
          today,
        )).preview[ended.commitment.id.value],
        isNull,
      );
      final slot = (await range(targetRepo))
          .preview[counted.commitment.id.value]!
          .single;
      final admitted = await targetRepo.preparePlannedOccurrence(slot, today);
      final after = await _snapshot(target!);
      for (final table in before.entries) {
        for (final old in table.value) {
          expect(
            after[table.key],
            contains(equals(old)),
            reason: '${table.key} existing rows unchanged',
          );
        }
      }
      for (final table in [
        'actuals',
        'evidences',
        'entitlement_plans',
        'entitlement_ledger_entries',
        'session_policies',
        'replacement_occurrences',
        'financial_accounts',
        'account_entries',
        'transaction_matches',
        'match_allocations',
        'relationship_reviews',
        'schedule_definitions',
      ]) {
        expect(before[table], isNotEmpty);
        expect(after[table], before[table]);
      }
      expect(after['occurrences']!.length, before['occurrences']!.length + 1);
      expect(
        after['reminder_rules']!
            .where((r) => r['occurrence_id'] == admitted.id.value)
            .map((r) => r['offset_seconds'])
            .toSet(),
        {-1800, -3600},
      );
      expect(
        after['reminder_instances']!.where(
          (r) => r['occurrence_id'] == admitted.id.value,
        ),
        hasLength(2),
      );
      expect(
        after['financial_expectations']!.singleWhere(
          (r) => r['occurrence_id'] == admitted.id.value,
        )['minor_units'],
        123456,
      );
      await expectLater(
        targetRepo.preparePlannedOccurrence(slot, today),
        throwsStateError,
      );
      expect(await _snapshot(target!), after);
      await target!.close();
      target = AppDatabase(NativeDatabase(targetFile));
      expect(await _snapshot(target!), after);
      expect(
        await target!.customSelect('PRAGMA foreign_key_check').get(),
        isEmpty,
      );
    } finally {
      key.dispose();
      await source?.close();
      await target?.close();
      await root.delete(recursive: true);
    }
  });

  test('literal legacy 90-day horizon does not terminate the logical 60-slot count', () async {
    final root = await Directory.systemTemp.createTemp('hybrid-legacy90-');
    final file = File('${root.path}/live.sqlite');
    var db = AppDatabase(NativeDatabase(file));
    try {
      final plan =
          await CreateCommitmentPlan(
            commitments: DriftCommitmentRepository(db),
            plans: DriftCommitmentPlanRepository(db),
            financialExpectations: FinancialExpectationUseCases(
              DriftFinancialExpectationRepository(db),
            ),
          )(
            title: 'قدیمی',
            kind: CommitmentKind.recurring,
            startAt: DateTime(2026, 1, 19, 18, 35),
            frequency: RecurrenceFrequency.monthly,
            occurrenceCount: 60,
            reminderOffsets: const [Duration(minutes: 30)],
            financialDirection: FinancialExpectationDirection.outgoing,
            financialAmount: 1000,
          );
      // Literal old payload, not modern JSON with selectively removed keys.
      await db.customStatement(
        'UPDATE schedule_definitions SET generation_horizon_days = 90, recurrence_rule = ? WHERE id = ?',
        [
          '{"frequency":2,"interval":1,"weekdays":[],"dayOfMonth":19,"monthEndPolicy":0}',
          plan.schedule.id.value,
        ],
      );
      await db.close();
      db = AppDatabase(NativeDatabase(file));
      final repo = DriftCommitmentPlanRepository(db);
      final before = await _snapshot(db);
      final restored = (await repo.findByCommitmentId(plan.commitment.id))!;
      expect(restored.schedule.generationHorizonDays, 90);
      expect(restored.schedule.occurrenceCount, 60);
      expect(
        restored.schedule.recurrenceRule!.calendar,
        RecurrenceCalendar.gregorian,
      );
      final today = LocalDate(2026, 1, 1);
      final last = await repo.loadPlannedRange(
        LocalDate(2030, 12, 1),
        LocalDate(2031, 1, 1),
        today,
      );
      expect(
        last.preview[plan.commitment.id.value]!.single.date,
        LocalDate(2030, 12, 19),
      );
      expect(
        (await repo.loadPlannedRange(
          LocalDate(2031, 1, 1),
          LocalDate(2031, 2, 1),
          today,
        )).preview,
        isEmpty,
      );
      expect(await _snapshot(db), before);
    } finally {
      await db.close();
      await root.delete(recursive: true);
    }
  });
}
