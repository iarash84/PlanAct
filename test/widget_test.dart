import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/startup_splash.dart';
import 'package:planact/features/calendar/presentation/calendar_page.dart';
import 'package:planact/features/commitments/application/commitment_repository.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/main.dart';

void main() {
  testWidgets('پوستهٔ فارسی و ثبت تعهد کار می‌کند', (tester) async {
    await tester.pumpWidget(const PlanActApp());
    await tester.pumpAndSettle();

    expect(find.text('امروز'), findsWidgets);
    expect(find.text('چه چیزی نیاز به توجه دارد؟'), findsOneWidget);
    expect(find.text('ثبت تعهد جدید'), findsOneWidget);

    final todayContext = tester.element(
      find.text('چه چیزی نیاز به توجه دارد؟'),
    );
    expect(Directionality.of(todayContext), TextDirection.rtl);

    await tester.tap(find.text('ثبت تعهد جدید'));
    await tester.pumpAndSettle();
    expect(find.text('اصل تعهد'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('commitment-title-field')),
      'کلاس زبان',
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
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('commitment-kind-dropdown')),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.byKey(const ValueKey('commitment-kind-dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('تکرارشونده').last);
    await tester.pumpAndSettle();
    // Recurrence weekdays use Dart's DateTime convention (Sunday = 1).
    const weekdayLabelsByDartWeekday = ['د', 'س', 'چ', 'پ', 'ج', 'ش', 'ی'];
    final todayLabel = weekdayLabelsByDartWeekday[DateTime.now().weekday - 1];
    await tester.scrollUntilVisible(
      find.widgetWithText(FilterChip, todayLabel),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.widgetWithText(FilterChip, todayLabel));
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('commitment-save-button')),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.byKey(const ValueKey('commitment-save-button')));
    await tester.pumpAndSettle();
    expect(find.text('مرور و ثبت'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('commitment-save-button')));
    await tester.pumpAndSettle();

    expect(find.text('کلاس زبان'), findsWidgets);
    expect(find.text('تعیین وضعیت'), findsWidgets);
  });

  testWidgets('ناوبری تقویم فارسی را نمایش می‌دهد', (tester) async {
    await tester.pumpWidget(const PlanActApp());

    await tester.tap(find.text('تقویم'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('ماه قبل'), findsOneWidget);
    expect(find.byTooltip('ماه بعد'), findsOneWidget);
    for (final weekday in [
      'شنبه',
      'یکشنبه',
      'دوشنبه',
      'سه‌شنبه',
      'چهارشنبه',
      'پنجشنبه',
      'جمعه',
    ]) {
      expect(find.text(weekday), findsOneWidget);
    }

    await tester.tap(find.byTooltip('ماه بعد'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('ماه قبل'), findsOneWidget);
  });

  testWidgets('calendar shows compact count and selected-day details', (
    tester,
  ) async {
    final commitment = Commitment.create(title: 'کلاس موسیقی');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CalendarPage(
            commitments: [commitment],
            scheduledDates: {
              commitment.id.value: [DateTime.now()],
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('۱'), findsWidgets);
    final semantics = tester.ensureSemantics();
    expect(
      find.bySemanticsLabel(RegExp('امروز.*انتخاب‌شده|انتخاب‌شده.*امروز')),
      findsOneWidget,
    );
    semantics.dispose();
    await tester.scrollUntilVisible(
      find.text('کلاس موسیقی'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('کلاس موسیقی'), findsOneWidget);
  });

  testWidgets('خطای راه‌اندازی امکان تلاش دوباره دارد', (tester) async {
    var attempts = 0;
    await tester.pumpWidget(
      PlanActStartup(
        repositoryLoader: () {
          attempts++;
          if (attempts == 1) {
            return Future.error(StateError('startup failed'));
          }
          return Future.value(InMemoryCommitmentRepository());
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('راه‌اندازی برنامه انجام نشد'), findsOneWidget);
    expect(find.text('تلاش دوباره'), findsOneWidget);
    expect(attempts, 1);

    await tester.tap(find.text('تلاش دوباره'));
    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(find.text('چه چیزی نیاز به توجه دارد؟'), findsOneWidget);
  });
}
