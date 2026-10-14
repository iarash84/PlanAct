import 'package:flutter/material.dart';
import 'package:planact/app/theme/planact_spacing.dart';

class ReportBarDatum {
  const ReportBarDatum(this.label, this.value, this.formattedValue);
  final String label;
  final int value;
  final String formattedValue;
}

/// Exact values remain integers; only bar geometry uses a normalized ratio.
/// Signed series share a zero baseline, with negatives towards directional end.
class ReportBarChart extends StatelessWidget {
  const ReportBarChart({super.key, required this.title, required this.data});
  final String title;
  final List<ReportBarDatum> data;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final maximum = data.fold<int>(
      0,
      (max, d) => d.value.abs() > max ? d.value.abs() : max,
    );
    final signed = data.any((d) => d.value < 0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: PlanActSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          if (signed)
            const Text(
              'مبدأ میله‌ها صفر است؛ مقدار منفی با علامت − مشخص شده است.',
            ),
          for (final datum in data)
            Padding(
              padding: const EdgeInsets.only(top: PlanActSpacing.md),
              child: Semantics(
                label: '${datum.label}: ${datum.formattedValue}',
                child: ExcludeSemantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('${datum.label} · ${datum.formattedValue}'),
                      const SizedBox(height: PlanActSpacing.xs),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final extent =
                              constraints.maxWidth / (signed ? 2 : 1);
                          final width = maximum == 0
                              ? 0.0
                              : extent * (datum.value.abs() / maximum);
                          return SizedBox(
                            height: PlanActSpacing.md,
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: ColoredBox(
                                    color: scheme.surfaceContainerHighest,
                                  ),
                                ),
                                PositionedDirectional(
                                  start: signed
                                      ? (datum.value < 0
                                            ? extent
                                            : extent - width)
                                      : 0,
                                  width: width,
                                  top: 0,
                                  bottom: 0,
                                  child: ColoredBox(color: scheme.secondary),
                                ),
                                if (signed)
                                  PositionedDirectional(
                                    start: extent,
                                    width: 1,
                                    top: 0,
                                    bottom: 0,
                                    child: ColoredBox(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (maximum == 0) const Text('همهٔ مقادیر صفر هستند.'),
        ],
      ),
    );
  }
}
