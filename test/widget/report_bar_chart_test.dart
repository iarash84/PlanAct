import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/features/reports/presentation/report_bar_chart.dart';

void main() {
  for (final dark in [false, true]) {
    testWidgets(
      'signed chart has common zero and exact accessible values ($dark)',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final semantics = tester.ensureSemantics();
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? PlanActTheme.dark() : PlanActTheme.light(),
            home: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(1.8)),
              child: const Directionality(
                textDirection: TextDirection.rtl,
                child: Scaffold(
                  body: SingleChildScrollView(
                    child: ReportBarChart(
                      title: 'مقایسهٔ موجودی حساب در بازهٔ انتخاب‌شده',
                      data: [
                        ReportBarDatum('ابتدای دوره', 100, '۱۰۰ ریال'),
                        ReportBarDatum('خالص گردش کل دوره', -50, '−۵۰ ریال'),
                        ReportBarDatum('پایان دوره', 0, '۰ ریال'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        expect(
          find.bySemanticsLabel('خالص گردش کل دوره: −۵۰ ریال'),
          findsOneWidget,
        );
        final bars = tester
            .widgetList<PositionedDirectional>(
              find.byType(PositionedDirectional),
            )
            .toList();
        // 360dp plot: positive max fills one 180dp half; -50 fills 90dp.
        expect(bars[0].start, 0);
        expect(bars[0].width, 180);
        expect(bars[2].start, 180);
        expect(bars[2].width, 90);
        expect(bars[4].width, 0);
        expect(tester.takeException(), isNull);
        semantics.dispose();
      },
    );
  }
  testWidgets('zero series is disclosed and empty chart has no invented bars', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const Scaffold(
          body: ReportBarChart(
            title: 'اعتبار',
            data: [ReportBarDatum('باقی‌مانده', 0, '۰ جلسه')],
          ),
        ),
      ),
    );
    expect(find.text('همهٔ مقادیر صفر هستند.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(
      MaterialApp(
        home: const Scaffold(
          body: ReportBarChart(title: 'اعتبار', data: []),
        ),
      ),
    );
    expect(find.text('اعتبار'), findsNothing);
    expect(
      find.descendant(
        of: find.byType(ReportBarChart),
        matching: find.byType(Stack),
      ),
      findsNothing,
    );
  });
}
