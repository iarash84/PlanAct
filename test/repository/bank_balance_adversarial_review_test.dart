import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/finance/data/bank_balance_store.dart';
import 'package:planact/features/finance/data/drift_finance_repository.dart';
import 'package:planact/features/finance/domain/bank_balance.dart';
import 'package:planact/features/finance/domain/finance.dart';

void main() {
  test('out-of-range report difference must not commit opposite-sign money', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = DriftFinanceRepository(db);
    final account = FinancialAccount(
      id: StableId.generate(),
      name: 'حساب آزمون',
      currency: 'IRR',
      type: FinancialAccountType.bank,
    );
    await repo.saveAccount(account);
    await repo.saveEntry(
      AccountEntry(
        id: StableId.generate(),
        accountId: account.id,
        type: AccountEntryType.expense,
        amount: const Money(minorUnits: 1, currency: 'IRR'),
        occurredAt: DateTime.utc(2026, 1, 1),
      ),
    );
    await BankBalanceStore(db).observe(
      BankBalanceObservation(
        id: 'overflow-source',
        entryId: 'source-entry',
        accountId: account.id.value,
        irr: 9223372036854775807,
        sourceAmount: 9223372036854775807,
        sourceUnit: 'rial',
        transactionTime: DateTime.utc(2026, 1, 2),
      ),
    );
    final snapshot = await repo.bankBalance(account.id.value);
    expect(snapshot.ledgerAtReport, -1);
    // The required positive difference is 9223372036854775808, outside int64.
    await expectLater(
      repo
          .reconcileBankBalance(
            snapshot,
            BankReconciliationReason.unknownAdjustment,
          )
          .then((entry) async {
            // Synthetic fixture values only; never production financial data.
            printOnFailure(
              'synthetic committed difference=${entry.amount.minorUnits}',
            );
            await repo.recoverBankReconciliations(
              await repo.previewBankRecovery({account.id.value}),
            );
            final reversal = (await repo.listEntries()).last;
            printOnFailure(
              'synthetic recovery entries=${(await repo.listEntries()).length}, '
              'last=${reversal.amount.minorUnits}',
            );
            return entry;
          }),
      throwsA(anything),
    );
    expect((await repo.listEntries()).length, 1);
  });
}
