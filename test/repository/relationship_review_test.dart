import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/core/errors/app_error.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/backup/data/sqlite_backup_snapshot.dart';
import 'package:planact/features/finance/application/finance_use_cases.dart';
import 'package:planact/features/finance/data/drift_finance_repository.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/reconciliation/application/reconciliation_use_cases.dart';
import 'package:planact/features/reconciliation/data/drift_reconciliation_repository.dart';
import 'package:planact/features/reconciliation/domain/reconciliation.dart';
import 'package:planact/features/reconciliation/domain/relationship_review.dart';

void main() {
  // Restore and concurrency cases intentionally create independent database
  // owners against separate or restored SQLite files.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late Directory directory;
  late File file;
  late AppDatabase database;
  late DriftReconciliationRepository repository;
  late AccountEntry transaction;
  late StableId occurrence;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('relationship-review-');
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
      amount: const Money(minorUnits: 1000, currency: 'IRR'),
      occurredAt: DateTime.utc(2026),
    );
    await finance.saveEntry(transaction);
    final commitment = StableId.generate().value;
    final cycle = StableId.generate().value;
    final schedule = StableId.generate().value;
    occurrence = StableId.generate();
    await database.customStatement(
      'INSERT INTO commitments(id,title,created_at,status) VALUES (?, ?, 0, 0)',
      [commitment, 'کلاس'],
    );
    await database.customStatement(
      'INSERT INTO commitment_cycles VALUES (?, ?, 0, 0, NULL, NULL, NULL, 0, 0, 1)',
      [cycle, commitment],
    );
    await database.customStatement(
      "INSERT INTO schedule_definitions VALUES (?, ?, 0, 0, '2026-01-01', NULL, NULL, NULL, NULL, NULL, NULL, 1, '2026-01-01', 90)",
      [schedule, cycle],
    );
    await database.customStatement(
      "INSERT INTO occurrences VALUES (?, ?, ?, 'one', 0, '2026-01-01', '2026-01-01', 0, 0)",
      [occurrence.value, cycle, schedule],
    );
    await database.customStatement(
      'INSERT INTO financial_expectations(id,occurrence_id,direction,minor_units,currency,status,created_at,updated_at) VALUES (?, ?, 0, 1000, ?, 0, 0, 0)',
      [StableId.generate().value, occurrence.value, 'IRR'],
    );
  });
  tearDown(() async {
    await database.close();
    await directory.delete(recursive: true);
  });

  Future<TransactionMatch> match(int amount, {RelationshipReview? expected}) =>
      ReconciliationUseCases(repository).match(
        transactionId: transaction.id,
        transactionAmount: transaction.amount,
        createdAt: DateTime.now().toUtc(),
        occurrenceIds: [occurrence],
        allocations: [Money(minorUnits: amount, currency: 'IRR')],
        expectedReview: expected,
      );

  Future<RelationshipReview> independent(RelationshipReview expected) =>
      repository.decideReview(
        expected: expected,
        decision: RelationshipReviewDecision.independent,
        recordedAt: DateTime.utc(2026),
      );

  Future<AccountEntry> anotherTransaction({int amount = 1000}) async {
    final entry = AccountEntry(
      id: StableId.generate(),
      accountId: transaction.accountId,
      type: AccountEntryType.expense,
      amount: Money(minorUnits: amount, currency: 'IRR'),
      occurredAt: DateTime.utc(2026),
    );
    await DriftFinanceRepository(database).saveEntry(entry);
    return entry;
  }

  Future<TransactionMatch> allocate(
    AccountEntry entry,
    int amount, {
    DriftReconciliationRepository? writer,
  }) => ReconciliationUseCases(writer ?? repository).match(
    transactionId: entry.id,
    transactionAmount: entry.amount,
    createdAt: DateTime.utc(2026),
    occurrenceIds: [occurrence],
    allocations: [Money(minorUnits: amount, currency: 'IRR')],
  );

  test(
    'approved excess remains transaction remainder, never transferable credit',
    () async {
      await database.customStatement(
        'UPDATE financial_expectations SET minor_units=1000000',
      );
      final entry = await anotherTransaction(amount: 1200000);
      await expectLater(
        allocate(entry, 1000001),
        throwsA(isA<ValidationError>()),
      );
      expect(await repository.list(), isEmpty);
      await allocate(entry, 1000000);
      expect((await repository.loadReview(entry)).remainderMinorUnits, 200000);
      await expectLater(allocate(entry, 1), throwsA(isA<ValidationError>()));
      expect(
        (await DriftFinanceRepository(database).listEntries()),
        hasLength(2),
      );
    },
  );

  test(
    'partial many-to-many payments aggregate duplicate occurrence rows',
    () async {
      final secondOccurrence = StableId.generate();
      await database.customStatement(
        'INSERT INTO occurrences SELECT ?,cycle_id,schedule_definition_id,?,time_semantics,original_scheduled_value,current_scheduled_value,status,is_manual_override FROM occurrences WHERE id=?',
        [secondOccurrence.value, 'two', occurrence.value],
      );
      await database.customStatement(
        'INSERT INTO financial_expectations(id,occurrence_id,direction,minor_units,currency,status,created_at,updated_at) VALUES (?, ?, 0, 500, ?, 0, 0, 0)',
        [StableId.generate().value, secondOccurrence.value, 'IRR'],
      );
      await match(400);
      final other = await anotherTransaction();
      final commands = ReconciliationUseCases(repository);
      await expectLater(
        commands.match(
          transactionId: other.id,
          transactionAmount: other.amount,
          createdAt: DateTime.utc(2026),
          occurrenceIds: [occurrence, occurrence],
          allocations: const [
            Money(minorUnits: 400, currency: 'IRR'),
            Money(minorUnits: 201, currency: 'IRR'),
          ],
        ),
        throwsA(isA<ValidationError>()),
      );
      await commands.match(
        transactionId: other.id,
        transactionAmount: other.amount,
        createdAt: DateTime.utc(2026),
        occurrenceIds: [occurrence, secondOccurrence],
        allocations: const [
          Money(minorUnits: 600, currency: 'IRR'),
          Money(minorUnits: 300, currency: 'IRR'),
        ],
      );
      expect((await repository.loadReview(other)).remainderMinorUnits, 100);
      await expectLater(
        allocate(transaction, 1),
        throwsA(isA<ValidationError>()),
      );
      expect(await repository.list(), hasLength(2));
    },
  );

  test(
    'expectation cap serializes different transactions on separate writers',
    () async {
      final otherEntry = await anotherTransaction();
      final second = AppDatabase.forTesting(NativeDatabase(file));
      try {
        final writer = DriftReconciliationRepository(second);
        await second.readMetadata('schema_version');
        final outcomes = await Future.wait([
          allocate(
            transaction,
            600,
          ).then((_) => true, onError: (Object _) => false),
          allocate(
            otherEntry,
            600,
            writer: writer,
          ).then((_) => true, onError: (Object _) => false),
        ]);
        expect(outcomes.where((value) => value), hasLength(1));
        final saved = (await repository.list()).single;
        final loser = saved.transactionId == transaction.id
            ? otherEntry
            : transaction;
        await expectLater(
          allocate(loser, 401, writer: writer),
          throwsA(isA<ValidationError>()),
        );
        await allocate(loser, 400, writer: writer);
        expect(
          (await repository.list()).fold<int>(
            0,
            (sum, m) => sum + m.allocatedMinorUnits,
          ),
          1000,
        );
      } finally {
        await second.close();
      }
    },
  );

  test(
    'fresh expectation edits reject stale proposal and correction rolls back',
    () async {
      final original = await match(400);
      final other = await anotherTransaction();
      await allocate(other, 300);
      await expectLater(
        ReconciliationUseCases(repository).correct(
          original: original,
          createdAt: DateTime.utc(2026),
          occurrenceIds: [occurrence],
          allocations: const [Money(minorUnits: 701, currency: 'IRR')],
        ),
        throwsA(isA<ValidationError>()),
      );
      expect(
        (await repository.list()).firstWhere((m) => m.id == original.id).status,
        MatchStatus.active,
      );
      final corrected = await ReconciliationUseCases(repository).correct(
        original: original,
        createdAt: DateTime.utc(2026),
        occurrenceIds: [occurrence],
        allocations: const [Money(minorUnits: 700, currency: 'IRR')],
      );
      expect(corrected.allocatedMinorUnits, 700);
      await expectLater(
        ReconciliationUseCases(repository).correct(
          original: original,
          createdAt: DateTime.utc(2026),
          occurrenceIds: [occurrence],
          allocations: const [Money(minorUnits: 1, currency: 'IRR')],
        ),
        throwsA(isA<ValidationError>()),
      );
      await database.customStatement(
        'UPDATE financial_expectations SET minor_units=500',
      );
      await expectLater(allocate(other, 1), throwsA(isA<ValidationError>()));
      expect(await repository.list(), hasLength(3));
    },
  );

  test(
    'historical overallocations survive cold reopen and explicit correction',
    () async {
      final original = await match(900);
      await database.customStatement(
        'UPDATE financial_expectations SET minor_units=500',
      );
      final before = allocationFingerprintFor(await repository.list());
      await database.close();
      database = AppDatabase.forTesting(NativeDatabase(file));
      repository = DriftReconciliationRepository(database);
      expect(allocationFingerprintFor(await repository.list()), before);
      await repository.save(
        original,
      ); // Idempotent historical save is not a new allocation.
      final other = await anotherTransaction();
      await expectLater(allocate(other, 1), throwsA(isA<ValidationError>()));
      await ReconciliationUseCases(repository).correct(
        original: original,
        createdAt: DateTime.utc(2026),
        occurrenceIds: [occurrence],
        allocations: const [Money(minorUnits: 500, currency: 'IRR')],
      );
      final history = (await repository.list()).firstWhere(
        (m) => m.id == original.id,
      );
      expect(history.allocations.single.amount.minorUnits, 900);
      expect(history.status, MatchStatus.corrected);
    },
  );

  test('reversed transactions release expectation capacity without rewriting matches', () async {
    final original = await match(1000);
    final finance = DriftFinanceRepository(database);
    await FinanceUseCases(finance).voidEntry(
      original: transaction,
      account: (await finance.listAccounts()).single,
    );
    final other = await anotherTransaction();
    await allocate(other, 1000);
    expect(
      (await repository.list()).firstWhere((m) => m.id == original.id).status,
      MatchStatus.active,
    );
    expect(
      (await repository.list())
          .firstWhere((m) => m.id == original.id)
          .allocatedMinorUnits,
      1000,
    );
  });

  test('unchanged transaction review cannot bypass a freshly reduced expectation', () async {
    final expected = await repository.loadReview(transaction);
    final second = AppDatabase.forTesting(NativeDatabase(file));
    try {
      await second.customStatement(
        'UPDATE financial_expectations SET minor_units=300',
      );
      // Review tokens cover this transaction, not a stale expectation preview.
      (await repository.loadReview(transaction)).requireExpected(expected);
      await expectLater(
        match(400, expected: expected),
        throwsA(isA<ValidationError>()),
      );
      expect(await repository.list(), isEmpty);
      await match(300, expected: expected);
      expect(
        (await repository.loadReview(transaction)).remainderMinorUnits,
        700,
      );
    } finally {
      await second.close();
    }
  });

  test(
    'unknown, archived or absent expectation cannot authorize new allocation',
    () async {
      for (final sql in [
        'UPDATE financial_expectations SET currency=NULL',
        "UPDATE financial_expectations SET currency='USD'",
        "UPDATE financial_expectations SET currency='IRR', status=1",
        'DELETE FROM financial_expectations',
      ]) {
        await database.customStatement(sql);
        await expectLater(match(1), throwsA(isA<ValidationError>()));
      }
      expect(await repository.list(), isEmpty);
    },
  );

  test(
    'completed cycle rejects new allocation without changing financial history',
    () async {
      await database.customStatement('UPDATE commitment_cycles SET status = 2');
      await expectLater(match(400), throwsA(isA<ValidationError>()));
      expect(await repository.list(), isEmpty);
      expect(
        await database.select(database.accountEntries).get(),
        hasLength(1),
      );
    },
  );

  test('partial remainder decision and explicit reopen survive cold restart without financial mutation', () async {
    await match(400);
    final before = await DriftFinanceRepository(database).listEntries();
    final snapshot = await repository.loadReview(transaction);
    final decided = await independent(snapshot);
    expect(decided.remainderMinorUnits, 600);
    expect(decided.isIndependent, true);
    await database.close();
    database = AppDatabase.forTesting(NativeDatabase(file));
    repository = DriftReconciliationRepository(database);
    expect((await repository.loadReview(transaction)).isIndependent, true);
    expect(
      (await repository.reviewHistory(transaction)).single.remainderMinorUnits,
      600,
    );
    final reopened = await repository.decideReview(
      expected: decided,
      decision: RelationshipReviewDecision.reopened,
      recordedAt: DateTime.utc(2026),
    );
    expect(reopened.revision, 2);
    expect(reopened.isIndependent, false);
    await match(600, expected: reopened);
    expect((await repository.loadReview(transaction)).remainderMinorUnits, 0);
    expect(
      (await repository.reviewHistory(transaction)).map((e) => e.decision),
      [
        RelationshipReviewDecision.independent,
        RelationshipReviewDecision.reopened,
      ],
    );
    expect(
      (await DriftFinanceRepository(
        database,
      ).listEntries()).map((e) => (e.id, e.amount, e.category)),
      before.map((e) => (e.id, e.amount, e.category)),
    );
  });

  test(
    'backup snapshot retains effective review and append-only logical history',
    () async {
      await match(400);
      final decided = await independent(
        await repository.loadReview(transaction),
      );
      final bytes = await sqliteBackupSnapshot(
        database: database,
        target: File('${directory.path}/snapshot.sqlite'),
        redact: true,
      );
      final restoredFile = File('${directory.path}/restored.sqlite');
      await restoredFile.writeAsBytes(bytes);
      final restored = AppDatabase.forTesting(NativeDatabase(restoredFile));
      try {
        final reviews = DriftReconciliationRepository(restored);
        final current = await reviews.loadReview(transaction);
        current.requireExpected(decided);
        expect(current.isIndependent, isTrue);
        final reopened = await reviews.decideReview(
          expected: current,
          decision: RelationshipReviewDecision.reopened,
          recordedAt: DateTime.utc(2026),
        );
        expect(reopened.isIndependent, isFalse);
        expect(await reviews.reviewHistory(transaction), hasLength(2));
        expect((await repository.reviewHistory(transaction)), hasLength(1));
        expect((await reviews.list()).single.allocatedMinorUnits, 400);
      } finally {
        await restored.close();
      }
    },
  );

  test(
    'stale review after matching, duplicate decisions, and stale reopen reject',
    () async {
      final snapshot = await repository.loadReview(transaction);
      await match(100);
      await expectLater(independent(snapshot), throwsA(isA<ValidationError>()));
      final current = await independent(
        await repository.loadReview(transaction),
      );
      await expectLater(independent(current), throwsA(isA<ValidationError>()));
      await expectLater(
        repository.decideReview(
          expected: snapshot,
          decision: RelationshipReviewDecision.reopened,
          recordedAt: DateTime.utc(2026),
        ),
        throwsA(isA<ValidationError>()),
      );
      expect(await repository.reviewHistory(transaction), hasLength(1));
    },
  );

  test(
    'review and match races have one winner, including direct save admission',
    () async {
      final snapshot = await repository.loadReview(transaction);
      final outcomes = await Future.wait([
        independent(snapshot).then((_) => true, onError: (Object _) => false),
        match(
          600,
          expected: snapshot,
        ).then((_) => true, onError: (Object _) => false),
      ]);
      expect(outcomes.where((v) => v), hasLength(1));
      final current = await repository.loadReview(transaction);
      if (current.isIndependent) {
        await expectLater(match(100), throwsA(isA<ValidationError>()));
        expect(await repository.list(), isEmpty);
      } else {
        expect(await repository.reviewHistory(transaction), isEmpty);
        expect(current.allocatedMinorUnits, 600);
      }
    },
  );

  test(
    'two independent decisions from one snapshot cannot both append',
    () async {
      final snapshot = await repository.loadReview(transaction);
      final outcomes = await Future.wait([
        independent(snapshot).then((_) => true, onError: (Object _) => false),
        independent(snapshot).then((_) => true, onError: (Object _) => false),
      ]);
      expect(outcomes.where((v) => v), hasLength(1));
      expect(await repository.reviewHistory(transaction), hasLength(1));
    },
  );

  test('cumulative save admission is atomic across repository instances and use cases', () async {
    final other = ReconciliationUseCases(
      DriftReconciliationRepository(database),
    );
    final outcomes = await Future.wait([
      match(600).then((_) => true, onError: (Object _) => false),
      other
          .match(
            transactionId: transaction.id,
            transactionAmount: transaction.amount,
            createdAt: DateTime.utc(2026),
            occurrenceIds: [occurrence],
            allocations: const [Money(minorUnits: 600, currency: 'IRR')],
          )
          .then((_) => true, onError: (Object _) => false),
    ]);
    expect(outcomes.where((v) => v), hasLength(1));
    expect((await repository.loadReview(transaction)).allocatedMinorUnits, 600);
  });

  test(
    'separate SQLite connections cannot over-allocate concurrently',
    () async {
      final second = AppDatabase.forTesting(NativeDatabase(file));
      try {
        final other = ReconciliationUseCases(
          DriftReconciliationRepository(second),
        );
        await second.readMetadata('schema_version');
        final outcomes = await Future.wait([
          match(600).then((_) => true, onError: (Object _) => false),
          other
              .match(
                transactionId: transaction.id,
                transactionAmount: transaction.amount,
                createdAt: DateTime.utc(2026),
                occurrenceIds: [occurrence],
                allocations: const [Money(minorUnits: 600, currency: 'IRR')],
              )
              .then((_) => true, onError: (Object _) => false),
        ]);
        expect(outcomes.where((value) => value), hasLength(1));
        expect(
          (await repository.loadReview(transaction)).allocatedMinorUnits,
          600,
        );
      } finally {
        await second.close();
      }
    },
  );

  test(
    'separate SQLite connections serialize review versus guarded match',
    () async {
      final second = AppDatabase.forTesting(NativeDatabase(file));
      try {
        final other = DriftReconciliationRepository(second);
        final expected = await other.loadReview(transaction);
        final outcomes = await Future.wait([
          other
              .decideReview(
                expected: expected,
                decision: RelationshipReviewDecision.independent,
                recordedAt: DateTime.utc(2026),
              )
              .then((_) => true, onError: (Object _) => false),
          match(
            400,
            expected: expected,
          ).then((_) => true, onError: (Object _) => false),
        ]);
        expect(outcomes.where((value) => value), hasLength(1));
        final current = await repository.loadReview(transaction);
        expect(
          current.isIndependent ? current.allocatedMinorUnits : 400,
          current.isIndependent ? 0 : current.allocatedMinorUnits,
        );
      } finally {
        await second.close();
      }
    },
  );

  test(
    'unmatch invalidates independent decision without deleting its history',
    () async {
      final original = await match(400);
      final decided = await independent(
        await repository.loadReview(transaction),
      );
      await ReconciliationUseCases(repository).unmatch(original);
      final current = await repository.loadReview(transaction);
      expect(current.isIndependent, false);
      expect(current.remainderMinorUnits, 1000);
      expect(
        current.allocationFingerprint,
        isNot(decided.allocationFingerprint),
      );
      expect(await repository.reviewHistory(transaction), hasLength(1));
      await expectLater(
        repository.save(original),
        throwsA(isA<ValidationError>()),
      );
    },
  );

  test('bad correction rolls back original status and allocations', () async {
    final original = await match(400);
    await match(300);
    await expectLater(
      ReconciliationUseCases(repository).correct(
        original: original,
        createdAt: DateTime.utc(2026),
        occurrenceIds: [occurrence],
        allocations: const [Money(minorUnits: 800, currency: 'IRR')],
      ),
      throwsA(isA<ValidationError>()),
    );
    expect(
      (await repository.list()).firstWhere((m) => m.id == original.id).status,
      MatchStatus.active,
    );
    expect((await repository.loadReview(transaction)).allocatedMinorUnits, 700);
  });

  test(
    'reversed and changed transaction snapshots reject decision and match',
    () async {
      final snapshot = await repository.loadReview(transaction);
      await database.customStatement(
        'UPDATE account_entries SET minor_units=900 WHERE id=?',
        [transaction.id.value],
      );
      await expectLater(independent(snapshot), throwsA(isA<ValidationError>()));
      await expectLater(match(100), throwsA(isA<ValidationError>()));
      await database.customStatement(
        'INSERT INTO account_entries(id,account_id,type,minor_units,currency,occurred_at,reference_id) VALUES (?, ?, ?, 900, ?, 0, ?)',
        [
          StableId.generate().value,
          transaction.accountId.value,
          AccountEntryType.reversal.index,
          'IRR',
          transaction.id.value,
        ],
      );
      await expectLater(
        repository.loadReview(transaction),
        throwsA(isA<ValidationError>()),
      );
    },
  );

  test('database enforces append-only, FK, bounds and unique transaction revisions', () async {
    final decided = await independent(await repository.loadReview(transaction));
    for (final sql in [
      'UPDATE relationship_reviews SET decision=1',
      'DELETE FROM relationship_reviews',
    ]) {
      await expectLater(database.customStatement(sql), throwsException);
    }
    for (final values in [
      [
        StableId.generate().value,
        transaction.id.value,
        1,
        0,
        1000,
        'IRR',
        '[]',
        '[]',
        1000,
        0,
      ],
      [
        StableId.generate().value,
        StableId.generate().value,
        1,
        0,
        1000,
        'IRR',
        '[]',
        '[]',
        1000,
        0,
      ],
      [
        StableId.generate().value,
        transaction.id.value,
        2,
        2,
        1000,
        'IRR',
        '[]',
        '[]',
        1000,
        0,
      ],
      [
        StableId.generate().value,
        transaction.id.value,
        2,
        0,
        1000,
        'IRR',
        '[]',
        '[]',
        1001,
        0,
      ],
    ]) {
      await expectLater(
        database.customStatement(
          'INSERT INTO relationship_reviews VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
          values,
        ),
        throwsException,
      );
    }
    expect(
      (await repository.loadReview(transaction)).revision,
      decided.revision,
    );
  });
}
