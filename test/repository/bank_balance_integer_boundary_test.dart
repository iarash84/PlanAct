import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/core/database/undo_journal.dart';
import 'package:planact/core/errors/app_error.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/finance/data/bank_balance_store.dart';
import 'package:planact/features/finance/data/drift_finance_repository.dart';
import 'package:planact/features/finance/domain/bank_balance.dart';
import 'package:planact/features/finance/domain/finance.dart';

const maximum = 9223372036854775807;
const minimum = -9223372036854775808;

void main() {
  late AppDatabase db;
  late DriftFinanceRepository repo;
  late FinancialAccount account;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DriftFinanceRepository(db);
    account = FinancialAccount(
      id: StableId.generate(),
      name: 'حساب آزمون',
      currency: 'IRR',
      type: FinancialAccountType.bank,
    );
    await repo.saveAccount(account);
  });
  tearDown(() => db.close());

  Future<AccountEntry> entry(int value, int day) async {
    final result = AccountEntry(
      id: StableId.generate(),
      accountId: account.id,
      type: AccountEntryType.adjustment,
      amount: Money(minorUnits: value, currency: 'IRR'),
      occurredAt: DateTime.utc(2026, 1, day),
    );
    await repo.saveEntry(result);
    return result;
  }

  Future<void> observe(int day, int value) => BankBalanceStore(db).observe(
    BankBalanceObservation(
      id: 'source-$day',
      entryId: 'source-entry-$day',
      accountId: account.id.value,
      irr: value,
      sourceAmount: value,
      sourceUnit: 'rial',
      transactionTime: DateTime.utc(2026, 1, day),
    ),
  );

  test('report accumulation rejects positive and negative int64 overflow', () async {
    for (final boundary in [maximum, minimum]) {
      final first = await entry(boundary, 1);
      final second = await entry(boundary > 0 ? 1 : -1, 1);
      await observe(2, 0);
      await expectLater(
        repo.bankBalance(account.id.value),
        throwsA(isA<ValidationError>()),
      );
      // Remove synthetic rows only, to exercise the other bound independently.
      await db.customStatement(
        'DELETE FROM account_entries WHERE id IN (?, ?)',
        [first.id.value, second.id.value],
      );
    }
  });

  test(
    'wide accumulation preserves cancellation without intermediate wrap',
    () async {
      await entry(maximum, 1);
      await entry(1, 1);
      await entry(-1, 1);
      await observe(2, maximum);
      final snapshot = await repo.bankBalance(account.id.value);
      expect(snapshot.ledgerAtReport, maximum);
      expect(snapshot.difference, 0);
      expect(snapshot.canReconcile, isFalse);
    },
  );

  test('maximum supported difference and reversal remain exact', () async {
    await observe(2, maximum);
    final decision = await repo.reconcileBankBalance(
      await repo.bankBalance(account.id.value),
      BankReconciliationReason.unknownAdjustment,
    );
    expect(decision.amount.minorUnits, maximum);
    await repo.recoverBankReconciliations(
      await repo.previewBankRecovery({account.id.value}),
    );
    final reversal = (await repo.listEntries()).singleWhere(
      (e) => e.referenceId == decision.id.value,
    );
    expect(reversal.amount.minorUnits, -maximum);
    expect((await repo.bankBalance(account.id.value)).ledgerAtReport, 0);
  });

  test(
    'minimum signed effect cannot be negated; no reversal or Undo is written',
    () async {
      final original = await entry(minimum, 1);
      await expectLater(
        repo.reverseEntry(
          expected: original,
          accountId: account.id,
          occurredAt: DateTime.utc(2026, 2),
        ),
        throwsA(isA<ValidationError>()),
      );
      expect((await repo.listEntries()).single.amount.minorUnits, minimum);
      expect(
        await UndoJournal(db).latest('finance:${original.id.value}'),
        isNull,
      );
    },
  );

  test('recovery rolls back earlier reversals when a later negation is unsupported', () async {
    // Legacy/synthetic negative report permits the signed minimum decision.
    await observe(1, minimum);
    final oldest = await repo.reconcileBankBalance(
      await repo.bankBalance(account.id.value),
      BankReconciliationReason.unknownAdjustment,
    );
    await observe(2, minimum + 1);
    final newest = await repo.reconcileBankBalance(
      await repo.bankBalance(account.id.value),
      BankReconciliationReason.unknownAdjustment,
    );
    final preview = await repo.previewBankRecovery({account.id.value});
    expect(preview.decisions.first.entry.id, newest.id);
    await expectLater(
      repo.recoverBankReconciliations(preview),
      throwsA(isA<ValidationError>()),
    );
    expect((await repo.listEntries()).length, 2);
    expect(
      (await repo.previewBankRecovery({account.id.value})).tokens,
      preview.tokens,
    );
    for (final original in [oldest, newest]) {
      expect(
        await UndoJournal(db).latest('finance:${original.id.value}'),
        isNull,
      );
    }
  });

  test(
    'known fee rejects unsupported positive magnitude before metadata write',
    () async {
      await observe(1, minimum);
      final snapshot = await repo.bankBalance(account.id.value);
      await expectLater(
        repo.reconcileBankBalance(snapshot, BankReconciliationReason.knownFee),
        throwsA(isA<ValidationError>()),
      );
      expect(await repo.listEntries(), isEmpty);
      expect((await repo.bankBalance(account.id.value)).token, snapshot.token);
    },
  );
}
