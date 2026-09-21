import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/scheduling/domain/calendar_policies.dart';
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

  test('pause excludes future occurrences but preserves history', () {
    final generated = const OccurrenceGenerator().generate(
      schedule: schedule,
      through: LocalDate(2026, 1, 3),
    );
    final completed = generated.first.withStatus(OccurrenceStatus.completed);
    final filtered = const CalendarPolicies().excludePausedFutureOccurrences(
      occurrences: [completed, generated[1], generated[2]],
      pauses: [
        PauseWindow(start: LocalDate(2026, 1, 2), end: LocalDate(2026, 1, 3)),
      ],
    );

    expect(filtered, hasLength(1));
    expect(filtered.single.status, OccurrenceStatus.completed);
  });

  test('detects local-date and fixed-instant conflicts', () {
    final allDay = const OccurrenceGenerator()
        .generate(schedule: schedule, through: LocalDate(2026, 1, 1))
        .single;
    final sameDate = Occurrence(
      id: StableId.generate(),
      cycleId: cycleId,
      scheduleDefinitionId: schedule.id,
      occurrenceKey: 'other',
      originalScheduledAt: LocalDate(2026, 1, 1),
      currentScheduledAt: LocalDate(2026, 1, 1),
    );

    final conflicts = const CalendarPolicies().findConflicts([
      allDay,
      sameDate,
    ]);
    expect(conflicts.single.kind, ConflictKind.localDate);
  });
}
