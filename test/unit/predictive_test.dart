import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/automation/application/local_ai.dart';
import 'package:planact/features/automation/domain/automation.dart';
import 'package:planact/features/automation/domain/predictive.dart';

void main() {
  AutomationTransaction tx(int day, int amount, String merchant) =>
      AutomationTransaction(
        amount: Money(minorUnits: amount, currency: 'IRR'),
        occurredAt: DateTime.utc(2026, 1, day),
        merchant: merchant,
      );

  RecurringPattern pattern() {
    final items = [
      tx(1, 100000, 'ACME'),
      tx(31, 100000, 'ACME'),
      tx(60, 100000, 'ACME'),
    ];
    return RecurringPattern(
      normalizedMerchant: 'acme',
      occurrences: items,
      averageAmount: items.first.amount,
      intervalDays: 29,
      nextExpectedAt: DateTime.utc(2026, 3, 1),
      explanation: 'test',
    );
  }

  test('deterministic forecast is bounded, sorted, and totals by currency', () {
    final result = const DeterministicForecastEngine().forecast(
      patterns: [pattern()],
      from: DateTime.utc(2026, 3, 1),
      to: DateTime.utc(2026, 4, 1),
    );
    expect(result.items, hasLength(2));
    expect(result.items.first.expectedAt, DateTime.utc(2026, 3, 1));
    expect(result.totalsByCurrency['IRR']?.minorUnits, 200000);
  });

  test('risk engine is explainable and deterministic', () {
    final result = const DeterministicRiskEngine().assess([
      const RiskInput(
        subjectId: 'bill',
        overdueOccurrences: 2,
        insufficientFunds: true,
      ),
      const RiskInput(subjectId: 'safe'),
    ]);
    expect(result.first.subjectId, 'bill');
    expect(result.first.level, RiskLevel.high);
    expect(result.first.reasons, isNotEmpty);
    expect(result.last.level, RiskLevel.low);
  });

  test('anomaly engine flags deviation without mutating transactions', () {
    final transactions = [
      tx(1, 100000, 'ACME'),
      tx(2, 100000, 'ACME'),
      tx(3, 100000, 'ACME'),
      tx(4, 250000, 'ACME'),
    ];
    final result = const DeterministicAnomalyEngine().detect(transactions);
    expect(result, hasLength(1));
    expect(result.single.kind, AnomalyKind.amountDeviation);
    expect(result.single.transaction.amount.minorUnits, 250000);
    expect(transactions.last.amount.minorUnits, 250000);
  });

  test(
    'AI disabled or unavailable falls back to deterministic result',
    () async {
      final result = await const PredictiveService().evaluate(
        recurringPatterns: [pattern()],
        riskInputs: const [RiskInput(subjectId: 'bill')],
        anomalyTransactions: const [],
        from: DateTime.utc(2026, 3, 1),
        to: DateTime.utc(2026, 3, 1),
        enableAi: true,
      );
      expect(result.provider, PredictiveProvider.deterministic);
      expect(result.aiInsight, isNull);
    },
  );

  test('accepted local AI insight is optional and evaluated', () async {
    final result = await PredictiveService(aiAdapter: _FakeAiAdapter())
        .evaluate(
          recurringPatterns: [pattern()],
          riskInputs: const [RiskInput(subjectId: 'bill')],
          anomalyTransactions: const [],
          from: DateTime.utc(2026, 3, 1),
          to: DateTime.utc(2026, 3, 1),
          enableAi: true,
        );
    expect(result.provider, PredictiveProvider.onDeviceAi);
    expect(result.aiInsight?.summary, 'خلاصه');
  });
}

class _FakeAiAdapter implements OnDeviceAiAdapter {
  @override
  LocalAiAvailability get availability => LocalAiAvailability.available;

  @override
  Future<LocalAiInsight> evaluate(LocalAiRequest request) async =>
      const LocalAiInsight(
        summary: 'خلاصه',
        confidence: PredictiveConfidence.high,
        explanation: 'توضیح',
      );
}
