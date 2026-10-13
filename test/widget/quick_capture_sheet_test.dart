import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/features/commitments/application/commitment_draft.dart';
import 'package:planact/features/capture/presentation/quick_capture_sheet.dart';

void main() {
  Widget host() => const MaterialApp(
    locale: Locale('fa'),
    home: Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(body: QuickCaptureSheet()),
    ),
  );

  testWidgets('cancelling an empty custom reminder does not crash', (
    tester,
  ) async {
    await tester.pumpWidget(host());

    await tester.enterText(
      find.byKey(const ValueKey('commitment-title-field')),
      'جلسه',
    );
    await tester.ensureVisible(find.text('یادآور'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('یادآور'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('زمان دلخواه'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('زمان دلخواه'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('custom-reminder-minutes-field')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('custom-reminder-cancel')));
    await tester.pumpAndSettle();

    expect(find.text('یادآوری دلخواه'), findsNothing);
    expect(find.text('یادآوری‌های این تعهد'), findsOneWidget);
  });

  testWidgets(
    'single page validates and retains input across optional sections',
    (tester) async {
      await tester.pumpWidget(host());
      expect(find.text('افزودن تعهد'), findsOneWidget);
      expect(find.text('ادامه'), findsNothing);
      expect(find.text('زمان‌بندی'), findsOneWidget);
      await tester.tap(find.text('ثبت تعهد'));
      await tester.pumpAndSettle();
      expect(find.text('عنوان تعهد را وارد کنید.'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('commitment-title-field')),
        'کلاس',
      );
      await tester.tap(find.text('ثبت تعهد'));
      await tester.pumpAndSettle();
      expect(find.text('تاریخ و زمان شروع را انتخاب کنید.'), findsOneWidget);
      await tester.ensureVisible(find.text('جزئیات بیشتر'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('جزئیات بیشتر'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.widgetWithText(TextField, 'توضیحات (اختیاری)'),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'توضیحات (اختیاری)'),
        'یادداشت',
      );
      await tester.ensureVisible(find.text('جزئیات بیشتر'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('جزئیات بیشتر'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('جزئیات بیشتر'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextFormField, 'کلاس'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'یادداشت'), findsOneWidget);
    },
  );
  testWidgets('failed persistence keeps capture open and supports retry', (
    tester,
  ) async {
    var attempts = 0;
    final pending = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fa'),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => QuickCaptureSheet(
                  onSave: (draft) async {
                    attempts++;
                    if (attempts == 1) throw StateError('transient failure');
                    await pending.future;
                  },
                ),
              ),
              child: const Text('باز کردن'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('باز کردن'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('commitment-title-field')),
      'کلاس',
    );
    await tester.tap(find.text('انتخاب تاریخ'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('capture-date-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('تأیید تاریخ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('انتخاب زمان'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TextButton).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('ثبت تعهد'));
    await tester.pumpAndSettle();
    expect(attempts, 1);
    expect(find.textContaining('اطلاعات شما حفظ شده است'), findsOneWidget);
    expect(find.text('افزودن تعهد'), findsOneWidget);
    await tester.tap(find.text('ثبت تعهد'));
    await tester.pump();
    expect(attempts, 2);
    expect(
      tester
          .widget<TextFormField>(
            find.byKey(const ValueKey('commitment-title-field')),
          )
          .enabled,
      isFalse,
    );
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const ValueKey('commitment-save-button')),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<AbsorbPointer>(
            find
                .descendant(
                  of: find.byType(QuickCaptureSheet),
                  matching: find.byType(AbsorbPointer),
                )
                .first,
          )
          .absorbing,
      isTrue,
    );
    expect(
      tester
          .widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'انصراف'))
          .onPressed,
      isNull,
    );
    pending.complete();
    await tester.pumpAndSettle();
    expect(find.text('باز کردن'), findsOneWidget);
  });

  testWidgets(
    'collapsed credit validation opens correction and retains optional inputs',
    (tester) async {
      CommitmentDraft? submitted;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickCaptureSheet(
              onSave: (draft) async {
                submitted = draft;
                throw StateError('injected failure');
              },
            ),
          ),
        ),
      );
      await tester.enterText(
        find.byKey(const ValueKey('commitment-title-field')),
        'کلاس موسیقی',
      );
      await _tap(tester, find.text('انتخاب تاریخ'));
      await _tap(tester, find.byKey(const ValueKey('capture-date-1')));
      await _tap(tester, find.text('تأیید تاریخ'));
      await _tap(tester, find.text('انتخاب زمان'));
      await _tap(tester, find.byType(TextButton).last);
      await _tap(tester, find.text('یادآور'));
      await _tap(tester, find.text('۱۵ دقیقه قبل'));
      await _tap(tester, find.text('یادآور'));
      await _tap(tester, find.text('اعتبار جلسات'));
      await _tap(
        tester,
        find.byType(DropdownButtonFormField<EntitlementDraft>),
      );
      await _tap(tester, find.text('تعداد ثابت جلسه').last);
      final units = find.widgetWithText(TextField, 'تعداد جلسه');
      await tester.ensureVisible(units);
      await tester.pumpAndSettle();
      await tester.enterText(units, '۴');
      await tester.enterText(units, '');
      await _tap(tester, find.text('اعتبار جلسات'));
      await _tap(tester, find.text('ثبت تعهد'));
      expect(submitted, isNull);
      expect(find.text('تعداد جلسهٔ معتبر را وارد کنید.'), findsOneWidget);
      expect(units, findsOneWidget);
      await tester.ensureVisible(units);
      await tester.pumpAndSettle();
      await tester.enterText(units, '۶');
      await _tap(tester, find.text('اعتبار جلسات'));
      await _tap(tester, find.text('اطلاعات مالی'));
      await _tap(tester, find.text('پرداختی'));
      final amount = find.widgetWithText(TextField, 'مبلغ مورد انتظار به ریال');
      await tester.ensureVisible(amount);
      await tester.pumpAndSettle();
      await tester.enterText(amount, '۱۲۳۴۵');
      await _tap(tester, find.text('اطلاعات مالی'));
      await _tap(tester, find.text('ثبت تعهد'));
      expect(submitted!.entitlementUnits, 6);
      expect(submitted!.financialAmount, 12345);
      expect(
        submitted!.financialMeaning,
        CommitmentFinancialMeaning.paymentRequired,
      );
      expect(submitted!.reminderOffsets, [const Duration(minutes: 15)]);
      expect(find.textContaining('اطلاعات شما حفظ شده است'), findsOneWidget);
      await _tap(tester, find.text('اطلاعات مالی'));
      expect(tester.widget<TextField>(amount).controller!.text, '۱۲۳۴۵');
    },
  );

  for (final dark in [false, true]) {
    testWidgets('narrow RTL form with large text and keyboard ($dark)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = const FakeViewPadding(bottom: 260);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.view.resetViewInsets();
      });
      await tester.pumpWidget(
        MaterialApp(
          theme: dark ? PlanActTheme.dark() : PlanActTheme.light(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(2),
              disableAnimations: true,
            ),
            child: child!,
          ),
          home: const Scaffold(body: QuickCaptureSheet()),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        tester
            .widget<ExpansionTile>(
              find.byKey(const ValueKey('commitment-reminders-section')),
            )
            .expansionAnimationStyle!
            .duration,
        Duration.zero,
      );
      final save = find.byKey(const ValueKey('commitment-save-button'));
      expect(tester.getRect(save).bottom, lessThanOrEqualTo(640));
      for (final label in [
        'یادآور',
        'اعتبار جلسات',
        'اطلاعات مالی',
        'جزئیات بیشتر',
      ]) {
        await tester.ensureVisible(find.text(label));
        await tester.pumpAndSettle();
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });
  }
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}
