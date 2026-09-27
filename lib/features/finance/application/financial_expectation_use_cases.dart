import 'package:planact/core/errors/app_error.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/finance/domain/financial_expectation.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/reconciliation/domain/reconciliation.dart';

abstract interface class FinancialExpectationRepository {
  Future<List<FinancialExpectation>> listExpectations();
  Future<void> saveExpectation(FinancialExpectation expectation);
  Future<List<TransactionMatch>> listMatches();
  Future<List<FinancialAccount>> listAccounts();
}

class InMemoryFinancialExpectationRepository
    implements FinancialExpectationRepository {
  final Map<StableId, FinancialExpectation> _items = {};
  List<TransactionMatch> matches = const [];
  List<FinancialAccount> accounts = const [];

  @override
  Future<List<FinancialExpectation>> listExpectations() async =>
      List.unmodifiable(_items.values);

  @override
  Future<void> saveExpectation(FinancialExpectation expectation) async {
    _items[expectation.id] = expectation;
  }

  @override
  Future<List<TransactionMatch>> listMatches() async =>
      List.unmodifiable(matches);

  @override
  Future<List<FinancialAccount>> listAccounts() async =>
      List.unmodifiable(accounts);
}

class FinancialExpectationUseCases {
  FinancialExpectationUseCases(
    this.repository, {
    @Deprecated('Use a repository-backed reconciliation source')
    List<TransactionMatch>? matches,
  }) : _legacyMatches = matches;

  final FinancialExpectationRepository repository;
  final List<TransactionMatch>? _legacyMatches;

  Future<FinancialExpectation> create({
    required StableId occurrenceId,
    required FinancialExpectationDirection direction,
    required int amount,
    String? currency,
    StableId? accountId,
    DateTime? now,
  }) async {
    _validate(amount, currency);
    final timestamp = (now ?? DateTime.now()).toUtc();
    final item = FinancialExpectation(
      id: StableId.generate(timestamp: timestamp),
      occurrenceId: occurrenceId,
      direction: direction,
      amount: amount,
      currency: currency?.trim().isEmpty == true ? null : currency?.trim(),
      accountId: accountId,
      createdAt: timestamp,
      updatedAt: timestamp,
    );
    await repository.saveExpectation(item);
    return item;
  }

  Future<FinancialExpectation> update(
    FinancialExpectation expectation, {
    required int amount,
    String? currency,
    FinancialExpectationDirection? direction,
    StableId? accountId,
    DateTime? now,
  }) async {
    _validate(amount, currency);
    final item = FinancialExpectation(
      id: expectation.id,
      occurrenceId: expectation.occurrenceId,
      direction: direction ?? expectation.direction,
      amount: amount,
      currency: currency?.trim().isEmpty == true ? null : currency?.trim(),
      accountId: accountId,
      status: expectation.status,
      createdAt: expectation.createdAt,
      updatedAt: (now ?? DateTime.now()).toUtc(),
    );
    await repository.saveExpectation(item);
    return item;
  }

  Future<FinancialExpectation?> getByOccurrence(StableId occurrenceId) async {
    final items = await repository.listExpectations();
    for (final item in items) {
      if (item.occurrenceId == occurrenceId &&
          item.status == FinancialExpectationStatus.active) {
        return item;
      }
    }
    return null;
  }

  Future<List<FinancialExpectationSettlement>> outstanding() async =>
      (await _settlements())
          .where((item) => !item.settled)
          .toList(growable: false);

  Future<List<FinancialExpectationSettlement>> settled() async =>
      (await _settlements())
          .where((item) => item.settled)
          .toList(growable: false);

  Future<FinancialExpectation> archive(
    FinancialExpectation item, {
    DateTime? now,
  }) async {
    final archived = item.archive(now ?? DateTime.now());
    await repository.saveExpectation(archived);
    return archived;
  }

  Future<List<FinancialExpectationSettlement>> _settlements() async {
    final active = (await repository.listExpectations()).where(
      (item) => item.status == FinancialExpectationStatus.active,
    );
    final matches = _legacyMatches ?? await repository.listMatches();
    return active
        .map((item) {
          var total = 0;
          for (final match in matches) {
            if (match.status != MatchStatus.active) continue;
            for (final allocation in match.allocations) {
              if (allocation.occurrenceId == item.occurrenceId &&
                  item.currency != null &&
                  allocation.amount.currency == item.currency) {
                total += allocation.amount.minorUnits;
              }
            }
          }
          return FinancialExpectationSettlement(
            expectation: item,
            allocatedAmount: item.currency == null
                ? null
                : Money(minorUnits: total, currency: item.currency!),
          );
        })
        .toList(growable: false);
  }

  void _validate(int amount, String? currency) {
    if (amount <= 0) {
      throw const ValidationError('Expectation amount must be positive');
    }
    if (currency != null && currency.trim().isEmpty) {
      throw const ValidationError('Expectation currency cannot be empty');
    }
  }
}
