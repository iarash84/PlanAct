import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/features/reports/presentation/financial_report_chart.dart';

void main() {
  for (final dark in [false, true]) {
    for (final style in FinancialChartStyle.values) {
      testWidgets('$style populated RTL 360dp large text dark=$dark', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(360, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? PlanActTheme.dark() : PlanActTheme.light(),
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: MediaQuery(
                data: const MediaQueryData(textScaler: TextScaler.linear(1.8)),
                child: Scaffold(
                  body: SingleChildScrollView(
                    child: FinancialReportChart(
                      title: 'نمودار مالی',
                      labels: const ['آموزش', 'خرید'],
                      series: const [
                        FinancialChartSeries('مبلغ', [100, -20]),
                      ],
                      format: (v) => '$v ریال',
                      style: style,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        expect(find.text('نمودار مالی'), findsOneWidget);
        await tester.ensureVisible(find.text('مقادیر دقیق نمودار'));
        await tester.tap(find.text('مقادیر دقیق نمودار'));
        await tester.pumpAndSettle();
        expect(find.textContaining('100 ریال'), findsWidgets);
        expect(find.textContaining('-20 ریال'), findsWidgets);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
