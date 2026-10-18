import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/features/commitments/application/commitment_draft.dart';
import 'package:planact/features/capture/presentation/quick_capture_sheet.dart';
import 'package:planact/features/reminders/domain/reminder.dart';

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

  testWidgets('day presets are opt-in, toggleable and submitted together', (
    tester,
  ) async {
    CommitmentDraft? submitted;
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: QuickCaptureSheet(
              onSave: (draft) async {
                submitted = draft;
              },
            ),
          ),
        ),
      ),
    );
    await tester.enterText(
      find.byKey(const ValueKey('commitment-title-field')),
      'تمدید بیمه',
    );
    await _tap(tester, find.text('انتخاب تاریخ'));
    await _tap(tester, find.byKey(const ValueKey('capture-date-1')));
    await _tap(tester, find.text('تأیید تاریخ'));
    await _tap(tester, find.text('انتخاب زمان'));
    await _tap(tester, find.byType(TextButton).last);
    await _tap(tester, find.text('یادآور'));
    final three = find.widgetWithText(FilterChip, '۳ روز قبل');
    final ten = find.widgetWithText(FilterChip, '۱۰ روز قبل');
    expect(tester.widget<FilterChip>(three).selected, isFalse);
    expect(tester.widget<FilterChip>(ten).selected, isFalse);
    await _tap(tester, three);
    await _tap(tester, ten);
    await _tap(tester, three);
    expect(tester.widget<FilterChip>(three).selected, isFalse);
    await _tap(tester, three);
    await _tap(tester, find.text('یادآور'));
    await _tap(tester, find.text('ثبت تعهد'));
    expect(
      submitted!.reminderOffsets,
      unorderedEquals([const Duration(days: 3), const Duration(days: 10)]),
    );
    expect(tester.takeException(), isNull);
    expect(submitted!.reminderDelivery, ReminderDelivery.notification);
  });

  testWidgets(
    'alarm choice survives section collapse, validation and submission',
    (tester) async {
      CommitmentDraft? submitted;
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: QuickCaptureSheet(
                onSave: (draft) async {
                  submitted = draft;
                },
              ),
            ),
          ),
        ),
      );
      await tester.enterText(
        find.byKey(const ValueKey('commitment-title-field')),
        'قرار',
      );
      await _tap(tester, find.text('یادآور'));
      await _tap(tester, find.widgetWithText(ChoiceChip, 'آلارم'));
      await _tap(tester, find.widgetWithText(FilterChip, '۱۵ دقیقه قبل'));
      await _tap(tester, find.text('یادآور'));
      await _tap(tester, find.text('ثبت تعهد'));
      expect(submitted, isNull);
      await _tap(tester, find.text('یادآور'));
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'آلارم'))
            .selected,
        isTrue,
      );
      await _tap(tester, find.text('یادآور'));
      await _tap(tester, find.text('انتخاب تاریخ'));
      await _tap(tester, find.byKey(const ValueKey('capture-date-1')));
      await _tap(tester, find.text('تأیید تاریخ'));
      await _tap(tester, find.text('انتخاب زمان'));
      await _tap(tester, find.byType(TextButton).last);
      await _tap(tester, find.text('ثبت تعهد'));
      expect(submitted!.reminderDelivery, ReminderDelivery.alarm);
      expect(submitted!.reminderOffsets, [const Duration(minutes: 15)]);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'single page validates and retains input across optional sections',
    (tester) async {
      await tester.pumpWidget(host());
      expect(find.text('افزودن تعهد'), findsOneWidget);
      expect(find.text('ادامه'), findsNothing);
      expect(find.text('زمان‌بندی'), findsOneWidget);
      expect(find.text('اعتبار جلسات', skipOffstage: false), findsNothing);
      expect(find.text('اعتبار جلسه', skipOffstage: false), findsNothing);
      expect(find.text('تعداد جلسه', skipOffstage: false), findsNothing);
      expect(find.textContaining('بدون بستهٔ جلسه'), findsNothing);
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
    'collapsed finance validation opens correction and retains optional inputs',
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
      await _tap(tester, find.text('اطلاعات مالی'));
      await _tap(tester, find.text('پرداختی'));
      final amount = find.widgetWithText(TextField, 'مبلغ مورد انتظار به ریال');
      await tester.ensureVisible(amount);
      await tester.pumpAndSettle();
      await tester.enterText(amount, '۱۲۳۴۵');
      await tester.enterText(amount, '');
      await _tap(tester, find.text('اطلاعات مالی'));
      await _tap(tester, find.text('ثبت تعهد'));
      expect(submitted, isNull);
      expect(find.text('مبلغ مورد انتظار را وارد کنید.'), findsOneWidget);
      expect(amount, findsOneWidget);
      await tester.ensureVisible(amount);
      await tester.pumpAndSettle();
      await tester.enterText(amount, '۱۲۳۴۵');
      // Grouping is the approved input behavior. Preserve the formatted editing
      // value across failed saving, not the pre-formatter keystrokes.
      final enteredAmount = tester.widget<TextField>(amount).controller!.value;
      expect(enteredAmount.text, '12,345');
      await _tap(tester, find.text('اطلاعات مالی'));
      await _tap(tester, find.text('ثبت تعهد'));
      expect(submitted!.entitlement, EntitlementDraft.none);
      expect(submitted!.entitlementUnits, isNull);
      expect(submitted!.financialAmount, 12345);
      expect(
        submitted!.financialMeaning,
        CommitmentFinancialMeaning.paymentRequired,
      );
      expect(submitted!.reminderOffsets, [const Duration(minutes: 15)]);
      expect(find.textContaining('اطلاعات شما حفظ شده است'), findsOneWidget);
      await _tap(tester, find.text('اطلاعات مالی'));
      expect(tester.widget<TextField>(amount).controller!.value, enteredAmount);
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
      for (final label in ['یادآور', 'اطلاعات مالی', 'جزئیات بیشتر']) {
        await tester.ensureVisible(find.text(label));
        await tester.pumpAndSettle();
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      for (final label in ['۳ روز قبل', '۱۰ روز قبل']) {
        await _tap(tester, find.widgetWithText(FilterChip, label));
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
