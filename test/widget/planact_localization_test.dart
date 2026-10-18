import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/planact_app.dart';
import 'package:planact/l10n/generated/app_localizations.dart';
import 'package:planact/core/presentation/planact_jalali_date_picker.dart';
import 'package:planact/features/capture/presentation/quick_capture_sheet.dart';
import 'package:planact/features/commitments/application/commitment_repository.dart';
import 'package:planact/features/quick_add/presentation/quick_add_sheet.dart';

// QA_FIX_VERIFICATION: exercise the production root, not a localized test
// MaterialApp. Framework semantics must reach actual navigation and modal
// routes in both themes; cancelling an unfinished draft must not write.
void main() {
  for (final brightness in Brightness.values) {
    testWidgets('production Persian framework routes in ${brightness.name}', (
      tester,
    ) async {
      tester.platformDispatcher.platformBrightnessTestValue = brightness;
      tester.view.physicalSize = const Size(400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.platformDispatcher.clearPlatformBrightnessTestValue();
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final semantics = tester.ensureSemantics();
      final repository = InMemoryCommitmentRepository();
      await tester.pumpWidget(PlanActApp(repository: repository));
      await tester.pumpAndSettle();

      final root = tester.element(find.byType(NavigationBar));
      _expectPersian(root, brightness);
      expect(
        MaterialLocalizations.of(root).tabLabel(tabIndex: 1, tabCount: 4),
        'برگه ۱ از ۴',
      );
      for (final (index, label) in [
        'امروز',
        'تقویم',
        'مالی',
        'بیشتر',
      ].indexed) {
        final tab = find.bySemanticsLabel(
          RegExp('$label\\nبرگه ${['۱', '۲', '۳', '۴'][index]} از ۴'),
        );
        expect(tab, findsOneWidget);
      }
      await tester.tap(find.byType(NavigationDestination).last);
      await tester.pumpAndSettle();
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        3,
      );
      _expectPersian(tester.element(find.byType(NavigationBar)), brightness);

      await tester.tap(find.byTooltip('افزودن سریع'));
      await tester.pumpAndSettle();
      _expectPersian(tester.element(find.byType(QuickAddSheet)), brightness);
      final material = MaterialLocalizations.of(root);
      final barrier = find.bySemanticsLabel(material.scrimLabel);
      expect(barrier, findsOneWidget);
      expect(
        tester.getSemantics(barrier).hintOverrides?.onTapHint,
        material.scrimOnTapHint(material.bottomSheetLabel),
      );
      expect(material.scrimLabel, isNot('Scrim'));
      expect(find.bySemanticsLabel('بستن'), findsWidgets);
      // A tap outside the actual sheet cancels the route, not a form command.
      await tester.tapAt(const Offset(20, 100));
      await tester.pumpAndSettle();
      expect(find.byType(QuickAddSheet), findsNothing);
      expect(await repository.list(), isEmpty);

      await tester.tap(find.byTooltip('افزودن سریع'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('quick-add-commitment')));
      await tester.pumpAndSettle();
      _expectPersian(
        tester.element(find.byType(QuickCaptureSheet)),
        brightness,
      );
      await tester.enterText(
        find.byKey(const ValueKey('commitment-title-field')),
        'آزمون محلی‌سازی',
      );

      // Localization must not replace PlanAct's custom Jalali date route.
      await _tap(tester, find.text('انتخاب تاریخ'));
      expect(find.byType(PlanActJalaliDatePicker), findsOneWidget);
      expect(find.byType(DatePickerDialog), findsNothing);
      _expectPersian(
        tester.element(find.byType(PlanActJalaliDatePicker)),
        brightness,
      );
      await _tap(tester, find.text('انصراف').last);
      expect(find.text('انتخاب تاریخ'), findsOneWidget);

      await _tap(tester, find.text('انتخاب زمان'));
      expect(find.byType(TimePickerDialog), findsOneWidget);
      _expectPersian(tester.element(find.byType(TimePickerDialog)), brightness);
      expect(find.text('لغو'), findsOneWidget);
      expect(find.text('انتخاب زمان'), findsWidgets);
      await _tap(tester, find.text('لغو'));
      expect(find.byType(TimePickerDialog), findsNothing);
      expect(find.text('انتخاب زمان'), findsOneWidget);

      expect(find.text('اعتبار جلسات'), findsNothing);
      final advanced = find.text('اطلاعات مالی');
      await tester.ensureVisible(advanced);
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel(material.expandedHint), findsWidgets);
      final collapsed = find.bySemanticsLabel(RegExp('^اطلاعات مالی')).first;
      expect(
        tester.getSemantics(collapsed).getSemanticsData().hint,
        material.expandedHint,
      );
      await _tap(tester, advanced);
      expect(
        tester
            .getSemantics(find.bySemanticsLabel(RegExp('^اطلاعات مالی')).first)
            .getSemanticsData()
            .hint,
        material.collapsedHint,
      );
      await _tap(tester, advanced);
      expect(
        tester
            .getSemantics(find.bySemanticsLabel(RegExp('^اطلاعات مالی')).first)
            .getSemanticsData()
            .hint,
        material.expandedHint,
      );
      await _tap(tester, find.text('انصراف'));
      expect(find.byType(QuickCaptureSheet), findsNothing);
      expect(await repository.list(), isEmpty);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });
  }
}

void _expectPersian(BuildContext context, Brightness brightness) {
  expect(Localizations.localeOf(context), const Locale('fa'));
  expect(AppLocalizations.of(context)?.commonSave, 'ذخیره');
  expect(Directionality.of(context), TextDirection.rtl);
  expect(WidgetsLocalizations.of(context).textDirection, TextDirection.rtl);
  expect(MaterialLocalizations.of(context).cancelButtonLabel, 'لغو');
  expect(CupertinoLocalizations.of(context).cancelButtonLabel, 'لغو');
  expect(Theme.of(context).brightness, brightness);
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}
