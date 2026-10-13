import 'dart:io';

import 'package:drift/native.dart';
import 'package:planact/core/database/app_database.dart' as db;
import 'package:planact/core/ids/stable_id.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/features/commitments/application/commitment_plan_use_case.dart';
import 'package:planact/features/commitments/data/drift_commitment_plan_repository.dart';
import 'package:planact/features/commitments/data/drift_commitment_repository.dart';
import 'package:planact/features/scheduling/domain/occurrence.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';

void main() {
  test(
    'file-backed week range preserves starts/status/history after restart',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'planact-calendar-',
      );
      final file = File('${directory.path}/calendar.sqlite');
      var database = AppDatabase.forTesting(NativeDatabase(file));
      try {
        var plans = DriftCommitmentPlanRepository(database);
        final create = CreateCommitmentPlan(
          commitments: DriftCommitmentRepository(database),
          plans: plans,
        );
        final expected = <String>{};
        for (final date in [
          DateTime(2026, 9, 30, 23, 59),
          DateTime(2026, 10, 1),
          DateTime(2026, 10, 7, 23, 59),
          DateTime(2026, 10, 8),
          DateTime(2026, 10, 10),
        ]) {
          final plan = await create(title: 'بازه', startAt: date);
          if (date.day == 1 || date.day == 7) {
            expected.add(plan.occurrences.single.id.value);
          }
        }
        final allDay = await create(
          title: 'تمام‌روز',
          startAt: DateTime(2026, 10, 3),
        );
        final changed = allDay.occurrences.single
            .reschedule(LocalDate(2026, 10, 3))
            .withStatus(OccurrenceStatus.cancelled);
        await plans.saveOccurrence(changed);
        expected.add(changed.id.value);
        final instant = await create(
          title: 'لحظه',
          startAt: DateTime.utc(2026, 10, 4, 12),
        );
        final fixedSchedule = ScheduleDefinition.create(
          cycleId: instant.cycle.id,
          mode: ScheduleMode.oneOff,
          timeSemantics: TimeSemantics.fixedInstant,
          startDate: LocalDate(2026, 10, 4),
          fixedInstant: DateTime.utc(2026, 10, 4, 12),
        );
        final fixedOccurrences = const OccurrenceGenerator().generate(
          schedule: fixedSchedule,
          through: LocalDate(2026, 10, 7),
        );
        await plans.save(
          CommitmentPlan(
            commitment: instant.commitment,
            cycle: instant.cycle,
            schedule: fixedSchedule,
            occurrences: fixedOccurrences,
            reminders: const [],
          ),
        );
        // Saving is additive; the original floating occurrence is retained.
        expected.add(instant.occurrences.single.id.value);
        expected.add(fixedOccurrences.single.id.value);
        final before = await plans.loadWeek(LocalDate(2026, 10, 1));
        expect(
          before.values.expand((x) => x).map((x) => x.id.value).toSet(),
          expected,
        );
        expect(
          before[instant.commitment.id.value]!
              .where((item) => item.id == fixedOccurrences.single.id)
              .single
              .currentScheduledAt,
          DateTime.utc(2026, 10, 4, 12),
        );
        expect(
          before[allDay.commitment.id.value]!.single.currentScheduledAt,
          LocalDate(2026, 10, 3),
        );
        expect(
          before[allDay.commitment.id.value]!.single.status,
          OccurrenceStatus.cancelled,
        );
        await database.close();
        database = AppDatabase.forTesting(NativeDatabase(file));
        plans = DriftCommitmentPlanRepository(database);
        final after = await plans.loadWeek(LocalDate(2026, 10, 1));
        expect(
          after.values.expand((x) => x).map((x) => x.id.value).toSet(),
          expected,
        );
        expect(
          (await plans.findByCommitmentId(allDay.commitment.id))!
              .occurrences
              .single
              .originalScheduledAt,
          DateTime(2026, 10, 3),
        );
        expect(await plans.loadWeek(LocalDate(2040, 1, 1)), isEmpty);
      } finally {
        await database.close();
        await directory.delete(recursive: true);
      }
    },
  );
  test('month rejects empty, reversed and over-31-date ranges', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    final plans = DriftCommitmentPlanRepository(database);
    try {
      final start = LocalDate(2026, 10, 1);
      for (final days in [0, -1, 32, 365]) {
        await expectLater(
          plans.loadMonth(start, start.addDays(days)),
          throwsArgumentError,
        );
      }
      for (final days in [1, 28, 29, 30, 31]) {
        expect(await plans.loadMonth(start, start.addDays(days)), isEmpty);
      }
      expect(
        await plans.loadMonth(LocalDate(2026, 12, 20), LocalDate(2027, 1, 20)),
        isEmpty,
      );
    } finally {
      await database.close();
    }
  });

  test(
    'file-backed month bounds and all statuses survive cold reopen',
    () async {
      final directory = await Directory.systemTemp.createTemp('planact-month-');
      final file = File('${directory.path}/calendar.sqlite');
      var database = AppDatabase.forTesting(NativeDatabase(file));
      try {
        var plans = DriftCommitmentPlanRepository(database);
        final create = CreateCommitmentPlan(
          commitments: DriftCommitmentRepository(database),
          plans: plans,
        );
        final expected = <String, Occurrence>{};
        final start = LocalDate(2026, 9, 20);
        final end = LocalDate(2026, 10, 21);
        for (final offset in [-1, 0, 10, 11, 20, 30, 31, 40]) {
          final date = start.addDays(offset);
          for (final semantics in TimeSemantics.values) {
            final local = DateTime(date.year, date.month, date.day);
            final plan = await create(title: 'ماه', startAt: local);
            final schedule = ScheduleDefinition.create(
              cycleId: plan.cycle.id,
              mode: ScheduleMode.oneOff,
              timeSemantics: semantics,
              startDate: date,
              timeZoneId: semantics == TimeSemantics.floatingLocalTime
                  ? 'Asia/Tehran'
                  : null,
              localTime: semantics == TimeSemantics.floatingLocalTime
                  ? LocalTime(23, 59)
                  : null,
              fixedInstant: semantics == TimeSemantics.fixedInstant
                  ? local.toUtc()
                  : null,
            );
            final generated = const OccurrenceGenerator().generate(
              schedule: schedule,
              through: date,
            );
            final occurrence = generated.single.withStatus(
              OccurrenceStatus.values[expected.length %
                  OccurrenceStatus.values.length],
            );
            await plans.save(
              CommitmentPlan(
                commitment: plan.commitment,
                cycle: plan.cycle,
                schedule: schedule,
                occurrences: [occurrence],
                reminders: const [],
              ),
            );
            if (offset >= 0 && offset < 31) {
              expected[plan.occurrences.single.id.value] =
                  plan.occurrences.single;
              expected[occurrence.id.value] = occurrence;
            }
          }
        }
        // A manually moved historical row must be selected by current, not original date.
        final movedPlan = await create(
          title: 'جابه‌جا',
          startAt: DateTime(2025, 1, 1),
        );
        final moved = movedPlan.occurrences.single
            .reschedule(LocalDate(2026, 10, 20))
            .withStatus(OccurrenceStatus.cancelled);
        await plans.saveOccurrence(moved);
        expected[moved.id.value] = moved;

        Future<void> verify() async {
          final changes =
              (await database
                      .customSelect('SELECT total_changes() AS n')
                      .getSingle())
                  .read<int>('n');
          final result = await plans.loadMonth(start, end);
          final occurrences = result.values.expand((items) => items).toList();
          expect(
            occurrences.map((item) => item.id.value).toSet(),
            expected.keys.toSet(),
          );
          expect(
            occurrences.map((item) => item.status).toSet(),
            OccurrenceStatus.values.toSet(),
          );
          for (final item in occurrences) {
            final original = expected[item.id.value]!;
            expect(item.currentScheduledAt, original.currentScheduledAt);
            expect(item.originalScheduledAt, original.originalScheduledAt);
            expect(item.status, original.status);
            expect(item.isManualOverride, original.isManualOverride);
            expect(
              result.values.where((items) => items.contains(item)).length,
              1,
            );
          }
          expect(
            await plans.loadMonth(LocalDate(2040, 1, 1), LocalDate(2040, 2, 1)),
            isEmpty,
          );
          expect(
            (await database
                    .customSelect('SELECT total_changes() AS n')
                    .getSingle())
                .read<int>('n'),
            changes,
          );
          final week = await plans.loadWeek(start);
          final sevenDates = await plans.loadMonth(start, start.addDays(7));
          expect(week.keys.toSet(), sevenDates.keys.toSet());
          expect(
            week.values
                .expand((items) => items)
                .map((item) => item.id.value)
                .toSet(),
            sevenDates.values
                .expand((items) => items)
                .map((item) => item.id.value)
                .toSet(),
          );
        }

        await verify();
        await database.close();
        database = AppDatabase.forTesting(NativeDatabase(file));
        plans = DriftCommitmentPlanRepository(database);
        await verify();
      } finally {
        await database.close();
        await directory.delete(recursive: true);
      }
    },
  );

  test('file-backed month timing at 12000 historical rows stays bounded', () async {
    final directory = await Directory.systemTemp.createTemp(
      'planact-month-volume-',
    );
    final file = File('${directory.path}/calendar.sqlite');
    var database = AppDatabase.forTesting(NativeDatabase(file));
    try {
      final plans = DriftCommitmentPlanRepository(database);
      final create = CreateCommitmentPlan(
        commitments: DriftCommitmentRepository(database),
        plans: plans,
      );
      final owners = <CommitmentPlan>[];
      for (var i = 0; i < 20; i++) {
        owners.add(await create(title: 'حجم', startAt: DateTime(2020, 1, 1)));
      }
      final expected = <String>{};
      final first = LocalDate(2024, 1, 1);
      final start = LocalDate(2026, 10, 1);
      final end = LocalDate(2026, 11, 1);
      await database.batch((batch) {
        final rows = <db.OccurrencesCompanion>[];
        for (var day = 0; day < 1200; day++) {
          final date = first.addDays(day);
          for (var slot = 0; slot < 10; slot++) {
            final owner = owners[(day * 10 + slot) % owners.length];
            final id = StableId.generate().value;
            final prefix = '${date.year}-${date.month}-${date.day}';
            final value = switch (slot % 3) {
              0 => 'date:$prefix',
              1 => 'local:${prefix}T18:0:0.0',
              _ =>
                'instant:${DateTime(date.year, date.month, date.day, 18).toUtc().toIso8601String()}',
            };
            rows.add(
              db.OccurrencesCompanion.insert(
                id: id,
                cycleId: owner.cycle.id.value,
                scheduleDefinitionId: owner.schedule.id.value,
                occurrenceKey: 'volume:$day:$slot',
                timeSemantics: switch (slot % 3) {
                  0 => TimeSemantics.allDayLocalDate.index,
                  1 => TimeSemantics.floatingLocalTime.index,
                  _ => TimeSemantics.fixedInstant.index,
                },
                originalScheduledValue: value,
                currentScheduledValue: value,
                status: OccurrenceStatus
                    .values[(day + slot) % OccurrenceStatus.values.length]
                    .index,
                isManualOverride: false,
              ),
            );
            if (date.compareTo(start) >= 0 && date.compareTo(end) < 0) {
              expected.add(id);
            }
          }
        }
        batch.insertAll(database.occurrences, rows);
      });
      await database.close();
      database = AppDatabase.forTesting(NativeDatabase(file));
      final reopened = DriftCommitmentPlanRepository(database);
      final times = <int>[];
      for (var run = 0; run < 4; run++) {
        final watch = Stopwatch()..start();
        final result = await reopened.loadMonth(start, end);
        watch.stop();
        times.add(watch.elapsedMilliseconds);
        expect(
          result.values
              .expand((items) => items)
              .map((item) => item.id.value)
              .toSet(),
          expected,
        );
        expect(expected.length, 310);
        // Broad desktop regression guard, not a reference-device release budget.
        expect(watch.elapsed, lessThan(const Duration(seconds: 5)));
      }
      // Synthetic fixture counts/timings only; never personal data.
      // ignore: avoid_print
      print(
        'Month desktop regression: 12020 stored / 310 returned; cold+warm ms=$times; budget=5000ms/query',
      );
    } finally {
      await database.close();
      await directory.delete(recursive: true);
    }
  });
}
