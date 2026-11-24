import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/planact_app.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/localization/planact_localizations.dart';
import 'package:planact/features/calendar/presentation/planned_occurrence_widgets.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/features/actuals/data/drift_actual_repository.dart';
import 'package:planact/features/actuals/domain/actual.dart';
import 'package:planact/features/capture/presentation/quick_capture_sheet.dart';
import 'package:planact/features/commitments/application/commitment_cycles.dart';
import 'package:planact/features/commitments/application/commitment_plan_use_case.dart';
import 'package:planact/features/commitments/data/drift_commitment_plan_repository.dart';
import 'package:planact/features/commitments/data/drift_commitment_repository.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/finance/application/financial_expectation_use_cases.dart';
import 'package:planact/features/finance/data/drift_financial_expectation_repository.dart';
import 'package:planact/features/scheduling/application/occurrence_actions.dart';
import 'package:planact/features/scheduling/presentation/occurrence_action_row.dart';

class _Fixture {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  late final plans = DriftCommitmentPlanRepository(db);
  late final owners = DriftCommitmentRepository(db);
  late final expectations = DriftFinancialExpectationRepository(db);
  late final create = CreateCommitmentPlan(
    commitments: owners,
    plans: plans,
    financialExpectations: FinancialExpectationUseCases(expectations),
  );
  late CommitmentPlan first;
  CommitmentPlan? second;

  Future<void> seed({bool next = true}) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day, 10);
    first = await create(title: 'تعهد مشترک', startAt: start);
    await DriftActualRepository(db).recordOccurrenceActual(
      expected: first.occurrences.single,
      outcome: ActualOutcome.completed,
      recordedAt: start,
    );
    if (next) {
      await finish();
      second = await create(
        title: 'نباید مالک تازه بسازد',
        startAt: start.add(const Duration(days: 1)),
        newCycle: NewCommitmentCycleContext(
          commitmentId: first.commitment.id,
          expectedCycleSet: await plans.cycleSetToken(first.commitment.id),
        ),
      );
    }
  }

  Future<void> finish() async => plans.completeCycle(
    cycleId: first.cycle.id,
    expectedCycleSet: await plans.cycleSetToken(first.commitment.id),
    completedAt: first.cycle.startDate,
  );

  Future<void> open(WidgetTester tester, Brightness brightness) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: brightness == Brightness.light
            ? PlanActTheme.light()
            : PlanActTheme.dark(),
        builder: (context, child) => Directionality(
          textDirection: TextDirection.rtl,
          child: MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => CommitmentDetailsPage(
                    commitment: first.commitment,
                    repository: owners,
                    planRepository: plans,
                    expectationRepository: expectations,
                    occurrenceExecutor: PersistedOccurrenceActionExecutor(
                      plans: plans,
                    ),
                    onSaved: () async {},
                  ),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }
}

