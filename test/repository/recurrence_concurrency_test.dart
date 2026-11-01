import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/database/app_database.dart';
import 'package:planact/features/actuals/data/drift_actual_repository.dart';
import 'package:planact/features/actuals/domain/actual.dart';
import 'package:planact/features/commitments/application/commitment_plan_use_case.dart';
import 'package:planact/features/commitments/data/drift_commitment_plan_repository.dart';
import 'package:planact/features/commitments/data/drift_commitment_repository.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/finance/application/financial_expectation_use_cases.dart';
import 'package:planact/features/finance/data/drift_financial_expectation_repository.dart';
import 'package:planact/features/finance/domain/financial_expectation.dart';
import 'package:planact/features/scheduling/domain/occurrence.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';

// Repository acceptance: independent file-backed connections must contend at
// a writer held after the production schema_metadata UPDATE, before domain
// reads (NativeDatabase's contender is busy at BEGIN IMMEDIATE). A busy loser
// rolls back, explicit retry sees fresh committed state, dependent intent is
// unique, and manual/resolved/actual history survives retry and cold reopen.
// This does not claim native delivery, automatic busy retries or release signoff.
const _writerSql = 'UPDATE schema_metadata SET value = value WHERE key = ?';
const _deadline = Duration(seconds: 10);
const _tables = [
  'schedule_definitions',
  'occurrences',
  'reminder_rules',
  'reminder_instances',
  'financial_expectations',
  'actuals',
  'evidences',
  'account_entries',
  'transaction_matches',
  'entitlement_ledger_entries',
];

// Sticky interception also wraps Drift's transaction executor. The barrier is
// AFTER the real SQLite write, not before acquisition or around Future.wait.
class _WriterProbe extends QueryInterceptor {
  final acquired = Completer<void>();
  final release = Completer<void>();
  bool armed = false;
  bool hold = false;
  int transactionOpenAttempts = 0;
  int attempts = 0;

  @override
  Future<bool> ensureOpen(
    QueryExecutor executor,
    QueryExecutorUser user,
  ) async {
    if (!armed || executor is! TransactionExecutor) {
      return executor.ensureOpen(user);
    }
    transactionOpenAttempts++;
    try {
      return await executor.ensureOpen(user);
    } on SqliteException catch (error) {
      if (error.resultCode == 5) busyErrors++;
      rethrow;
    }
  }

  int successfulAcquisitions = 0;
  int busyErrors = 0;
  int domainReads = 0;

  @override
  Future<void> runCustom(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) async {
    if (!armed || statement != _writerSql) {
      return executor.runCustom(statement, args);
    }
    attempts++;
    expect(args, ['schema_version']);
    try {
      await executor.runCustom(statement, args);
    } on SqliteException catch (error) {
      if (error.resultCode == 5) busyErrors++;
      rethrow;
    }
    successfulAcquisitions++;
    if (hold) {
      hold = false;
      acquired.complete();
      await release.future.timeout(_deadline);
    }
  }

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    if (armed &&
        executor is TransactionExecutor &&
        [
          'commitment_cycles',
          'schedule_definitions',
          'occurrences',
        ].any(statement.contains)) {
      domainReads++;
      expect(
        successfulAcquisitions,
        greaterThan(0),
        reason: 'Domain reads must follow actual writer acquisition.',
      );
    }
    return executor.runSelect(statement, args);
  }
}

Future<Map<String, List<Map<String, Object?>>>> _snapshot(
  AppDatabase database,
) async => {
  for (final table in _tables)
    table: [
      for (final row
          in await database
              .customSelect('SELECT * FROM $table ORDER BY id')
              .get())
        row.data,
    ],
};

void _expectPreserved(
  Map<String, List<Map<String, Object?>>> before,
  Map<String, List<Map<String, Object?>>> after, {
  bool inferred = false,
}) {
  for (final table in _tables) {
    if (inferred && table == 'schedule_definitions') continue;
    for (final row in before[table]!) {
      expect(
        after[table]!.singleWhere((r) => r['id'] == row['id']),
        row,
        reason: '$table historical row must not be rewritten',
      );
    }
  }
  for (final table in [
    'actuals',
    'evidences',
    'account_entries',
    'transaction_matches',
    'entitlement_ledger_entries',
  ]) {
    expect(after[table], before[table]);
  }
}

