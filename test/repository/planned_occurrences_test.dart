import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/commitments/application/commitment_plan_use_case.dart';
import 'package:planact/features/commitments/data/drift_commitment_plan_repository.dart';
import 'package:planact/features/commitments/data/drift_commitment_repository.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/finance/application/financial_expectation_use_cases.dart';
import 'package:planact/features/finance/data/drift_financial_expectation_repository.dart';
import 'package:planact/features/finance/domain/financial_expectation.dart';
import 'package:planact/features/scheduling/domain/occurrence.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';

const _tables = [
  'schedule_definitions',
  'occurrences',
  'reminder_rules',
  'reminder_instances',
  'financial_expectations',
];
Future<Map<String, List<Map<String, Object?>>>> _snapshot(
  AppDatabase db,
) async => {
  for (final table in _tables)
    table: [
      for (final r
          in await db.customSelect('SELECT * FROM $table ORDER BY id').get())
        r.data,
    ],
};

Future<CommitmentPlan> _create(AppDatabase db, {int count = 60}) =>
    CreateCommitmentPlan(
      commitments: DriftCommitmentRepository(db),
      plans: DriftCommitmentPlanRepository(db),
      financialExpectations: FinancialExpectationUseCases(
        DriftFinancialExpectationRepository(db),
      ),
    )(
      title: 'برنامه',
      kind: CommitmentKind.recurring,
      startAt: DateTime(2026, 1, 19, 18, 35),
      frequency: RecurrenceFrequency.monthly,
      recurrenceCalendar: RecurrenceCalendar.gregorian,
      occurrenceCount: count,
      reminderOffsets: const [Duration(minutes: 30), Duration(minutes: 60)],
      financialDirection: FinancialExpectationDirection.outgoing,
      financialAmount: 123456,
    );

Future<PlannedOccurrenceSlot> _slot(
  DriftCommitmentPlanRepository repo, {
  int year = 2030,
  int month = 1,
}) async {
  final start = LocalDate(year, month, 1);
  final end = LocalDate.fromDateTime(DateTime.utc(year, month + 1, 1));
  return (await repo.loadPlannedRange(
    start,
    end,
    LocalDate(2026, 1, 1),
  )).preview.values.expand((v) => v).single;
}

class _WriterBarrier extends QueryInterceptor {
  bool armed = false;
  final acquired = Completer<void>();
  final release = Completer<void>();
  @override
  Future<void> runCustom(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) async {
    await executor.runCustom(statement, args);
    if (armed &&
        statement == 'UPDATE schema_metadata SET value = value WHERE key = ?') {
      armed = false;
      acquired.complete();
      await release.future.timeout(const Duration(seconds: 10));
    }
  }
}

