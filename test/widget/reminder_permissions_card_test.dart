import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/features/reminders/presentation/reminder_permissions_card.dart';

void main() {
  Future<void> show(WidgetTester tester, Future<bool> Function() enable) =>
      tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Directionality(
              textDirection: TextDirection.rtl,
              child: ReminderPermissionsCard(enable: enable),
            ),
          ),
        ),
      );

  testWidgets('permission requests require a tap and cannot overlap', (
    tester,
  ) async {
    final completion = Completer<bool>();
    var calls = 0;
    await show(tester, () {
      calls++;
      return completion.future;
    });
    expect(calls, 0);
    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    expect(calls, 1);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    completion.complete(true);
    await tester.pumpAndSettle();
    expect(
      find.text('مجوزها فعال شدند و یادآوری‌های آینده دوباره زمان‌بندی شدند.'),
      findsOneWidget,
    );
  });

  testWidgets('denial preserves retry and errors are visible', (tester) async {
    var calls = 0;
    await show(tester, () async {
      calls++;
      if (calls == 1) return false;
      throw StateError('platform unavailable');
    });
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('مجوز اعلان یا زنگ دقیق فعال نیست'),
      findsOneWidget,
    );
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(find.textContaining('اطلاعات شما محفوظ است'), findsOneWidget);
    expect(calls, 2);
  });
}
