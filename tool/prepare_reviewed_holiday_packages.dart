import 'dart:convert';
import 'dart:io';

import 'package:planact/core/time/jalali_date.dart';
import 'package:planact/features/calendar/domain/annual_holiday_data.dart';

/// Converts the pinned time.ir fact format. Other publishers can author a v1
/// payload directly. This does not fetch, predict, approve or sign source data.
Map<String, dynamic> prepareReviewedAnnual(
  Map<String, dynamic> raw,
  List<dynamic> events, {
  required int year,
  required int revision,
}) {
  if (raw['year'] != year) throw const FormatException('Wrong source year');
  final rows = raw['holidays'] as List;
  final holidays = <Map<String, Object>>[];
  for (final row in rows) {
    if (row['jalali_year'] != year || ![0, 2].contains(row['base'])) {
      throw const FormatException('Unexpected published row');
    }
    final month = row['jalali_month'] as int;
    final day = row['jalali_day'] as int;
    final gregorian = JalaliDate(year, month, day).toDateTime();
    if (gregorian.year != row['gregorian_year'] ||
        gregorian.month != row['gregorian_month'] ||
        gregorian.day != row['gregorian_day']) {
      throw const FormatException('Published calendars disagree');
    }
    final fixed = row['base'] == 0;
    final matches = events
        .where(
          (event) =>
              event['calendar'] == (fixed ? 'Persian' : 'Hijri') &&
              event['month'] == row[fixed ? 'jalali_month' : 'hijri_month'] &&
              ((event['rule'] == 'end of month' &&
                      [29, 30].contains(row['hijri_day'])) ||
                  event['day'] == row[fixed ? 'jalali_day' : 'hijri_day']),
        )
        .toList();
    if (matches.isEmpty) {
      throw const FormatException('Unknown published occasion');
    }
    for (final event in matches) {
      holidays.add({
        'month': month,
        'day': day,
        'title': event['title'] as String,
        'kind': fixed ? 'officialFixed' : 'officialVariable',
      });
    }
  }
  final payload = <String, dynamic>{
    'year': year,
    'revision': revision,
    'source': raw['source'],
    'provenance': {
      'retrievedUtc': raw['retrieved_utc'],
      'retrievalMethod': raw['retrieval_method'],
      'months': [
        for (final month in raw['months'] as List)
          {
            'month': month['month'],
            'sourceUrl': month['source_url'],
            'responseSha256': month['response_sha256'],
          },
      ],
    },
    'months': [
      for (final month in raw['months'] as List)
        {
          'month': month['month'],
          'dayCount': month['day_count'],
          'officialDays': month['official_days'],
        },
    ],
    'holidays': holidays,
  };
  AnnualHolidayData.parse(jsonEncode(payload));
  return payload;
}

void main(List<String> args) {
  try {
    if (args.length != 4) {
      throw const FormatException(
        'Usage: prepare_reviewed_holiday_packages.dart RAW_JSON YEAR REVISION OUTPUT',
      );
    }
    final root = File.fromUri(Platform.script).parent.parent;
    final output = File(args[3]);
    if (output.existsSync()) {
      throw StateError('Refusing to overwrite reviewed data');
    }
    final payload = prepareReviewedAnnual(
      jsonDecode(File(args[0]).readAsStringSync()) as Map<String, dynamic>,
      jsonDecode(
        File('${root.path}/third_party/iranian_holidays/events.json')
            .readAsStringSync(),
      ) as List,
      year: int.parse(args[1]),
      revision: int.parse(args[2]),
    );
    output.parent.createSync(recursive: true);
    output.writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(payload)}\n',
    );
    stdout.writeln(
      'Prepared reviewed payload ${payload['year']} r${payload['revision']}; sign separately.',
    );
  } catch (error) {
    stderr.writeln('Annual holiday preparation failed: $error');
    exitCode = 1;
  }
}
