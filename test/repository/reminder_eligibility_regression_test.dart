import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/features/actuals/data/drift_actual_repository.dart';
import 'package:planact/features/actuals/domain/actual.dart';
import 'package:planact/features/commitments/application/commitment_plan_use_case.dart';
import 'package:planact/features/commitments/application/commitment_use_cases.dart';
import 'package:planact/features/commitments/data/drift_commitment_plan_repository.dart';
import 'package:planact/features/commitments/data/drift_commitment_repository.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/commitments/domain/commitment_cycle.dart';
import 'package:planact/features/reminders/application/reminder_service.dart';
import 'package:planact/features/reminders/data/drift_reminder_repository.dart';
import 'package:planact/features/reminders/domain/reminder.dart';
import 'package:planact/features/scheduling/application/edit_commitment_schedule.dart';
import 'package:planact/features/scheduling/application/series_editing.dart';

class _Platform implements ReminderPlatformAdapter {
  final active = <String, ReminderInstance>{};
  @override
  Future<void> schedule(ReminderInstance instance) async {
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
  late DriftCommitmentRepository commitments;
  late CommitmentPlan plan;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('reminder-eligibility-');
    file = File('${directory.path}/state.sqlite');
    database = AppDatabase.forTesting(NativeDatabase(file));
    platform = _Platform();
    repository = DriftReminderRepository(database);
    service = ReminderService(repository: repository, platform: platform);
    plans = DriftCommitmentPlanRepository(database);
    commitments = DriftCommitmentRepository(database);
    plan =
        await CreateCommitmentPlan(
          commitments: commitments,
          plans: plans,
          reminderService: service,
        )(
          title: 'synthetic history',
          startAt: DateTime(2030, 1, 1, 18),
          reminderOffsets: [Duration.zero, const Duration(minutes: 15)],
        );
  });
  tearDown(() async {
    await database.close();
    await directory.delete(recursive: true);
  });

  for (final status in [CommitmentStatus.archived, CommitmentStatus.paused]) {
    test(
      'editing ${status.name} history never schedules notifications and restores the edited time after restart',
      () async {
        if (status == CommitmentStatus.archived) {
          await ArchiveCommitment(commitments)(plan.commitment.id);
        } else {
          await PauseCommitment(commitments)(plan.commitment.id);
        }
        await service.reconcile(now: DateTime(2029));
        expect(platform.active, isEmpty);
        final rowsBefore = await repository.listInstances();
        expect(
          await EditCommitmentSchedule(plans, reminders: service)(
            commitmentId: plan.commitment.id,
            expected: plan.occurrences.single,
            scheduledAt: DateTime(2030, 1, 2, 18),
            scope: SeriesEditScope.onlyThis,
            now: DateTime(2029),
          ),
          false,
        );
        expect(await repository.canRemind(plan.occurrences.single.id), false);
        expect(platform.active, isEmpty);
        expect(
          (await repository.listInstances()).where(
            (r) => r.status == ReminderInstanceStatus.scheduled,
          ),
          isEmpty,
        );
        expect((await repository.listInstances()).length, rowsBefore.length);
        await database.close();
        database = AppDatabase.forTesting(NativeDatabase(file));
        repository = DriftReminderRepository(database);
        service = ReminderService(repository: repository, platform: platform);
        commitments = DriftCommitmentRepository(database);
        plans = DriftCommitmentPlanRepository(database);
        await service.reconcile(now: DateTime(2029));
        expect(platform.active, isEmpty);
        if (status == CommitmentStatus.archived) {
          await RestoreCommitment(commitments)(plan.commitment.id);
        } else {
          await ResumeCommitment(commitments)(plan.commitment.id);
        }
        await service.reconcile(now: DateTime(2029));
        expect(platform.active.length, 2);
        expect(platform.active.values.map((r) => r.scheduledAt).toSet(), {
          DateTime(2030, 1, 2, 18).toUtc(),
          DateTime(2030, 1, 2, 17, 45).toUtc(),
        });
        expect(
          (await plans.findByCommitmentId(plan.commitment.id))!
              .occurrences
              .single
              .id,
          plan.occurrences.single.id,
        );
      },
    );
  }

  test('reopening while archived keeps recovery intent until the owner is restored', () async {
    final actuals = DriftActualRepository(database);
    final completed = await actuals.recordOccurrenceActual(
      expected: plan.occurrences.single,
      outcome: ActualOutcome.completed,
      recordedAt: DateTime(2029),
    );
    await service.synchronizeOccurrence(
      occurrenceId: completed.id,
      occurrenceStart: completed.currentScheduledAt as DateTime,
      resolved: true,
    );
    await ArchiveCommitment(commitments)(plan.commitment.id);
    final reopened = await actuals.recordOccurrenceActual(
      expected: completed,
      outcome: ActualOutcome.reopened,
      recordedAt: DateTime(2029),
    );
    await service.synchronizeOccurrence(
      occurrenceId: reopened.id,
      occurrenceStart: reopened.currentScheduledAt as DateTime,
      resolved: false,
    );
    expect(platform.active, isEmpty);
    expect(await repository.hasPendingReopening(reopened.id), true);
    await RestoreCommitment(commitments)(plan.commitment.id);
    await service.reconcile(now: DateTime(2029));
    expect(platform.active.length, 2);
    expect(await repository.hasPendingReopening(reopened.id), false);
  });

  for (final status in CommitmentCycleStatus.values.where(
    (s) => s != CommitmentCycleStatus.active,
  )) {
    test(
      'direct scheduling reads fresh ${status.name} cycle eligibility',
      () async {
        await database.customStatement(
          'UPDATE commitment_cycles SET status = ? WHERE id = ?',
          [status.index, plan.cycle.id.value],
        );
        await service.reconcile(now: DateTime(2029));
        final result = await service.schedule(
          rule: plan.reminders.first,
          occurrenceStart: DateTime(2030, 1, 1, 18),
        );
        expect(result.status, ReminderInstanceStatus.cancelled);
        expect(platform.active, isEmpty);
        expect(
          (await repository.listInstances()).where(
            (r) => r.status == ReminderInstanceStatus.scheduled,
          ),
          isEmpty,
        );
      },
    );
  }

  for (final outcome in [
    ActualOutcome.completed,
    ActualOutcome.cancelled,
    ActualOutcome.noShow,
  ]) {
    test(
      'direct scheduling cannot reactivate a ${outcome.name} occurrence',
      () async {
        await DriftActualRepository(database).recordOccurrenceActual(
          expected: plan.occurrences.single,
          outcome: outcome,
          recordedAt: DateTime(2029),
        );
        await service.reconcile(now: DateTime(2029));
        final result = await service.schedule(
          rule: plan.reminders.first,
          occurrenceStart: DateTime(2030, 1, 1, 18),
        );
        expect(result.status, ReminderInstanceStatus.cancelled);
        expect(platform.active, isEmpty);
      },
    );
  }
}
