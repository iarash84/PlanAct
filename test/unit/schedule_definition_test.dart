import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/errors/app_error.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';

void main() {
  final cycleId = StableId.generate(timestamp: DateTime.utc(2026, 1, 1));

  test('keeps an all-day local date without manufacturing an instant', () {
    final schedule = ScheduleDefinition.create(
      cycleId: cycleId,
      mode: ScheduleMode.oneOff,
      timeSemantics: TimeSemantics.allDayLocalDate,
      startDate: LocalDate(2026, 3, 21),
    );

    expect(schedule.startDate, LocalDate(2026, 3, 21));
    expect(schedule.fixedInstant, isNull);
    expect(schedule.localTime, isNull);
  });

  test('requires timezone context for floating local time', () {
    expect(
      () => ScheduleDefinition.create(
        cycleId: cycleId,
        mode: ScheduleMode.oneOff,
        timeSemantics: TimeSemantics.floatingLocalTime,
        startDate: LocalDate(2026, 3, 21),
        localTime: LocalTime(18, 0),
      ),
      throwsA(isA<ValidationError>()),
    );
  });

  test('stores fixed instants in UTC', () {
    final schedule = ScheduleDefinition.create(
      cycleId: cycleId,
      mode: ScheduleMode.oneOff,
      timeSemantics: TimeSemantics.fixedInstant,
      startDate: LocalDate(2026, 3, 21),
      fixedInstant: DateTime.parse('2026-03-21T18:00:00+03:30'),
    );

    expect(schedule.fixedInstant, DateTime.utc(2026, 3, 21, 14, 30));
  });

  test('creates an explicit next schedule version', () {
    final schedule = ScheduleDefinition.create(
      cycleId: cycleId,
      mode: ScheduleMode.openEndedRecurring,
      timeSemantics: TimeSemantics.floatingLocalTime,
      startDate: LocalDate(2026, 3, 21),
      localTime: LocalTime(18, 0),
      timeZoneId: 'Asia/Tehran',
      recurrenceRule: RecurrenceRule(
        frequency: RecurrenceFrequency.weekly,
        weekdays: {DateTime.saturday},
      ),
    );

    final next = schedule.nextVersion(
      effectiveFrom: LocalDate(2026, 4, 18),
      localTime: LocalTime(19, 0),
    );

    expect(next.version, 2);
    expect(next.effectiveFrom, LocalDate(2026, 4, 18));
    expect(next.localTime, LocalTime(19, 0));
    expect(next.id, isNot(schedule.id));
  });
}
