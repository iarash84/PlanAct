import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/features/actuals/data/drift_actual_repository.dart';
import 'package:planact/features/actuals/domain/actual.dart';
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
import 'package:planact/features/reminders/application/reminder_service.dart';
import 'package:planact/features/reminders/data/drift_reminder_repository.dart';
import 'package:planact/features/reminders/domain/reminder.dart';
import 'package:planact/features/scheduling/application/edit_commitment_schedule.dart';
import 'package:planact/features/scheduling/application/extend_recurring_schedules.dart';
import 'package:planact/features/scheduling/application/series_editing.dart';
import 'package:planact/features/scheduling/domain/occurrence.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:sqlite3/sqlite3.dart';

// Scoped repository acceptance: production snapshot/encryption/strict validation,
// real close/rebind and cold reopen, then rolling from restored durable metadata.
// No native delivery, widget journey, legacy or concurrency acceptance is claimed.
class _NoInstallationKeys implements BackupKeyStorage {
  int reads = 0;

  @override
  Future<Uint8List> loadKey(String keyId) async {
    reads++;
    throw StateError('Fresh installation has no source installation key');
  }
}

class _Platform implements ReminderPlatformAdapter {
  final scheduled = <ReminderInstance>[];
  final cancelled = <ReminderInstance>[];

  @override
  Future<void> schedule(ReminderInstance instance) async =>
      scheduled.add(instance);

  @override
  Future<void> cancel(ReminderInstance instance) async =>
      cancelled.add(instance);
}

class _Rebuild implements BackupRebuildHook {
  _Rebuild(this.action);
  final Future<void> Function() action;
  int calls = 0;

  @override
  Future<void> rebuild() async {
    calls++;
    await action();
  }
}

DateTime _at(int year, int month, int day, {int hour = 18}) {
  final date = Jalali(year, month, day).toGregorian();
  return DateTime(date.year, date.month, date.day, hour, 35);
}

List<String> _schema(File file) {
  final db = sqlite3.open(file.path, mode: OpenMode.readOnly);
  try {
    return SqliteBackupStorage.schema(db);
  } finally {
    db.close();
  }
}

