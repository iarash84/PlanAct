import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/core/localization/persian_date_formatter.dart';
import 'package:planact/core/presentation/holiday_provider_scope.dart';
import 'package:planact/core/presentation/planact_jalali_date_picker.dart';
import 'package:planact/core/time/jalali_date.dart';
import 'package:planact/features/calendar/domain/holiday_provider.dart';

void main() {
  Future<void> open(
    WidgetTester tester, {
    required JalaliDate date,
    IranianHolidayProvider provider = const IranianHolidayProvider(),
    bool dark = false,
    double scale = 1,
    void Function(DateTime?)? onResult,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: dark ? PlanActTheme.dark() : PlanActTheme.light(),
        builder: (context, child) => HolidayProviderScope(
          readProvider: () => provider,
          child: MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                // Deliberately use a pushed route and then a modal under the root seam.
                await Navigator.push<void>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Scaffold(
                      body: TextButton(
                        onPressed: () async {
                          final result = await showDialog<DateTime>(
                            context: context,
                            builder: (_) => PlanActJalaliDatePicker(
                              initialDate: date.toDateTime(),
                            ),
                          );
                          onResult?.call(result);
                        },
                        child: const Text('انتخاب تاریخ'),
                      ),
                    ),
                  ),
                );
              },
              child: const Text('باز کردن'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('باز کردن'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('انتخاب تاریخ'));
    await tester.pumpAndSettle();
  }

  testWidgets('full weekday titles RTL and explicit holiday date selection', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    DateTime? result;
    final date = JalaliDate(1405, 1, 1);
    await open(tester, date: date, onResult: (value) => result = value);
    for (final name in PersianDateFormatter.compactWeekdayNames) {
      expect(find.text(name), findsOneWidget);
    }
    expect(
      tester.getCenter(find.text('ش')).dx,
      greaterThan(tester.getCenter(find.text('ج')).dx),
    );
    final day = find.byKey(const ValueKey('capture-date-1'));
    expect(tester.getSemantics(day).label, contains('شنبه'));
    expect(tester.getSemantics(day).label, contains('۱۴۰۵'));
    expect(tester.getSemantics(day).label, contains('تعطیل رسمی'));
    expect(
      find.textContaining('پوشش تعطیلات رسمی این سال کامل نیست'),
      findsNothing,
    );
    await tester.tap(day);
    await tester.pumpAndSettle();
    expect(result, isNull);
    await tester.tap(find.text('تأیید تاریخ'));
    await tester.pumpAndSettle();
    expect(result, date.toDateTime());
    expect(result!.hour, 0);
    expect(find.byType(PlanActJalaliDatePicker), findsNothing);
    semantics.dispose();
  });

  testWidgets(
    'all overlapping typed reasons and provenance; inspection/cancel do not select',
    (tester) async {
      final date = JalaliDate(1405, 1, 7); // Friday.
      final reasons = [
        CalendarHoliday(
          date: date,
          title: 'رسمی آزمون',
          kind: CalendarHolidayKind.officialVariable,
          source: 'validated-package',
          version: 'revision-2',
        ),
        CalendarHoliday(
          date: date,
          title: 'بسته بودن مرکز',
          kind: CalendarHolidayKind.special,
          source: 'durable-closure-fixture',
          version: 'v1',
          scope: 'مرکز آزمون',
        ),
      ];
      final provider = IranianHolidayProvider(
        annualOverrides: {
          1405: [reasons.first],
        },
        specialClosures: [reasons.last],
      );
      var returned = false;
      DateTime? result;
      await open(
        tester,
        date: date,
        provider: provider,
        onResult: (value) {
          returned = true;
          result = value;
        },
      );
      final info = find.byKey(const ValueKey('date-reasons'));
      await tester.ensureVisible(info);
      await tester.tap(info);
      await tester.pumpAndSettle();
      expect(find.text('تعطیلی هفتگی: تعطیلی هفتگی (جمعه)'), findsOneWidget);
      expect(find.text('تعطیل رسمی: رسمی آزمون'), findsOneWidget);
      expect(find.text('تعطیلی خاص: بسته بودن مرکز'), findsOneWidget);
      expect(find.textContaining('validated-package'), findsOneWidget);
      expect(find.textContaining('durable-closure-fixture'), findsOneWidget);
      expect(returned, isFalse);
      expect(provider.holidaysFor(date).length, 3);
      expect(reasons.length, 2);
      await tester.tap(find.text('انصراف'));
      await tester.pumpAndSettle();
      expect(returned, isTrue);
      expect(result, isNull);
      expect(provider.holidaysFor(date).length, 3);
    },
  );

  for (final dark in [false, true]) {
    for (final width in [320.0, 360.0, 430.0]) {
      testWidgets('complete six-row month visible $width dark=$dark', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final month = List.generate(
          12,
          (index) => JalaliDate(1405, index + 1, 1),
        ).firstWhere((date) => date.weekDay - 1 + date.monthLength > 35);
        await open(tester, date: month, dark: dark);
        final grid = tester.getRect(
          find.byKey(const ValueKey('date-picker-grid')),
        );
        final confirm = tester.getRect(find.text('تأیید تاریخ'));
        expect(grid.left, greaterThanOrEqualTo(0));
        expect(grid.right, lessThanOrEqualTo(width));
        expect(grid.top, greaterThanOrEqualTo(0));
        expect(grid.bottom, lessThan(confirm.top));
        for (var day = 1; day <= month.monthLength; day++) {
          final target = find.byKey(ValueKey('capture-date-$day'));
          expect(target.hitTestable(), findsOneWidget);
          expect(tester.getSize(target).height, greaterThanOrEqualTo(48));
        }
        await tester.tap(
          find.byKey(ValueKey('capture-date-${month.monthLength}')),
        );
        await tester.pumpAndSettle();
        expect(find.byType(PlanActJalaliDatePicker), findsOneWidget);
        await tester.tap(find.text('انصراف'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final dark in [false, true]) {
    testWidgets(
      'narrow large text $dark: coverage warning, full headings and standard targets',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await open(tester, date: JalaliDate(1406, 1, 1), dark: dark, scale: 2);
        expect(
          find.textContaining('نبود نشانهٔ تعطیلی به معنی روز کاری قطعی نیست'),
          findsOneWidget,
        );
        final day = find.byKey(const ValueKey('capture-date-1'));
        await tester.ensureVisible(day);
        await tester.pumpAndSettle();
        final grid = tester.getRect(
          find.byKey(const ValueKey('date-picker-grid')),
        );
        final dialog = tester.getRect(find.byType(AlertDialog));
        expect(grid.left, greaterThanOrEqualTo(dialog.left));
        expect(grid.right, lessThanOrEqualTo(dialog.right));
        expect(grid.width, lessThanOrEqualTo(320));
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is SingleChildScrollView &&
                widget.scrollDirection == Axis.horizontal,
          ),
          findsNothing,
        );
        expect(tester.getSize(day).height, greaterThanOrEqualTo(48));
        for (final name in PersianDateFormatter.compactWeekdayNames) {
          expect(find.text(name), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
}
