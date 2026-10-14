import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/planact_app.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/localization/planact_localizations.dart';
import 'package:planact/features/commitments/application/commitment_progress_reader.dart';
import 'package:planact/features/commitments/data/drift_commitment_plan_repository.dart';
import 'package:planact/features/commitments/data/drift_commitment_repository.dart';
import 'package:planact/features/commitments/domain/counted_commitment_progress.dart';
import 'package:planact/features/commitments/presentation/commitment_progress_section.dart';
import 'package:planact/features/scheduling/domain/occurrence.dart';
import 'package:planact/features/scheduling/presentation/occurrence_action_row.dart';

import '../fixtures/counted_commitment.dart';

class Reader implements CommitmentProgressReader {
  Reader(this.load);
  final Future<CountedCommitmentProgress?> Function() load;
  @override
  Future<CountedCommitmentProgress?> read(StableId id) => load();
}

CountedCommitmentProgress music() {
  final plan = countedPlan();
  return buildCountedCommitmentProgress(
    schedule: plan.schedule,
    occurrences: plan.occurrences,
    settlements: const [],
  )!;
}

Widget app(
  Reader reader, {
  int revision = 0,
  bool dark = false,
  double scale = 1,
}) => MaterialApp(
  locale: const Locale('fa'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  theme: dark ? PlanActTheme.dark() : PlanActTheme.light(),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: Scaffold(
    body: SingleChildScrollView(
      child: CommitmentProgressSection(
        reader: reader,
        commitmentId: owner,
        revision: revision,
      ),
    ),
  ),
);
final owner = StableId.generate();

Future<void> settleIo(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 120)),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final dark in [false, true]) {
    testWidgets(
      'music text alternatives and RTL chart fit 320dp, 2x text, dark=$dark',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 1000));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final semantics = tester.ensureSemantics();
        await tester.pumpWidget(
          app(Reader(() async => music()), dark: dark, scale: 2),
        );
        await tester.pumpAndSettle();
        expect(find.text('انجام‌شده: ۲ نوبت (۵۰٪)'), findsOneWidget);
        expect(find.text('لغوشده: ۱ نوبت (۲۵٪)'), findsOneWidget);
        expect(find.text('باقی‌مانده: ۱ نوبت (۲۵٪)'), findsOneWidget);
        expect(
          find.bySemanticsLabel('انجام‌شده: ۲ نوبت (۵۰٪)'),
          findsOneWidget,
        );
        final done = find.byKey(const ValueKey('outcome-segment-completed'));
        final remaining = find.byKey(
          const ValueKey('outcome-segment-remaining'),
        );
        expect(
          tester.getCenter(done).dx,
          greaterThan(tester.getCenter(remaining).dx),
        );
        expect(tester.getSize(done).width, closeTo(160, 0.1));
        final progress = music();
        await tester.pumpWidget(
          app(
            Reader(
              () async => CountedCommitmentProgress(
                outcomes: progress.outcomes,
                payments: CountedProgress(4, {
                  ProgressPart.completed: 2,
                  ProgressPart.partial: 1,
                  ProgressPart.unknown: 1,
                }),
                excludedCancellations: 0,
                ambiguous: false,
              ),
            ),
            dark: dark,
            scale: 2,
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('پرداخت جزئی: ۱ نوبت (۲۵٪)'), findsOneWidget);
        expect(find.text('وضعیت پرداخت نامشخص: ۱ نوبت (۲۵٪)'), findsOneWidget);
        expect(tester.takeException(), isNull);
        semantics.dispose();
      },
    );
  }

  testWidgets(
    'refresh retains chart, discloses errors, retries and ignores late reads; absent count hides chart',
    (tester) async {
      final requests = <Completer<CountedCommitmentProgress?>>[];
      final reader = Reader(() {
        final request = Completer<CountedCommitmentProgress?>();
        requests.add(request);
        return request.future;
      });
      await tester.pumpWidget(app(reader));
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      requests[0].complete(music());
      await tester.pumpAndSettle();
      await tester.pumpWidget(app(reader, revision: 1));
      expect(find.text('انجام‌شده: ۲ نوبت (۵۰٪)'), findsOneWidget);
      requests[1].completeError(StateError('read failed'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('نمودار قبلی ممکن است قدیمی باشد'),
        findsOneWidget,
      );
      await tester.tap(find.text('تلاش دوباره'));
      await tester.pump();
      await tester.pumpWidget(app(reader, revision: 2));
      requests[3].complete(null);
      await tester.pumpAndSettle();
      requests[2].complete(music());
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('occurrence-progress')), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    },
  );

  testWidgets('loan has exact payment counts and percentages', (tester) async {
    final progress = CountedCommitmentProgress(
      outcomes: CountedProgress(50, {ProgressPart.remaining: 50}),
      payments: CountedProgress(50, {
        ProgressPart.completed: 10,
        ProgressPart.remaining: 40,
      }),
      excludedCancellations: 0,
      ambiguous: false,
    );
    final reader = Reader(() async => progress);
    await tester.pumpWidget(app(reader));
    await tester.pumpAndSettle();
    expect(find.text('پرداخت‌شده: ۱۰ نوبت (۲۰٪)'), findsOneWidget);
    expect(find.text('پرداخت‌نشده: ۴۰ نوبت (۸۰٪)'), findsOneWidget);
    expect(
      find.text('۲۰٪ تسویه‌شده، ۸۰٪ بدون تسویهٔ تأییدشده'),
      findsOneWidget,
    );
  });

  testWidgets(
    'ambiguous history discloses uncertainty without a misleading chart',
    (tester) async {
      final plan = countedPlan(target: 2);
      await tester.pumpWidget(
        app(
          Reader(
            () async => buildCountedCommitmentProgress(
              schedule: plan.schedule,
              occurrences: plan.occurrences,
              settlements: const [],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('درصد قابل اتکا نیست'), findsOneWidget);
      expect(find.byKey(const ValueKey('occurrence-progress')), findsNothing);
    },
  );

  testWidgets(
    'real shell search → Details → confirmed outcome → fresh chart and durable history',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      final plan = countedPlan(statuses: [OccurrenceStatus.scheduled]);
      final commitments = DriftCommitmentRepository(database);
      final plans = DriftCommitmentPlanRepository(database);
      await commitments.save(plan.commitment);
      await plans.save(plan);
      await tester.pumpWidget(PlanActApp(repository: commitments));
      await settleIo(tester);
      await tester.tap(find.byKey(const ValueKey('shell-search')));
      await settleIo(tester);
      await tester.enterText(
        find.byKey(const ValueKey('global-search-query')),
        'موسیقی',
      );
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          ValueKey('search-result-commitment-${plan.commitment.id.value}'),
        ),
      );
      await settleIo(tester);
      expect(find.byType(CommitmentDetailsPage), findsOneWidget);
      expect(find.text('باقی‌مانده: ۴ نوبت (۱۰۰٪)'), findsOneWidget);
      final actionMenu = find.descendant(
        of: find.byType(OccurrenceActionRow).first,
        matching: find.byWidgetPredicate((widget) => widget is PopupMenuButton),
      );
      await tester.scrollUntilVisible(
        actionMenu.hitTestable(),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(actionMenu);
      await tester.pumpAndSettle();
      await tester.tap(find.text('انجام شد / حضور داشت'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('انجام شد'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'تأیید'));
      await settleIo(tester);
      await tester.scrollUntilVisible(
        find.byType(CommitmentProgressSection),
        -400,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('انجام‌شده: ۱ نوبت (۲۵٪)'), findsOneWidget);
      expect(find.text('باقی‌مانده: ۳ نوبت (۷۵٪)'), findsOneWidget);
      final saved = (await plans.findByCommitmentId(plan.commitment.id))!;
      expect(
        saved.occurrences.where((o) => o.status == OccurrenceStatus.completed),
        hasLength(1),
      );
      expect(await database.select(database.actuals).get(), hasLength(1));
    },
  );
}
