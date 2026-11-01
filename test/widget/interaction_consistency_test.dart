import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/planact_app.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/features/calendar/presentation/calendar_page.dart';
import 'package:planact/features/calendar/presentation/week_timeline_view.dart';
import 'package:planact/features/commitments/application/commitment_plan_use_case.dart';
import 'package:planact/features/commitments/application/commitment_repository.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/commitments/presentation/commitment_browse_sheet.dart';
import 'package:planact/features/commitments/presentation/commitment_card_layout.dart';
import 'package:planact/features/quick_add/presentation/quick_add_sheet.dart';
import 'package:planact/features/today/presentation/today_page.dart';

class _Repository extends InMemoryCommitmentRepository {
  int writes = 0;
  bool failReads = false;
  @override
  Future<List<Commitment>> list() async {
    if (failReads) throw StateError('fixture read failure');
    return super.list();
  }

  @override
  Future<void> save(Commitment commitment) async {
    writes++;
    await super.save(commitment);
  }
}

Future<void> _host(
  WidgetTester tester,
  _Repository repository, {
  bool dark = false,
  double scale = 1,
  bool reducedMotion = false,
  Size size = const Size(320, 1000),
  TextDirection direction = TextDirection.rtl,
  CommitmentPlanRepository? plans,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: dark ? PlanActTheme.dark() : PlanActTheme.light(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
          disableAnimations: reducedMotion,
          padding: const EdgeInsets.only(top: 24, bottom: 24),
          viewPadding: const EdgeInsets.only(top: 24, bottom: 24),
        ),
        child: Directionality(textDirection: direction, child: child!),
      ),
      home: HomeShell(repository: repository, planRepository: plans),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _scrollToEnd(WidgetTester tester, Finder scrollable) async {
  for (var attempt = 0; attempt < 30; attempt++) {
    final position = tester.state<ScrollableState>(scrollable).position;
    position.jumpTo(position.maxScrollExtent);
    await tester.pumpAndSettle();
    if (position.extentAfter == 0 &&
        (position.pixels - position.maxScrollExtent).abs() < 0.01) {
      return;
    }
  }
  fail('The end of the bounded fixture was not reached.');
}

Future<void> _dismissOccurrenceActions(WidgetTester tester) async {
  final sheet = find.byType(BottomSheet);
  expect(sheet, findsOneWidget);
  expect(
    find.descendant(of: sheet, matching: find.byType(Card)),
    findsOneWidget,
  );
  Navigator.of(tester.element(sheet)).pop();
  await tester.pumpAndSettle();
}

Future<void> _open(WidgetTester tester, String title) async {
  await tester.tap(find.byTooltip('گزینه‌های بیشتر'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(title));
  await tester.pumpAndSettle();
}

void main() {
  for (final direction in TextDirection.values) {
    testWidgets('floating Add follows logical end in $direction', (
      tester,
    ) async {
      await _host(tester, _Repository(), direction: direction);
      final add = tester.getRect(find.byKey(const ValueKey('shell-quick-add')));
      final page = tester.getRect(find.byType(PageView));
      if (direction == TextDirection.rtl) {
        expect(add.center.dx, lessThan(page.center.dx));
      } else {
        expect(add.center.dx, greaterThan(page.center.dx));
      }
      expect(page.bottom, tester.getRect(find.byType(NavigationBar)).top);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'detail opening failure is visible inside the retained panel and row tap retries',
    (tester) async {
      final item = Commitment.create(title: 'تعهد برای تلاش دوباره');
      var attempts = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: PlanActTheme.light(),
          home: Scaffold(
            body: CommitmentBrowseSheet(
              title: 'تاریخچه',
              items: [item],
              subtitle: (_) => 'فعال',
              onRetry: () {},
              onOpen: (_) async {
                attempts++;
                if (attempts == 1) {
                  throw StateError('fixture detail read failure');
                }
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final row = find.byKey(ValueKey('commitment-browse-${item.id.value}'));
      await tester.tap(row);
      await tester.pumpAndSettle();
      expect(
        find.text(
          'نمایش جزئیات انجام نشد؛ برای تلاش دوباره تعهد را انتخاب کنید.',
        ),
        findsOneWidget,
      );
      await tester.ensureVisible(row);
      await tester.tap(row);
      await tester.pumpAndSettle();
      expect(attempts, 2);
      expect(
        find.text(
          'نمایش جزئیات انجام نشد؛ برای تلاش دوباره تعهد را انتخاب کنید.',
        ),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  for (final dark in [false, true]) {
    for (final scale in [1.0, 2.0]) {
      // Populated narrow/large-text journeys have existing row-layout gaps.
      // Keep this data-filled journey at 430dp; shell geometry and Finance
      // separately cover 320dp / doubled text. See the verification record.
      if (scale == 1) {
        testWidgets(
          'last Today, Month, Week and More targets clear floating Add dark=$dark scale=$scale',
          (tester) async {
            final repository = _Repository();
            final plans = InMemoryCommitmentPlanRepository();
            final create = CreateCommitmentPlan(
              commitments: repository,
              plans: plans,
            );
            final now = DateTime.now();
            late Commitment last;
            for (var index = 0; index < 12; index++) {
              last = (await create(
                title: 'تعهد چیدمان $index',
                startAt: DateTime(now.year, now.month, now.day, 12, index),
              )).commitment;
            }
            repository.writes = 0;
            await _host(
              tester,
              repository,
              plans: plans,
              dark: dark,
              scale: scale,
              reducedMotion: true,
              size: const Size(430, 640),
            );
            final add = find.byKey(const ValueKey('shell-quick-add'));
            final addRect = tester.getRect(add);
            void expectClear(Finder target) {
              final rect = tester.getRect(target);
              expect(rect.bottom, lessThanOrEqualTo(addRect.top));
              expect(
                rect.top,
                greaterThanOrEqualTo(tester.getRect(find.byType(PageView)).top),
              );
              expect(target.hitTestable(), findsOneWidget);
            }

            final today = find.byType(TodayPage);
            await _scrollToEnd(
              tester,
              find
                  .descendant(of: today, matching: find.byType(Scrollable))
                  .first,
            );
            final todayRow = find
                .ancestor(
                  of: find.descendant(
                    of: today,
                    matching: find.text(last.title),
                  ),
                  matching: find.byType(CommitmentCardLayout),
                )
                .last;
            final todayAction = find.descendant(
              of: todayRow,
              matching: find.byType(TextButton),
            );
            expectClear(todayAction);
            await tester.tap(todayAction);
            await tester.pumpAndSettle();
            await _dismissOccurrenceActions(tester);

            await tester.tap(find.text('تقویم').last);
            await tester.pumpAndSettle();
            final calendar = find.byType(CalendarPage);
            await _scrollToEnd(
              tester,
              find
                  .descendant(of: calendar, matching: find.byType(Scrollable))
                  .first,
            );
            final monthCard = find.byKey(
              ValueKey('calendar-commitment-${last.id.value}'),
            );
            expectClear(monthCard);
            final monthTitle = find.descendant(
              of: monthCard,
              matching: find.text(last.title),
            );
            await tester.ensureVisible(monthTitle);
            await tester.pumpAndSettle();
            await tester.tap(monthTitle);
            await tester.pumpAndSettle();
            final manageCommitment = find.byKey(
              const ValueKey('occurrence-manage-commitment'),
            );
            expect(manageCommitment, findsOneWidget);
            final occurrenceSheet = find.byType(BottomSheet);
            final occurrenceScroll = find.descendant(
              of: occurrenceSheet,
              matching: find.byType(Scrollable),
            );
            await tester.scrollUntilVisible(
              manageCommitment,
              200,
              scrollable: occurrenceScroll,
            );
            await tester.tap(manageCommitment);
            await tester.pumpAndSettle();
            expect(find.byType(CommitmentDetailsPage), findsOneWidget);
            await tester.enterText(
              find.widgetWithText(TextField, 'عنوان'),
              'تعهد تقویم ویرایش‌شده',
            );
            await tester.scrollUntilVisible(
              find.widgetWithText(FilledButton, 'ذخیره'),
              200,
              scrollable: find.byType(Scrollable).first,
            );
            await tester.tap(
              find.widgetWithText(FilledButton, 'ذخیره'),
              warnIfMissed: true,
            );
            await tester.pumpAndSettle();
            expect(
              (await repository.findById(last.id))!.title,
              'تعهد تقویم ویرایش‌شده',
            );

            await tester.tap(find.text('هفته'));
            await tester.pumpAndSettle();
            final editedWeekRow = find.descendant(
              of: find.byType(WeekTimelineView),
              matching: find.text('تعهد تقویم ویرایش‌شده'),
            );
            final weekScroll = find
                .descendant(
                  of: find.byKey(const ValueKey('week-agenda-scroll')),
                  matching: find.byType(Scrollable),
                )
                .first;
            await tester.scrollUntilVisible(
              editedWeekRow,
              200,
              scrollable: weekScroll,
            );
            await Scrollable.ensureVisible(
              tester.element(editedWeekRow),
              alignment: 0.2,
            );
            await tester.pumpAndSettle();
            expect(editedWeekRow.hitTestable(), findsOneWidget);
            await tester.tap(editedWeekRow);
            await tester.pumpAndSettle();
            final manageFromWeek = find.byKey(
              const ValueKey('occurrence-manage-commitment'),
            );
            final sheetScroll = find.descendant(
              of: find.byType(BottomSheet),
              matching: find.byType(Scrollable),
            );
            if (sheetScroll.evaluate().isNotEmpty) {
              await tester.scrollUntilVisible(
                manageFromWeek,
                200,
                scrollable: sheetScroll.first,
              );
            }
            await tester.ensureVisible(manageFromWeek);
            await tester.pumpAndSettle();
            await tester.tap(manageFromWeek);
            await tester.pumpAndSettle();
            expect(find.byType(CommitmentDetailsPage), findsOneWidget);
            expect(
              find.widgetWithText(TextField, 'تعهد تقویم ویرایش‌شده'),
              findsOneWidget,
            );
            await tester.pageBack();
            await tester.pumpAndSettle();

            await tester.pumpAndSettle();
            final agenda = find.byKey(const ValueKey('week-agenda-scroll'));
            final weekRow = find.descendant(
              of: find.byType(WeekTimelineView),
              matching: find.text('تعهد تقویم ویرایش‌شده'),
            );
            await tester.scrollUntilVisible(
              weekRow,
              200,
              scrollable: find
                  .descendant(of: agenda, matching: find.byType(Scrollable))
                  .first,
            );
            await Scrollable.ensureVisible(
              tester.element(weekRow),
              alignment: 0.2,
            );
            await tester.pumpAndSettle();
            expectClear(weekRow);
            await tester.tap(weekRow);
            await tester.pumpAndSettle();
            await _dismissOccurrenceActions(tester);

            await tester.tap(find.text('بیشتر').last);
            await tester.pumpAndSettle();
            final settings = find.text('تنظیمات');
            final moreList = find.ancestor(
              of: settings,
              matching: find.byType(ListView),
            );
            await _scrollToEnd(
              tester,
              find
                  .descendant(of: moreList, matching: find.byType(Scrollable))
                  .first,
            );
            expectClear(settings);
            await tester.tap(settings);
            await tester.pumpAndSettle();
            expect(find.byType(PageView), findsNothing);
            await tester.pageBack();
            await tester.pumpAndSettle();
            expect(tester.getRect(add), addRect);
            expect(repository.writes, 1);
            expect(tester.takeException(), isNull);
          },
        );
      }

      testWidgets(
        'Quick Add stays mounted, stationary and usable across all tabs dark=$dark scale=$scale',
        (tester) async {
          final repository = _Repository();
          await _host(
            tester,
            repository,
            dark: dark,
            scale: scale,
            reducedMotion: scale == 2,
          );
          final fab = find.byKey(const ValueKey('shell-quick-add'));
          final element = tester.element(fab);
          final rect = tester.getRect(fab);
          void expectFloatingContent() {
            final pageRect = tester.getRect(find.byType(PageView));
            final navigationRect = tester.getRect(find.byType(NavigationBar));
            // Content beside + must continue to navigation, without a reserved
            // full-width action row shortening every tab's viewport.
            expect(pageRect.bottom, navigationRect.top);
            expect(pageRect.overlaps(tester.getRect(fab)), isTrue);
          }

          expectFloatingContent();
          for (final label in ['بیشتر', 'تقویم', 'مالی', 'امروز']) {
            await tester.tap(find.text(label).last);
            for (var frame = 0; frame < 6; frame++) {
              await tester.pump(const Duration(milliseconds: 50));
              expect(tester.element(fab), same(element));
              expect(tester.getRect(fab), rect);
              expect(find.byType(FloatingActionButton), findsOneWidget);
              expectFloatingContent();
            }
            await tester.pumpAndSettle();
          }
          await tester.tap(fab);
          await tester.pumpAndSettle();
          expect(find.byType(QuickAddSheet), findsOneWidget);
          expect(repository.writes, 0);
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        'both browse routes expand, scroll, retain position through details and refresh dark=$dark scale=$scale',
        (tester) async {
          final repository = _Repository();
          for (var i = 0; i < 70; i++) {
            await repository.save(
              Commitment.create(title: 'تعهد ${i.toString().padLeft(2, '0')}'),
            );
          }
          final archived = Commitment.create(title: 'تعهد بایگانی‌شده')
              .archive();
          final completed = Commitment.create(title: 'تعهد انجام‌شده')
              .complete();
          final cancelled = Commitment.create(title: 'تعهد لغوشده').cancel();
          for (final item in [archived, completed, cancelled]) {
            await repository.save(item);
          }
          repository.writes = 0;
          await _host(
            tester,
            repository,
            dark: dark,
            scale: scale,
            reducedMotion: scale == 2,
          );
          for (final history in [false, true]) {
            await _open(
              tester,
              history ? 'تاریخچه و بایگانی تعهدها' : 'خط زمانی تعهدات',
            );
            final sheet = find.byType(CommitmentBrowseSheet);
            final state = tester.state(sheet);
            expect(
              ModalRoute.of(tester.element(sheet))!.transitionDuration,
              scale == 2 ? Duration.zero : const Duration(milliseconds: 220),
            );
            final initialHeight = tester.getSize(sheet).height;
            final contents = tester.widget<CommitmentBrowseSheet>(sheet);
            expect(contents.items.length, history ? 73 : 70);
            expect(contents.items.any((c) => c.id == archived.id), history);
            final title = find.text(contents.title).last;
            // Dragging the pinned heading uses the same scroll controller as rows.
            await tester.drag(title, const Offset(0, -600));
            await tester.pumpAndSettle();
            final draggable = tester.widget<DraggableScrollableSheet>(
              find.byType(DraggableScrollableSheet),
            );
            expect(draggable.controller!.size, closeTo(1, .001));
            expect(tester.getSize(sheet).height, greaterThan(initialHeight));
            final scroll = tester
                .widget<CustomScrollView>(
                  find.byKey(const ValueKey('commitment-browse-scroll')),
                )
                .controller!;
            final titleTop = tester.getTopLeft(title).dy;
            await tester.drag(
              find.byKey(const ValueKey('commitment-browse-scroll')),
              const Offset(0, -650),
            );
            await tester.pumpAndSettle();
            expect(scroll.offset, greaterThan(0));
            expect(tester.getTopLeft(title).dy, titleTop);
            final offset = scroll.offset;
            final row = find
                .descendant(of: sheet, matching: find.byType(ListTile))
                .hitTestable()
                .first;
            final rowKey = tester.widget<ListTile>(row).key!;
            final original = contents.items.firstWhere(
              (c) =>
                  'commitment-browse-${c.id.value}' ==
                  (rowKey as ValueKey).value,
            );
            final wasPaused = original.status == CommitmentStatus.paused;
            await tester.tap(row);
            await tester.pumpAndSettle();
            await tester.scrollUntilVisible(
              find.text('جزئیات و ویرایش'),
              180,
              scrollable: find.byType(Scrollable).last,
            );
            await tester.ensureVisible(find.text('جزئیات و ویرایش'));
            await tester.pumpAndSettle();
            await tester.tap(find.text('جزئیات و ویرایش'));
            await tester.pumpAndSettle();
            expect(find.byType(CommitmentDetailsPage), findsOneWidget);
            await tester.tap(find.byType(BackButton));
            await tester.pumpAndSettle();
            expect(tester.state(sheet), same(state));
            expect(scroll.offset, closeTo(offset, .01));
            expect(draggable.controller!.size, closeTo(1, .001));
            expect(repository.writes, history ? 1 : 0);
            await tester.tap(find.byKey(rowKey));
            await tester.pumpAndSettle();
            await tester.tap(find.text(wasPaused ? 'ادامه' : 'توقف موقت'));
            await tester.pumpAndSettle();
            final current = tester
                .widget<CommitmentBrowseSheet>(sheet)
                .items
                .firstWhere(
                  (c) =>
                      'commitment-browse-${c.id.value}' ==
                      (rowKey as ValueKey).value,
                );
            expect(
              current.status,
              wasPaused ? CommitmentStatus.active : CommitmentStatus.paused,
            );
            expect(
              (await repository.findById(current.id))!.status,
              current.status,
            );
            // One status command per visit; browsing/details/expansion never writes.
            expect(repository.writes, history ? 2 : 1);
            await tester.tap(find.byTooltip('نمایش کوچک‌تر'));
            await tester.pumpAndSettle();
            expect(draggable.controller!.size, closeTo(.6, .001));
            await tester.tap(find.byTooltip('نمایش تمام‌صفحه'));
            await tester.pumpAndSettle();
            expect(find.byType(DraggableScrollableSheet), findsOneWidget);
            await tester.tap(find.byTooltip('بستن'));
            await tester.pumpAndSettle();
            expect(sheet, findsNothing);
            expect(tester.takeException(), isNull);
          }
        },
      );
    }
  }

  testWidgets(
    'browse read failure is distinct from empty and retries in the retained sheet',
    (tester) async {
      final repository = _Repository();
      await repository.save(Commitment.create(title: 'تعهد پس از تلاش مجدد'));
      repository.writes = 0;
      repository.failReads = true;
      await _host(tester, repository);
      await _open(tester, 'خط زمانی تعهدات');
      final sheet = find.byType(CommitmentBrowseSheet);
      final state = tester.state(sheet);
      expect(tester.widget<CommitmentBrowseSheet>(sheet).error, isNotNull);
      repository.failReads = false;
      await tester.tap(
        find.descendant(of: sheet, matching: find.text('تلاش دوباره')),
      );
      await tester.pumpAndSettle();
      expect(tester.state(sheet), same(state));
      expect(tester.widget<CommitmentBrowseSheet>(sheet).error, isNull);
      expect(find.text('تعهد پس از تلاش مجدد'), findsOneWidget);
      expect(repository.writes, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'empty browse sheets expand without list content and system Back closes the same route',
    (tester) async {
      final repository = _Repository();
      await _host(tester, repository, reducedMotion: true);
      for (final title in ['خط زمانی تعهدات', 'تاریخچه و بایگانی تعهدها']) {
        await _open(tester, title);
        expect(find.byType(AlertDialog), findsNothing);
        expect(
          tester
              .widget<CommitmentBrowseSheet>(find.byType(CommitmentBrowseSheet))
              .items,
          isEmpty,
        );
        final heading = tester
            .widget<CommitmentBrowseSheet>(find.byType(CommitmentBrowseSheet))
            .title;
        await tester.drag(find.text(heading).last, const Offset(0, -600));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<DraggableScrollableSheet>(
                find.byType(DraggableScrollableSheet),
              )
              .controller!
              .size,
          1,
        );
        await tester.tap(find.byTooltip('نمایش کوچک‌تر'));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('نمایش تمام‌صفحه'));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<DraggableScrollableSheet>(
                find.byType(DraggableScrollableSheet),
              )
              .controller!
              .size,
          1,
        );
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byType(CommitmentBrowseSheet), findsNothing);
      }
      await _open(tester, 'خط زمانی تعهدات');
      final heading = tester
          .widget<CommitmentBrowseSheet>(find.byType(CommitmentBrowseSheet))
          .title;
      await tester.drag(find.text(heading).last, const Offset(0, 600));
      await tester.pumpAndSettle();
      expect(find.byType(CommitmentBrowseSheet), findsNothing);
      expect(repository.writes, 0);
      expect(tester.takeException(), isNull);
    },
  );
}
