import 'package:planact/core/time/jalali_date.dart';
import 'package:planact/features/scheduling/domain/occurrence.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';

/// Read-only range contract; does not generate or mutate occurrences.
abstract interface class CalendarRangeRepository {
  Future<Map<String, List<Occurrence>>> loadWeek(LocalDate start);
}

abstract final class WeekTimeline {
  static JalaliDate startOfWeek(JalaliDate date) =>
      date.addDays(1 - date.weekDay);
  static List<JalaliDate> dates(JalaliDate date) =>
      List.generate(7, (i) => startOfWeek(date).addDays(i));
  static LocalDate localDate(JalaliDate date) {
    final value = date.toDateTime();
    return LocalDate(value.year, value.month, value.day);
  }

  static DateTime displayDate(Object value) => switch (value) {
    DateTime date => date.isUtc ? date.toLocal() : date,
    LocalDate date => DateTime(date.year, date.month, date.day),
    _ => throw ArgumentError('Unsupported scheduled value'),
  };
  static double minute(DateTime date) =>
      date.hour * 60 + date.minute.toDouble();
  static double initialMinute(JalaliDate week, DateTime now) =>
      startOfWeek(JalaliDate.fromDateTime(now)) == startOfWeek(week)
      ? (minute(now) - 120).clamp(0, 1440)
      : 480;
  static double? indicatorMinute(JalaliDate day, DateTime now) =>
      day == JalaliDate.fromDateTime(now) ? minute(now) : null;
}

/// Geometry input only. Production supplies null ends: no duration is invented.
class TimelineSpan {
  const TimelineSpan(this.id, this.start, [this.end]);
  final String id;
  final DateTime start;
  final DateTime? end;
}

class TimelineSegment {
  const TimelineSegment(this.id, this.day, this.startMinute, this.endMinute);
  final String id;
  final JalaliDate day;
  final double startMinute;
  final double? endMinute;
}

List<TimelineSegment> segmentTimelineSpan(TimelineSpan span) {
  final start = span.start.isUtc ? span.start.toLocal() : span.start;
  final end = span.end?.isUtc == true ? span.end!.toLocal() : span.end;
  if (end == null) {
    return [
      TimelineSegment(
        span.id,
        JalaliDate.fromDateTime(start),
        WeekTimeline.minute(start),
        null,
      ),
    ];
  }
  if (!end.isAfter(start)) throw ArgumentError('End must follow start');
  final result = <TimelineSegment>[];
  var cursor = start;
  while (cursor.isBefore(end)) {
    final midnight = DateTime(cursor.year, cursor.month, cursor.day + 1);
    final stop = end.isBefore(midnight) ? end : midnight;
    result.add(
      TimelineSegment(
        span.id,
        JalaliDate.fromDateTime(cursor),
        WeekTimeline.minute(cursor),
        stop == midnight ? 1440 : WeekTimeline.minute(stop),
      ),
    );
    cursor = stop;
  }
  return result;
}

class TimelineLane {
  const TimelineLane(this.segment, this.lane, this.laneCount);
  final TimelineSegment segment;
  final int lane;
  final int laneCount;
}

/// Half-open explicit intervals; visual point footprints are only hit geometry.
/// Connected overlap groups share lane widths, including groups of >2 items.
List<TimelineLane> layoutTimelineLanes(
  List<TimelineSegment> input, {
  double pointFootprintMinutes = 48,
}) {
  final sorted = [...input]
    ..sort((a, b) {
      final date = a.day.compareTo(b.day);
      if (date != 0) return date;
      final time = a.startMinute.compareTo(b.startMinute);
      return time != 0 ? time : a.id.compareTo(b.id);
    });
  final result = <TimelineLane>[];
  var group = <(TimelineSegment, int)>[];
  var ends = <double>[];
  JalaliDate? day;
  double groupEnd = -1;
  void flush() {
    result.addAll(
      group.map((entry) => TimelineLane(entry.$1, entry.$2, ends.length)),
    );
    group = [];
    ends = [];
    groupEnd = -1;
  }

  for (final segment in sorted) {
    if (day != segment.day || segment.startMinute >= groupEnd) flush();
    day = segment.day;
    final end =
        segment.endMinute ?? segment.startMinute + pointFootprintMinutes;
    var lane = ends.indexWhere((value) => value <= segment.startMinute);
    if (lane < 0) {
      lane = ends.length;
      ends.add(end);
    } else {
      ends[lane] = end;
    }
    group.add((segment, lane));
    if (end > groupEnd) groupEnd = end;
  }
  flush();
  return result;
}
