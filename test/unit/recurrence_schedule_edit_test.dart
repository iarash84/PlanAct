import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/errors/app_error.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/commitments/application/commitment_plan_use_case.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/commitments/domain/commitment_cycle.dart';
import 'package:planact/features/scheduling/application/recurrence_schedule_edit.dart';
import 'package:planact/features/scheduling/application/series_editing.dart';
import 'package:planact/features/scheduling/domain/occurrence.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';

CommitmentPlan fixture({
  required RecurrenceRule rule,
  int? count,
  LocalDate? start,
  int rows = 3,
}) {
  final day = start ?? LocalDate(2027, 1, 2);
  final owner = Commitment.create(
    title: 'کلاس',
    now: day.toUtcDateForCalculation(),
    kind: CommitmentKind.recurring,
  );
  final cycle = CommitmentCycle.create(
    commitmentId: owner.id,
    cycleType: CommitmentCycleType.openEnded,
    startDate: day.toUtcDateForCalculation(),
    completionRule: CompletionRule.manual,
  ).activate();
  final schedule = ScheduleDefinition.create(
    cycleId: cycle.id,
    mode: count == null
        ? ScheduleMode.openEndedRecurring
        : ScheduleMode.fixedCount,
    timeSemantics: TimeSemantics.allDayLocalDate,
    startDate: day,
    recurrenceRule: rule,
    occurrenceCount: count,
    generationHorizonDays: 800,
  );
  return CommitmentPlan(
    commitment: owner,
    cycle: cycle,
    schedule: schedule,
    occurrences: const OccurrenceGenerator()
        .generate(schedule: schedule, through: day.addDays(800))
        .take(rows)
        .toList(),
    reminders: const [],
  );
}

RecurrenceEditPreview preview(
  CommitmentPlan plan,
  RecurrenceScheduleEdit edit, {
  int anchor = 0,
  LocalDate? now,
}) => buildRecurrenceEditPreview(
  plan: plan,
  expected: plan.occurrences[anchor],
  scheduledAt: plan.occurrences[anchor].currentScheduledAt,
  scope: SeriesEditScope.thisAndFollowing,
  today: now ?? plan.schedule.startDate,
  edit: edit,
  token: 'snapshot',
  protectedIds: <StableId>{},
);

void main() {
  test('all-day daily interval retains identity and original evidence', () {
    final rule = RecurrenceRule(frequency: RecurrenceFrequency.daily);
    final plan = fixture(rule: rule);
    final result = preview(
      plan,
      RecurrenceScheduleEdit(
        rule: RecurrenceRule(frequency: RecurrenceFrequency.daily, interval: 2),
      ),
    );
    expect(result.occurrences.map((o) => o.currentScheduledAt), [
      LocalDate(2027, 1, 2),
      LocalDate(2027, 1, 4),
      LocalDate(2027, 1, 6),
    ]);
    expect(result.occurrences[1].id, plan.occurrences[1].id);
    expect(result.occurrences[1].originalScheduledAt, LocalDate(2027, 1, 3));
    expect(result.schedule.localTime, isNull);
  });

  test(
    'weekly selected weekdays are independent from inclusive termination',
    () {
      final rule = RecurrenceRule(
        frequency: RecurrenceFrequency.weekly,
        weekdays: {6, 1},
      );
      final plan = fixture(rule: rule, rows: 2);
      final result = preview(
        plan,
        RecurrenceScheduleEdit(
          rule: RecurrenceRule(
            frequency: RecurrenceFrequency.weekly,
            weekdays: {6, 1},
          ),
          endDate: LocalDate(2027, 1, 4),
        ),
      );
      expect(result.schedule.mode, ScheduleMode.fixedDateRangeRecurring);
      expect(result.occurrences.map((o) => o.currentScheduledAt), [
        LocalDate(2027, 1, 2),
        LocalDate(2027, 1, 4),
      ]);
      expect(result.schedule.endDate, LocalDate(2027, 1, 4));
    },
  );

  test(
    'count subtracts exact pre-boundary logical prefix, not number of rows',
    () {
      final rule = RecurrenceRule(frequency: RecurrenceFrequency.daily);
      final plan = fixture(rule: rule, count: 10);
      final result = preview(
        plan,
        RecurrenceScheduleEdit(rule: rule, totalCount: 6),
        anchor: 1,
      );
      expect(result.schedule.occurrenceCount, 6);
      final slots = const OccurrenceGenerator().plannedSlots(
        schedule: result.schedule,
        start: LocalDate(2027, 1, 3),
        endExclusive: LocalDate(2027, 1, 20),
        scheduleFingerprint: '',
      );
      expect(slots, hasLength(5));
      expect(
        () => preview(
          plan,
          RecurrenceScheduleEdit(
            rule: RecurrenceRule(
              frequency: RecurrenceFrequency.daily,
              interval: 2,
            ),
            totalCount: 10,
          ),
          anchor: 2,
        ),
        throwsA(isA<ValidationError>()),
      );
    },
  );

  test('Gregorian monthly original day 31 clamps and comes back', () {
    final rule = RecurrenceRule(
      frequency: RecurrenceFrequency.monthly,
      dayOfMonth: 31,
      monthEndPolicy: MonthEndPolicy.clampToLastDay,
    );
    final plan = fixture(rule: rule, start: LocalDate(2027, 1, 31));
    final result = preview(plan, RecurrenceScheduleEdit(rule: rule));
    expect(result.occurrences.map((o) => o.currentScheduledAt), [
      LocalDate(2027, 1, 31),
      LocalDate(2027, 2, 28),
      LocalDate(2027, 3, 31),
    ]);
  });

  test('Jalali yearly and legacy Gregorian rules retain exact anchors', () {
    for (final rule in [
      RecurrenceRule(
        frequency: RecurrenceFrequency.yearly,
        calendar: RecurrenceCalendar.jalali,
        dayOfMonth: 30,
        monthOfYear: 12,
        monthEndPolicy: MonthEndPolicy.clampToLastDay,
      ),
      RecurrenceRule(
        frequency: RecurrenceFrequency.yearly,
        legacyCalendarSemantics: true,
      ),
    ]) {
      final plan = fixture(rule: rule, start: LocalDate(2025, 3, 20), rows: 2);
      final result = preview(plan, RecurrenceScheduleEdit(rule: rule));
      expect(result.schedule.recurrenceRule!.calendar, rule.calendar);
      expect(
        result.schedule.recurrenceRule!.legacyCalendarSemantics,
        rule.legacyCalendarSemantics,
      );
      expect(
        result.occurrences.map((o) => o.currentScheduledAt),
        plan.occurrences.map((o) => o.currentScheduledAt),
      );
    }
  });
}
