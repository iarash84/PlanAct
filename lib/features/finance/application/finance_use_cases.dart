import 'package:planact/core/application/command_gate.dart';
import 'package:planact/core/application/undo_token.dart';
import 'package:planact/core/errors/app_error.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/finance/domain/transfer_fee_policy.dart';

abstract interface class FinanceRepository {
  Future<List<FinancialAccount>> listAccounts();
  Future<List<AccountEntry>> listEntries();
  Future<void> saveAccount(FinancialAccount account);
  Future<void> reorderAccounts(List<StableId> orderedIds);
  Future<void> saveEntry(AccountEntry entry);
  Future<void> saveTransfer({
    required AccountEntry outgoing,
    required AccountEntry incoming,
    AccountEntry? fee,
  });
  Future<void> createAccount(
    FinancialAccount account, {
    AccountEntry? openingBalance,
  });
}

/// Creation and optional classification must commit together or not at all.
/// Fresh transactional admission; never a snapshot upsert.
abstract interface class AtomicAccountEditing {
  Future<void> editAccount({
    required FinancialAccount original,
    required FinancialAccount replacement,
  });
  Future<void> setAccountStatus(StableId id, FinancialAccountStatus status);
}

abstract interface class TaggedFinanceCreation {
  Future<void> createTaggedEntry(AccountEntry entry, Set<String> tags);
}

abstract interface class AtomicFinanceCorrection {
  Future<void> saveCorrection({
    required AccountEntry reversal,
    required AccountEntry corrected,
  });
}

abstract interface class AtomicFinanceReversal {
  Future<AccountEntry> reverseEntry({
    required AccountEntry expected,
    required StableId accountId,
    required DateTime occurredAt,
    AccountEntry? corrected,
  });
}

abstract interface class AccountStatusUndoRepository {
  Future<UndoToken?> accountStatusUndo(StableId id);
  Future<void> undoAccountStatus(StableId id, UndoToken expected);
}

