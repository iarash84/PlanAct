import 'package:planact/core/application/command_gate.dart';
import 'package:planact/core/errors/app_error.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/commitments/application/commitment_plan_use_case.dart';
import 'package:planact/features/commitments/domain/commitment_cycle.dart';
import 'package:planact/features/reminders/application/reminder_service.dart';
import 'package:planact/features/scheduling/application/series_editing.dart';
import 'package:planact/features/scheduling/domain/occurrence.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';

/// Date/time-only series edits. Frequency and termination are not inferred.
class EditCommitmentSchedule {
  const EditCommitmentSchedule(this.plans, {this.reminders});
  final CommitmentPlanRepository plans;
  final ReminderService? reminders;

  Future<bool> call({
    required StableId commitmentId,
    required Occurrence expected,
    required Object scheduledAt,
    required SeriesEditScope scope,
    required DateTime now,
  }) => CommandGate.runFor(plans, () async {
    final transaction = plans;
    if (transaction is! CommitmentPlanTransaction) {
      throw StateError('Schedule edits require transactional persistence.');
    }
    final changed = await (transaction as CommitmentPlanTransaction)
        .runTransaction(() async {
          final plan = await plans.findByCommitmentId(commitmentId);
          if (plan == null) throw const ValidationError('Plan was not found.');
          if (plan.cycle.status != CommitmentCycleStatus.active) {
            throw const ValidationError('Only an active cycle can be edited.');
          }
          final occurrence = plan.occurrences
              .where((o) => o.id == expected.id)
              .firstOrNull;
          if (occurrence == null ||
              occurrence.status != expected.status ||
              occurrence.currentScheduledAt != expected.currentScheduledAt ||
              occurrence.scheduleDefinitionId !=
                  expected.scheduleDefinitionId) {
            throw const ValidationError(
              'Occurrence changed; reload before editing.',
            );
          }
          if ({
            OccurrenceStatus.completed,
            OccurrenceStatus.cancelled,
            OccurrenceStatus.skipped,
          }.contains(occurrence.status)) {
            throw const ValidationError(
              'Resolved history cannot be rescheduled.',
            );
          }
          final today = LocalDate.fromDateTime(now);
          final anchor = _date(occurrence.currentScheduledAt);
          if (anchor.compareTo(today) < 0 ||
              _date(scheduledAt).compareTo(today) < 0) {
            throw const ValidationError('Past dates cannot be edited.');
          }
          if (scope == SeriesEditScope.onlyThis) {
            final result = const SeriesEditor().editOccurrence(
              schedule: plan.schedule,
              occurrence: occurrence,
              newScheduledAt: scheduledAt,
              scope: scope,
              notBefore: today,
            );
            await plans.saveOccurrence(result.updatedOccurrence!);
            return [result.updatedOccurrence!];
          }
          if (plan.schedule.mode == ScheduleMode.oneOff) {
            throw const ValidationError(
              'One-off plans only support one occurrence.',
            );
          }
          final boundary = scope == SeriesEditScope.thisAndFollowing
              ? anchor
              : today;
          final candidates = plan.occurrences
              .where(
                (o) =>
                    _date(o.currentScheduledAt).compareTo(boundary) >= 0 &&
                    !o.isManualOverride &&
                    !{
                      OccurrenceStatus.completed,
                      OccurrenceStatus.cancelled,
                      OccurrenceStatus.skipped,
                    }.contains(o.status),
              )
              .toList();
          if (!candidates.any((o) => o.id == occurrence.id)) {
            throw const ValidationError(
              'Manually edited occurrences cannot anchor a series edit.',
            );
          }
          final shifted = const SeriesEditor()
              .editOccurrence(
                schedule: plan.schedule,
                occurrence: occurrence,
                newScheduledAt: scheduledAt,
                scope: SeriesEditScope.entireActiveCycle,
                occurrences: candidates,
                notBefore: boundary,
              )
              .occurrences!;
          if (shifted.any(
            (o) => _date(o.currentScheduledAt).compareTo(today) < 0,
          )) {
            throw const ValidationError(
              'An edit cannot move occurrences into the past.',
            );
          }
          final earliest = shifted
              .map((o) => _date(o.currentScheduledAt))
              .reduce((a, b) => a.compareTo(b) < 0 ? a : b);
          final delta = _date(scheduledAt)
              .toUtcDateForCalculation()
              .difference(anchor.toUtcDateForCalculation())
              .inDays;
          final rule = plan.schedule.recurrenceRule;
          if (rule == null || plan.schedule.mode == ScheduleMode.fixedCount) {
            throw const ValidationError(
              'This schedule requires an explicit termination-aware editor.',
            );
          }
          if (delta != 0 && rule.interval != 1) {
            throw const ValidationError(
              'Interval phase changes require an explicit recurrence editor.',
            );
          }
          if (delta != 0 &&
              {
                RecurrenceFrequency.monthly,
                RecurrenceFrequency.yearly,
              }.contains(rule.frequency)) {
            throw const ValidationError(
              'Monthly/yearly date shifts require an explicit recurrence editor.',
            );
          }
          final shiftedRule = RecurrenceRule(
            frequency: rule.frequency,
            interval: rule.interval,
            weekdays: rule.weekdays
                .map((day) => (day - 1 + delta) % 7 + 1)
                .toSet(),
            dayOfMonth: rule.dayOfMonth,
            monthEndPolicy: rule.monthEndPolicy,
          );
          final schedule = ScheduleDefinition(
            id: StableId.generate(),
            cycleId: plan.cycle.id,
            mode: plan.schedule.mode,
            timeSemantics: plan.schedule.timeSemantics,
            startDate: earliest,
            effectiveFrom: boundary,
            version: plan.schedule.version + 1,
            generationHorizonDays: plan.schedule.generationHorizonDays,
            localTime: scheduledAt is DateTime
                ? LocalTime(scheduledAt.hour, scheduledAt.minute)
                : null,
            timeZoneId: plan.schedule.timeZoneId,
            recurrenceRule: shiftedRule,
            endDate: plan.schedule.endDate,
            occurrenceCount: plan.schedule.occurrenceCount,
          );
          // Retain original values and identifiers; prior schedule definitions stay
          // in the database. Only unresolved automatically generated rows migrate.
          final updated = shifted
              .map(
                (o) => Occurrence(
                  id: o.id,
                  cycleId: o.cycleId,
                  scheduleDefinitionId: schedule.id,
                  occurrenceKey: o.occurrenceKey,
                  originalScheduledAt: o.originalScheduledAt,
                  currentScheduledAt: o.currentScheduledAt,
                  status: OccurrenceStatus.rescheduled,
                  isManualOverride: false,
                ),
              )
              .toList();
          await plans.save(
            CommitmentPlan(
              commitment: plan.commitment,
              cycle: plan.cycle,
              schedule: schedule,
              occurrences: updated,
              reminders: const [],
            ),
          );
          return updated;
        });
    var pending = false;
    for (final occurrence in changed) {
      try {
        await reminders?.synchronizeOccurrence(
          occurrenceId: occurrence.id,
          occurrenceStart: occurrence.currentScheduledAt is DateTime
              ? occurrence.currentScheduledAt as DateTime
              : null,
          resolved: false,
        );
      } catch (_) {
        pending = true;
      }
    }
    return pending;
  });

  LocalDate _date(Object value) =>
      value is LocalDate ? value : LocalDate.fromDateTime(value as DateTime);
}
