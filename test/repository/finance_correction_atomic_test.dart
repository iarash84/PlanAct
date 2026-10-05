import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/finance/data/drift_finance_repository.dart';
import 'package:planact/features/finance/domain/finance.dart';

void main() {
  test('failed second correction insert rolls back reversal', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = DriftFinanceRepository(database);
    final account = FinancialAccount(
      id: StableId.generate(),
      name: 'حساب',
      currency: 'IRR',
      type: FinancialAccountType.bank,
    );
    await repository.saveAccount(account);
    final date = DateTime.utc(2026, 9, 20);
    final amount = Money(minorUnits: 100, currency: 'IRR');
    final original = AccountEntry(
      id: StableId.generate(),
      accountId: account.id,
      type: AccountEntryType.expense,
      amount: amount,
      occurredAt: date,
    );
    await repository.saveEntry(original);
    final reversal = AccountEntry(
      id: StableId.generate(),
      accountId: account.id,
      type: AccountEntryType.income,
      amount: amount,
      occurredAt: date,
      referenceId: original.id.value,
    );
    final invalidCorrection = AccountEntry(
      id: StableId.generate(),
      accountId: StableId.generate(),
      type: AccountEntryType.expense,
      amount: amount,
      occurredAt: date,
      referenceId: original.id.value,
    );
    await expectLater(
      repository.saveCorrection(
        reversal: reversal,
        corrected: invalidCorrection,
      ),
      throwsA(isA<Exception>()),
    );
    expect((await repository.listEntries()).map((entry) => entry.id), [
      original.id,
    ]);
  });
}
