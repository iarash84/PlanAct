import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/core/localization/persian_date_formatter.dart';
import 'package:planact/core/time/jalali_date.dart';
import 'package:planact/core/presentation/planact_jalali_date_picker.dart';
import 'package:planact/features/calendar/presentation/calendar_page.dart';
import 'package:planact/features/calendar/presentation/week_timeline_view.dart';

void main() {
  for (final dark in [false, true]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'Calendar controls and Week date confirm/cancel RTL 320/390dp scale=$scale dark=$dark',
        (tester) async {
          // The test font has wider Persian glyphs than a shaped device font.
          // Verify a sufficient-width row, then the narrow-screen fallback.
          final width = scale == 1 ? 390.0 : 320.0;
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          const initial = JalaliDate(1405, 12, 20);
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
              home: const Scaffold(
                body: CalendarPage(
                  commitments: [],
                  scheduledDates: {},
                  initialDate: initial,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final today = find.byKey(const ValueKey('calendar-return-today'));
          final picker = find.byKey(const ValueKey('calendar-pick-date'));
          expect(find.text('امروز'), findsOneWidget);
          expect(picker, findsNothing);
          expect(find.text('نمایش فهرست روز انتخاب‌شده'), findsNothing);
          await tester.tap(find.text('هفته'));
          await tester.pumpAndSettle();
          final todayRect = tester.getRect(today);
          final pickerRect = tester.getRect(picker);
          for (final rect in [todayRect, pickerRect]) {
            expect(rect.left, greaterThanOrEqualTo(0));
            expect(rect.right, lessThanOrEqualTo(width));
            expect(rect.width, greaterThanOrEqualTo(48));
            expect(rect.height, greaterThanOrEqualTo(48));
          }
          if (scale == 1) {
            expect(todayRect.top, pickerRect.top);
            expect(todayRect.left, greaterThanOrEqualTo(pickerRect.right));
          } else {
            expect(pickerRect.top, greaterThanOrEqualTo(todayRect.bottom));
          }
          tester.view.physicalSize = const Size(320, 900);
          await tester.pumpAndSettle();
          for (final action in [today, picker]) {
            final rect = tester.getRect(action);
            expect(rect.left, greaterThanOrEqualTo(0));
            expect(rect.right, lessThanOrEqualTo(320));
            expect(rect.width, greaterThanOrEqualTo(48));
            expect(rect.height, greaterThanOrEqualTo(48));
          }
          expect(tester.takeException(), isNull);
          final week = find.byType(WeekTimelineView);
          expect(tester.widget<WeekTimelineView>(week).date, initial);
          await tester.tap(picker);
          await tester.pumpAndSettle();
          await tester.tap(find.byTooltip('ماه بعد').last);
          await tester.pumpAndSettle();
          final day = find.byKey(const ValueKey('capture-date-15'));
          await tester.ensureVisible(day);
          await tester.tap(day);
          await tester.pumpAndSettle();
          final cancel = find.text('انصراف');
          await tester.ensureVisible(cancel);
          await tester.tap(cancel);
          await tester.pumpAndSettle();
          expect(find.byType(PlanActJalaliDatePicker), findsNothing);
          expect(tester.widget<WeekTimelineView>(week).date, initial);
          await tester.tap(picker);
          await tester.pumpAndSettle();
          await tester.tap(find.byTooltip('ماه بعد').last);
          await tester.pumpAndSettle();
          await tester.ensureVisible(day);
          await tester.tap(day);
          await tester.pumpAndSettle();
          final confirm = find.text('تأیید تاریخ');
          await tester.ensureVisible(confirm);
          await tester.tap(confirm);
          await tester.pumpAndSettle();
          const selected = JalaliDate(1406, 1, 15);
          expect(tester.widget<WeekTimelineView>(week).date, selected);
          await tester.tap(find.text('ماه'));
          await tester.pumpAndSettle();
          expect(picker, findsNothing);
          expect(
            find.text(PersianDateFormatter.month(selected)),
            findsOneWidget,
          );
          await tester.scrollUntilVisible(
            find.byKey(const ValueKey('calendar-day-15')),
            200,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.pumpAndSettle();
          expect(
            tester
                .widget<Semantics>(
                  find.byKey(const ValueKey('calendar-day-15')),
                )
                .properties
                .selected,
            isTrue,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
    testWidgets(
      'visible Today action restores month and week without mode changes dark=$dark',
      (tester) async {
        tester.view.physicalSize = const Size(320, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final today = JalaliDate.now();
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? PlanActTheme.dark() : PlanActTheme.light(),
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(2)),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Scaffold(
                  body: CalendarPage(
                    commitments: const [],
                    scheduledDates: const {},
                    initialDate: today.addMonths(-2),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.byTooltip('ماه قبل'));
        await tester.pump();
        final button = find.byKey(const ValueKey('calendar-return-today'));
        expect(find.text('امروز'), findsOneWidget);
        expect(find.byKey(const ValueKey('calendar-pick-date')), findsNothing);
        expect(find.text('نمایش فهرست روز انتخاب‌شده'), findsNothing);
        expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
        await tester.tap(button);
        await tester.pumpAndSettle();
        expect(find.text(PersianDateFormatter.month(today)), findsOneWidget);
        expect(
          tester
              .widget<Semantics>(
                find.byKey(ValueKey('calendar-day-${today.day}')),
              )
              .properties
              .selected,
          isTrue,
        );
        expect(
          tester
              .widget<SegmentedButton<bool>>(
                find.byKey(const ValueKey('calendar-mode-toggle')),
              )
              .selected,
          {false},
        );
        await tester.tap(find.text('هفته'));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('هفته بعد'));
        await tester.pump();
        expect(
          tester.widget<WeekTimelineView>(find.byType(WeekTimelineView)).date,
          today.addDays(7),
        );
        await tester.tap(button);
        await tester.pumpAndSettle();
        expect(
          tester.widget<WeekTimelineView>(find.byType(WeekTimelineView)).date,
          today,
        );
        expect(
          tester
              .widget<SegmentedButton<bool>>(
                find.byKey(const ValueKey('calendar-mode-toggle')),
              )
              .selected,
          {true},
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
