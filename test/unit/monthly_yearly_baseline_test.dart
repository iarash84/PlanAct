import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/time/jalali_date.dart';
import 'package:planact/features/scheduling/domain/occurrence.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';

LocalDate date(int year, int month, int day) =>
    LocalDate.fromDateTime(JalaliDate(year, month, day).toDateTime());
ScheduleDefinition schedule({
  RecurrenceCalendar calendar = RecurrenceCalendar.jalali,
  RecurrenceFrequency frequency = RecurrenceFrequency.monthly,
  int year = 1405,
  int month = 7,
  int day = 19,
  int? count,
  LocalDate? end,
  int interval = 1,
}) => ScheduleDefinition.create(
  cycleId: StableId.generate(),
  mode: count != null
      ? ScheduleMode.fixedCount
      : end != null
      ? ScheduleMode.fixedDateRangeRecurring
      : ScheduleMode.openEndedRecurring,
  timeSemantics: TimeSemantics.allDayLocalDate,
  startDate: date(year, month, day),
  recurrenceRule: RecurrenceRule(
    frequency: frequency,
    calendar: calendar,
    interval: interval,
    dayOfMonth: calendar == RecurrenceCalendar.jalali
        ? day
        : date(year, month, day).day,
    monthOfYear: calendar == RecurrenceCalendar.jalali
        ? month
        : date(year, month, day).month,
    monthEndPolicy: MonthEndPolicy.clampToLastDay,
  ),
  occurrenceCount: count,
  endDate: end,
  generationHorizonDays: 90,
);
List<JalaliDate> generate(
  ScheduleDefinition value,
  LocalDate from,
  LocalDate through,
) => const OccurrenceGenerator()
    .generate(schedule: value, windowStart: from, through: through)
    .map((o) {
      final d = o.currentScheduledAt as LocalDate;
      return JalaliDate.fromDateTime(DateTime(d.year, d.month, d.day));
    })
    .toList();
void main() {
  test(
    'legacy Gregorian interpretation still reproduces Persian day19 drift',
    () {
      final value = schedule(calendar: RecurrenceCalendar.gregorian);
      final days = generate(value, value.startDate, date(1406, 1, 1));
      expect(days.first.day, 19);
      expect(days.any((d) => d.day != 19), isTrue);
      expect(days.length, 3);
    },
  );
  test(
    'Persian monthly day19 is stable and rolling horizon is not termination',
    () {
      final value = schedule();
      expect(generate(value, date(1405, 7, 19), date(1405, 10, 19)), [
        const JalaliDate(1405, 7, 19),
        const JalaliDate(1405, 8, 19),
        const JalaliDate(1405, 9, 19),
        const JalaliDate(1405, 10, 19),
      ]);
      expect(
        generate(value, date(1406, 7, 19), date(1406, 10, 19)).first,
        const JalaliDate(1406, 7, 19),
      );
    },
  );
  test('yearly19Mehr remains 1406 and1407 independently of display', () {
    final value = schedule(frequency: RecurrenceFrequency.yearly);
    expect(generate(value, date(1406, 7, 1), date(1406, 9, 1)), [
      const JalaliDate(1406, 7, 19),
    ]);
    expect(generate(value, date(1407, 7, 1), date(1407, 9, 1)), [
      const JalaliDate(1407, 7, 19),
    ]);
  });
  test('Esfand30 clamps same month without losing leap anchor', () {
    final value = schedule(
      frequency: RecurrenceFrequency.yearly,
      year: 1403,
      month: 12,
      day: 30,
    );
    expect(generate(value, date(1404, 12, 1), date(1405, 2, 1)), [
      const JalaliDate(1404, 12, 29),
    ]);
    expect(generate(value, date(1408, 12, 1), date(1409, 2, 1)), [
      const JalaliDate(1408, 12, 30),
    ]);
    expect(value.recurrenceRule!.dayOfMonth, 30);
  });
  test('count and end inclusive remain global across rolling windows', () {
    final counted = schedule(count: 5);
    expect(generate(counted, date(1405, 11, 1), date(1406, 2, 1)), [
      const JalaliDate(1405, 11, 19),
    ]);
    expect(generate(counted, date(1406, 7, 1), date(1406, 9, 1)), isEmpty);
    final ended = schedule(end: date(1405, 9, 19));
    expect(generate(ended, date(1405, 9, 1), date(1405, 11, 1)), [
      const JalaliDate(1405, 9, 19),
    ]);
  });
  test('monthly interval phase survives rolling window', () {
    final value = schedule(interval: 2);
    expect(generate(value, date(1406, 7, 1), date(1406, 9, 30)), [
      const JalaliDate(1406, 7, 19),
      const JalaliDate(1406, 9, 19),
    ]);
  });
}
