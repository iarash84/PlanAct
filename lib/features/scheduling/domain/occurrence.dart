import 'package:shamsi_date/shamsi_date.dart';
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
      throw const ValidationError(
        'A completed occurrence cannot be rescheduled',
      );
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
    LocalDate? windowStart,
    Iterable<Occurrence> existing = const [],
  }) {
    final existingByKey = <String, Occurrence>{
      for (final item in existing) item.occurrenceKey: item,
    };
    final generated = <Occurrence>[];
    var lower = windowStart ?? schedule.startDate;
    if (lower.compareTo(schedule.startDate) < 0) lower = schedule.startDate;
    if (lower.compareTo(schedule.effectiveFrom) < 0) {
      lower = schedule.effectiveFrom;
    }
    final horizonEnd = (windowStart ?? schedule.startDate).addDays(
      schedule.generationHorizonDays,
    );
    var limit = through.compareTo(horizonEnd) < 0 ? through : horizonEnd;
    if (schedule.endDate != null && schedule.endDate!.compareTo(limit) < 0) {
      limit = schedule.endDate!;
    }
    if (lower.compareTo(limit) > 0) return generated;
    var index = _slotsBefore(schedule, lower);

    for (final date in _candidateDates(schedule, lower, limit)) {
      if (schedule.endDate != null && date.compareTo(schedule.endDate!) > 0) {
        break;
      }
      if (schedule.occurrenceCount != null &&
          index >= schedule.occurrenceCount!) {
        break;
      }
      if (_matches(schedule, date)) {
        final key =
            '${schedule.id.value}:${date.year}-${date.month}-${date.day}';
        final previous = existingByKey[key];
        if (date.compareTo(windowStart ?? schedule.startDate) >= 0 &&
            date.compareTo(schedule.effectiveFrom) >= 0) {
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
        }
        index++;
      }
    }
    return generated;
  }

  // Count recurrence slots, never persisted rows. Daily/weekly prefixes are
  // arithmetic; sparse calendar prefixes visit months/years, not historical days.
  int _slotsBefore(ScheduleDefinition schedule, LocalDate lower) {
    if (schedule.occurrenceCount == null) return 0;
    final days = lower
        .toUtcDateForCalculation()
        .difference(schedule.startDate.toUtcDateForCalculation())
        .inDays;
    if (days <= 0) return 0;
    if (schedule.mode == ScheduleMode.oneOff) return 1;
    final rule = schedule.recurrenceRule!;
    if (rule.frequency == RecurrenceFrequency.daily) {
      return (days + rule.interval - 1) ~/ rule.interval;
    }
    if (rule.frequency == RecurrenceFrequency.weekly) {
      final weekdays = rule.weekdays.isEmpty
          ? {schedule.startDate.toUtcDateForCalculation().weekday}
          : rule.weekdays;
      final period = 7 * rule.interval;
      final full = days ~/ period;
      final remainder = days % period;
      final startWeekday = schedule.startDate.toUtcDateForCalculation().weekday;
      return full * weekdays.length +
          weekdays
              .where((weekday) => (weekday - startWeekday + 7) % 7 < remainder)
              .length;
    }
    if (rule.legacyCalendarSemantics &&
        rule.frequency == RecurrenceFrequency.monthly &&
        rule.dayOfMonth == null) {
      var count = 0;
      final start = schedule.startDate;
      var monthIndex = start.year * 12 + start.month - 1;
      final last = lower.year * 12 + lower.month - 1;
      while (monthIndex <= last) {
        final year = monthIndex ~/ 12;
        final month = monthIndex % 12 + 1;
        final first = LocalDate(year, month, 1);
        final next = LocalDate.fromDateTime(DateTime.utc(year, month + 1, 1));
        final from = first.compareTo(start) < 0 ? start : first;
        final to = next.compareTo(lower) > 0 ? lower : next;
        if (to.compareTo(from) > 0) {
          count += to
              .toUtcDateForCalculation()
              .difference(from.toUtcDateForCalculation())
              .inDays;
        }
        if (count >= schedule.occurrenceCount!) return count;
        monthIndex += rule.interval;
      }
      return count;
    }
    var count = 0;
    for (final date in _candidateDates(
      schedule,
      schedule.startDate,
      lower.addDays(-1),
    )) {
      if (_matches(schedule, date)) count++;
      if (count >= schedule.occurrenceCount!) break;
    }
    return count;
  }

  Iterable<LocalDate> _candidateDates(
    ScheduleDefinition schedule,
    LocalDate lower,
    LocalDate upper,
  ) sync* {
    if (lower.compareTo(upper) > 0) return;
    if (schedule.mode == ScheduleMode.oneOff) {
      if (schedule.startDate.compareTo(lower) >= 0 &&
          schedule.startDate.compareTo(upper) <= 0) {
        yield schedule.startDate;
      }
      return;
    }
    final rule = schedule.recurrenceRule!;
    if (rule.frequency == RecurrenceFrequency.daily) {
      final days = lower
          .toUtcDateForCalculation()
          .difference(schedule.startDate.toUtcDateForCalculation())
          .inDays;
      var date = schedule.startDate.addDays(
        ((days + rule.interval - 1) ~/ rule.interval) * rule.interval,
      );
      while (date.compareTo(upper) <= 0) {
        yield date;
        date = date.addDays(rule.interval);
      }
      return;
    }
    if (rule.frequency == RecurrenceFrequency.weekly ||
        (rule.legacyCalendarSemantics &&
            rule.frequency == RecurrenceFrequency.monthly &&
            rule.dayOfMonth == null)) {
      // These patterns can contain multiple days per period; scan only the
      // bounded window (legacy null-day monthly intentionally matches all days).
      var date = lower;
      while (date.compareTo(upper) <= 0) {
        yield date;
        date = date.addDays(1);
      }
      return;
    }
    final calendar = rule.legacyCalendarSemantics
        ? RecurrenceCalendar.gregorian
        : rule.calendar;
    final start = _calendarParts(schedule.startDate, calendar);
    final from = _calendarParts(lower, calendar);
    final to = _calendarParts(upper, calendar);
    final yearly = rule.frequency == RecurrenceFrequency.yearly;
    final step = yearly ? 12 * rule.interval : rule.interval;
    final anchorMonth = yearly
        ? (rule.legacyCalendarSemantics
              ? start.$2
              : rule.monthOfYear ?? start.$2)
        : start.$2;
    final base = start.$1 * 12 + anchorMonth - 1;
    final delta = from.$1 * 12 + from.$2 - 1 - base;
    // Include the containing period; the anchor can be later in this month.
    var monthIndex = base + (delta ~/ step) * step;
    final last = to.$1 * 12 + to.$2 - 1;
    while (monthIndex <= last) {
      final year = monthIndex ~/ 12;
      final month = yearly
          ? (rule.legacyCalendarSemantics
                ? start.$2
                : rule.monthOfYear ?? start.$2)
          : monthIndex % 12 + 1;
      final day = rule.legacyCalendarSemantics && yearly
          ? start.$3
          : rule.dayOfMonth ?? start.$3;
      final length = calendar == RecurrenceCalendar.jalali
          ? Jalali(year, month, 1).monthLength
          : DateTime.utc(year, month + 1, 0).day;
      final clamp =
          !(rule.legacyCalendarSemantics && yearly) &&
          rule.monthEndPolicy == MonthEndPolicy.clampToLastDay;
      if (day <= length || clamp) {
        final actualDay = day > length ? length : day;
        final g = calendar == RecurrenceCalendar.jalali
            ? Jalali(year, month, actualDay).toGregorian()
            : Gregorian(year, month, actualDay);
        final date = LocalDate(g.year, g.month, g.day);
        if (date.compareTo(lower) >= 0 && date.compareTo(upper) <= 0) {
          yield date;
        }
      }
      monthIndex += step;
    }
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
        if (!selectedWeekdays.contains(
          date.toUtcDateForCalculation().weekday,
        )) {
          return false;
        }
        return days >= 0 && days ~/ 7 % rule.interval == 0;
      case RecurrenceFrequency.monthly:
      case RecurrenceFrequency.yearly:
        if (rule.legacyCalendarSemantics) {
          if (rule.frequency == RecurrenceFrequency.yearly) {
            return date.month == schedule.startDate.month &&
                date.day == schedule.startDate.day &&
                (date.year - schedule.startDate.year) % rule.interval == 0;
          }
          if (rule.dayOfMonth == null) {
            return ((date.year - schedule.startDate.year) * 12 +
                        date.month -
                        schedule.startDate.month) %
                    rule.interval ==
                0;
          }
        }
        final start = _calendarParts(schedule.startDate, rule.calendar);
        final current = _calendarParts(date, rule.calendar);
        final targetDay = rule.dayOfMonth ?? start.$3;
        final lastDay = rule.calendar == RecurrenceCalendar.jalali
            ? Jalali(current.$1, current.$2, 1).monthLength
            : DateTime.utc(current.$1, current.$2 + 1, 0).day;
        final day =
            targetDay > lastDay &&
                rule.monthEndPolicy == MonthEndPolicy.clampToLastDay
            ? lastDay
            : targetDay;
        if (current.$3 != day) return false;
        if (rule.frequency == RecurrenceFrequency.yearly) {
          return current.$2 == (rule.monthOfYear ?? start.$2) &&
              (current.$1 - start.$1) % rule.interval == 0;
        }
        return ((current.$1 - start.$1) * 12 + current.$2 - start.$2) %
                rule.interval ==
            0;
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

  (int, int, int) _calendarParts(LocalDate date, RecurrenceCalendar calendar) {
    if (calendar == RecurrenceCalendar.gregorian) {
      return (date.year, date.month, date.day);
    }
    final value = Gregorian(date.year, date.month, date.day).toJalali();
    return (value.year, value.month, value.day);
  }
}
