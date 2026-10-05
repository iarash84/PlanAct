import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/features/commitments/application/commitment_plan_use_case.dart';
import 'package:planact/features/commitments/data/drift_commitment_plan_repository.dart';
import 'package:planact/features/commitments/data/drift_commitment_repository.dart';
import 'package:planact/features/reminders/application/reminder_service.dart';
import 'package:planact/features/reminders/data/drift_reminder_repository.dart';
import 'package:planact/features/reminders/domain/reminder.dart';
import 'package:planact/features/scheduling/application/occurrence_actions.dart';
import 'package:planact/features/scheduling/domain/occurrence.dart';

class _Platform implements ReminderPlatformAdapter {
  final active = <String, ReminderInstance>{};
  bool fail = false;
  bool failCancel = false;
  @override
  Future<void> schedule(ReminderInstance instance) async {
    if (fail) throw StateError('injected platform failure');
    active[instance.id.value] = instance;
  }

  @override
  Future<void> cancel(ReminderInstance instance) async {
    if (failCancel) throw StateError('injected cancellation failure');
    active.remove(instance.id.value);
  }
}

void main() {
  test(
    'replacement intent commits before cancellation failure; restart retries',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'cancel-recovery-',
      );
      final file = File('${directory.path}/state.sqlite');
      var database = AppDatabase.forTesting(NativeDatabase(file));
      addTearDown(() async {
        await database.close();
        await directory.delete(recursive: true);
      });
      final platform = _Platform();
      final repository = DriftReminderRepository(database);
      final service = ReminderService(
        repository: repository,
        platform: platform,
      );
      final plans = DriftCommitmentPlanRepository(database);
      final plan =
          await CreateCommitmentPlan(
            commitments: DriftCommitmentRepository(database),
            plans: plans,
            reminderService: service,
          ).call(
            title: 'قطع لغو اعلان',
            startAt: DateTime(2030, 1, 1, 18),
            reminderOffsets: [Duration.zero],
          );
      platform.failCancel = true;
      final executor = PersistedOccurrenceActionExecutor(
        plans: plans,
        reminders: service,
      );
      await expectLater(
        executor.reschedule(plan.occurrences.single, DateTime(2030, 1, 2, 18)),
        throwsA(isA<OccurrenceReminderDeliveryPending>()),
      );
      final instances = await repository.listInstances();
      expect(
        instances.where(
          (item) => item.status == ReminderInstanceStatus.scheduled,
        ),
        hasLength(1),
      );
      expect(
        instances.where(
          (item) => item.status == ReminderInstanceStatus.cancelled,
        ),
        hasLength(1),
      );
      await database.close();
      database = AppDatabase.forTesting(NativeDatabase(file));
      platform.failCancel = false;
      final recovered = ReminderService(
        repository: DriftReminderRepository(database),
        platform: platform,
      );
      await recovered.reconcile(now: DateTime.utc(2029, 12, 31));
      expect(
        platform.active.values.single.scheduledAt,
        DateTime(2030, 1, 2, 18).toUtc(),
      );
      final current = (await DriftCommitmentPlanRepository(
        database,
      ).findByCommitmentId(plan.commitment.id))!.occurrences.single;
      platform.failCancel = true;
      await expectLater(
        PersistedOccurrenceActionExecutor(
          plans: DriftCommitmentPlanRepository(database),
          reminders: recovered,
        ).complete(current),
        throwsA(isA<OccurrenceReminderDeliveryPending>()),
      );
      expect(
        (await DriftCommitmentPlanRepository(database)
                .findByCommitmentId(plan.commitment.id))!
            .occurrences
            .single
            .status,
        OccurrenceStatus.completed,
      );
      platform.failCancel = false;
      await recovered.reconcile(now: DateTime.utc(2029, 12, 31));
      expect(platform.active, isEmpty);
    },
  );

  test(
    'recovery preserves snooze, delivered history and explicit cancellation',
    () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      final repository = DriftReminderRepository(database);
      final platform = _Platform();
      final service = ReminderService(
        repository: repository,
        platform: platform,
      );
      final plan =
          await CreateCommitmentPlan(
            commitments: DriftCommitmentRepository(database),
            plans: DriftCommitmentPlanRepository(database),
            reminderService: service,
          ).call(
            title: 'حفظ سابقه یادآوری',
            startAt: DateTime(2030, 1, 1, 18),
            reminderOffsets: [
              Duration.zero,
              const Duration(minutes: 15),
              const Duration(hours: 1),
            ],
          );
      final instances = await repository.listInstances();
      final snoozed = await service.snooze(
        instances[0],
        DateTime.utc(2030, 1, 3),
      );
      await repository.saveInstance(instances[1].deliver());
      await service.cancel(instances[2]);
      await service.reconcile(now: DateTime.utc(2029, 12, 31));
      final restored = await repository.listInstances();
      expect(restored, hasLength(3));
      expect(
        restored.singleWhere((item) => item.id == snoozed.id).snoozedUntil,
        snoozed.snoozedUntil,
      );
      expect(
        restored.singleWhere((item) => item.id == instances[1].id).status,
        ReminderInstanceStatus.delivered,
      );
      expect(
        restored.singleWhere((item) => item.id == instances[2].id).status,
        ReminderInstanceStatus.cancelled,
      );
      expect(platform.active.keys, [snoozed.id.value]);
      expect(plan.reminderDeliveryPending, isFalse);
    },
  );

  for (final interruptedEdit in [false, true]) {
    test(
      'reopen repairs ${interruptedEdit ? 'stale' : 'missing'} intent idempotently',
      () async {
        final directory = await Directory.systemTemp.createTemp(
          'reminder-recovery-',
        );
        final file = File('${directory.path}/state.sqlite');
        var database = AppDatabase.forTesting(NativeDatabase(file));
        addTearDown(() async {
          await database.close();
          await directory.delete(recursive: true);
        });
        final platform = _Platform();
        final plans = DriftCommitmentPlanRepository(database);
        final plan =
            await CreateCommitmentPlan(
              commitments: DriftCommitmentRepository(database),
              plans: plans,
            ).call(
              title: 'بازیابی پس از قطع عملیات',
              startAt: DateTime(2030, 1, 1, 18),
              reminderOffsets: [Duration.zero, const Duration(minutes: 15)],
            );
        final original = plan.occurrences.single;
        if (interruptedEdit) {
          final service = ReminderService(
            repository: DriftReminderRepository(database),
            platform: platform,
          );
          for (final rule in plan.reminders) {
            await service.schedule(
              rule: rule,
              occurrenceStart: original.currentScheduledAt as DateTime,
            );
          }
          // Simulate process death after the occurrence commit, before platform sync.
          await plans.saveOccurrence(
            original.reschedule(DateTime(2030, 1, 2, 18)),
          );
        }
        await database.close();
        database = AppDatabase.forTesting(NativeDatabase(file));
        final repository = DriftReminderRepository(database);
        final service = ReminderService(
          repository: repository,
          platform: platform,
        );
        await service.reconcile(now: DateTime.utc(2029, 12, 31));
        expect(platform.active, hasLength(2));
        final expected = interruptedEdit
            ? DateTime(2030, 1, 2, 18)
            : DateTime(2030, 1, 1, 18);
        expect(
          platform.active.values.map((item) => item.scheduledAt),
          contains(expected.toUtc()),
        );
        final ids = platform.active.keys.toSet();
        final rows = (await repository.listInstances()).length;
        await service.reconcile(now: DateTime.utc(2029, 12, 31));
        expect(platform.active.keys.toSet(), ids);
        expect(await repository.listInstances(), hasLength(rows));
        expect(await DriftCommitmentRepository(database).list(), hasLength(1));
      },
    );
  }

  test(
    'platform failure reports committed creation with all intents recoverable',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'creation-recovery-',
      );
      final file = File('${directory.path}/state.sqlite');
      var database = AppDatabase.forTesting(NativeDatabase(file));
      addTearDown(() async {
        await database.close();
        await directory.delete(recursive: true);
      });
      final platform = _Platform()..fail = true;
      final plan =
          await CreateCommitmentPlan(
            commitments: DriftCommitmentRepository(database),
            plans: DriftCommitmentPlanRepository(database),
            reminderService: ReminderService(
              repository: DriftReminderRepository(database),
              platform: platform,
            ),
          ).call(
            title: 'ثبت موفق با اعلان معوق',
            startAt: DateTime(2030, 1, 1, 18),
            reminderOffsets: [Duration.zero, const Duration(hours: 1)],
          );
      expect(plan.reminderDeliveryPending, isTrue);
      expect(
        await DriftReminderRepository(database).listInstances(),
        hasLength(2),
      );
      await database.close();
      database = AppDatabase.forTesting(NativeDatabase(file));
      platform.fail = false;
      await ReminderService(
        repository: DriftReminderRepository(database),
        platform: platform,
      ).reconcile(now: DateTime.utc(2029, 12, 31));
      expect(platform.active, hasLength(2));
      expect(await DriftCommitmentRepository(database).list(), hasLength(1));
    },
  );
}
