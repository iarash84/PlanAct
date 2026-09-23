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
  }) {
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
        final historical = occurrences.where(
          (item) =>
              item.status == OccurrenceStatus.completed ||
              item.status == OccurrenceStatus.cancelled ||
              item.status == OccurrenceStatus.skipped,
        );
        final future = occurrences
            .where((item) => !historical.contains(item))
            .map((item) => item.reschedule(newScheduledAt))
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