void main() {
  // This suite intentionally opens independent databases for reopen and
  // concurrent-writer coverage.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  for (final count in [12, 60]) {
    test(
      'file-backed $count slot termination survives sparse preparation',
      () async {
        final dir = await Directory.systemTemp.createTemp('planned-count-');
        var db = AppDatabase.forTesting(
          NativeDatabase(File('${dir.path}/live.sqlite')),
        );
        try {
          await _create(db, count: count);
          var repo = DriftCommitmentPlanRepository(db);
          final lastYear = 2026 + (count - 1) ~/ 12;
          final slot = await _slot(repo, year: lastYear, month: 12);
          final occurrence = await repo.preparePlannedOccurrence(
            slot,
            LocalDate(2026, 1, 1),
          );
          await repo.saveOccurrence(
            occurrence.withStatus(OccurrenceStatus.completed),
          );
          await db.close();
          db = AppDatabase.forTesting(
            NativeDatabase(File('${dir.path}/live.sqlite')),
          );
          repo = DriftCommitmentPlanRepository(db);
          final next = LocalDate(lastYear + 1, 1, 1);
          expect(
            (await repo.loadPlannedRange(
              next,
              next.addDays(31),
              LocalDate(2026, 1, 1),
            )).preview,
            isEmpty,
          );
          final december = await repo.loadPlannedRange(
            LocalDate(lastYear, 12, 1),
            LocalDate(lastYear + 1, 1, 1),
            LocalDate(2026, 1, 1),
          );
          expect(december.preview, isEmpty);
          expect(
            december.recorded.values.single.single.status,
            OccurrenceStatus.completed,
          );
        } finally {
          await db.close();
          await dir.delete(recursive: true);
        }
      },
    );
  }

  test('faithful legacy inference is read-only and admitted dependencies are exact', () async {
    final dir = await Directory.systemTemp.createTemp('planned-legacy-');
    final db = AppDatabase.forTesting(
      NativeDatabase(File('${dir.path}/live.sqlite')),
    );
    try {
      await _create(db);
      final repo = DriftCommitmentPlanRepository(db);
      final row = await db.select(db.scheduleDefinitions).getSingle();
      final metadata = jsonDecode(row.recurrenceRule!) as Map<String, dynamic>;
      for (final key in [
        'formatVersion',
        'calendar',
        'monthOfYear',
        'generationReminderMinutes',
        'generationFinancialExpectation',
      ]) {
        metadata.remove(key);
      }
      await db.customStatement(
        'UPDATE schedule_definitions SET recurrence_rule = ?',
        [jsonEncode(metadata)],
      );
      final before = await _snapshot(db);
      final slot = await _slot(repo);
      expect(await _snapshot(db), before);
      final occurrence = await repo.preparePlannedOccurrence(
        slot,
        LocalDate(2026, 1, 1),
      );
      final after = await _snapshot(db);
      expect(after['schedule_definitions'], before['schedule_definitions']);
      expect(
        after['reminder_rules']!
            .where((r) => r['occurrence_id'] == occurrence.id.value)
            .map((r) => r['offset_seconds'])
            .toSet(),
        {-1800, -3600},
      );
      expect(
        after['financial_expectations']!.singleWhere(
          (r) => r['occurrence_id'] == occurrence.id.value,
        )['minor_units'],
        123456,
      );
    } finally {
      await db.close();
      await dir.delete(recursive: true);
    }
  });

  test(
    'file SQLite read-only long range, exact dependencies and cold reopen',
    () async {
      final dir = await Directory.systemTemp.createTemp('planned-range-');
      final file = File('${dir.path}/live.sqlite');
      var db = AppDatabase.forTesting(NativeDatabase(file));
      try {
        final plan = await _create(db);
        var repo = DriftCommitmentPlanRepository(db);
        final before = await _snapshot(db);
        final changes =
            (await db.customSelect('SELECT total_changes() AS n').getSingle())
                .read<int>('n');
        final slot = await _slot(repo);
        expect(slot.date, LocalDate(2030, 1, 19));
        expect(
          await repo.loadMonth(LocalDate(2030, 1, 1), LocalDate(2030, 2, 1)),
          isEmpty,
        );
        expect(await repo.loadWeek(LocalDate(2030, 1, 19)), isEmpty);
        expect(await _snapshot(db), before);
        expect(
          (await db.customSelect('SELECT total_changes() AS n').getSingle())
              .read<int>('n'),
          changes,
        );
        await db.close();
        db = AppDatabase.forTesting(NativeDatabase(file));
        repo = DriftCommitmentPlanRepository(db);
        expect(
          (await _slot(repo)).scheduleFingerprint,
          slot.scheduleFingerprint,
        );
        final recorded = await repo.preparePlannedOccurrence(
          slot,
          LocalDate(2030, 1, 1),
        );
        final after = await _snapshot(db);
        expect(after['occurrences']!.length, before['occurrences']!.length + 1);
        expect(
          after['reminder_rules']!.where(
            (r) => r['occurrence_id'] == recorded.id.value,
          ),
          hasLength(2),
        );
        final rules = after['reminder_rules']!
            .where((r) => r['occurrence_id'] == recorded.id.value)
            .map((r) => r['id'])
            .toSet();
        expect(
          after['reminder_instances']!.where(
            (r) => rules.contains(r['rule_id']),
          ),
          hasLength(2),
        );
        expect(
          after['financial_expectations']!.singleWhere(
            (r) => r['occurrence_id'] == recorded.id.value,
          )['minor_units'],
          123456,
        );
        for (final table in _tables) {
          for (final old in before[table]!) {
            expect(after[table]!.singleWhere((r) => r['id'] == old['id']), old);
          }
        }
        await expectLater(
          repo.preparePlannedOccurrence(slot, LocalDate(2030, 1, 1)),
          throwsStateError,
        );
        await db.close();
        db = AppDatabase.forTesting(NativeDatabase(file));
        repo = DriftCommitmentPlanRepository(db);
        final range = await repo.loadPlannedRange(
          LocalDate(2030, 1, 1),
          LocalDate(2030, 2, 1),
          LocalDate(2030, 1, 1),
          commitmentId: plan.commitment.id,
        );
        expect(range.preview, isEmpty);
        expect(
          range.recorded[plan.commitment.id.value]!.single.id,
          recorded.id,
        );
        expect(await _snapshot(db), after);
      } finally {
        await db.close();
        await dir.delete(recursive: true);
      }
    },
  );

  // Acceptance: preview and rolling admission must agree about a moved row's
  // destination; reaching that slot cannot create duplicate rows or dependencies.
  test('file SQLite moved preview stays occupied during rolling and reopen', () async {
    final dir = await Directory.systemTemp.createTemp('planned-moved-rolling-');
    final file = File('${dir.path}/live.sqlite');
    var db = AppDatabase.forTesting(NativeDatabase(file));
    try {
      final plan = await _create(db);
      var repo = DriftCommitmentPlanRepository(db);
      final slot = await _slot(repo, year: 2030, month: 12);
      final moved = plan.occurrences.first.reschedule(
        DateTime(2030, 12, 19, 20),
      );
      await repo.saveOccurrence(moved);
      final before = await _snapshot(db);
      final start = LocalDate(2030, 12, 1);
      final end = LocalDate(2031, 1, 1);
      final range = await repo.loadPlannedRange(start, end, start);
      expect(range.preview, isEmpty);
      expect(range.recorded.values.single.single.id, moved.id);
      expect(await _snapshot(db), before);
      await expectLater(
        repo.preparePlannedOccurrence(slot, start),
        throwsStateError,
      );
      // Last logical slot: the horizon contains no other eligible future slots.
      expect(await repo.extendRecurringSchedules(slot.date), 0);
      expect(await _snapshot(db), before);
      await db.close();
      db = AppDatabase.forTesting(NativeDatabase(file));
      repo = DriftCommitmentPlanRepository(db);
      expect(await repo.extendRecurringSchedules(slot.date), 0);
      final reopened = await repo.loadPlannedRange(start, end, start);
      expect(reopened.preview, isEmpty);
      expect(reopened.recorded.values.single.single.id, moved.id);
      expect(await _snapshot(db), before);
    } finally {
      await db.close();
      await dir.delete(recursive: true);
    }
  });

  test('version boundary, moved original/current occupancy and resolved manual rows', () async {
    final dir = await Directory.systemTemp.createTemp('planned-version-');
    final db = AppDatabase.forTesting(
      NativeDatabase(File('${dir.path}/live.sqlite')),
    );
    try {
      final plan = await _create(db);
      final repo = DriftCommitmentPlanRepository(db);
      final old = await db.select(db.scheduleDefinitions).getSingle();
      final nextId = StableId.generate();
      await db
          .into(db.scheduleDefinitions)
          .insert(
            old
                .copyWith(
                  id: nextId.value,
                  version: 2,
                  effectiveFrom: '2030-1-19',
                )
                .toCompanion(true),
          );
      final slot = await _slot(repo);
      expect(slot.scheduleId, nextId);
      final moved = plan.occurrences.first.reschedule(
        DateTime(2030, 1, 19, 20),
      );
      await repo.saveOccurrence(moved);
      expect(
        (await repo.loadPlannedRange(
          LocalDate(2030, 1, 1),
          LocalDate(2030, 2, 1),
          LocalDate(2026, 1, 1),
        )).preview,
        isEmpty,
      );
      await expectLater(
        repo.preparePlannedOccurrence(slot, LocalDate(2026, 1, 1)),
        throwsStateError,
      );
      final feb = await _slot(repo, month: 2);
      final recorded = await repo.preparePlannedOccurrence(
        feb,
        LocalDate(2030, 1, 1),
      );
      await repo.saveOccurrence(
        recorded
            .reschedule(DateTime(2030, 6, 19))
            .withStatus(OccurrenceStatus.cancelled),
      );
      for (final month in [2, 6]) {
        final start = LocalDate(2030, month, 1);
        expect(
          (await repo.loadPlannedRange(
            start,
            LocalDate.fromDateTime(DateTime.utc(2030, month + 1, 1)),
            LocalDate(2026, 1, 1),
          )).preview,
          isEmpty,
        );
      }
      expect(
        (await repo.loadMonth(
          LocalDate(2030, 6, 1),
          LocalDate(2030, 7, 1),
        )).values.single.single.status,
        OccurrenceStatus.cancelled,
      );
    } finally {
      await db.close();
      await dir.delete(recursive: true);
    }
  });

  test(
    'stale exact metadata, inactive/past and ambiguous legacy fail closed',
    () async {
      final dir = await Directory.systemTemp.createTemp('planned-stale-');
      final db = AppDatabase.forTesting(
        NativeDatabase(File('${dir.path}/live.sqlite')),
      );
      try {
        final plan = await _create(db);
        final repo = DriftCommitmentPlanRepository(db);
        final slot = await _slot(repo);
        await expectLater(
          repo.preparePlannedOccurrence(slot, LocalDate(2030, 1, 20)),
          throwsStateError,
        );
        final row = await db.select(db.scheduleDefinitions).getSingle();
        final metadata =
            jsonDecode(row.recurrenceRule!) as Map<String, dynamic>;
        metadata['generationReminderMinutes'] = [15];
        await db.customStatement(
          'UPDATE schedule_definitions SET recurrence_rule = ?',
          [jsonEncode(metadata)],
        );
        final before = await _snapshot(db);
        await expectLater(
          repo.preparePlannedOccurrence(slot, LocalDate(2030, 1, 1)),
          throwsStateError,
        );
        expect(await _snapshot(db), before);
        final fresh = await _slot(repo);
        await db.customStatement('UPDATE commitments SET status = ?', [
          CommitmentStatus.archived.index,
        ]);
        await expectLater(
          repo.preparePlannedOccurrence(fresh, LocalDate(2030, 1, 1)),
          throwsStateError,
        );
        expect(
          (await repo.loadPlannedRange(
            LocalDate(2030, 1, 1),
            LocalDate(2030, 2, 1),
            LocalDate(2026, 1, 1),
          )).preview,
          isEmpty,
        );
        await db.customStatement('UPDATE commitments SET status = ?', [
          CommitmentStatus.active.index,
        ]);
        metadata.remove('generationReminderMinutes');
        metadata.remove('generationFinancialExpectation');
        metadata.remove('formatVersion');
        await db.customStatement(
          'UPDATE schedule_definitions SET recurrence_rule = ?',
          [jsonEncode(metadata)],
        );
        await db.customStatement(
          'UPDATE reminder_rules SET enabled = 0 WHERE occurrence_id = ?',
          [plan.occurrences.first.id.value],
        );
        final legacyBefore = await _snapshot(db);
        expect(
          (await repo.loadPlannedRange(
            LocalDate(2030, 1, 1),
            LocalDate(2030, 2, 1),
            LocalDate(2026, 1, 1),
          )).preview,
          isEmpty,
        );
        expect(await _snapshot(db), legacyBefore);
      } finally {
        await db.close();
        await dir.delete(recursive: true);
      }
    },
  );

  test(
    'dependency failure rolls back occurrence and rules; explicit retry works',
    () async {
      final dir = await Directory.systemTemp.createTemp('planned-rollback-');
      final db = AppDatabase.forTesting(
        NativeDatabase(File('${dir.path}/live.sqlite')),
      );
      try {
        await _create(db);
        final repo = DriftCommitmentPlanRepository(db);
        final slot = await _slot(repo);
        final before = await _snapshot(db);
        await db.customStatement(
          "CREATE TRIGGER reject_planned_instance BEFORE INSERT ON reminder_instances BEGIN SELECT RAISE(ABORT, 'injected'); END",
        );
        await expectLater(
          repo.preparePlannedOccurrence(slot, LocalDate(2030, 1, 1)),
          throwsA(isA<SqliteException>()),
        );
        expect(await _snapshot(db), before);
        await db.customStatement('DROP TRIGGER reject_planned_instance');
        await repo.preparePlannedOccurrence(slot, LocalDate(2030, 1, 1));
        expect(
          (await db.select(db.occurrences).get()).length,
          before['occurrences']!.length + 1,
        );
      } finally {
        await db.close();
        await dir.delete(recursive: true);
      }
    },
  );

  for (final journal in ['delete', 'wal']) {
    test(
      '$journal independent SQLite writer busy rollback; retry rejects occupied',
      () async {
        final dir = await Directory.systemTemp.createTemp('planned-race-');
        final file = File('${dir.path}/live.sqlite');
        final probe = _WriterBarrier();
        final first = AppDatabase.forTesting(
          NativeDatabase(file).interceptWith(probe),
        );
        final second = AppDatabase.forTesting(NativeDatabase(file));
        try {
          await first.customStatement('PRAGMA journal_mode = $journal');
          await _create(first);
          await second.customSelect('SELECT 1').get();
          for (final db in [first, second]) {
            await db.customStatement('PRAGMA busy_timeout = 0');
          }
          final a = DriftCommitmentPlanRepository(first);
          final b = DriftCommitmentPlanRepository(second);
          final slot = await _slot(a);
          final before = await _snapshot(second);
          probe.armed = true;
          final winner = a.preparePlannedOccurrence(
            slot,
            LocalDate(2030, 1, 1),
          );
          final assertion = expectLater(winner, completion(isA<Occurrence>()));
          await probe.acquired.future.timeout(const Duration(seconds: 10));
          await expectLater(
            b.preparePlannedOccurrence(slot, LocalDate(2030, 1, 1)),
            throwsA(
              isA<SqliteException>().having((e) => e.resultCode, 'busy', 5),
            ),
          );
          expect(await _snapshot(second), before);
          probe.release.complete();
          await assertion;
          await expectLater(
            b.preparePlannedOccurrence(slot, LocalDate(2030, 1, 1)),
            throwsStateError,
          );
          expect(
            (await second.select(second.occurrences).get()).length,
            before['occurrences']!.length + 1,
          );
        } finally {
          if (!probe.release.isCompleted) {
            probe.release.complete();
          }
          await first.close();
          await second.close();
          await dir.delete(recursive: true);
        }
      },
    );
  }
}
