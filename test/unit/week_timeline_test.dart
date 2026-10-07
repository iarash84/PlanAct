import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/time/jalali_date.dart';
import 'package:planact/features/calendar/application/week_timeline.dart';

void main() {
  test('Saturday weeks cross Jalali month/year and leap boundaries', () {
    for (final date in [
      JalaliDate(1403, 12, 30),
      JalaliDate(1404, 1, 1),
      JalaliDate(1405, 6, 31),
      JalaliDate(1405, 7, 1),
    ]) {
      final days = WeekTimeline.dates(date);
      expect(days.first.weekDay, 1);
      expect(days.last.weekDay, 7);
      expect(days, contains(date));
      for (var i = 1; i < 7; i++) {
        expect(days[i], days[i - 1].addDays(1));
      }
      expect(WeekTimeline.localDate(date).day, date.toDateTime().day);
    }
    expect(JalaliDate(1403, 12, 30).addDays(1), JalaliDate(1404, 1, 1));
  });
  test('point has no end; explicit duration splits midnight half-open', () {
    final point = segmentTimelineSpan(
      TimelineSpan('p', DateTime(2026, 3, 20, 23, 59)),
    ).single;
    expect(point.startMinute, 1439);
    expect(point.endMinute, isNull);
    final parts = segmentTimelineSpan(
      TimelineSpan(
        'x',
        DateTime(2026, 3, 20, 23, 30),
        DateTime(2026, 3, 22, 1),
      ),
    );
    expect(parts.map((p) => p.startMinute), [1410, 0, 0]);
    expect(parts.map((p) => p.endMinute), [1440, 1440, 60]);
    expect(
      segmentTimelineSpan(
        TimelineSpan('x', DateTime(2026, 3, 20, 23), DateTime(2026, 3, 21)),
      ).length,
      1,
    );
    expect(
      () => segmentTimelineSpan(
        TimelineSpan('bad', DateTime(2026), DateTime(2025)),
      ),
      throwsArgumentError,
    );
  });
  test(
    'three overlap lanes; touching intervals and different days do not overlap',
    () {
      final day = JalaliDate(1405, 1, 1);
      final lanes = layoutTimelineLanes([
        TimelineSegment('a', day, 60, 180),
        TimelineSegment('b', day, 90, 150),
        TimelineSegment('c', day, 100, 120),
        TimelineSegment('d', day, 180, 200),
        TimelineSegment('e', day.addDays(1), 100, 120),
      ]);
      expect(lanes.take(3).map((x) => x.lane).toSet(), {0, 1, 2});
      expect(lanes.take(3).map((x) => x.laneCount), [3, 3, 3]);
      expect(lanes[3].laneCount, 1);
      expect(lanes[4].laneCount, 1);
      expect(
        layoutTimelineLanes([
          TimelineSegment('a', day, 0, null),
          TimelineSegment('b', day, 10, null),
        ], pointFootprintMinutes: 60).last.lane,
        1,
      );
    },
  );
  test('indicator and initial scrolling are view-only and bounded', () {
    final now = DateTime(2026, 10, 7, 13, 42);
    final day = JalaliDate.fromDateTime(now);
    expect(WeekTimeline.indicatorMinute(day, now), 822);
    expect(WeekTimeline.indicatorMinute(day.addDays(1), now), isNull);
    expect(WeekTimeline.initialMinute(day, now), 702);
    expect(WeekTimeline.initialMinute(day.addDays(7), now), 480);
    expect(WeekTimeline.initialMinute(day, DateTime(2026, 10, 7, 1)), 0);
  });
}
