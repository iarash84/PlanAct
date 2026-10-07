import 'package:planact/core/errors/app_error.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/commitments/application/commitment_plan_use_case.dart';
import 'package:planact/features/commitments/application/commitment_repository.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/finance/application/finance_use_cases.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/reconciliation/application/reconciliation_use_cases.dart';
import 'package:planact/features/reconciliation/domain/reconciliation.dart';
import 'package:planact/features/reconciliation/domain/relationship_review.dart';
import 'package:planact/features/reconciliation/application/relationship_review_repository.dart';
import 'package:planact/features/scheduling/domain/occurrence.dart';

class RelationshipTarget {
  const RelationshipTarget(this.commitment, this.occurrence);
  final Commitment commitment;
  final Occurrence occurrence;
}

class TransactionRelationshipContext {
  const TransactionRelationshipContext({
    required this.transaction,
    required this.account,
    required this.available,
    required this.targets,
    this.review,
  });
  final AccountEntry transaction;
  final FinancialAccount? account;
  final Money available;
  final List<RelationshipTarget> targets;
  final RelationshipReview? review;
}

/// Reloads the durable transaction by identity; navigation never creates a ledger
/// entry or invents a financial expectation for the selected occurrence.
class ContextualReconciliation {
  const ContextualReconciliation({
    required this.finance,
    required this.commitments,
    required this.plans,
    required this.reconciliation,
  });
  final FinanceRepository finance;
  final CommitmentRepository commitments;
  final CommitmentPlanRepository plans;
  final ReconciliationUseCases reconciliation;

  Future<TransactionRelationshipContext> load(StableId transactionId) async {
    final entries = await finance.listEntries();
    final transaction = entries.where((e) => e.id == transactionId).firstOrNull;
    if (transaction == null ||
        (transaction.type != AccountEntryType.income &&
            transaction.type != AccountEntryType.expense) ||
        entries.any(
          (e) =>
              e.type == AccountEntryType.reversal &&
              e.referenceId == transactionId.value,
        )) {
      throw const ValidationError('Transaction is unavailable for matching');
    }
    final accounts = await finance.listAccounts();
    final matches = await reconciliation.repository.list();
    final used = matches
        .where(
          (m) =>
              m.transactionId == transactionId &&
              m.status == MatchStatus.active,
        )
        .fold<int>(0, (sum, m) => sum + m.allocatedMinorUnits);
    final targets = <RelationshipTarget>[];
    for (final commitment in await commitments.list()) {
      // Archived commitments remain selectable as explicitly labelled history.
      final plan = await plans.findByCommitmentId(commitment.id);
      for (final occurrence in plan?.occurrences ?? <Occurrence>[]) {
        targets.add(RelationshipTarget(commitment, occurrence));
      }
    }
    final repository = reconciliation.repository;
    final review = repository is RelationshipReviewRepository
        ? await (repository as RelationshipReviewRepository).loadReview(
            transaction,
          )
        : null;
    return TransactionRelationshipContext(
      review: review,
      transaction: transaction,
      account: accounts.where((a) => a.id == transaction.accountId).firstOrNull,
      available: Money(
        minorUnits:
            review?.remainderMinorUnits ??
            (transaction.amount.minorUnits - used).clamp(
              0,
              transaction.amount.minorUnits,
            ),
        currency:
            review?.transactionAmount.currency ?? transaction.amount.currency,
      ),
      targets: List.unmodifiable(targets),
    );
  }

  Future<RelationshipReview> markIndependent({
    required RelationshipReview expected,
    DateTime? recordedAt,
  }) => _decide(expected, RelationshipReviewDecision.independent, recordedAt);

  Future<RelationshipReview> reopen({
    required RelationshipReview expected,
    DateTime? recordedAt,
  }) => _decide(expected, RelationshipReviewDecision.reopened, recordedAt);

  Future<RelationshipReview> _decide(
    RelationshipReview expected,
    RelationshipReviewDecision decision,
    DateTime? at,
  ) async {
    await load(expected.transactionId);
    final repository = reconciliation.repository;
    if (repository is! RelationshipReviewRepository) {
      throw const ValidationError('Relationship review is unsupported');
    }
    return (repository as RelationshipReviewRepository).decideReview(
      expected: expected,
      decision: decision,
      recordedAt: at ?? DateTime.now().toUtc(),
    );
  }

  Future<void> confirm({
    required StableId transactionId,
    required StableId occurrenceId,
    required int minorUnits,
    RelationshipReview? expectedReview,
  }) async {
    final context = await load(transactionId);
    if (expectedReview != null) {
      if (context.review == null) {
        throw const ValidationError('Relationship review is unsupported');
      }
      context.review!.requireExpected(expectedReview);
    }
    if (context.review?.isIndependent == true) {
      throw const ValidationError(
        'Reopen the relationship review before matching',
      );
    }
    if (minorUnits <= 0 ||
        minorUnits > context.available.minorUnits ||
        !context.targets.any((t) => t.occurrence.id == occurrenceId)) {
      throw const ValidationError('Invalid relationship allocation');
    }
    await reconciliation.match(
      expectedReview: expectedReview ?? context.review,
      transactionId: context.transaction.id,
      transactionAmount: context.transaction.amount,
      createdAt: DateTime.now().toUtc(),
      occurrenceIds: [occurrenceId],
      allocations: [
        Money(
          minorUnits: minorUnits,
          currency: context.transaction.amount.currency,
        ),
      ],
    );
  }
}
