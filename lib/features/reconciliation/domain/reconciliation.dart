import 'package:planact/core/errors/app_error.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';

enum MatchStatus { active, corrected, reversed }

enum AllocationType { payment, refund, correction }

class MatchAllocation {
  MatchAllocation({
    required this.id,
    required this.matchId,
    required this.occurrenceId,
    required this.amount,
    this.type = AllocationType.payment,
  }) {
    if (amount.minorUnits <= 0) {
      throw const ValidationError('Allocation amount must be positive');
    }
  }

  final StableId id;
  final StableId matchId;
  final StableId occurrenceId;
  final Money amount;
  final AllocationType type;
}

class TransactionMatch {
  TransactionMatch({
    required this.id,
    required this.transactionId,
    required this.transactionAmount,
    required this.createdAt,
    required this.allocations,
    this.status = MatchStatus.active,
    this.correctedMatchId,
  }) {
    if (allocations.isEmpty) {
      throw const ValidationError('A match must contain an allocation');
    }
    if (allocations.any((item) => item.matchId != id)) {
      throw const ValidationError('Allocation belongs to another match');
    }
    if (allocations.any(
      (item) => item.amount.currency != transactionAmount.currency,
    )) {
      throw const ValidationError('Match currencies must be equal');
    }
    final allocated = allocations.fold(
      0,
      (sum, item) => sum + item.amount.minorUnits,
    );
    if (allocated > transactionAmount.minorUnits) {
      throw const ValidationError(
        'Allocations cannot exceed transaction amount',
      );
    }
  }

  final StableId id;
  final StableId transactionId;
  final Money transactionAmount;
  final DateTime createdAt;
  final List<MatchAllocation> allocations;
  final MatchStatus status;
  final StableId? correctedMatchId;

  int get allocatedMinorUnits =>
      allocations.fold(0, (sum, item) => sum + item.amount.minorUnits);
  Money get remaining => Money(
    minorUnits: transactionAmount.minorUnits - allocatedMinorUnits,
    currency: transactionAmount.currency,
  );
  bool get isFull => remaining.minorUnits == 0;
  bool get isPartial => allocatedMinorUnits > 0 && !isFull;
  bool get isOverpayment => allocatedMinorUnits > transactionAmount.minorUnits;
}

class FinancialPlannedVsActual {
  const FinancialPlannedVsActual({
    required this.occurrenceId,
    required this.plannedAmount,
    required this.matchedAmount,
    required this.explanation,
  });

  final StableId occurrenceId;
  final Money plannedAmount;
  final Money matchedAmount;
  final String explanation;
  Money get variance => plannedAmount - matchedAmount;
  bool get settled => variance.minorUnits == 0;
}
