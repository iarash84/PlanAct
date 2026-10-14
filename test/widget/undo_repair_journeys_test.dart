import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/planact_app.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/localization/persian_copy.g.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/core/time/jalali_date.dart';
import 'package:planact/features/commitments/application/commitment_plan_use_case.dart';
import 'package:planact/features/commitments/application/commitment_use_cases.dart';
import 'package:planact/features/commitments/data/drift_commitment_plan_repository.dart';
import 'package:planact/features/commitments/data/drift_commitment_repository.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/finance/application/finance_use_cases.dart';
import 'package:planact/features/finance/application/financial_expectation_use_cases.dart';
import 'package:planact/features/finance/data/drift_finance_repository.dart';
import 'package:planact/features/finance/data/drift_financial_expectation_repository.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/finance/domain/financial_expectation.dart';
import 'package:planact/features/finance/presentation/finance_page.dart';
import 'package:planact/features/reconciliation/application/contextual_reconciliation.dart';
import 'package:planact/features/reconciliation/application/reconciliation_use_cases.dart';
import 'package:planact/features/reconciliation/data/drift_reconciliation_repository.dart';
import 'package:planact/features/reconciliation/domain/reconciliation.dart';
import 'package:planact/features/reconciliation/presentation/transaction_relationship_page.dart';
import 'package:planact/features/reminders/application/reminder_service.dart';
import 'package:planact/features/reminders/data/drift_reminder_repository.dart';
import 'package:planact/features/reminders/domain/reminder.dart';
import 'package:planact/features/scheduling/application/edit_commitment_schedule.dart';
import 'package:planact/features/scheduling/application/occurrence_actions.dart';
import 'package:planact/features/scheduling/application/series_editing.dart';
import 'package:planact/features/actuals/data/drift_actual_repository.dart';
import 'package:planact/features/actuals/domain/actual.dart';
import 'package:planact/features/scheduling/domain/occurrence.dart';
import 'package:planact/features/today/application/attention_engine.dart';
import 'package:planact/features/today/presentation/today_page.dart';

Future<void> settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 80)),
  );
  await tester.pumpAndSettle();
}

Future<void> tapText(WidgetTester tester, String label) async {
  final finder = find.text(label).last;
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await settle(tester);
}

class _ReminderPlatform implements ReminderPlatformAdapter {
  final active = <String, ReminderInstance>{};
  @override
  Future<void> schedule(ReminderInstance instance) async {
    active[instance.id.value] = instance;
  }

  @override
  Future<void> cancel(ReminderInstance instance) async {
    active.remove(instance.id.value);
  }
}

