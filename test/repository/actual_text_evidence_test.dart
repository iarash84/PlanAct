import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/database/app_database.dart' hide Actual, Evidence;
import 'package:planact/core/errors/app_error.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/actuals/data/drift_actual_repository.dart';
import 'package:planact/features/actuals/domain/actual.dart';
import 'package:planact/features/backup/data/sqlite_backup_snapshot.dart';
import 'package:planact/features/backup/data/sqlite_backup_storage.dart';
import 'package:planact/features/commitments/application/commitment_plan_use_case.dart';
import 'package:planact/features/commitments/data/drift_commitment_plan_repository.dart';
import 'package:planact/features/commitments/data/drift_commitment_repository.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/commitments/domain/commitment_cycle.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

void main() {
  test(
    'creation rollback, empty/no-op and save bypass guards preserve originals',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      try {
        final plan = await CreateCommitmentPlan(
          commitments: DriftCommitmentRepository(db),
          plans: DriftCommitmentPlanRepository(db),
        )(title: 'test', startAt: DateTime(2027));
        final repo = DriftActualRepository(db);
        final completed = await repo.recordOccurrenceActual(
          expected: plan.occurrences.single,
          outcome: ActualOutcome.completed,
          recordedAt: DateTime.utc(2026),
        );
        final actual = (await repo.list()).single;
        await expectLater(
          repo.mutateTextEvidence(actualId: actual.id, value: '  '),
          throwsA(isA<ValidationError>()),
        );
        await expectLater(
          repo.mutateTextEvidence(actualId: actual.id, value: null),
          throwsA(isA<ValidationError>()),
        );
        await db.customStatement(
          "CREATE TRIGGER reject_order BEFORE UPDATE ON schema_metadata WHEN NEW.key = 'actual_evidence_order_v1' BEGIN SELECT RAISE(ABORT, 'injected'); END",
        );
        await expectLater(
          repo.mutateTextEvidence(actualId: actual.id, value: 'rollback'),
          throwsA(anything),
        );
        expect((await repo.list()).single.evidence, isEmpty);
        await db.customStatement('DROP TRIGGER reject_order');
        await repo.mutateTextEvidence(actualId: actual.id, value: 'original');
        final original = (await repo.list()).single.evidence.single;
        await repo.mutateTextEvidence(
          actualId: actual.id,
          expected: original,
          value: 'original',
        );
        expect((await repo.list()).single.evidence.single.history, isEmpty);
        final invented = Evidence(
          id: StableId.generate(),
          actualId: actual.id,
          type: EvidenceType.note,
          value: 'bypass',
          createdAt: DateTime.now().toUtc(),
        );
        await expectLater(
          repo.save(actual.addEvidence(invented)),
          throwsA(isA<ValidationError>()),
        );
        await repo.recordOccurrenceActual(
          expected: completed,
          outcome: ActualOutcome.reopened,
          recordedAt: DateTime.utc(2026),
        );
        final otherId = (await repo.list()).last.id;
        await expectLater(
          repo.mutateTextEvidence(
            actualId: otherId,
            expected: original,
            value: 'move',
          ),
          throwsA(isA<ValidationError>()),
        );
        expect((await repo.list()).first.evidence.single.value, 'original');
        expect((await repo.list()).last.evidence, isEmpty);
      } finally {
        await db.close();
      }
    },
  );
  test('original ownership, stale revision, discard and cold reopen preserve history without ledger effects', () async {
    final dir = await Directory.systemTemp.createTemp('actual-text-');
    final file = File('${dir.path}/live.sqlite');
    var db = AppDatabase.forTesting(NativeDatabase(file));
    try {
      final plans = DriftCommitmentPlanRepository(db);
      final plan = await CreateCommitmentPlan(
        commitments: DriftCommitmentRepository(db),
        plans: plans,
      )(title: 'test', startAt: DateTime(2027, 1, 2));
      var repo = DriftActualRepository(db);
      final completed = await repo.recordOccurrenceActual(
        expected: plan.occurrences.single,
        outcome: ActualOutcome.completed,
        recordedAt: DateTime.utc(2026),
      );
      final id = (await repo.list()).single.id;
      await repo.mutateTextEvidence(actualId: id, value: 'original');
      final original = (await repo.list()).single.evidence.single;
      await repo.recordOccurrenceActual(
        expected: completed,
        outcome: ActualOutcome.reopened,
        recordedAt: DateTime.utc(2026),
      );
      await DriftCommitmentRepository(db)
          .changeStatus(plan.commitment.id, CommitmentStatus.paused);
      await repo.mutateTextEvidence(
        actualId: id,
        expected: original,
        value: 'edited',
      );
      await expectLater(
        repo.mutateTextEvidence(
          actualId: id,
          expected: original,
          value: 'stale',
        ),
        throwsA(isA<ValidationError>()),
      );
      final edited = (await repo.list()).first.evidence.single;
      await DriftCommitmentRepository(db)
          .changeStatus(plan.commitment.id, CommitmentStatus.archived);
      await repo.mutateTextEvidence(
        actualId: id,
        expected: edited,
        value: null,
      );
      await expectLater(
        repo.mutateTextEvidence(
          actualId: id,
          expected: edited,
          value: 'resurrect',
        ),
        throwsA(isA<ValidationError>()),
      );
      expect((await db.select(db.evidences).get()).single.value, 'original');
      await db.close();
      db = AppDatabase.forTesting(NativeDatabase(file));
      repo = DriftActualRepository(db);
      final history = await repo.list();
      expect(history.map((a) => a.outcome), [
        ActualOutcome.completed,
        ActualOutcome.reopened,
      ]);
      expect(history.last.evidence, isEmpty);
      final evidence = history.first.evidence.single;
      expect(evidence.actualId, id);
      expect(evidence.value, 'edited');
      expect(evidence.originalValue, 'original');
      expect(evidence.revision, 2);
      expect(evidence.isDiscarded, isTrue);
      expect(evidence.history.map((r) => r.isDiscarded), [false, true]);
      expect(await db.select(db.accountEntries).get(), isEmpty);
      expect(await db.select(db.entitlementLedgerEntries).get(), isEmpty);
      await expectLater(
        repo.save(
          Actual(
            id: history.first.id,
            occurrenceId: history.first.occurrenceId,
            outcome: history.first.outcome,
            recordedAt: history.first.recordedAt,
            evidence: [original],
          ),
        ),
        throwsA(isA<ValidationError>()),
      );
    } finally {
      await db.close();
      await dir.delete(recursive: true);
    }
  });

  test('two SQLite connections compare fresh revisions and failed metadata writes roll back', () async {
    final dir = await Directory.systemTemp.createTemp('actual-race-');
    final file = File('${dir.path}/live.sqlite');
    final db = AppDatabase.forTesting(NativeDatabase(file));
    AppDatabase? other;
    try {
      final plan = await CreateCommitmentPlan(
        commitments: DriftCommitmentRepository(db),
        plans: DriftCommitmentPlanRepository(db),
      )(title: 'test', startAt: DateTime(2027));
      final repo = DriftActualRepository(db);
      await repo.recordOccurrenceActual(
        expected: plan.occurrences.single,
        outcome: ActualOutcome.completed,
        recordedAt: DateTime.utc(2026),
      );
      final id = (await repo.list()).single.id;
      await repo.mutateTextEvidence(actualId: id, value: 'original');
      final expected = (await repo.list()).single.evidence.single;
      other = AppDatabase.forTesting(NativeDatabase(file));
      final second = DriftActualRepository(other);
      await other.customStatement('PRAGMA busy_timeout = 5000');
      Future<bool> attempt(DriftActualRepository r, String text) async {
        try {
          await r.mutateTextEvidence(
            actualId: id,
            expected: expected,
            value: text,
          );
          return true;
        } catch (_) {
          return false;
        }
      }

      expect(
        (await Future.wait([attempt(repo, 'one'), attempt(second, 'two')]))
            .where((v) => v),
        hasLength(1),
      );
      final fresh = (await repo.list()).single.evidence.single;
      await db.customStatement(
        "CREATE TRIGGER reject_text BEFORE UPDATE ON schema_metadata WHEN NEW.key LIKE 'actual_text_head_v1:%' BEGIN SELECT RAISE(ABORT, 'injected'); END",
      );
      await expectLater(
        repo.mutateTextEvidence(
          actualId: id,
          expected: fresh,
          value: 'failure',
        ),
        throwsA(anything),
      );
      expect((await repo.list()).single.evidence.single.revision, 1);
      await db.customStatement('DROP TRIGGER reject_text');
      await db.customStatement('UPDATE commitment_cycles SET status = ?', [
        CommitmentCycleStatus.completed.index,
      ]);
      await expectLater(
        repo.mutateTextEvidence(
          actualId: id,
          expected: fresh,
          value: 'completed',
        ),
        throwsA(isA<ValidationError>()),
      );
      await expectLater(
        repo.mutateTextEvidence(actualId: id, value: 'new'),
        throwsA(isA<ValidationError>()),
      );
    } finally {
      await other?.close();
      await db.close();
      await dir.delete(recursive: true);
    }
  });

  test('strict backup preserves equal-time append order after reversed logical inserts and rejects corrupted history', () async {
    final dir = await Directory.systemTemp.createTemp('actual-backup-');
    final live = File('${dir.path}/live.sqlite');
    final db = AppDatabase.forTesting(NativeDatabase(live));
    AppDatabase? restored;
    try {
      final plan = await CreateCommitmentPlan(
        commitments: DriftCommitmentRepository(db),
        plans: DriftCommitmentPlanRepository(db),
      )(title: 'test', startAt: DateTime(2027));
      final repo = DriftActualRepository(db);
      final completed = await repo.recordOccurrenceActual(
        expected: plan.occurrences.single,
        outcome: ActualOutcome.completed,
        recordedAt: DateTime.utc(2026),
      );
      final id = (await repo.list()).single.id;
      await repo.mutateTextEvidence(actualId: id, value: 'first');
      await repo.mutateTextEvidence(actualId: id, value: 'second');
      final first = (await repo.list()).single.evidence.first;
      await repo.mutateTextEvidence(
        actualId: id,
        expected: first,
        value: 'revised',
      );
      await repo.recordOccurrenceActual(
        expected: completed,
        outcome: ActualOutcome.reopened,
        recordedAt: DateTime.utc(2026),
      );
      final bytes = await sqliteBackupSnapshot(
        database: db,
        target: File('${dir.path}/snapshot.sqlite'),
        redact: true,
      );
      final target = File('${dir.path}/logical.sqlite');
      await target.writeAsBytes(bytes);
      final raw = sqlite.sqlite3.open(target.path);
      final schema = SqliteBackupStorage.schema(raw);
      for (final table in ['actuals', 'evidences']) {
        raw.execute('CREATE TEMP TABLE copy_$table AS SELECT * FROM $table');
        raw.execute('DELETE FROM $table');
        raw.execute(
          'INSERT INTO $table SELECT * FROM copy_$table ORDER BY rowid DESC',
        );
        raw.execute('DROP TABLE copy_$table');
      }
      raw.close();
      final storage = SqliteBackupStorage(
        live: live,
        schemaVersion: db.schemaVersion,
        expectedSchema: schema,
        snapshot: live.readAsBytes,
        closeLive: () async {},
      );
      storage.validateFile(target);
      restored = AppDatabase.forTesting(NativeDatabase(target));
      final history = await DriftActualRepository(restored).list();
      expect(history.map((a) => a.outcome), [
        ActualOutcome.completed,
        ActualOutcome.reopened,
      ]);
      expect(history.first.evidence.map((e) => e.value), ['revised', 'second']);
      expect(history.first.evidence.first.history.single.value, 'revised');
      await restored.close();
      restored = null;
      final corrupt = sqlite.sqlite3.open(target.path);
      corrupt.execute(
        "UPDATE schema_metadata SET value = '{}' WHERE key LIKE 'actual_text_history_v1:%'",
      );
      corrupt.close();
      expect(
        () => storage.validateFile(target),
        throwsA(isA<ValidationError>()),
      );
    } finally {
      await restored?.close();
      await db.close();
      await dir.delete(recursive: true);
    }
  });
}
