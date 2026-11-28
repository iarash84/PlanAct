import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/money_unit_scope.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/reconciliation/application/contextual_reconciliation.dart';
import 'package:planact/features/reconciliation/application/relationship_target_reader.dart';
import 'package:planact/features/reconciliation/presentation/relationship_target_browser.dart';
import 'package:planact/features/reconciliation/presentation/relationship_target_paging.dart';
import 'package:planact/features/scheduling/domain/occurrence.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';

class PagedReader implements RelationshipTargetReader {
  PagedReader(this.targets);
  final List<RelationshipTarget> targets;
  final queries = <RelationshipTargetQuery>[];
  bool fail = false;
  final waiting = <String, Completer<RelationshipTargetPage>>{};
  @override
  Future<RelationshipTargetPage> read(
    RelationshipTargetQuery query,
    String currency,
  ) async {
    queries.add(query);
    if (fail) throw StateError('controlled read failure');
    if (waiting.containsKey(query.query)) return waiting[query.query]!.future;
    return pageLocalRelationshipTargets(targets, query);
  }

  @override
  Future<List<RelationshipTarget>> byIds(
    Iterable<StableId> ids,
    String currency,
  ) async => targets.where((t) => ids.contains(t.occurrence.id)).toList();
}

List<RelationshipTarget> targets() {
  final cycle = StableId.generate();
  return List.generate(
    43,
    (i) => RelationshipTarget(
      Commitment.create(
        title: 'کلاس $i',
        description: 'شرح موسیقی $i',
        tags: {'آموزش'},
      ),
      Occurrence(
        id: StableId.generate(),
        cycleId: cycle,
        scheduleDefinitionId: StableId.generate(),
        occurrenceKey: 'slot-$i',
        originalScheduledAt: LocalDate(2026, 11, 1).addDays(i),
        currentScheduledAt: LocalDate(2026, 11, 1).addDays(i),
      ),
      expected: const Money(minorUnits: 1000, currency: 'IRR'),
      allocated: const Money(minorUnits: 200, currency: 'IRR'),
      outstanding: Money(minorUnits: 800 + i, currency: 'IRR'),
      cycleLabel: 'دورهٔ پاییز',
    ),
  );
}

