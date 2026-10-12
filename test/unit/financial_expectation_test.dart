import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/finance/application/financial_expectation_use_cases.dart';
import 'package:planact/features/finance/domain/financial_expectation.dart';
import 'package:planact/features/reconciliation/domain/reconciliation.dart';

void main() {
  final occurrence = StableId.generate();

  test(
    'supports outgoing and incoming expectations with optional fields',
    () async {
      final repository = InMemoryFinancialExpectationRepository();
      final useCases = FinancialExpectationUseCases(repository);
      final outgoing = await useCases.create(
        occurrenceId: occurrence,
        direction: FinancialExpectationDirection.outgoing,
        amount: 1250,
      );
      expect(outgoing.direction, FinancialExpectationDirection.outgoing);
      expect(outgoing.accountId, isNull);
      expect(await useCases.getByOccurrence(occurrence), outgoing);

      final currencyless = await useCases.create(
        occurrenceId: StableId.generate(),
        direction: FinancialExpectationDirection.incoming,
        amount: 1,
      );
      expect(currencyless.currency, isNull);
    },
  );

  test('rejects zero and negative amounts', () async {
    final useCases = FinancialExpectationUseCases(
      InMemoryFinancialExpectationRepository(),
    );
    expect(
      () => useCases.create(
        occurrenceId: occurrence,
        direction: FinancialExpectationDirection.incoming,
        amount: 0,
      ),
      throwsA(isA<Exception>()),
    );
  });

  test('settlement follows active allocations, not activity status', () async {
    final repository = InMemoryFinancialExpectationRepository();
    final matchId = StableId.generate();
    final match = TransactionMatch(
      id: matchId,
      transactionId: StableId.generate(),
      transactionAmount: const Money(minorUnits: 1000, currency: 'تومان'),
      createdAt: DateTime.utc(2026),
      allocations: [
        MatchAllocation(
          id: StableId.generate(),
          matchId: matchId,
          occurrenceId: occurrence,
          amount: const Money(minorUnits: 1000, currency: 'تومان'),
        ),
      ],
    );
    final expectation = await FinancialExpectationUseCases(repository).create(
      occurrenceId: occurrence,
      direction: FinancialExpectationDirection.incoming,
      amount: 1000,
      currency: 'تومان',
    );
    repository.matches = [match];
    final useCases = FinancialExpectationUseCases(repository);
    expect((await useCases.settled()).single.expectation.id, expectation.id);
    expect((await useCases.outstanding()), isEmpty);

    repository.matches = [];
    expect(await useCases.settled(), isEmpty);
    expect(
      (await useCases.outstanding()).single.allocatedAmount,
      const Money(minorUnits: 0, currency: 'تومان'),
    );
  });

  test(
    'allocation totals isolate currencies, occurrences and match status',
    () async {
      final repository = InMemoryFinancialExpectationRepository();
      final useCases = FinancialExpectationUseCases(repository);
      final otherOccurrence = StableId.generate();
      final rial = await useCases.create(
        occurrenceId: occurrence,
        direction: FinancialExpectationDirection.incoming,
        amount: 1000,
        currency: 'IRR',
      );
      final dollar = await useCases.create(
        occurrenceId: occurrence,
        direction: FinancialExpectationDirection.incoming,
        amount: 1000,
        currency: 'USD',
      );
      final unknown = await useCases.create(
        occurrenceId: otherOccurrence,
        direction: FinancialExpectationDirection.outgoing,
        amount: 1000,
      );

      TransactionMatch match(
        StableId target,
        int amount,
        String currency, {
        MatchStatus status = MatchStatus.active,
      }) {
        final id = StableId.generate();
        return TransactionMatch(
          id: id,
          transactionId: StableId.generate(),
          transactionAmount: Money(minorUnits: amount, currency: currency),
          createdAt: DateTime.utc(2026),
          status: status,
          allocations: [
            MatchAllocation(
              id: StableId.generate(),
              matchId: id,
              occurrenceId: target,
              amount: Money(minorUnits: amount, currency: currency),
            ),
          ],
        );
      }

      repository.matches = [
        match(occurrence, 400, 'IRR'),
        match(occurrence, 600, 'IRR'),
        match(occurrence, 250, 'USD'),
        match(otherOccurrence, 900, 'IRR'),
        match(occurrence, 700, 'USD', status: MatchStatus.reversed),
        match(occurrence, 800, 'USD', status: MatchStatus.corrected),
      ];
      expect((await useCases.settled()).single.expectation.id, rial.id);
      final outstanding = await useCases.outstanding();
      expect(outstanding.map((item) => item.expectation.id), [
        dollar.id,
        unknown.id,
      ]);
      expect(
        outstanding.first.allocatedAmount,
        const Money(minorUnits: 250, currency: 'USD'),
      );
      expect(outstanding.last.allocatedAmount, isNull);
      await useCases.archive(rial);
      expect(await useCases.settled(), isEmpty);
      expect(await repository.listExpectations(), hasLength(3));
    },
  );

  test(
    'archive preserves the record but removes it from active queries',
    () async {
      final repository = InMemoryFinancialExpectationRepository();
      final useCases = FinancialExpectationUseCases(repository);
      final item = await useCases.create(
        occurrenceId: StableId.generate(),
        direction: FinancialExpectationDirection.outgoing,
        amount: 50,
      );
      await useCases.archive(item);
      expect(await repository.listExpectations(), hasLength(1));
      expect(await useCases.outstanding(), isEmpty);
    },
  );
}
