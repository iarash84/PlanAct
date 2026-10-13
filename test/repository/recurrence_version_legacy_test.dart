import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/database/app_database.dart' hide Occurrence;
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/commitments/data/drift_commitment_plan_repository.dart';
import 'package:planact/features/scheduling/application/extend_recurring_schedules.dart';
import 'package:planact/features/scheduling/domain/occurrence.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

// Acceptance: startup/resume maintenance -> production repository transaction ->
// recurrence slots -> durable occurrence/reminder writes -> reload consumers.
// Old version excludes the next effective date; new version includes it without
// resetting original phase/count. Manual/resolved original slots remain occupied;
// moved current dates do not acquire another slot. Literal old payloads migrate
// from committed v16 declarations, retain Gregorian matching, and infer reminders
// only from unanimous representable evidence. Reopen must preserve all of this.
// No UI, native delivery, concurrency or encrypted backup claims in this file.
const _oldMonthlyNull =
    '{"frequency":2,"interval":2,"weekdays":[],"dayOfMonth":null,"monthEndPolicy":1}';
const _oldMonthly31 =
    '{"frequency":2,"interval":1,"weekdays":[],"dayOfMonth":31,"monthEndPolicy":1}';
// Historically yearly matching used the start month/day, not dayOfMonth or clamp.
const _oldYearly =
    '{"frequency":3,"interval":1,"weekdays":[],"dayOfMonth":15,"monthEndPolicy":1}';

String _date(LocalDate d) => '${d.year}-${d.month}-${d.day}';
String _value(LocalDate d, [int hour = 9]) => 'local:${_date(d)}T$hour:0:0.000';

class _HistoricalFile {
  _HistoricalFile(this.directory, this.file, this.raw);

  final Directory directory;
  final File file;
  final sqlite.Database raw;
  final owner = StableId.generate();
  final cycle = StableId.generate();
  final schedule = StableId.generate();

  static Future<_HistoricalFile> create() async {
    final directory = await Directory.systemTemp.createTemp('recurrence-v16-');
    final file = File('${directory.path}/legacy.sqlite');
    final raw = sqlite.sqlite3.open(file.path);
    final fixture = jsonDecode(
      await File('test/fixtures/backup_schema/fresh-v16.json').readAsString(),
    ) as Map<String, dynamic>;
    final sql = (fixture['sql'] as List).cast<String>();
    for (final statement in [
      ...sql.where((s) => s.startsWith('CREATE TABLE')),
      ...sql.where((s) => !s.startsWith('CREATE TABLE')),
    ]) {
      raw.execute(statement);
    }
    raw.execute('PRAGMA foreign_keys = ON');
    raw.execute('PRAGMA user_version = 16');
    raw.execute("INSERT INTO schema_metadata VALUES ('schema_version', '16')");
    final result = _HistoricalFile(directory, file, raw);
    raw.execute(
      'INSERT INTO commitments(id,title,created_at,status,kind) VALUES (?,?,0,0,1)',
      [result.owner.value, 'قدیمی'],
    );
    raw.execute(
      'INSERT INTO commitment_cycles(id,commitment_id,cycle_type,start_date,consumed_units,completion_rule,status) VALUES (?,?,0,0,0,4,1)',
      [result.cycle.value, result.owner.value],
    );
    return result;
  }

  void addSchedule({
    StableId? id,
    required String payload,
    required LocalDate start,
    LocalDate? effective,
    int version = 1,
    int horizon = 90,
    int? count,
    int hour = 9,
  }) {
    raw.execute(
      'INSERT INTO schedule_definitions(id,cycle_id,mode,time_semantics,start_date,local_time,time_zone_id,recurrence_rule,occurrence_count,version,effective_from,generation_horizon_days) VALUES (?,?,?,0,?,?,?,?,?,?,?,?)',
      [
        (id ?? schedule).value,
        cycle.value,
        count == null ? 1 : 3,
        _date(start),
        '$hour:0',
        'Asia/Tehran',
        payload,
        count,
        version,
        _date(effective ?? start),
        horizon,
      ],
    );
  }