void main() {
  Future<void> show(
    WidgetTester tester,
    PagedReader reader, {
    bool dark = false,
    double scale = 1,
  }) async {
    StableId? selected;
    await tester.pumpWidget(
      MaterialApp(
        theme: dark ? PlanActTheme.dark() : PlanActTheme.light(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: child!,
          ),
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (context, update) => RelationshipTargetBrowser(
                reader: reader,
                targets: const [],
                currency: 'IRR',
                selected: selected,
                onSelected: (id) => update(() => selected = id),
                enabled: true,
                moneyInput: PinnedMoneyInput(MoneyUnitScope.of(context)),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'paged reader selection survives search paging filters and retry',
    (tester) async {
      final data = targets();
      final reader = PagedReader(data);
      await show(tester, reader);
      expect(find.byType(RelationshipTargetCard), findsNWidgets(20));
      await tap(
        tester,
        find.byKey(
          ValueKey('relationship-target-${data.first.occurrence.id.value}'),
        ),
      );
      await tap(tester, find.text('صفحهٔ بعد'));
      expect(reader.queries.last.page, 1);
      expect(
        find.byKey(const ValueKey('relationship-selected')),
        findsOneWidget,
      );
      final search = find.byKey(const ValueKey('relationship-search'));
      await tester.ensureVisible(search);
      await tester.enterText(search, 'موسيقي 42');
      await tester.pumpAndSettle();
      expect(reader.queries.last.page, 0);
      expect(find.byType(RelationshipTargetCard), findsNWidgets(2));
      expect(
        find.byKey(const ValueKey('relationship-selected')),
        findsOneWidget,
      );
      await tap(tester, find.text('فیلترهای هدف'));
      await tester.enterText(
        find.byKey(const ValueKey('relationship-minimum')),
        '900',
      );
      await tap(tester, find.text('اعمال فیلترها'));
      expect(reader.queries.last.minimumOutstanding, 900);
      expect(
        find.byKey(const ValueKey('relationship-selected')),
        findsOneWidget,
      );
      reader.fail = true;
      await tap(tester, find.text('پاک‌کردن فیلترها'));
      expect(
        find.text('هدف‌ها بارگذاری نشدند. دوباره تلاش کنید.'),
        findsOneWidget,
      );
      reader.fail = false;
      await tap(tester, find.text('بازخوانی'));
      expect(
        find.byKey(const ValueKey('relationship-selected')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('date status cycle and four sort controls reach reader query', (
    tester,
  ) async {
    final reader = PagedReader(targets());
    await show(tester, reader);
    await tap(tester, find.text('فیلترهای هدف'));
    await tap(tester, find.text('از تاریخ'));
    expect(find.byType(Dialog), findsOneWidget);
    await tap(
      tester,
      find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(FilledButton),
      ),
    );
    await tap(tester, find.text('اعمال فیلترها'));
    expect(reader.queries.last.from, isNotNull);
    await tap(tester, find.text('پاک‌کردن فیلترها'));
    final occurrence = find.byWidgetPredicate(
      (w) => w is DropdownButtonFormField<OccurrenceStatus>,
    );
    await tap(tester, occurrence);
    await tap(tester, find.text('برنامه‌ریزی‌شده').last);
    expect(reader.queries.last.occurrenceStatus, OccurrenceStatus.scheduled);
    final owner = find.byWidgetPredicate(
      (w) => w is DropdownButtonFormField<CommitmentStatus>,
    );
    await tap(tester, owner);
    await tap(tester, find.text('فعال').last);
    expect(reader.queries.last.commitmentStatus, CommitmentStatus.active);
    final cycle = find.byWidgetPredicate(
      (w) => w is DropdownButtonFormField<StableId>,
    );
    await tap(tester, cycle);
    await tap(tester, find.text('دورهٔ پاییز').last);
    expect(
      reader.queries.last.cycleId,
      reader.targets.first.occurrence.cycleId,
    );
    final sort = find.byWidgetPredicate(
      (w) => w is DropdownButtonFormField<RelationshipTargetSort>,
    );
    for (final entry in {
      'تاریخ: جدیدتر': RelationshipTargetSort.dateDescending,
      'مانده: کمتر': RelationshipTargetSort.amountAscending,
      'مانده: بیشتر': RelationshipTargetSort.amountDescending,
      'تاریخ: قدیمی‌تر': RelationshipTargetSort.dateAscending,
    }.entries) {
      await tap(tester, sort);
      await tap(tester, find.text(entry.key).last);
      expect(reader.queries.last.sort, entry.value);
      expect(reader.queries.last.page, 0);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('late search response cannot overwrite newest query', (
    tester,
  ) async {
    final reader = PagedReader(targets());
    await show(tester, reader);
    reader.waiting['old'] = Completer();
    final search = find.byKey(const ValueKey('relationship-search'));
    await tester.enterText(search, 'old');
    await tester.pump();
    await tester.enterText(search, '42');
    await tester.pumpAndSettle();
    expect(find.text('کلاس 42'), findsOneWidget);
    reader.waiting['old']!.complete(
      RelationshipTargetPage(items: const [], total: 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('کلاس 42'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  for (final dark in [false, true]) {
    testWidgets('320dp RTL scale 2 rich cards and filters dark=$dark', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final reader = PagedReader(targets().take(1).toList());
      await show(tester, reader, dark: dark, scale: 2);
      await tap(tester, find.text('فیلترهای هدف'));
      await tap(tester, find.text('اعمال فیلترها'));
      await tester.ensureVisible(find.byType(RelationshipTargetCard));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.textContaining('مبلغ مورد انتظار:'), findsOneWidget);
      expect(find.text('#آموزش'), findsOneWidget);
      expect(
        Directionality.of(tester.element(find.byType(RelationshipTargetCard))),
        TextDirection.rtl,
      );
    });
  }
  test('local compatibility uses all tokens description tags bounds and deterministic sorts', () {
    final data = targets();
    var page = pageLocalRelationshipTargets(
      data,
      const RelationshipTargetQuery(
        query: 'آموزش موسيقي',
        minimumOutstanding: 820,
        maximumOutstanding: 825,
        sort: RelationshipTargetSort.amountDescending,
      ),
    );
    expect(page.total, 6);
    expect(page.items.first.outstanding!.minorUnits, 825);
    page = pageLocalRelationshipTargets(
      data,
      const RelationshipTargetQuery(page: 2),
    );
    expect(page.items, hasLength(3));
  });
}
