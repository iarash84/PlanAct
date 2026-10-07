import 'package:planact/core/application/command_gate.dart';
import 'package:planact/core/errors/app_error.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/finance/domain/financial_expectation.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/reconciliation/domain/reconciliation.dart';
import 'package:planact/features/reconciliation/domain/relationship_review.dart';
import 'package:planact/features/reconciliation/application/relationship_review_repository.dart';

abstract interface class ReconciliationRepository {
  Future<List<TransactionMatch>> list();
  Future<void> save(TransactionMatch match);
}

abstract interface class AtomicMatchCorrection {
  Future<void> saveCorrection({
    required TransactionMatch original,
    required TransactionMatch corrected,
  });
}

class ReconciliationEngine {
  const ReconciliationEngine({this.scorer = const ReconciliationScorer()});

  final ReconciliationScorer scorer;

  List<ReconciliationCandidate> findCandidates({
    required AccountEntry transaction,
    required Iterable<FinancialExpectation> expectations,
    required Map<StableId, DateTime> expectedDates,
    required Iterable<TransactionMatch> existingMatches,
  }) {
    final used = <StableId, int>{};
    for (final match in existingMatches.where(
      (item) => item.status == MatchStatus.active,
    )) {
      for (final allocation in match.allocations) {
        used[match.transactionId] =
            (used[match.transactionId] ?? 0) + allocation.amount.minorUnits;
      }
    }
    final available = Money(
      minorUnits: transaction.amount.minorUnits - (used[transaction.id] ?? 0),
      currency: transaction.amount.currency,
    );
    if (available.minorUnits <= 0) return const [];
    return expectations
        .where((item) => item.status == FinancialExpectationStatus.active)
        .map((item) {
          final candidate = scorer.score(
            transaction: transaction,
            expectation: item,
            expectedAt: expectedDates[item.occurrenceId] ?? item.createdAt,
            availableAmount: available,
          );
          return candidate;
        })
        .whereType<ReconciliationCandidate>()
        .where(
          (item) => item.status != ReconciliationSuggestionStatus.noCandidate,
        )
        .toList(growable: false)
      ..sort((a, b) => b.score.compareTo(a.score));
  }
}

