import 'package:planact/core/errors/app_error.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';

enum FinancialAccountType { bank, cash, digitalWallet, credit }

enum FinancialAccountStatus { active, archived }

enum AccountEntrySource { manual, sms, import }

enum TransferMethod { cardToCard, sheba, pol, satna, paya }

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

enum IranianBank {
  melli('ملی', 'melli'),
  mellat('ملت', 'mellat'),
  saderat('صادرات', 'saderat'),
  tejarat('تجارت', 'tejarat'),
  refah('رفاه', 'refah'),
  maskan('مسکن', 'maskan'),
  sepah('سپه', 'sepah'),
  keshavarzi('کشاورزی', 'keshavarzi'),
  pasargad('پاسارگاد', 'pasargad'),
  saman('سامان', 'saman'),
  parsian('پارسیان', 'parsian'),
  shahr('شهر', 'shahr'),
  ayandeh('آینده', 'ayandeh'),
  eghtesadNovin('اقتصاد نوین', 'eghtesad_novin'),
  day('دی', 'day'),
  gardeshgari('گردشگری', 'gardeshgari'),
  iranZamin('ایران‌زمین', 'iran_zamin'),
  karafarin('کارآفرین', 'karafarin'),
  sina('سینا', 'sina'),
  ghavamin('قوامین', 'ghavamin');

  const IranianBank(this.label, this.code);
  final String label;
  final String code;

  static IranianBank? fromCode(String? code) => code == null
      ? null
      : IranianBank.values.where((bank) => bank.code == code).firstOrNull;

  static IranianBank? detect(String name) {
    final normalized = name.replaceAll('ي', 'ی').replaceAll('ك', 'ک');
    return IranianBank.values
        .where((bank) => normalized.contains(bank.label))
        .firstOrNull;
  }
}

class FinancialAccount {
  FinancialAccount({
    required this.id,
    required this.name,
    required this.currency,
    required this.type,
    this.bank,
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
  final IranianBank? bank;
  final FinancialAccountStatus status;

  FinancialAccount archive() => FinancialAccount(
    id: id,
    name: name,
    currency: currency,
    type: type,
    bank: bank,
    status: FinancialAccountStatus.archived,
  );

  FinancialAccount restore() => FinancialAccount(
    id: id,
    name: name,
    currency: currency,
    type: type,
    bank: bank,
    status: FinancialAccountStatus.active,
  );

  FinancialAccount update({
    required String name,
    FinancialAccountType? type,
    IranianBank? bank,
  }) => FinancialAccount(
    id: id,
    name: name,
    currency: currency,
    type: type ?? this.type,
    bank: bank ?? this.bank,
    status: status,
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
    this.category,
    this.source = AccountEntrySource.manual,
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
  final String? category;
  final AccountEntrySource source;
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