void main() {
  late AppDatabase database;
  late DriftCommitmentRepository commitments;
  late DriftCommitmentPlanRepository plans;
  late DriftFinanceRepository finance;
  late CommitmentPlan plan;
  late FinancialAccount bank;
  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    commitments = DriftCommitmentRepository(database);
    plans = DriftCommitmentPlanRepository(database);
    finance = DriftFinanceRepository(database);
    plan = await CreateCommitmentPlan(commitments: commitments, plans: plans)(
      title: 'class',
      startAt: DateTime.now().add(const Duration(days: 5)),
    );
    bank = FinancialAccount(
      id: StableId.generate(),
      name: 'bank',
      currency: 'IRR',
      type: FinancialAccountType.bank,
    );
    await FinanceUseCases(finance).createAccount(bank);
  });
  tearDown(() async => database.close());

  Future<void> openHistory(WidgetTester tester) async {
    await tester.tap(find.byTooltip('گزینه‌های بیشتر'));
    await settle(tester);
    await tapText(tester, 'تاریخچه و بایگانی تعهدها');
    await tapText(tester, 'class');
  }

  testWidgets(
    'root lifecycle Undo remains reachable after snackbar expires and restores paused archive state',
    (tester) async {
      await PauseCommitment(commitments)(plan.commitment.id);
      await tester.pumpWidget(
        PlanActApp(repository: commitments, planRepository: plans),
      );
      await settle(tester);
      await openHistory(tester);
      await tapText(tester, PersianCopy.planactAppShowCommitmentDetailsTitle5);
      expect(
        (await commitments.findById(plan.commitment.id))!.status,
        CommitmentStatus.archived,
      );
      await tester.pump(const Duration(seconds: 6));
      await settle(tester);
      await openHistory(tester);
      await tapText(tester, PersianCopy.undoStatusAction);
      await tapText(tester, PersianCopy.commonCancel);
      expect(
        (await commitments.findById(plan.commitment.id))!.status,
        CommitmentStatus.archived,
      );
      await openHistory(tester);
      await tapText(tester, PersianCopy.undoStatusAction);
      await tapText(tester, PersianCopy.financePageConfirmedActions);
      expect(
        (await commitments.findById(plan.commitment.id))!.status,
        CommitmentStatus.paused,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'root Finance cancellation refreshes Today unpaid attention for a matched payment',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final due =
          await CreateCommitmentPlan(commitments: commitments, plans: plans)(
            title: 'synthetic arrears',
            startAt: DateTime.now().subtract(const Duration(days: 2)),
          );
      await FinancialExpectationUseCases(
        DriftFinancialExpectationRepository(database),
      ).create(
        occurrenceId: due.occurrences.single.id,
        direction: FinancialExpectationDirection.outgoing,
        amount: 100,
        currency: 'IRR',
      );
      final entry = await FinanceUseCases(finance).record(
        account: bank,
        type: AccountEntryType.expense,
        amount: const Money(minorUnits: 100, currency: 'IRR'),
        occurredAt: DateTime.now(),
      );
      await ContextualReconciliation(
        finance: finance,
        commitments: commitments,
        plans: plans,
        reconciliation: ReconciliationUseCases(
          DriftReconciliationRepository(database),
        ),
      ).confirm(
        transactionId: entry.id,
        occurrenceId: due.occurrences.single.id,
        minorUnits: 100,
      );
      await tester.pumpWidget(
        PlanActApp(repository: commitments, planRepository: plans),
      );
      await settle(tester);
      expect(
        tester
            .widget<TodayPage>(find.byType(TodayPage))
            .dashboard!
            .attention
            .where((a) => a.reason == AttentionReason.overdueUnpaidExpectation),
        isEmpty,
      );
      await tester.tap(find.text('مالی').last);
      await settle(tester);
      final menu = find.byKey(ValueKey('entry-menu:${entry.id.value}'));
      await tester.scrollUntilVisible(
        menu,
        250,
        scrollable: find
            .descendant(
              of: find.byType(FinancePage),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tap(menu);
      await settle(tester);
      await tapText(tester, PersianCopy.financePageConfirmedTitle);
      await tapText(tester, PersianCopy.commonCancel);
      expect((await finance.listEntries()).length, 1);
      await tester.tap(menu);
      await settle(tester);
      await tapText(tester, PersianCopy.financePageConfirmedTitle);
      await tapText(tester, PersianCopy.financePageConfirmedActions);
      await tester.tap(find.text('امروز').last);
      await settle(tester);
      final attention = tester
          .widget<TodayPage>(find.byType(TodayPage))
          .dashboard!
          .attention;
      expect(
        attention
            .singleWhere(
              (a) => a.reason == AttentionReason.overdueUnpaidExpectation,
            )
            .amountMinorUnits,
        100,
      );
      expect(
        find.text(PersianCopy.attentionEngineAttentionActionReconcilePayment),
        findsWidgets,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'Finance cancellation requires confirmation, removes further cancellation, and archive Undo preserves ledger',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final entry = await FinanceUseCases(finance).record(
        account: bank,
        type: AccountEntryType.expense,
        amount: const Money(minorUnits: 100, currency: 'IRR'),
        occurredAt: DateTime.now(),
      );
      var refreshes = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: FinancePage(
            repository: finance,
            onDataChanged: () async {
              refreshes++;
            },
          ),
        ),
      );
      await settle(tester);
      final menu = find.byKey(ValueKey('entry-menu:${entry.id.value}'));
      await tester.scrollUntilVisible(
        menu,
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(menu);
      await tester.tap(menu);
      await settle(tester);
      await tapText(tester, PersianCopy.financePageConfirmedTitle);
      await tapText(tester, PersianCopy.commonCancel);
      expect((await finance.listEntries()).length, 1);
      await tester.tap(menu);
      await settle(tester);
      await tapText(tester, PersianCopy.financePageConfirmedTitle);
      await tapText(tester, PersianCopy.financePageConfirmedActions);
      expect((await FinanceUseCases(finance).balance(bank)).minorUnits, 0);
      expect(refreshes, 1);
      expect(tester.widget<PopupMenuButton<String>>(menu).enabled, false);
      final accountMenu = find.byKey(ValueKey('account-menu:${bank.id.value}'));
      await tester.ensureVisible(accountMenu);
      await tester.tap(accountMenu);
      await settle(tester);
      await tapText(tester, PersianCopy.financeArchivedAccountAction);
      await tapText(tester, PersianCopy.financePageConfirmedActions);
      expect(
        (await finance.listAccounts()).single.status,
        FinancialAccountStatus.archived,
      );
      await tapText(tester, PersianCopy.undoAction);
      await tapText(tester, PersianCopy.financePageConfirmedActions);
      expect(
        (await finance.listAccounts()).single.status,
        FinancialAccountStatus.active,
      );
      expect((await finance.listEntries()).length, 2);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'Finance correction retains its draft on cancel and reports committed state when consumer refresh fails',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final entry = await FinanceUseCases(finance).record(
        account: bank,
        type: AccountEntryType.expense,
        amount: const Money(minorUnits: 100, currency: 'IRR'),
        occurredAt: DateTime.now(),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: FinancePage(
            repository: finance,
            onDataChanged: () async =>
                throw StateError('consumer refresh failed'),
          ),
        ),
      );
      await settle(tester);
      final menu = find.byKey(ValueKey('entry-menu:${entry.id.value}'));
      await tester.scrollUntilVisible(
        menu,
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(menu);
      await settle(tester);
      await tapText(tester, PersianCopy.financeCorrectAction);
      await tester.enterText(
        find.widgetWithText(TextField, 'مبلغ به ریال'),
        '50',
      );
      await tester.tap(
        find.text(PersianCopy.financePageResultPrimaryLabel).last,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tapText(tester, PersianCopy.commonCancel);
      expect((await finance.listEntries()).length, 1);
      expect(find.text('50'), findsOneWidget);
      await tester.tap(
        find.text(PersianCopy.financePageResultPrimaryLabel).last,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tapText(tester, PersianCopy.financePageConfirmedActions);
      expect((await finance.listEntries()).length, 3);
      expect((await FinanceUseCases(finance).balance(bank)).minorUnits, -50);
      expect(find.text(PersianCopy.undoRefreshPending), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'real relationship correction and removal retain historical allocations without changing money',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final entry = await FinanceUseCases(finance).record(
        account: bank,
        type: AccountEntryType.expense,
        amount: const Money(minorUnits: 100, currency: 'IRR'),
        occurredAt: DateTime.now(),
      );
      final reconciliation = ReconciliationUseCases(
        DriftReconciliationRepository(database),
      );
      final flow = ContextualReconciliation(
        finance: finance,
        commitments: commitments,
        plans: plans,
        reconciliation: reconciliation,
      );
      await flow.confirm(
        transactionId: entry.id,
        occurrenceId: plan.occurrences.single.id,
        minorUnits: 100,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: TransactionRelationshipPage(
            transactionId: entry.id,
            flow: flow,
          ),
        ),
      );
      await settle(tester);
      await tapText(tester, PersianCopy.matchHistoryTitle);
      await tapText(tester, PersianCopy.matchCorrectAction);
      await tester.enterText(
        find.widgetWithText(
          TextField,
          '${PersianCopy.matchAmountLabel} (ریال)',
        ),
        '60',
      );
      await tapText(tester, PersianCopy.commonSave);
      await tapText(tester, PersianCopy.commonCancel);
      expect(
        (await reconciliation.repository.list()).single.status,
        MatchStatus.active,
      );
      expect(find.text('60'), findsOneWidget);
      await tapText(tester, PersianCopy.commonSave);
      await tapText(tester, PersianCopy.financePageConfirmedActions);
      final history = await reconciliation.repository.list();
      expect(history.where((m) => m.status == MatchStatus.corrected).length, 1);
      expect(
        history
            .singleWhere((m) => m.status == MatchStatus.active)
            .allocatedMinorUnits,
        60,
      );
      await tapText(tester, PersianCopy.matchRemoveAction);
      await tapText(tester, PersianCopy.financePageConfirmedActions);
      expect((await flow.load(entry.id)).available.minorUnits, 100);
      expect(
        (await reconciliation.repository.list()).every(
          (m) => m.status != MatchStatus.active,
        ),
        true,
      );
      expect((await finance.listEntries()).length, 1);
      expect((await FinanceUseCases(finance).balance(bank)).minorUnits, -100);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  for (final archived in [true, false]) {
    testWidgets(
      'inactive Details date edit saves and refreshes without notifications, archived=$archived',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 1600));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final original = plan.occurrences.single.currentScheduledAt as DateTime;
        final platform = _ReminderPlatform();
        final reminders = ReminderService(
          repository: DriftReminderRepository(database),
          platform: platform,
        );
        await reminders.schedule(
          rule: ReminderRule.atOccurrence(
            occurrenceId: plan.occurrences.single.id,
          ),
          occurrenceStart: original,
        );
        if (archived) {
          await ArchiveCommitment(commitments)(plan.commitment.id);
        } else {
          await PauseCommitment(commitments)(plan.commitment.id);
        }
        await reminders.reconcile(now: DateTime.now());
        var refreshes = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: CommitmentDetailsPage(
              commitment: (await commitments.findById(plan.commitment.id))!,
              repository: commitments,
              planRepository: plans,
              expectationRepository: DriftFinancialExpectationRepository(
                database,
              ),
              occurrenceExecutor: PersistedOccurrenceActionExecutor(
                plans: plans,
                actuals: DriftActualRepository(database),
                reminders: reminders,
              ),
              onSaved: () async {
                refreshes++;
              },
            ),
          ),
        );
        await settle(tester);
        final popup = find.byType(PopupMenuButton<OccurrenceAction>);
        await tester.scrollUntilVisible(
          popup,
          250,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(popup);
        await settle(tester);
        // The underlying row stays busy until the modal editor closes.
        // Pump modal animations without waiting for its progress indicator.
        Future<void> pumpEditor() async {
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));
        }

        await tester.tap(
          find.text(
            PersianCopy.occurrenceActionsAvailableOccurrenceActionsLabel4,
          ),
        );
        await pumpEditor();
        await tester.tap(find.byIcon(Icons.calendar_month_outlined).last);
        await pumpEditor();
        final jalali = JalaliDate.fromDateTime(original);
        final day = jalali.day == 1 ? 2 : jalali.day - 1;
        await tester.tap(find.byKey(ValueKey('capture-date-$day')));
        await pumpEditor();
        await tester.tap(find.text('تأیید تاریخ'));
        await pumpEditor();
        await tester.tap(find.text('ذخیرهٔ زمان'));
        await settle(tester);
        final selected = JalaliDate(
          jalali.year,
          jalali.month,
          day,
        ).toDateTime();
        final current = (await plans.findByCommitmentId(plan.commitment.id))!
            .occurrences
            .single;
        expect(
          current.currentScheduledAt,
          DateTime(
            selected.year,
            selected.month,
            selected.day,
            original.hour,
            original.minute,
          ),
        );
        expect(refreshes, 1);
        expect(platform.active, isEmpty);
        expect(
          (await reminders.repository.listInstances()).where(
            (r) => r.status == ReminderInstanceStatus.scheduled,
          ),
          isEmpty,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  testWidgets(
    'Details shows schedule Undo and partial reopening, preserving actual history',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final originalTime = plan.occurrences.single.currentScheduledAt;
      await EditCommitmentSchedule(plans)(
        commitmentId: plan.commitment.id,
        expected: plan.occurrences.single,
        scheduledAt: (originalTime as DateTime).add(const Duration(days: 1)),
        scope: SeriesEditScope.onlyThis,
        now: DateTime.now(),
      );
      var refreshes = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: CommitmentDetailsPage(
            commitment: plan.commitment,
            repository: commitments,
            planRepository: plans,
            expectationRepository: DriftFinancialExpectationRepository(
              database,
            ),
            occurrenceExecutor: PersistedOccurrenceActionExecutor(
              plans: plans,
              actuals: DriftActualRepository(database),
            ),
            onSaved: () async {
              refreshes++;
            },
          ),
        ),
      );
      await settle(tester);
      await tester.scrollUntilVisible(
        find.text(PersianCopy.undoScheduleAction),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tapText(tester, PersianCopy.undoScheduleAction);
      await tapText(tester, PersianCopy.financePageConfirmedActions);
      expect(
        (await plans.findByCommitmentId(plan.commitment.id))!
            .occurrences
            .single
            .currentScheduledAt,
        originalTime,
      );
      expect(refreshes, 1);
      final current = (await plans.findByCommitmentId(plan.commitment.id))!
          .occurrences
          .single;
      await DriftActualRepository(database).recordOccurrenceActual(
        expected: current,
        outcome: ActualOutcome.partial,
        recordedAt: DateTime.now(),
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        MaterialApp(
          home: CommitmentDetailsPage(
            commitment: plan.commitment,
            repository: commitments,
            planRepository: plans,
            expectationRepository: DriftFinancialExpectationRepository(
              database,
            ),
            occurrenceExecutor: PersistedOccurrenceActionExecutor(
              plans: plans,
              actuals: DriftActualRepository(database),
            ),
            onSaved: () async {
              refreshes++;
            },
          ),
        ),
      );
      await settle(tester);
      final popup = find.byType(PopupMenuButton<OccurrenceAction>);
      await tester.scrollUntilVisible(
        popup,
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(popup);
      await settle(tester);
      await tapText(
        tester,
        PersianCopy.occurrenceActionsAvailableOccurrenceActionsLabel7,
      );
      expect(find.text(PersianCopy.actualReopenMessage), findsOneWidget);
      await tapText(tester, PersianCopy.financePageConfirmedActions);
      expect(
        (await plans.findByCommitmentId(plan.commitment.id))!
            .occurrences
            .single
            .status,
        OccurrenceStatus.scheduled,
      );
      expect((await DriftActualRepository(database).list()).length, 2);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
