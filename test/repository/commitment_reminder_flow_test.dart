import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/features/commitments/application/commitment_plan_use_case.dart';
import 'package:planact/features/commitments/data/drift_commitment_plan_repository.dart';
import 'package:planact/features/commitments/data/drift_commitment_repository.dart';
import 'package:planact/features/reminders/application/reminder_service.dart';
import 'package:planact/features/reminders/data/drift_reminder_repository.dart';
import 'package:planact/features/reminders/domain/reminder.dart';

class _Platform implements ReminderPlatformAdapter {
  final scheduled = <ReminderInstance>[];
  bool fail = false;

  @override
  Future<void> schedule(ReminderInstance instance) async {
    if (fail) throw StateError('platform unavailable');
    scheduled.add(instance);
  }

  @override
  Future<void> cancel(ReminderInstance instance) async {}
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
