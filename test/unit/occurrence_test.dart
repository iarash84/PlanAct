import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/errors/app_error.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/scheduling/domain/occurrence.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';

void main() {
  final cycleId = StableId.generate(timestamp: DateTime.utc(2026, 1, 1));

  test('generates bounded and idempotent weekly occurrences', () {
    final schedule = ScheduleDefinition.create(
      cycleId: cycleId,
      mode: ScheduleMode.openEndedRecurring,
      timeSemantics: TimeSemantics.allDayLocalDate,
      startDate: LocalDate(2026, 1, 3),
      recurrenceRule: RecurrenceRule(
        frequency: RecurrenceFrequency.weekly,
        weekdays: {DateTime.saturday},
      ),
      generationHorizonDays: 20,
    );
    const generator = OccurrenceGenerator();

    final first = generator.generate(
      schedule: schedule,
      through: LocalDate(2026, 3, 1),
    );
    final second = generator.generate(
      schedule: schedule,
      through: LocalDate(2026, 3, 1),
      existing: first,
    );

    expect(first, hasLength(3));
    expect(
      second.map((item) => item.id),
      orderedEquals(first.map((item) => item.id)),
    );
    expect(first.every((item) => item.currentScheduledAt is LocalDate), isTrue);
  });

  test('does not replace a manually rescheduled existing occurrence', () {
    final schedule = ScheduleDefinition.create(
      cycleId: cycleId,
      mode: ScheduleMode.openEndedRecurring,
      timeSemantics: TimeSemantics.allDayLocalDate,
      startDate: LocalDate(2026, 1, 5),
      recurrenceRule: RecurrenceRule(frequency: RecurrenceFrequency.daily),
      generationHorizonDays: 3,
    );
    const generator = OccurrenceGenerator();
    final initial = generator.generate(
      schedule: schedule,
      through: LocalDate(2026, 1, 8),
    );
    final moved = initial.first.reschedule(LocalDate(2026, 1, 10));
    final regenerated = generator.generate(
      schedule: schedule,
      through: LocalDate(2026, 1, 8),
      existing: [moved, ...initial.skip(1)],
    );

    expect(regenerated.first.currentScheduledAt, LocalDate(2026, 1, 10));
    expect(regenerated.first.status, OccurrenceStatus.rescheduled);
  });

  test('preserves non-completed historical outcomes without deleting the occurrence', () {
    final schedule = ScheduleDefinition.create(
      cycleId: cycleId,
      mode: ScheduleMode.oneOff,
      timeSemantics: TimeSemantics.allDayLocalDate,
      startDate: LocalDate(2026, 1, 10),
    );
    final occurrence = const OccurrenceGenerator()
        .generate(schedule: schedule, through: LocalDate(2026, 1, 10))
        .single;

    final cancelled = occurrence.withStatus(OccurrenceStatus.cancelled);
    final deferred = occurrence.withStatus(OccurrenceStatus.deferred);

    expect(cancelled.id, occurrence.id);
    expect(cancelled.originalScheduledAt, occurrence.originalScheduledAt);
    expect(deferred.status, OccurrenceStatus.deferred);
  });

  test('does not rewrite a completed occurrence', () {
    final schedule = ScheduleDefinition.create(
      cycleId: cycleId,
      mode: ScheduleMode.oneOff,
      timeSemantics: TimeSemantics.allDayLocalDate,
      startDate: LocalDate(2026, 1, 10),
    );
    final occurrence = const OccurrenceGenerator()
        .generate(schedule: schedule, through: LocalDate(2026, 1, 10))
        .single
        .withStatus(OccurrenceStatus.completed);

    expect(
      () => occurrence.withStatus(OccurrenceStatus.cancelled),
      throwsA(isA<ValidationError>()),
    );
  });

  test('clamps a monthly day to the last day when policy allows it', () {
    final schedule = ScheduleDefinition.create(
      cycleId: cycleId,
      mode: ScheduleMode.openEndedRecurring,
      timeSemantics: TimeSemantics.allDayLocalDate,
      startDate: LocalDate(2026, 1, 31),
      recurrenceRule: RecurrenceRule(
        frequency: RecurrenceFrequency.monthly,
        dayOfMonth: 31,
        monthEndPolicy: MonthEndPolicy.clampToLastDay,
      ),
      generationHorizonDays: 70,
    );

    final generated = const OccurrenceGenerator().generate(
      schedule: schedule,
      through: LocalDate(2026, 4, 1),
    );

    expect(
      generated.map((item) => (item.currentScheduledAt as LocalDate).day),
      containsAll(<int>[31, 28, 31]),
    );
  });
}
