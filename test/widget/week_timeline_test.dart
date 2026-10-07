import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/features/commitments/presentation/commitment_identity_marker.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/time/jalali_date.dart';
import 'package:planact/features/calendar/application/week_timeline.dart';
import 'package:planact/features/calendar/presentation/calendar_page.dart';
import 'package:planact/features/calendar/presentation/week_timeline_view.dart';
import 'package:planact/features/calendar/domain/holiday_provider.dart';
import 'package:planact/core/localization/persian_date_formatter.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/scheduling/domain/occurrence.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';

void main() {
  for (final dark in [false, true]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'week narrow RTL agenda status/identity/tap dark $dark scale $scale',
        (tester) async {
          tester.view.physicalSize = const Size(320, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final day = WeekTimeline.startOfWeek(JalaliDate(1400, 7, 15));
          final start = day.toDateTime();
          final item = Commitment.create(
            title: 'کلاس موسیقی',
            color: CommitmentColor.rose,
          );
          final occurrences = [
            for (final status in OccurrenceStatus.values)
              Occurrence(
                id: StableId.generate(),
                cycleId: StableId.generate(),
                scheduleDefinitionId: StableId.generate(),
                occurrenceKey: status.name,
                originalScheduledAt: DateTime(
                  start.year,
                  start.month,
                  start.day,
                  8 + status.index,
                ),
                currentScheduledAt: DateTime(
                  start.year,
                  start.month,
                  start.day,
                  8 + status.index,
                ),
                status: status,
              ),
          ];
          Commitment? tapped;
          await tester.pumpWidget(
            MaterialApp(
              theme: dark ? PlanActTheme.dark() : PlanActTheme.light(),
              home: MediaQuery(
                data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Scaffold(
                    body: CalendarPage(
                      commitments: [item],
                      scheduledDates: const {},
                      occurrences: {item.id.value: occurrences},
                      initialDate: day,
                      onCommitmentTap: (value) => tapped = value,
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.tap(find.text('هفته'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final first = find.byKey(
            ValueKey('week-card-${occurrences.first.id.value}'),
          );
          expect(tester.getSize(first).width, greaterThanOrEqualTo(48));
          expect(tester.getSize(first).height, greaterThanOrEqualTo(48));
          expect(
            find.descendant(
              of: first,
              matching: find.byType(CommitmentIdentityMarker),
            ),
            findsOneWidget,
          );
          expect(find.byKey(const ValueKey('week-hour-scroll')), findsNothing);
          expect(find.byKey(const ValueKey('week-body-scroll')), findsNothing);
          await tester.ensureVisible(first);
          await tester.pumpAndSettle();
          await tester.tap(first);
          await tester.pumpAndSettle();
          expect(tapped, item);
          for (final status in OccurrenceStatus.values) {
            await tester.scrollUntilVisible(
              find.byKey(
                ValueKey('week-card-${occurrences[status.index].id.value}'),
              ),
              180,
              scrollable: find.descendant(
                of: find.byKey(const ValueKey('week-agenda-scroll')),
                matching: find.byType(Scrollable),
              ),
            );
            expect(
              find.text(switch (status) {
                OccurrenceStatus.scheduled => 'برنامه‌ریزی‌شده',
                OccurrenceStatus.due => 'موعد رسیده',
                OccurrenceStatus.completed => 'انجام‌شده',
                OccurrenceStatus.skipped => 'عدم حضور',
                OccurrenceStatus.cancelled => 'لغوشده',
                OccurrenceStatus.rescheduled => 'جابه‌جا شده',
                OccurrenceStatus.overdue => 'عقب‌افتاده',
                OccurrenceStatus.deferred => 'موکول شده',
                OccurrenceStatus.pendingDecision => 'نیازمند تصمیم',
              }),
              findsOneWidget,
            );
          }
          expect(tester.takeException(), isNull);
          await tester.tap(find.byTooltip('هفته بعد'));
          await tester.pumpAndSettle();
          expect(
            find.text('برای این هفته رخدادی ثبت نشده است.'),
            findsOneWidget,
          );
          await tester.tap(find.byTooltip('هفته قبل'));
          await tester.pumpAndSettle();
          expect(
            find.byKey(ValueKey('week-card-${occurrences.first.id.value}')),
            findsOneWidget,
          );
          await tester.tap(find.text('بازگشت به امروز'));
          await tester.pumpAndSettle();
          await tester.pump(const Duration(minutes: 2));
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
          await tester.pump(const Duration(minutes: 2));
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  testWidgets('tablet all-day and three point lanes remain separate', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(2600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final day = WeekTimeline.startOfWeek(JalaliDate(1405, 1, 1));
    final date = day.toDateTime();
    final item = Commitment.create(title: 'آزمون');
    Occurrence occurrence(Object start) => Occurrence(
      id: StableId.generate(),
      cycleId: StableId.generate(),
      scheduleDefinitionId: StableId.generate(),
      occurrenceKey: StableId.generate().value,
      originalScheduledAt: start,
      currentScheduledAt: start,
    );
    final allDay = occurrence(LocalDate.fromDateTime(date));
    final points = List.generate(
      3,
      (_) => occurrence(DateTime(date.year, date.month, date.day, 8)),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: PlanActTheme.light(),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: CalendarPage(
              commitments: [item],
              scheduledDates: const {},
              initialDate: day,
              occurrences: {
                item.id.value: [allDay, ...points],
              },
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('هفته'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('week-hour-scroll')), findsOneWidget);
    expect(
      find.byKey(ValueKey('week-card-${allDay.id.value}')),
      findsOneWidget,
    );
    final rects = points
        .map(
          (p) =>
              tester.getRect(find.byKey(ValueKey('week-card-${p.id.value}'))),
        )
        .toList();
    for (var i = 0; i < rects.length; i++) {
      expect(rects[i].width, greaterThanOrEqualTo(48));
      for (var j = i + 1; j < rects.length; j++) {
        expect(rects[i].overlaps(rects[j]), isFalse);
      }
    }
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('async navigation ignores stale completion', (tester) async {
    final requests = <Completer<Map<String, List<Occurrence>>>>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: CalendarPage(
              commitments: const [],
              scheduledDates: const {},
              initialDate: JalaliDate(1405, 1, 1),
              weekLoader: (_) {
                final request = Completer<Map<String, List<Occurrence>>>();
                requests.add(request);
                return request.future;
              },
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('هفته'));
    await tester.pump();
    await tester.tap(find.byTooltip('هفته بعد'));
    await tester.pump();
    expect(requests, hasLength(2));
    requests.last.complete({});
    await tester.pumpAndSettle();
    requests.first.completeError(StateError('stale'));
    await tester.pumpAndSettle();
    expect(find.text('بارگذاری هفته انجام نشد.'), findsNothing);
    expect(find.text('برای این هفته رخدادی ثبت نشده است.'), findsOneWidget);
    final vertical = tester
        .widget<CustomScrollView>(
          find.byKey(const ValueKey('week-agenda-scroll')),
        )
        .controller!;
    expect(vertical.offset, 0);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('current week starts today and earlier days remain accessible', (
    tester,
  ) async {
    final today = JalaliDate.now();
    await tester.pumpWidget(
      MaterialApp(
        theme: PlanActTheme.light(),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: WeekTimelineView(
              date: today,
              commitments: const [],
              occurrences: const {},
              holidays: const IranianHolidayProvider(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final scroll = tester
        .widget<CustomScrollView>(
          find.byKey(const ValueKey('week-agenda-scroll')),
        )
        .controller!;
    final todayHeading = find.text(
      '${PersianDateFormatter.date(today)} · امروز',
    );
    expect(tester.getTopLeft(todayHeading).dy, lessThan(60));
    expect(find.text('برای این هفته رخدادی ثبت نشده است.'), findsOneWidget);
    if (today.weekDay > 1) {
      scroll.jumpTo(scroll.position.minScrollExtent);
      await tester.pumpAndSettle();
      expect(
        find.text(PersianDateFormatter.date(WeekTimeline.startOfWeek(today))),
        findsOneWidget,
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'agenda all-day, equal starts, holidays, sticky headings and add',
    (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final day = WeekTimeline.startOfWeek(JalaliDate(1406, 1, 1));
      final item = Commitment.create(
        title: 'عنوان بلند فارسی برای یک برنامه خوانا بدون کوتاه‌سازی',
      );
      Occurrence occurrence(Object start) => Occurrence(
        id: StableId.generate(),
        cycleId: StableId.generate(),
        scheduleDefinitionId: StableId.generate(),
        occurrenceKey: StableId.generate().value,
        originalScheduledAt: start,
        currentScheduledAt: start,
      );
      final start = day.toDateTime();
      final records = [
        occurrence(LocalDate.fromDateTime(start)),
        occurrence(DateTime(start.year, start.month, start.day, 8)),
        occurrence(DateTime(start.year, start.month, start.day, 8)),
      ];
      var added = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: PlanActTheme.dark(),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: CalendarPage(
                commitments: [item],
                scheduledDates: const {},
                initialDate: day,
                occurrences: {item.id.value: records},
                onAdd: () => added = true,
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('هفته'));
      await tester.pumpAndSettle();
      expect(find.text('تمام‌روز'), findsOneWidget);
      expect(find.text('۰۸:۰۰'), findsNWidgets(2));
      expect(find.textContaining('دادهٔ تعطیلات کامل نیست'), findsWidgets);
      final firstRect = tester.getRect(
        find.byKey(ValueKey('week-card-${records[1].id.value}')),
      );
      final secondRect = tester.getRect(
        find.byKey(ValueKey('week-card-${records[2].id.value}')),
      );
      expect(firstRect.overlaps(secondRect), isFalse);
      final scroll = tester
          .widget<CustomScrollView>(
            find.byKey(const ValueKey('week-agenda-scroll')),
          )
          .controller!;
      scroll.jumpTo(100);
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.text(PersianDateFormatter.date(day))).dy,
        lessThan(220),
      );
      await tester.tap(find.byTooltip('هفته بعد'));
      await tester.pumpAndSettle();
      expect(find.text('برای این هفته رخدادی ثبت نشده است.'), findsOneWidget);
      await tester.tap(find.text('افزودن سریع'));
      expect(added, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('return today resets scrolling within the same current week', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: PlanActTheme.light(),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: CalendarPage(
              commitments: const [],
              scheduledDates: const {},
              initialDate: JalaliDate.now(),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('هفته'));
    await tester.pumpAndSettle();
    final before = tester
        .widget<CustomScrollView>(
          find.byKey(const ValueKey('week-agenda-scroll')),
        )
        .controller!;
    final initialOffset = before.offset;
    before.jumpTo(initialOffset + 120);
    await tester.pump();
    await tester.tap(find.text('بازگشت به امروز'));
    await tester.pumpAndSettle();
    final after = tester
        .widget<CustomScrollView>(
          find.byKey(const ValueKey('week-agenda-scroll')),
        )
        .controller!;
    expect(after.offset, initialOffset);
    expect(tester.takeException(), isNull);
  });

  testWidgets('async loading error retry', (tester) async {
    final pending = Completer<Map<String, List<Occurrence>>>();
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: CalendarPage(
              commitments: const [],
              scheduledDates: const {},
              initialDate: JalaliDate(1405, 1, 1),
              weekLoader: (_) {
                calls++;
                return calls == 1 ? pending.future : Future.value({});
              },
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('هفته'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    pending.completeError(StateError('test'));
    await tester.pumpAndSettle();
    expect(find.text('بارگذاری هفته انجام نشد.'), findsOneWidget);
    await tester.tap(find.text('تلاش دوباره'));
    await tester.pumpAndSettle();
    expect(find.text('برای این هفته رخدادی ثبت نشده است.'), findsOneWidget);
    expect(calls, 2);
    await tester.pumpWidget(const SizedBox());
  });
}
