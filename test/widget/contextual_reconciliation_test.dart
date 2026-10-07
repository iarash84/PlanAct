import 'dart:io';
import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/planact_app.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/commitments/application/commitment_plan_use_case.dart';
import 'package:planact/features/commitments/application/commitment_repository.dart';
import 'package:planact/features/commitments/data/drift_commitment_plan_repository.dart';
import 'package:planact/features/commitments/data/drift_commitment_repository.dart';
import 'package:planact/features/finance/application/finance_use_cases.dart';
import 'package:planact/features/finance/data/drift_finance_repository.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/inbox/application/inbox_use_cases.dart';
import 'package:planact/features/inbox/data/drift_inbox_repository.dart';
import 'package:planact/features/inbox/presentation/inbox_page.dart';
import 'package:planact/features/reconciliation/application/contextual_reconciliation.dart';
import 'package:planact/features/reconciliation/application/reconciliation_use_cases.dart';
import 'package:planact/features/reconciliation/data/drift_reconciliation_repository.dart';
import 'package:planact/features/reconciliation/presentation/transaction_relationship_page.dart';

class _DelayedContext extends ContextualReconciliation {
  _DelayedContext(ContextualReconciliation flow, this.pending)
    : super(
        finance: flow.finance,
        commitments: flow.commitments,
        plans: flow.plans,
        reconciliation: flow.reconciliation,
      );
  final Future<TransactionRelationshipContext> pending;
  @override
  Future<TransactionRelationshipContext> load(StableId transactionId) =>
      pending;
}