class InMemoryFinanceRepository
    implements FinanceRepository, AtomicAccountEditing, AtomicFinanceReversal {
  @override
  Future<AccountEntry> reverseEntry({
    required AccountEntry expected,
    required StableId accountId,
    required DateTime occurredAt,
    AccountEntry? corrected,
  }) async {
    final reversals = prepareFinanceReversal(
      expected: expected,
      accountId: accountId,
      entries: _entries.values.toList(),
      accounts: _accounts.values.toList(),
      occurredAt: occurredAt,
      corrected: corrected,
    );
    for (final entry in reversals) {
      _entries[entry.id] = entry;
    }
    if (corrected != null) _entries[corrected.id] = corrected;
    return reversals.firstWhere((e) => e.referenceId == expected.id.value);
  }

  @override
  Future<void> editAccount({
    required FinancialAccount original,
    required FinancialAccount replacement,
  }) async {
    final fresh = _accounts[original.id];
    if (fresh == null || !fresh.sameEditableFields(original)) {
      throw const ValidationError('Account edit conflict');
    }
    _accounts[original.id] = FinancialAccount(
      id: fresh.id,
      name: replacement.name,
      currency: fresh.currency,
      type: replacement.type,
      bank: replacement.bank,
      identifiers: replacement.identifiers,
      status: fresh.status,
    );
  }

  @override
  Future<void> setAccountStatus(
    StableId id,
    FinancialAccountStatus status,
  ) async {
    final fresh = _accounts[id];
    if (fresh == null) throw const ValidationError('Account missing');
    _accounts[id] = status == FinancialAccountStatus.active
        ? fresh.restore()
        : fresh.archive();
  }

  final Map<StableId, FinancialAccount> _accounts = {};
  final Map<StableId, AccountEntry> _entries = {};

  @override
  Future<List<FinancialAccount>> listAccounts() async =>
      List.unmodifiable(_accounts.values);
  @override
  Future<List<AccountEntry>> listEntries() async =>
      List.unmodifiable(_entries.values);

  @override
  Future<void> reorderAccounts(List<StableId> orderedIds) async {
    final existing = _accounts.keys.toSet();
    if (orderedIds.length != existing.length ||
        orderedIds.toSet().length != orderedIds.length ||
        !orderedIds.every(existing.contains)) {
      throw const ValidationError('Account order is stale');
    }
    final reordered = <StableId, FinancialAccount>{};
    for (final id in orderedIds) {
      reordered[id] = _accounts[id]!;
    }
    _accounts
      ..clear()
      ..addAll(reordered);
  }

  @override
  Future<void> saveAccount(FinancialAccount account) async =>
      _accounts[account.id] = account;
  @override
  Future<void> saveEntry(AccountEntry entry) async =>
      _entries[entry.id] = entry;

  @override
  Future<void> saveTransfer({
    required AccountEntry outgoing,
    required AccountEntry incoming,
    AccountEntry? fee,
  }) async {
    final previous = Map<StableId, AccountEntry>.from(_entries);
    try {
      _entries[outgoing.id] = outgoing;
      _entries[incoming.id] = incoming;
      if (fee != null) _entries[fee.id] = fee;
    } catch (_) {
      _entries
        ..clear()
        ..addAll(previous);
      rethrow;
    }
  }

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

  Future<void> reorderAccounts(List<StableId> orderedIds) =>
      repository.reorderAccounts(orderedIds);

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
    Set<String> tags = const {},
  }) => CommandGate.runFor(repository, () async {
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
    if (tags.isEmpty) {
      await repository.saveEntry(entry);
    } else if (repository case final TaggedFinanceCreation tagged) {
      await tagged.createTaggedEntry(entry, tags);
    } else {
      throw StateError('Atomic tagged creation is not supported.');
    }
    return entry;
  });

  Future<(AccountEntry, AccountEntry)> transfer({
    required FinancialAccount from,
    required FinancialAccount to,
    required Money amount,
    required DateTime occurredAt,
    TransferMethod method = TransferMethod.cardToCard,
    TransferFeePolicy feePolicy = const NoTransferFeePolicy(),
  }) => CommandGate.runFor(repository, () async {
    _assertActive(from);
    _assertActive(to);
    if (from.id == to.id) {
      throw const ValidationError('Transfer accounts must differ');
    }
    _assertCurrency(from, amount);
    _assertCurrency(to, amount);
    final group = StableId.generate(timestamp: occurredAt);
    final fee = feePolicy.feeFor(
      context: TransferFeeContext(amount: amount, method: method),
    );
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
    final feeEntry = fee.minorUnits == 0
        ? null
        : AccountEntry(
            id: StableId.generate(
              timestamp: occurredAt.add(const Duration(microseconds: 1)),
            ),
            accountId: from.id,
            type: AccountEntryType.expense,
            amount: fee,
            occurredAt: occurredAt.toUtc(),
            transferGroupId: group,
            note: 'کارمزد انتقال',
            category: 'کارمزد',
          );
    await repository.saveTransfer(
      outgoing: outgoing,
      incoming: incoming,
      fee: feeEntry,
    );
    return (outgoing, incoming);
  });

  Future<void> archive(FinancialAccount account) =>
      CommandGate.runFor(repository, () async {
        if (repository case final AtomicAccountEditing editor) {
          await editor.setAccountStatus(
            account.id,
            FinancialAccountStatus.archived,
          );
        } else {
          await repository.saveAccount(account.archive());
        }
      });

  Future<void> restore(FinancialAccount account) =>
      CommandGate.runFor(repository, () async {
        if (repository case final AtomicAccountEditing editor) {
          await editor.setAccountStatus(
            account.id,
            FinancialAccountStatus.active,
          );
        } else {
          await repository.saveAccount(account.restore());
        }
      });

  Future<void> updateAccount({
    required FinancialAccount account,
    required String name,
    FinancialAccountType? type,
  }) => CommandGate.runFor(repository, () async {
    await editAccount(
      original: account,
      replacement: account.update(name: name, type: type),
    );
  });

  /// Corrects an immutable ledger entry by recording an opposite-signed
  /// reversal followed by the corrected entry. The original remains auditable.
  Future<void> editAccount({
    required FinancialAccount original,
    required FinancialAccount replacement,
  }) => CommandGate.runFor(repository, () async {
    if (original.id != replacement.id) {
      throw const ValidationError('Account identity cannot change');
    }
    if (repository case final AtomicAccountEditing editor) {
      await editor.editAccount(original: original, replacement: replacement);
    } else {
      throw const ValidationError('Atomic account editing is not supported');
    }
  });

  Future<AccountEntry> correctEntry({
    required AccountEntry original,
    required FinancialAccount account,
    required AccountEntryType type,
    required Money amount,
    required DateTime occurredAt,
    String? note,
    String? category,
  }) => CommandGate.runFor(repository, () async {
    _assertActive(account);
    _assertCurrency(account, amount);
    final corrected = AccountEntry(
      id: StableId.generate(
        timestamp: occurredAt.add(const Duration(microseconds: 1)),
      ),
      accountId: account.id,
      type: type,
      amount: amount,
      occurredAt: occurredAt.toUtc(),
      referenceId: original.id.value,
      note: note,
      category: category,
      source: AccountEntrySource.manual,
    );
    if (repository case AtomicFinanceReversal atomic) {
      await atomic.reverseEntry(
        expected: original,
        accountId: account.id,
        occurredAt: occurredAt,
        corrected: corrected,
      );
    } else {
      throw const ValidationError('Atomic finance reversal is required');
    }
    return corrected;
  });

  Future<AccountEntry> voidEntry({
    required AccountEntry original,
    required FinancialAccount account,
    DateTime? occurredAt,
  }) => CommandGate.runFor(repository, () async {
    _assertActive(account);
    if (repository case AtomicFinanceReversal atomic) {
      return atomic.reverseEntry(
        expected: original,
        accountId: account.id,
        occurredAt: occurredAt ?? DateTime.now().toUtc(),
      );
    }
    throw const ValidationError('Atomic finance reversal is required');
  });

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

