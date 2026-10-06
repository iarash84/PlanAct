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

class _Platform implements ReminderPlatformAdapter {
  bool fail = false;
  @override
  Future<void> cancel(ReminderInstance instance) async {
    if (fail) throw StateError('offline platform');
  }

  @override
  Future<void> schedule(ReminderInstance instance) async {
    if (fail) throw const ReminderPermissionUnavailable();
  }
}

void main() {
  test('edits persist across cold restart despite platform failure; stale edits rejected', () async {
    final directory = await Directory.systemTemp.createTemp(
      'planact-reminder-edit',
    );
    final file = File('${directory.path}/state.sqlite');
    var database = AppDatabase.forTesting(NativeDatabase(file));
    try {
      var repository = DriftReminderRepository(database);
      final platform = _Platform();
      var service = ReminderService(repository: repository, platform: platform);
      final plan =
          await CreateCommitmentPlan(
            commitments: DriftCommitmentRepository(database),
            plans: DriftCommitmentPlanRepository(database),
            reminderService: service,
          )(
            title: 'کلاس',
            startAt: DateTime(2030, 1, 1, 18),
            reminderOffsets: [
              const Duration(minutes: 15),
              const Duration(hours: 1),
            ],
          );
      final current = await repository.listRules();
      final instances = await repository.listInstances();
      await repository.saveInstance(instances.first.deliver());
      final snoozed = instances.last.snoozeUntil(
        DateTime.utc(2030, 1, 1, 17, 30),
      );
      await repository.saveInstance(snoozed);
      final added = ReminderRule.beforeOccurrence(
        occurrenceId: plan.occurrences.single.id,
        offset: const Duration(minutes: 30),
      );
      platform.fail = true;
      expect(
        await service.editOccurrenceRules(
          occurrenceId: plan.occurrences.single.id,
          expected: current,
          selected: [current.last, added],
          now: DateTime(2029),
        ),
        isTrue,
      );
      await database.close();
      database = AppDatabase.forTesting(NativeDatabase(file));
      repository = DriftReminderRepository(database);
      service = ReminderService(repository: repository, platform: _Platform());
      final rules = await repository.listRules();
      expect(
        rules.where((rule) => rule.enabled).map((rule) => rule.id),
        unorderedEquals([current.last.id, added.id]),
      );
      final restored = await repository.listInstances();
      expect(
        restored.singleWhere((item) => item.id == instances.first.id).status,
        ReminderInstanceStatus.delivered,
      );
      expect(
        restored.singleWhere((item) => item.id == snoozed.id).snoozedUntil,
        snoozed.snoozedUntil,
      );
      await expectLater(
        service.editOccurrenceRules(
          occurrenceId: plan.occurrences.single.id,
          expected: current,
          selected: [],
          now: DateTime(2029),
        ),
        throwsStateError,
      );
      await service.reconcile(now: DateTime(2029));
      expect(
        await service.editOccurrenceRules(
          occurrenceId: plan.occurrences.single.id,
          expected: rules.where((rule) => rule.enabled).toList(),
          selected: [],
          now: DateTime(2029),
        ),
        isFalse,
      );
      expect(
        (await repository.listRules()).where((rule) => rule.enabled),
        isEmpty,
      );
      expect(
        (await repository.listInstances()).where(
          (item) =>
              item.status == ReminderInstanceStatus.scheduled ||
              item.status == ReminderInstanceStatus.snoozed,
        ),
        isEmpty,
      );
      expect(
        (await repository.listInstances())
            .singleWhere((item) => item.id == instances.first.id)
            .status,
        ReminderInstanceStatus.delivered,
      );
    } finally {
      await database.close();
      await directory.delete(recursive: true);
    }
  });

  test(
    'transaction rollback retains rules and instances when persistence fails',
    () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      try {
        final repository = DriftReminderRepository(database);
        final service = ReminderService(
          repository: repository,
          platform: _Platform(),
        );
        final plan =
            await CreateCommitmentPlan(
              commitments: DriftCommitmentRepository(database),
              plans: DriftCommitmentPlanRepository(database),
              reminderService: service,
            )(
              title: 'کلاس',
              startAt: DateTime(2030, 1, 1, 18),
              reminderOffsets: [const Duration(minutes: 15)],
            );
        final current = await repository.listRules();
        await database.customStatement(
          "CREATE TRIGGER reject_rule BEFORE INSERT ON reminder_rules BEGIN SELECT RAISE(ABORT, 'injected'); END",
        );
        await expectLater(
          service.editOccurrenceRules(
            occurrenceId: plan.occurrences.single.id,
            expected: current,
            selected: [
              ReminderRule.atOccurrence(
                occurrenceId: plan.occurrences.single.id,
              ),
            ],
            now: DateTime(2029),
          ),
          throwsA(anything),
        );
        expect((await repository.listRules()).single.enabled, isTrue);
        expect(
          (await repository.listInstances()).single.status,
          ReminderInstanceStatus.scheduled,
        );
      } finally {
        await database.close();
      }
    },
  );
}
