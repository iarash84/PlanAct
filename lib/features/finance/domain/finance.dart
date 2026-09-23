import 'package:planact/core/errors/app_error.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';

enum FinancialAccountType { bank, cash, digitalWallet, credit }

enum FinancialAccountStatus { active, archived }

enum AccountEntryType {
  openingBalance,
  income,
  expense,
  transferIn,
  transferOut,
  adjustment,
  refund,
  reversal,
}

class FinancialAccount {
  FinancialAccount({
    required this.id,
    required this.name,
    required this.currency,
    required this.type,
    this.status = FinancialAccountStatus.active,
  }) {
    if (name.trim().isEmpty || currency.trim().isEmpty) {
      throw const ValidationError('Account name and currency are required');
    }
  }
  final StableId id;
  final String name;
  final String currency;
  final FinancialAccountType type;
  final FinancialAccountStatus status;

  FinancialAccount archive() => FinancialAccount(
    id: id,
    name: name,
    currency: currency,
    type: type,
    status: FinancialAccountStatus.archived,
  );
}

class AccountEntry {
  AccountEntry({
    required this.id,
    required this.accountId,
    required this.type,
    required this.amount,
    required this.occurredAt,
    this.referenceId,
    this.note,
    this.transferGroupId,
  }) {
    if (amount.minorUnits == 0) {
      throw const ValidationError('Entry amount cannot be zero');
    }
  }
  final StableId id;
  final StableId accountId;
  final AccountEntryType type;
  final Money amount;
  final DateTime occurredAt;
  final String? referenceId;
  final String? note;
  final StableId? transferGroupId;

  Money get signedAmount {
    switch (type) {
      case AccountEntryType.expense:
      case AccountEntryType.transferOut:
        return -amount;
      case AccountEntryType.openingBalance:
      case AccountEntryType.income:
      case AccountEntryType.adjustment:
      case AccountEntryType.refund:
      case AccountEntryType.reversal:
      case AccountEntryType.transferIn:
        return amount;
    }
  }
}

Money rebuildBalance(FinancialAccount account, Iterable<AccountEntry> entries) {
  var balance = Money(minorUnits: 0, currency: account.currency);
  for (final entry in entries.where((e) => e.accountId == account.id)) {
    balance += entry.signedAmount;
  }
  return balance;
}
