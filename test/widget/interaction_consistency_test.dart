import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/planact_app.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/features/commitments/application/commitment_repository.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/commitments/presentation/commitment_browse_sheet.dart';
import 'package:planact/features/quick_add/presentation/quick_add_sheet.dart';

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
}) async {
  tester.view.physicalSize = const Size(320, 1000);
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
        child: Directionality(textDirection: TextDirection.rtl, child: child!),
      ),
      home: HomeShell(repository: repository),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _open(WidgetTester tester, String title) async {
  await tester.tap(find.byTooltip('گزینه‌های بیشتر'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(title));
  await tester.pumpAndSettle();
}

void main() {
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
      testWidgets(
        'Quick Add stays mounted, stationary and usable across all tabs dark=$dark scale=$scale',
        (tester) async {
          final repository = _Repository();
          await _host(tester, repository, dark: dark, scale: scale);
          final fab = find.byKey(const ValueKey('shell-quick-add'));
          final element = tester.element(fab);
          final rect = tester.getRect(fab);
          for (final label in ['بیشتر', 'تقویم', 'مالی', 'امروز']) {
            await tester.tap(find.text(label).last);
            for (var frame = 0; frame < 6; frame++) {
              await tester.pump(const Duration(milliseconds: 50));
              expect(tester.element(fab), same(element));
              expect(tester.getRect(fab), rect);
              expect(find.byType(FloatingActionButton), findsOneWidget);
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
