import 'package:planact/core/money/money.dart';
import 'package:planact/features/automation/domain/automation.dart';

enum PredictiveConfidence { low, medium, high }

enum RiskLevel { low, medium, high }

enum AnomalyKind { amountDeviation, unexpectedTransaction }

class ForecastItem {
  const ForecastItem({
    required this.expectedAt,
    required this.amount,
    required this.source,
    required this.confidence,
    required this.explanation,
  });

  final DateTime expectedAt;
  final Money amount;
  final String source;
  final PredictiveConfidence confidence;
  final String explanation;
}

class Forecast {
  const Forecast({
    required this.from,
    required this.to,
    required this.items,
    required this.totalsByCurrency,
  });

  final DateTime from;
  final DateTime to;
  final List<ForecastItem> items;
  final Map<String, Money> totalsByCurrency;
}

class RiskSignal {
  const RiskSignal({
    required this.subjectId,
    required this.level,
    required this.score,
    required this.reasons,
  });

  final String subjectId;
  final RiskLevel level;
  final int score;
  final List<String> reasons;
}

class RiskInput {
  const RiskInput({
    required this.subjectId,
    this.overdueOccurrences = 0,
    this.dueWithinDays,
    this.recentMissedOccurrences = 0,
    this.insufficientFunds = false,
  });

  final String subjectId;
  final int overdueOccurrences;
  final int? dueWithinDays;
  final int recentMissedOccurrences;
  final bool insufficientFunds;
}

class Anomaly {
  const Anomaly({
    required this.transaction,
    required this.kind,
    required this.score,
    required this.explanation,
  });

  final AutomationTransaction transaction;
  final AnomalyKind kind;
  final int score;
  final String explanation;
}

abstract interface class ForecastEngine {
  Forecast forecast({
    required Iterable<RecurringPattern> patterns,
    required DateTime from,
    required DateTime to,
  });
}

abstract interface class RiskEngine {
  List<RiskSignal> assess(Iterable<RiskInput> inputs);
}

abstract interface class AnomalyEngine {
  List<Anomaly> detect(Iterable<AutomationTransaction> transactions);
}

class DeterministicForecastEngine implements ForecastEngine {
  const DeterministicForecastEngine();

  @override
  Forecast forecast({
    required Iterable<RecurringPattern> patterns,
    required DateTime from,
    required DateTime to,
  }) {
    if (to.isBefore(from)) {
      throw ArgumentError.value(to, 'to', 'نباید پیش از ابتدای بازه باشد.');
    }
    final items = <ForecastItem>[];
    for (final pattern in patterns) {
      if (pattern.intervalDays <= 0) continue;
      var expectedAt = pattern.nextExpectedAt;
      while (expectedAt.isBefore(from)) {
        expectedAt = expectedAt.add(Duration(days: pattern.intervalDays));
      }
      while (!expectedAt.isAfter(to)) {
        items.add(
          ForecastItem(
            expectedAt: expectedAt,
            amount: pattern.averageAmount,
            source: pattern.normalizedMerchant,
            confidence: pattern.occurrences.length >= 5
                ? PredictiveConfidence.high
                : PredictiveConfidence.medium,
            explanation:
                'برآورد قطعی‌پذیر بر پایه ${pattern.occurrences.length} پرداخت دوره‌ای با فاصله ${pattern.intervalDays} روز است.',
          ),
        );
        expectedAt = expectedAt.add(Duration(days: pattern.intervalDays));
      }
    }
    items.sort((a, b) => a.expectedAt.compareTo(b.expectedAt));
    final totals = <String, Money>{};
    for (final item in items) {
      final currency = item.amount.currency;
      totals[currency] = Money(
        minorUnits:
            (totals[currency]?.minorUnits ?? 0) + item.amount.minorUnits,
        currency: currency,
      );
    }
    return Forecast(
      from: from,
      to: to,
      items: List.unmodifiable(items),
      totalsByCurrency: Map.unmodifiable(totals),
    );
  }
}

class DeterministicRiskEngine implements RiskEngine {
  const DeterministicRiskEngine();

  @override
  List<RiskSignal> assess(Iterable<RiskInput> inputs) {
    final signals = <RiskSignal>[];
    for (final input in inputs) {
      var score = 0;
      final reasons = <String>[];
      if (input.overdueOccurrences > 0) {
        score += (input.overdueOccurrences * 30).clamp(0, 60);
        reasons.add('${input.overdueOccurrences} مورد عقب‌افتاده وجود دارد');
      }
      if (input.recentMissedOccurrences > 0) {
        score += (input.recentMissedOccurrences * 15).clamp(0, 30);
        reasons.add(
          '${input.recentMissedOccurrences} مورد اخیر انجام نشده است',
        );
      }
      if (input.dueWithinDays != null &&
          input.dueWithinDays! >= 0 &&
          input.dueWithinDays! <= 3) {
        score += 15;
        reasons.add('سررسید تا سه روز آینده است');
      }
      if (input.insufficientFunds) {
        score += 35;
        reasons.add('موجودی قابل تخصیص کافی نیست');
      }
      score = score.clamp(0, 100);
      signals.add(
        RiskSignal(
          subjectId: input.subjectId,
          level: score >= 70
              ? RiskLevel.high
              : score >= 35
              ? RiskLevel.medium
              : RiskLevel.low,
          score: score,
          reasons: List.unmodifiable(reasons),
        ),
      );
    }
    signals.sort((a, b) {
      final scoreOrder = b.score.compareTo(a.score);
      return scoreOrder != 0 ? scoreOrder : a.subjectId.compareTo(b.subjectId);
    });
    return List.unmodifiable(signals);
  }
}

class DeterministicAnomalyEngine implements AnomalyEngine {
  const DeterministicAnomalyEngine({
    this.normalizer = const MerchantNormalizer(),
    this.minimumHistory = 3,
    this.deviationPercent = 50,
  });

  final MerchantNormalizer normalizer;
  final int minimumHistory;
  final int deviationPercent;

  @override
  List<Anomaly> detect(Iterable<AutomationTransaction> transactions) {
    final ordered = [...transactions]
      ..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
    final history = <String, List<int>>{};
    final anomalies = <Anomaly>[];
    for (final transaction in ordered) {
      final merchant = normalizer.normalize(transaction.merchant);
      final key = '${transaction.amount.currency}|$merchant';
      final amounts = history.putIfAbsent(key, () => <int>[]);
      if (merchant.isNotEmpty && amounts.length >= minimumHistory) {
        final sorted = [...amounts]..sort();
        final baseline = sorted[sorted.length ~/ 2];
        final difference = (transaction.amount.minorUnits - baseline).abs();
        if (baseline > 0 && difference * 100 >= baseline * deviationPercent) {
          final score = ((difference * 100) ~/ baseline).clamp(0, 100);
          anomalies.add(
            Anomaly(
              transaction: transaction,
              kind: AnomalyKind.amountDeviation,
              score: score,
              explanation: 'مبلغ با میانه پرداخت‌های قبلی همین پذیرنده تفاوت معنادار دارد؛ فقط نیازمند بررسی کاربر است.',
            ),
          );
        }
      }
      amounts.add(transaction.amount.minorUnits.abs());
    }
    return List.unmodifiable(anomalies);
  }
}