Future<Map<String, List<Map<String, Object?>>>> _logical(AppDatabase db) async {
  final tables = await db
      .customSelect(
        "SELECT name FROM sqlite_master WHERE type = 'table' "
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

void main() {
  // Encrypted backup coverage intentionally creates independent database
  // owners for source, target, safety, and cold-reopen validation.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  test('independent encrypted restore rebinds recurrence, cold reopens and extends without rewriting history', () async {
    final root = await Directory.systemTemp.createTemp('recurrence-recovery-');
    final sourceFile = File('${root.path}/source/live.sqlite');
    final targetFile = File('${root.path}/fresh/live.sqlite');
    await sourceFile.parent.create();
    await targetFile.parent.create();
    AppDatabase? source = AppDatabase(NativeDatabase(sourceFile));
    AppDatabase? target = AppDatabase(NativeDatabase(targetFile));
    final key = await BackupRecoveryKey.generate();
    final wrongKey = await BackupRecoveryKey.generate();
    final keys = _NoInstallationKeys();
    final platform = _Platform();
    try {
      final sourceDb = source;
      final sourcePlans = DriftCommitmentPlanRepository(sourceDb);
      final create = CreateCommitmentPlan(
        commitments: DriftCommitmentRepository(sourceDb),
        plans: sourcePlans,
        financialExpectations: FinancialExpectationUseCases(
          DriftFinancialExpectationRepository(sourceDb),
        ),
        reminderService: ReminderService(
          repository: DriftReminderRepository(sourceDb),
          platform: platform,
        ),
      );
      final monthly = await create(
        title: 'اجاره ماهانه',
        kind: CommitmentKind.recurring,
        startAt: _at(1405, 7, 19),
        frequency: RecurrenceFrequency.monthly,
        recurrenceCalendar: RecurrenceCalendar.jalali,
        reminderOffsets: const [Duration(minutes: 30), Duration(minutes: 60)],
        financialDirection: FinancialExpectationDirection.outgoing,
        financialAmount: 123456,
      );
      final yearly = await create(
        title: 'تمدید سالانه',
        kind: CommitmentKind.recurring,
        startAt: _at(1405, 7, 19),
        frequency: RecurrenceFrequency.yearly,
        recurrenceCalendar: RecurrenceCalendar.jalali,
        reminderOffsets: const [Duration(minutes: 45)],
        financialDirection: FinancialExpectationDirection.incoming,
        financialAmount: 654321,
      );
      final counted = await create(
        title: 'سالانه با تعداد محدود',
        kind: CommitmentKind.recurring,
        startAt: _at(1403, 12, 30),
        frequency: RecurrenceFrequency.yearly,
        recurrenceCalendar: RecurrenceCalendar.jalali,
        occurrenceCount: 6,
        reminderOffsets: const [Duration(minutes: 15)],
        financialDirection: FinancialExpectationDirection.outgoing,
        financialAmount: 777,
      );
      final ended = await create(
        title: 'ماهانه تا تاریخ مشخص',
        kind: CommitmentKind.recurring,
        startAt: _at(1405, 7, 19),
        frequency: RecurrenceFrequency.monthly,
        recurrenceCalendar: RecurrenceCalendar.jalali,
        endDate: _at(1406, 9, 19),
        reminderOffsets: const [Duration(minutes: 10)],
      );
      final completed = await DriftActualRepository(sourceDb)
          .recordOccurrenceActual(
            expected: monthly.occurrences.first,
            outcome: ActualOutcome.completed,
            recordedAt: _at(1405, 7, 19),
            note: 'سابقه باید حفظ شود',
          );
      final moved = monthly.occurrences[2].reschedule(_at(1405, 9, 22));
      await sourcePlans.saveOccurrence(moved);
      await EditCommitmentSchedule(sourcePlans)(
        commitmentId: monthly.commitment.id,
        expected: monthly.occurrences[1],
        scheduledAt: _at(1405, 8, 19, hour: 20),
        scope: SeriesEditScope.thisAndFollowing,
        now: _at(1405, 8, 1),
      );
      await sourceDb.writeMetadata('recurrence_acceptance', 'source');
      // Platform IDs are deliberately not portable; durable rules/history are.
      await sourceDb.customStatement(
        'UPDATE reminder_instances SET platform_notification_id = ?',
        ['source-installation-only'],
      );
      final expected = await _logical(sourceDb);
      for (final row in expected['reminder_instances']!) {
        row['platform_notification_id'] = null;
      }
      final sourceStorage = SqliteBackupStorage(
        live: sourceFile,
        schemaVersion: sourceDb.schemaVersion,
        expectedSchema: _schema(sourceFile),
        snapshot: () => sqliteBackupSnapshot(
          database: sourceDb,
          target: File('${sourceFile.path}.snapshot'),
          redact: false,
        ),
        closeLive: sourceDb.close,
      );
      final exporter = BackupService(
        storage: sourceStorage,
        validator: BackupValidator(
          currentSchemaVersion: sourceDb.schemaVersion,
        ),
        rebuildHook: _Rebuild(() async {}),
        keyStorage: keys,
        encryptor: AesGcmBackupEncryptor(),
        nonceGenerator: SecureBackupNonce(),
      );
      final payload = await sqliteBackupSnapshot(
        database: sourceDb,
        target: File('${sourceFile.path}.export'),
        redact: true,
      );
      await sourceStorage.validatePayload(payload);
      final package = await exporter.create(
        payload: payload,
        appVersion: 'recurrence-acceptance',
        createdAt: DateTime.utc(2026, 10, 10),
        recoveryKey: key.bytes,
      );
      expect(package.formatVersion, 2);
      expect(package.payload, isNot(payload));
      expect(package.encode(), isNot(contains(key.text)));
      final backupFile = File('${root.path}/recurrence.planactbackup');
      await backupFile.writeAsString(package.encode(), flush: true);
      final keyText = key.text;
      key.dispose();
      await sourceDb.close();
      source = null;
      await sourceFile.parent.delete(recursive: true);

      await target.writeMetadata('recurrence_acceptance', 'target');
      var targetPlans = DriftCommitmentPlanRepository(target);
      expect(
        await targetPlans.findByCommitmentId(monthly.commitment.id),
        isNull,
      );
      final oldTargetPlans = targetPlans;
      final oldTarget = target;
      final originalTarget = await _logical(target);
      var closes = 0;
      final rebuild = _Rebuild(() async {
        expect(target, isNull, reason: 'Replacement must close the live owner');
        target = AppDatabase(NativeDatabase(targetFile));
        targetPlans = DriftCommitmentPlanRepository(target!);
        expect(identical(targetPlans, oldTargetPlans), false);
        expect(identical(target, oldTarget), false);
        // Compare every persisted logical row before reminder rebuilding.
        expect(await _logical(target!), expected);
        await ReminderService(
          repository: DriftReminderRepository(target!),
          platform: platform,
        ).reconcile(now: _at(1405, 7, 1));
      });
      final storage = SqliteBackupStorage(
        live: targetFile,
        schemaVersion: target!.schemaVersion,
        // Trusted target schema, never declarations from incoming payload.
        expectedSchema: _schema(targetFile),
        snapshot: () => sqliteBackupSnapshot(
          database: target!,
          target: File('${targetFile.path}.snapshot'),
          redact: false,
        ),
        closeLive: () async {
          await target!.close();
          target = null;
          closes++;
        },
      );
      final importer = BackupService(
        storage: storage,
        validator: BackupValidator(currentSchemaVersion: target!.schemaVersion),
        rebuildHook: rebuild,
        keyStorage: keys,
        encryptor: AesGcmBackupEncryptor(),
        nonceGenerator: SecureBackupNonce(),
      );
      final decoded = BackupPackage.decode(await backupFile.readAsString());
      await expectLater(importer.restore(decoded), throwsException);
      await expectLater(
        importer.restore(decoded, recoveryKey: wrongKey.bytes),
        throwsException,
      );
      expect(await _logical(target!), originalTarget);
      expect(closes, 0);
      expect(rebuild.calls, 0);
      final enteredKey = BackupRecoveryKey.parse(keyText);
      try {
        await importer.restore(decoded, recoveryKey: enteredKey.bytes);
      } finally {
        enteredKey.dispose();
      }
      expect(keys.reads, 0);
      expect(closes, 1);
      expect(rebuild.calls, 1);
      expect(await storage.marker.exists(), false);
      storage.validateFile(targetFile);
      storage.validateFile(storage.safety);
      final safety = AppDatabase(NativeDatabase(storage.safety));
      try {
        expect(await _logical(safety), originalTarget);
      } finally {
        await safety.close();
      }
      expect(
        await targetPlans.findByCommitmentId(monthly.commitment.id),
        isNotNull,
      );
      final restoredBeforeRestart = await _logical(target!);
      await target!.close();
      target = AppDatabase(NativeDatabase(targetFile));
      targetPlans = DriftCommitmentPlanRepository(target!);
      expect(await _logical(target!), restoredBeforeRestart);
      final restoredMonthly = (await targetPlans.findByCommitmentId(
        monthly.commitment.id,
      ))!;
      expect(restoredMonthly.schedule.version, 2);
      expect(
        restoredMonthly.schedule.recurrenceRule!.calendar,
        RecurrenceCalendar.jalali,
      );
      expect(restoredMonthly.schedule.recurrenceRule!.dayOfMonth, 19);
      expect(restoredMonthly.schedule.localTime, LocalTime(20, 35));
      expect(restoredMonthly.schedule.generationReminderOffsets, const [
        Duration(minutes: 30),
        Duration(minutes: 60),
      ]);
      expect(
        restoredMonthly.schedule.generationFinancialExpectation!.amount,
        123456,
      );
      final restoredCounted = (await targetPlans.findByCommitmentId(
        counted.commitment.id,
      ))!;
      expect(restoredCounted.schedule.mode, ScheduleMode.fixedCount);
      expect(restoredCounted.schedule.occurrenceCount, 6);
      expect(restoredCounted.schedule.recurrenceRule!.monthOfYear, 12);
      expect(restoredCounted.schedule.recurrenceRule!.dayOfMonth, 30);
      final restoredEnded = (await targetPlans.findByCommitmentId(
        ended.commitment.id,
      ))!;
      expect(restoredEnded.schedule.mode, ScheduleMode.fixedDateRangeRecurring);
      expect(
        restoredEnded.schedule.endDate,
        LocalDate.fromDateTime(_at(1406, 9, 19)),
      );

      final extend = ExtendRecurringSchedules(targetPlans);
      // Advance contiguous bounded windows: rolling is not historical repair.
      expect(await extend(_at(1405, 11, 1)), greaterThan(0));
      expect(await extend(_at(1406, 3, 1)), greaterThan(0));
      expect(await extend(_at(1406, 7, 1)), greaterThan(0));
      expect(await extend(_at(1406, 12, 1)), greaterThan(0));
      expect(await extend(_at(1408, 7, 1)), greaterThan(0));
      expect(await extend(_at(1408, 7, 1)), 0);
      final afterMonthly = (await targetPlans.findByCommitmentId(
        monthly.commitment.id,
      ))!;
      final afterYearly = (await targetPlans.findByCommitmentId(
        yearly.commitment.id,
      ))!;
      final afterCounted = (await targetPlans.findByCommitmentId(
        counted.commitment.id,
      ))!;
      final afterEnded = (await targetPlans.findByCommitmentId(
        ended.commitment.id,
      ))!;
      expect(
        afterMonthly.occurrences.any(
          (o) => o.currentScheduledAt == _at(1408, 7, 19, hour: 20),
        ),
        true,
      );
      expect(
        afterYearly.occurrences.any(
          (o) => o.currentScheduledAt == _at(1408, 7, 19),
        ),
        true,
      );
      expect(
        afterYearly.occurrences.any(
          (o) => o.currentScheduledAt == _at(1409, 7, 19),
        ),
        true,
      );
      expect(
        afterCounted.occurrences.map((o) => o.currentScheduledAt).toSet(),
        {
          _at(1403, 12, 30),
          _at(1404, 12, 29),
          _at(1405, 12, 29),
          _at(1406, 12, 29),
          _at(1407, 12, 29),
          _at(1408, 12, 30),
        },
      );
      expect(afterEnded.occurrences, hasLength(15));
      expect(afterEnded.occurrences.last.currentScheduledAt, _at(1406, 9, 19));
      expect(
        afterMonthly.occurrences
            .singleWhere((o) => o.id == completed.id)
            .status,
        OccurrenceStatus.completed,
      );
      final retainedMoved = afterMonthly.occurrences.singleWhere(
        (o) => o.id == moved.id,
      );
      expect(retainedMoved.currentScheduledAt, moved.currentScheduledAt);
      expect(retainedMoved.isManualOverride, true);
      final after = await _logical(target!);
      for (final table in [
        'schedule_definitions',
        'occurrences',
        'actuals',
        'financial_expectations',
        'reminder_rules',
      ]) {
        for (final old in expected[table]!) {
          expect(
            after[table]!.singleWhere((row) => row['id'] == old['id']),
            old,
            reason: '$table history must not be rewritten by rolling',
          );
        }
      }
      expect(after['schedule_definitions'], expected['schedule_definitions']);
      expect(after['account_entries'], isEmpty);
      final originalIds = expected['occurrences']!
          .map((row) => row['id'])
          .toSet();
      for (final plan in [afterMonthly, afterYearly, afterCounted]) {
        final amount = plan.commitment.id == yearly.commitment.id
            ? 654321
            : plan.commitment.id == counted.commitment.id
            ? 777
            : 123456;
        final offsets = plan.commitment.id == yearly.commitment.id
            ? {-2700}
            : plan.commitment.id == counted.commitment.id
            ? {-900}
            : {-1800, -3600};
        for (final occurrence in plan.occurrences.where(
          (o) => !originalIds.contains(o.id.value),
        )) {
          expect(occurrence.scheduleDefinitionId, plan.schedule.id);
          final rules = after['reminder_rules']!
              .where((r) => r['occurrence_id'] == occurrence.id.value)
              .toList();
          expect(rules.map((r) => r['offset_seconds']).toSet(), offsets);
          expect(rules, hasLength(offsets.length));
          final expectation = after['financial_expectations']!.singleWhere(
            (r) => r['occurrence_id'] == occurrence.id.value,
          );
          expect(expectation['minor_units'], amount);
          expect(
            expectation['direction'],
            plan.commitment.id == yearly.commitment.id ? 1 : 0,
          );
          expect(
            after['reminder_instances']!.where(
              (r) => r['occurrence_id'] == occurrence.id.value,
            ),
            hasLength(offsets.length),
          );
        }
        expect(
          plan.occurrences.map((o) => o.occurrenceKey).toSet(),
          hasLength(plan.occurrences.length),
        );
      }
      expect(platform.scheduled, isNotEmpty);
      await target!.close();
      target = AppDatabase(NativeDatabase(targetFile));
      expect(
        await _logical(target!),
        after,
        reason: 'Extended intent survives another cold restart',
      );
    } finally {
      key.dispose();
      wrongKey.dispose();
      await source?.close();
      await target?.close();
      await root.delete(recursive: true);
    }
  });
}
