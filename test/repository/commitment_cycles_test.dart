import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/core/errors/app_error.dart';
import 'package:planact/features/actuals/data/drift_actual_repository.dart';
import 'package:planact/features/actuals/domain/actual.dart';
import 'package:planact/features/backup/data/sqlite_backup_snapshot.dart';
import 'package:planact/features/commitments/application/commitment_cycles.dart';
import 'package:planact/features/commitments/application/commitment_plan_use_case.dart';
import 'package:planact/features/commitments/data/drift_commitment_plan_repository.dart';
import 'package:planact/features/commitments/data/drift_commitment_repository.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/commitments/domain/commitment_cycle.dart';
import 'package:planact/features/finance/application/financial_expectation_use_cases.dart';
import 'package:planact/features/finance/data/drift_financial_expectation_repository.dart';
import 'package:planact/features/finance/domain/financial_expectation.dart';
import 'package:planact/features/reminders/data/drift_reminder_repository.dart';
import 'package:planact/features/reminders/domain/reminder.dart';

CreateCommitmentPlan command(AppDatabase db) => CreateCommitmentPlan(
  commitments: DriftCommitmentRepository(db),
  plans: DriftCommitmentPlanRepository(db),
  financialExpectations: FinancialExpectationUseCases(
    DriftFinancialExpectationRepository(db),
  ),
);

Future<void> resolve(AppDatabase db, CommitmentPlan plan) async {
  for (final occurrence in plan.occurrences) {
    await DriftActualRepository(db).recordOccurrenceActual(
      expected: occurrence,
      outcome: ActualOutcome.completed,
      recordedAt: DateTime(2026, 1, 1, 19),
    );
  }
}

Future<NewCommitmentCycleContext> context(
  DriftCommitmentPlanRepository repo,
  CommitmentPlan plan,
) async => NewCommitmentCycleContext(
  commitmentId: plan.commitment.id,
  expectedCycleSet: await repo.cycleSetToken(plan.commitment.id),
);

