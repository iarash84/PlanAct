import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/localization/planact_localizations.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/commitments/application/commitment_plan_use_case.dart';
import 'package:planact/features/commitments/data/drift_commitment_plan_repository.dart';
import 'package:planact/features/commitments/data/drift_commitment_repository.dart';
import 'package:planact/features/finance/application/finance_use_cases.dart';
import 'package:planact/features/finance/data/drift_finance_repository.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/reconciliation/application/contextual_reconciliation.dart';
import 'package:planact/features/reconciliation/application/reconciliation_use_cases.dart';
import 'package:planact/features/reconciliation/data/drift_reconciliation_repository.dart';
import 'package:planact/features/reconciliation/domain/commitment_association.dart';
import 'package:planact/features/reconciliation/presentation/transaction_relationship_page.dart';
import 'package:planact/features/reports/data/drift_reports_reader.dart';
import 'package:planact/features/reports/domain/personal_reports.dart';
import 'package:planact/features/reports/presentation/report_commitment_association_list.dart';
import 'package:planact/features/reports/presentation/reports_page.dart';
import 'package:planact/features/today/application/attention_engine.dart';

class _ControlledFlow extends ContextualReconciliation {
  _ControlledFlow(ContextualReconciliation flow)
    : super(
        finance: flow.finance,
        commitments: flow.commitments,
        plans: flow.plans,
        reconciliation: flow.reconciliation,
      );
  bool fail = false;
  Completer<void>? wait;
  int calls = 0;

  @override
  Future<CommitmentAssociation> associateCommitment({
    required CommitmentAssociation expected,
    required StableId transactionId,
    required StableId? commitmentId,
  }) async {
    calls++;
    if (fail) throw StateError('injected write failure');
    await wait?.future;
    return super.associateCommitment(
      expected: expected,
      transactionId: transactionId,
      commitmentId: commitmentId,
    );
  }
}

