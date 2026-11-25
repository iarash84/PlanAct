import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/planact_app.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/actuals/data/drift_actual_repository.dart';
import 'package:planact/features/actuals/domain/actual.dart';
import 'package:planact/features/commitments/application/commitment_plan_use_case.dart';
import 'package:planact/features/commitments/data/drift_commitment_plan_repository.dart';
import 'package:planact/features/commitments/data/drift_commitment_repository.dart';
import 'package:planact/features/commitments/domain/commitment.dart'
    show Commitment;
import 'package:planact/features/finance/application/financial_expectation_use_cases.dart';
import 'package:planact/features/finance/data/drift_financial_expectation_repository.dart';
import 'package:planact/features/scheduling/application/occurrence_actions.dart';
import 'package:planact/features/scheduling/presentation/occurrence_action_row.dart';

class _Actuals extends DriftActualRepository {
  _Actuals(super.database);
  bool failRead = false;
  bool failWrite = false;
  @override
  Future<List<Actual>> list() async {
    if (failRead) throw StateError('read failure');
    return super.list();
  }

  @override
  Future<void> mutateTextEvidence({
    required StableId actualId,
    Evidence? expected,
    required String? value,
  }) async {
    if (failWrite) throw StateError('write failure');
    await super.mutateTextEvidence(
      actualId: actualId,
      expected: expected,
      value: value,
    );
  }
}

class _Fixture {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  late final plans = DriftCommitmentPlanRepository(db);
  late final owners = DriftCommitmentRepository(db);
  late final expectations = DriftFinancialExpectationRepository(db);
  late final actuals = _Actuals(db);
  late CommitmentPlan plan;
  int refreshes = 0;
  Commitment? awaitedOwner;
  Future<void> seed() async {
    final now = DateTime.now();
    plan =
        await CreateCommitmentPlan(
          commitments: owners,
          plans: plans,
          financialExpectations: FinancialExpectationUseCases(expectations),
        )(
          title: 'نتیجه و شاهد',
          startAt: DateTime(now.year, now.month, now.day, 10),
        );
    await actuals.recordOccurrenceActual(
      expected: plan.occurrences.single,
      outcome: ActualOutcome.completed,
      recordedAt: now,
      note: 'یادداشت اولیه',
    );
  }

