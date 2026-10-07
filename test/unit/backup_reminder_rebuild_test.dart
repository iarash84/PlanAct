import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/reminders/application/reminder_service.dart';
import 'package:planact/features/reminders/domain/reminder.dart';

class EligibilityRepository extends InMemoryReminderRepository
    implements ReminderOccurrenceEligibility {
  @override
  Future<bool> canRemind(StableId occurrenceId) async => false;
}

class Platform implements ReminderPlatformAdapter {
  int schedules = 0;
  int cancellations = 0;
  @override
  Future<void> schedule(ReminderInstance instance) async => schedules++;
  @override
  Future<void> cancel(ReminderInstance instance) async => cancellations++;
}

void main() {
  test(
    'restore reconciliation cancels ineligible occurrence reminders',
    () async {
      final repository = EligibilityRepository();
      final platform = Platform();
      final rule = ReminderRule.atOccurrence(occurrenceId: StableId.generate());
      final instance = ReminderInstance.fromRule(
        rule: rule,
        occurrenceStart: DateTime.utc(2030),
      );
      await repository.saveRule(rule);
      await repository.saveInstance(instance);
      await ReminderService(
        repository: repository,
        platform: platform,
      ).reconcile(now: DateTime.utc(2026));
      expect(platform.schedules, 0);
      expect(platform.cancellations, 1);
      expect(
        (await repository.listInstances()).single.status,
        ReminderInstanceStatus.cancelled,
      );
    },
  );

  test(
    'restore reconciliation preserves delivered notification history',
    () async {
      final repository = EligibilityRepository();
      final platform = Platform();
      final rule = ReminderRule.atOccurrence(occurrenceId: StableId.generate());
      final instance = ReminderInstance.fromRule(
        rule: rule,
        occurrenceStart: DateTime.utc(2020),
      ).deliver();
      await repository.saveRule(rule);
      await repository.saveInstance(instance);
      await ReminderService(
        repository: repository,
        platform: platform,
      ).reconcile(now: DateTime.utc(2026));
      expect(
        (await repository.listInstances()).single.status,
        ReminderInstanceStatus.delivered,
      );
      expect(platform.schedules, 0);
    },
  );
}
