import 'package:planact/features/automation/domain/automation.dart';
import 'package:planact/features/automation/domain/predictive.dart';

enum LocalAiAvailability { available, disabled, unavailable }

enum PredictiveProvider { deterministic, onDeviceAi }

class LocalAiRequest {
  const LocalAiRequest({
    required this.forecast,
    required this.risks,
    required this.anomalies,
  });

  final Forecast forecast;
  final List<RiskSignal> risks;
  final List<Anomaly> anomalies;
}

class LocalAiInsight {
  const LocalAiInsight({
    required this.summary,
    required this.confidence,
    required this.explanation,
  });

  final String summary;
  final PredictiveConfidence confidence;
  final String explanation;
}

abstract interface class OnDeviceAiAdapter {
  LocalAiAvailability get availability;

  Future<LocalAiInsight> evaluate(LocalAiRequest request);
}

class LocalAiEvaluationPolicy {
  const LocalAiEvaluationPolicy({
    this.minimumConfidence = PredictiveConfidence.medium,
  });

  final PredictiveConfidence minimumConfidence;

  bool accepts(LocalAiInsight insight) =>
      insight.summary.trim().isNotEmpty &&
      insight.explanation.trim().isNotEmpty &&
      insight.confidence.index >= minimumConfidence.index;
}

class PredictiveResult {
  const PredictiveResult({
    required this.forecast,
    required this.risks,
    required this.anomalies,
    required this.provider,
    required this.explanation,
    this.aiInsight,
  });

  final Forecast forecast;
  final List<RiskSignal> risks;
  final List<Anomaly> anomalies;
  final PredictiveProvider provider;
  final String explanation;
  final LocalAiInsight? aiInsight;
}

/// Coordinates optional local AI without making it a dependency of core flows.
///
/// Only derived signals are sent to the adapter. Raw notes, account identifiers,
/// transaction descriptions, and merchant text are deliberately excluded.
class PredictiveService {
  const PredictiveService({
    this.forecastEngine = const DeterministicForecastEngine(),
    this.riskEngine = const DeterministicRiskEngine(),
    this.anomalyEngine = const DeterministicAnomalyEngine(),
    this.aiAdapter,
    this.evaluationPolicy = const LocalAiEvaluationPolicy(),
  });

  final ForecastEngine forecastEngine;
  final RiskEngine riskEngine;
  final AnomalyEngine anomalyEngine;
  final OnDeviceAiAdapter? aiAdapter;
  final LocalAiEvaluationPolicy evaluationPolicy;

  Future<PredictiveResult> evaluate({
    required Iterable<RecurringPattern> recurringPatterns,
    required Iterable<RiskInput> riskInputs,
    required Iterable<AutomationTransaction> anomalyTransactions,
    required DateTime from,
    required DateTime to,
    bool enableAi = false,
  }) async {
    final forecast = forecastEngine.forecast(
      patterns: recurringPatterns,
      from: from,
      to: to,
    );
    final risks = riskEngine.assess(riskInputs);
    final anomalies = anomalyEngine.detect(anomalyTransactions);
    final fallback = PredictiveResult(
      forecast: forecast,
      risks: risks,
      anomalies: anomalies,
      provider: PredictiveProvider.deterministic,
      explanation: enableAi
          ? 'هوش مصنوعی محلی در دسترس یا قابل اعتماد نبود؛ نتیجه قطعی‌پذیر استفاده شد.'
          : 'هوش مصنوعی اختیاری خاموش است؛ نتیجه قطعی‌پذیر استفاده شد.',
    );
    final adapter = aiAdapter;
    if (!enableAi ||
        adapter == null ||
        adapter.availability != LocalAiAvailability.available) {
      return fallback;
    }
    try {
      final insight = await adapter.evaluate(
        LocalAiRequest(forecast: forecast, risks: risks, anomalies: anomalies),
      );
      if (!evaluationPolicy.accepts(insight)) return fallback;
      return PredictiveResult(
        forecast: forecast,
        risks: risks,
        anomalies: anomalies,
        provider: PredictiveProvider.onDeviceAi,
        aiInsight: insight,
        explanation: 'خلاصه اختیاری روی دستگاه تولید شد؛ داده‌های قطعی‌پذیر همچنان مبنای نتیجه هستند.',
      );
    } catch (_) {
      return fallback;
    }
  }
}