class InMemoryReconciliationRepository
    implements
        ReconciliationRepository,
        RelationshipReviewRepository,
        AtomicMatchCorrection {
  final Map<StableId, TransactionMatch> _matches = {};
  final Map<StableId, AccountEntry> _transactions = {};
  final Map<StableId, List<RelationshipReviewEntry>> _reviews = {};

  RelationshipReview _review(StableId id) => RelationshipReview.project(
    transactionId: id,
    transactionAmount:
        (_transactions[id] ??
                (throw const ValidationError(
                  'Load the transaction review first',
                )))
            .amount,
    matches: _matches.values,
    latestDecision: _reviews[id]?.lastOrNull,
  );

  @override
  Future<RelationshipReview> loadReview(AccountEntry transaction) async {
    if (transaction.type != AccountEntryType.income &&
        transaction.type != AccountEntryType.expense) {
      throw const ValidationError('Transaction is not eligible for matching');
    }
    _transactions[transaction.id] = transaction;
    return _review(transaction.id);
  }

  @override
  Future<List<RelationshipReviewEntry>> reviewHistory(
    AccountEntry transaction,
  ) async => List.unmodifiable(_reviews[transaction.id] ?? []);

  @override
  Future<RelationshipReview> decideReview({
    required RelationshipReview expected,
    required RelationshipReviewDecision decision,
    required DateTime recordedAt,
  }) async {
    final current = _review(expected.transactionId);
    current.requireExpected(expected);
    final entry = current.append(decision, recordedAt);
    (_reviews[expected.transactionId] ??= []).add(entry);
    return _review(expected.transactionId);
  }

  @override
  Future<void> saveReviewedMatch(
    TransactionMatch match,
    RelationshipReview expected,
  ) async {
    final current = _review(match.transactionId);
    current.requireExpected(expected);
    if (current.isIndependent) {
      throw const ValidationError(
        'Reopen the relationship review before matching',
      );
    }
    _save(match);
  }

  void _save(TransactionMatch match) {
    final old = _matches[match.id];
    if (old != null) {
      TransactionMatch immutablePart(TransactionMatch value) =>
          TransactionMatch(
            id: value.id,
            transactionId: value.transactionId,
            transactionAmount: value.transactionAmount,
            createdAt: value.createdAt,
            allocations: value.allocations,
          );
      if (old.transactionId != match.transactionId ||
          old.createdAt != match.createdAt ||
          allocationFingerprintFor([immutablePart(old)]) !=
              allocationFingerprintFor([immutablePart(match)]) ||
          (old.status != MatchStatus.active &&
              (old.status != match.status ||
                  old.correctedMatchId != match.correctedMatchId)) ||
          (old.status == MatchStatus.active &&
              match.status == MatchStatus.active &&
              old.correctedMatchId != match.correctedMatchId)) {
        throw const ValidationError('Match history cannot be rewritten');
      }
    } else if (match.status != MatchStatus.active) {
      throw const ValidationError('Only existing matches can be resolved');
    }
    if (match.status == MatchStatus.active) {
      final current = _transactions[match.transactionId];
      if (current != null && current.amount != match.transactionAmount) {
        throw const ValidationError('Transaction amount changed');
      }
      final used = _matches.values
          .where(
            (m) =>
                m.transactionId == match.transactionId &&
                m.id != match.id &&
                m.status == MatchStatus.active,
          )
          .fold(0, (sum, m) => sum + m.allocatedMinorUnits);
      if (used + match.allocatedMinorUnits >
          match.transactionAmount.minorUnits) {
        throw const ValidationError(
          'Cumulative allocation exceeds transaction amount',
        );
      }
      if (current != null && _review(match.transactionId).isIndependent) {
        throw const ValidationError(
          'Reopen the relationship review before matching',
        );
      }
    }
    _matches[match.id] = match;
  }

  @override
  Future<void> saveCorrection({
    required TransactionMatch original,
    required TransactionMatch corrected,
  }) async {
    final before = Map<StableId, TransactionMatch>.from(_matches);
    try {
      _save(original);
      _save(corrected);
    } catch (_) {
      _matches
        ..clear()
        ..addAll(before);
      rethrow;
    }
  }

  @override
  Future<List<TransactionMatch>> list() async =>
      List.unmodifiable(_matches.values);

  @override
  Future<void> save(TransactionMatch match) async => _save(match);
}

class ReconciliationUseCases {
  ReconciliationUseCases(
    this.repository, {
    this.engine = const ReconciliationEngine(),
  });
  final ReconciliationRepository repository;
  final ReconciliationEngine engine;

  Future<List<ReconciliationCandidate>> candidates({
    required AccountEntry transaction,
    required Iterable<FinancialExpectation> expectations,
    required Map<StableId, DateTime> expectedDates,
  }) async => engine.findCandidates(
    transaction: transaction,
    expectations: expectations,
    expectedDates: expectedDates,
    existingMatches: await repository.list(),
  );

  Future<TransactionMatch> match({
    required StableId transactionId,
    required Money transactionAmount,
    required DateTime createdAt,
    required List<StableId> occurrenceIds,
    required List<Money> allocations,
    RelationshipReview? expectedReview,
  }) => CommandGate.runFor(repository, () async {
    if (occurrenceIds.length != allocations.length || occurrenceIds.isEmpty) {
      throw const ValidationError('Occurrences and allocations must align');
    }
    final matchId = StableId.generate(timestamp: createdAt);
    final items = <MatchAllocation>[];
    for (var index = 0; index < occurrenceIds.length; index++) {
      items.add(
        MatchAllocation(
          id: StableId.generate(timestamp: createdAt),
          matchId: matchId,
          occurrenceId: occurrenceIds[index],
          amount: allocations[index],
        ),
      );
    }
    final result = TransactionMatch(
      id: matchId,
      transactionId: transactionId,
      transactionAmount: transactionAmount,
      createdAt: createdAt.toUtc(),
      allocations: items,
    );
    if (expectedReview != null) {
      final reviews = repository;
      if (reviews is! RelationshipReviewRepository) {
        throw const ValidationError('Relationship review is unsupported');
      }
      await (reviews as RelationshipReviewRepository).saveReviewedMatch(
        result,
        expectedReview,
      );
    } else {
      await repository.save(result);
    }
    return result;
  });

