import 'package:flutter_test/flutter_test.dart';
import 'package:planact/features/calendar/presentation/week_timeline_view.dart';
import 'package:planact/features/scheduling/domain/occurrence.dart';
import 'package:planact/features/scheduling/presentation/occurrence_status_label.dart';

void main() {
  test('all persisted occurrence statuses retain their Persian labels', () {
    const labels = {
      OccurrenceStatus.scheduled: 'برنامه‌ریزی‌شده',
      OccurrenceStatus.due: 'موعد رسیده',
      OccurrenceStatus.completed: 'انجام‌شده',
      OccurrenceStatus.skipped: 'عدم حضور',
      OccurrenceStatus.cancelled: 'لغوشده',
      OccurrenceStatus.rescheduled: 'جابه‌جا شده',
      OccurrenceStatus.overdue: 'عقب‌افتاده',
      OccurrenceStatus.deferred: 'موکول شده',
      OccurrenceStatus.pendingDecision: 'نیازمند تصمیم',
    };
    expect(labels.keys, OccurrenceStatus.values);
    for (final entry in labels.entries) {
      expect(occurrenceStatusLabel(entry.key), entry.value);
      expect(calendarStatusLabel(entry.key), entry.value);
    }
  });
}
