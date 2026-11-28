import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/finance/domain/financial_expectation.dart';
import 'package:planact/features/reconciliation/domain/reconciliation.dart';

/// Missing means no retained expectation, not an ambiguous/archived expectation.
enum OccurrenceExpectationState { missing, existing, ambiguous }

enum OccurrenceAllocationErrorCode {
  stale,
  missing,
  ambiguous,
  currency,
  capacity,
  historicalInactive,
  storage,
}

class OccurrenceAllocationException implements Exception {
  const OccurrenceAllocationException(this.code);
  final OccurrenceAllocationErrorCode code;
  @override
  String toString() => 'OccurrenceAllocationException(${code.name})';
}

/// Immutable read model. [fingerprint] is opaque and must not be interpreted by UI.
/// Confirmation uses fresh durable values, never caller-modified snapshot fields.
class OccurrenceAllocationSnapshot {
  const OccurrenceAllocationSnapshot({
    required this.transaction,
    required this.occurrenceId,
    required this.expectationState,
    required this.suggestedDirection,
    required this.expectedTotal,
    required this.expectationCapacity,
    required this.transactionCapacity,
    required this.fingerprint,
  });

  final AccountEntry transaction;
  final StableId occurrenceId;
  final OccurrenceExpectationState expectationState;
  final FinancialExpectationDirection suggestedDirection;
  final Money? expectedTotal;
  final Money? expectationCapacity;
  final Money transactionCapacity;
  final String fingerprint;
}

abstract interface class AtomicOccurrenceAllocationRepository {
  /// Read-only: opening or cancelling this snapshot performs no write.
  Future<OccurrenceAllocationSnapshot> loadOccurrenceAllocation(
    StableId transactionId,
    StableId occurrenceId,
  );

  /// [total] is required only for missing expectations; it is never inferred
  /// from [allocation]. An existing expectation cannot be edited by this command.
  Future<TransactionMatch> confirmOccurrenceAllocation(
    OccurrenceAllocationSnapshot snapshot, {
    Money? total,
    required Money allocation,
  });
}
