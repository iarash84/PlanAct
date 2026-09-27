import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/reminders/application/reminder_service.dart';
import 'package:planact/features/commitments/application/commitment_repository.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/commitments/domain/commitment_cycle.dart';
import 'package:planact/features/reminders/domain/reminder.dart';
import 'package:planact/features/scheduling/domain/occurrence.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';

class CommitmentPlan {
  const CommitmentPlan({
    required this.commitment,
    required this.cycle,
    required this.schedule,
    required this.occurrences,
    required this.reminders,
  });

  final Commitment commitment;
  final CommitmentCycle cycle;
  final ScheduleDefinition schedule;
  final List<Occurrence> occurrences;
  final List<ReminderRule> reminders;
}

abstract interface class CommitmentPlanRepository {
  Future<void> save(CommitmentPlan plan);
  Future<CommitmentPlan?> findByCommitmentId(StableId commitmentId);
}

class InMemoryCommitmentPlanRepository implements CommitmentPlanRepository {
  final Map<StableId, CommitmentPlan> _plans = {};

  @override
  Future<void> save(CommitmentPlan plan) async =>
      _plans[plan.commitment.id] = plan;

  @override
  Future<CommitmentPlan?> findByCommitmentId(StableId commitmentId) async =>
      _plans[commitmentId];
}

class CreateCommitmentPlan {
  const CreateCommitmentPlan({
    required this.commitments,
    required this.plans,
    this.reminderService,
  });

  final CommitmentRepository commitments;
  final CommitmentPlanRepository plans;
  final ReminderService? reminderService;

  Future<CommitmentPlan> call({
    required String title,
    required DateTime startAt,
    CommitmentKind kind = CommitmentKind.oneOff,
    CommitmentPriority priority = CommitmentPriority.normal,
    String? description,
    Set<String> tags = const {},
    List<String> attachmentIds = const [],
    RecurrenceFrequency? frequency,
    Set<int> weekdays = const {},
    int? dayOfMonth,
    int? occurrenceCount,
    DateTime? endDate,
    List<Duration> reminderOffsets = const [],
    @Deprecated('Use reminderOffsets to support multiple reminders.')
    Duration? reminderOffset,
  }) async {
    final effectiveReminderOffsets = reminderOffsets.isNotEmpty
        ? reminderOffsets
        : reminderOffset == null
        ? const <Duration>[]
        : [reminderOffset];
    final commitment = Commitment.create(
      title: title,
      now: startAt,
      kind: kind,
      priority: priority,
      description: description,
      tags: tags,
      attachmentIds: attachmentIds,
    );
    final cycle = CommitmentCycle.create(
      commitmentId: commitment.id,
      cycleType: kind == CommitmentKind.oneOff
          ? CommitmentCycleType.fixedCount
          : occurrenceCount != null
          ? CommitmentCycleType.fixedCount
          : endDate != null
          ? CommitmentCycleType.fixedDateRange
          : CommitmentCycleType.openEnded,
      startDate: startAt,
      completionRule: occurrenceCount != null
          ? CompletionRule.byUnits
          : endDate != null
          ? CompletionRule.byDate
          : CompletionRule.manual,
      plannedEndDate: endDate,
      targetUnits:
          occurrenceCount ?? (kind == CommitmentKind.oneOff ? 1 : null),
    ).activate();
    final localDate = LocalDate.fromDateTime(startAt);
    final schedule = ScheduleDefinition.create(
      cycleId: cycle.id,
      mode: kind == CommitmentKind.oneOff
          ? ScheduleMode.oneOff
          : occurrenceCount != null
          ? ScheduleMode.fixedCount
          : endDate != null
          ? ScheduleMode.fixedDateRangeRecurring
          : ScheduleMode.openEndedRecurring,
      timeSemantics: TimeSemantics.floatingLocalTime,
      startDate: localDate,
      localTime: LocalTime(startAt.hour, startAt.minute),
      timeZoneId: 'local',
      recurrenceRule: kind == CommitmentKind.oneOff
          ? null
          : RecurrenceRule(
              frequency: frequency ?? RecurrenceFrequency.weekly,
              weekdays: weekdays,
              dayOfMonth: dayOfMonth ?? startAt.day,
              monthEndPolicy: MonthEndPolicy.clampToLastDay,
            ),
      endDate: endDate == null ? null : LocalDate.fromDateTime(endDate),
      occurrenceCount: occurrenceCount,
    );
    final through = endDate == null
        ? localDate.addDays(kind == CommitmentKind.oneOff ? 0 : 90)
        : LocalDate.fromDateTime(endDate);
    final occurrences = OccurrenceGenerator().generate(
      schedule: schedule,
      through: through,
    );
    final reminders = [
      for (final occurrence in occurrences)
        for (final offset in effectiveReminderOffsets)
          ReminderRule.beforeOccurrence(
            occurrenceId: occurrence.id,
            offset: offset,
            title: title,
          ),
    ];
    final plan = CommitmentPlan(
      commitment: commitment,
      cycle: cycle,
      schedule: schedule,
      occurrences: List.unmodifiable(occurrences),
      reminders: List.unmodifiable(reminders),
    );
    await commitments.save(commitment);
    await plans.save(plan);
    if (reminderService != null) {
      for (final reminder in reminders) {
        final occurrence = occurrences.firstWhere(
          (item) => item.id == reminder.occurrenceId,
        );
        await reminderService!.schedule(
          rule: reminder,
          occurrenceStart: occurrence.currentScheduledAt as DateTime,
        );
      }
    }
    return plan;
  }
}
