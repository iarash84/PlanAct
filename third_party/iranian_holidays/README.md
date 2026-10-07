# Iranian holiday source snapshots

The upstream events and month-start snapshots are CC0-1.0; their dedication is in [LICENSE](LICENSE). This does not claim a CC0 license for time.ir.
No converter implementation or GPL source code is copied.

## Provenance

- Events: https://github.com/persian-calendar/events at commit `3bfbcc5b667765691784b55b58d8a385217d96d9`, events.json. The local [events.json](events.json) contains only Iranian public holidays (10 Persian fixed event rows and 18 Hijri event rows), preserving upstream metadata. This community-maintained transcription cites University of Tehran annual calendars; it is not itself an official authority.
- Month starts: https://github.com/roozbehp/qamari at commit `575d275ef169c0a18012506d473ba1008a1c10d0`, sources/calendar-center.txt. The local [month_starts.json](month_starts.json) is a lossless projection of the Gregorian month-start dates for Hijri 1442/1 through 1447/10. That source records calendar-center published annual calendars. The consolidated/observed table is deliberately NOT used: observed moon sightings can differ from previously published calendars.
- Upstream events COPYING and qamari LICENSE are both CC0.

## Coverage and refresh

Provider version: iran-1400-1405-v2. Complete public lookup covers Jalali 1400–1405, inclusive. Extra source rows outside that interval are not exposed as complete annual coverage. Fixed current rules are exposed from 1400 onward; future variable holidays are unknown, not predicted. No historical claims are made before 1400.

### Published 1405 calendar facts

[time_ir_1405.json](time_ir_1405.json) records minimal date facts retrieved from https://www.time.ir/ on 2026-10-06, using the site's public monthly calendar action. Each of the twelve monthly responses includes its underlying public source URL and SHA-256 of the received response. All 365 enabled days were checked, and official day markers exactly matched official event dates. The snapshot has ten fixed and nineteen lunar date records (including two Eid cycles). Existing CC0 event titles are reused; the combined Prophet/Imam Sadiq birthday expands into two existing reasons.

This is a secondary published-calendar source, not a directly retrieved official PDF or observed-moon prediction. The previously inaccessible official PDF is not claimed as independently verified. No time.ir JavaScript, HTML, artwork, descriptions, editorial titles or database dump is redistributed; only the minimal factual date mapping and provenance are retained. The CC0 notice applies only to the original upstream snapshots, not the website or its content. StarCalendar/AGPL implementation and datasets were not imported.

Refresh requires explicit review of a published source, a pinned source revision, updated snapshots/coverage/version and regression tests. Generate using [the offline generator](../../tool/generate_iranian_holidays.py), then apply the repository Dart formatter to [the generated data](../../lib/features/calendar/domain/iranian_holiday_data.dart). Running both steps must reproduce that file without differences. Neither generation nor normal application use needs a network connection.

The last day of Safar is computed from adjacent published month starts, not hard-coded to day 30. Special/temporary closures are not inferred from recurring holidays; there are no real special closures bundled in this revision.
