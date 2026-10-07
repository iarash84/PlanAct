import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/core/localization/persian_date_formatter.dart';
import 'package:planact/core/time/jalali_date.dart';
import 'package:planact/features/calendar/presentation/calendar_page.dart';
import 'package:planact/features/calendar/presentation/week_timeline_view.dart';

void main() {
  for (final dark in [false, true]) {
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
        expect(find.text('بازگشت به امروز'), findsOneWidget);
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
