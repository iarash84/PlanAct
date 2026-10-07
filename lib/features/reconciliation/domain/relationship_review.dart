import 'dart:convert';

import 'package:planact/core/errors/app_error.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/reconciliation/domain/reconciliation.dart';

/// Persisted indices are append-only.
enum RelationshipReviewDecision { independent, reopened }

class RelationshipReviewEntry {
  const RelationshipReviewEntry({
    required this.id,
    required this.transactionId,
    required this.revision,
    required this.decision,
    required this.transactionAmount,
    required this.allocationFingerprint,
    required this.allocationHistoryFingerprint,
    required this.remainderMinorUnits,
    required this.recordedAt,
  });

  final StableId id;
  final StableId transactionId;
  final int revision;
  final RelationshipReviewDecision decision;
  final Money transactionAmount;
  final String allocationFingerprint;
  final String allocationHistoryFingerprint;
  final int remainderMinorUnits;
  final DateTime recordedAt;
}

/// A compare-and-append token, not a mutable flag on a transaction or category.
/// History fingerprint also detects allocation changes followed by restoration
/// (ABA); active identity alone must not resurrect an old independent decision.
class RelationshipReview {
  const RelationshipReview({
    required this.transactionId,
    required this.transactionAmount,
    required this.allocationFingerprint,
    required this.allocationHistoryFingerprint,
    required this.allocatedMinorUnits,
    required this.latestDecision,
  });

  factory RelationshipReview.project({
    required StableId transactionId,
    required Money transactionAmount,
    required Iterable<TransactionMatch> matches,
    RelationshipReviewEntry? latestDecision,
  }) {
    final history = matches
        .where((m) => m.transactionId == transactionId)
        .toList();
    final active = history
        .where((m) => m.status == MatchStatus.active)
        .toList();
    return RelationshipReview(
      transactionId: transactionId,
      transactionAmount: transactionAmount,
      allocationFingerprint: allocationFingerprintFor(active),
      allocationHistoryFingerprint: allocationFingerprintFor(history),
      allocatedMinorUnits: active.fold(
        0,
        (sum, m) => sum + m.allocatedMinorUnits,
      ),
      latestDecision: latestDecision,
    );
  }

  final StableId transactionId;
  final Money transactionAmount;
  final String allocationFingerprint;
  final String allocationHistoryFingerprint;
  final int allocatedMinorUnits;
  final RelationshipReviewEntry? latestDecision;

  int get revision => latestDecision?.revision ?? 0;
  int get remainderMinorUnits =>
      (transactionAmount.minorUnits - allocatedMinorUnits).clamp(
        0,
        transactionAmount.minorUnits,
      );
  bool get isIndependent =>
      remainderMinorUnits > 0 &&
      latestDecision?.decision == RelationshipReviewDecision.independent &&
      latestDecision?.transactionAmount == transactionAmount &&
      latestDecision?.allocationFingerprint == allocationFingerprint &&
      latestDecision?.allocationHistoryFingerprint ==
          allocationHistoryFingerprint &&
      latestDecision?.remainderMinorUnits == remainderMinorUnits;

  void requireExpected(RelationshipReview expected) {
    if (transactionId != expected.transactionId ||
        transactionAmount != expected.transactionAmount ||
        allocationFingerprint != expected.allocationFingerprint ||
        allocationHistoryFingerprint != expected.allocationHistoryFingerprint ||
        allocatedMinorUnits != expected.allocatedMinorUnits ||
        revision != expected.revision ||
        latestDecision?.id != expected.latestDecision?.id) {
      throw const ValidationError(
        'Relationship review is stale; reload before confirming',
      );
    }
  }

  RelationshipReviewEntry append(
    RelationshipReviewDecision decision,
    DateTime at,
  ) {
    if (remainderMinorUnits <= 0 ||
        (decision == RelationshipReviewDecision.independent && isIndependent) ||
        (decision == RelationshipReviewDecision.reopened && !isIndependent)) {
      throw const ValidationError(
        'Relationship review decision is not applicable',
      );
    }
    return RelationshipReviewEntry(
      id: StableId.generate(timestamp: at),
      transactionId: transactionId,
      revision: revision + 1,
      decision: decision,
      transactionAmount: transactionAmount,
      allocationFingerprint: allocationFingerprint,
      allocationHistoryFingerprint: allocationHistoryFingerprint,
      remainderMinorUnits: remainderMinorUnits,
      recordedAt: at.toUtc(),
    );
  }
}

/// Canonical, collision-free encoding of identities, amounts, targets and states.
/// This is deliberately not a total-only fingerprint (equal totals can differ).
String allocationFingerprintFor(Iterable<TransactionMatch> matches) {
  final sorted = matches.toList()
    ..sort((a, b) => a.id.value.compareTo(b.id.value));
  return jsonEncode([
    for (final match in sorted)
      [
        match.id.value,
        match.status.index,
        match.correctedMatchId?.value,
        match.transactionAmount.minorUnits,
        match.transactionAmount.currency,
        ...((match.allocations.toList()
              ..sort((a, b) => a.id.value.compareTo(b.id.value)))
            .map(
              (a) => [
                a.id.value,
                a.occurrenceId.value,
                a.amount.minorUnits,
                a.amount.currency,
                a.type.index,
              ],
            )),
      ],
  ]);
}