/// Fresh-state admission shared by production persistence and test repositories.
List<AccountEntry> prepareFinanceReversal({
  required AccountEntry expected,
  required StableId accountId,
  required List<AccountEntry> entries,
  required List<FinancialAccount> accounts,
  required DateTime occurredAt,
  AccountEntry? corrected,
}) {
  final original = entries.where((e) => e.id == expected.id).firstOrNull;
  if (original == null ||
      original.accountId != accountId ||
      original.type != expected.type ||
      original.amount != expected.amount ||
      original.referenceId != expected.referenceId ||
      original.transferGroupId != expected.transferGroupId ||
      original.occurredAt.millisecondsSinceEpoch ~/ 1000 !=
          expected.occurredAt.millisecondsSinceEpoch ~/ 1000 ||
      original.type == AccountEntryType.reversal) {
    throw const ValidationError('Transaction changed or cannot be reversed');
  }
  final targets = original.transferGroupId == null
      ? [original]
      : entries
            .where(
              (e) =>
                  e.transferGroupId == original.transferGroupId &&
                  e.type != AccountEntryType.reversal,
            )
            .toList();
  if (original.transferGroupId != null) {
    final outgoing = targets
        .where((e) => e.type == AccountEntryType.transferOut)
        .toList();
    final incoming = targets
        .where((e) => e.type == AccountEntryType.transferIn)
        .toList();
    if (corrected != null ||
        outgoing.length != 1 ||
        incoming.length != 1 ||
        outgoing.single.amount != incoming.single.amount ||
        outgoing.single.accountId == incoming.single.accountId ||
        targets.any(
          (e) => !{
            AccountEntryType.transferOut,
            AccountEntryType.transferIn,
            AccountEntryType.expense,
          }.contains(e.type),
        )) {
      throw const ValidationError(
        'Transfer reversal requires its complete group',
      );
    }
  }
  for (final entry in targets) {
    final account = accounts.where((a) => a.id == entry.accountId).firstOrNull;
    if (account == null ||
        account.status != FinancialAccountStatus.active ||
        account.currency != entry.amount.currency ||
        entries.any(
          (e) =>
              e.referenceId == entry.id.value &&
              (e.type == AccountEntryType.reversal ||
                  e.note == 'حذف امن تراکنش ${entry.id.value}' ||
                  e.note == 'اصلاح تراکنش ${entry.id.value}'),
        )) {
      throw const ValidationError(
        'Entry already reversed or account unavailable',
      );
    }
  }
  if (corrected != null &&
      (corrected.accountId != accountId ||
          corrected.amount.currency != original.amount.currency ||
          !{
            AccountEntryType.income,
            AccountEntryType.expense,
          }.contains(corrected.type) ||
          corrected.amount.minorUnits <= 0 ||
          original.transferGroupId != null)) {
    throw const ValidationError('Invalid corrected entry');
  }
  return [
    for (final entry in targets)
      AccountEntry(
        id: StableId.generate(),
        accountId: entry.accountId,
        type: AccountEntryType.reversal,
        amount: -entry.signedAmount,
        occurredAt: occurredAt.toUtc(),
        referenceId: entry.id.value,
        transferGroupId: entry.transferGroupId,
      ),
  ];
}
