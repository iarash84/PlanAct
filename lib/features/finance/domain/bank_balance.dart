import 'package:planact/features/finance/domain/finance.dart';

/// A bank observation is historical evidence, never a mutable ledger balance.
class BankBalanceObservation {
  const BankBalanceObservation({
    required this.id,
    required this.entryId,
    required this.accountId,
    required this.irr,
    required this.sourceAmount,
    required this.sourceUnit,
    required this.transactionTime,
  });

  final String id;
  final String entryId;
  final String accountId;
  final int irr;
  final int sourceAmount;
  final String sourceUnit;
  final DateTime? transactionTime;

  Map<String, dynamic> toJson() => {
    'version': 1,
    'id': id,
    'entryId': entryId,
    'accountId': accountId,
    'irr': irr,
    'sourceAmount': sourceAmount,
    'sourceUnit': sourceUnit,
    'transactionTime': transactionTime?.toUtc().toIso8601String(),
  };

  factory BankBalanceObservation.fromJson(Map<String, dynamic> json) {
    if (json['version'] != 1) throw StateError('Unsupported bank observation');
    return BankBalanceObservation(
      id: json['id'] as String,
      entryId: json['entryId'] as String,
      accountId: json['accountId'] as String,
      irr: json['irr'] as int,
      sourceAmount: json['sourceAmount'] as int,
      sourceUnit: json['sourceUnit'] as String,
      transactionTime: json['transactionTime'] == null
          ? null
          : DateTime.parse(json['transactionTime'] as String),
    );
  }
}

enum BankReconciliationReason { knownFee, unknownAdjustment }

class BankBalanceSnapshot {
  const BankBalanceSnapshot({
    required this.accountId,
    required this.latest,
    required this.ambiguous,
    required this.ledgerAtReport,
    required this.token,
    required this.activeReconciliation,
  });
  final String accountId;
  final BankBalanceObservation? latest;
  final bool ambiguous;
  final int ledgerAtReport;
  final String token;
  final bool activeReconciliation;
  int? get difference => latest == null ? null : latest!.irr - ledgerAtReport;
  bool get canReconcile =>
      latest?.transactionTime != null &&
      !ambiguous &&
      !activeReconciliation &&
      difference != 0;
}

BankBalanceSnapshot projectBankBalance({
  required String accountId,
  required List<BankBalanceObservation> observations,
  required List<AccountEntry> entries,
  required String token,
  required bool activeReconciliation,
}) {
  final own = observations.where((o) => o.accountId == accountId).toList();
  final reliable = own.where((o) => o.transactionTime != null).toList()
    ..sort((a, b) => b.transactionTime!.compareTo(a.transactionTime!));
  final latest = reliable.firstOrNull;
  // Equal timestamps cannot establish a last post-transaction balance, even if
  // their values agree. Unknown timestamps may be newer: disclose and block.
  final ambiguous =
      own.any((o) => o.transactionTime == null) ||
      (latest != null &&
          reliable
                  .where((o) => o.transactionTime == latest.transactionTime)
                  .length >
              1);
  // Reconciliation compares corrected history, not historical cash reporting.
  // A later reversal therefore cancels its original effect at the boundary.
  final originals = {for (final entry in entries) entry.id.value: entry};
  final atReport = latest == null
      ? 0
      : entries
            .where((e) {
              final effectiveTime = e.type == AccountEntryType.reversal
                  ? originals[e.referenceId]?.occurredAt ?? e.occurredAt
                  : e.occurredAt;
              return e.accountId.value == accountId &&
                  !effectiveTime.isAfter(latest.transactionTime!);
            })
            .fold<int>(0, (sum, e) => sum + e.signedAmount.minorUnits);
  return BankBalanceSnapshot(
    accountId: accountId,
    latest: latest,
    ambiguous: ambiguous,
    ledgerAtReport: atReport,
    token: token,
    activeReconciliation: activeReconciliation,
  );
}

abstract interface class BankBalanceRepository {
  Future<BankBalanceSnapshot> bankBalance(String accountId);
  Future<AccountEntry> reconcileBankBalance(
    BankBalanceSnapshot expected,
    BankReconciliationReason reason,
  );
}
