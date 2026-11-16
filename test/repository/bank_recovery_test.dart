import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/core/database/undo_journal.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/finance/data/bank_balance_store.dart';
import 'package:planact/features/finance/data/drift_finance_repository.dart';
import 'package:planact/features/finance/domain/bank_balance.dart';
import 'package:planact/features/finance/domain/finance.dart';

Future<List<AccountEntry>> chain(
  AppDatabase db,
  DriftFinanceRepository repo,
  FinancialAccount account,
) async {
  await repo.saveAccount(account);
  final result = <AccountEntry>[];
  for (var i = 1; i <= 2; i++) {
    await BankBalanceStore(db).observe(
      BankBalanceObservation(
        id: '${account.id.value}-$i',
        entryId: 'source-$i',
        accountId: account.id.value,
        irr: 100 * i,
        sourceAmount: 100 * i,
        sourceUnit: 'rial',
        transactionTime: DateTime.utc(2026, 1, i),
      ),
    );
    result.add(
      await repo.reconcileBankBalance(
        await repo.bankBalance(account.id.value),
        BankReconciliationReason.unknownAdjustment,
      ),
    );
  }
  return result;
}

FinancialAccount account(String name) => FinancialAccount(
  id: StableId.generate(),
  name: name,
  currency: 'IRR',
  type: FinancialAccountType.bank,
);

void main() {
  test('newest first, conservative both accounts, exact durable reversal and evidence retry', () async {
    final dir = await Directory.systemTemp.createTemp('bank-recovery');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/db.sqlite');
    var db = AppDatabase.forTesting(NativeDatabase(file));
    var repo = DriftFinanceRepository(db);
    final a = account('الف');
    final b = account('ب');
    final originals = [
      ...await chain(db, repo, a),
      ...await chain(db, repo, b),
    ];
    await expectLater(
      repo.reverseEntry(
        expected: originals.first,
        accountId: a.id,
        occurredAt: DateTime.utc(2026, 2),
      ),
      throwsA(isA<BankRecoveryRequired>()),
    );
    final evidence = (await repo.bankBalance(a.id.value)).observations.first;
    await expectLater(
      repo.reviewBankObservation(
        expected: evidence,
        accountId: b.id.value,
        sourceAmount: 400,
        sourceUnit: 'rial',
        transactionTime: evidence.transactionTime,
        active: true,
      ),
      throwsA(isA<BankRecoveryRequired>()),
    );
    final preview = await repo.previewBankRecovery({a.id.value, b.id.value});
    expect(preview.decisions.length, 4);
    expect(preview.decisions.first.through, DateTime.utc(2026, 1, 2));
    await db.close();
    db = AppDatabase.forTesting(NativeDatabase(file));
    repo = DriftFinanceRepository(db);
    await repo.recoverBankReconciliations(preview);
    var entries = await repo.listEntries();
    expect(entries.length, 8);
    for (final original in originals) {
      final reversal = entries.singleWhere(
        (e) => e.referenceId == original.id.value,
      );
      expect(reversal.type, AccountEntryType.reversal);
      expect(
        reversal.signedAmount.minorUnits,
        -original.signedAmount.minorUnits,
      );
      expect(
        await UndoJournal(db).latest('finance:${original.id.value}'),
        isNotNull,
      );
    }
    expect((await repo.bankBalance(a.id.value)).ledgerAtReport, 0);
    expect((await repo.bankBalance(a.id.value)).observations.first.revision, 0);
    await repo.reviewBankObservation(
      expected: evidence,
      accountId: b.id.value,
      sourceAmount: 400,
      sourceUnit: 'rial',
      transactionTime: evidence.transactionTime,
      active: true,
    );
    await expectLater(
      repo.recoverBankReconciliations(preview),
      throwsA(anything),
    );
    expect((await repo.listEntries()).length, 8);
    await db.close();
    db = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(db.close);
    repo = DriftFinanceRepository(db);
    expect(
      (await repo.previewBankRecovery({a.id.value, b.id.value})).decisions,
      isEmpty,
    );
    expect(
      (await BankBalanceStore(
        db,
      ).observations()).singleWhere((o) => o.id == evidence.id).revision,
      1,
    );
  });

  test('second SQLite writer stales preview; late cash excluded; mid-command rollback', () async {
    final dir = await Directory.systemTemp.createTemp('bank-recovery-stale');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/db.sqlite');
    final db = AppDatabase.forTesting(NativeDatabase(file));
    final second = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(db.close);
    addTearDown(second.close);
    final repo = DriftFinanceRepository(db);
    final other = DriftFinanceRepository(second);
    final a = account('حساب');
    await chain(db, repo, a);
    final preview = await repo.previewBankRecovery({a.id.value});
    await other.saveEntry(
      AccountEntry(
        id: StableId.generate(),
        accountId: a.id,
        type: AccountEntryType.income,
        amount: const Money(minorUnits: 777, currency: 'IRR'),
        occurredAt: DateTime.utc(2026, 2),
      ),
    );
    expect((await repo.bankBalance(a.id.value)).ledgerAtReport, 200);
    await expectLater(
      repo.recoverBankReconciliations(preview),
      throwsA(anything),
    );
    expect((await repo.listEntries()).length, 3);
    final fresh = await repo.previewBankRecovery({a.id.value});
    // Fail the second reversal after the first insert and journal append.
    await db.customStatement(
      '''CREATE TRIGGER fail_second_recovery BEFORE INSERT ON account_entries
      WHEN NEW.type = ${AccountEntryType.reversal.index} AND
        (SELECT COUNT(*) FROM account_entries WHERE type = ${AccountEntryType.reversal.index}) = 1
      BEGIN SELECT RAISE(ABORT, 'injected failure'); END''',
    );
    await expectLater(
      repo.recoverBankReconciliations(fresh),
      throwsA(anything),
    );
    expect((await repo.listEntries()).length, 3);
    expect((await repo.previewBankRecovery({a.id.value})).decisions.length, 2);
    for (final decision in fresh.decisions) {
      expect(
        await UndoJournal(db).latest('finance:${decision.entry.id.value}'),
        isNull,
      );
    }
    await db.customStatement('DROP TRIGGER fail_second_recovery');
    final outcomes = await Future.wait([
      for (final writer in [repo, other])
        writer
            .recoverBankReconciliations(fresh)
            .then((_) => true, onError: (Object _) => false),
    ]);
    expect(outcomes.where((success) => success).length, 1);
    expect((await repo.listEntries()).length, 5);
    expect((await repo.bankBalance(a.id.value)).ledgerAtReport, 0);
    expect(rebuildBalance(a, await repo.listEntries()).minorUnits, 777);
  });
}
