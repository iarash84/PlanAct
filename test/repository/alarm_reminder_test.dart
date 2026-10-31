import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/features/backup/data/sqlite_backup_snapshot.dart';
import 'package:planact/features/commitments/application/commitment_plan_use_case.dart';
import 'package:planact/features/commitments/data/drift_commitment_plan_repository.dart';
import 'package:planact/features/commitments/data/drift_commitment_repository.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/reminders/application/reminder_service.dart';
import 'package:planact/features/reminders/data/drift_reminder_repository.dart';
import 'package:planact/features/reminders/domain/reminder.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';

class _Platform implements ReminderPlatformAdapter {
  final scheduled = <ReminderInstance>[];
  final cancelled = <ReminderInstance>[];
  bool denied = false;
  @override
  Future<void> schedule(ReminderInstance instance) async {
    if (denied) throw const ReminderPermissionUnavailable();
    scheduled.add(instance);
  }

  @override
  Future<void> cancel(ReminderInstance instance) async =>
      cancelled.add(instance);
}

class _StaleListing extends DriftReminderRepository {
  _StaleListing(super.database, this.snapshot);
  final ReminderInstance snapshot;
  @override
  Future<List<ReminderInstance>> listInstances() async => [snapshot];
}

void main() {
  // Cold-reopen and restore coverage intentionally creates multiple
  // file-backed database owners in this test process.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late Directory directory;
  late File live;
  late AppDatabase db;
  late DriftReminderRepository reminders;
  late DriftCommitmentPlanRepository plans;
  late _Platform platform;
  late ReminderService service;

  void bind() {
    reminders = DriftReminderRepository(db);
    plans = DriftCommitmentPlanRepository(db);
    service = ReminderService(repository: reminders, platform: platform);
  }

  Future<CommitmentPlan> create({bool recurring = false}) =>
      CreateCommitmentPlan(
        commitments: DriftCommitmentRepository(db),
        plans: plans,
        reminderService: service,
      )(
        title: 'alarm fixture',
        startAt: DateTime(2030, 1, 1, 18),
        kind: recurring ? CommitmentKind.recurring : CommitmentKind.oneOff,
        frequency: RecurrenceFrequency.daily,
        reminderDelivery: ReminderDelivery.alarm,
        reminderOffsets: [const Duration(minutes: 15)],
      );

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('planact-alarm-');
    live = File('${directory.path}/planact.sqlite');
    db = AppDatabase(NativeDatabase(live));
    platform = _Platform();
    bind();
  });
  tearDown(() async {
    await db.close();
    await directory.delete(recursive: true);
  });

  test(
    'alarm intent, cold reopen, and portable snapshot preserve method and snooze',
    () async {
      platform.denied = true;
      final plan = await create(recurring: true);
      expect(plan.reminderDeliveryPending, isTrue);
      final instance = (await reminders.listInstances()).first;
      platform.denied = false;
      await service.snooze(instance, DateTime(2030, 1, 1, 17, 55));
      await db.close();
      db = AppDatabase(NativeDatabase(live));
      bind();
      expect(
        (await reminders.listRules()).every(
          (r) => r.delivery == ReminderDelivery.alarm,
        ),
        isTrue,
      );
      final reopened = await reminders.findInstance(instance.id);
      expect(reopened!.delivery, ReminderDelivery.alarm);
      expect(reopened.status, ReminderInstanceStatus.snoozed);
      expect(reopened.snoozedUntil, DateTime(2030, 1, 1, 17, 55).toUtc());
      final loaded = (await plans.findByCommitmentId(plan.commitment.id))!;
      expect(
        loaded.schedule.generationReminderDelivery,
        ReminderDelivery.alarm,
      );
      expect(
        loaded.schedule
            .nextVersion(effectiveFrom: LocalDate(2030, 1, 2))
            .generationReminderDelivery,
        ReminderDelivery.alarm,
      );

      final bytes = await sqliteBackupSnapshot(
        database: db,
        target: File('${directory.path}/snapshot'),
        redact: true,
      );
      final restored = File('${directory.path}/restored.sqlite');
      await restored.writeAsBytes(bytes);
      final restoredDb = AppDatabase(NativeDatabase(restored));
      try {
        final restoredReminders = DriftReminderRepository(restoredDb);
        expect(
          (await restoredReminders.findInstance(instance.id))!.snoozedUntil,
          reopened.snoozedUntil,
        );
        expect(
          (await restoredReminders.listRules()).first.delivery,
          ReminderDelivery.alarm,
        );
        expect(
          (await DriftCommitmentPlanRepository(restoredDb)
                  .findByCommitmentId(plan.commitment.id))!
              .schedule
              .generationReminderDelivery,
          ReminderDelivery.alarm,
        );
      } finally {
        await restoredDb.close();
      }
    },
    // VACUUM INTO copies the complete SQLite database and can be slower when
    // the full widget suite is running concurrently on Windows.
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test('legacy absence of delivery metadata is notification; unknown data is rejected', () async {
    await create();
    await db.customStatement(
      "DELETE FROM schema_metadata WHERE key LIKE 'reminder_delivery_v1:%'",
    );
    expect(
      (await reminders.listRules()).single.delivery,
      ReminderDelivery.notification,
    );
    expect(
      (await reminders.listInstances()).single.delivery,
      ReminderDelivery.notification,
    );
    final id = (await reminders.listRules()).single.id;
    await db.writeMetadata(
      'reminder_delivery_v1:rule:${id.value}',
      'unsupported',
    );
    await expectLater(reminders.listRules(), throwsArgumentError);
  });

  test('changing delivery replaces rule, cancels old alarm, and preserves its history', () async {
    final plan = await create();
    final old = (await reminders.listRules()).single;
    final replacement = ReminderRule.beforeOccurrence(
      occurrenceId: old.occurrenceId,
      offset: old.offset,
      delivery: ReminderDelivery.notification,
    );
    expect(
      await service.editOccurrenceRules(
        occurrenceId: old.occurrenceId,
        expected: [old],
        selected: [replacement],
        now: DateTime(2029),
      ),
      isFalse,
    );
    final rules = await reminders.listRules();
    expect(rules.singleWhere((r) => r.id == old.id).enabled, isFalse);
    final instances = await reminders.listInstances();
    expect(
      instances.singleWhere((i) => i.ruleId == old.id).status,
      ReminderInstanceStatus.cancelled,
    );
    expect(
      instances.singleWhere((i) => i.ruleId == old.id).delivery,
      ReminderDelivery.alarm,
    );
    expect(platform.scheduled.last.delivery, ReminderDelivery.notification);
    expect(
      (await plans.findByCommitmentId(plan.commitment.id))!
          .occurrences
          .single
          .status
          .name,
      'scheduled',
    );
  });

  test('native snooze committed during reconciliation is reread under writer admission', () async {
    await create();
    final instance = (await reminders.listInstances()).single;
    final until = DateTime(2030, 1, 1, 18, 10).toUtc();
    // The native command uses these same v19 epoch-second columns.
    await db.customStatement(
      'UPDATE reminder_instances SET status=3, snoozed_until=? WHERE id=?',
      [until.millisecondsSinceEpoch ~/ 1000, instance.id.value],
    );
    // Simulate the listing captured before the native transaction committed.
    await ReminderService(
      repository: _StaleListing(db, instance),
      platform: platform,
    ).reconcile(now: DateTime(2030, 1, 1, 18));
    expect(
      (await reminders.findInstance(instance.id))!.status,
      ReminderInstanceStatus.snoozed,
    );
    expect(platform.scheduled.last.snoozedUntil, until);
  });

  test('resolving a ringing alarm stops playback without changing delivered history', () async {
    final plan = await create();
    final instance = (await reminders.listInstances()).single;
    await reminders.saveInstance(instance.deliver());
    await service.synchronizeOccurrence(
      occurrenceId: plan.occurrences.single.id,
      occurrenceStart: null,
      resolved: true,
    );
    expect(platform.cancelled.last.id, instance.id);
    expect(
      (await reminders.findInstance(instance.id))!.status,
      ReminderInstanceStatus.delivered,
    );
  });

  test('rescheduling a delivered alarm stops its old playback and preserves history', () async {
    final plan = await create();
    final instance = (await reminders.listInstances()).single;
    await reminders.saveInstance(instance.deliver());
    final moved = plan.occurrences.single.reschedule(DateTime(2030, 1, 2, 18));
    await plans.saveOccurrence(moved);
    await service.synchronizeOccurrence(
      occurrenceId: moved.id,
      occurrenceStart: moved.currentScheduledAt as DateTime,
      resolved: false,
    );
    expect(platform.cancelled.any((i) => i.id == instance.id), isTrue);
    expect(
      (await reminders.findInstance(instance.id))!.status,
      ReminderInstanceStatus.delivered,
    );
    expect(platform.scheduled.last.delivery, ReminderDelivery.alarm);
    expect(
      platform.scheduled.last.scheduledAt,
      DateTime(2030, 1, 2, 17, 45).toUtc(),
    );
  });

  test('newly materialized and explicitly prepared future slots inherit alarm method', () async {
    final plan = await create(recurring: true);
    await plans.extendRecurringSchedules(LocalDate(2030, 5, 1));
    final loaded = (await plans.findByCommitmentId(plan.commitment.id))!;
    expect(
      loaded.occurrences.any(
        (o) => (o.currentScheduledAt as DateTime).month >= 5,
      ),
      isTrue,
    );
    expect(
      (await reminders.listRules()).every(
        (r) => r.delivery == ReminderDelivery.alarm,
      ),
      isTrue,
    );
    // Far beyond the operational horizon: reading does not create reminder intent.
    final before = (await reminders.listInstances()).length;
    final range = await plans.loadPlannedRange(
      LocalDate(2032, 1, 1),
      LocalDate(2032, 1, 2),
      LocalDate(2030, 1, 1),
    );
    final slots = range.preview[plan.commitment.id.value]!;
    expect(slots, hasLength(1));
    expect((await reminders.listInstances()).length, before);
    final prepared = await plans.preparePlannedOccurrence(
      slots.single,
      LocalDate(2030, 1, 1),
    );
    expect(
      (await reminders.listRules())
          .singleWhere((r) => r.occurrenceId == prepared.id)
          .delivery,
      ReminderDelivery.alarm,
    );
  });
}
