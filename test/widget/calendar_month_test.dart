import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/theme/commitment_identity_palette.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/core/localization/persian_date_formatter.dart';
import 'package:planact/core/time/jalali_date.dart';
import 'package:planact/features/calendar/presentation/calendar_commitment_card.dart';
import 'package:planact/features/calendar/presentation/calendar_page.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/reminders/domain/reminder.dart';
import 'package:planact/features/scheduling/domain/occurrence.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';

import 'calendar_commitment_card_test.dart' show occurrence;

Widget host(
  CalendarPage page, {
  Brightness brightness = Brightness.light,
  double scale = 1,
}) => MaterialApp(
  theme: brightness == Brightness.dark
      ? PlanActTheme.dark()
      : PlanActTheme.light(),
  home: MediaQuery(
    data: MediaQueryData(textScaler: TextScaler.linear(scale)),
    child: Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(body: page),
    ),
  ),
);

void size(WidgetTester tester, {double height = 900}) {
  tester.view.physicalSize = Size(320, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void top(WidgetTester tester) {
  tester
      .state<ScrollableState>(find.byType(Scrollable).first)
      .position
      .jumpTo(0);
}

void main() {
  testWidgets('empty weeks stay compact beside a dense week', (tester) async {
    size(tester);
    const date = JalaliDate(1405, 1, 1);
    final items = List.generate(
      4,
      (index) => Commitment.create(title: 'کلاس موسیقی و تمرین گروهی $index'),
    );
    await tester.pumpWidget(
      host(
        CalendarPage(
          commitments: items,
          scheduledDates: {
            for (final item in items) item.id.value: [date.toDateTime()],
          },
          initialDate: date,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final dense = tester.getRect(find.byKey(const ValueKey('calendar-day-1')));
    final empty = tester.getRect(find.byKey(const ValueKey('calendar-day-15')));
    expect(empty.height, inInclusiveRange(48, 64));
    expect(dense.height, greaterThan(empty.height));
    expect(
      tester.getSize(find.byKey(const ValueKey('calendar-month-grid'))).height,
      lessThan(450),
    );
    final position = tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position;
    final offset = position.pixels;
    await tester.tap(find.byKey(const ValueKey('calendar-day-15')));
    await tester.pumpAndSettle();
    expect(
      position.pixels,
      offset,
      reason: 'Day selection must not jump to the list',
    );
    expect(
      tester
          .widget<Semantics>(find.byKey(const ValueKey('calendar-day-15')))
          .properties
          .selected,
      isTrue,
    );
    await tester.scrollUntilVisible(
      find.text('برای این روز تعهدی ثبت نشده است.'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byType(CalendarCommitmentCard), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final brightness in Brightness.values) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'dense Month 320dp $scale $brightness titles, pairs, targets and full day list',
        (tester) async {
          size(tester);
          const date = JalaliDate(1405, 1, 1);
          final items = List.generate(
            8,
            (i) => Commitment.create(
              title: 'کلاس موسیقی و تمرین گروهی شماره $i',
              color: CommitmentColor.values[i],
            ),
          );
          final records = {
            for (var i = 0; i < items.length; i++)
              items[i].id.value: [
                occurrence(
                  LocalDate.fromDateTime(date.toDateTime()),
                  status: OccurrenceStatus
                      .values[i % OccurrenceStatus.values.length],
                ),
              ],
          };
          final reminder = ReminderRule.beforeOccurrence(
            occurrenceId: records[items.first.id.value]!.first.id,
            offset: const Duration(minutes: 15),
          );
          Commitment? opened;
          await tester.pumpWidget(
            host(
              CalendarPage(
                commitments: items,
                scheduledDates: const {},
                initialDate: date,
                monthLoader: (_, _) async => records,
                reminderRules: [reminder],
                onCommitmentTap: (item) => opened = item,
              ),
              brightness: brightness,
              scale: scale,
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final day = find.byKey(const ValueKey('calendar-day-1'));
          final semantics = tester.widget<Semantics>(day).properties;
          for (final item in items) {
            expect(semantics.label, contains(item.title));
          }
          expect(semantics.label, contains('نمایش فهرست روز'));
          final markers = find.descendant(
            of: day,
            matching: find.byWidgetPredicate(
              (w) =>
                  w is Container && w.key.toString().contains('month-title-'),
            ),
          );
          expect(markers, findsNWidgets(2));
          expect(
            find.descendant(of: day, matching: find.text('+۶')),
            findsOneWidget,
          );
          for (final item in items.take(2)) {
            final marker = find.byKey(
              ValueKey('month-title-1-${item.id.value}'),
            );
            final container = tester.widget<Container>(marker);
            final text = tester.widget<Text>(
              find.descendant(of: marker, matching: find.byType(Text)),
            );
            expect(
              (container.decoration as BoxDecoration).color,
              CommitmentIdentityPalette.background(item.color!, brightness),
            );
            expect(
              text.style!.color,
              CommitmentIdentityPalette.foreground(item.color!, brightness),
            );
            expect(text.maxLines, 2);
            expect(
              tester.getSize(marker).height,
              greaterThanOrEqualTo(32 * scale),
            );
          }
          final headings = PersianDateFormatter.weekdayNames
              .map(
                (name) => find.byWidgetPredicate(
                  (w) => w is Semantics && w.properties.label == name,
                ),
              )
              .toList();
          for (var i = 0; i < 7; i++) {
            final rect = tester.getRect(headings[i]);
            expect(rect.left, greaterThanOrEqualTo(0));
            expect(rect.right, lessThanOrEqualTo(320));
            if (i > 0) {
              expect(
                rect.right,
                lessThanOrEqualTo(tester.getRect(headings[i - 1]).left + 0.001),
              );
            }
          }
          for (var d = 1; d <= 31; d++) {
            final target = find.byKey(ValueKey('calendar-day-$d'));
            final rect = tester.getRect(target);
            expect(rect.height, greaterThanOrEqualTo(48));
            expect(rect.left, greaterThanOrEqualTo(0));
            expect(rect.right, lessThanOrEqualTo(320));
          }
          expect(
            find.byWidgetPredicate(
              (w) =>
                  w is Scrollable &&
                  (w.axisDirection == AxisDirection.left ||
                      w.axisDirection == AxisDirection.right),
            ),
            findsNothing,
          );
          expect(find.text('نمایش فهرست روز انتخاب‌شده'), findsNothing);
          final heading = find.text(PersianDateFormatter.relative(date));
          await tester.scrollUntilVisible(
            heading,
            200,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.pumpAndSettle();
          expect(heading, findsOneWidget);
          expect(tester.getRect(heading).top, greaterThanOrEqualTo(0));
          expect(tester.getRect(heading).bottom, lessThanOrEqualTo(900));
          // Scroll through the full list: no loss of full titles or actual history.
          for (var i = 0; i < items.length; i++) {
            final card = find.byKey(
              ValueKey('calendar-commitment-${items[i].id.value}'),
            );
            await tester.scrollUntilVisible(
              card,
              200,
              scrollable: find.byType(Scrollable).first,
            );
            await tester.pumpAndSettle();
            final widget = tester.widget<CalendarCommitmentCard>(
              find.ancestor(
                of: card,
                matching: find.byType(CalendarCommitmentCard),
              ),
            );
            expect(
              widget.occurrences.single,
              records[items[i].id.value]!.single,
            );
            expect(widget.reminderRules, [reminder]);
            expect(
              find.descendant(of: card, matching: find.text(items[i].title)),
              findsOneWidget,
            );
          }
          final last = find.byKey(
            ValueKey('calendar-commitment-${items.last.id.value}'),
          );
          final lastTitle = find.descendant(
            of: last,
            matching: find.text(items.last.title),
          );
          await tester.ensureVisible(lastTitle);
          await tester.pumpAndSettle();
          await tester.tap(lastTitle);
          expect(opened, items.last);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('production half-open range includes the final Jalali day', (
    tester,
  ) async {
    size(tester, height: 1600);
    for (final date in [
      const JalaliDate(1405, 1, 31),
      const JalaliDate(1405, 7, 30),
      const JalaliDate(1405, 12, 29),
      const JalaliDate(1403, 12, 30),
    ]) {
      final item = Commitment.create(title: 'تعهد آخر ماه');
      final last = LocalDate.fromDateTime(date.toDateTime());
      await tester.pumpWidget(
        host(
          CalendarPage(
            key: ValueKey(date),
            commitments: [item],
            scheduledDates: const {},
            initialDate: date,
            monthLoader: (start, endExclusive) async {
              expect(
                start,
                LocalDate.fromDateTime(
                  JalaliDate(date.year, date.month, 1).toDateTime(),
                ),
              );
              expect(endExclusive, last.addDays(1));
              return {
                item.id.value: [occurrence(last)],
              };
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Semantics>(find.byKey(ValueKey('calendar-day-${date.day}')))
            .properties
            .label,
        contains(item.title),
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets(
    'bounded loading, failure retry, stale success/error, today reload and disposal',
    (tester) async {
      size(tester, height: 1600);
      const date = JalaliDate(1405, 12, 29);
      final item = Commitment.create(title: 'تاریخچهٔ محفوظ');
      final requests =
          <(LocalDate, LocalDate, Completer<Map<String, List<Occurrence>>>)>[];
      Future<Map<String, List<Occurrence>>> loader(
        LocalDate start,
        LocalDate end,
      ) {
        final result = Completer<Map<String, List<Occurrence>>>();
        requests.add((start, end, result));
        return result.future;
      }

      await tester.pumpWidget(
        host(
          CalendarPage(
            commitments: [item],
            scheduledDates: {
              item.id.value: [date.toDateTime()],
            },
            initialDate: date,
            monthLoader: loader,
          ),
        ),
      );
      expect(
        requests.single.$1,
        LocalDate.fromDateTime(JalaliDate(1405, 12, 1).toDateTime()),
      );
      expect(
        requests.single.$2,
        LocalDate.fromDateTime(JalaliDate(1406, 1, 1).toDateTime()),
      );
      await tester.ensureVisible(find.text('در حال بارگذاری رخدادهای ماه…'));
      await tester.pump();
      expect(find.text('برای این روز تعهدی ثبت نشده است.'), findsNothing);
      requests[0].$3.completeError(StateError('read failed'));
      await tester.pumpAndSettle();
      expect(find.text('بارگذاری رخدادهای ماه انجام نشد.'), findsOneWidget);
      await tester.tap(find.text('تلاش دوباره'));
      await tester.pump();
      expect(requests.length, 2);
      top(tester);
      await tester.pump();
      await tester.tap(find.byTooltip('ماه بعد'));
      await tester.pump();
      expect(requests.length, 3);
      expect(
        requests.last.$1,
        LocalDate.fromDateTime(JalaliDate(1406, 1, 1).toDateTime()),
      );
      expect(
        requests.last.$2,
        LocalDate.fromDateTime(JalaliDate(1406, 2, 1).toDateTime()),
      );
      requests[1].$3.complete({
        item.id.value: [occurrence(date.toDateTime())],
      });
      requests[2].$3.complete({});
      await tester.pumpAndSettle();
      expect(find.byType(CalendarCommitmentCard), findsNothing);
      expect(
        tester
            .widget<Semantics>(find.byKey(const ValueKey('calendar-day-29')))
            .properties
            .selected,
        isTrue,
      );
      await tester.tap(find.byTooltip('ماه قبل'));
      await tester.pump();
      await tester.tap(find.byTooltip('ماه بعد'));
      await tester.pump();
      requests[3].$3.completeError(StateError('stale error'));
      requests[4].$3.complete({});
      await tester.pumpAndSettle();
      expect(find.text('بارگذاری رخدادهای ماه انجام نشد.'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('calendar-return-today')));
      await tester.pump();
      final today = JalaliDate.now();
      expect(
        requests.last.$1,
        LocalDate.fromDateTime(
          JalaliDate(today.year, today.month, 1).toDateTime(),
        ),
      );
      requests.last.$3.complete({});
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('calendar-return-today')));
      await tester.pump();
      expect(requests.length, 7);
      await tester.pumpWidget(const SizedBox());
      requests.last.$3.completeError(StateError('disposed'));
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'grid rightward NEXT, leftward PREV, threshold, vertical, taps, buttons and year boundary',
    (tester) async {
      size(tester, height: 1600);
      const date = JalaliDate(1405, 12, 29);
      await tester.pumpWidget(
        host(
          CalendarPage(
            commitments: const [],
            scheduledDates: const {},
            initialDate: date,
          ),
        ),
      );
      final day = find.byKey(const ValueKey('calendar-day-10'));
      await tester.tap(day);
      await tester.pumpAndSettle();
      expect(tester.widget<Semantics>(day).properties.selected, isTrue);
      await tester.drag(day, const Offset(0, -80));
      await tester.pumpAndSettle();
      top(tester);
      await tester.pumpAndSettle();
      expect(find.text('اسفند ۱۴۰۵'), findsOneWidget);
      await tester.drag(day, const Offset(30, 0));
      await tester.pumpAndSettle();
      expect(find.text('اسفند ۱۴۰۵'), findsOneWidget);
      await tester.drag(day, const Offset(110, 0));
      await tester.pumpAndSettle();
      expect(find.text('فروردین ۱۴۰۶'), findsOneWidget);
      expect(tester.widget<Semantics>(day).properties.selected, isTrue);
      await tester.drag(day, const Offset(-110, 0));
      await tester.pumpAndSettle();
      expect(find.text('اسفند ۱۴۰۵'), findsOneWidget);
      await tester.drag(find.text('اسفند ۱۴۰۵'), const Offset(110, 0));
      await tester.pumpAndSettle();
      expect(find.text('اسفند ۱۴۰۵'), findsOneWidget);
      await tester.tap(find.byTooltip('ماه بعد'));
      await tester.pumpAndSettle();
      expect(find.text('فروردین ۱۴۰۶'), findsOneWidget);
      await tester.tap(find.byTooltip('ماه قبل'));
      await tester.pumpAndSettle();
      expect(find.text('اسفند ۱۴۰۵'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'legacy fixture fallback and realistic 3000 recorded Month rows',
    (tester) async {
      size(tester, height: 1600);
      const date = JalaliDate(1405, 1, 1);
      final item = Commitment.create(title: 'ثبت قدیمی');
      await tester.pumpWidget(
        host(
          CalendarPage(
            commitments: [item],
            scheduledDates: {
              item.id.value: [date.toDateTime()],
            },
            initialDate: date,
          ),
        ),
      );
      expect(
        tester
            .widget<Semantics>(find.byKey(const ValueKey('calendar-day-1')))
            .properties
            .label,
        contains(item.title),
      );
      final items = List.generate(
        100,
        (i) => Commitment.create(title: 'تعهد $i'),
      );
      final records = {
        for (final item in items)
          item.id.value: List.generate(
            30,
            (d) => occurrence(JalaliDate(1405, 1, d + 1).toDateTime()),
          ),
      };
      final watch = Stopwatch()..start();
      await tester.pumpWidget(
        host(
          CalendarPage(
            key: const ValueKey('volume'),
            commitments: items,
            scheduledDates: const {},
            initialDate: date,
            monthLoader: (_, _) async => records,
          ),
        ),
      );
      await tester.pumpAndSettle();
      watch.stop();
      // Leave room for host scheduling variance; this is not a device benchmark.
      expect(watch.elapsed, lessThan(const Duration(seconds: 10)));
      expect(
        tester
            .widget<Semantics>(find.byKey(const ValueKey('calendar-day-30')))
            .properties
            .label,
        contains('۱۰۰ تعهد'),
      );
      expect(find.text('+۹۸'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );
}
