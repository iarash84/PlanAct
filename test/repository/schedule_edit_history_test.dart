import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/actuals/application/actual_use_cases.dart';
import 'package:planact/features/actuals/domain/actual.dart';
import 'package:planact/features/scheduling/domain/occurrence.dart';

void main() {
  test(
    'reopening hides resolved projection but retains both historical results',
    () {
      final occurrence = Occurrence(
        id: StableId.generate(),
        cycleId: StableId.generate(),
        scheduleDefinitionId: StableId.generate(),
        occurrenceKey: 'history',
        originalScheduledAt: DateTime(2027, 1, 2, 18),
        currentScheduledAt: DateTime(2027, 1, 3, 19),
        status: OccurrenceStatus.rescheduled,
        isManualOverride: true,
      );
      final time = DateTime.utc(2027, 1, 2);
      final history = [
        Actual(
          id: StableId.generate(),
          occurrenceId: occurrence.id,
          outcome: ActualOutcome.completed,
          recordedAt: time,
        ),
        Actual(
          id: StableId.generate(),
          occurrenceId: occurrence.id,
          outcome: ActualOutcome.reopened,
          recordedAt: time,
        ),
      ];
      final projection = const HistoryProjection()
          .build(occurrences: [occurrence], actuals: history)
          .single;
      expect(projection.isResolved, isFalse);
      expect(projection.plannedAt, occurrence.currentScheduledAt);
      expect(history, hasLength(2));
      expect(history.first.outcome, ActualOutcome.completed);
      expect(
        statusForActual(
          occurrence.withStatus(OccurrenceStatus.completed),
          ActualOutcome.reopened,
        ),
        OccurrenceStatus.rescheduled,
      );
    },
  );
}
