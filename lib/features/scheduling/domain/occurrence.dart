import 'package:planact/core/errors/app_error.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';

enum OccurrenceStatus {
  scheduled,
  due,
  completed,
  skipped,
  cancelled,
  rescheduled,
  overdue,
  deferred,
  pendingDecision,
}

class Occurrence {
  Occurrence({
    required this.id,
    required this.cycleId,
    required this.scheduleDefinitionId,
    required this.occurrenceKey,
    required this.originalScheduledAt,
    required this.currentScheduledAt,
    this.status = OccurrenceStatus.scheduled,
    this.isManualOverride = false,
  }) {
    if (occurrenceKey.trim().isEmpty) {
      throw const ValidationError('Occurrence key cannot be empty');
    }
  }

  final StableId id;
  final StableId cycleId;
  final StableId scheduleDefinitionId;
  final String occurrenceKey;
  final Object originalScheduledAt;
  final Object currentScheduledAt;
  final OccurrenceStatus status;
  final bool isManualOverride;

  Occurrence reschedule(Object newScheduledAt) {
    if (status == OccurrenceStatus.completed) {
      throw const ValidationError('A completed occurrence cannot be rescheduled');
    }
    return Occurrence(
      id: id,
      cycleId: cycleId,
      scheduleDefinitionId: scheduleDefinitionId,
      occurrenceKey: occurrenceKey,
      originalScheduledAt: originalScheduledAt,
      currentScheduledAt: newScheduledAt,
      status: OccurrenceStatus.rescheduled,
      isManualOverride: true,
    );
  }

  Occurrence deferTo({required Object newScheduledAt, required String newKey}) {
    if (status == OccurrenceStatus.completed) {
      throw const ValidationError('A completed occurrence cannot be deferred');
    }
    return Occurrence(
      id: StableId.generate(),
      cycleId: cycleId,
      scheduleDefinitionId: scheduleDefinitionId,
      occurrenceKey: newKey,
      originalScheduledAt: originalScheduledAt,
      currentScheduledAt: newScheduledAt,
      status: OccurrenceStatus.scheduled,
      isManualOverride: true,
    );
  }

  Occurrence withStatus(OccurrenceStatus nextStatus) {
    if (status == OccurrenceStatus.completed &&
        nextStatus != OccurrenceStatus.completed) {
      throw const ValidationError('A completed occurrence is historical');
    }
    return Occurrence(
      id: id,
      cycleId: cycleId,
      scheduleDefinitionId: scheduleDefinitionId,
      occurrenceKey: occurrenceKey,
      originalScheduledAt: originalScheduledAt,
      currentScheduledAt: currentScheduledAt,
      status: nextStatus,
      isManualOverride: isManualOverride,
    );
  }
}

class OccurrenceGenerator {
  const OccurrenceGenerator();

  List<Occurrence> generate({
    required ScheduleDefinition schedule,
    required LocalDate through,
    Iterable<Occurrence> existing = const [],
  }) {
    final existingByKey = <String, Occurrence>{
      for (final item in existing) item.occurrenceKey: item,
    };
    final generated = <Occurrence>[];
    var date = schedule.startDate;
    var index = 0;
    final horizonEnd = schedule.startDate.addDays(
      schedule.generationHorizonDays,
    );
    final limit = through.compareTo(horizonEnd) < 0 ? through : horizonEnd;

    while (date.compareTo(limit) <= 0) {
      if (schedule.endDate != null && date.compareTo(schedule.endDate!) > 0) {
        break;
      }
      if (schedule.occurrenceCount != null &&
          index >= schedule.occurrenceCount!) {
        break;
      }
      if (_matches(schedule, date)) {
        final key = '${schedule.id.value}:${date.year}-${date.month}-$index';
        final previous = existingByKey[key];
        generated.add(
          previous ??
              Occurrence(
                id: StableId.generate(
                  timestamp: date.toUtcDateForCalculation(),
                ),
                cycleId: schedule.cycleId,
                scheduleDefinitionId: schedule.id,
                occurrenceKey: key,
                originalScheduledAt: _scheduledValue(schedule, date),
                currentScheduledAt: _scheduledValue(schedule, date),
              ),
        );
        index++;
      }
      date = date.addDays(1);
    }
    return generated;
  }

  bool _matches(ScheduleDefinition schedule, LocalDate date) {
    if (schedule.mode == ScheduleMode.oneOff) {
      return date == schedule.startDate;
    }
    final rule = schedule.recurrenceRule!;
    final days = date
        .toUtcDateForCalculation()
        .difference(schedule.startDate.toUtcDateForCalculation())
        .inDays;
    switch (rule.frequency) {
      case RecurrenceFrequency.daily:
        return days >= 0 && days % rule.interval == 0;
      case RecurrenceFrequency.weekly:
        final selectedWeekdays = rule.weekdays.isEmpty
            ? {schedule.startDate.toUtcDateForCalculation().weekday}
            : rule.weekdays;
        if (!selectedWeekdays.contains(date.toUtcDateForCalculation().weekday)) {
          return false;
        }
        return days >= 0 && days ~/ 7 % rule.interval == 0;
      case RecurrenceFrequency.monthly:
        if (rule.dayOfMonth != null) {
          final lastDay = DateTime.utc(date.year, date.month + 1, 0).day;
          final target =
              rule.dayOfMonth! > lastDay &&
                  rule.monthEndPolicy == MonthEndPolicy.clampToLastDay
              ? lastDay
              : rule.dayOfMonth;
          if (date.day != target) return false;
        }
        return _monthDistance(schedule.startDate, date) % rule.interval == 0;
      case RecurrenceFrequency.yearly:
        return date.month == schedule.startDate.month &&
            date.day == schedule.startDate.day &&
            (date.year - schedule.startDate.year) % rule.interval == 0;
    }
  }

  Object _scheduledValue(ScheduleDefinition schedule, LocalDate date) {
    switch (schedule.timeSemantics) {
      case TimeSemantics.allDayLocalDate:
        return date;
      case TimeSemantics.fixedInstant:
        return schedule.fixedInstant!;
      case TimeSemantics.floatingLocalTime:
        return DateTime(
          date.year,
          date.month,
          date.day,
          schedule.localTime!.hour,
          schedule.localTime!.minute,
        );
    }
  }

  int _monthDistance(LocalDate from, LocalDate to) =>
      (to.year - from.year) * 12 + to.month - from.month;
}
