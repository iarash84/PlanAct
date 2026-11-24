import 'dart:convert';

import 'package:planact/core/errors/app_error.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/commitments/application/commitment_plan_use_case.dart';
import 'package:planact/features/scheduling/application/series_editing.dart';
import 'package:planact/features/scheduling/domain/occurrence.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';

/// Explicit complete pattern/termination, never inferred from a date delta.
class RecurrenceScheduleEdit {
  const RecurrenceScheduleEdit({
    required this.rule,
    this.endDate,
    this.totalCount,
  });
  final RecurrenceRule rule;
  final LocalDate? endDate;
  final int? totalCount;
}

class RecurrenceEditPreview {
  RecurrenceEditPreview({
    required this.token,
    required this.schedule,
    required List<Occurrence> occurrences,
    required this.boundary,
  }) : occurrences = List.unmodifiable(occurrences);

  /// Opaque, ephemeral comparison token. Do not log or persist it.
  final String token;
  final ScheduleDefinition schedule;
  final List<Occurrence> occurrences;
  final LocalDate boundary;
}

abstract interface class RecurrenceEditRepository {
  /// Coherent read only; called inside the plan transaction on confirmation.
  Future<String> recurrenceEditToken(StableId commitmentId);
  Future<void> recordScheduleReminderIntent(StableId occurrenceId);
  Future<Set<StableId>> protectedScheduleOccurrences(StableId commitmentId);
}

LocalDate scheduleEditDate(Object value) =>
    value is LocalDate ? value : LocalDate.fromDateTime(value as DateTime);