  StableId addOccurrence(
    LocalDate original, {
    LocalDate? current,
    OccurrenceStatus status = OccurrenceStatus.scheduled,
    bool manual = false,
    List<int> offsets = const [],
  }) {
    final id = StableId.generate();
    raw.execute('INSERT INTO occurrences VALUES (?,?,?,?,0,?,?,?,?)', [
      id.value,
      cycle.value,
      schedule.value,
      '${schedule.value}:${_date(original)}',
      _value(original),
      _value(current ?? original),
      status.index,
      manual ? 1 : 0,
    ]);
    for (final offset in offsets) {
      raw.execute(
        'INSERT INTO reminder_rules(id,occurrence_id,anchor,offset_seconds,enabled) VALUES (?,?,0,?,1)',
        [StableId.generate().value, id.value, -offset * 60],
      );
    }
    return id;
  }

  AppDatabase open() {
    expect(raw.select('PRAGMA user_version').single.values.single, 16);
    raw.close();
    return AppDatabase.forTesting(NativeDatabase(file));
  }
}

String _modernRule(int frequency, {int interval = 1, int? day, int? month}) =>
    jsonEncode({
      'formatVersion': 2,
      'calendar': 'gregorian',
      'frequency': frequency,
      'interval': interval,
      'weekdays': <int>[],
      'dayOfMonth': day,
      'monthOfYear': month,
      'monthEndPolicy': 1,
      'generationReminderMinutes': <int>[],
      'generationFinancialExpectation': null,
    });

Future<List<Occurrence>> _occurrences(AppDatabase db, StableId owner) async =>
    (await DriftCommitmentPlanRepository(db).findByCommitmentId(owner))!
        .occurrences;

Future<List<Map<String, Object?>>> _stored(AppDatabase db) async =>
    (await db.customSelect('SELECT * FROM occurrences ORDER BY id').get())
        .map((r) => r.data)
        .toList();

