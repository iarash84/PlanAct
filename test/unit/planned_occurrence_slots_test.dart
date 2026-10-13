import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/scheduling/domain/occurrence.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';
import 'package:shamsi_date/shamsi_date.dart';

LocalDate _jalali(int year, int month, int day) {
  final g = Jalali(year, month, day).toGregorian();
  return LocalDate(g.year, g.month, g.day);
}

void main() {
  const generator = OccurrenceGenerator();
  ScheduleDefinition monthly({int? count, LocalDate? end}) =>
      ScheduleDefinition.create(
        cycleId: StableId.generate(),
        mode: count != null
            ? ScheduleMode.fixedCount
            : end != null
            ? ScheduleMode.fixedDateRangeRecurring
            : ScheduleMode.openEndedRecurring,
        timeSemantics: TimeSemantics.allDayLocalDate,
        startDate: LocalDate(2026, 1, 19),
        recurrenceRule: RecurrenceRule(
          frequency: RecurrenceFrequency.monthly,
          dayOfMonth: 19,
        ),
        occurrenceCount: count,
        endDate: end,
        generationHorizonDays: 90,
      );
  List<PlannedOccurrenceSlot> month(ScheduleDefinition schedule, int index) {
    final start = LocalDate.fromDateTime(DateTime.utc(2026, 1 + index, 1));
    final end = LocalDate.fromDateTime(DateTime.utc(2026, 2 + index, 1));
    return generator.plannedSlots(
      schedule: schedule,
      start: start,
      endExclusive: end,
      scheduleFingerprint: 'durable-token',
    );
  }

  for (final count in [12, 60]) {
    test(
      '$count monthly slots, no extra slot, independent of horizon/rows',
      () {
        final schedule = monthly(count: count);
        final all = [for (var i = 0; i <= count; i++) ...month(schedule, i)];
        expect(all, hasLength(count));
        expect(month(schedule, count - 1), hasLength(1));
        expect(month(schedule, count), isEmpty);
        expect(all.last.scheduleId, schedule.id);
        expect(all.last.cycleId, schedule.cycleId);
        expect(all.last.scheduleFingerprint, 'durable-token');
        expect(all.last.scheduledAt, all.last.date);
        expect(
          generator.generate(
            schedule: schedule,
            through: LocalDate(2035, 1, 1),
          ),
          hasLength(4),
        );
      },
    );
  }

  test('inclusive schedule end, half-open query end and 1–31 bounds', () {
    final schedule = monthly(end: LocalDate(2026, 12, 19));
    expect(month(schedule, 11), hasLength(1));
    expect(month(schedule, 12), isEmpty);
    expect(
      generator.plannedSlots(
        schedule: schedule,
        start: LocalDate(2026, 12, 1),
        endExclusive: LocalDate(2026, 12, 19),
        scheduleFingerprint: 'x',
      ),
      isEmpty,
    );
    for (final days in [0, 32, -1]) {
      expect(
        () => generator.plannedSlots(
          schedule: schedule,
          start: LocalDate(2026, 1, 1),
          endExclusive: LocalDate(2026, 1, 1).addDays(days),
          scheduleFingerprint: 'x',
        ),
        throwsArgumentError,
      );
    }
  });

  test('Jalali yearly Esfand 30 clamps then returns to original anchor', () {
    final schedule = ScheduleDefinition.create(
      cycleId: StableId.generate(),
      mode: ScheduleMode.fixedCount,
      timeSemantics: TimeSemantics.allDayLocalDate,
      startDate: _jalali(1399, 12, 30),
      occurrenceCount: 6,
      recurrenceRule: RecurrenceRule(
        frequency: RecurrenceFrequency.yearly,
        calendar: RecurrenceCalendar.jalali,
        monthOfYear: 12,
        dayOfMonth: 30,
        monthEndPolicy: MonthEndPolicy.clampToLastDay,
      ),
    );
    for (var year = 1399; year <= 1404; year++) {
      final expected = _jalali(year, 12, Jalali(year, 12, 1).monthLength);
      final slots = generator.plannedSlots(
        schedule: schedule,
        start: expected,
        endExclusive: expected.addDays(1),
        scheduleFingerprint: 'x',
      );
      expect(slots.single.date, expected);
    }
    expect(_jalali(1403, 12, 30), isNot(_jalali(1403, 12, 29)));
  });

  test('legacy yearly leap day skips rather than adopting clamp', () {
    final schedule = ScheduleDefinition.create(
      cycleId: StableId.generate(),
      mode: ScheduleMode.openEndedRecurring,
      timeSemantics: TimeSemantics.allDayLocalDate,
      startDate: LocalDate(2024, 2, 29),
      recurrenceRule: RecurrenceRule(
        frequency: RecurrenceFrequency.yearly,
        legacyCalendarSemantics: true,
        monthEndPolicy: MonthEndPolicy.clampToLastDay,
      ),
    );
    expect(
      generator.plannedSlots(
        schedule: schedule,
        start: LocalDate(2025, 2, 1),
        endExclusive: LocalDate(2025, 3, 1),
        scheduleFingerprint: 'x',
      ),
      isEmpty,
    );
    expect(
      generator
          .plannedSlots(
            schedule: schedule,
            start: LocalDate(2028, 2, 1),
            endExclusive: LocalDate(2028, 3, 1),
            scheduleFingerprint: 'x',
          )
          .single
          .date,
      LocalDate(2028, 2, 29),
    );
  });
}
