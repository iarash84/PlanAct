import 'package:planact/features/reconciliation/application/atomic_occurrence_allocation_repository.dart';
import 'package:planact/features/classification/application/tag_repository.dart';
import 'package:planact/features/reconciliation/application/relationship_target_reader.dart';
import 'package:planact/features/commitments/application/commitment_cycles.dart';
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

import 'package:planact/features/reconciliation/application/commitment_association_repository.dart';
import 'package:planact/features/reconciliation/domain/commitment_association.dart';

class RelationshipTarget {
  const RelationshipTarget(
    this.commitment,
    this.occurrence, {
    this.expected,
    this.allocated,
    this.outstanding,
    this.cycleLabel,
  });
  final Commitment commitment;
  final Occurrence occurrence;
  final Money? expected;
  final Money? allocated;
  final Money? outstanding;
  final String? cycleLabel;
}

class TransactionRelationshipContext {
  const TransactionRelationshipContext({
    required this.transaction,
    required this.account,
    required this.available,
    required this.targets,
    this.review,
    this.matches = const [],
    this.association,
    this.commitments = const [],
    this.transactionTags = const [],
  });
  final List<String> transactionTags;
  final CommitmentAssociation? association;
  final List<Commitment> commitments;
  final AccountEntry transaction;
  final FinancialAccount? account;
  final Money available;
  final List<RelationshipTarget> targets;
  final RelationshipReview? review;
  final List<TransactionMatch> matches;
}

/// Reloads the durable transaction by identity; navigation never creates a ledger
/// entry or invents a financial expectation for the selected occurrence.
class ContextualReconciliation {
  const ContextualReconciliation({
    required this.finance,
    required this.commitments,
    required this.plans,
    required this.reconciliation,
    this.targetReader,
    this.pageLoader,
    this.tags,
  });
  final FinanceRepository finance;
  final CommitmentRepository commitments;
  final CommitmentPlanRepository plans;
  final ReconciliationUseCases reconciliation;

  final RelationshipTargetReader? targetReader;
  final TagRepository? tags;
  final Future<TransactionRelationshipContext> Function(
    Future<TransactionRelationshipContext> Function() read,
  )?
  pageLoader;

  Future<TransactionRelationshipContext> load(StableId transactionId) =>
      _load(transactionId, includeTargets: true);

  Future<TransactionRelationshipContext> loadForPage(StableId transactionId) {
    if (targetReader == null && pageLoader == null) return load(transactionId);
    Future<TransactionRelationshipContext> read() =>
        _load(transactionId, includeTargets: targetReader == null);
    return pageLoader == null ? read() : pageLoader!(read);
  }

  Future<TransactionRelationshipContext> _load(
    StableId transactionId, {
    required bool includeTargets,
  }) async {
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
    final selectableCommitments = await commitments.list();
    for (final commitment
        in includeTargets ? selectableCommitments : <Commitment>[]) {
      // Archived commitments remain selectable as explicitly labelled history.
      final allPlans = await plans.listByCommitmentId(commitment.id);
      for (final occurrence in allPlans.expand((p) => p.occurrences)) {
        targets.add(RelationshipTarget(commitment, occurrence));
      }
    }
    final repository = reconciliation.repository;
    final review = repository is RelationshipReviewRepository
        ? await (repository as RelationshipReviewRepository).loadReview(
            transaction,
          )
        : null;
    if (!includeTargets) {
      targets.addAll(
        await targetReader!.byIds(
          matches
              .where((m) => m.transactionId == transactionId)
              .expand((m) => m.allocations.map((a) => a.occurrenceId)),
          transaction.amount.currency,
        ),
      );
    }
    final tagRepository = tags;
    final transactionTags = <String>[];
    if (tagRepository != null) {
      final memberships = await tagRepository.tagsFor(
        transactionId.value,
        TaggableType.accountEntry,
      );
      transactionTags.addAll(
        (await tagRepository.list())
            .where((tag) => memberships.contains(tag.id))
            .map((tag) => tag.label),
      );
      transactionTags.sort();
    }
    return TransactionRelationshipContext(
      transactionTags: List.unmodifiable(transactionTags),
      association: repository is CommitmentAssociationRepository
          ? await (repository as CommitmentAssociationRepository)
                .loadAssociation(transactionId)
          : null,
      commitments: List.unmodifiable(selectableCommitments),
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
      matches: List.unmodifiable(
        matches.where((m) => m.transactionId == transactionId),
      ),
    );
  }

  Future<CommitmentAssociation> associateCommitment({
    required CommitmentAssociation expected,
    required StableId transactionId,
    required StableId? commitmentId,
  }) {
    final repository = reconciliation.repository;
    if (repository is! CommitmentAssociationRepository) {
      throw const ValidationError('Commitment association is unavailable');
    }
    return (repository as CommitmentAssociationRepository).associateCommitment(
      expected: expected,
      transactionId: transactionId,
      commitmentId: commitmentId,
    );
  }

  Future<RelationshipReview> markIndependent({
    required RelationshipReview expected,
    DateTime? recordedAt,
  }) => _decide(expected, RelationshipReviewDecision.independent, recordedAt);

  Future<void> removeMatch(TransactionMatch expected) =>
      reconciliation.unmatch(expected);

  Future<void> correctMatch({
    required TransactionMatch original,
    required List<StableId> occurrenceIds,
    required List<Money> allocations,
  }) async {
    final current = await load(original.transactionId);
    if (!occurrenceIds.every(
      (id) => current.targets.any((t) => t.occurrence.id == id),
    )) {
      throw const ValidationError('Occurrence no longer available');
    }
    await reconciliation.correct(
      original: original,
      createdAt: DateTime.now().toUtc(),
      occurrenceIds: occurrenceIds,
      allocations: allocations,
    );
  }

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

  bool get supportsAtomicAllocation =>
      reconciliation.repository is AtomicOccurrenceAllocationRepository;

  Future<OccurrenceAllocationSnapshot?> loadOccurrenceAllocation(
    StableId transactionId,
    StableId occurrenceId,
  ) async {
    final repository = reconciliation.repository;
    if (repository is! AtomicOccurrenceAllocationRepository) return null;
    return (repository as AtomicOccurrenceAllocationRepository)
        .loadOccurrenceAllocation(transactionId, occurrenceId);
  }

  Future<void> confirmSelectedOccurrence({
    required OccurrenceAllocationSnapshot? snapshot,
    required StableId transactionId,
    required StableId occurrenceId,
    required Money allocation,
    Money? total,
    RelationshipReview? expectedReview,
  }) async {
    final repository = reconciliation.repository;
    if (repository is AtomicOccurrenceAllocationRepository) {
      if (snapshot == null ||
          snapshot.transaction.id != transactionId ||
          snapshot.occurrenceId != occurrenceId) {
        throw const OccurrenceAllocationException(
          OccurrenceAllocationErrorCode.stale,
        );
      }
      await (repository as AtomicOccurrenceAllocationRepository)
          .confirmOccurrenceAllocation(
            snapshot,
            total: total,
            allocation: allocation,
          );
      return;
    }
    // Compatibility for nonproduction repositories without the atomic contract.
    if (total != null) {
      throw const OccurrenceAllocationException(
        OccurrenceAllocationErrorCode.missing,
      );
    }
    await confirm(
      transactionId: transactionId,
      occurrenceId: occurrenceId,
      minorUnits: allocation.minorUnits,
      expectedReview: expectedReview,
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
