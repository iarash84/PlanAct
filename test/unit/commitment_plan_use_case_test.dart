import 'package:flutter_test/flutter_test.dart';
import 'package:planact/features/commitments/application/commitment_plan_use_case.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/commitments/application/commitment_repository.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';

void main() {
  test(
    'creates a recurring plan with bounded occurrences and reminders',
    () async {
      final commitments = InMemoryCommitmentRepository();
      final plans = InMemoryCommitmentPlanRepository();
      final start = DateTime(2026, 9, 22, 18);

      final plan =
          await CreateCommitmentPlan(
            commitments: commitments,
            plans: plans,
          ).call(
            title: 'کلاس موسیقی',
            startAt: start,
            kind: CommitmentKind.recurring,
            frequency: RecurrenceFrequency.weekly,
            weekdays: {2, 4},
            occurrenceCount: 4,
            reminderOffset: const Duration(minutes: 5),
          );

      expect(plan.commitment.title, 'کلاس موسیقی');
      expect(plan.cycle.targetUnits, 4);
      expect(plan.schedule.mode, ScheduleMode.fixedCount);
      expect(plan.occurrences, hasLength(4));
      expect(plan.reminders, hasLength(4));
      expect(
        plan.reminders.every(
          (rule) => rule.offset == -const Duration(minutes: 5),
        ),
        isTrue,
      );
      expect(await commitments.findById(plan.commitment.id), isNotNull);
      expect(await plans.findByCommitmentId(plan.commitment.id), same(plan));
    },
  );

  test('creates a one-off plan without a recurrence rule', () async {
    final plan = await CreateCommitmentPlan(
      commitments: InMemoryCommitmentRepository(),
      plans: InMemoryCommitmentPlanRepository(),
    ).call(title: 'قرار پزشکی', startAt: DateTime(2026, 9, 22, 9));

    expect(plan.schedule.mode, ScheduleMode.oneOff);
    expect(plan.schedule.recurrenceRule, isNull);
    expect(plan.occurrences, hasLength(1));
  });
}