Future<void> show(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    180,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'next-cycle form saves under the same owner and refreshes Details',
    (tester) async {
      final fixture = _Fixture();
      addTearDown(fixture.db.close);
      await tester.runAsync(() async {
        await fixture.seed(next: false);
        await fixture.finish();
      });
      await fixture.open(tester, Brightness.light);
      final create = find.byKey(const ValueKey('cycle-create'));
      await show(tester, create);
      await tester.tap(create);
      await tester.pumpAndSettle();
      final date = find.text('انتخاب تاریخ');
      await tester.ensureVisible(date);
      await tester.tap(date);
      await tester.pumpAndSettle();
      final pickerContext = tester.element(find.byType(AlertDialog));
      await tester.tap(
        find.byTooltip(
          planActL10n(pickerContext).planactJalaliDatePickerBuildTooltip2,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('capture-date-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('تأیید تاریخ'));
      await tester.pumpAndSettle();
      final time = find.text('انتخاب زمان');
      await tester.ensureVisible(time);
      await tester.tap(time);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(TextButton).last);
      await tester.pumpAndSettle();
      final save = find.byKey(const ValueKey('commitment-save-button'));
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pumpAndSettle();
      expect(find.byType(QuickCaptureSheet), findsNothing);
      final cycles = (await tester.runAsync(
        () => fixture.plans.listByCommitmentId(fixture.first.commitment.id),
      ))!;
      expect(cycles, hasLength(2));
      expect(cycles.last.commitment.id, fixture.first.commitment.id);
      expect(cycles.last.commitment.title, 'تعهد مشترک');
      expect(cycles.first.cycle.actualEndDate, isNotNull);
      final selector = find.byWidgetPredicate(
        (widget) =>
            widget is DropdownButtonFormField<StableId> &&
            widget.decoration.labelText == 'دورهٔ انتخابی',
      );
      expect(
        tester.widget<DropdownButtonFormField<StableId>>(selector).initialValue,
        cycles.last.cycle.id,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'stale completion keeps its selected date and rejects the write',
    (tester) async {
      final fixture = _Fixture();
      addTearDown(fixture.db.close);
      await tester.runAsync(() => fixture.seed(next: false));
      await fixture.open(tester, Brightness.light);
      final finish = find.byKey(const ValueKey('cycle-finish'));
      await show(tester, finish);
      await tester.tap(finish);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('cycle-end-date')));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FilledButton).last);
      await tester.pumpAndSettle();
      await tester.runAsync(fixture.finish);
      await tester.tap(find.byKey(const ValueKey('cycle-finish-confirm')));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('cycle-finish-confirm')),
            )
            .onPressed,
        isNotNull,
      );
      expect(
        find.text(
          planActL10n(tester.element(find.byType(AlertDialog))).cycleFailure,
        ),
        findsWidgets,
      );
      await tester.tap(find.text('انصراف').last);
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'fresh paused owner disables cycle actions despite stale route owner',
    (tester) async {
      final fixture = _Fixture();
      addTearDown(fixture.db.close);
      await tester.runAsync(() => fixture.seed());
      await tester.runAsync(
        () => fixture.owners.save(fixture.first.commitment.pause()),
      );
      await fixture.open(tester, Brightness.light);
      expect(
        find.text('برای عملیات دوره، تعهد باید فعال باشد.'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('cycle-create')), findsNothing);
      expect(find.byKey(const ValueKey('cycle-finish')), findsNothing);
      await show(tester, find.byType(PlannedDetailsRange));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 150)),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widgetList<OccurrenceActionRow>(find.byType(OccurrenceActionRow))
            .every((row) => !row.readOnly),
        isTrue,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('explicit Jalali completion refreshes into read-only history', (
    tester,
  ) async {
    final fixture = _Fixture();
    addTearDown(fixture.db.close);
    await tester.runAsync(() => fixture.seed(next: false));
    await fixture.open(tester, Brightness.light);
    final finish = find.byKey(const ValueKey('cycle-finish'));
    await show(tester, finish);
    await tester.tap(finish);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cycle-end-date')));
    await tester.pumpAndSettle();
    // Explicit confirmation accepts the visibly selected Jalali local date.
    await tester.tap(find.byType(FilledButton).last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cycle-finish-confirm')));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pumpAndSettle();
    final saved = await tester.runAsync(
      () => fixture.plans.findByCycleId(fixture.first.cycle.id),
    );
    expect(saved!.cycle.actualEndDate, isNotNull);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('این دوره تاریخی و فقط خواندنی است.'), findsWidgets);
    expect(find.byKey(const ValueKey('cycle-create')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  for (final brightness in Brightness.values) {
    testWidgets(
      'Details cycle selection isolates rows at 320px 2x $brightness',
      (tester) async {
        tester.view.physicalSize = const Size(320, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final fixture = _Fixture();
        addTearDown(fixture.db.close);
        await tester.runAsync(() => fixture.seed());
        await fixture.open(tester, brightness);
        final selector = find.byType(DropdownButtonFormField<dynamic>);
        // Use the semantic field label: unrelated metadata controls remain intact.
        final cycleField = find.byWidgetPredicate(
          (widget) =>
              widget is DropdownButtonFormField &&
              widget.decoration.labelText == 'دورهٔ انتخابی',
        );
        expect(cycleField, findsOneWidget);
        expect(selector, findsNothing);
        tester
            .state<ScrollableState>(find.byType(Scrollable).first)
            .position
            .jumpTo(0);
        await tester.pumpAndSettle();
        await show(tester, cycleField);
        final current = tester.widget<DropdownButtonFormField<StableId>>(
          cycleField,
        );
        expect(current.initialValue, fixture.second!.cycle.id);
        current.onChanged!(fixture.first.cycle.id);
        await tester.pumpAndSettle();
        expect(find.text('این دوره تاریخی و فقط خواندنی است.'), findsWidgets);
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 150)),
        );
        await tester.pumpAndSettle();
        await show(tester, find.byType(PlannedDetailsRange));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 150)),
        );
        await tester.pumpAndSettle();
        await show(tester, find.byType(OccurrenceActionRow));
        final oldRows = tester.widgetList<OccurrenceActionRow>(
          find.byType(OccurrenceActionRow),
        );
        expect(oldRows, isNotEmpty);
        expect(oldRows.every((row) => row.readOnly), isTrue);
        expect(
          oldRows.every(
            (row) => row.occurrence.cycleId == fixture.first.cycle.id,
          ),
          isTrue,
        );
        tester
            .state<ScrollableState>(find.byType(Scrollable).first)
            .position
            .jumpTo(0);
        await tester.pumpAndSettle();
        await show(tester, cycleField);
        tester.widget<DropdownButtonFormField<StableId>>(cycleField).onChanged!(
          fixture.second!.cycle.id,
        );
        await tester.pumpAndSettle();
        final finish = find.byKey(const ValueKey('cycle-finish'));
        await show(tester, finish);
        expect(tester.widget<OutlinedButton>(finish).onPressed, isNull);
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 150)),
        );
        await tester.pumpAndSettle();
        await show(tester, find.byType(PlannedDetailsRange));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 150)),
        );
        await tester.pumpAndSettle();
        await show(tester, find.byType(OccurrenceActionRow));
        final activeRows = tester.widgetList<OccurrenceActionRow>(
          find.byType(OccurrenceActionRow),
        );
        expect(activeRows.every((row) => !row.readOnly), isTrue);
        expect(
          activeRows.every(
            (row) => row.occurrence.cycleId == fixture.second!.cycle.id,
          ),
          isTrue,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  testWidgets(
    'completion cancellation and next-cycle cancellation write nothing',
    (tester) async {
      final fixture = _Fixture();
      addTearDown(fixture.db.close);
      await tester.runAsync(() => fixture.seed(next: false));
      await fixture.open(tester, Brightness.light);
      final before = await tester.runAsync(
        () => fixture.plans.cycleSetToken(fixture.first.commitment.id),
      );
      final finish = find.byKey(const ValueKey('cycle-finish'));
      await show(tester, finish);
      await tester.tap(finish);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('cycle-finish-confirm')),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(find.text('انصراف').last);
      await tester.pumpAndSettle();
      expect(
        await tester.runAsync(
          () => fixture.plans.cycleSetToken(fixture.first.commitment.id),
        ),
        before,
      );
      await tester.runAsync(fixture.finish);
      await tester.pumpWidget(const SizedBox());
      await fixture.open(tester, Brightness.light);
      final create = find.byKey(const ValueKey('cycle-create'));
      await show(tester, create);
      await tester.tap(create);
      await tester.pumpAndSettle();
      expect(find.byType(QuickCaptureSheet), findsOneWidget);
      expect(
        tester
            .widget<QuickCaptureSheet>(find.byType(QuickCaptureSheet))
            .cycleOwner!
            .id,
        fixture.first.commitment.id,
      );
      expect(
        tester
            .widget<DropdownButtonFormField<CommitmentKind>>(
              find.byKey(const ValueKey('commitment-kind-dropdown')),
            )
            .onChanged,
        isNull,
      );
      await tester.tap(find.text('انصراف').last);
      await tester.pumpAndSettle();
      expect(
        await tester.runAsync(
          () => fixture.plans.listByCommitmentId(fixture.first.commitment.id),
        ),
        hasLength(1),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
