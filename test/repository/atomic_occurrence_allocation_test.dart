import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/backup/data/sqlite_backup_snapshot.dart';
import 'package:planact/features/backup/data/sqlite_backup_storage.dart';
import 'package:planact/features/finance/data/drift_finance_repository.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/finance/domain/financial_expectation.dart';
import 'package:planact/features/reconciliation/application/atomic_occurrence_allocation_repository.dart';
import 'package:planact/features/reconciliation/data/drift_reconciliation_repository.dart';
import 'package:planact/features/reconciliation/domain/relationship_review.dart';

import 'package:sqlite3/sqlite3.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late Directory directory;
  late File file;
  late AppDatabase database;
  late DriftReconciliationRepository repository;
  late AccountEntry transaction;
  late StableId occurrence;
  Money money(int value, [String currency = 'IRR']) =>
      Money(minorUnits: value, currency: currency);
  Matcher error(OccurrenceAllocationErrorCode code) =>
      isA<OccurrenceAllocationException>().having((e) => e.code, 'code', code);

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('atomic-occurrence-');
    file = File('${directory.path}/state.sqlite');
    database = AppDatabase.forTesting(NativeDatabase(file));
    repository = DriftReconciliationRepository(database);
    final finance = DriftFinanceRepository(database);
    final account = FinancialAccount(
      id: StableId.generate(),
      name: 'حساب',
      currency: 'IRR',
      type: FinancialAccountType.bank,
    );
    await finance.saveAccount(account);
    transaction = AccountEntry(
      id: StableId.generate(),
      accountId: account.id,
      type: AccountEntryType.expense,
      amount: money(1000),
      occurredAt: DateTime.utc(2026),
    );
    await finance.saveEntry(transaction);
    final owner = StableId.generate().value;
    final cycle = StableId.generate().value;
    final schedule = StableId.generate().value;
    occurrence = StableId.generate();
    await database.customStatement(
      'INSERT INTO commitments(id,title,created_at,status) VALUES (?, ?, 0, 0)',
      [owner, 'کلاس'],
    );
    await database.customStatement(
      'INSERT INTO commitment_cycles VALUES (?, ?, 0, 0, NULL, NULL, NULL, 0, 0, 1)',
      [cycle, owner],
    );
    await database.customStatement(
      "INSERT INTO schedule_definitions VALUES (?, ?, 0, 0, '2026-01-01', NULL, NULL, NULL, NULL, NULL, NULL, 1, '2026-01-01', 90)",
      [schedule, cycle],
    );
    await database.customStatement(
      "INSERT INTO occurrences VALUES (?, ?, ?, 'one', 0, '2026-01-01', '2026-01-01', 0, 0)",
      [occurrence.value, cycle, schedule],
    );
  });
  tearDown(() async {
    await database.close();
    await directory.delete(recursive: true);
  });
  Future<OccurrenceAllocationSnapshot> load() =>
      repository.loadOccurrenceAllocation(transaction.id, occurrence);
  Future<int> count(String table) async =>
      (await database
              .customSelect('SELECT COUNT(*) AS n FROM $table')
              .getSingle())
          .read<int>('n');
  Future<void> expectation({String? currency = 'IRR', int status = 0}) =>
      database.customStatement(
        'INSERT INTO financial_expectations(id,occurrence_id,direction,minor_units,currency,status,created_at,updated_at) VALUES (?, ?, 0, 1000, ?, ?, 0, 0)',
        [StableId.generate().value, occurrence.value, currency, status],
      );

  test('opening writes nothing; explicit total and partial then second payment survive cold reopen', () async {
    final before =
        (await database.customSelect('SELECT total_changes() AS n').getSingle())
            .read<int>('n');
    final snapshot = await load();
    expect(snapshot.expectationState, OccurrenceExpectationState.missing);
    expect(snapshot.suggestedDirection, FinancialExpectationDirection.outgoing);
    expect(
      (await database.customSelect('SELECT total_changes() AS n').getSingle())
          .read<int>('n'),
      before,
    );
    final match = await repository.confirmOccurrenceAllocation(
      snapshot,
      total: money(700),
      allocation: money(300),
    );
    expect(match.allocatedMinorUnits, 300);
    final next = await load();
    expect(next.expectedTotal, money(700));
    expect(next.expectationCapacity, money(400));
    await repository.confirmOccurrenceAllocation(next, allocation: money(400));
    await database.close();
    database = AppDatabase.forTesting(NativeDatabase(file));
    repository = DriftReconciliationRepository(database);
    expect((await load()).expectationCapacity, money(0));
    expect(await count('financial_expectations'), 1);
    expect(await count('transaction_matches'), 2);
    expect(await count('account_entries'), 1);
    expect(await count('relationship_reviews'), 0);
    expect(await count('entitlement_ledger_entries'), 0);
  });

  test('strict personal-backup snapshot retains atomic expectation and two allocations on reopen', () async {
    final first = await repository.confirmOccurrenceAllocation(
      await load(),
      total: money(700),
      allocation: money(300),
    );
    final second = await repository.confirmOccurrenceAllocation(
      await load(),
      allocation: money(400),
    );
    expect(first.id, isNot(second.id));
    final before = await load();
    expect(before.expectationState, OccurrenceExpectationState.existing);
    expect(before.expectedTotal, money(700));
    expect(before.expectationCapacity, money(0));
    expect(before.transactionCapacity, money(300));

    const retainedTables = [
      'financial_expectations',
      'transaction_matches',
      'match_allocations',
      'account_entries',
    ];
    Future<List<Map<String, Object?>>> rows(
      AppDatabase db,
      String table,
    ) async => [
      for (final row
          in await db.customSelect('SELECT * FROM $table ORDER BY id').get())
        Map<String, Object?>.from(row.data),
    ];
    final expected = {
      for (final table in retainedTables) table: await rows(database, table),
    };
    expect(expected['financial_expectations'], hasLength(1));
    expect(expected['transaction_matches'], hasLength(2));
    expect(expected['match_allocations'], hasLength(2));
    expect(expected['account_entries'], hasLength(1));

    final schemaDatabase = sqlite3.open(file.path, mode: OpenMode.readOnly);
    late List<String> expectedSchema;
    try {
      expectedSchema = SqliteBackupStorage.schema(schemaDatabase);
    } finally {
      schemaDatabase.close();
    }
    final storage = SqliteBackupStorage(
      live: file,
      schemaVersion: database.schemaVersion,
      expectedSchema: expectedSchema,
      snapshot: () => sqliteBackupSnapshot(
        database: database,
        target: File('${directory.path}/safety.sqlite'),
        redact: false,
      ),
      closeLive: database.close,
    );
    final payload = await sqliteBackupSnapshot(
      database: database,
      target: File('${directory.path}/snapshot.sqlite'),
      redact: true,
    );
    await expectLater(storage.validatePayload(payload), completes);

    final restoredFile = File('${directory.path}/restored.sqlite');
    await restoredFile.writeAsBytes(payload, flush: true);
    await database.close();
    final restored = AppDatabase.forTesting(NativeDatabase(restoredFile));
    try {
      final restoredSnapshot = await DriftReconciliationRepository(restored)
          .loadOccurrenceAllocation(transaction.id, occurrence);
      expect(restoredSnapshot.expectationState, before.expectationState);
      expect(restoredSnapshot.expectedTotal, before.expectedTotal);
      expect(restoredSnapshot.expectationCapacity, before.expectationCapacity);
      expect(restoredSnapshot.transactionCapacity, before.transactionCapacity);
      expect(restoredSnapshot.fingerprint, before.fingerprint);
      for (final table in retainedTables) {
        expect(await rows(restored, table), expected[table], reason: table);
      }
    } finally {
      await restored.close();
    }
  });

  test('missing total, invalid amounts, currency and both caps reject without partial writes', () async {
    final snapshot = await load();
    await expectLater(
      repository.confirmOccurrenceAllocation(snapshot, allocation: money(1)),
      throwsA(error(OccurrenceAllocationErrorCode.missing)),
    );
    for (final (total, allocation, code) in [
      (money(2000), money(1001), OccurrenceAllocationErrorCode.capacity),
      (money(200), money(201), OccurrenceAllocationErrorCode.capacity),
      (money(0), money(1), OccurrenceAllocationErrorCode.capacity),
      (money(200), money(0), OccurrenceAllocationErrorCode.capacity),
      (money(200, 'USD'), money(1), OccurrenceAllocationErrorCode.currency),
    ]) {
      await expectLater(
        repository.confirmOccurrenceAllocation(
          snapshot,
          total: total,
          allocation: allocation,
        ),
        throwsA(error(code)),
      );
      expect(await count('financial_expectations'), 0);
      expect(await count('transaction_matches'), 0);
    }
  });

  test(
    'allocation insert failure rolls back expectation and retry works',
    () async {
      final snapshot = await load();
      await database.customStatement(
        "CREATE TRIGGER fail_allocation BEFORE INSERT ON match_allocations BEGIN SELECT RAISE(ABORT, 'test'); END",
      );
      await expectLater(
        repository.confirmOccurrenceAllocation(
          snapshot,
          total: money(500),
          allocation: money(200),
        ),
        throwsA(error(OccurrenceAllocationErrorCode.storage)),
      );
      expect(await count('financial_expectations'), 0);
      expect(await count('transaction_matches'), 0);
      await database.customStatement('DROP TRIGGER fail_allocation');
      await repository.confirmOccurrenceAllocation(
        snapshot,
        total: money(500),
        allocation: money(200),
      );
    },
  );

  test(
    'independent connections compare snapshot after writer admission',
    () async {
      final second = AppDatabase.forTesting(NativeDatabase(file));
      try {
        final other = DriftReconciliationRepository(second);
        final a = await load();
        final b = await other.loadOccurrenceAllocation(
          transaction.id,
          occurrence,
        );
        await repository.confirmOccurrenceAllocation(
          a,
          total: money(500),
          allocation: money(200),
        );
        await expectLater(
          other.confirmOccurrenceAllocation(
            b,
            total: money(500),
            allocation: money(200),
          ),
          throwsA(error(OccurrenceAllocationErrorCode.stale)),
        );
        expect(await count('financial_expectations'), 1);
        expect(await count('transaction_matches'), 1);
      } finally {
        await second.close();
      }
    },
  );

  test('expectation-set, transaction, account, occurrence, owner and cycle changes invalidate', () async {
    for (final sql in [
      "UPDATE account_entries SET note = 'changed'",
      "UPDATE financial_accounts SET name = 'changed'",
      "UPDATE commitments SET title = 'changed'",
      'UPDATE commitment_cycles SET consumed_units = consumed_units + 1',
      "UPDATE occurrences SET current_scheduled_value = '2026-01-02'",
    ]) {
      final before = await load();
      await database.customStatement(sql);
      await expectLater(
        repository.confirmOccurrenceAllocation(
          before,
          total: money(500),
          allocation: money(1),
        ),
        throwsA(error(OccurrenceAllocationErrorCode.stale)),
      );
    }
    final before = await load();
    await expectation();
    await expectLater(
      repository.confirmOccurrenceAllocation(
        before,
        total: money(500),
        allocation: money(1),
      ),
      throwsA(error(OccurrenceAllocationErrorCode.stale)),
    );
    expect(await count('transaction_matches'), 0);
  });

  test('ambiguous retained expectations and unknown/wrong currencies never become uncapped', () async {
    await expectation(status: 1);
    expect(
      (await load()).expectationState,
      OccurrenceExpectationState.ambiguous,
    );
    await expectLater(
      repository.confirmOccurrenceAllocation(
        await load(),
        total: money(500),
        allocation: money(1),
      ),
      throwsA(error(OccurrenceAllocationErrorCode.ambiguous)),
    );
    await database.customStatement('DELETE FROM financial_expectations');
    await expectation(currency: null);
    await expectLater(
      repository.confirmOccurrenceAllocation(
        await load(),
        allocation: money(1),
      ),
      throwsA(error(OccurrenceAllocationErrorCode.currency)),
    );
  });

  test('review ABA and historical/inactive guards are retained', () async {
    final snapshot = await load();
    var review = await repository.loadReview(transaction);
    review = await repository.decideReview(
      expected: review,
      decision: RelationshipReviewDecision.independent,
      recordedAt: DateTime.utc(2026),
    );
    await repository.decideReview(
      expected: review,
      decision: RelationshipReviewDecision.reopened,
      recordedAt: DateTime.utc(2026),
    );
    await expectLater(
      repository.confirmOccurrenceAllocation(
        snapshot,
        total: money(500),
        allocation: money(1),
      ),
      throwsA(error(OccurrenceAllocationErrorCode.stale)),
    );
    await database.customStatement('UPDATE commitment_cycles SET status = 2');
    await expectLater(
      load(),
      throwsA(error(OccurrenceAllocationErrorCode.historicalInactive)),
    );
    await database.customStatement('UPDATE commitment_cycles SET status = 1');
    await database.customStatement('UPDATE commitments SET status = 1');
    await expectLater(
      load(),
      throwsA(error(OccurrenceAllocationErrorCode.historicalInactive)),
    );
  });
}
