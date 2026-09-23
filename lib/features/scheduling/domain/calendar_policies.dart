import 'package:planact/features/scheduling/domain/occurrence.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';

enum ConflictKind { exactInstant, localDate, localTime }

class PauseWindow {
  const PauseWindow({required this.start, required this.end});

  final LocalDate start;
  final LocalDate end;

  bool contains(LocalDate date) =>
      date.compareTo(start) >= 0 && date.compareTo(end) <= 0;
}

class ScheduleConflict {
  const ScheduleConflict({
    required this.left,
    required this.right,
    required this.kind,
  });

  final Occurrence left;
  final Occurrence right;
  final ConflictKind kind;
}

class CalendarPolicies {
  const CalendarPolicies();

  List<Occurrence> excludePausedFutureOccurrences({
    required Iterable<Occurrence> occurrences,
    required Iterable<PauseWindow> pauses,
  }) {
    return occurrences
        .where((occurrence) {
          if (_isHistorical(occurrence)) return true;
          final date = _dateOf(occurrence.currentScheduledAt);
          return !pauses.any((pause) => pause.contains(date));
        })
        .toList(growable: false);
  }

  List<ScheduleConflict> findConflicts(Iterable<Occurrence> occurrences) {
    final items = occurrences.toList(growable: false);
    final conflicts = <ScheduleConflict>[];
    for (var i = 0; i < items.length; i++) {
      for (var j = i + 1; j < items.length; j++) {
        final kind = _conflictKind(items[i], items[j]);
        if (kind != null) {
          conflicts.add(
            ScheduleConflict(left: items[i], right: items[j], kind: kind),
          );
        }
      }
    }
    return conflicts;
  }

  bool _isHistorical(Occurrence occurrence) =>
      occurrence.status == OccurrenceStatus.completed ||
      occurrence.status == OccurrenceStatus.cancelled ||
      occurrence.status == OccurrenceStatus.skipped;

  LocalDate _dateOf(Object value) => switch (value) {
    LocalDate date => date,
    DateTime instant => LocalDate.fromDateTime(instant),
    _ => throw StateError('Unsupported occurrence time value'),
  };

  ConflictKind? _conflictKind(Occurrence left, Occurrence right) {
    final a = left.currentScheduledAt;
    final b = right.currentScheduledAt;
    if (a is DateTime && b is DateTime && a.toUtc() == b.toUtc()) {
      return ConflictKind.exactInstant;
    }
    if (a is LocalDate && b is LocalDate && a == b) {
      return ConflictKind.localDate;
    }
    if (a is DateTime &&
        b is DateTime &&
        a.hour == b.hour &&
        a.minute == b.minute) {
      return ConflictKind.localTime;
    }
    return null;
  }
}
