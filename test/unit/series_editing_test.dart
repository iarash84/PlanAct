import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/scheduling/application/series_editing.dart';
import 'package:planact/features/scheduling/domain/occurrence.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';

void main() {
  final cycleId = StableId.generate(timestamp: DateTime.utc(2026, 1, 1));
  final schedule = ScheduleDefinition.create(
    cycleId: cycleId,
    mode: ScheduleMode.openEndedRecurring,
    timeSemantics: TimeSemantics.allDayLocalDate,
    startDate: LocalDate(2026, 1, 1),
    recurrenceRule: RecurrenceRule(frequency: RecurrenceFrequency.daily),
  );
  final occurrences = const OccurrenceGenerator().generate(
    schedule: schedule,
    through: LocalDate(2026, 1, 3),
  );

  test('only-this creates a historical reschedule override', () {
    final result = const SeriesEditor().editOccurrence(
      schedule: schedule,
      occurrence: occurrences.first,
      newScheduledAt: LocalDate(2026, 1, 10),
      scope: SeriesEditScope.onlyThis,
    );

    expect(result.updatedOccurrence?.status, OccurrenceStatus.rescheduled);
    expect(
      result.updatedOccurrence?.originalScheduledAt,
      LocalDate(2026, 1, 1),
    );
    expect(
      result.updatedOccurrence?.currentScheduledAt,
      LocalDate(2026, 1, 10),
    );
  });

  test('this-and-following creates a new schedule version', () {
    final result = const SeriesEditor().editOccurrence(
      schedule: schedule,
      occurrence: occurrences[1],
      newScheduledAt: LocalDate(2026, 1, 20),
      scope: SeriesEditScope.thisAndFollowing,
      followingRecurrenceRule: RecurrenceRule(
        frequency: RecurrenceFrequency.weekly,
        weekdays: {DateTime.saturday},
      ),
    );

    expect(result.newSchedule?.version, 2);
    expect(result.newSchedule?.effectiveFrom, LocalDate(2026, 1, 2));
  });

  test('entire active cycle does not mutate historical occurrences', () {
    final completed = occurrences.first.withStatus(OccurrenceStatus.completed);
    final result = const SeriesEditor().editOccurrence(
      schedule: schedule,
      occurrence: occurrences[1],
      newScheduledAt: LocalDate(2026, 1, 20),
      scope: SeriesEditScope.entireActiveCycle,
      occurrences: [completed, occurrences[1], occurrences[2]],
    );

    expect(result.occurrences, hasLength(2));
    expect(result.occurrences!.every((item) => item.isManualOverride), isTrue);
    expect(completed.currentScheduledAt, LocalDate(2026, 1, 1));
  });
}
