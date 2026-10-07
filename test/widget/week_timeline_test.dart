import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/theme/commitment_identity_palette.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/time/jalali_date.dart';
import 'package:planact/features/calendar/application/week_timeline.dart';
import 'package:planact/features/calendar/presentation/calendar_page.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/scheduling/domain/occurrence.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';

void main() {
  for (final dark in [false, true]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'week narrow RTL status/identity/tap/synchronized scroll dark $dark scale $scale',
        (tester) async {
          tester.view.physicalSize = const Size(320, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final day = WeekTimeline.startOfWeek(JalaliDate(1405, 7, 15));
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
            tester.widget<Material>(first).color,
            CommitmentIdentityPalette.background(
              CommitmentColor.rose,
              dark ? Brightness.dark : Brightness.light,
            ),
          );
          await tester.ensureVisible(first);
          await tester.pumpAndSettle();
          await tester.tap(first);
          await tester.pumpAndSettle();
          expect(tapped, item);
          for (final status in OccurrenceStatus.values) {
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
          final header = tester
              .widget<SingleChildScrollView>(
                find.byKey(const ValueKey('week-header-scroll')),
              )
              .controller!;
          final body = tester
              .widget<SingleChildScrollView>(
                find.byKey(const ValueKey('week-body-scroll')),
              )
              .controller!;
          body.jumpTo(200);
          await tester.pump();
          expect(header.offset, body.offset);
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
          await tester.tap(find.byTooltip('امروز'));
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
    tester.view.physicalSize = const Size(1600, 1000);
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
        .widget<SingleChildScrollView>(
          find.byKey(const ValueKey('week-hour-scroll')),
        )
        .controller!;
    expect(vertical.offset, 960);
    await tester.pumpWidget(const SizedBox());
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
