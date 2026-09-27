import 'package:planact/core/errors/app_error.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/finance/domain/finance.dart';

abstract interface class FinanceRepository {
  Future<List<FinancialAccount>> listAccounts();
  Future<List<AccountEntry>> listEntries();
  Future<void> saveAccount(FinancialAccount account);
  Future<void> saveEntry(AccountEntry entry);
  Future<void> createAccount(
    FinancialAccount account, {
    AccountEntry? openingBalance,
  });
}

class InMemoryFinanceRepository implements FinanceRepository {
  final Map<StableId, FinancialAccount> _accounts = {};
  final Map<StableId, AccountEntry> _entries = {};

  @override
  Future<List<FinancialAccount>> listAccounts() async =>
      List.unmodifiable(_accounts.values);
  @override
  Future<List<AccountEntry>> listEntries() async =>
      List.unmodifiable(_entries.values);
  @override
  Future<void> saveAccount(FinancialAccount account) async =>
      _accounts[account.id] = account;
  @override
  Future<void> saveEntry(AccountEntry entry) async =>
      _entries[entry.id] = entry;

  @override
  Future<void> createAccount(
    FinancialAccount account, {
    AccountEntry? openingBalance,
  }) async {
    _accounts[account.id] = account;
    if (openingBalance != null) _entries[openingBalance.id] = openingBalance;
  }
}

class FinanceUseCases {
  FinanceUseCases(this.repository);
  final FinanceRepository repository;

  Future<void> createAccount(
    FinancialAccount account, {
    Money? openingBalance,
    DateTime? occurredAt,
  }) {
    if (openingBalance != null) {
      _assertCurrency(account, openingBalance);
    }
    final entry = openingBalance == null || openingBalance.minorUnits == 0
        ? null
        : AccountEntry(
            id: StableId.generate(timestamp: occurredAt),
            accountId: account.id,
            type: AccountEntryType.openingBalance,
            amount: openingBalance,
            occurredAt: (occurredAt ?? DateTime.now()).toUtc(),
            note: 'موجودی اولیه',
          );
    return repository.createAccount(account, openingBalance: entry);
  }

  Future<AccountEntry> record({
    required FinancialAccount account,
    required AccountEntryType type,
    required Money amount,
    required DateTime occurredAt,
    String? referenceId,
    String? note,
    String? category,
    AccountEntrySource source = AccountEntrySource.manual,
  }) async {
    _assertActive(account);
    _assertCurrency(account, amount);
    final entry = AccountEntry(
      id: StableId.generate(timestamp: occurredAt),
      accountId: account.id,
      type: type,
      amount: amount,
      occurredAt: occurredAt.toUtc(),
      referenceId: referenceId,
      note: note,
      category: category,
      source: source,
    );
    await repository.saveEntry(entry);
    return entry;
  }

  Future<(AccountEntry, AccountEntry)> transfer({
    required FinancialAccount from,
    required FinancialAccount to,
    required Money amount,
    required DateTime occurredAt,
  }) async {
    _assertActive(from);
    _assertActive(to);
    if (from.id == to.id) {
      throw const ValidationError('Transfer accounts must differ');
    }
    _assertCurrency(from, amount);
    _assertCurrency(to, amount);
    final group = StableId.generate(timestamp: occurredAt);
    final outgoing = AccountEntry(
      id: StableId.generate(timestamp: occurredAt),
      accountId: from.id,
      type: AccountEntryType.transferOut,
      amount: amount,
      occurredAt: occurredAt.toUtc(),
      transferGroupId: group,
    );
    final incoming = AccountEntry(
      id: StableId.generate(timestamp: occurredAt),
      accountId: to.id,
      type: AccountEntryType.transferIn,
      amount: amount,
      occurredAt: occurredAt.toUtc(),
      transferGroupId: group,
    );
    await repository.saveEntry(outgoing);
    await repository.saveEntry(incoming);
    return (outgoing, incoming);
  }

  Future<void> archive(FinancialAccount account) async {
    await repository.saveAccount(account.archive());
  }

  Future<Money> balance(FinancialAccount account) async =>
      rebuildBalance(account, await repository.listEntries());

  void _assertActive(FinancialAccount account) {
    if (account.status != FinancialAccountStatus.active) {
      throw const ValidationError('Archived accounts cannot be mutated');
    }
  }

  void _assertCurrency(FinancialAccount account, Money amount) {
    if (account.currency != amount.currency) {
      throw const ValidationError('Account and entry currencies must match');
    }
  }
}
