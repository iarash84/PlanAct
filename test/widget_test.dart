import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/main.dart';

void main() {
  testWidgets('پوستهٔ فارسی و ثبت تعهد کار می‌کند', (tester) async {
    await tester.pumpWidget(const PlanActApp());

    expect(find.text('امروز'), findsWidgets);
    expect(find.text('چه چیزی نیاز به توجه دارد؟'), findsOneWidget);
    expect(find.text('ثبت اولین تعهد'), findsOneWidget);

    final todayContext = tester.element(
      find.text('چه چیزی نیاز به توجه دارد؟'),
    );
    expect(Directionality.of(todayContext), TextDirection.rtl);

    await tester.tap(find.text('ثبت اولین تعهد'));
    await tester.pumpAndSettle();
    expect(find.text('تعهد جدید'), findsNWidgets(2));

    await tester.enterText(find.byType(TextField).first, 'کلاس زبان');
    await tester.tap(find.widgetWithText(FilterChip, 'د'));
    await tester.tap(find.widgetWithText(FilterChip, 'پ'));
    await tester.tap(find.widgetWithText(FilledButton, 'ثبت'));
    await tester.pumpAndSettle();

    expect(find.text('کلاس زبان'), findsOneWidget);
    expect(find.textContaining('فعال • '), findsOneWidget);
  });

  testWidgets('ناوبری تقویم فارسی را نمایش می‌دهد', (tester) async {
    await tester.pumpWidget(const PlanActApp());

    await tester.tap(find.text('تقویم'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('ماه قبل'), findsOneWidget);
    expect(find.byTooltip('ماه بعد'), findsOneWidget);
    expect(find.text('ج'), findsOneWidget);

    await tester.tap(find.byTooltip('ماه بعد'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('ماه قبل'), findsOneWidget);
  });
}
