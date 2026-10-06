import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/localization/persian_date_formatter.dart';
import 'package:planact/core/presentation/planact_jalali_date_picker.dart';
import 'package:planact/core/time/jalali_date.dart';
import 'package:planact/features/calendar/presentation/calendar_page.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/reminders/domain/reminder.dart';
import 'package:planact/features/reminders/presentation/occurrence_reminders.dart';
import 'package:planact/features/scheduling/domain/occurrence.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';

Occurrence occurrence(Object date) => Occurrence(
  id: StableId.generate(),
  cycleId: StableId.generate(),
  scheduleDefinitionId: StableId.generate(),
  occurrenceKey: StableId.generate().value,
  originalScheduledAt: date,
  currentScheduledAt: date,
);

Widget app(Widget child, {Brightness brightness = Brightness.light}) =>
    MaterialApp(
      theme: ThemeData(brightness: brightness),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(body: child),
      ),
    );

void main() {
  testWidgets('Calendar distinguishes all-day data from midnight time', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final now = DateTime.now();
    final selected = occurrence(LocalDate.fromDateTime(now));
    final commitment = Commitment.create(title: 'تمدید بیمه');
    await tester.pumpWidget(
      app(
        CalendarPage(
          commitments: [commitment],
          scheduledDates: {
            commitment.id.value: [now],
          },
          occurrences: {
            commitment.id.value: [selected],
          },
        ),
      ),
    );
    expect(find.text('تمام‌روز (بدون ساعت) • بدون یادآوری'), findsOneWidget);
    expect(find.textContaining('ساعت ۰۰:۰۰'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'shared picker month controls match Calendar RTL convention and year rollover',
    (tester) async {
      final date = JalaliDate(1405, 1, 10);
      await tester.pumpWidget(
        app(PlanActJalaliDatePicker(initialDate: date.toDateTime())),
      );
      expect(
        tester
            .widget<Icon>(
              find.descendant(
                of: find.byTooltip('ماه قبل'),
                matching: find.byType(Icon),
              ),
            )
            .icon,
        Icons.chevron_left,
      );
      expect(
        tester
            .widget<Icon>(
              find.descendant(
                of: find.byTooltip('ماه بعد'),
                matching: find.byType(Icon),
              ),
            )
            .icon,
        Icons.chevron_right,
      );
      await tester.tap(find.byTooltip('ماه قبل'));
      await tester.pump();
      expect(
        find.text(PersianDateFormatter.month(JalaliDate(1404, 12, 1))),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('ماه بعد'));
      await tester.pump();
      expect(
        find.text(PersianDateFormatter.month(JalaliDate(1405, 1, 1))),
        findsOneWidget,
      );
    },
  );

  for (final brightness in Brightness.values) {
    testWidgets(
      'Calendar shows selected occurrence time and reminders in $brightness',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final now = DateTime.now();
        final selected = occurrence(
          DateTime(now.year, now.month, now.day, 18, 30),
        );
        final next = occurrence(DateTime(now.year, now.month, now.day + 1, 9));
        final commitment = Commitment.create(title: 'کلاس موسیقی');
        await tester.pumpWidget(
          app(
            CalendarPage(
              commitments: [commitment],
              scheduledDates: {
                commitment.id.value: [
                  selected.currentScheduledAt as DateTime,
                  next.currentScheduledAt as DateTime,
                ],
              },
              occurrences: {
                commitment.id.value: [selected, next],
              },
              reminderRules: [
                ReminderRule.beforeOccurrence(
                  occurrenceId: selected.id,
                  offset: const Duration(minutes: 15),
                ),
                ReminderRule.beforeOccurrence(
                  occurrenceId: next.id,
                  offset: const Duration(hours: 2),
                ),
              ],
            ),
            brightness: brightness,
          ),
        );
        expect(
          find.text('ساعت ۱۸:۳۰ • یادآوری: ۱۵ دقیقه قبل از شروع'),
          findsOneWidget,
        );
        expect(find.textContaining('۲ ساعت قبل'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'reminder dialog supports Persian custom minutes and cancelling leaves input untouched',
    (tester) async {
      final selected = occurrence(DateTime(2030, 1, 1, 18));
      await tester.pumpWidget(
        app(
          EditOccurrenceRemindersDialog(occurrence: selected, rules: const []),
        ),
      );
      await tester.enterText(find.byType(TextField), '۴۵');
      await tester.tap(find.text('افزودن یادآوری'));
      await tester.pump();
      expect(find.text('۴۵ دقیقه قبل از شروع'), findsOneWidget);
      await tester.tap(find.byTooltip('حذف این یادآوری'));
      await tester.pump();
      expect(find.text('بدون یادآوری'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
