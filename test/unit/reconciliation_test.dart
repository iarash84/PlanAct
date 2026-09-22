import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/errors/app_error.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/reconciliation/application/reconciliation_use_cases.dart';
import 'package:planact/features/reconciliation/domain/reconciliation.dart';

void main() {
  final transactionId = StableId.generate(timestamp: DateTime.utc(2026, 2, 1));
  final occurrenceA = StableId.generate(timestamp: DateTime.utc(2026, 2, 2));
  final occurrenceB = StableId.generate(timestamp: DateTime.utc(2026, 2, 3));

  test(
    'supports partial many-to-many allocation and remaining amount',
    () async {
      final repository = InMemoryReconciliationRepository();
      final useCases = ReconciliationUseCases(repository);
      final match = await useCases.match(
        transactionId: transactionId,
        transactionAmount: const Money(minorUnits: 1000, currency: 'IRR'),
        createdAt: DateTime.utc(2026, 2, 4),
        occurrenceIds: [occurrenceA, occurrenceB],
        allocations: const [
          Money(minorUnits: 400, currency: 'IRR'),
          Money(minorUnits: 300, currency: 'IRR'),
        ],
      );

      expect(match.isPartial, isTrue);
      expect(match.remaining, const Money(minorUnits: 300, currency: 'IRR'));
      expect(match.allocations, hasLength(2));
    },
  );

  test('supports full matching and rejects over-allocation', () async {
    final repository = InMemoryReconciliationRepository();
    final useCases = ReconciliationUseCases(repository);
    final full = await useCases.match(
      transactionId: transactionId,
      transactionAmount: const Money(minorUnits: 700, currency: 'IRR'),
      createdAt: DateTime.utc(2026, 2, 5),
      occurrenceIds: [occurrenceA, occurrenceB],
      allocations: const [
        Money(minorUnits: 400, currency: 'IRR'),
        Money(minorUnits: 300, currency: 'IRR'),
      ],
    );
    expect(full.isFull, isTrue);

    expect(
      () => useCases.match(
        transactionId: transactionId,
        transactionAmount: const Money(minorUnits: 500, currency: 'IRR'),
        createdAt: DateTime.utc(2026, 2, 6),
        occurrenceIds: [occurrenceA, occurrenceB],
        allocations: const [
          Money(minorUnits: 400, currency: 'IRR'),
          Money(minorUnits: 300, currency: 'IRR'),
        ],
      ),
      throwsA(isA<ValidationError>()),
    );
  });

  test('corrects a match without deleting original history', () async {
    final repository = InMemoryReconciliationRepository();
    final useCases = ReconciliationUseCases(repository);
    final original = await useCases.match(
      transactionId: transactionId,
      transactionAmount: const Money(minorUnits: 500, currency: 'IRR'),
      createdAt: DateTime.utc(2026, 2, 7),
      occurrenceIds: [occurrenceA],
      allocations: const [Money(minorUnits: 500, currency: 'IRR')],
    );
    final corrected = await useCases.correct(
      original: original,
      createdAt: DateTime.utc(2026, 2, 8),
      occurrenceIds: [occurrenceB],
      allocations: const [Money(minorUnits: 500, currency: 'IRR')],
    );

    expect(corrected.allocations.single.occurrenceId, occurrenceB);
    expect(await repository.list(), hasLength(2));
    expect(
      (await repository.list()).firstWhere((m) => m.id == original.id).status,
      MatchStatus.corrected,
    );
  });

  test('reports planned versus actual as partial and settled', () async {
    final repository = InMemoryReconciliationRepository();
    final useCases = ReconciliationUseCases(repository);
    await useCases.match(
      transactionId: transactionId,
      transactionAmount: const Money(minorUnits: 700, currency: 'IRR'),
      createdAt: DateTime.utc(2026, 2, 9),
      occurrenceIds: [occurrenceA, occurrenceB],
      allocations: const [
        Money(minorUnits: 400, currency: 'IRR'),
        Money(minorUnits: 200, currency: 'IRR'),
      ],
    );
    final projection = await useCases.plannedVsActual(
      planned: {
        occurrenceA: const Money(minorUnits: 400, currency: 'IRR'),
        occurrenceB: const Money(minorUnits: 300, currency: 'IRR'),
      },
    );

    expect(projection.first.settled, isTrue);
    expect(projection.last.explanation, contains('جزئی'));
  });
}
