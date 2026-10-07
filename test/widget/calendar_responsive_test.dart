import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/core/localization/persian_date_formatter.dart';
import 'package:planact/core/time/jalali_date.dart';
import 'package:planact/features/calendar/presentation/calendar_page.dart';

void main() {
  for (final width in [320.0, 360.0, 390.0]) {
    for (final scale in [1.0, 2.0]) {
      for (final dark in [false, true]) {
        testWidgets('calendar fits $width RTL scale $scale dark $dark', (
          tester,
        ) async {
          tester.view.physicalSize = Size(width, 800);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tester.pumpWidget(
            MaterialApp(
              theme: dark ? PlanActTheme.dark() : PlanActTheme.light(),
              home: MediaQuery(
                data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Scaffold(
                    body: CalendarPage(
                      commitments: const [],
                      scheduledDates: const {},
                      initialDate: JalaliDate(1405, 1, 1),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(
            find.byWidgetPredicate(
              (w) =>
                  w is Scrollable &&
                  (w.axisDirection == AxisDirection.left ||
                      w.axisDirection == AxisDirection.right),
            ),
            findsNothing,
          );
          final headings = PersianDateFormatter.weekdayNames
              .map(
                (name) => find.byWidgetPredicate(
                  (w) => w is Semantics && w.properties.label == name,
                ),
              )
              .toList();
          for (final heading in headings) {
            expect(heading, findsOneWidget);
            final rect = tester.getRect(heading);
            expect(rect.left, greaterThanOrEqualTo(0));
            expect(rect.right, lessThanOrEqualTo(width));
          }
          for (var index = 1; index < 7; index++) {
            expect(
              tester.getCenter(headings[index]).dx,
              lessThan(tester.getCenter(headings[index - 1]).dx),
            );
          }
          // Every date, including both outer columns, can be selected using
          // vertical scrolling only. Selection retains full Persian semantics.
          for (var day = 1; day <= 31; day++) {
            final target = find.byKey(ValueKey('calendar-day-$day'));
            await tester.ensureVisible(target);
            await tester.pumpAndSettle();
            final rect = tester.getRect(target);
            expect(rect.left, greaterThanOrEqualTo(0));
            expect(rect.right, lessThanOrEqualTo(width));
            expect(rect.height, greaterThanOrEqualTo(48));
            await tester.tap(target);
            await tester.pumpAndSettle();
            final semantics = tester.widget<Semantics>(target).properties;
            expect(semantics.selected, isTrue);
            expect(
              semantics.label,
              contains(PersianDateFormatter.date(JalaliDate(1405, 1, day))),
            );
            expect(tester.takeException(), isNull);
          }
          // The lazy outer list may dispose its header after scrolling down.
          tester
              .state<ScrollableState>(find.byType(Scrollable).first)
              .position
              .jumpTo(0);
          await tester.pumpAndSettle();
          await tester.tap(find.byTooltip('ماه بعد'));
          await tester.pumpAndSettle();
          expect(find.text('اردیبهشت ۱۴۰۵'), findsOneWidget);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
