import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/errors/app_error.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/reconciliation/application/reconciliation_use_cases.dart';
import 'package:planact/features/reconciliation/domain/reconciliation.dart';
import 'package:planact/features/reconciliation/domain/relationship_review.dart';

void main() {
  final transaction = AccountEntry(
    id: StableId.generate(),
    accountId: StableId.generate(),
    type: AccountEntryType.expense,
    amount: const Money(minorUnits: 1000, currency: 'IRR'),
    occurredAt: DateTime.utc(2026),
    category: 'آموزش',
  );
  final occurrence = StableId.generate();
  late InMemoryReconciliationRepository repository;
  setUp(() => repository = InMemoryReconciliationRepository());

  Future<TransactionMatch> match(int amount, {RelationshipReview? expected}) =>
      ReconciliationUseCases(repository).match(
        transactionId: transaction.id,
        transactionAmount: transaction.amount,
        createdAt: DateTime.utc(2026),
        occurrenceIds: [occurrence],
        allocations: [Money(minorUnits: amount, currency: 'IRR')],
        expectedReview: expected,
      );
  Future<RelationshipReview> decide(
    RelationshipReview expected,
    RelationshipReviewDecision decision,
  ) => repository.decideReview(
    expected: expected,
    decision: decision,
    recordedAt: DateTime.utc(2026),
  );

  test(
    'independent covers only unmatched remainder and reopening appends',
    () async {
      await repository.loadReview(transaction);
      await match(400);
      final initial = await repository.loadReview(transaction);
      final independent = await decide(
        initial,
        RelationshipReviewDecision.independent,
      );
      expect(independent.isIndependent, isTrue);
      expect(independent.latestDecision!.remainderMinorUnits, 600);
      await expectLater(match(100), throwsA(isA<ValidationError>()));
      await expectLater(
        decide(initial, RelationshipReviewDecision.independent),
        throwsA(isA<ValidationError>()),
      );
      final reopened = await decide(
        independent,
        RelationshipReviewDecision.reopened,
      );
      expect(reopened.revision, 2);
      expect(reopened.isIndependent, isFalse);
      await match(600, expected: reopened);
      final full = await repository.loadReview(transaction);
      await expectLater(
        decide(full, RelationshipReviewDecision.independent),
        throwsA(isA<ValidationError>()),
      );
      expect(await repository.reviewHistory(transaction), hasLength(2));
      expect(transaction.category, 'آموزش');
    },
  );

  test(
    'equal allocation totals with different identities invalidate tokens',
    () async {
      await repository.loadReview(transaction);
      final original = await match(400);
      final before = await repository.loadReview(transaction);
      await ReconciliationUseCases(repository).correct(
        original: original,
        createdAt: DateTime.utc(2026),
        occurrenceIds: [StableId.generate()],
        allocations: const [Money(minorUnits: 400, currency: 'IRR')],
      );
      final after = await repository.loadReview(transaction);
      expect(after.allocatedMinorUnits, before.allocatedMinorUnits);
      expect(
        () => after.requireExpected(before),
        throwsA(isA<ValidationError>()),
      );
    },
  );

  test(
    'resolved history cannot reactivate or resurrect independent decision',
    () async {
      await repository.loadReview(transaction);
      final original = await match(400);
      await decide(
        await repository.loadReview(transaction),
        RelationshipReviewDecision.independent,
      );
      await ReconciliationUseCases(repository).reject(original);
      expect((await repository.loadReview(transaction)).isIndependent, isFalse);
      await expectLater(
        repository.save(original),
        throwsA(isA<ValidationError>()),
      );
      expect(await repository.reviewHistory(transaction), hasLength(1));
    },
  );

  test('review and guarded match races admit exactly one operation', () async {
    final expected = await repository.loadReview(transaction);
    Future<bool> attempt(Future<Object?> operation) async {
      try {
        await operation;
        return true;
      } on ValidationError {
        return false;
      }
    }

    final outcomes = await Future.wait([
      attempt(decide(expected, RelationshipReviewDecision.independent)),
      attempt(match(400, expected: expected)),
    ]);
    expect(outcomes.where((value) => value), hasLength(1));
  });

  test('match retains an immutable allocation copy', () async {
    final saved = await match(400);
    expect(() => saved.allocations.clear(), throwsUnsupportedError);
    expect(saved.allocatedMinorUnits, 400);
  });
}
