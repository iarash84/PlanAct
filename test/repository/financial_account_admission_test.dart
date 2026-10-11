import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/finance/application/finance_use_cases.dart';
import 'package:planact/features/finance/data/drift_finance_repository.dart';
import 'package:planact/features/finance/domain/finance.dart';

void main() {
  test('fresh durable account admission rejects stale archived selection and preserves history', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = DriftFinanceRepository(database);
    final active = FinancialAccount(
      id: StableId.generate(),
      name: 'حساب',
      currency: 'IRR',
      type: FinancialAccountType.cash,
    );
    await repository.saveAccount(active);
    final useCases = FinanceUseCases(repository);
    final historical = await useCases.record(
      account: active,
      type: AccountEntryType.expense,
      amount: const Money(minorUnits: 100, currency: 'IRR'),
      occurredAt: DateTime.utc(2026, 9, 20),
    );
    await repository.saveAccount(
      FinancialAccount(
        id: active.id,
        name: active.name,
        currency: active.currency,
        type: active.type,
        status: FinancialAccountStatus.archived,
      ),
    );
    await expectLater(
      useCases.record(
        account: active,
        type: AccountEntryType.income,
        amount: const Money(minorUnits: 50, currency: 'IRR'),
        occurredAt: DateTime.utc(2026, 9, 21),
      ),
      throwsStateError,
    );
    await repository.saveEntry(historical);
    expect(await repository.listEntries(), hasLength(1));
    expect(
      (await repository.listAccounts()).single.status,
      FinancialAccountStatus.archived,
    );
  });
}
