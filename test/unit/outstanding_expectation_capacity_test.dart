import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/errors/app_error.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/finance/domain/financial_expectation.dart';
import 'package:planact/features/reconciliation/application/reconciliation_use_cases.dart';
import 'package:planact/features/reconciliation/domain/reconciliation.dart';

void main() {
  final occurrence = StableId.generate();
  final transaction = AccountEntry(
    id: StableId.generate(),
    accountId: StableId.generate(),
    type: AccountEntryType.expense,
    amount: const Money(minorUnits: 1200000, currency: 'IRR'),
    occurredAt: DateTime.utc(2026),
  );
  FinancialExpectation expectation({
    int amount = 1000000,
    String? currency = 'IRR',
    FinancialExpectationStatus status = FinancialExpectationStatus.active,
  }) => FinancialExpectation(
    id: StableId.generate(),
    occurrenceId: occurrence,
    direction: FinancialExpectationDirection.outgoing,
    amount: amount,
    currency: currency,
    accountId: transaction.accountId,
    status: status,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );

  TransactionMatch match(
    int amount, {
    StableId? transactionId,
    MatchStatus status = MatchStatus.active,
    String currency = 'IRR',
  }) {
    final id = StableId.generate();
    return TransactionMatch(
      id: id,
      transactionId: transactionId ?? transaction.id,
      transactionAmount: Money(minorUnits: 1200000, currency: currency),
      createdAt: DateTime.utc(2026),
      status: status,
      allocations: [
        MatchAllocation(
          id: StableId.generate(),
          matchId: id,
          occurrenceId: occurrence,
          amount: Money(minorUnits: amount, currency: currency),
        ),
      ],
    );
  }

  test('approved transaction excess is not expectation capacity', () {
    final capacity = OutstandingExpectationCapacity(
      expectations: [expectation()],
      matches: const [],
    );
    expect(capacity.remaining(occurrence, 'IRR'), 1000000);
    capacity.requireAllocations(match(1000000).allocations);
    expect(
      () => capacity.requireAllocations(match(1000001).allocations),
      throwsA(isA<ValidationError>()),
    );
    expect(
      transaction.amount.minorUnits - capacity.remaining(occurrence, 'IRR'),
      200000,
    );
  });

  test(
    'partial allocations aggregate across transactions and repeated targets',
    () {
      final capacity = OutstandingExpectationCapacity(
        expectations: [expectation()],
        matches: [
          match(300000),
          match(400000, transactionId: StableId.generate()),
        ],
      );
      expect(capacity.remaining(occurrence, 'IRR'), 300000);
      expect(
        () => capacity.requireAllocations([
          ...match(200000).allocations,
          ...match(100001).allocations,
        ]),
        throwsA(isA<ValidationError>()),
      );
    },
  );

  test('correction excludes exactly the replaced match; resolved and reversed do not settle', () {
    final original = match(600000);
    final reversedTransaction = StableId.generate();
    final capacity = OutstandingExpectationCapacity(
      expectations: [expectation()],
      matches: [
        original,
        match(100000),
        match(900000, status: MatchStatus.corrected),
        match(900000, status: MatchStatus.reversed),
        match(900000, transactionId: reversedTransaction),
        match(900000, currency: 'USD'),
      ],
      reversedTransactionIds: {reversedTransaction},
      excludingMatchId: original.id,
    );
    expect(capacity.remaining(occurrence, 'IRR'), 900000);
    capacity.requireAllocations(match(900000).allocations);
  });

  test('historical excess clamps capacity without becoming credit or changing history', () {
    final historical = match(1100000);
    final capacity = OutstandingExpectationCapacity(
      expectations: [expectation()],
      matches: [historical],
    );
    expect(capacity.remaining(occurrence, 'IRR'), 0);
    expect(
      () => capacity.requireAllocations(match(1).allocations),
      throwsA(isA<ValidationError>()),
    );
    expect(historical.allocatedMinorUnits, 1100000);
    expect(historical.status, MatchStatus.active);
  });

  test('missing, unknown currency, archived and ambiguous expectations fail closed', () {
    for (final expectations in <List<FinancialExpectation>>[
      [],
      [expectation(currency: null)],
      [expectation(currency: 'USD')],
      [expectation(status: FinancialExpectationStatus.archived)],
      [expectation(), expectation()],
    ]) {
      expect(
        OutstandingExpectationCapacity(
          expectations: expectations,
          matches: const [],
        ).remaining(occurrence, 'IRR'),
        0,
      );
    }
  });

  test('application candidate preview caps available amount and omits settled targets', () {
    const engine = ReconciliationEngine(
      scorer: ReconciliationScorer(toleranceMinorUnits: 200000),
    );
    List<ReconciliationCandidate> preview(List<TransactionMatch> matches) =>
        engine.findCandidates(
          transaction: transaction,
          expectations: [expectation()],
          expectedDates: {occurrence: DateTime.utc(2026)},
          existingMatches: matches,
        );
    expect(preview([]).single.availableAmount.minorUnits, 1000000);
    expect(
      preview([match(700000, transactionId: StableId.generate())])
          .single
          .availableAmount
          .minorUnits,
      300000,
    );
    expect(
      preview([match(1000000, transactionId: StableId.generate())]),
      isEmpty,
    );
  });
}
