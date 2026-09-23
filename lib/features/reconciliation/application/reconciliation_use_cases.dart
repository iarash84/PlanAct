import 'package:planact/core/errors/app_error.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/reconciliation/domain/reconciliation.dart';

abstract interface class ReconciliationRepository {
  Future<List<TransactionMatch>> list();
  Future<void> save(TransactionMatch match);
}

class InMemoryReconciliationRepository implements ReconciliationRepository {
  final Map<StableId, TransactionMatch> _matches = {};

  @override
  Future<List<TransactionMatch>> list() async =>
      List.unmodifiable(_matches.values);

  @override
  Future<void> save(TransactionMatch match) async => _matches[match.id] = match;
}

class ReconciliationUseCases {
  ReconciliationUseCases(this.repository);
  final ReconciliationRepository repository;

  Future<TransactionMatch> match({
    required StableId transactionId,
    required Money transactionAmount,
    required DateTime createdAt,
    required List<StableId> occurrenceIds,
    required List<Money> allocations,
  }) async {
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
    await repository.save(result);
    return result;
  }

  Future<TransactionMatch> correct({
    required TransactionMatch original,
    required DateTime createdAt,
    required List<StableId> occurrenceIds,
    required List<Money> allocations,
  }) async {
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
  }

  Future<List<FinancialPlannedVsActual>> plannedVsActual({
    required Map<StableId, Money> planned,
  }) async {
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
  }
}