void main() {
  // This suite intentionally opens two independent SQLite connections to
  // exercise real writer contention and retry behavior.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  for (final journal in ['delete', 'wal']) {
    for (final scenario in ['monthly', 'yearly', 'legacy monthly']) {
      test('$journal / $scenario: actual writer overlap, retry and cold reopen', () async {
        final directory = await Directory.systemTemp.createTemp(
          'recurrence-race-',
        );
        final file = File('${directory.path}/live.sqlite');
        final firstProbe = _WriterProbe();
        final secondProbe = _WriterProbe();
        final firstNative = NativeDatabase(file);
        final secondNative = NativeDatabase(file);
        final first = AppDatabase.forTesting(
          firstNative.interceptWith(firstProbe),
        );
        final second = AppDatabase.forTesting(
          secondNative.interceptWith(secondProbe),
        );
        AppDatabase? reopened;
        Future<int>? winner;
        var closed = false;
        try {
          expect(identical(firstNative, secondNative), isFalse);
          await first.customStatement('PRAGMA journal_mode = $journal');
          final firstRepo = DriftCommitmentPlanRepository(first);
          final secondRepo = DriftCommitmentPlanRepository(second);
          final yearly = scenario == 'yearly';
          final inferred = scenario == 'legacy monthly';
          final plan =
              await CreateCommitmentPlan(
                commitments: DriftCommitmentRepository(first),
                plans: firstRepo,
                financialExpectations: FinancialExpectationUseCases(
                  DriftFinancialExpectationRepository(first),
                ),
              )(
                title: 'تعهد تکرارشونده',
                kind: CommitmentKind.recurring,
                startAt: DateTime(2026, 1, 19, 18, 35),
                frequency: yearly
                    ? RecurrenceFrequency.yearly
                    : RecurrenceFrequency.monthly,
                recurrenceCalendar: RecurrenceCalendar.gregorian,
                reminderOffsets: const [
                  Duration(minutes: 30),
                  Duration(minutes: 60),
                ],
                financialDirection: FinancialExpectationDirection.outgoing,
                financialAmount: 123456,
              );
          await firstRepo.saveOccurrence(
            // The manual slot's ORIGINAL date lies inside the extension
            // window, while its moved date lies outside it.
            plan.occurrences[yearly ? 1 : 3].reschedule(
              DateTime(2035, 6, 3, 19),
            ),
          );
          await firstRepo.saveOccurrence(
            plan.occurrences[2].withStatus(OccurrenceStatus.cancelled),
          );
          await DriftActualRepository(first).recordOccurrenceActual(
            expected: plan.occurrences.first,
            outcome: ActualOutcome.completed,
            recordedAt: DateTime.utc(2026, 1, 19, 20),
            note: 'سابقه باید حفظ شود',
          );
          if (inferred) {
            final row = await first
                .select(first.scheduleDefinitions)
                .getSingle();
            final metadata =
                jsonDecode(row.recurrenceRule!) as Map<String, dynamic>;
            for (final key in [
              'formatVersion',
              'calendar',
              'monthOfYear',
              'generationReminderMinutes',
              'generationFinancialExpectation',
            ]) {
              metadata.remove(key);
            }
            await first.customStatement(
              'UPDATE schedule_definitions SET recurrence_rule = ? WHERE id = ?',
              [jsonEncode(metadata), row.id],
            );
          }
          // Open/migrate both connections BEFORE the lock experiment. Disable
          // blocking waits so synchronous native SQLite cannot block the Dart
          // isolate that must release the winning transaction's barrier.
          await second.customSelect('SELECT 1').get();
          for (final database in [first, second]) {
            await database.customStatement('PRAGMA busy_timeout = 0');
            expect(
              (await database.customSelect('PRAGMA journal_mode').getSingle())
                  .read<String>('journal_mode'),
              journal,
            );
          }
          expect(firstRepo.commandGate, isNull);
          expect(secondRepo.commandGate, isNull);
          final before = await _snapshot(first);
          expect(before['actuals'], hasLength(1));
          final today = yearly ? LocalDate(2027, 1, 1) : LocalDate(2026, 3, 1);
          firstProbe
            ..armed = true
            ..hold = true;
          secondProbe.armed = true;
          winner = firstRepo.extendRecurringSchedules(today);
          // Attach the expectation before awaiting the barrier, so unexpected
          // errors are never left as unhandled asynchronous failures.
          final winningResult = expectLater(winner, completion(1));
          await firstProbe.acquired.future.timeout(_deadline);
          expect(firstProbe.domainReads, 0);
          await expectLater(
            secondRepo.extendRecurringSchedules(today).timeout(_deadline),
            throwsA(
              isA<SqliteException>().having(
                (error) => error.resultCode,
                'SQLITE_BUSY',
                5,
              ),
            ),
          );
          // NativeDatabase opens an IMMEDIATE transaction: the loser can be
          // busy in ensureOpen before reaching the production UPDATE. Both
          // paths are real SQLite writer acquisition, not a mock busy error.
          expect(secondProbe.transactionOpenAttempts, 1);
          expect(secondProbe.attempts, 0);
          expect(secondProbe.busyErrors, 1);
          expect(secondProbe.successfulAcquisitions, 0);
          expect(secondProbe.domainReads, 0);
          // The winner is still holding SQLite's writer, with no domain reads
          // or inserts yet. The failed contender left all durable rows intact.
          expect(firstProbe.release.isCompleted, isFalse);
          expect(await _snapshot(second), before);
          firstProbe.release.complete();
          await winningResult;
          expect(firstProbe.successfulAcquisitions, 1);
          expect(firstProbe.domainReads, greaterThan(0));
          expect(await secondRepo.extendRecurringSchedules(today), 0);
          expect(secondProbe.successfulAcquisitions, 1);
          expect(secondProbe.domainReads, greaterThan(0));
          final after = await _snapshot(second);
          _expectPreserved(before, after, inferred: inferred);
          final added = after['occurrences']!
              .where(
                (r) =>
                    !before['occurrences']!.any((old) => old['id'] == r['id']),
              )
              .toList();
          expect(added, hasLength(1));
          final expectedDate = yearly ? '2029-1-19' : '2026-6-19';
          final projected = (await secondRepo.findByCommitmentId(
            plan.commitment.id,
          ))!;
          expect(
            projected.occurrences
                .singleWhere((row) => row.id.value == added.single['id'])
                .currentScheduledAt,
            yearly
                ? DateTime(2029, 1, 19, 18, 35)
                : DateTime(2026, 6, 19, 18, 35),
          );
          expect(
            added.single['occurrence_key'],
            '${plan.schedule.id.value}:$expectedDate',
          );
          expect(
            after['occurrences']!.map((r) => r['occurrence_key']).toSet(),
            hasLength(after['occurrences']!.length),
          );
          final id = added.single['id'];
          final rules = after['reminder_rules']!
              .where((r) => r['occurrence_id'] == id)
              .toList();
          expect(rules, hasLength(2));
          expect(rules.map((r) => r['offset_seconds']).toSet(), {-1800, -3600});
          for (final rule in rules) {
            expect(
              after['reminder_instances']!.where(
                (r) => r['rule_id'] == rule['id'],
              ),
              hasLength(1),
            );
          }
          final expectations = after['financial_expectations']!
              .where((r) => r['occurrence_id'] == id)
              .toList();
          expect(expectations, hasLength(1));
          expect(expectations.single['minor_units'], 123456);
          expect(expectations.single['direction'], 0);
          for (final counts in {
            'occurrences': 1,
            'reminder_rules': 2,
            'reminder_instances': 2,
            'financial_expectations': 1,
          }.entries) {
            expect(
              after[counts.key],
              hasLength(before[counts.key]!.length + counts.value),
            );
          }
          if (inferred) {
            final metadata = jsonDecode(
              after['schedule_definitions']!.single['recurrence_rule']!
                  as String,
            ) as Map<String, dynamic>;
            expect(metadata['generationReminderMinutes'], [30, 60]);
            expect(
              (metadata['generationFinancialExpectation'] as Map)['amount'],
              123456,
            );
            expect(metadata['legacyCalendarSemantics'], true);
          }
          expect(await firstRepo.extendRecurringSchedules(today), 0);
          expect(await _snapshot(first), after);
          await second.close();
          await first.close();
          closed = true;
          // Both original handles are closed: no shared executor, repository,
          // stream cache or connection state is retained for the reopen check.
          reopened = AppDatabase.forTesting(NativeDatabase(file));
          expect(await _snapshot(reopened), after);
          expect(
            await DriftCommitmentPlanRepository(reopened)
                .extendRecurringSchedules(today),
            0,
          );
          expect(await _snapshot(reopened), after);
          expect(
            await reopened.customSelect('PRAGMA foreign_key_check').get(),
            isEmpty,
          );
        } finally {
          if (!firstProbe.release.isCompleted) firstProbe.release.complete();
          if (winner != null) {
            try {
              await winner;
            } catch (_) {
              /* Original expectation reports it. */
            }
          }
          if (!closed) {
            await second.close();
            await first.close();
          }
          await reopened?.close();
          await directory.delete(recursive: true);
        }
      });
    }
  }
}
