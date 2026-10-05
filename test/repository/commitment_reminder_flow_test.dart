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
import 'package:planact/features/sessions/domain/session_policy.dart';

class _Platform implements ReminderPlatformAdapter {
  final scheduled = <ReminderInstance>[];
  bool fail = false;
  bool permissionDenied = false;
  final cancelled = <ReminderInstance>[];

  @override
  Future<void> schedule(ReminderInstance instance) async {
    if (permissionDenied) throw const ReminderPermissionUnavailable();
    if (fail) throw StateError('platform unavailable');
    scheduled.add(instance);
  }

  @override
  Future<void> cancel(ReminderInstance instance) async {
    cancelled.add(instance);
  }
}

void main() {
  late AppDatabase database;
  late DriftReminderRepository reminders;
  late DriftCommitmentRepository commitments;
  late DriftCommitmentPlanRepository plans;
  late _Platform platform;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    reminders = DriftReminderRepository(database);
    commitments = DriftCommitmentRepository(database);
    plans = DriftCommitmentPlanRepository(database);
    platform = _Platform();
  });
  tearDown(() => database.close());

  test('creation persists rules and instances and schedules platform; restart reads back', () async {
    final plan =
        await CreateCommitmentPlan(
          commitments: commitments,
          plans: plans,
          reminderService: ReminderService(
            repository: reminders,
            platform: platform,
          ),
        ).call(
          title: 'یادآوری',
          startAt: DateTime(2030, 1, 1, 18),
          reminderOffsets: [const Duration(minutes: 15)],
        );
    expect(
      (await plans.findByCommitmentId(plan.commitment.id))!.reminders,
      hasLength(1),
    );
    expect(await reminders.listInstances(), hasLength(1));
    expect(platform.scheduled, hasLength(1));
    final restarted = _Platform();
    await ReminderService(
      repository: DriftReminderRepository(database),
      platform: restarted,
    ).reconcile(now: DateTime.utc(2029, 12, 31));
    expect(restarted.scheduled.single.id, platform.scheduled.single.id);
  });

  test(
    'denied permission saves every intent and reports pending delivery',
    () async {
      platform.permissionDenied = true;
      final plan =
          await CreateCommitmentPlan(
            commitments: commitments,
            plans: plans,
            reminderService: ReminderService(
              repository: reminders,
              platform: platform,
            ),
          ).call(
            title: 'یادآوری بدون مجوز',
            startAt: DateTime(2030, 1, 1, 18),
            reminderOffsets: [
              const Duration(minutes: 15),
              const Duration(hours: 1),
            ],
          );
      expect(plan.reminderDeliveryPending, isTrue);
      expect(await commitments.list(), hasLength(1));
      expect(await reminders.listInstances(), hasLength(2));
      platform.permissionDenied = false;
      await ReminderService(
        repository: reminders,
        platform: platform,
      ).reconcile(now: DateTime.utc(2029, 12, 31));
      expect(platform.scheduled, hasLength(2));
    },
  );

  test(
    'disable/re-enable keeps platform and persisted IDs identical',
    () async {
      await CreateCommitmentPlan(
        commitments: commitments,
        plans: plans,
        reminderService: ReminderService(
          repository: reminders,
          platform: platform,
        ),
      ).call(
        title: 'شناسه پایدار',
        startAt: DateTime(2030, 1, 1, 18),
        reminderOffsets: [Duration.zero],
      );
      final rule = (await reminders.listRules()).single;
      final original = (await reminders.listInstances()).single;
      final service = ReminderService(
        repository: reminders,
        platform: platform,
      );
      await service.schedule(
        rule: rule.disable(),
        occurrenceStart: original.scheduledAt,
      );
      final restored = await service.schedule(
        rule: rule.enable(),
        occurrenceStart: original.scheduledAt,
      );
      expect(restored.id, original.id);
      expect(
        (await reminders.listInstances()).single.id,
        platform.scheduled.last.id,
      );
    },
  );

  test(
    'occurrence edit, cancellation and restore synchronize Android intent',
    () async {
      final service = ReminderService(
        repository: reminders,
        platform: platform,
      );
      final plan =
          await CreateCommitmentPlan(
            commitments: commitments,
            plans: plans,
            reminderService: service,
          ).call(
            title: 'جابجایی جلسه',
            startAt: DateTime(2030, 1, 1, 18),
            reminderOffsets: [Duration.zero],
          );
      final executor = PersistedOccurrenceActionExecutor(
        plans: plans,
        reminders: service,
      );
      final original = plan.occurrences.single;
      await executor.reschedule(original, DateTime(2030, 1, 2, 18));
      final edited = (await plans.findByCommitmentId(plan.commitment.id))!
          .occurrences
          .single;
      expect(await reminders.canRemind(edited.id), isTrue);
      expect(
        (await reminders.listInstances())
            .where((item) => item.status == ReminderInstanceStatus.scheduled)
            .single
            .scheduledAt,
        DateTime(2030, 1, 2, 18).toUtc(),
      );
      await executor.cancel(edited, outcome: SessionOutcome.providerCancelled);
      expect(
        (await reminders.listInstances()).every(
          (item) => item.status == ReminderInstanceStatus.cancelled,
        ),
        isTrue,
      );
      final cancelled = (await plans.findByCommitmentId(plan.commitment.id))!
          .occurrences
          .single;
      await executor.restore(cancelled);
      expect(
        (await reminders.listInstances()).where(
          (item) => item.status == ReminderInstanceStatus.scheduled,
        ),
        hasLength(1),
      );
      await executor.complete(edited);
      expect(await reminders.canRemind(edited.id), isFalse);
      expect(
        (await reminders.listInstances()).every(
          (item) => item.status == ReminderInstanceStatus.cancelled,
        ),
        isTrue,
      );
      expect(platform.cancelled, isNotEmpty);
    },
  );

  test('platform failure leaves durable intent to retry on restart', () async {
    platform.fail = true;
    await expectLater(
      CreateCommitmentPlan(
        commitments: commitments,
        plans: plans,
        reminderService: ReminderService(
          repository: reminders,
          platform: platform,
        ),
      ).call(
        title: 'قابل بازیابی',
        startAt: DateTime(2030, 1, 1, 18),
        reminderOffsets: [const Duration(minutes: 15)],
      ),
      throwsStateError,
    );
    expect(await commitments.list(), hasLength(1));
    expect(await reminders.listRules(), hasLength(1));
    expect(await reminders.listInstances(), hasLength(1));
    platform.fail = false;
    await ReminderService(
      repository: reminders,
      platform: platform,
    ).reconcile(now: DateTime.utc(2029, 12, 31));
    expect(platform.scheduled, hasLength(1));
  });

  test(
    'transaction rolls back commitment when plan persistence fails',
    () async {
      final planRepository = DriftCommitmentPlanRepository(database);
      await expectLater(
        planRepository.runTransaction(() async {
          await commitments.save(
            (await CreateCommitmentPlan(
                  commitments: commitments,
                  plans: plans,
                ).call(title: 'temporary', startAt: DateTime(2030, 1, 1)))
                .commitment,
          );
          throw StateError('injected failure');
        }),
        throwsStateError,
      );
      expect(await commitments.list(), isEmpty);
    },
  );
}
