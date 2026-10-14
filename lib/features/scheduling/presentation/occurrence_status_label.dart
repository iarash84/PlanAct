import 'package:planact/core/localization/persian_copy.g.dart';
import 'package:planact/features/scheduling/domain/occurrence.dart';

String occurrenceStatusLabel(OccurrenceStatus status) => switch (status) {
  OccurrenceStatus.scheduled => PersianCopy.occurrenceScheduled,
  OccurrenceStatus.due => PersianCopy.occurrenceDue,
  OccurrenceStatus.completed => PersianCopy.occurrenceCompleted,
  OccurrenceStatus.skipped => PersianCopy.occurrenceSkipped,
  OccurrenceStatus.cancelled => PersianCopy.occurrenceCancelled,
  OccurrenceStatus.rescheduled => PersianCopy.occurrenceRescheduled,
  OccurrenceStatus.overdue => PersianCopy.occurrenceOverdue,
  OccurrenceStatus.deferred => PersianCopy.occurrenceDeferred,
  OccurrenceStatus.pendingDecision => PersianCopy.occurrencePendingDecision,
};