RecurrenceEditPreview buildRecurrenceEditPreview({
  required CommitmentPlan plan,
  required Occurrence expected,
  required Object scheduledAt,
  required SeriesEditScope scope,
  required LocalDate today,
  required RecurrenceScheduleEdit edit,
  required String token,
  required Set<StableId> protectedIds,
}) {
  if (scope == SeriesEditScope.onlyThis) {
    throw const ValidationError('A single occurrence supports date/time only.');
  }
  final old = plan.schedule;
  final rule = old.recurrenceRule;
  if (rule == null || old.timeSemantics == TimeSemantics.fixedInstant) {
    throw const ValidationError(
      'Only recurring local schedules can be edited.',
    );
  }
  final next = edit.rule;
  if (next.calendar != rule.calendar ||
      next.legacyCalendarSemantics != rule.legacyCalendarSemantics ||
      next.monthEndPolicy != rule.monthEndPolicy ||
      next.dayOfMonth != rule.dayOfMonth ||
      next.monthOfYear != rule.monthOfYear) {
    throw const ValidationError(
      'Reference calendar and original anchors must be preserved.',
    );
  }
  if ((old.timeSemantics == TimeSemantics.allDayLocalDate) !=
      (scheduledAt is LocalDate)) {
    throw const ValidationError('Schedule time semantics must be preserved.');
  }
  final boundary = scope == SeriesEditScope.thisAndFollowing
      ? scheduleEditDate(expected.currentScheduledAt)
      : (today.compareTo(old.effectiveFrom) < 0 ? old.effectiveFrom : today);
  if (boundary.compareTo(today) < 0 ||
      boundary.compareTo(old.effectiveFrom) < 0 ||
      scheduleEditDate(scheduledAt).compareTo(boundary) < 0) {
    throw const ValidationError(
      'The new schedule cannot precede its boundary.',
    );
  }
  // Keep the original phase. A changed phase before the version boundary would
  // reinterpret the total count. Compare logical prefixes, never persisted rows.
  final schedule = ScheduleDefinition(
    id: StableId.generate(),
    cycleId: old.cycleId,
    mode: edit.totalCount != null
        ? ScheduleMode.fixedCount
        : edit.endDate != null
        ? ScheduleMode.fixedDateRangeRecurring
        : ScheduleMode.openEndedRecurring,
    timeSemantics: old.timeSemantics,
    startDate: old.startDate,
    version: old.version + 1,
    effectiveFrom: boundary,
    generationHorizonDays: old.generationHorizonDays,
    localTime: scheduledAt is DateTime
        ? LocalTime(scheduledAt.hour, scheduledAt.minute)
        : null,
    timeZoneId: old.timeZoneId,
    recurrenceRule: next,
    endDate: edit.endDate,
    occurrenceCount: edit.totalCount,
    generationReminderOffsets: old.generationReminderOffsets,
    generationReminderDelivery: old.generationReminderDelivery,
    generationFinancialExpectation: old.generationFinancialExpectation,
  );
  const generator = OccurrenceGenerator();
  if (edit.totalCount != null) {
    if (old.version != 1) {
      throw const ValidationError(
        'Count phase across prior versions requires independent correction.',
      );
    }
    final days = boundary
        .toUtcDateForCalculation()
        .difference(old.startDate.toUtcDateForCalculation())
        .inDays;
    if (days > 36600) {
      throw const ValidationError('Count prefix exceeds the bounded editor.');
    }
    int prefix(ScheduleDefinition source) {
      var count = 0;
      for (
        var day = source.startDate;
        day.compareTo(boundary) < 0;
        day = day.addDays(31)
      ) {
        final end = day.addDays(31).compareTo(boundary) > 0
            ? boundary
            : day.addDays(31);
        count += generator
            .plannedSlots(
              schedule: source,
              start: day,
              endExclusive: end,
              scheduleFingerprint: '',
            )
            .length;
      }
      return count;
    }

    // Candidate prefix needs its pre-boundary rule, not the version's lower bound.
    final candidate = ScheduleDefinition(
      id: schedule.id,
      cycleId: schedule.cycleId,
      mode: schedule.mode,
      timeSemantics: schedule.timeSemantics,
      startDate: schedule.startDate,
      version: 1,
      effectiveFrom: schedule.startDate,
      generationHorizonDays: schedule.generationHorizonDays,
      localTime: schedule.localTime,
      timeZoneId: schedule.timeZoneId,
      recurrenceRule: next,
      occurrenceCount: edit.totalCount,
    );
    if (prefix(old) != prefix(candidate) || prefix(old) >= edit.totalCount!) {
      throw const ValidationError(
        'The requested total cannot preserve the logical count phase.',
      );
    }
  }
  final rows =
      plan.occurrences
          .where(
            (o) =>
                scheduleEditDate(o.currentScheduledAt).compareTo(boundary) >=
                    0 ||
                scheduleEditDate(o.originalScheduledAt).compareTo(boundary) >=
                    0,
          )
          .toList()
        ..sort((a, b) {
          final order = scheduleEditDate(a.currentScheduledAt)
              .compareTo(scheduleEditDate(b.currentScheduledAt));
          return order != 0 ? order : a.id.value.compareTo(b.id.value);
        });
  if (!rows.any((o) => o.id == expected.id)) {
    throw const ValidationError('Anchor is outside the editable range.');
  }
  // Bound sparse-pattern remapping independently from the operational horizon.
  final through = boundary.addDays(36600);
  final slots = <PlannedOccurrenceSlot>[];
  for (
    var day = boundary;
    day.compareTo(through) <= 0 && slots.length < rows.length;
    day = day.addDays(31)
  ) {
    final end = day.addDays(31).compareTo(through.addDays(1)) > 0
        ? through.addDays(1)
        : day.addDays(31);
    slots.addAll(
      generator.plannedSlots(
        schedule: schedule,
        start: day,
        endExclusive: end,
        scheduleFingerprint: '',
      ),
    );
  }
  if (slots.length < rows.length) {
    throw const ValidationError(
      'This edit would remove recorded occurrences; shorten only through explicit correction.',
    );
  }
  final lastTarget = scheduleEditDate(slots[rows.length - 1].scheduledAt);
  if (rows.any(
    (row) =>
        scheduleEditDate(row.originalScheduledAt).compareTo(lastTarget) > 0,
  )) {
    throw const ValidationError(
      'This compression leaves ambiguous original-date occupancy.',
    );
  }
  final updated = <Occurrence>[];
  for (var i = 0; i < rows.length; i++) {
    final row = rows[i];
    final target = slots[i].scheduledAt;
    final protected =
        row.isManualOverride ||
        row.resultRevision != 0 ||
        protectedIds.contains(row.id) ||
        !{
          OccurrenceStatus.scheduled,
          OccurrenceStatus.rescheduled,
        }.contains(row.status) ||
        scheduleEditDate(row.currentScheduledAt).compareTo(today) < 0;
    if (protected) {
      if (row.currentScheduledAt != target) {
        throw const ValidationError('This edit would move protected history.');
      }
      continue;
    }
    updated.add(
      Occurrence(
        id: row.id,
        cycleId: row.cycleId,
        scheduleDefinitionId: schedule.id,
        occurrenceKey: row.occurrenceKey,
        originalScheduledAt: row.originalScheduledAt,
        currentScheduledAt: target,
        status: OccurrenceStatus.rescheduled,
        resultRevision: row.resultRevision,
      ),
    );
  }
  if (updated.isEmpty) {
    throw const ValidationError('No safely editable occurrences.');
  }
  if (updated
          .firstWhere((o) => o.id == expected.id, orElse: () => expected)
          .currentScheduledAt !=
      scheduledAt) {
    throw const ValidationError(
      'Selected date does not match the preserved recurrence phase.',
    );
  }
  return RecurrenceEditPreview(
    token: jsonEncode([
      token,
      expected.id.value,
      scope.index,
      today.year,
      today.month,
      today.day,
      scheduledAt is DateTime
          ? scheduledAt.toIso8601String()
          : [
              scheduleEditDate(scheduledAt).year,
              scheduleEditDate(scheduledAt).month,
              scheduleEditDate(scheduledAt).day,
            ],
      next.frequency.index,
      next.interval,
      (next.weekdays.toList()..sort()),
      next.calendar.index,
      next.dayOfMonth,
      next.monthOfYear,
      edit.totalCount,
      edit.endDate == null
          ? null
          : [edit.endDate!.year, edit.endDate!.month, edit.endDate!.day],
    ]),
    schedule: schedule,
    occurrences: updated,
    boundary: boundary,
  );
}
