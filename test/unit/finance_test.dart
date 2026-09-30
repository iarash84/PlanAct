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

  test('creates an opening balance as a ledger entry', () async {
    final useCases = FinanceUseCases(InMemoryFinanceRepository());
    final account = FinancialAccount(
      id: StableId.generate(timestamp: DateTime.utc(2026, 1, 6)),
      name: 'حساب افتتاحیه',
      currency: 'IRR',
      type: FinancialAccountType.bank,
    );

    await useCases.createAccount(
      account,
      openingBalance: const Money(minorUnits: 12500, currency: 'IRR'),
      occurredAt: DateTime.utc(2026, 1, 6),
    );

    expect(
      await useCases.balance(account),
      const Money(minorUnits: 12500, currency: 'IRR'),
    );
    final entries = await useCases.repository.listEntries();
    expect(entries.single.type, AccountEntryType.openingBalance);
    expect(entries.single.note, 'موجودی اولیه');
  });

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
  test('corrects an entry without mutating the original ledger record', () async {
    final localRepository = InMemoryFinanceRepository();
    final useCases = FinanceUseCases(localRepository);
    await useCases.createAccount(account);
    final original = await useCases.record(
      account: account,
      type: AccountEntryType.expense,
      amount: const Money(minorUnits: 500, currency: 'IRR'),
      occurredAt: DateTime.utc(2026, 1, 7),
    );

    await useCases.correctEntry(
      original: original,
      account: account,
      type: AccountEntryType.income,
      amount: const Money(minorUnits: 700, currency: 'IRR'),
      occurredAt: DateTime.utc(2026, 1, 8),
    );

    expect((await localRepository.listEntries()).length, 3);
    expect(await useCases.balance(account), const Money(minorUnits: 700, currency: 'IRR'));
  });

  test('restores an archived account without changing its history', () async {
    final localRepository = InMemoryFinanceRepository();
    final useCases = FinanceUseCases(localRepository);
    await useCases.createAccount(account);
    await useCases.archive(account);
    await useCases.restore(account.archive());
    final accounts = await localRepository.listAccounts();
    expect(accounts.single.status, FinancialAccountStatus.active);
  });
}
