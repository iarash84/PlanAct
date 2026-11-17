import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/core/errors/app_error.dart';
import 'package:planact/core/money/signed_int64.dart';

/// A blocked operation is not permission to reverse or retry it automatically.
class BankRecoveryRequired extends ValidationError {
  const BankRecoveryRequired(super.message, this.accountIds);
  final Set<String> accountIds;
}

class BankRecoveryDecision {
  const BankRecoveryDecision({
    required this.entry,
    required this.observationId,
    required this.through,
    required this.reason,
  });
  final AccountEntry entry;
  final String observationId;
  final DateTime through;
  final BankReconciliationReason reason;
}

class BankRecoveryPreview {
  const BankRecoveryPreview({
    required this.accounts,
    required this.tokens,
    required this.decisions,
  });
  final List<FinancialAccount> accounts;
  final Map<String, String> tokens;

  /// Newest report boundary first, across every involved account.
  final List<BankRecoveryDecision> decisions;
}

abstract interface class BankRecoveryRepository {
  Future<BankRecoveryPreview> previewBankRecovery(Set<String> accountIds);
  Future<void> recoverBankReconciliations(BankRecoveryPreview expected);
}

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
    this.revision = 0,
    this.active = true,
  });

  final String id;
  final String entryId;
  final String accountId;
  final int? irr;
  final int sourceAmount;
  final String? sourceUnit;
  final DateTime? transactionTime;
  final int revision;
  final bool active;
  bool get complete => irr != null && transactionTime != null;

  Map<String, dynamic> toJson() => {
    'version': 1,
    'revision': revision,
    'active': active,
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
      revision: json['revision'] as int? ?? 0,
      active: json['active'] as bool? ?? true,
      irr: json['irr'] as int?,
      sourceAmount: json['sourceAmount'] as int,
      sourceUnit: json['sourceUnit'] as String?,
      transactionTime: json['transactionTime'] == null
          ? null
          : DateTime.parse(json['transactionTime'] as String),
    );
  }
}

/// Review is evidence-only: it never reverses or replaces a ledger entry.
abstract interface class BankObservationReviewRepository {
  Future<void> reviewBankObservation({
    required BankBalanceObservation expected,
    required String accountId,
    required int sourceAmount,
    required String? sourceUnit,
    required DateTime? transactionTime,
    required bool active,
  });
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
    this.observations = const [],
    this.accountName,
  });
  final String? accountName;
  final List<BankBalanceObservation> observations;
  final String accountId;
  final BankBalanceObservation? latest;
  final bool ambiguous;
  final int ledgerAtReport;
  final String token;
  final bool activeReconciliation;
  int? get difference => latest?.irr == null
      ? null
      : trySignedInt64(BigInt.from(latest!.irr!) - BigInt.from(ledgerAtReport));
  bool get canReconcile =>
      latest?.transactionTime != null &&
      !ambiguous &&
      !activeReconciliation &&
      difference != null &&
      difference != 0;
}

BankBalanceSnapshot projectBankBalance({
  required String accountId,
  required List<BankBalanceObservation> observations,
  required List<AccountEntry> entries,
  required String token,
  required bool activeReconciliation,
  String? accountName,
}) {
  final own = observations
      .where((o) => o.accountId == accountId && o.active)
      .toList();
  final reliable = own.where((o) => o.complete).toList()
    ..sort((a, b) => b.transactionTime!.compareTo(a.transactionTime!));
  final latest = reliable.firstOrNull;
  // Equal timestamps cannot establish a last post-transaction balance, even if
  // their values agree. Unknown timestamps may be newer: disclose and block.
  final ambiguous =
      own.any((o) => !o.complete) ||
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
      : checkedSignedInt64(
          entries
              .where((e) {
                final effectiveTime = e.type == AccountEntryType.reversal
                    ? originals[e.referenceId]?.occurredAt ?? e.occurredAt
                    : e.occurredAt;
                return e.accountId.value == accountId &&
                    !effectiveTime.isAfter(latest.transactionTime!);
              })
              .fold<BigInt>(BigInt.zero, (sum, e) {
                final amount = BigInt.from(e.amount.minorUnits);
                return sum +
                    (e.type == AccountEntryType.expense ||
                            e.type == AccountEntryType.transferOut
                        ? -amount
                        : amount);
              }),
        );
  return BankBalanceSnapshot(
    accountName: accountName,
    accountId: accountId,
    observations: observations.where((o) => o.accountId == accountId).toList(),
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
