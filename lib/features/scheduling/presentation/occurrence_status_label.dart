import 'package:planact/features/scheduling/domain/occurrence.dart';

String occurrenceStatusLabel(OccurrenceStatus status) => switch (status) {
  OccurrenceStatus.scheduled => 'برنامه‌ریزی‌شده',
  OccurrenceStatus.due => 'موعد رسیده',
  OccurrenceStatus.completed => 'انجام‌شده',
  OccurrenceStatus.skipped => 'عدم حضور',
  OccurrenceStatus.cancelled => 'لغوشده',
  OccurrenceStatus.rescheduled => 'جابه‌جا شده',
  OccurrenceStatus.overdue => 'عقب‌افتاده',
  OccurrenceStatus.deferred => 'موکول شده',
  OccurrenceStatus.pendingDecision => 'نیازمند تصمیم',
};
