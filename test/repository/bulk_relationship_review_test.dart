import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/finance/data/drift_finance_repository.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/reconciliation/application/bulk_relationship_review.dart';
import 'package:planact/features/reconciliation/application/reconciliation_use_cases.dart';
import 'package:planact/features/reconciliation/data/drift_reconciliation_repository.dart';
import 'package:planact/features/reconciliation/domain/relationship_review.dart';

void main() {
  // This test intentionally opens independent database owners for restore
  // and concurrent relationship-review coverage.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late Directory directory;
  late File file;
  late AppDatabase database;
  late DriftFinanceRepository finance;
  late DriftReconciliationRepository reviews;
  late RelationshipQueue queue;
  late FinancialAccount account;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('bulk-relationship-');
    file = File('${directory.path}/state.sqlite');
    database = AppDatabase.forTesting(NativeDatabase(file));
    finance = DriftFinanceRepository(database);
    reviews = DriftReconciliationRepository(database);
    queue = RelationshipQueue(finance, reviews);
    account = FinancialAccount(
      id: StableId.generate(),
      name: 'حساب',
      currency: 'IRR',
      type: FinancialAccountType.bank,
    );
    await finance.saveAccount(account);
  });
  tearDown(() async {
    await database.close();
    await directory.delete(recursive: true);
  });
  Future<AccountEntry> entry(
    int index, {
    AccountEntryType type = AccountEntryType.expense,
    String? reference,
  }) async {
    final result = AccountEntry(
      id: StableId.generate(),
      accountId: account.id,
      type: type,
      amount: const Money(minorUnits: 1000, currency: 'IRR'),
      occurredAt: DateTime.utc(2026, 1, 1).add(Duration(minutes: index)),
      note: 'تراکنش $index',
      referenceId: reference,
    );
    await finance.saveEntry(result);
    return result;
  }

  Future<Map<String, bool>> run(
    List<RelationshipQueueItem> items, {
    BulkRelationshipReview? runner,
  }) async {
    final results = <String, bool>{};
    await (runner ?? BulkRelationshipReview(reviews)).run(
      items,
      onStarted: (_) {},
      onFinished: (item, result) =>
          results[item.transaction.id.value] = result != null,
    );
    return results;
  }

  test('large queue pages/filter scope exclude transfers reversals and independent remainders', () async {
    for (var i = 0; i < 121; i++) {
      await entry(
        i,
        type: i.isEven ? AccountEntryType.income : AccountEntryType.expense,
      );
    }
    final transfer = await entry(200, type: AccountEntryType.transferOut);
    final reversed = await entry(201);
    await entry(
      202,
      type: AccountEntryType.reversal,
      reference: reversed.id.value,
    );
    await entry(203, type: AccountEntryType.openingBalance);
    final first = await queue.load();
    expect(first.items, hasLength(50));
    expect(first.hasNext, true);
    expect(
      first.items.any(
        (i) =>
            i.transaction.id == transfer.id || i.transaction.id == reversed.id,
      ),
      false,
    );
    expect((await queue.load(page: 2)).items, hasLength(21));
    expect(
      (await queue.load(type: AccountEntryType.income)).items
          .every((i) => i.transaction.type == AccountEntryType.income),
      true,
    );
    expect((await queue.load(query: 'تراکنش 120')).items, hasLength(1));
    expect((await run(first.items)).values.every((v) => v), true);
    expect((await queue.load(independent: true)).items, hasLength(50));
    expect(
      (await queue.load()).items.any(
        (i) => first.items.any((old) => old.transaction.id == i.transaction.id),
      ),
      false,
    );
    await expectLater(
      run([first.items.first, first.items.first]),
      throwsArgumentError,
    );
    final independent = (await queue.load(independent: true)).items;
    await expectLater(run(independent), throwsArgumentError);
    final oversized = [
      ...(await queue.load()).items,
      (await queue.load(page: 1)).items.first,
    ];
    await expectLater(run(oversized), throwsArgumentError);
    final invalid = RelationshipQueueItem(
      transfer,
      await reviews.loadReview(first.items.first.transaction),
    );
    await expectLater(run([invalid]), throwsArgumentError);
  });

  test('middle transactional failure retry replay and old undo preserve cold durable history and balance', () async {
    for (var i = 0; i < 3; i++) {
      await entry(i);
    }
    final items = (await queue.load()).items;
    final before = await finance.listEntries();
    final balance = rebuildBalance(account, before);
    final failed = items[1];
    await database.customStatement(
      "CREATE TRIGGER fail_bulk_relationship BEFORE INSERT ON relationship_reviews WHEN NEW.transaction_id='${failed.transaction.id.value}' BEGIN SELECT RAISE(ABORT, 'test failure'); END",
    );
    final results = await run(items);
    expect(results.values.toList(), [true, false, true]);
    expect(await reviews.reviewHistory(failed.transaction), isEmpty);
    await database.customStatement('DROP TRIGGER fail_bulk_relationship');
    expect((await run([failed])).values.single, true);
    expect((await run(items)).values.every((v) => !v), true);
    final decided = await reviews.loadReview(items.first.transaction);
    final reopened = await reviews.decideReview(
      expected: decided,
      decision: RelationshipReviewDecision.reopened,
      recordedAt: DateTime.now(),
    );
    final newest = await reviews.decideReview(
      expected: reopened,
      decision: RelationshipReviewDecision.independent,
      recordedAt: DateTime.now(),
    );
    await expectLater(
      reviews.decideReview(
        expected: decided,
        decision: RelationshipReviewDecision.reopened,
        recordedAt: DateTime.now(),
      ),
      throwsException,
    );
    expect(newest.revision, 3);
    await database.close();
    database = AppDatabase.forTesting(NativeDatabase(file));
    finance = DriftFinanceRepository(database);
    reviews = DriftReconciliationRepository(database);
    queue = RelationshipQueue(finance, reviews);
    expect((await queue.load()).items, isEmpty);
    expect((await queue.load(independent: true)).items, hasLength(3));
    expect(
      (await reviews.reviewHistory(items.first.transaction))
          .map((e) => e.revision),
      [1, 2, 3],
    );
    expect((await reviews.reviewHistory(failed.transaction)).length, 1);
    expect(
      (await finance.listEntries()).map((e) => e.id),
      before.map((e) => e.id),
    );
    expect(rebuildBalance(account, await finance.listEntries()), balance);
    expect(await reviews.list(), isEmpty);
  });

  test('concurrent allocation invalidates loaded token and partial remainder still selectable', () async {
    final transaction = await entry(0);
    final old = (await queue.load()).items.single;
    final commitment = StableId.generate().value,
        cycle = StableId.generate().value,
        schedule = StableId.generate().value;
    final occurrence = StableId.generate();
    await database.customStatement(
      'INSERT INTO commitments(id,title,created_at,status) VALUES (?, ?, 0, 0)',
      [commitment, 'کلاس'],
    );
    await database.customStatement(
      'INSERT INTO commitment_cycles VALUES (?, ?, 0, 0, NULL, NULL, NULL, 0, 0, 0)',
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
    final second = AppDatabase.forTesting(NativeDatabase(file));
    try {
      await ReconciliationUseCases(DriftReconciliationRepository(second)).match(
        transactionId: transaction.id,
        transactionAmount: transaction.amount,
        createdAt: DateTime.now(),
        occurrenceIds: [occurrence],
        allocations: const [Money(minorUnits: 400, currency: 'IRR')],
        expectedReview: old.review,
      );
    } finally {
      await second.close();
    }
    expect((await run([old])).values.single, false);
    final fresh = (await queue.load()).items.single;
    expect(fresh.review.remainderMinorUnits, 600);
    expect((await run([fresh])).values.single, true);
    expect((await reviews.list()).single.allocatedMinorUnits, 400);
    expect(await finance.listEntries(), hasLength(1));
    expect(
      (await reviews.reviewHistory(transaction)).single.remainderMinorUnits,
      600,
    );
  });

  test('stop between items keeps completed item and never writes remainder of selection', () async {
    for (var i = 0; i < 3; i++) {
      await entry(i);
    }
    final items = (await queue.load()).items;
    final runner = BulkRelationshipReview(reviews);
    var completed = 0;
    await runner.run(
      items,
      onStarted: (_) {},
      onFinished: (_, result) {
        expect(result, isNotNull);
        completed++;
        runner.cancel();
      },
    );
    expect(completed, 1);
    expect((await queue.load()).items, hasLength(2));
  });
}
