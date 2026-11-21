import 'package:planact/features/finance/domain/finance.dart';

/// Read-only evidence from one atomic financial operation, never inferred from
/// arbitrary reference IDs, notes or timestamp proximity.
class FinanceHistoryOperation {
  const FinanceHistoryOperation({required this.before, required this.after});
  final List<String> before;
  final List<String> after;
}

enum ReversalPurpose { correction, cancellation, unknown }

class TransactionHistoryRole {
  const TransactionHistoryRole({
    this.replacement = false,
    this.corrected = false,
    this.reversed = false,
    this.reversalPurpose,
  });
  final bool replacement;
  final bool corrected;
  final bool reversed;
  final ReversalPurpose? reversalPurpose;
}

class TransactionHistoryItem {
  const TransactionHistoryItem(this.entry, this.role);
  final AccountEntry entry;
  final TransactionHistoryRole role;
}

class TransactionHistory {
  const TransactionHistory({required this.role, required this.chain});
  final TransactionHistoryRole role;
  final List<TransactionHistoryItem> chain;
}

/// Projects only complete, unambiguous, explicitly journalled relationships.
/// Missing evidence leaves a reversal unknown rather than calling it a cancel.
List<AccountEntry> projectTransactionHistory(
  List<AccountEntry> entries,
  Iterable<FinanceHistoryOperation> operations,
) {
  final byId = {for (final e in entries) e.id.value: e};
  final corrected = <String>{};
  final replacements = <String>{};
  final reversed = <String>{};
  final purposes = <String, ReversalPurpose>{};
  final neighbours = <String, Set<String>>{};
  for (final e in entries.where((e) => e.type == AccountEntryType.reversal)) {
    final original = byId[e.referenceId];
    if (original != null && _isReversalOf(e, original)) {
      reversed.add(original.id.value);
    }
  }
  for (final operation in operations) {
    final before = operation.before.toSet();
    final after = operation.after.toSet();
    if (before.isEmpty ||
        before.length != operation.before.length ||
        after.length != operation.after.length ||
        before.intersection(after).isNotEmpty ||
        !before.every(byId.containsKey) ||
        !after.every(byId.containsKey)) {
      continue;
    }
    final originals = before.map((id) => byId[id]!).toList();
    final results = after.map((id) => byId[id]!).toList();
    final reversals = results
        .where((e) => e.type == AccountEntryType.reversal)
        .toList();
    final newEntries = results
        .where((e) => e.type != AccountEntryType.reversal)
        .toList();
    if (reversals.length != originals.length ||
        originals.any(
          (original) =>
              reversals.where((r) => _isReversalOf(r, original)).length != 1,
        )) {
      continue;
    }
    final isCorrection =
        originals.length == 1 &&
        newEntries.length == 1 &&
        _isFinancial(originals.single) &&
        _isFinancial(newEntries.single) &&
        originals.single.transferGroupId == null &&
        newEntries.single.transferGroupId == null &&
        newEntries.single.referenceId == originals.single.id.value &&
        newEntries.single.amount.currency == originals.single.amount.currency;
    if (!isCorrection && newEntries.isNotEmpty) continue;
    for (final reversal in reversals) {
      final purpose = isCorrection
          ? ReversalPurpose.correction
          : ReversalPurpose.cancellation;
      if (purposes.containsKey(reversal.id.value) &&
          purposes[reversal.id.value] != purpose) {
        purposes[reversal.id.value] = ReversalPurpose.unknown;
      } else {
        purposes[reversal.id.value] = purpose;
      }
    }
    if (isCorrection) {
      corrected.add(originals.single.id.value);
      replacements.add(newEntries.single.id.value);
    }
    final ids = {...before, ...after};
    for (final id in ids) {
      (neighbours[id] ??= {}).addAll(ids.where((other) => other != id));
    }
  }
  TransactionHistoryRole role(AccountEntry e) => TransactionHistoryRole(
    replacement: replacements.contains(e.id.value),
    corrected: corrected.contains(e.id.value),
    reversed: reversed.contains(e.id.value),
    reversalPurpose: e.type == AccountEntryType.reversal
        ? purposes[e.id.value] ?? ReversalPurpose.unknown
        : null,
  );
  final chains = <String, List<TransactionHistoryItem>>{};
  for (final id in neighbours.keys) {
    if (chains.containsKey(id)) continue;
    final visited = <String>{};
    final pending = [id];
    while (pending.isNotEmpty) {
      final current = pending.removeLast();
      if (visited.add(current)) pending.addAll(neighbours[current] ?? {});
    }
    final chain = List<TransactionHistoryItem>.unmodifiable([
      for (final e in entries)
        if (visited.contains(e.id.value)) TransactionHistoryItem(e, role(e)),
    ]);
    for (final member in visited) {
      chains[member] = chain;
    }
  }
  return [
    for (final entry in entries)
      entry.withHistory(
        TransactionHistory(
          role: role(entry),
          chain: chains[entry.id.value] ?? const [],
        ),
      ),
  ];
}

bool _isFinancial(AccountEntry e) =>
    e.type == AccountEntryType.income || e.type == AccountEntryType.expense;

bool _isReversalOf(AccountEntry reversal, AccountEntry original) =>
    original.type != AccountEntryType.reversal &&
    reversal.referenceId == original.id.value &&
    reversal.accountId == original.accountId &&
    reversal.amount.currency == original.amount.currency &&
    BigInt.from(reversal.signedAmount.minorUnits) ==
        -BigInt.from(original.signedAmount.minorUnits);
