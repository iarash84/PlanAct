import 'package:planact/core/errors/app_error.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/finance/domain/financial_expectation.dart';

enum MatchStatus { active, corrected, reversed }

enum AllocationType { payment, refund, correction }

enum ReconciliationSuggestionStatus {
  noCandidate,
  suggested,
  confirmed,
  rejected,
  partial,
  ambiguous,
}

class MatchReason {
  const MatchReason({required this.points, required this.text});

  final int points;
  final String text;
}

class ReconciliationCandidate {
  const ReconciliationCandidate({
    required this.transaction,
    required this.score,
    required this.reasons,
    required this.status,
    required this.availableAmount,
  });

  final AccountEntry transaction;
  final int score;
  final List<MatchReason> reasons;
  final ReconciliationSuggestionStatus status;
  final Money availableAmount;

  String get explanation => reasons.map((reason) => reason.text).join('، ');
}

class ReconciliationScorer {
  const ReconciliationScorer({
    this.dateWindowDays = 7,
    this.toleranceMinorUnits = 0,
  });

  final int dateWindowDays;
  final int toleranceMinorUnits;

  ReconciliationCandidate? score({
    required AccountEntry transaction,
    required FinancialExpectation expectation,
    required DateTime expectedAt,
    required Money availableAmount,
  }) {
    if (transaction.amount.currency != expectation.currency ||
        transaction.amount.currency != availableAmount.currency) {
      return null;
    }
    final reasons = <MatchReason>[];
    var score = 0;
    final difference = (transaction.amount.minorUnits - expectation.amount)
        .abs();
    if (difference == 0) {
      score += 50;
      reasons.add(const MatchReason(points: 50, text: 'مبلغ یکسان است'));
    } else if (difference <= toleranceMinorUnits) {
      score += 30;
      reasons.add(
        const MatchReason(points: 30, text: 'اختلاف مبلغ در محدوده مجاز است'),
      );
    } else if (transaction.amount.minorUnits < expectation.amount) {
      score += 15;
      reasons.add(const MatchReason(points: 15, text: 'پرداخت جزئی است'));
    } else {
      reasons.add(const MatchReason(points: 0, text: 'اختلاف مبلغ زیاد است'));
    }

    final expectedDirection =
        expectation.direction == FinancialExpectationDirection.incoming
        ? AccountEntryType.income
        : AccountEntryType.expense;
    if (transaction.type == expectedDirection) {
      score += 25;
      reasons.add(const MatchReason(points: 25, text: 'جهت تراکنش درست است'));
    } else {
      reasons.add(const MatchReason(points: 0, text: 'جهت تراکنش نادرست است'));
      return ReconciliationCandidate(
        transaction: transaction,
        score: score,
        reasons: List.unmodifiable(reasons),
        status: ReconciliationSuggestionStatus.noCandidate,
        availableAmount: availableAmount,
      );
    }

    if (expectation.accountId == transaction.accountId) {
      score += 15;
      reasons.add(
        const MatchReason(
          points: 15,
          text: 'حساب مورد انتظار و حساب تراکنش یکسان است',
        ),
      );
    } else if (expectation.accountId != null) {
      reasons.add(const MatchReason(points: 0, text: 'حساب تراکنش متفاوت است'));
    }

    final days = transaction.occurredAt.difference(expectedAt).inDays.abs();
    if (days <= dateWindowDays) {
      final points = 10 - (days > 10 ? 10 : (days > 0 ? days : 0));
      score += points;
      reasons.add(
        MatchReason(
          points: points,
          text: '$days روز با تاریخ مورد انتظار فاصله دارد',
        ),
      );
    } else {
      reasons.add(
        const MatchReason(
          points: 0,
          text: 'تاریخ تراکنش خارج از بازه بررسی است',
        ),
      );
    }

    final status =
        availableAmount.minorUnits < expectation.amount && score >= 40
        ? ReconciliationSuggestionStatus.partial
        : score >= 80
        ? ReconciliationSuggestionStatus.suggested
        : ReconciliationSuggestionStatus.noCandidate;
    return ReconciliationCandidate(
      transaction: transaction,
      score: score,
      reasons: List.unmodifiable(reasons),
      status: status,
      availableAmount: availableAmount,
    );
  }
}

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
    // Allocations may exceed the transaction amount: the excess is retained as
    // an explicit overpayment/credit projection instead of being discarded.
    // Negative allocation values remain forbidden by MatchAllocation.
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
  Money get overpayment => Money(
    minorUnits: allocatedMinorUnits > transactionAmount.minorUnits
        ? allocatedMinorUnits - transactionAmount.minorUnits
        : 0,
    currency: transactionAmount.currency,
  );
  bool get isFull => remaining.minorUnits == 0;
  bool get isPartial =>
      allocatedMinorUnits > 0 &&
      allocatedMinorUnits < transactionAmount.minorUnits;
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
