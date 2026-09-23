import 'package:planact/core/money/money.dart';

/// A stable, deterministic representation of a merchant name.
class MerchantNormalizer {
  const MerchantNormalizer();

  String normalize(String? merchant) {
    if (merchant == null) return '';
    var value = merchant.trim().toLowerCase();
    value = value.replaceAll(RegExp(r'[\u200c\u200f\u202a-\u202e]'), ' ');
    value = value.replaceAll(RegExp(r'[ًٌٍَُِّْـ]'), '');
    value = value.replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ');
    value = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    const suffixes = <String>{'inc', 'llc', 'ltd', 'co', 'شرکت', 'فروشگاه'};
    final words = value.split(' ')
      ..removeWhere((word) => word.isEmpty || suffixes.contains(word));
    return words.join(' ');
  }
}

class AutomationTransaction {
  const AutomationTransaction({
    required this.amount,
    required this.occurredAt,
    this.merchant,
    this.category,
    this.description,
  });

  final Money amount;
  final DateTime occurredAt;
  final String? merchant;
  final String? category;
  final String? description;
}

class RecurringPattern {
  const RecurringPattern({
    required this.normalizedMerchant,
    required this.occurrences,
    required this.averageAmount,
    required this.intervalDays,
    required this.nextExpectedAt,
    required this.explanation,
  });

  final String normalizedMerchant;
  final List<AutomationTransaction> occurrences;
  final Money averageAmount;
  final int intervalDays;
  final DateTime nextExpectedAt;
  final String explanation;
}

class RecurringPatternDetector {
  const RecurringPatternDetector({
    this.normalizer = const MerchantNormalizer(),
  });

  final MerchantNormalizer normalizer;

  List<RecurringPattern> detect(
    Iterable<AutomationTransaction> transactions, {
    DateTime? asOf,
    int minimumOccurrences = 3,
    int maximumIntervalDays = 45,
    int amountTolerancePercent = 10,
  }) {
    final groups = <String, List<AutomationTransaction>>{};
    for (final transaction in transactions) {
      final merchant = normalizer.normalize(transaction.merchant);
      if (merchant.isNotEmpty) {
        groups.putIfAbsent(merchant, () => []).add(transaction);
      }
    }
    final results = <RecurringPattern>[];
    for (final entry in groups.entries) {
      final items = [...entry.value]
        ..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
      if (items.length < minimumOccurrences) continue;
      final average =
          items.fold<int>(0, (sum, item) => sum + item.amount.minorUnits) ~/
          items.length;
      if (items.any(
        (item) => item.amount.currency != items.first.amount.currency,
      )) {
        continue;
      }
      final intervals = <int>[];
      for (var i = 1; i < items.length; i++) {
        intervals.add(
          items[i].occurredAt.difference(items[i - 1].occurredAt).inDays,
        );
      }
      final interval = intervals.reduce((a, b) => a + b) ~/ intervals.length;
      final consistent =
          intervals.every((value) => (value - interval).abs() <= 3) &&
          items.every(
            (item) =>
                (item.amount.minorUnits - average).abs() * 100 <=
                average * amountTolerancePercent,
          ) &&
          interval > 0 &&
          interval <= maximumIntervalDays;
      if (!consistent) continue;
      final next = items.last.occurredAt.add(Duration(days: interval));
      results.add(
        RecurringPattern(
          normalizedMerchant: entry.key,
          occurrences: List.unmodifiable(items),
          averageAmount: Money(
            minorUnits: average,
            currency: items.first.amount.currency,
          ),
          intervalDays: interval,
          nextExpectedAt: next,
          explanation:
              'پرداخت‌های ${items.length}گانه با فاصله تقریبی $interval روز و مبلغ مشابه شناسایی شد.',
        ),
      );
    }
    results.sort((a, b) => a.nextExpectedAt.compareTo(b.nextExpectedAt));
    return List.unmodifiable(results);
  }
}

enum AutomationConfidence { low, medium, high }

class MatchCandidate {
  const MatchCandidate({
    required this.id,
    required this.score,
    required this.reasons,
  });
  final String id;
  final int score;
  final List<String> reasons;
  AutomationConfidence get confidence => score >= 80
      ? AutomationConfidence.high
      : score >= 55
      ? AutomationConfidence.medium
      : AutomationConfidence.low;
}

class SmartMatchScorer {
  const SmartMatchScorer({this.normalizer = const MerchantNormalizer()});
  final MerchantNormalizer normalizer;

  MatchCandidate score({
    required String id,
    required AutomationTransaction transaction,
    required AutomationTransaction candidate,
    int dateWindowDays = 7,
    int amountTolerancePercent = 5,
  }) {
    var score = 0;
    final reasons = <String>[];
    if (transaction.amount.currency == candidate.amount.currency) {
      score += 20;
      reasons.add('واحد پول یکسان است');
    }
    final difference =
        (transaction.amount.minorUnits - candidate.amount.minorUnits).abs();
    final tolerance =
        (transaction.amount.minorUnits.abs() * amountTolerancePercent) ~/ 100;
    if (difference <= tolerance) {
      score += 45;
      reasons.add('مبلغ در محدوده قابل قبول است');
    }
    if (normalizer.normalize(transaction.merchant) ==
            normalizer.normalize(candidate.merchant) &&
        normalizer.normalize(transaction.merchant).isNotEmpty) {
      score += 25;
      reasons.add('نام پذیرنده یکسان است');
    }
    if (transaction.occurredAt.difference(candidate.occurredAt).inDays.abs() <=
        dateWindowDays) {
      score += 10;
      reasons.add('تاریخ‌ها نزدیک هستند');
    }
    return MatchCandidate(
      id: id,
      score: score,
      reasons: List.unmodifiable(reasons),
    );
  }
}

class CategorySuggestion {
  const CategorySuggestion({
    required this.category,
    required this.confidence,
    required this.explanation,
  });
  final String category;
  final AutomationConfidence confidence;
  final String explanation;
}

class CategorizationSuggester {
  const CategorizationSuggester({this.normalizer = const MerchantNormalizer()});
  final MerchantNormalizer normalizer;

  CategorySuggestion? suggest({
    required AutomationTransaction transaction,
    required Map<String, String> merchantCategories,
  }) {
    final category =
        merchantCategories[normalizer.normalize(transaction.merchant)];
    if (category == null) return null;
    return CategorySuggestion(
      category: category,
      confidence: AutomationConfidence.high,
      explanation: 'دسته‌بندی بر اساس تطبیق دقیق نام پذیرنده پیشنهاد شد؛ تأیید کاربر لازم است.',
    );
  }
}
