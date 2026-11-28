import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/features/capture/presentation/quick_capture_sheet.dart';

void main() {
  for (final dark in [false, true]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('financial choices RTL dark=$dark scale=$scale', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(320, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var saves = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? PlanActTheme.dark() : PlanActTheme.light(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: child!,
              ),
            ),
            home: Scaffold(
              body: QuickCaptureSheet(
                onSave: (_) async {
                  saves++;
                },
              ),
            ),
          ),
        );
        await _tap(tester, find.text('اطلاعات مالی'));
        final group = find.byKey(
          const ValueKey('commitment-financial-meaning'),
        );
        final choices = find.descendant(
          of: group,
          matching: find.byType(ChoiceChip),
        );
        final none = find.widgetWithText(ChoiceChip, 'ندارد');
        final payment = find.widgetWithText(ChoiceChip, 'پرداختی');
        final receivable = find.widgetWithText(ChoiceChip, 'دریافتی');
        final amount = find.widgetWithText(
          TextField,
          'مبلغ مورد انتظار به ریال',
        );
        expect(choices, findsNWidgets(3));
        expect(tester.widget<ChoiceChip>(none).selected, isTrue);
        expect(amount, findsNothing);
        for (final choice in choices.evaluate()) {
          final finder = find.byWidget(choice.widget);
          await tester.ensureVisible(finder);
          await tester.pumpAndSettle();
          final rect = tester.getRect(finder);
          expect(rect.left, greaterThanOrEqualTo(0));
          expect(rect.right, lessThanOrEqualTo(320));
          expect(rect.height, greaterThanOrEqualTo(PlanActSpacing.touchTarget));
        }
        final wrap = tester.widget<Wrap>(group);
        expect(wrap.spacing, PlanActSpacing.sm);
        expect(wrap.runSpacing, PlanActSpacing.sm);
        await _tap(tester, payment);
        expect(tester.widget<ChoiceChip>(payment).selected, isTrue);
        expect(tester.widget<ChoiceChip>(none).selected, isFalse);
        await tester.ensureVisible(amount);
        await tester.enterText(amount, '۱۲۳۴۵');
        await _tap(tester, receivable);
        expect(tester.widget<ChoiceChip>(receivable).selected, isTrue);
        expect(tester.widget<ChoiceChip>(payment).selected, isFalse);
        expect(tester.widget<TextField>(amount).controller!.text, '12,345');
        await _tap(tester, receivable);
        expect(tester.widget<ChoiceChip>(receivable).selected, isTrue);
        await tester.ensureVisible(amount);
        await tester.pumpAndSettle();
        expect(
          tester.getRect(group).bottom,
          lessThan(tester.getRect(amount).top),
        );
        await _tap(tester, none);
        expect(amount, findsNothing);
        await _tap(tester, payment);
        expect(tester.widget<TextField>(amount).controller!.text, '12,345');
        await _tap(tester, find.text('اطلاعات مالی'));
        await _tap(tester, find.text('اطلاعات مالی'));
        expect(tester.widget<ChoiceChip>(payment).selected, isTrue);
        expect(tester.widget<TextField>(amount).controller!.text, '12,345');
        expect(saves, 0);
        expect(tester.takeException(), isNull);
      });
    }
  }
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
  await tester.pumpAndSettle();
  for (
    var attempt = 0;
    attempt < 4 && finder.hitTestable().evaluate().isEmpty;
    attempt++
  ) {
    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(0, -150),
    );
    await tester.pumpAndSettle();
  }
  await tester.tap(finder);
  await tester.pumpAndSettle();
}