void main() {
  late AppDatabase database;
  late Directory directory;
  late File databaseFile;
  late DriftCommitmentRepository commitments;
  late DriftCommitmentPlanRepository plans;
  late DriftFinanceRepository finance;
  late ReconciliationUseCases reconciliation;
  late ContextualReconciliation flow;
  late AccountEntry transaction;
  late StableId occurrenceId;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('planact-context-');
    databaseFile = File(
      '${directory.path}${Platform.pathSeparator}state.sqlite',
    );
    database = AppDatabase.forTesting(NativeDatabase(databaseFile));
    commitments = DriftCommitmentRepository(database);
    plans = DriftCommitmentPlanRepository(database);
    finance = DriftFinanceRepository(database);
    reconciliation = ReconciliationUseCases(
      DriftReconciliationRepository(database),
    );
    flow = ContextualReconciliation(
      finance: finance,
      commitments: commitments,
      plans: plans,
      reconciliation: reconciliation,
    );
    final plan =
        await CreateCommitmentPlan(commitments: commitments, plans: plans)(
          title: 'کلاس موسیقی',
          startAt: DateTime.now().add(const Duration(days: 1)),
        );
    occurrenceId = plan.occurrences.single.id;
    final account = FinancialAccount(
      id: StableId.generate(),
      name: 'حساب آزمون',
      currency: 'IRR',
      type: FinancialAccountType.bank,
    );
    await finance.saveAccount(account);
    transaction = await FinanceUseCases(finance).record(
      account: account,
      type: AccountEntryType.expense,
      amount: const Money(minorUnits: 1000, currency: 'IRR'),
      occurredAt: DateTime.now(),
      note: 'پرداخت واردشده',
    );
  });
  tearDown(() async {
    await database.close();
    await directory.delete(recursive: true);
  });

  test(
    'relationship and transaction context survive file database restart',
    () async {
      await flow.confirm(
        transactionId: transaction.id,
        occurrenceId: occurrenceId,
        minorUnits: 400,
      );
      await database.close();
      database = AppDatabase.forTesting(NativeDatabase(databaseFile));
      final restored = ContextualReconciliation(
        finance: DriftFinanceRepository(database),
        commitments: DriftCommitmentRepository(database),
        plans: DriftCommitmentPlanRepository(database),
        reconciliation: ReconciliationUseCases(
          DriftReconciliationRepository(database),
        ),
      );
      final context = await restored.load(transaction.id);
      expect(context.transaction.id, transaction.id);
      expect(context.available.minorUnits, 600);
      expect(context.targets.single.occurrence.id, occurrenceId);
      expect(
        (await DriftReconciliationRepository(
          database,
        ).list()).single.allocations.single.occurrenceId,
        occurrenceId,
      );
    },
  );

  test('partial allocations retain identity, reload and reject excess without ledger mutations', () async {
    await flow.confirm(
      transactionId: transaction.id,
      occurrenceId: occurrenceId,
      minorUnits: 400,
    );
    final context = await flow.load(transaction.id);
    expect(context.available.minorUnits, 600);
    expect(context.transaction.id, transaction.id);
    expect(context.targets.single.occurrence.id, occurrenceId);
    expect(
      (await reconciliation.repository.list()).single.transactionId,
      transaction.id,
    );
    await expectLater(
      flow.confirm(
        transactionId: transaction.id,
        occurrenceId: occurrenceId,
        minorUnits: 601,
      ),
      throwsException,
    );
    expect(await finance.listEntries(), hasLength(1));
    expect(
      (await plans.findByCommitmentId(context.targets.single.commitment.id))!
          .occurrences
          .single
          .status,
      context.targets.single.occurrence.status,
    );
  });

  testWidgets(
    'SMS confirmation routes the imported entry, not another transaction',
    (tester) async {
      final inbox = InboxUseCases(DriftInboxRepository(database));
      await inbox.stageSms(
        rawText: 'برداشت مبلغ ۲۵۰۰ 2026-09-20',
        sourceKey: 'sms:context',
        currency: 'IRR',
        importedAt: DateTime.utc(2026, 9, 20),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: PlanActTheme.light(),
          home: Builder(
            builder: (context) => Scaffold(
              body: InboxPage(
                inbox: inbox,
                finance: finance,
                onDetermineRelationship: (id) async {
                  await Navigator.of(context).push(
                    MaterialPageRoute<bool>(
                      builder: (_) => TransactionRelationshipPage(
                        transactionId: id,
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
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('تأیید و ثبت'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('تأیید و ثبت'));
      await tester.pumpAndSettle();
      final imported = (await finance.listEntries()).singleWhere(
        (e) => e.id != transaction.id,
      );
      await tester.tap(find.text('تعیین ارتباط'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TransactionRelationshipPage>(
              find.byType(TransactionRelationshipPage),
            )
            .transactionId,
        imported.id,
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(InboxPage), findsOneWidget);
      expect(await finance.listEntries(), hasLength(2));
      expect(await reconciliation.repository.list(), isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('loading is explicit until durable context arrives', (
    tester,
  ) async {
    final pending = Completer<TransactionRelationshipContext>();
    final delayed = _DelayedContext(flow, pending.future);
    await tester.pumpWidget(
      MaterialApp(
        home: TransactionRelationshipPage(
          transactionId: transaction.id,
          flow: delayed,
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('به تعهدی مربوط نیست'), findsNothing);
    pending.complete(await flow.load(transaction.id));
    await tester.pumpAndSettle();
    expect(find.text('به تعهدی مربوط نیست'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'no candidates still permits independent decision; back alone makes no review',
    (tester) async {
      final emptyFlow = ContextualReconciliation(
        finance: finance,
        commitments: InMemoryCommitmentRepository(),
        plans: plans,
        reconciliation: reconciliation,
      );
      Future<void> open() async {
        await tester.pumpWidget(
          MaterialApp(
            theme: PlanActTheme.light(),
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<bool>(
                      builder: (_) => TransactionRelationshipPage(
                        transactionId: transaction.id,
                        flow: emptyFlow,
                      ),
                    ),
                  ),
                  child: const Text('ورود'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('ورود'));
        await tester.pumpAndSettle();
      }

      await open();
      expect(
        find.text('هنوز رخدادی برای انتخاب ثبت نشده است.'),
        findsOneWidget,
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect((await emptyFlow.load(transaction.id)).review!.revision, 0);
      await tester.tap(find.text('ورود'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('به تعهدی مربوط نیست'));
      await tester.pumpAndSettle();
      expect(
        (await emptyFlow.load(transaction.id)).review!.isIndependent,
        isTrue,
      );
      expect(await reconciliation.repository.list(), isEmpty);
      expect(await finance.listEntries(), hasLength(1));
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'stale independent/reopen decisions retain draft until explicit reload',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TransactionRelationshipPage(
            transactionId: transaction.id,
            flow: flow,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('کلاس موسیقی'));
      await tester.enterText(
        find.widgetWithText(TextField, 'مبلغ ارتباط'),
        '400',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      final independent = await flow.markIndependent(
        expected: (await flow.load(transaction.id)).review!,
      );
      await tester.ensureVisible(find.text('به تعهدی مربوط نیست'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('به تعهدی مربوط نیست'));
      await tester.pumpAndSettle();
      expect(find.textContaining('ثبت تصمیم انجام نشد'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.widgetWithText(TextField, 'مبلغ ارتباط'))
            .controller!
            .text,
        '400',
      );
      expect(tester.widget<ListTile>(find.byType(ListTile)).selected, isTrue);
      await tester.ensureVisible(find.widgetWithText(TextButton, 'بازخوانی'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('بازخوانی'));
      await tester.pumpAndSettle();
      await flow.reopen(expected: independent);
      await tester.ensureVisible(find.text('بازگشایی بررسی ارتباط'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('بازگشایی بررسی ارتباط'));
      await tester.pumpAndSettle();
      expect(find.textContaining('ثبت تصمیم انجام نشد'), findsOneWidget);
      expect(find.text('بازگشایی بررسی ارتباط'), findsOneWidget);
      await tester.ensureVisible(find.widgetWithText(TextButton, 'بازخوانی'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('بازخوانی'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.widgetWithText(TextField, 'مبلغ ارتباط'))
            .controller!
            .text,
        '400',
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  for (final dark in [false, true]) {
    testWidgets(
      'partial independent remainder undo, reopen and relink with dirty back (${dark ? 'dark' : 'light'})',
      (tester) async {
        await flow.confirm(
          transactionId: transaction.id,
          occurrenceId: occurrenceId,
          minorUnits: 400,
        );
        bool? returned;
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? PlanActTheme.dark() : PlanActTheme.light(),
            builder: (context, child) => Directionality(
              textDirection: TextDirection.rtl,
              child: MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(1.8)),
                child: child!,
              ),
            ),
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () async {
                    returned = await Navigator.of(context).push<bool>(
                      MaterialPageRoute<bool>(
                        builder: (_) => TransactionRelationshipPage(
                          transactionId: transaction.id,
                          flow: flow,
                        ),
                      ),
                    );
                  },
                  child: const Text('ورود'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('ورود'));
        await tester.pumpAndSettle();
        expect(
          Directionality.of(
            tester.element(find.byType(TransactionRelationshipPage)),
          ),
          TextDirection.rtl,
        );
        await tester.ensureVisible(find.text('به تعهدی مربوط نیست'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('به تعهدی مربوط نیست'));
        await tester.pumpAndSettle();
        expect((await flow.load(transaction.id)).review!.isIndependent, isTrue);
        expect(find.text('تأیید ارتباط'), findsNothing);
        await tester.tap(find.text('بازگردانی'));
        await tester.pumpAndSettle();
        expect(
          (await flow.load(transaction.id)).review!.isIndependent,
          isFalse,
        );
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('به تعهدی مربوط نیست'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('به تعهدی مربوط نیست'));
        await tester.pumpAndSettle();
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(returned, isTrue);
        await tester.tap(find.text('ورود'));
        await tester.pumpAndSettle();
        expect(find.textContaining('بررسی‌شده:'), findsOneWidget);
        await tester.ensureVisible(find.text('بازگشایی بررسی ارتباط'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('بازگشایی بررسی ارتباط'));
        await tester.pumpAndSettle();
        expect(
          (await flow.load(transaction.id)).review!.isIndependent,
          isFalse,
        );
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();
        await tester.drag(find.byType(SnackBar), const Offset(0, 300));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(find.text('کلاس موسیقی'), 150);
        await tester.pumpAndSettle();
        await tester.tap(find.text('کلاس موسیقی'));
        await tester.ensureVisible(
          find.widgetWithText(TextField, 'مبلغ ارتباط'),
        );
        await tester.pumpAndSettle();
        await tester.enterText(
          find.widgetWithText(TextField, 'مبلغ ارتباط'),
          '600',
        );
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.ensureVisible(find.text('تأیید ارتباط'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('تأیید ارتباط'));
        await tester.pumpAndSettle();
        expect(returned, isTrue);
        expect((await flow.load(transaction.id)).available.minorUnits, 0);
        expect(await reconciliation.repository.list(), hasLength(2));
        expect(await finance.listEntries(), hasLength(1));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
    testWidgets(
      'Today opens exact transaction and back retains origin (${dark ? 'dark' : 'light'})',
      (tester) async {
        tester.platformDispatcher.platformBrightnessTestValue = dark
            ? Brightness.dark
            : Brightness.light;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        await tester.pumpWidget(
          PlanActApp(repository: commitments, planRepository: plans),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(TextButton, 'تعیین ارتباط'));
        await tester.pumpAndSettle();
        expect(find.byType(TransactionRelationshipPage), findsOneWidget);
        expect(
          tester
              .widget<TransactionRelationshipPage>(
                find.byType(TransactionRelationshipPage),
              )
              .transactionId,
          transaction.id,
        );
        expect(find.text('پرداخت واردشده'), findsOneWidget);
        expect(find.text('کلاس موسیقی'), findsOneWidget);
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(find.text('تعیین ارتباط'), findsWidgets);
        expect((await flow.load(transaction.id)).review!.revision, 0);
        expect(await reconciliation.repository.list(), isEmpty);
        expect(await finance.listEntries(), hasLength(1));
        await tester.tap(find.widgetWithText(TextButton, 'تعیین ارتباط'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('به تعهدی مربوط نیست'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('به تعهدی مربوط نیست'));
        await tester.pumpAndSettle();
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(find.widgetWithText(TextButton, 'تعیین ارتباط'), findsNothing);
        expect((await flow.load(transaction.id)).review!.isIndependent, isTrue);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        await tester.pumpWidget(
          PlanActApp(repository: commitments, planRepository: plans),
        );
        await tester.pumpAndSettle();
        expect(find.widgetWithText(TextButton, 'تعیین ارتباط'), findsNothing);
        expect(await reconciliation.repository.list(), isEmpty);
        expect(await finance.listEntries(), hasLength(1));
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );

    testWidgets(
      'selection and amount survive refresh; confirmation returns to source (${dark ? 'dark' : 'light'})',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? PlanActTheme.dark() : PlanActTheme.light(),
            builder: (context, child) =>
                Directionality(textDirection: TextDirection.rtl, child: child!),
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<bool>(
                      builder: (_) => TransactionRelationshipPage(
                        transactionId: transaction.id,
                        flow: flow,
                      ),
                    ),
                  ),
                  child: const Text('المصدر'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('المصدر'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('کلاس موسیقی'));
        await tester.enterText(
          find.widgetWithText(TextField, 'مبلغ ارتباط'),
          '400',
        );
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.ensureVisible(find.widgetWithText(TextButton, 'بازخوانی'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('بازخوانی'));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<TextField>(find.widgetWithText(TextField, 'مبلغ ارتباط'))
              .controller!
              .text,
          '400',
        );
        expect(tester.widget<ListTile>(find.byType(ListTile)).selected, isTrue);
        // A stale remaining amount must fail without losing the user's draft.
        await flow.confirm(
          transactionId: transaction.id,
          occurrenceId: occurrenceId,
          minorUnits: 700,
        );
        await tester.ensureVisible(find.text('تأیید ارتباط'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('تأیید ارتباط'));
        await tester.pumpAndSettle();
        expect(find.byType(TransactionRelationshipPage), findsOneWidget);
        expect(
          tester
              .widget<TextField>(find.widgetWithText(TextField, 'مبلغ ارتباط'))
              .controller!
              .text,
          '400',
        );
        expect(tester.widget<ListTile>(find.byType(ListTile)).selected, isTrue);
        await tester.ensureVisible(find.widgetWithText(TextButton, 'بازخوانی'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('بازخوانی'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.widgetWithText(TextField, 'مبلغ ارتباط'),
          '300',
        );
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.ensureVisible(find.text('تأیید ارتباط'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('تأیید ارتباط'));
        await tester.pumpAndSettle();
        expect(find.text('المصدر'), findsOneWidget);
        expect(
          (await reconciliation.repository.list())
              .last
              .allocations
              .single
              .occurrenceId,
          occurrenceId,
        );
        expect(await finance.listEntries(), hasLength(1));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