  Future<void> open(
    WidgetTester tester,
    Brightness brightness, {
    double scale = 1,
  }) async {
    awaitedOwner = await tester.runAsync(
      () async => (await owners.findById(plan.commitment.id))!,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: brightness == Brightness.light
            ? PlanActTheme.light()
            : PlanActTheme.dark(),
        builder: (context, child) => Directionality(
          textDirection: TextDirection.rtl,
          child: MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              child: const Text('open'),
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => CommitmentDetailsPage(
                    commitment: (awaitedOwner ?? plan.commitment),
                    repository: owners,
                    planRepository: plans,
                    expectationRepository: expectations,
                    occurrenceExecutor: PersistedOccurrenceActionExecutor(
                      plans: plans,
                      actuals: actuals,
                    ),
                    onSaved: () async {
                      refreshes++;
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byType(OccurrenceActionRow),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find
          .descendant(
            of: find.byType(OccurrenceActionRow).first,
            matching: find.byType(ListTile),
          )
          .first,
    );
    await tester.pumpAndSettle();
  }
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.pumpAndSettle();
  await tester.ensureVisible(finder.last);
  await tester.pumpAndSettle();
  await tester.tap(finder.last);
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
  await tester.pumpAndSettle();
}

Future<void> _save(WidgetTester tester) async {
  await _tap(tester, find.widgetWithText(FilledButton, 'ذخیره'));
  await _tap(tester, find.widgetWithText(FilledButton, 'ذخیره'));
}

void main() {
  testWidgets(
    'Details history read failure retries; cancel writes nothing; failed save retains draft and retries',
    (tester) async {
      final fixture = _Fixture();
      addTearDown(fixture.db.close);
      await tester.runAsync(fixture.seed);
      // Async failure is intentionally delivered through the history future.
      fixture.actuals.failRead = true;
      await fixture.open(tester, Brightness.light);
      expect(find.text('تلاش دوباره برای خواندن سوابق'), findsOneWidget);
      fixture.actuals.failRead = false;
      await _tap(tester, find.text('تلاش دوباره برای خواندن سوابق'));
      await _tap(tester, find.text('افزودن شاهد متنی'));
      await tester.enterText(
        find.byKey(const ValueKey('actual-text-input')),
        'لغو بدون ثبت',
      );
      await _tap(tester, find.widgetWithText(TextButton, 'انصراف'));
      expect(
        (await tester.runAsync(fixture.actuals.list))!.single.evidence,
        isEmpty,
      );
      await _tap(tester, find.text('افزودن شاهد متنی'));
      await tester.enterText(
        find.byKey(const ValueKey('actual-text-input')),
        'متن آزمون ABC 123',
      );
      fixture.actuals.failWrite = true;
      await _save(tester);
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('actual-text-input')))
            .controller!
            .text,
        'متن آزمون ABC 123',
      );
      expect(find.textContaining('ذخیره نشد'), findsOneWidget);
      fixture.actuals.failWrite = false;
      await _save(tester);
      expect(
        (await tester.runAsync(fixture.actuals.list))!
            .single
            .evidence
            .single
            .value,
        'متن آزمون ABC 123',
      );
      expect(find.text('یادداشت اولیه'), findsOneWidget);
      await _tap(tester, find.text('ویرایش شاهد متنی'));
      await tester.enterText(
        find.byKey(const ValueKey('actual-text-input')),
        'نسخه دوم',
      );
      await _save(tester);
      await _tap(tester, find.text('کنار گذاشتن متن'));
      await _save(tester);
      final item = (await tester.runAsync(fixture.actuals.list))!
          .single
          .evidence
          .single;
      expect(item.isDiscarded, isTrue);
      expect(item.originalValue, 'متن آزمون ABC 123');
      expect(item.history.length, greaterThanOrEqualTo(2));
      expect(find.text('متن کنارگذاشته‌شده'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Details stale evidence preserves draft and explicitly reloads before retry',
    (tester) async {
      final fixture = _Fixture();
      addTearDown(fixture.db.close);
      await tester.runAsync(() async {
        await fixture.seed();
        final actual = (await fixture.actuals.list()).single;
        await fixture.actuals.mutateTextEvidence(
          actualId: actual.id,
          value: 'نسخه اول',
        );
      });
      await fixture.open(tester, Brightness.light);
      await _tap(tester, find.text('ویرایش شاهد متنی'));
      await tester.enterText(
        find.byKey(const ValueKey('actual-text-input')),
        'پیش‌نویس من',
      );
      await tester.runAsync(() async {
        final actual = (await fixture.actuals.list()).single;
        await fixture.actuals.mutateTextEvidence(
          actualId: actual.id,
          expected: actual.evidence.single,
          value: 'نسخه هم‌زمان',
        );
      });
      await _save(tester);
      expect(find.textContaining('ذخیره نشد'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('actual-text-input')))
            .controller!
            .text,
        'پیش‌نویس من',
      );
      await _tap(tester, find.text('خواندن آخرین نسخه'));
      expect(find.text('نسخه هم‌زمان'), findsOneWidget);
      await _save(tester);
      expect(
        (await tester.runAsync(fixture.actuals.list))!
            .single
            .evidence
            .single
            .value,
        'پیش‌نویس من',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Details earlier result evidence remains independently editable after reopening',
    (tester) async {
      final fixture = _Fixture();
      addTearDown(fixture.db.close);
      late Actual earlier;
      await tester.runAsync(() async {
        await fixture.seed();
        earlier = (await fixture.actuals.list()).single;
        await fixture.actuals.mutateTextEvidence(
          actualId: earlier.id,
          value: 'شاهد نتیجه پیشین',
        );
        final current = (await fixture.plans.findByCommitmentId(
          fixture.plan.commitment.id,
        ))!.occurrences.single;
        await fixture.actuals.recordOccurrenceActual(
          expected: current,
          outcome: ActualOutcome.reopened,
          recordedAt: DateTime.now(),
          note: 'نتیجه بازگشایی',
        );
      });
      await fixture.open(tester, Brightness.light);
      expect(find.text('نتیجه بازگشایی'), findsOneWidget);
      await _tap(tester, find.text('ویرایش شاهد متنی'));
      await tester.enterText(
        find.byKey(const ValueKey('actual-text-input')),
        'توضیح تکمیلی پیشین',
      );
      await _save(tester);
      final results = (await tester.runAsync(fixture.actuals.list))!;
      expect(
        results.firstWhere((a) => a.id == earlier.id).evidence.single.value,
        'توضیح تکمیلی پیشین',
      );
      expect(
        results
            .where((a) => a.outcome == ActualOutcome.reopened)
            .single
            .evidence,
        isEmpty,
      );
      await _tap(tester, find.byType(ExpansionTile));
      expect(find.text('شاهد نتیجه پیشین'), findsOneWidget);
      expect(
        find.textContaining('توضیح تکمیلی پیشین'),
        findsAtLeastNWidgets(2),
      );
      expect(tester.takeException(), isNull);
    },
  );

  for (final status in ['paused', 'archived', 'completed']) {
    testWidgets('Details evidence policy for $status', (tester) async {
      final fixture = _Fixture();
      addTearDown(fixture.db.close);
      await tester.runAsync(() async {
        await fixture.seed();
        if (status == 'completed') {
          await fixture.plans.completeCycle(
            cycleId: fixture.plan.cycle.id,
            expectedCycleSet: await fixture.plans.cycleSetToken(
              fixture.plan.commitment.id,
            ),
            completedAt: DateTime.now(),
          );
        } else {
          await fixture.owners.save(
            status == 'paused'
                ? fixture.plan.commitment.pause()
                : fixture.plan.commitment.archive(),
          );
        }
      });
      await fixture.open(tester, Brightness.light);
      if (status == 'completed') {
        expect(find.text('افزودن شاهد متنی'), findsNothing);
      } else {
        await _tap(tester, find.text('افزودن شاهد متنی'));
        await tester.enterText(
          find.byKey(const ValueKey('actual-text-input')),
          'شاهد تاریخی',
        );
        await _save(tester);
        expect(
          (await tester.runAsync(fixture.actuals.list))!
              .single
              .evidence
              .single
              .value,
          'شاهد تاریخی',
        );
      }
      expect(tester.takeException(), isNull);
    });
  }

  for (final brightness in Brightness.values) {
    testWidgets(
      'Details evidence long mixed text 320dp scale2 ${brightness.name}',
      (tester) async {
        tester.view.physicalSize = const Size(320, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final fixture = _Fixture();
        addTearDown(fixture.db.close);
        await tester.runAsync(() async {
          await fixture.seed();
          final actual = (await fixture.actuals.list()).single;
          await fixture.actuals.mutateTextEvidence(
            actualId: actual.id,
            value: List.filled(12, 'شاهد فارسی mixed English 123').join('\n'),
          );
        });
        await fixture.open(tester, brightness, scale: 2);
        expect(find.textContaining('mixed English'), findsOneWidget);
        await _tap(tester, find.text('ویرایش شاهد متنی'));
        expect(find.byKey(const ValueKey('actual-text-input')), findsOneWidget);
        await _tap(tester, find.widgetWithText(TextButton, 'انصراف'));
        expect(tester.takeException(), isNull);
      },
    );
  }
}