void main() {
  late Directory directory;
  late AppDatabase database;
  late DriftCommitmentRepository commitments;
  late DriftCommitmentPlanRepository plans;
  late DriftFinanceRepository finance;
  late DriftReconciliationRepository reconciliation;
  late _ControlledFlow flow;
  late AccountEntry entry;
  late StableId first, second;
  final now = DateTime(2026, 11, 24, 12);
  Object? routeResult;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('association-route-');
    database = AppDatabase.forTesting(
      NativeDatabase(File('${directory.path}/state.sqlite')),
    );
    commitments = DriftCommitmentRepository(database);
    plans = DriftCommitmentPlanRepository(database);
    finance = DriftFinanceRepository(database);
    reconciliation = DriftReconciliationRepository(database);
    flow = _ControlledFlow(
      ContextualReconciliation(
        finance: finance,
        commitments: commitments,
        plans: plans,
        reconciliation: ReconciliationUseCases(reconciliation),
      ),
    );
    final create = CreateCommitmentPlan(commitments: commitments, plans: plans);
    final one = await create(
      title: 'کلاس موسیقی',
      startAt: now.add(const Duration(days: 1)),
    );
    final two = await create(
      title: 'کلاس زبان',
      startAt: now.add(const Duration(days: 2)),
    );
    first = one.cycle.commitmentId;
    second = two.cycle.commitmentId;
    final account = FinancialAccount(
      id: StableId.generate(),
      name: 'حساب آزمون',
      currency: 'IRR',
      type: FinancialAccountType.bank,
    );
    await finance.saveAccount(account);
    entry = await FinanceUseCases(finance).record(
      account: account,
      type: AccountEntryType.expense,
      amount: const Money(minorUnits: 1000, currency: 'IRR'),
      occurredAt: now,
      note: 'پرداخت آزمون',
    );
    routeResult = null;
  });

  tearDown(() async {
    await database.close();
    await directory.delete(recursive: true);
  });

  Future<void> open(
    WidgetTester tester, {
    bool dark = false,
    double scale = 1,
  }) async {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
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
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              child: const Text('open'),
              onPressed: () async {
                routeResult = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => TransactionRelationshipPage(
                      transactionId: entry.id,
                      flow: flow,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<void> select(WidgetTester tester, String title) async {
    ScaffoldMessenger.of(
      tester.element(find.byType(TransactionRelationshipPage)),
    ).removeCurrentSnackBar();
    await tester.pumpAndSettle();
    final dropdown = find.byType(DropdownButtonFormField<StableId>);
    await tester.scrollUntilVisible(
      dropdown,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await Scrollable.ensureVisible(tester.element(dropdown), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(dropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text(title).last);
    await tester.pumpAndSettle();
  }

  Future<void> save(
    WidgetTester tester, {
    bool unlink = false,
    bool confirm = true,
  }) async {
    ScaffoldMessenger.of(
      tester.element(find.byType(TransactionRelationshipPage)),
    ).removeCurrentSnackBar();
    await tester.pumpAndSettle();
    final action = find.byKey(
      ValueKey(unlink ? 'association-unlink' : 'association-save'),
    );
    await Scrollable.ensureVisible(tester.element(action), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(action);
    await tester.pump(const Duration(milliseconds: 400));
    final l10n = planActL10n(tester.element(find.byType(AlertDialog)));
    await tester.tap(
      find.widgetWithText(
        confirm ? FilledButton : TextButton,
        confirm ? l10n.financePageConfirmedActions : l10n.commonCancel,
      ),
    );
    if (flow.wait != null) {
      await tester.pump(const Duration(milliseconds: 400));
    } else {
      await tester.pumpAndSettle();
    }
  }

  Future<void> expectRemainder() async {
    final context = await flow.load(entry.id);
    expect(context.available.minorUnits, 1000);
    expect(context.review!.isIndependent, isFalse);
    expect(await reconciliation.list(), isEmpty);
    final dashboard = const AttentionEngine().buildActionCenter(
      now: now,
      commitments: await commitments.list(),
      plans: const {},
      expectations: const [],
      matches: await reconciliation.list(),
      inboxSuggestions: const [],
      entries: await finance.listEntries(),
      accounts: await finance.listAccounts(),
    );
    expect(
      dashboard.attention.any(
        (item) =>
            item.attentionItem?.id == 'transaction:${entry.id.value}' &&
            item.attentionItem?.amountMinorUnits == 1000,
      ),
      isTrue,
    );
    expect((await finance.listEntries()).length, 1);
  }

  testWidgets(
    'production route create/change/unlink and cancellation preserve Today remainder',
    (tester) async {
      await open(tester);
      await select(tester, 'کلاس موسیقی');
      expect((await flow.load(entry.id)).association!.revision, 0);
      await save(tester, confirm: false);
      expect((await flow.load(entry.id)).association!.revision, 0);
      expect(
        tester
            .widget<DropdownButtonFormField<StableId>>(
              find.byType(DropdownButtonFormField<StableId>),
            )
            .initialValue,
        first,
      );
      await save(tester);
      expect((await flow.load(entry.id)).association!.commitmentId, first);
      await expectRemainder();
      await select(tester, 'کلاس زبان');
      await save(tester, confirm: false);
      expect((await flow.load(entry.id)).association!.commitmentId, first);
      await save(tester);
      expect((await flow.load(entry.id)).association!.commitmentId, second);
      await save(tester, unlink: true, confirm: false);
      expect((await flow.load(entry.id)).association!.commitmentId, second);
      await save(tester, unlink: true);
      final head = (await flow.load(entry.id)).association!;
      expect(head.commitmentId, isNull);
      expect(head.revision, 3);
      await expectRemainder();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(routeResult, true);
      expect(flow.calls, 3);
    },
  );

  testWidgets('navigation with a selected draft writes nothing', (
    tester,
  ) async {
    await open(tester);
    await select(tester, 'کلاس موسیقی');
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(routeResult, isNull);
    expect(flow.calls, 0);
    expect((await flow.load(entry.id)).association!.revision, 0);
  });

  testWidgets('write failure retains draft; refresh and retry use fresh head', (
    tester,
  ) async {
    await open(tester);
    await select(tester, 'کلاس موسیقی');
    flow.fail = true;
    await save(tester);
    final l10n = planActL10n(
      tester.element(find.byType(TransactionRelationshipPage)),
    );
    expect(find.text(l10n.commitmentAssociationError), findsOneWidget);
    expect((await flow.load(entry.id)).association!.revision, 0);
    expect(
      tester
          .widget<DropdownButtonFormField<StableId>>(
            find.byType(DropdownButtonFormField<StableId>),
          )
          .initialValue,
      first,
    );
    // Concurrent durable change makes the page token stale, not the draft.
    final fresh = await flow.load(entry.id);
    await reconciliation.associateCommitment(
      expected: fresh.association!,
      transactionId: entry.id,
      commitmentId: second,
    );
    flow.fail = false;
    await save(tester);
    expect(find.text(l10n.commitmentAssociationError), findsOneWidget);
    final reload = find.widgetWithText(TextButton, l10n.inboxPageBuildTooltip);
    await tester.scrollUntilVisible(
      reload,
      -200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(reload);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<DropdownButtonFormField<StableId>>(
            find.byType(DropdownButtonFormField<StableId>),
          )
          .initialValue,
      first,
    );
    await save(tester);
    expect((await flow.load(entry.id)).association!.commitmentId, first);
    await expectRemainder();
  });

  testWidgets('pending save blocks duplicate action and navigation', (
    tester,
  ) async {
    await open(tester);
    await select(tester, 'کلاس موسیقی');
    flow.wait = Completer<void>();
    await save(tester);
    expect(flow.calls, 1);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('association-save')))
          .onPressed,
      isNull,
    );
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byType(TransactionRelationshipPage), findsOneWidget);
    flow.wait!.complete();
    await tester.pumpAndSettle();
    expect((await flow.load(entry.id)).association!.revision, 1);
  });

  testWidgets(
    'review reconstruction preserves association and selectable commitments',
    (tester) async {
      await open(tester);
      await select(tester, 'کلاس موسیقی');
      await save(tester);
      final l10n = planActL10n(
        tester.element(find.byType(TransactionRelationshipPage)),
      );
      final independent = find.widgetWithText(
        OutlinedButton,
        l10n.transactionRelationshipPageBuildChildren8,
      );
      await tester.scrollUntilVisible(
        independent,
        -200,
        scrollable: find.byType(Scrollable).first,
      );
      ScaffoldMessenger.of(
        tester.element(find.byType(TransactionRelationshipPage)),
      ).removeCurrentSnackBar();
      await tester.pumpAndSettle();
      await tester.tap(independent);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byType(DropdownButtonFormField<StableId>),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.text(l10n.commitmentAssociationCurrent('کلاس موسیقی')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<DropdownButton<StableId>>(
              find.byType(DropdownButton<StableId>),
            )
            .items,
        hasLength(2),
      );
      await select(tester, 'کلاس زبان');
      await save(tester);
      expect((await flow.load(entry.id)).association!.commitmentId, second);
      expect((await flow.load(entry.id)).review!.isIndependent, isTrue);
    },
  );

  testWidgets(
    'narrow dark large-text association and production report remain descriptive',
    (tester) async {
      await open(tester, dark: true, scale: 1.8);
      await select(tester, 'کلاس موسیقی');
      await save(tester);
      expect(tester.takeException(), isNull);
      final filter = ReportFilter(from: now, to: now);
      final reader = DriftReportsReader(database);
      final snapshot = await reader.read(filter, now: now);
      final report = buildPersonalReport(
        snapshot,
        filter,
        kind: PersonalReportKind.overview,
        now: now,
      );
      expect(report.associations, hasLength(1));
      expect(report.settlements, isEmpty);
      await expectRemainder();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await tester.pumpWidget(
        MaterialApp(
          theme: PlanActTheme.dark(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(1.8)),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: child!,
            ),
          ),
          home: ReportsPage(reader: reader, now: now),
        ),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pumpAndSettle();
      expect(find.byType(LinearProgressIndicator), findsNothing);
      final list = find.byType(ReportCommitmentAssociationList);
      await tester.scrollUntilVisible(
        list,
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(list, findsOneWidget);
      final component = tester.widget<ReportCommitmentAssociationList>(list);
      expect(component.associations.single.commitment.id, first);
      final l10n = planActL10n(tester.element(list));
      expect(
        component.descriptiveNotSettlementLabel,
        l10n.commitmentAssociationDisclaimer,
      );
      expect(
        find.descendant(of: list, matching: find.text('کلاس موسیقی')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: list, matching: find.textContaining('۱٬۰۰۰')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
