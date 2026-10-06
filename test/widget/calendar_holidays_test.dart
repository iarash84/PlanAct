import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/time/jalali_date.dart';
import 'package:planact/features/calendar/presentation/calendar_page.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('holiday reasons and coverage warning in $brightness', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      Future<void> show(JalaliDate date) => tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: brightness, useMaterial3: true),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: CalendarPage(
                key: ValueKey(date),
                initialDate: date,
                commitments: const [],
                scheduledDates: const {},
              ),
            ),
          ),
        ),
      );
      await show(const JalaliDate(1404, 1, 1));
      expect(find.text('تعطیل رسمی: آغاز نوروز'), findsOneWidget);
      expect(find.text('تعطیلی هفتگی (جمعه)'), findsOneWidget);
      expect(
        find.textContaining('دادهٔ تعطیلات رسمی این سال کامل نیست'),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
      await show(const JalaliDate(1405, 1, 1));
      expect(
        find.textContaining('دادهٔ تعطیلات رسمی این سال کامل نیست'),
        findsOneWidget,
      );
      expect(find.text('تعطیل رسمی: آغاز نوروز'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
