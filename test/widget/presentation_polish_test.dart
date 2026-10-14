import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:planact/app/planact_app.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/features/finance/application/finance_use_cases.dart';
import 'package:planact/features/finance/presentation/finance_page.dart';
import 'package:planact/features/inbox/presentation/inbox_page.dart';
import 'package:planact/features/reports/presentation/reports_page.dart';

void main() {
  testWidgets('upper menu opens reports and inbox and returns to Today', (
    tester,
  ) async {
    final smsCalls = <String>[];
    const smsChannel = MethodChannel('planact/sms');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(smsChannel, (
      call,
    ) async {
      smsCalls.add(call.method);
      return false;
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        smsChannel,
        null,
      ),
    );
    await tester.pumpWidget(const PlanActApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('گزینه‌های بیشتر'));
    await tester.pumpAndSettle();
    expect(find.text('افزودن تعهد'), findsOneWidget);
    expect(find.text('خط زمانی تعهدات'), findsOneWidget);
    await tester.tap(find.text('گزارش‌ها'));
    await tester.pumpAndSettle();
    expect(find.byType(ReportsPage), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('گزینه‌های بیشتر'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('صندوق ورودی'));
    await tester.pumpAndSettle();
    expect(find.byType(InboxPage), findsOneWidget);
    expect(smsCalls, everyElement('hasAccess'));
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('چه چیزی نیاز به توجه دارد؟'), findsOneWidget);
    await tester.tap(find.text('مالی').last);
    await tester.pumpAndSettle();
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.text('مدیریت مالی'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final dark in [false, true]) {
    testWidgets('narrow large-text RTL menu with reduced motion, dark=$dark', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: dark ? PlanActTheme.dark() : PlanActTheme.light(),
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 800),
              textScaler: TextScaler.linear(2),
              disableAnimations: true,
            ),
            child: const Directionality(
              textDirection: TextDirection.rtl,
              child: HomeShell(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('گزینه‌های بیشتر'));
      await tester.pumpAndSettle();
      for (final label in [
        'افزودن تعهد',
        'خط زمانی تعهدات',
        'گزارش‌ها',
        'صندوق ورودی',
      ]) {
        expect(find.text(label), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('standalone Finance retains its header', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: FinancePage(repository: InMemoryFinanceRepository())),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.text('مالی'), findsOneWidget);
  });
}
