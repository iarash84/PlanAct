import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/automation/domain/automation.dart';

void main() {
  AutomationTransaction tx(int day, int amount, String merchant) =>
      AutomationTransaction(
        amount: Money(minorUnits: amount, currency: 'IRR'),
        occurredAt: DateTime.utc(2026, 1, day),
        merchant: merchant,
      );

  test('normalizes merchant variants deterministically', () {
    const normalizer = MerchantNormalizer();
    expect(normalizer.normalize('  فروشگاه   نمونه  '), 'نمونه');
    expect(normalizer.normalize('ACME, Inc.'), 'acme');
  });

  test('detects recurring payments and explains the result', () {
    final pattern = const RecurringPatternDetector().detect([
      tx(1, 100000, 'ACME, Inc.'),
      tx(31, 102000, ' acme '),
      tx(60, 98000, 'ACME'),
    ]);

    expect(pattern, hasLength(1));
    expect(pattern.single.normalizedMerchant, 'acme');
    expect(pattern.single.intervalDays, 29);
    expect(pattern.single.averageAmount.minorUnits, 100000);
    expect(pattern.single.explanation, contains('3'));
  });

  test('does not classify irregular payments as recurring', () {
    final patterns = const RecurringPatternDetector().detect([
      tx(1, 100000, 'فروشگاه'),
      tx(2, 100000, 'فروشگاه'),
      tx(60, 300000, 'فروشگاه'),
    ]);
    expect(patterns, isEmpty);
  });

  test('smart match score is explainable and high only for strong match', () {
    final scorer = const SmartMatchScorer();
    final result = scorer.score(
      id: 'candidate-1',
      transaction: tx(10, 100000, 'ACME'),
      candidate: tx(12, 100000, 'Acme Inc'),
    );

    expect(result.score, 100);
    expect(result.confidence, AutomationConfidence.high);
    expect(result.reasons, hasLength(4));
  });

  test('categorization is a suggestion and requires explicit confirmation', () {
    final suggestion = const CategorizationSuggester().suggest(
      transaction: tx(10, 100000, 'ACME'),
      merchantCategories: const {'acme': 'اشتراک'},
    );

    expect(suggestion?.category, 'اشتراک');
    expect(suggestion?.confidence, AutomationConfidence.high);
    expect(suggestion?.explanation, contains('تأیید'));
  });

  test(
    'unknown merchant produces no categorization mutation or suggestion',
    () {
      final suggestion = const CategorizationSuggester().suggest(
        transaction: tx(10, 100000, 'Unknown'),
        merchantCategories: const {'acme': 'اشتراک'},
      );
      expect(suggestion, isNull);
    },
  );
}
