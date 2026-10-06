import 'package:planact/core/errors/app_error.dart';
import 'package:planact/features/scheduling/domain/occurrence.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';

enum SeriesEditScope { onlyThis, thisAndFollowing, entireActiveCycle }

class SeriesEditResult {
  const SeriesEditResult({
    this.updatedOccurrence,
    this.newSchedule,
    this.occurrences,
  });

  final Occurrence? updatedOccurrence;
  final ScheduleDefinition? newSchedule;
  final List<Occurrence>? occurrences;
}

class SeriesEditor {
  const SeriesEditor();

  SeriesEditResult editOccurrence({
    required ScheduleDefinition schedule,
    required Occurrence occurrence,
    required Object newScheduledAt,
    required SeriesEditScope scope,
    Iterable<Occurrence> occurrences = const [],
    LocalTime? followingLocalTime,
    RecurrenceRule? followingRecurrenceRule,
    LocalDate? notBefore,
  }) {
    final source = occurrence.currentScheduledAt;
    if ((source is LocalDate) != (newScheduledAt is LocalDate) ||
        (source is DateTime &&
            newScheduledAt is DateTime &&
            source.isUtc != newScheduledAt.isUtc)) {
      throw const ValidationError('An edit must preserve time semantics');
    }
    if (notBefore != null && _localDateOf(source).compareTo(notBefore) < 0) {
      throw const ValidationError('Past occurrences cannot be rescheduled');
    }
    switch (scope) {
      case SeriesEditScope.onlyThis:
        return SeriesEditResult(
          updatedOccurrence: occurrence.reschedule(newScheduledAt),
        );
      case SeriesEditScope.thisAndFollowing:
        final effectiveFrom = _localDateOf(occurrence.currentScheduledAt);
        final newSchedule = schedule.nextVersion(
          effectiveFrom: effectiveFrom,
          localTime: followingLocalTime,
          recurrenceRule: followingRecurrenceRule,
        );
        return SeriesEditResult(newSchedule: newSchedule);
      case SeriesEditScope.entireActiveCycle:
        final historical = {
          OccurrenceStatus.completed,
          OccurrenceStatus.cancelled,
          OccurrenceStatus.skipped,
        };
        final anchor = _localDateOf(occurrence.currentScheduledAt);
        final target = _localDateOf(newScheduledAt);
        final deltaDays = target
            .toUtcDateForCalculation()
            .difference(anchor.toUtcDateForCalculation())
            .inDays;

        final future = occurrences
            .where(
              (item) =>
                  item.cycleId == occurrence.cycleId &&
                  !historical.contains(item.status) &&
                  !item.isManualOverride &&
                  (notBefore == null ||
                      _localDateOf(item.currentScheduledAt)
                              .compareTo(notBefore) >=
                          0),
            )
            .map((item) {
              final value = item.currentScheduledAt;
              final shiftedDate = _localDateOf(value).addDays(deltaDays);
              if (value is LocalDate) return item.reschedule(shiftedDate);
              final time = newScheduledAt as DateTime;
              return item.reschedule(
                (value as DateTime).isUtc
                    ? DateTime.utc(
                        shiftedDate.year,
                        shiftedDate.month,
                        shiftedDate.day,
                        time.hour,
                        time.minute,
                        time.second,
                        time.millisecond,
                        time.microsecond,
                      )
                    : DateTime(
                        shiftedDate.year,
                        shiftedDate.month,
                        shiftedDate.day,
                        time.hour,
                        time.minute,
                        time.second,
                        time.millisecond,
                        time.microsecond,
                      ),
              );
            })
            .toList(growable: false);
        return SeriesEditResult(occurrences: future);
    }
  }

  LocalDate _localDateOf(Object value) {
    if (value is LocalDate) return value;
    if (value is DateTime) {
      return LocalDate.fromDateTime(value);
    }
    throw const ValidationError('Occurrence does not contain an editable date');
  }
}
