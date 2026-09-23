import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/startup_splash.dart';
import 'package:planact/core/time/jalali_date.dart';
import 'package:planact/features/commitments/application/commitment_repository.dart';
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

    await tester.enterText(
      find.byKey(const ValueKey('commitment-title-field')),
      'کلاس زبان',
    );
    await tester.tap(find.text('افزودن جزئیات'));
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
    const weekdayLabels = ['ش', 'ی', 'د', 'س', 'چ', 'ج', 'پ'];
    final todayLabel = weekdayLabels[JalaliDate.now().weekDay - 1];
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

    expect(find.text('کلاس زبان'), findsOneWidget);
    expect(find.textContaining('جلسه'), findsOneWidget);
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