void main() {
  for (final scenario in [
    (
      name: 'daily',
      frequency: 0,
      start: LocalDate(2026, 1, 1),
      boundary: LocalDate(2026, 1, 5),
      horizon: 7,
      old: [1, 2, 3, 4].map((d) => LocalDate(2026, 1, d)).toList(),
      next: [5, 6, 7, 8].map((d) => LocalDate(2026, 1, d)).toList(),
    ),
    (
      name: 'monthly',
      frequency: 2,
      start: LocalDate(2026, 1, 19),
      boundary: LocalDate(2026, 2, 19),
      horizon: 90,
      old: [LocalDate(2026, 1, 19)],
      next: [
        LocalDate(2026, 2, 19),
        LocalDate(2026, 3, 19),
        LocalDate(2026, 4, 19),
      ],
    ),
    (
      name: 'yearly',
      frequency: 3,
      start: LocalDate(2026, 10, 10),
      boundary: LocalDate(2027, 10, 10),
      horizon: 800,
      old: [LocalDate(2026, 10, 10)],
      next: [LocalDate(2027, 10, 10), LocalDate(2028, 10, 10)],
    ),
  ]) {
    test(
      '${scenario.name}: full future interval exclusive old/inclusive new survives reopen',
      () async {
        final fixture = await _HistoricalFile.create();
        final next = StableId.generate();
        final payload = _modernRule(
          scenario.frequency,
          day: scenario.start.day,
          month: scenario.start.month,
        );
        fixture.addSchedule(
          payload: payload,
          start: scenario.start,
          horizon: scenario.horizon,
        );
        fixture.addSchedule(
          id: next,
          payload: payload,
          start: scenario.start,
          effective: scenario.boundary,
          version: 2,
          hour: 18,
          horizon: scenario.horizon,
        );
        var db = fixture.open();
        try {
          expect(
            await ExtendRecurringSchedules(DriftCommitmentPlanRepository(db))(
              DateTime(
                scenario.start.year,
                scenario.start.month,
                scenario.start.day,
              ),
            ),
            scenario.old.length + scenario.next.length,
          );
          final rows = await _occurrences(db, fixture.owner);
          for (final part in [
            (fixture.schedule, scenario.old, 9),
            (next, scenario.next, 18),
          ]) {
            final owned =
                rows.where((o) => o.scheduleDefinitionId == part.$1).toList()
                  ..sort(
                    (a, b) => (a.currentScheduledAt as DateTime).compareTo(
                      b.currentScheduledAt as DateTime,
                    ),
                  );
            expect(
              owned.map((o) => o.currentScheduledAt),
              part.$2.map((d) => DateTime(d.year, d.month, d.day, part.$3)),
            );
          }
          final stored = await _stored(db);
          await db.close();
          db = AppDatabase.forTesting(NativeDatabase(fixture.file));
          expect(await _stored(db), stored);
          expect(
            await ExtendRecurringSchedules(DriftCommitmentPlanRepository(db))(
              DateTime(
                scenario.start.year,
                scenario.start.month,
                scenario.start.day,
              ),
            ),
            0,
          );
          expect(await _stored(db), stored);
        } finally {
          await db.close();
          await fixture.directory.delete(recursive: true);
        }
      },
    );
  }

  test('finite count uses original two-month phase; occupied moved/resolved slots do not reset it', () async {
    final fixture = await _HistoricalFile.create();
    final start = LocalDate(2026, 1, 19);
    final boundary = LocalDate(2026, 7, 19);
    final next = StableId.generate();
    final payload = _modernRule(2, interval: 2, day: 19);
    fixture.addSchedule(payload: payload, start: start, count: 5, horizon: 180);
    fixture.addSchedule(
      id: next,
      payload: payload,
      start: start,
      count: 5,
      effective: boundary,
      version: 2,
      hour: 18,
      horizon: 180,
    );
    fixture.addOccurrence(start, status: OccurrenceStatus.completed);
    fixture.addOccurrence(
      LocalDate(2026, 3, 19),
      status: OccurrenceStatus.cancelled,
    );
    // The approved hybrid occupancy rule protects both original and current
    // dates. Moving May onto September suppresses a duplicate destination row,
    // without changing the five logical slots or authorizing a sixth slot.
    fixture.addOccurrence(
      LocalDate(2026, 5, 19),
      current: LocalDate(2026, 9, 19),
      status: OccurrenceStatus.rescheduled,
      manual: true,
    );
    // July still owns its original slot even though its current date is November.
    fixture.addOccurrence(
      boundary,
      current: LocalDate(2026, 11, 19),
      status: OccurrenceStatus.rescheduled,
      manual: true,
    );
    var db = fixture.open();
    try {
      final before = await _stored(db);
      final command = ExtendRecurringSchedules(
        DriftCommitmentPlanRepository(db),
      );
      expect(await command(DateTime(2026, 7, 1)), 0);
      final rows = await _occurrences(db, fixture.owner);
      expect(rows, hasLength(4));
      expect(rows.where((o) => o.scheduleDefinitionId == next), isEmpty);
      final after = await _stored(db);
      expect(after.where((r) => before.any((b) => b['id'] == r['id'])), before);
      await db.close();
      db = AppDatabase.forTesting(NativeDatabase(fixture.file));
      expect(await _stored(db), after);
      expect(
        await ExtendRecurringSchedules(DriftCommitmentPlanRepository(db))(
          DateTime(2026, 11, 1),
        ),
        0,
      );
      expect(await _stored(db), after);
    } finally {
      await db.close();
      await fixture.directory.delete(recursive: true);
    }
  });

  for (final scenario in [
    (
      name: 'null-day monthly keeps every day in eligible Gregorian month',
      payload: _oldMonthlyNull,
      start: LocalDate(2026, 1, 30),
      now: DateTime(2026, 3, 1),
      horizon: 30,
      expected: List.generate(31, (i) => DateTime(2026, 3, i + 1, 9)),
    ),
    (
      name: 'monthly day31 clamps February then restores March anchor',
      payload: _oldMonthly31,
      start: LocalDate(2026, 1, 31),
      now: DateTime(2026, 2, 1),
      horizon: 60,
      expected: [DateTime(2026, 2, 28, 9), DateTime(2026, 3, 31, 9)],
    ),
    (
      name: 'yearly uses Gregorian start month/day rather than conflicting day key',
      payload: _oldYearly,
      start: LocalDate(2024, 2, 29),
      now: DateTime(2027, 2, 1),
      horizon: 500,
      expected: [DateTime(2028, 2, 29, 9)],
    ),
  ]) {
    test(
      'literal OLD v16 migration: ${scenario.name}, inferred reminders and cold reopen',
      () async {
        final fixture = await _HistoricalFile.create();
        fixture.addSchedule(
          payload: scenario.payload,
          start: scenario.start,
          horizon: scenario.horizon,
        );
        fixture.addOccurrence(scenario.start, offsets: [30, 5]);
        var db = fixture.open();
        try {
          expect(await db.readMetadata('schema_version'), '18');
          final initial = await db.select(db.scheduleDefinitions).getSingle();
          expect(initial.recurrenceRule, scenario.payload);
          final before = await _stored(db);
          expect(
            await ExtendRecurringSchedules(DriftCommitmentPlanRepository(db))(
              scenario.now,
            ),
            scenario.expected.length,
          );
          final plan = (await DriftCommitmentPlanRepository(db)
              .findByCommitmentId(fixture.owner))!;
          expect(
            plan.schedule.recurrenceRule!.calendar,
            RecurrenceCalendar.gregorian,
          );
          expect(plan.schedule.recurrenceRule!.legacyCalendarSemantics, isTrue);
          expect(plan.schedule.generationReminderOffsets, [
            const Duration(minutes: 5),
            const Duration(minutes: 30),
          ]);
          final added =
              plan.occurrences
                  .where((o) => !before.any((r) => r['id'] == o.id.value))
                  .toList()
                ..sort(
                  (a, b) => (a.currentScheduledAt as DateTime).compareTo(
                    b.currentScheduledAt as DateTime,
                  ),
                );
          expect(added.map((o) => o.currentScheduledAt), scenario.expected);
          final rules = await db.select(db.reminderRules).get();
          for (final occurrence in added) {
            expect(
              rules
                  .where((r) => r.occurrenceId == occurrence.id.value)
                  .map((r) => r.offsetSeconds)
                  .toSet(),
              {-300, -1800},
            );
          }
          expect(
            await db.select(db.reminderInstances).get(),
            hasLength(2 * added.length),
          );
          expect(await db.select(db.financialExpectations).get(), isEmpty);
          final upgraded = (await db.select(db.scheduleDefinitions).getSingle())
              .recurrenceRule;
          final metadata = jsonDecode(upgraded!) as Map<String, dynamic>;
          expect(metadata['formatVersion'], 2);
          expect(metadata['legacyCalendarSemantics'], true);
          final stored = await _stored(db);
          await db.close();
          db = AppDatabase.forTesting(NativeDatabase(fixture.file));
          expect(
            (await db.select(db.scheduleDefinitions).getSingle())
                .recurrenceRule,
            upgraded,
          );
          expect(await _stored(db), stored);
          expect(
            await ExtendRecurringSchedules(DriftCommitmentPlanRepository(db))(
              scenario.now,
            ),
            0,
          );
          expect(await _stored(db), stored);
          // Extend again after upgrade/reopen: semantics must not be modernized.
          final later = scenario.payload == _oldMonthlyNull
              ? DateTime(2026, 5, 1)
              : scenario.payload == _oldMonthly31
              ? DateTime(2026, 4, 1)
              : DateTime(2029, 2, 1);
          expect(
            await ExtendRecurringSchedules(DriftCommitmentPlanRepository(db))(
              later,
            ),
            scenario.payload == _oldYearly ? 0 : greaterThan(0),
          );
          final all = await _occurrences(db, fixture.owner);
          if (scenario.payload == _oldMonthlyNull) {
            expect(
              all.where((o) => (o.currentScheduledAt as DateTime).month == 5),
              hasLength(31),
            );
          } else if (scenario.payload == _oldMonthly31) {
            expect(
              all.any((o) => o.currentScheduledAt == DateTime(2026, 4, 30, 9)),
              true,
            );
            expect(
              all.any((o) => o.currentScheduledAt == DateTime(2026, 5, 31, 9)),
              true,
            );
          } else {
            // 2029/2030 are not leap years; no annual row may be invented.
            expect(
              all.where((o) => (o.currentScheduledAt as DateTime).year > 2028),
              isEmpty,
            );
          }
        } finally {
          await db.close();
          await fixture.directory.delete(recursive: true);
        }
      },
    );
  }

  for (final reason in [
    'mixed',
    'missing',
    'disabled',
    'absolute',
    'duplicate',
    'after-start',
    'sub-minute',
    'custom-body',
    'custom-title',
  ]) {
    test(
      'literal OLD reminder inference rejects $reason durably without changing rules',
      () async {
        final fixture = await _HistoricalFile.create();
        fixture.addSchedule(
          payload: _oldMonthly31,
          start: LocalDate(2026, 1, 31),
        );
        fixture.addOccurrence(LocalDate(2026, 1, 31), offsets: [30]);
        final second = fixture.addOccurrence(
          LocalDate(2026, 2, 28),
          offsets: reason == 'missing' ? [] : [reason == 'mixed' ? 5 : 30],
        );
        switch (reason) {
          case 'disabled':
            fixture.raw.execute(
              'UPDATE reminder_rules SET enabled=0 WHERE occurrence_id=?',
              [second.value],
            );
          case 'absolute':
            fixture.raw.execute(
              'UPDATE reminder_rules SET anchor=1, absolute_at=0 WHERE occurrence_id=?',
              [second.value],
            );
          case 'duplicate':
            fixture.raw.execute(
              'INSERT INTO reminder_rules(id,occurrence_id,anchor,offset_seconds,enabled) VALUES (?,?,0,-1800,1)',
              [StableId.generate().value, second.value],
            );
          case 'after-start':
            fixture.raw.execute(
              'UPDATE reminder_rules SET offset_seconds=60 WHERE occurrence_id=?',
              [second.value],
            );
          case 'sub-minute':
            fixture.raw.execute(
              'UPDATE reminder_rules SET offset_seconds=-61 WHERE occurrence_id=?',
              [second.value],
            );
          case 'custom-body':
            fixture.raw.execute(
              "UPDATE reminder_rules SET body='یادداشت' WHERE occurrence_id=?",
              [second.value],
            );
          case 'custom-title':
            fixture.raw.execute(
              "UPDATE reminder_rules SET title='متفاوت' WHERE occurrence_id=?",
              [second.value],
            );
        }
        var db = fixture.open();
        try {
          final rules = await db.select(db.reminderRules).get();
          expect(
            await ExtendRecurringSchedules(DriftCommitmentPlanRepository(db))(
              DateTime(2026, 3, 1),
            ),
            greaterThan(0),
          );
          expect(
            (await db.select(db.scheduleDefinitions).getSingle())
                .recurrenceRule,
            _oldMonthly31,
          );
          expect(await db.select(db.reminderRules).get(), rules);
          expect(await db.select(db.reminderInstances).get(), isEmpty);
          final stored = await _stored(db);
          await db.close();
          db = AppDatabase.forTesting(NativeDatabase(fixture.file));
          expect(await _stored(db), stored);
          expect(
            await ExtendRecurringSchedules(DriftCommitmentPlanRepository(db))(
              DateTime(2026, 3, 1),
            ),
            0,
          );
          expect(
            (await db.select(db.scheduleDefinitions).getSingle())
                .recurrenceRule,
            _oldMonthly31,
          );
          expect(await db.select(db.reminderRules).get(), rules);
        } finally {
          await db.close();
          await fixture.directory.delete(recursive: true);
        }
      },
    );
  }
}
