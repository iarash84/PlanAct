import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/theme/commitment_identity_palette.dart';
import 'package:planact/app/theme/planact_status_colors.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/localization/persian_date_formatter.dart';
import 'package:planact/core/time/jalali_date.dart';
import 'package:planact/features/calendar/presentation/calendar_commitment_card.dart';
import 'package:planact/features/calendar/presentation/calendar_page.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/reminders/domain/reminder.dart';
import 'package:planact/features/scheduling/domain/occurrence.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';

Occurrence occurrence(
  Object date, {
  OccurrenceStatus status = OccurrenceStatus.scheduled,
}) => Occurrence(
  id: StableId.generate(),
  cycleId: StableId.generate(),
  scheduleDefinitionId: StableId.generate(),
  occurrenceKey: StableId.generate().value,
  originalScheduledAt: date,
  currentScheduledAt: date,
  status: status,
);

void main() {
  for (final brightness in Brightness.values) {
    final theme = brightness == Brightness.dark
        ? PlanActTheme.dark()
        : PlanActTheme.light();
    Widget host(Widget child, {double scale = 1}) => MaterialApp(
      theme: theme,
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(scale)),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(body: child),
        ),
      ),
    );

    testWidgets(
      '$brightness card preserves identity, separate occurrences and navigation at 320dp / 2x',
      (tester) async {
        tester.view.physicalSize = const Size(320, 1200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final commitment = Commitment.create(
          title: 'کلاس موسیقی و تمرین گروهی',
          color: CommitmentColor.violet,
          tags: {'آموزش'},
        );
        final timed = occurrence(
          DateTime(2026, 3, 21, 18, 30),
          status: OccurrenceStatus.cancelled,
        );
        final allDay = occurrence(LocalDate(2026, 3, 21));
        var tapped = false;
        await tester.pumpWidget(
          host(
            ListView(
              children: [
                CalendarCommitmentCard(
                  commitment: commitment,
                  occurrences: [timed, allDay],
                  reminderRules: [
                    ReminderRule.beforeOccurrence(
                      occurrenceId: timed.id,
                      offset: const Duration(minutes: 15),
                    ),
                  ],
                  onTap: () => tapped = true,
                ),
              ],
            ),
            scale: 2,
          ),
        );
        expect(tester.takeException(), isNull);
        expect(find.byType(Card), findsOneWidget);
        expect(find.text('ساعت ۱۸:۳۰'), findsOneWidget);
        expect(find.text('تمام‌روز (بدون ساعت)'), findsOneWidget);
        expect(find.text('لغوشده'), findsOneWidget);
        expect(find.text('برنامه‌ریزی‌شده'), findsOneWidget);
        expect(find.text('یادآوری: ۱۵ دقیقه قبل از شروع'), findsOneWidget);
        expect(find.text('بدون یادآوری'), findsOneWidget);
        final marker = tester.widget<Container>(
          find.descendant(
            of: find.byKey(
              ValueKey('calendar-identity-${commitment.id.value}'),
            ),
            matching: find.byType(Container),
          ),
        );
        expect(
          (marker.decoration as BoxDecoration).color,
          CommitmentIdentityPalette.background(
            CommitmentColor.violet,
            brightness,
          ),
        );
        await tester.tap(find.text(commitment.title));
        expect(tapped, isTrue);
      },
    );

    testWidgets(
      '$brightness Month and Week use red holiday role without losing selection or reasons',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        const date = JalaliDate(1405, 1, 1);
        final commitment = Commitment.create(
          title: 'کلاس',
          color: CommitmentColor.blue,
        );
        await tester.pumpWidget(
          host(
            CalendarPage(
              commitments: [commitment],
              scheduledDates: {
                commitment.id.value: [date.toDateTime()],
              },
              occurrences: {
                commitment.id.value: [
                  occurrence(LocalDate.fromDateTime(date.toDateTime())),
                ],
              },
              initialDate: date,
            ),
          ),
        );
        final holidayColor = theme.extension<PlanActStatusColors>()!.holiday;
        final day = find.byKey(const ValueKey('calendar-day-1'));
        final numbers = find.descendant(of: day, matching: find.byType(Text));
        expect(tester.widget<Text>(numbers.first).style!.color, holidayColor);
        expect(
          tester
              .widget<Text>(
                find.descendant(of: day, matching: find.text('تعطیل')),
              )
              .style!
              .color,
          holidayColor,
        );
        expect(tester.widget<Semantics>(day).properties.selected, isTrue);
        expect(find.text('تعطیل رسمی: آغاز نوروز'), findsOneWidget);
        expect(find.byType(CalendarCommitmentCard), findsOneWidget);
        final card = tester.widget<CalendarCommitmentCard>(
          find.byType(CalendarCommitmentCard),
        );
        expect(card.commitment.color, CommitmentColor.blue);
        await tester.tap(find.text('هفته'));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<Text>(find.text(PersianDateFormatter.date(date)))
              .style!
              .color,
          holidayColor,
        );
        expect(
          tester.widget<Text>(find.text('آغاز نوروز')).style!.color,
          holidayColor,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '$brightness absent occurrence details do not invent a time or status',
      (tester) async {
        await tester.pumpWidget(
          host(
            CalendarCommitmentCard(
              commitment: Commitment.create(title: 'تعهد قدیمی'),
              occurrences: const [],
              reminderRules: const [],
            ),
          ),
        );
        expect(find.text('جزئیات رخداد در دسترس نیست.'), findsOneWidget);
        expect(find.textContaining('ساعت'), findsNothing);
        expect(find.text('برنامه‌ریزی‌شده'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
