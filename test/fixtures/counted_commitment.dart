import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/commitments/application/commitment_plan_use_case.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/commitments/domain/commitment_cycle.dart';
import 'package:planact/features/finance/domain/financial_expectation.dart';
import 'package:planact/features/scheduling/domain/occurrence.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';

CommitmentPlan countedPlan({
  int target = 4,
  List<OccurrenceStatus> statuses = const [
    OccurrenceStatus.completed,
    OccurrenceStatus.completed,
    OccurrenceStatus.cancelled,
    OccurrenceStatus.scheduled,
  ],
  bool payments = false,
  LocalDate? start,
  int version = 1,
}) {
  final commitment = Commitment.create(
    title: payments ? 'اقساط وام' : 'کلاس موسیقی',
    kind: CommitmentKind.recurring,
  );
  final first = start ?? LocalDate.fromDateTime(DateTime.now());
  final cycle = CommitmentCycle.create(
    commitmentId: commitment.id,
    cycleType: CommitmentCycleType.fixedCount,
    startDate: DateTime(first.year, first.month, first.day),
    completionRule: CompletionRule.byUnits,
    targetUnits: target,
  ).activate();
  final initial = ScheduleDefinition.create(
    cycleId: cycle.id,
    mode: ScheduleMode.fixedCount,
    timeSemantics: TimeSemantics.floatingLocalTime,
    startDate: first,
    localTime: LocalTime(18, 0),
    timeZoneId: 'local',
    recurrenceRule: RecurrenceRule(frequency: RecurrenceFrequency.daily),
    occurrenceCount: target,
    generationFinancialExpectation: payments
        ? const FinancialExpectationTemplate(
            direction: FinancialExpectationDirection.outgoing,
            amount: 1000,
            currency: 'IRR',
          )
        : null,
  );
  final schedule = ScheduleDefinition(
    id: initial.id,
    cycleId: cycle.id,
    mode: initial.mode,
    timeSemantics: initial.timeSemantics,
    startDate: first,
    localTime: initial.localTime,
    timeZoneId: initial.timeZoneId,
    recurrenceRule: initial.recurrenceRule,
    occurrenceCount: target,
    effectiveFrom: version > 1 ? first.addDays(1) : first,
    version: version,
    generationHorizonDays: 90,
    generationFinancialExpectation: initial.generationFinancialExpectation,
  );
  return CommitmentPlan(
    commitment: commitment,
    cycle: cycle,
    schedule: schedule,
    occurrences: [
      for (var i = 0; i < statuses.length; i++)
        Occurrence(
          id: StableId.generate(),
          cycleId: cycle.id,
          scheduleDefinitionId: schedule.id,
          occurrenceKey: '${schedule.id}:$i',
          originalScheduledAt: DateTime(
            first.year,
            first.month,
            first.day + i,
            18,
          ),
          currentScheduledAt: DateTime(
            first.year,
            first.month,
            first.day + i,
            18,
          ),
          status: statuses[i],
        ),
    ],
    reminders: const [],
  );
}
