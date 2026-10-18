import 'dart:convert';

import 'package:planact/core/time/jalali_date.dart';
import 'package:planact/features/calendar/domain/calendar_holiday.dart';

/// The v1 annual payload shared by bundled data and signed imports.
/// Structural completeness does not establish factual source accuracy.
class AnnualHolidayData {
  AnnualHolidayData._(this.year, this.revision, this.source, this.holidays);

  final int year;
  final int revision;
  final String source;
  final List<CalendarHoliday> holidays;

  String get version => '$year-r$revision';

  static AnnualHolidayData parse(String encoded) {
    final data = jsonDecode(encoded) as Map<String, dynamic>;
    final year = data['year'] as int;
    final revision = data['revision'] as int;
    final source = data['source'] as String;
    final uri = Uri.parse(source);
    if (year < 1400 ||
        year > 1600 ||
        revision < 1 ||
        source.trim().isEmpty ||
        source.length > 500 ||
        !uri.hasAbsolutePath ||
        !['https', 'http'].contains(uri.scheme)) {
      throw const FormatException('metadata');
    }
    final months = data['months'] as List;
    if (months.length != 12) throw const FormatException('coverage');
    final markers = <String>{};
    for (var index = 0; index < 12; index++) {
      final month = months[index] as Map<String, dynamic>;
      final length = JalaliDate(year, index + 1, 1).monthLength;
      if (month['month'] != index + 1 || month['dayCount'] != length) {
        throw const FormatException('month');
      }
      final unique = <int>{};
      for (final day in month['officialDays'] as List) {
        if (day is! int || day < 1 || day > length || !unique.add(day)) {
          throw const FormatException('day');
        }
        markers.add('${index + 1}/$day');
      }
    }
    final holidays = <CalendarHoliday>[];
    final dates = <String>{};
    final unique = <String>{};
    final rows = data['holidays'] as List;
    if (rows.isEmpty || rows.length > 200) throw const FormatException('rows');
    for (final value in rows) {
      final row = value as Map<String, dynamic>;
      final month = row['month'] as int;
      final day = row['day'] as int;
      final title = row['title'] as String;
      final kind = switch (row['kind']) {
        'officialFixed' => CalendarHolidayKind.officialFixed,
        'officialVariable' => CalendarHolidayKind.officialVariable,
        _ => throw const FormatException('kind'),
      };
      if (month < 1 ||
          month > 12 ||
          day < 1 ||
          day > JalaliDate(year, month, 1).monthLength ||
          title.trim().isEmpty ||
          title.length > 180 ||
          title.runes.any(
            (r) =>
                r < 32 ||
                (r >= 0x202a && r <= 0x202e) ||
                (r >= 0x2066 && r <= 0x2069),
          ) ||
          !unique.add('$month/$day/${kind.name}/$title')) {
        throw const FormatException('holiday');
      }
      dates.add('$month/$day');
      holidays.add(
        CalendarHoliday(
          date: JalaliDate(year, month, day),
          title: title,
          kind: kind,
          source: source,
          version: '$year-r$revision',
        ),
      );
    }
    if (markers.length != dates.length || !markers.containsAll(dates)) {
      throw const FormatException('markers');
    }
    return AnnualHolidayData._(
      year,
      revision,
      source,
      List.unmodifiable(holidays),
    );
  }
}
