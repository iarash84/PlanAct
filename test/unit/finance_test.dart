import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/errors/app_error.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/finance/application/finance_use_cases.dart';
import 'package:planact/features/finance/domain/finance.dart';

void main() {
  final account = FinancialAccount(
    id: StableId.generate(timestamp: DateTime.utc(2026, 1, 1)),
    name: 'بانک',
    currency: 'IRR',
    type: FinancialAccountType.bank,
  );
  final wallet = FinancialAccount(
    id: StableId.generate(timestamp: DateTime.utc(2026, 1, 1)),
    name: 'کیف پول',
    currency: 'IRR',
    type: FinancialAccountType.cash,
  );
  final repository = InMemoryFinanceRepository();

  test('rebuilds account balance from append-only entries', () async {
    final useCases = FinanceUseCases(repository);
    await useCases.createAccount(account);
    await useCases.record(
      account: account,
      type: AccountEntryType.income,
      amount: const Money(minorUnits: 1000, currency: 'IRR'),
      occurredAt: DateTime.utc(2026, 1, 2),
    );
    await useCases.record(
      account: account,
      type: AccountEntryType.expense,
      amount: const Money(minorUnits: 250, currency: 'IRR'),
      occurredAt: DateTime.utc(2026, 1, 3),
    );

    expect(
      await useCases.balance(account),
      const Money(minorUnits: 750, currency: 'IRR'),
    );
  });

  test(
    'internal transfer changes balances but is not income or expense',
    () async {
      final useCases = FinanceUseCases(repository);
      await useCases.createAccount(wallet);
      await useCases.transfer(
        from: account,
        to: wallet,
        amount: const Money(minorUnits: 300, currency: 'IRR'),
        occurredAt: DateTime.utc(2026, 1, 4),
      );

      final entries = await repository.listEntries();
      final transferEntries = entries.where((e) => e.transferGroupId != null);
      expect(transferEntries, hasLength(2));
      expect(
        await useCases.balance(account),
        const Money(minorUnits: 450, currency: 'IRR'),
      );
      expect(
        await useCases.balance(wallet),
        const Money(minorUnits: 300, currency: 'IRR'),
      );
    },
  );

  test('archived account cannot receive new entries', () async {
    final useCases = FinanceUseCases(repository);
    final archived = account.archive();
    await expectLater(
      useCases.record(
        account: archived,
        type: AccountEntryType.income,
        amount: const Money(minorUnits: 1, currency: 'IRR'),
        occurredAt: DateTime.utc(2026, 1, 5),
      ),
      throwsA(isA<ValidationError>()),
    );
  });
}
