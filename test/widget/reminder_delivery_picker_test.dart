import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/features/reminders/domain/reminder.dart';
import 'package:planact/features/reminders/presentation/reminder_delivery_picker.dart';

void main() {
  for (final dark in [false, true]) {
    testWidgets(
      'alarm choice wraps at 320 logical pixels and text scale 2, dark=$dark',
      (tester) async {
        tester.view.physicalSize = const Size(320, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var value = ReminderDelivery.notification;
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? PlanActTheme.dark() : PlanActTheme.light(),
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(
                body: MediaQuery(
                  data: const MediaQueryData(textScaler: TextScaler.linear(2)),
                  child: StatefulBuilder(
                    builder: (context, setState) => SingleChildScrollView(
                      child: ReminderDeliveryPicker(
                        value: value,
                        onChanged: (next) => setState(() => value = next),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.widgetWithText(ChoiceChip, 'آلارم'));
        await tester.pumpAndSettle();
        expect(value, ReminderDelivery.alarm);
        expect(find.textContaining('قطع یا تعویق'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
