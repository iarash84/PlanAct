import 'package:planact/core/localization/planact_localizations.dart';

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/core/localization/persian_numbers.dart';

enum FinancialChartStyle { line, donut, grouped, stacked }

class FinancialChartSeries {
  const FinancialChartSeries(this.label, this.values);
  final String label;
  final List<int> values;
}

/// Integer data and exact text are authoritative; doubles are drawing geometry.
class FinancialReportChart extends StatelessWidget {
  const FinancialReportChart({
    super.key,
    required this.title,
    required this.labels,
    required this.series,
    required this.format,
    required this.style,
    this.positions,
  });
  final String title;
  final List<String> labels;
  final List<FinancialChartSeries> series;
  final String Function(int) format;
  final FinancialChartStyle style;

  /// Optional ordered civil-day/month coordinates, preserving gaps in line data.
  final List<int>? positions;

  @override
  Widget build(BuildContext context) {
    if (labels.isEmpty || series.isEmpty) return const SizedBox.shrink();
    assert(series.every((s) => s.values.length == labels.length));
    assert(positions == null || positions!.length == labels.length);
    final scheme = Theme.of(context).colorScheme;
    final colors = [
      scheme.primary,
      scheme.secondary,
      scheme.tertiary,
      scheme.onSurfaceVariant,
    ];
    final values = series.expand((s) => s.values);
    final positive = values.where((v) => v > 0).fold<int>(0, (a, b) => a + b);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: PlanActSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          if (style != FinancialChartStyle.donut)
            Text('${labels.first} ← ${labels.last}'),
          if (style != FinancialChartStyle.donut)
            Text(
              planActL10n(context).financialReportChartBuildChildren(
                (format(values.fold<int>(0, math.min))).toString(),
                (format(values.fold<int>(0, math.max))).toString(),
              ),
            ),
          if (style == FinancialChartStyle.grouped)
            Text(
              planActL10n(context).financialReportChartBuildChildren2(
                (labels.join(planActL10n(context).commonListSeparator))
                    .toString(),
              ),
            ),
          if (style == FinancialChartStyle.line)
            Text(planActL10n(context).financialReportChartBuildChildren3),
          if (style == FinancialChartStyle.donut && values.any((v) => v < 0))
            Text(planActL10n(context).financialReportChartBuildChildren4),
          if (style == FinancialChartStyle.donut && positive == 0)
            Text(planActL10n(context).financialReportChartBuildChildren5),
          if (values.every((v) => v == 0))
            Text(planActL10n(context).financialReportChartBuildChildren6)
          else
            ExcludeSemantics(
              child: SizedBox(
                height: 180,
                child: CustomPaint(
                  painter: _FinancialPainter(
                    labels,
                    series,
                    style,
                    colors,
                    scheme.outline,
                    Directionality.of(context),
                    positions,
                  ),
                ),
              ),
            ),
          for (var i = 0; i < series.length; i++)
            if (style != FinancialChartStyle.donut)
              _legend(
                colors[i % colors.length],
                '${PersianNumbers.format(i + 1)} · ${series[i].label}',
              ),
          if (style == FinancialChartStyle.donut)
            for (var i = 0; i < labels.length; i++)
              _legend(
                colors[i % colors.length],
                planActL10n(context).financialReportChartBuildChildren8(
                  (PersianNumbers.format(i + 1)).toString(),
                  (labels[i]).toString(),
                  (format(series.first.values[i])).toString(),
                  (positive > 0 && series.first.values[i] > 0
                          ? planActL10n(context)
                                .financialReportChartBuildChildren7(
                                  (PersianNumbers.format(
                                    (series.first.values[i] * 100 / positive)
                                        .toStringAsFixed(1),
                                  )).toString(),
                                )
                          : '')
                      .toString(),
                ),
              ),
          ExpansionTile(
            key: PageStorageKey('financial-chart-details:$title'),
            title: Text(planActL10n(context).financialReportChartBuildTitle),
            children: [
              for (var i = 0; i < labels.length; i++)
                Padding(
                  padding: const EdgeInsets.all(PlanActSpacing.sm),
                  child: Text(
                    planActL10n(context).financialReportChartBuildChildren10(
                      (labels[i]).toString(),
                      ([
                            for (final s in series)
                              planActL10n(
                                context,
                              ).financialReportChartBuildChildren9(
                                (s.label).toString(),
                                (format(s.values[i])).toString(),
                                (style == FinancialChartStyle.donut &&
                                            positive > 0 &&
                                            s.values[i] > 0
                                        ? planActL10n(
                                            context,
                                          ).financialReportChartBuildChildren7(
                                            (PersianNumbers.format(
                                              (s.values[i] * 100 / positive)
                                                  .toStringAsFixed(1),
                                            )).toString(),
                                          )
                                        : '')
                                    .toString(),
                              ),
                          ].join(planActL10n(context).commonClauseSeparator))
                          .toString(),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legend(Color color, String text) => Padding(
    padding: const EdgeInsets.only(top: PlanActSpacing.sm),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(end: PlanActSpacing.sm),
          child: SizedBox(
            width: PlanActSpacing.md,
            height: PlanActSpacing.md,
            child: ColoredBox(color: color),
          ),
        ),
        Expanded(child: Text(text)),
      ],
    ),
  );
}

class _FinancialPainter extends CustomPainter {
  _FinancialPainter(
    this.labels,
    this.series,
    this.style,
    this.colors,
    this.axisColor,
    this.direction,
    this.positions,
  );
  final List<String> labels;
  final List<FinancialChartSeries> series;
  final FinancialChartStyle style;
  final List<Color> colors;
  final Color axisColor;
  final TextDirection direction;
  final List<int>? positions;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      16,
      16,
      math.max(0, size.width - 32),
      size.height - 32,
    );
    if (style == FinancialChartStyle.donut) {
      final values = series.first.values;
      final total = values.where((v) => v > 0).fold<int>(0, (a, b) => a + b);
      if (total == 0) return;
      final diameter = math.min(rect.width, rect.height);
      final circle = Rect.fromCenter(
        center: rect.center,
        width: diameter * .8,
        height: diameter * .8,
      );
      var angle = -math.pi / 2;
      for (var i = 0; i < values.length; i++) {
        if (values[i] <= 0) continue;
        final sweep = values[i] / total * math.pi * 2;
        canvas.drawArc(
          circle,
          angle,
          sweep,
          false,
          Paint()
            ..color = colors[i % colors.length]
            ..style = PaintingStyle.stroke
            ..strokeWidth = diameter * .18,
        );
        angle += sweep;
      }
      return;
    }
    var low = 0, high = 0;
    for (var i = 0; i < labels.length; i++) {
      var pos = 0, neg = 0;
      for (final s in series) {
        low = math.min(low, s.values[i]);
        high = math.max(high, s.values[i]);
        if (s.values[i] >= 0) {
          pos += s.values[i];
        } else {
          neg += s.values[i];
        }
      }
      if (style == FinancialChartStyle.stacked) {
        low = math.min(low, neg);
        high = math.max(high, pos);
      }
    }
    if (low == high) return;
    double y(int v) => rect.bottom - (v - low) / (high - low) * rect.height;
    double x(double fraction) => direction == TextDirection.rtl
        ? rect.right - fraction * rect.width
        : rect.left + fraction * rect.width;
    canvas.drawLine(
      Offset(rect.left, y(0)),
      Offset(rect.right, y(0)),
      Paint()
        ..color = axisColor
        ..strokeWidth = 1,
    );
    final slot = rect.width / labels.length;
    for (var s = 0; s < series.length; s++) {
      final paint = Paint()..color = colors[s % colors.length];
      if (style == FinancialChartStyle.line) {
        final path = Path();
        for (var i = 0; i < labels.length; i++) {
          final point = Offset(
            x(
              labels.length == 1
                  ? .5
                  : positions == null
                  ? i / (labels.length - 1)
                  : (positions![i] - positions!.first) /
                        (positions!.last - positions!.first),
            ),
            y(series[s].values[i]),
          );
          if (i == 0) {
            path.moveTo(point.dx, point.dy);
          } else {
            path.lineTo(point.dx, point.dy);
          }
          if (labels.length <= 31 || i == 0 || i == labels.length - 1) {
            if (s.isEven) {
              canvas.drawCircle(point, 3, paint);
            } else {
              canvas.drawRect(
                Rect.fromCenter(center: point, width: 6, height: 6),
                paint,
              );
            }
          }
        }
        canvas.drawPath(
          path,
          paint
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      } else {
        for (var i = 0; i < labels.length; i++) {
          final value = series[s].values[i];
          var base = 0;
          if (style == FinancialChartStyle.stacked) {
            for (var before = 0; before < s; before++) {
              final v = series[before].values[i];
              if ((v >= 0) == (value >= 0)) base += v;
            }
          }
          final width =
              slot *
              .7 /
              (style == FinancialChartStyle.grouped ? series.length : 1);
          final center = x((i + .5) / labels.length);
          final left =
              style == FinancialChartStyle.grouped &&
                  direction == TextDirection.rtl
              ? center + slot * .35 - (s + 1) * width
              : center -
                    slot * .35 +
                    (style == FinancialChartStyle.grouped ? s * width : 0);
          canvas.drawRect(
            Rect.fromLTRB(
              left,
              math.min(y(base), y(base + value)),
              left + width,
              math.max(y(base), y(base + value)),
            ),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FinancialPainter oldDelegate) => true;
}
