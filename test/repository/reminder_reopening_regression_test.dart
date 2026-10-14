import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/features/actuals/data/drift_actual_repository.dart';
import 'package:planact/features/actuals/domain/actual.dart';
import 'package:planact/features/commitments/application/commitment_plan_use_case.dart';
import 'package:planact/features/commitments/data/drift_commitment_plan_repository.dart';
import 'package:planact/features/commitments/data/drift_commitment_repository.dart';
import 'package:planact/features/reminders/application/reminder_service.dart';
import 'package:planact/features/reminders/data/drift_reminder_repository.dart';
import 'package:planact/features/reminders/domain/reminder.dart';
import 'package:planact/features/scheduling/application/edit_commitment_schedule.dart';
import 'package:planact/features/scheduling/application/occurrence_actions.dart';
import 'package:planact/features/scheduling/application/schedule_undo.dart';
import 'package:planact/features/scheduling/application/series_editing.dart';

class _Platform implements ReminderPlatformAdapter {
  final active = <String, ReminderInstance>{};
  bool fail = false;
  @override
  Future<void> schedule(ReminderInstance instance) async {
    if (fail) throw StateError('synthetic delivery failure');
    active[instance.id.value] = instance;
  }

  @override
  Future<void> cancel(ReminderInstance instance) async {
    active.remove(instance.id.value);
  }
}

void main() {
  late Directory directory;
  late File file;
  late AppDatabase database;
  late _Platform platform;
  late DriftReminderRepository repository;
  late ReminderService service;
  late DriftCommitmentPlanRepository plans;
  late CommitmentPlan plan;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('reopening-regression-');
    file = File('${directory.path}/state.sqlite');
    database = AppDatabase.forTesting(NativeDatabase(file));
    platform = _Platform();
    repository = DriftReminderRepository(database);
    service = ReminderService(repository: repository, platform: platform);
    plans = DriftCommitmentPlanRepository(database);
    plan =
        await CreateCommitmentPlan(
          commitments: DriftCommitmentRepository(database),
          plans: plans,
          reminderService: service,
        )(
          title: 'synthetic reopening',
          startAt: DateTime(2030, 1, 1, 18),
          reminderOffsets: [
            Duration.zero,
            const Duration(minutes: 15),
            const Duration(hours: 1),
          ],
        );
  });
  tearDown(() async {
    await database.close();
    await directory.delete(recursive: true);
  });

  Future<void> reopenDatabase() async {
    await database.close();
    database = AppDatabase.forTesting(NativeDatabase(file));
    repository = DriftReminderRepository(database);
    service = ReminderService(repository: repository, platform: platform);
    plans = DriftCommitmentPlanRepository(database);
  }

  Future<void> complete() => PersistedOccurrenceActionExecutor(
    plans: plans,
    actuals: DriftActualRepository(database),
    reminders: service,
  ).complete(plan.occurrences.single);

  Future<void> restore() async {
    final completed = (await plans.findByCommitmentId(plan.commitment.id))!
        .occurrences
        .single;
    await PersistedOccurrenceActionExecutor(
      plans: plans,
      actuals: DriftActualRepository(database),
      reminders: service,
    ).restore(completed);
  }

  test('successful reopening consumes recovery intent before later cancellation, snooze and delivery survive restart', () async {
    await complete();
    await restore();
    expect(
      await repository.hasPendingReopening(plan.occurrences.single.id),
      false,
    );
    final instances = await repository.listInstances();
    await service.cancel(instances[0]);
    final snoozed = await service.snooze(
      instances[1],
      DateTime.utc(2030, 1, 2),
    );
    await repository.saveInstance(instances[2].deliver());
    await platform.cancel(instances[2]);
    await reopenDatabase();
    await service.reconcile(now: DateTime(2029));
    expect(platform.active.keys, [snoozed.id.value]);
    final rows = await repository.listInstances();
    expect(
      rows.firstWhere((r) => r.id == instances[0].id).status,
      ReminderInstanceStatus.cancelled,
    );
    expect(
      rows.firstWhere((r) => r.id == instances[1].id).snoozedUntil,
      DateTime.utc(2030, 1, 2),
    );
    expect(
      rows.firstWhere((r) => r.id == instances[2].id).status,
      ReminderInstanceStatus.delivered,
    );
  });

  test('multi-rule intent failure rolls back all rules and keeps interrupted reopening recoverable', () async {
    await complete();
    final rule = plan.reminders[1];
    await database.customStatement(
      "CREATE TRIGGER fail_second_rule BEFORE UPDATE ON reminder_instances WHEN NEW.rule_id = '${rule.id.value}' AND NEW.status = 0 BEGIN SELECT RAISE(ABORT, 'synthetic failure'); END",
    );
    await expectLater(
      restore(),
      throwsA(isA<OccurrenceReminderDeliveryPending>()),
    );
    expect(
      await repository.hasPendingReopening(plan.occurrences.single.id),
      true,
    );
    expect(
      (await repository.listInstances()).every(
        (r) => r.status == ReminderInstanceStatus.cancelled,
      ),
      true,
    );
    expect(platform.active, isEmpty);
    expect(
      (await DriftActualRepository(database).list()).last.outcome,
      ActualOutcome.reopened,
    );
    await database.customStatement('DROP TRIGGER fail_second_rule');
    await reopenDatabase();
    await service.reconcile(now: DateTime(2029));
    expect(platform.active.length, 3);
    expect(
      await repository.hasPendingReopening(plan.occurrences.single.id),
      false,
    );
  });

  test('delivery failure leaves complete committed intent; later cancellation stays cancelled on retry', () async {
    await complete();
    platform.fail = true;
    await expectLater(
      restore(),
      throwsA(isA<OccurrenceReminderDeliveryPending>()),
    );
    expect(
      (await repository.listInstances()).where(
        (r) => r.status == ReminderInstanceStatus.scheduled,
      ),
      hasLength(3),
    );
    expect(
      await repository.hasPendingReopening(plan.occurrences.single.id),
      false,
    );
    final cancelled = (await repository.listInstances()).first;
    await service.cancel(cancelled);
    await reopenDatabase();
    platform.fail = false;
    await service.reconcile(now: DateTime(2029));
    expect(platform.active.length, 2);
    expect(platform.active.containsKey(cancelled.id.value), false);
  });

  test('schedule Undo consumes recovery intent and preserves a subsequent explicit cancellation', () async {
    await EditCommitmentSchedule(plans, reminders: service)(
      commitmentId: plan.commitment.id,
      expected: plan.occurrences.single,
      scheduledAt: DateTime(2030, 1, 2, 18),
      scope: SeriesEditScope.onlyThis,
      now: DateTime(2029),
    );
    final token = (await plans.scheduleUndo(plan.commitment.id))!;
    expect(
      await UndoScheduleChange(plans, reminders: service)(
        plan.commitment.id,
        token,
        DateTime(2029),
      ),
      false,
    );
    expect(
      await repository.hasPendingReopening(plan.occurrences.single.id),
      false,
    );
    final active = (await repository.listInstances()).firstWhere(
      (r) => r.status == ReminderInstanceStatus.scheduled,
    );
    await service.cancel(active);
    await reopenDatabase();
    await service.reconcile(now: DateTime(2029));
    expect(platform.active.length, 2);
    expect(platform.active.containsKey(active.id.value), false);
  });
}
