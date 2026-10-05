import 'package:planact/core/application/command_gate.dart';
import 'package:planact/core/errors/app_error.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/finance/application/financial_expectation_use_cases.dart';
import 'package:planact/features/finance/domain/financial_expectation.dart';
import 'package:planact/features/reminders/application/reminder_service.dart';
import 'package:planact/features/sessions/data/drift_session_repositories.dart';
import 'package:planact/features/sessions/domain/entitlement.dart';
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
    this.reminderDeliveryPending = false,
  });

  final Commitment commitment;
  final CommitmentCycle cycle;
  final ScheduleDefinition schedule;
  final List<Occurrence> occurrences;
  final List<ReminderRule> reminders;

  /// Presentation feedback only; durable instances remain the retry source.
  final bool reminderDeliveryPending;
}

abstract interface class CommitmentPlanRepository {
  Future<void> save(CommitmentPlan plan);
  Future<CommitmentPlan?> findByCommitmentId(StableId commitmentId);
  Future<void> saveOccurrence(Occurrence occurrence);
}

abstract interface class CommitmentPlanTransaction {
  Future<T> runTransaction<T>(Future<T> Function() action);
}

class InMemoryCommitmentPlanRepository implements CommitmentPlanRepository {
  final Map<StableId, CommitmentPlan> _plans = {};

  @override
  Future<void> save(CommitmentPlan plan) async =>
      _plans[plan.commitment.id] = plan;

  @override
  Future<CommitmentPlan?> findByCommitmentId(StableId commitmentId) async =>
      _plans[commitmentId];

  @override
  Future<void> saveOccurrence(Occurrence occurrence) async {
    final entry = _plans.entries
        .where(
          (item) => item.value.occurrences.any((o) => o.id == occurrence.id),
        )
        .firstOrNull;
    if (entry == null) throw StateError('Occurrence was not found.');
    final plan = entry.value;
    final occurrences = [
      for (final item in plan.occurrences)
        item.id == occurrence.id ? occurrence : item,
    ];
    _plans[entry.key] = CommitmentPlan(
      commitment: plan.commitment,
      cycle: plan.cycle,
      schedule: plan.schedule,
      occurrences: List.unmodifiable(occurrences),
      reminders: plan.reminders,
    );
  }
}

class CreateCommitmentPlan {
  const CreateCommitmentPlan({
    required this.commitments,
    required this.plans,
    this.reminderService,
    this.entitlements,
    this.financialExpectations,
  });

  final CommitmentRepository commitments;
  final CommitmentPlanRepository plans;
  final ReminderService? reminderService;
  final EntitlementPlanRepository? entitlements;
  final FinancialExpectationUseCases? financialExpectations;

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
    int? entitlementUnits,
    DateTime? entitlementExpiry,
    FinancialExpectationDirection? financialDirection,
    int? financialAmount,
    @Deprecated('Use reminderOffsets to support multiple reminders.')
    Duration? reminderOffset,
  }) => CommandGate.runFor(commitments, () async {
    if (entitlementUnits != null && entitlementUnits <= 0) {
      throw const ValidationError('Entitlement units must be positive');
    }
    if (entitlementUnits != null && entitlements == null) {
      throw StateError('Entitlement repository is required for session plans.');
    }
    if (financialDirection != null &&
        (financialAmount == null || financialAmount <= 0)) {
      throw const ValidationError('Expected amount must be positive');
    }
    if (financialDirection != null && financialExpectations == null) {
      throw StateError('Financial expectation use cases are required.');
    }
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
    Future<void> persist() => CommandGate.runFor(commitments, () async {
      await commitments.save(commitment);
      await plans.save(plan);
      if (reminderService case final service?) {
        for (final rule in reminders) {
          final occurrence = occurrences.firstWhere(
            (item) => item.id == rule.occurrenceId,
          );
          await service.repository.saveRule(rule);
          await service.repository.saveInstance(
            ReminderInstance.fromRule(
              rule: rule,
              occurrenceStart: occurrence.currentScheduledAt as DateTime,
            ),
          );
        }
      }
      if (entitlementUnits != null) {
        final repository = entitlements;
        if (repository == null) {
          throw StateError(
            'Entitlement repository is required for session plans.',
          );
        }
        final entitlement = EntitlementPlan.create(
          cycleId: cycle.id,
          totalUnits: entitlementUnits,
          unitType: EntitlementUnitType.session,
          validFrom: startAt,
          plannedExpiry: entitlementExpiry,
        );
        await repository.save(entitlement);
      }
      if (financialDirection != null && financialAmount != null) {
        final expectationUseCases = financialExpectations;
        if (expectationUseCases == null) {
          throw StateError('Financial expectation use cases are required.');
        }
        for (final occurrence in occurrences) {
          await expectationUseCases.create(
            occurrenceId: occurrence.id,
            direction: financialDirection,
            amount: financialAmount,
          );
        }
      }
    });

    if (plans case final CommitmentPlanTransaction transaction) {
      await transaction.runTransaction(persist);
    } else {
      await persist();
    }
    var reminderDeliveryPending = false;
    if (reminderService != null) {
      for (final reminder in reminders) {
        final occurrence = occurrences.firstWhere(
          (item) => item.id == reminder.occurrenceId,
        );
        try {
          await reminderService!.schedule(
            rule: reminder,
            occurrenceStart: occurrence.currentScheduledAt as DateTime,
          );
        } on ReminderPermissionUnavailable {
          reminderDeliveryPending = true;
        }
      }
    }
    if (!reminderDeliveryPending) return plan;
    return CommitmentPlan(
      commitment: plan.commitment,
      cycle: plan.cycle,
      schedule: plan.schedule,
      occurrences: plan.occurrences,
      reminders: plan.reminders,
      reminderDeliveryPending: reminderDeliveryPending,
    );
  });
}
