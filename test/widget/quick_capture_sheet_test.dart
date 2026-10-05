import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
    await tester.tap(find.text('ادامه'));
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

  testWidgets('capture visits each step and preserves title when going back', (
    tester,
  ) async {
    await tester.pumpWidget(host());
    expect(find.text('اصل تعهد'), findsOneWidget);
    await tester.tap(find.text('ادامه'));
    await tester.pumpAndSettle();
    expect(find.text('عنوان تعهد را وارد کنید.'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('commitment-title-field')),
      'کلاس',
    );
    await tester.tap(find.text('ادامه'));
    await tester.pumpAndSettle();
    expect(find.text('زمان‌بندی'), findsOneWidget);
    await tester.tap(find.text('بازگشت'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextFormField, 'کلاس'), findsOneWidget);
  });
  testWidgets('failed persistence keeps capture open and supports retry', (
    tester,
  ) async {
    var attempts = 0;
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
    await tester.tap(find.text('ادامه'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('انتخاب تاریخ'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('capture-date-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('انتخاب زمان'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TextButton).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('ادامه'));
    await tester.pumpAndSettle();
    expect(find.text('مرور و ثبت'), findsOneWidget);
    await tester.tap(find.text('ثبت تعهد'));
    await tester.pumpAndSettle();
    expect(attempts, 1);
    expect(find.textContaining('اطلاعات شما حفظ شده است'), findsOneWidget);
    expect(find.text('مرور و ثبت'), findsOneWidget);
    await tester.tap(find.text('ثبت تعهد'));
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(find.text('باز کردن'), findsOneWidget);
  });
}
