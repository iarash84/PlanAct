import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/scheduling/domain/occurrence.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';
import 'package:shamsi_date/shamsi_date.dart';

ScheduleDefinition schedule(
  RecurrenceRule rule, {
  LocalDate? start,
  int? count,
}) => ScheduleDefinition.create(
  cycleId: StableId.generate(),
  mode: count == null
      ? ScheduleMode.openEndedRecurring
      : ScheduleMode.fixedCount,
  timeSemantics: TimeSemantics.allDayLocalDate,
  startDate: start ?? LocalDate(1900, 1, 31),
  recurrenceRule: rule,
  occurrenceCount: count,
  generationHorizonDays: 400,
);

List<LocalDate> dates(ScheduleDefinition s, LocalDate from, LocalDate to) =>
    const OccurrenceGenerator()
        .generate(schedule: s, windowStart: from, through: to)
        .map((o) => o.currentScheduledAt as LocalDate)
        .toList();

void main() {
  test(
    'daily far-future window seeks and count terminates by original slots',
    () {
      final s = schedule(
        RecurrenceRule(frequency: RecurrenceFrequency.daily, interval: 3),
        start: LocalDate(1, 1, 1),
      );
      final from = LocalDate(9000, 1, 1);
      final elapsed = from
          .toUtcDateForCalculation()
          .difference(s.startDate.toUtcDateForCalculation())
          .inDays;
      final expected = s.startDate.addDays(((elapsed + 2) ~/ 3) * 3);
      final watch = Stopwatch()..start();
      for (var i = 0; i < 100; i++) {
        expect(dates(s, from, from.addDays(10)).first, expected);
      }
      watch.stop();
      // Generous host-only regression guard, not a reference-device release budget.
      expect(watch.elapsedMilliseconds, lessThan(2000));
      final finite = schedule(
        s.recurrenceRule!,
        start: s.startDate,
        count: 100000,
      );
      expect(dates(finite, from, from.addDays(10)), isEmpty);
    },
  );

  test(
    'weekly interval count uses start-relative weeks with multiple weekdays',
    () {
      final s = schedule(
        RecurrenceRule(
          frequency: RecurrenceFrequency.weekly,
          interval: 2,
          weekdays: {DateTime.monday, DateTime.friday},
        ),
        start: LocalDate(2026, 1, 7),
        count: 5,
      ); // Wednesday, not week boundary
      expect(dates(s, LocalDate(2026, 1, 20), LocalDate(2026, 3, 1)), [
        LocalDate(2026, 1, 23),
        LocalDate(2026, 1, 26),
        LocalDate(2026, 2, 6),
      ]);
    },
  );

  test('monthly clamp retains day31 after short month and long prefix', () {
    final s = schedule(
      RecurrenceRule(
        frequency: RecurrenceFrequency.monthly,
        dayOfMonth: 31,
        monthEndPolicy: MonthEndPolicy.clampToLastDay,
      ),
      count: 1515,
    );
    expect(dates(s, LocalDate(2026, 2, 1), LocalDate(2026, 5, 31)), [
      LocalDate(2026, 2, 28),
      LocalDate(2026, 3, 31),
    ]);
  });

  test('skip counts actual matching slots not invalid month candidates', () {
    final s = schedule(
      RecurrenceRule(frequency: RecurrenceFrequency.monthly, dayOfMonth: 31),
      start: LocalDate(2025, 1, 31),
      count: 4,
    );
    expect(dates(s, LocalDate(2025, 4, 1), LocalDate(2025, 8, 31)), [
      LocalDate(2025, 5, 31),
      LocalDate(2025, 7, 31),
    ]);
  });

  test(
    'yearly anchor month independent of start month is not skipped on seek',
    () {
      final s = schedule(
        RecurrenceRule(
          frequency: RecurrenceFrequency.yearly,
          monthOfYear: 12,
          dayOfMonth: 19,
        ),
        start: LocalDate(2020, 1, 1),
      );
      expect(dates(s, LocalDate(2026, 6, 1), LocalDate(2027, 1, 1)), [
        LocalDate(2026, 12, 19),
      ]);
    },
  );

  test('Jalali yearly Esfand clamp returns original leap anchor', () {
    LocalDate local(int year, int month, int day) {
      final g = Jalali(year, month, day).toGregorian();
      return LocalDate(g.year, g.month, g.day);
    }

    final s = schedule(
      RecurrenceRule(
        frequency: RecurrenceFrequency.yearly,
        calendar: RecurrenceCalendar.jalali,
        monthOfYear: 12,
        dayOfMonth: 30,
        monthEndPolicy: MonthEndPolicy.clampToLastDay,
      ),
      start: local(1399, 12, 30),
    );
    for (final year in [1403, 1404, 1405]) {
      final expected = local(year, 12, Jalali(year, 12, 1).monthLength);
      expect(
        dates(
          s,
          local(year, 1, 1),
          local(year, 12, Jalali(year, 12, 1).monthLength),
        ),
        [expected],
      );
    }
  });

  test('legacy null-day monthly retains all days and historical count', () {
    final s = schedule(
      RecurrenceRule(
        frequency: RecurrenceFrequency.monthly,
        interval: 2,
        legacyCalendarSemantics: true,
      ),
      start: LocalDate(2025, 1, 30),
      count: 5,
    );
    expect(dates(s, LocalDate(2025, 3, 1), LocalDate(2025, 4, 1)), [
      LocalDate(2025, 3, 1),
      LocalDate(2025, 3, 2),
      LocalDate(2025, 3, 3),
    ]);
  });

  test(
    'legacy yearly leap-day skips not clamps and counts only real dates',
    () {
      final s = schedule(
        RecurrenceRule(
          frequency: RecurrenceFrequency.yearly,
          legacyCalendarSemantics: true,
          dayOfMonth: 1,
          monthOfYear: 1,
          monthEndPolicy: MonthEndPolicy.clampToLastDay,
        ),
        start: LocalDate(2000, 2, 29),
        count: 7,
      );
      expect(dates(s, LocalDate(2024, 1, 1), LocalDate(2025, 1, 1)), [
        LocalDate(2024, 2, 29),
      ]);
      expect(dates(s, LocalDate(2028, 1, 1), LocalDate(2029, 1, 1)), isEmpty);
    },
  );
}