void main() {
  test(
    'independent SQLite writers cannot create two active cycles from one token',
    () async {
      final directory = await Directory.systemTemp.createTemp('cycles-race-');
      final file = File('${directory.path}/live.sqlite');
      final db = AppDatabase.forTesting(NativeDatabase(file));
      AppDatabase? other;
      try {
        final repo = DriftCommitmentPlanRepository(db);
        final first = await command(db)(
          title: 'ترم',
          startAt: DateTime(2026, 1, 1, 18),
        );
        await resolve(db, first);
        await repo.completeCycle(
          cycleId: first.cycle.id,
          expectedCycleSet: await repo.cycleSetToken(first.commitment.id),
          completedAt: DateTime(2026, 1, 1, 20),
        );
        final fresh = await context(repo, first);
        other = AppDatabase.forTesting(NativeDatabase(file));
        await other.customSelect('SELECT 1').get();
        Future<bool> attempt(AppDatabase target) async {
          try {
            await command(target)(
              title: 'next',
              startAt: DateTime(2026, 1, 2, 18),
              newCycle: fresh,
            );
            return true;
          } on ValidationError {
            return false;
          } on SqliteException catch (error) {
            if (error.resultCode != 5 && error.resultCode != 6) rethrow;
            return false;
          }
        }

        final results = await Future.wait([attempt(db), attempt(other)]);
        expect(results.where((success) => success), hasLength(1));
        final cycles = await repo.listByCommitmentId(first.commitment.id);
        expect(cycles, hasLength(2));
        expect(
          cycles.where((p) => p.cycle.status == CommitmentCycleStatus.active),
          hasLength(1),
        );
        await expectLater(
          command(other)(
            title: 'stale',
            startAt: DateTime(2026, 1, 3),
            newCycle: fresh,
          ),
          throwsA(isA<ValidationError>()),
        );
      } finally {
        await other?.close();
        await db.close();
        await directory.delete(recursive: true);
      }
    },
  );
  test(
    'two independent cycles survive cold reopen and personal backup snapshot',
    () async {
      final directory = await Directory.systemTemp.createTemp('cycles-');
      final file = File('${directory.path}/live.sqlite');
      var db = AppDatabase.forTesting(NativeDatabase(file));
      try {
        var repo = DriftCommitmentPlanRepository(db);
        final first = await command(db)(
          title: 'ترم',
          startAt: DateTime(2026, 1, 1, 18),
        );
        await resolve(db, first);
        await repo.completeCycle(
          cycleId: first.cycle.id,
          expectedCycleSet: await repo.cycleSetToken(first.commitment.id),
          completedAt: DateTime(2026, 1, 1, 20),
        );
        final old = (await repo.findByCycleId(first.cycle.id))!;
        final second = await command(db)(
          title: 'ignored owner metadata',
          startAt: DateTime(2026, 1, 2, 18),
          newCycle: await context(repo, first),
          reminderOffsets: const [Duration(minutes: 30)],
          financialDirection: FinancialExpectationDirection.outgoing,
          financialAmount: 12345,
        );
        expect(second.commitment.id, first.commitment.id);
        expect(second.commitment.title, 'ترم');
        expect(second.cycle.id, isNot(first.cycle.id));
        expect(await db.select(db.commitments).get(), hasLength(1));
        expect(await db.select(db.entitlementLedgerEntries).get(), isEmpty);
        expect(await db.select(db.accountEntries).get(), isEmpty);
        await db.close();
        db = AppDatabase.forTesting(NativeDatabase(file));
        repo = DriftCommitmentPlanRepository(db);
        final plans = await repo.listByCommitmentId(first.commitment.id);
        expect(plans.map((p) => p.cycle.id), [first.cycle.id, second.cycle.id]);
        expect(plans.first.cycle.status, CommitmentCycleStatus.completed);
        expect(
          plans.first.occurrences.single.status,
          old.occurrences.single.status,
        );
        expect(
          (await repo.findByCommitmentId(first.commitment.id))!.cycle.id,
          second.cycle.id,
        );
        final backupFile = File('${directory.path}/backup.sqlite');
        final bytes = await sqliteBackupSnapshot(
          database: db,
          target: backupFile,
          redact: true,
        );
        expect(bytes, isNotEmpty);
        await backupFile.writeAsBytes(bytes, flush: true);
        final backup = AppDatabase.forTesting(NativeDatabase(backupFile));
        try {
          final restored = await DriftCommitmentPlanRepository(backup)
              .listByCommitmentId(first.commitment.id);
          expect(restored.map((p) => p.cycle.id), [
            first.cycle.id,
            second.cycle.id,
          ]);
          expect(
            restored.first.cycle.actualEndDate,
            plans.first.cycle.actualEndDate,
          );
          expect(
            await backup.select(backup.financialExpectations).get(),
            hasLength(1),
          );
          expect(await backup.select(backup.reminderRules).get(), hasLength(1));
        } finally {
          await backup.close();
        }
        await expectLater(repo.save(old), throwsA(isA<ValidationError>()));
        await expectLater(
          repo.saveOccurrence(old.occurrences.single),
          throwsA(isA<ValidationError>()),
        );
        await expectLater(
          DriftActualRepository(db).recordOccurrenceActual(
            expected: old.occurrences.single,
            outcome: ActualOutcome.reopened,
            recordedAt: DateTime(2026, 1, 3),
          ),
          throwsA(isA<ValidationError>()),
        );
      } finally {
        await db.close();
        await directory.delete(recursive: true);
      }
    },
  );

  test(
    'unresolved, overlapping, stale and inactive requests write nothing',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      try {
        final repo = DriftCommitmentPlanRepository(db);
        final first = await command(db)(
          title: 'ترم',
          startAt: DateTime(2026, 1, 1, 18),
        );
        final stale = await context(repo, first);
        await expectLater(
          repo.completeCycle(
            cycleId: first.cycle.id,
            expectedCycleSet: stale.expectedCycleSet,
            completedAt: DateTime(2026, 1, 1, 20),
          ),
          throwsA(isA<ValidationError>()),
        );
        await expectLater(
          command(db)(
            title: 'next',
            startAt: DateTime(2026, 1, 2),
            newCycle: stale,
          ),
          throwsA(isA<ValidationError>()),
        );
        await resolve(db, first);
        await expectLater(
          repo.completeCycle(
            cycleId: first.cycle.id,
            expectedCycleSet: stale.expectedCycleSet,
            completedAt: DateTime(2026, 1, 1, 20),
          ),
          throwsA(isA<ValidationError>()),
        );
        await repo.completeCycle(
          cycleId: first.cycle.id,
          expectedCycleSet: await repo.cycleSetToken(first.commitment.id),
          completedAt: DateTime(2026, 1, 1, 20),
        );
        final fresh = await context(repo, first);
        await expectLater(
          command(db)(
            title: 'next',
            startAt: DateTime(2026, 1, 1, 23),
            newCycle: fresh,
          ),
          throwsA(isA<ValidationError>()),
        );
        await DriftCommitmentRepository(db)
            .changeStatus(first.commitment.id, CommitmentStatus.paused);
        await expectLater(
          command(db)(
            title: 'next',
            startAt: DateTime(2026, 1, 2),
            newCycle: fresh,
          ),
          throwsA(isA<ValidationError>()),
        );
        expect(await db.select(db.commitments).get(), hasLength(1));
        expect(
          await repo.listByCommitmentId(first.commitment.id),
          hasLength(1),
        );
      } finally {
        await db.close();
      }
    },
  );

  test('lifecycle Undo restores only the current cycle and historical rules stay read-only', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    try {
      final repo = DriftCommitmentPlanRepository(db);
      final owners = DriftCommitmentRepository(db);
      final reminders = DriftReminderRepository(db);
      final first = await command(db)(
        title: 'ترم',
        startAt: DateTime(2026, 1, 1, 18),
        reminderOffsets: const [Duration(minutes: 30)],
      );
      final oldRule = (await reminders.listRules()).single;
      await reminders.saveInstance(
        ReminderInstance.fromRule(
          rule: oldRule,
          occurrenceStart: DateTime(2026, 1, 1, 18),
        ),
      );
      await resolve(db, first);
      await repo.completeCycle(
        cycleId: first.cycle.id,
        expectedCycleSet: await repo.cycleSetToken(first.commitment.id),
        completedAt: DateTime(2026, 1, 1, 20),
      );
      final second = await command(db)(
        title: 'ignored',
        startAt: DateTime(2026, 1, 2, 18),
        newCycle: await context(repo, first),
        reminderOffsets: const [Duration(minutes: 30)],
      );
      final newRule = (await reminders.listRules()).singleWhere(
        (r) => r.occurrenceId == second.occurrences.single.id,
      );
      await reminders.saveInstance(
        ReminderInstance.fromRule(
          rule: newRule,
          occurrenceStart: DateTime(2026, 1, 2, 18),
        ),
      );
      await owners.changeStatus(first.commitment.id, CommitmentStatus.archived);
      expect(
        (await reminders.listInstances()).every(
          (r) => r.status == ReminderInstanceStatus.cancelled,
        ),
        isTrue,
      );
      await owners.undoStatus(
        first.commitment.id,
        (await owners.statusUndo(first.commitment.id))!,
      );
      final restored = await reminders.listInstances();
      expect(
        restored.singleWhere((r) => r.ruleId == oldRule.id).status,
        ReminderInstanceStatus.cancelled,
      );
      expect(
        restored.singleWhere((r) => r.ruleId == newRule.id).status,
        ReminderInstanceStatus.scheduled,
      );
      expect(
        (await repo.findByCycleId(first.cycle.id))!.cycle.status,
        CommitmentCycleStatus.completed,
      );
      await expectLater(
        reminders.saveRule(oldRule),
        throwsA(isA<ValidationError>()),
      );
      await expectLater(
        reminders.saveInstance(
          ReminderInstance.fromRule(
            rule: oldRule,
            occurrenceStart: DateTime(2026, 1, 3),
          ),
        ),
        throwsA(isA<ValidationError>()),
      );
    } finally {
      await db.close();
    }
  });

  test('failure after cycle insertion rolls back all effects; competing requests admit once', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    try {
      final repo = DriftCommitmentPlanRepository(db);
      final first = await command(db)(
        title: 'ترم',
        startAt: DateTime(2026, 1, 1, 18),
      );
      await resolve(db, first);
      await repo.completeCycle(
        cycleId: first.cycle.id,
        expectedCycleSet: await repo.cycleSetToken(first.commitment.id),
        completedAt: DateTime(2026, 1, 1, 20),
      );
      final fresh = await context(repo, first);
      await db.customStatement(
        "CREATE TRIGGER reject_cycle_occurrence BEFORE INSERT ON occurrences BEGIN SELECT RAISE(ABORT, 'injected'); END",
      );
      await expectLater(
        command(db)(
          title: 'next',
          startAt: DateTime(2026, 1, 2),
          newCycle: fresh,
          reminderOffsets: const [Duration(minutes: 30)],
        ),
        throwsA(anything),
      );
      expect(
        await repo.cycleSetToken(first.commitment.id),
        fresh.expectedCycleSet,
      );
      expect(await db.select(db.reminderRules).get(), isEmpty);
      await db.customStatement('DROP TRIGGER reject_cycle_occurrence');
      Future<bool> attempt() async {
        try {
          await command(db)(
            title: 'next',
            startAt: DateTime(2026, 1, 2),
            newCycle: fresh,
          );
          return true;
        } on ValidationError {
          return false;
        }
      }

      final results = await Future.wait([attempt(), attempt()]);
      expect(results.where((success) => success), hasLength(1));
      expect(await repo.listByCommitmentId(first.commitment.id), hasLength(2));
    } finally {
      await db.close();
    }
  });
}