  Future<void> reject(TransactionMatch match) =>
      CommandGate.runFor(repository, () async {
        await repository.save(
          TransactionMatch(
            id: match.id,
            transactionId: match.transactionId,
            transactionAmount: match.transactionAmount,
            createdAt: match.createdAt,
            allocations: match.allocations,
            status: MatchStatus.reversed,
          ),
        );
      });

  Future<void> unmatch(TransactionMatch match) => reject(match);

  Future<TransactionMatch> correct({
    required TransactionMatch original,
    required DateTime createdAt,
    required List<StableId> occurrenceIds,
    required List<Money> allocations,
  }) => CommandGate.runFor(repository, () async {
    if (repository case AtomicMatchCorrection atomic) {
      // Validate and build without persisting an active replacement first.
      if (occurrenceIds.length != allocations.length || occurrenceIds.isEmpty) {
        throw const ValidationError('Occurrences and allocations must align');
      }
      final matchId = StableId.generate(timestamp: createdAt);
      final corrected = TransactionMatch(
        id: matchId,
        transactionId: original.transactionId,
        transactionAmount: original.transactionAmount,
        createdAt: createdAt.toUtc(),
        allocations: [
          for (var index = 0; index < occurrenceIds.length; index++)
            MatchAllocation(
              id: StableId.generate(timestamp: createdAt),
              matchId: matchId,
              occurrenceId: occurrenceIds[index],
              amount: allocations[index],
            ),
        ],
      );
      final superseded = TransactionMatch(
        id: original.id,
        transactionId: original.transactionId,
        transactionAmount: original.transactionAmount,
        createdAt: original.createdAt,
        allocations: original.allocations,
        status: MatchStatus.corrected,
        correctedMatchId: corrected.id,
      );
      await atomic.saveCorrection(original: superseded, corrected: corrected);
      return corrected;
    }
    final corrected = await match(
      transactionId: original.transactionId,
      transactionAmount: original.transactionAmount,
      createdAt: createdAt,
      occurrenceIds: occurrenceIds,
      allocations: allocations,
    );
    await repository.save(
      TransactionMatch(
        id: original.id,
        transactionId: original.transactionId,
        transactionAmount: original.transactionAmount,
        createdAt: original.createdAt,
        allocations: original.allocations,
        status: MatchStatus.corrected,
        correctedMatchId: corrected.id,
      ),
    );
    return corrected;
  });

  Future<List<FinancialPlannedVsActual>> plannedVsActual({
    required Map<StableId, Money> planned,
  }) => CommandGate.runFor(repository, () async {
    final totals = <StableId, int>{};
    final currencies = <StableId, String>{};
    for (final match in await repository.list()) {
      if (match.status != MatchStatus.active) continue;
      for (final allocation in match.allocations) {
        totals[allocation.occurrenceId] =
            (totals[allocation.occurrenceId] ?? 0) +
            allocation.amount.minorUnits;
        currencies[allocation.occurrenceId] = allocation.amount.currency;
      }
    }
    return planned.entries
        .map((item) {
          final currency = item.value.currency;
          final actual = Money(
            minorUnits: totals[item.key] ?? 0,
            currency: currencies[item.key] ?? currency,
          );
          return FinancialPlannedVsActual(
            occurrenceId: item.key,
            plannedAmount: item.value,
            matchedAmount: actual,
            explanation: actual.minorUnits == 0
                ? 'برای این تعهد پرداختی تطبیق داده نشده است.'
                : actual.minorUnits == item.value.minorUnits
                ? 'پرداخت کامل تطبیق داده شده است.'
                : 'پرداخت به‌صورت جزئی تطبیق داده شده است.',
          );
        })
        .toList(growable: false);
  });
}
