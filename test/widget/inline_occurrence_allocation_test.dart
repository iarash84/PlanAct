import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/commitments/data/drift_commitment_plan_repository.dart';
import 'package:planact/features/commitments/data/drift_commitment_repository.dart';
import 'package:planact/features/finance/data/drift_finance_repository.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/reconciliation/application/atomic_occurrence_allocation_repository.dart';
import 'package:planact/features/reconciliation/application/contextual_reconciliation.dart';
import 'package:planact/features/reconciliation/application/reconciliation_use_cases.dart';
import 'package:planact/features/reconciliation/data/drift_reconciliation_repository.dart';
import 'package:planact/features/reconciliation/data/drift_relationship_page_loader.dart';
import 'package:planact/features/reconciliation/data/drift_relationship_target_reader.dart';
import 'package:planact/features/reconciliation/presentation/transaction_relationship_page.dart';
import 'package:planact/features/scheduling/domain/occurrence.dart';
import 'package:planact/l10n/generated/app_localizations_fa.dart';

import '../fixtures/counted_commitment.dart';

class DelayedSelectionFlow extends ContextualReconciliation {
  DelayedSelectionFlow(AppDatabase db)
    : super(
        finance: DriftFinanceRepository(db),
        commitments: DriftCommitmentRepository(db),
        plans: DriftCommitmentPlanRepository(db),
        reconciliation: ReconciliationUseCases(
          DriftReconciliationRepository(db),
        ),
        targetReader: DriftRelationshipTargetReader(db),
        pageLoader: DriftRelationshipPageLoader(db).load,
      );
  Completer<OccurrenceAllocationSnapshot?>? delayed;
  @override
  Future<OccurrenceAllocationSnapshot?> loadOccurrenceAllocation(
    StableId transactionId,
    StableId occurrenceId,
  ) {
    final pending = delayed;
    delayed = null;
    return pending?.future ??
        super.loadOccurrenceAllocation(transactionId, occurrenceId);
  }
}

void main() {
  final copy = AppLocalizationsFa();
  for (final dark in [false, true]) {
    testWidgets(
      'SQLite paged route blank allocation, invalid input, capacity and retry ${dark ? 'dark' : 'light'}',
      (tester) async {
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        addTearDown(db.close);
        final plan = countedPlan(target: 1);
        final finance = DriftFinanceRepository(db);
        final account = FinancialAccount(
          id: StableId.generate(),
          name: 'حساب آزمون',
          currency: 'IRR',
          type: FinancialAccountType.cash,
        );
        final transaction = AccountEntry(
          id: StableId.generate(),
          accountId: account.id,
          type: dark ? AccountEntryType.income : AccountEntryType.expense,
          amount: const Money(minorUnits: 200, currency: 'IRR'),
          occurredAt: DateTime.now(),
        );
        await tester.runAsync(() async {
          await DriftCommitmentRepository(db).save(plan.commitment);
          await DriftCommitmentPlanRepository(db).save(plan);
          await finance.saveAccount(account);
          await finance.saveEntry(transaction);
        });
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final navigator = GlobalKey<NavigatorState>();
        await tester.pumpWidget(
          MaterialApp(
            navigatorKey: navigator,
            theme: dark ? PlanActTheme.dark() : PlanActTheme.light(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.6)),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: child!,
              ),
            ),
            home: const Scaffold(body: Text('مبدأ')),
          ),
        );
        Future<void> settleDb() async {
          for (var i = 0; i < 12; i++) {
            await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 25)),
            );
            await tester.pump();
          }
          await tester.pumpAndSettle();
        }

        Future<void> tap(Finder finder) async {
          await tester.ensureVisible(finder);
          await tester.tap(finder);
          await settleDb();
        }

        unawaited(
          navigator.currentState!.push(
            MaterialPageRoute<bool>(
              builder: (_) => TransactionRelationshipPage(
                transactionId: transaction.id,
                flow: DelayedSelectionFlow(db),
              ),
            ),
          ),
        );
        await settleDb();
        await tap(
          find.byKey(
            ValueKey('relationship-target-${plan.occurrences.first.id.value}'),
          ),
        );
        final total = find.byKey(
          const ValueKey('occurrence-expectation-total'),
        );
        final check = find.byKey(
          const ValueKey('occurrence-expectation-confirm'),
        );
        final amount = find.byWidgetPredicate(
          (w) => w is TextField && w.controller != null && w.key == null,
        );
        final save = find.widgetWithText(
          FilledButton,
          copy.occurrenceAllocationConfirm,
        );
        expect(find.text(copy.occurrenceAllocationTotalHelper), findsOneWidget);
        expect(
          find.text(copy.occurrenceAllocationAmountHelper),
          findsOneWidget,
        );
        await tester.ensureVisible(total);
        await tester.enterText(total, '200');
        await tap(check);
        Future<int> writeCount() async =>
            (await db.customSelect('SELECT total_changes() AS n').getSingle())
                .read<int>('n');
        final before = await tester.runAsync(writeCount);
        // Approved suggestion is editable; clearing it still requires a value.
        expect(tester.widget<TextField>(amount).controller!.text, '200');
        await tester.ensureVisible(amount);
        await tester.enterText(amount, '');
        await tap(save);
        expect(
          find.text(copy.occurrenceAllocationAmountRequired),
          findsOneWidget,
        );
        expect(find.text(copy.occurrenceAllocationErrorCapacity), findsNothing);
        expect(
          find.text(copy.occurrenceAllocationAmountOverCapacity),
          findsNothing,
        );
        expect(tester.widget<TextField>(amount).controller!.text, isEmpty);
        expect(await tester.runAsync(writeCount), before);
        for (final invalid in ['0', '-1', '0.1', '201']) {
          await tester.ensureVisible(amount);
          await tester.enterText(amount, invalid);
          await tap(save);
          expect(
            find.text(
              invalid == '201'
                  ? copy.occurrenceAllocationAmountOverCapacity
                  : copy.occurrenceAllocationAmountInvalid,
            ),
            findsOneWidget,
          );
          expect(
            find.text(copy.occurrenceAllocationErrorCapacity),
            findsNothing,
          );
          expect(tester.widget<TextField>(total).controller!.text, '200');
          expect(tester.widget<CheckboxListTile>(check).value, isTrue);
          expect(tester.widget<FilledButton>(save).onPressed, isNotNull);
          expect(await tester.runAsync(writeCount), before);
        }
        // No refresh, re-selection or total reconfirmation is needed.
        await tester.ensureVisible(amount);
        await tester.enterText(amount, '200');
        await tap(save);
        expect(find.byType(TransactionRelationshipPage), findsNothing);
        await tester.runAsync(() async {
          final expectations = await db
              .customSelect('SELECT minor_units FROM financial_expectations')
              .get();
          expect(expectations.single.read<int>('minor_units'), 200);
          final allocations = await db
              .customSelect('SELECT minor_units FROM match_allocations')
              .get();
          expect(allocations.single.read<int>('minor_units'), 200);
          expect((await finance.listEntries()).single.id, transaction.id);
        });
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets(
      'SQLite paged route explicit total, stale retry, two payments ${dark ? 'dark' : 'light'} RTL large text',
      (tester) async {
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        addTearDown(db.close);
        final plan = countedPlan(
          target: 2,
          statuses: const [
            OccurrenceStatus.scheduled,
            OccurrenceStatus.scheduled,
          ],
        );
        final finance = DriftFinanceRepository(db);
        final repo = DriftReconciliationRepository(db);
        final flow = DelayedSelectionFlow(db);
        final account = FinancialAccount(
          id: StableId.generate(),
          name: 'حساب آزمون',
          currency: 'IRR',
          type: FinancialAccountType.cash,
        );
        AccountEntry entry(int amount) => AccountEntry(
          id: StableId.generate(),
          accountId: account.id,
          type: dark ? AccountEntryType.income : AccountEntryType.expense,
          amount: Money(minorUnits: amount, currency: 'IRR'),
          occurredAt: DateTime.now(),
        );
        final first = entry(200);
        final second = entry(300);
        await tester.runAsync(() async {
          await DriftCommitmentRepository(db).save(plan.commitment);
          await DriftCommitmentPlanRepository(db).save(plan);
          await finance.saveAccount(account);
          await finance.saveEntry(first);
          await finance.saveEntry(second);
        });
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final navigator = GlobalKey<NavigatorState>();
        await tester.pumpWidget(
          MaterialApp(
            navigatorKey: navigator,
            theme: dark ? PlanActTheme.dark() : PlanActTheme.light(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.6)),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: child!,
              ),
            ),
            home: const Scaffold(body: Text('مبدأ')),
          ),
        );
        Future<void> settleDb() async {
          for (var i = 0; i < 12; i++) {
            await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 25)),
            );
            await tester.pump();
          }
          await tester.pumpAndSettle();
        }

        Future<void> open(AccountEntry transaction) async {
          unawaited(
            navigator.currentState!.push(
              MaterialPageRoute<bool>(
                builder: (_) => TransactionRelationshipPage(
                  transactionId: transaction.id,
                  flow: flow,
                ),
              ),
            ),
          );
          await settleDb();
        }

        Future<void> tap(Finder finder) async {
          await tester.ensureVisible(finder);
          await tester.tap(finder);
          await settleDb();
        }

        final total = find.byKey(
          const ValueKey('occurrence-expectation-total'),
        );
        final check = find.byKey(
          const ValueKey('occurrence-expectation-confirm'),
        );
        final amount = find.byWidgetPredicate(
          (w) => w is TextField && w.controller != null && w.key == null,
        );
        final save = find.widgetWithText(
          FilledButton,
          copy.occurrenceAllocationConfirm,
        );
        Future<int> count(String table) async =>
            (await db
                    .customSelect('SELECT COUNT(*) AS n FROM $table')
                    .getSingle())
                .read<int>('n');
        await open(first);
        await tap(
          find.byKey(
            ValueKey('relationship-target-${plan.occurrences.first.id.value}'),
          ),
        );
        expect(tester.widget<TextField>(total).controller!.text, '200');
        expect(tester.widget<TextField>(amount).controller!.text, '200');
        expect(tester.widget<CheckboxListTile>(check).value, isFalse);
        expect(tester.widget<FilledButton>(save).onPressed, isNull);
        expect(
          find.text(
            dark
                ? copy.occurrenceAllocationSuggestedIncome
                : copy.occurrenceAllocationSuggestedExpense,
          ),
          findsOneWidget,
        );
        await tester.runAsync(() async {
          expect(await count('financial_expectations'), 0);
          expect(await count('transaction_matches'), 0);
        });
        // Cancel a populated draft: no expectation or allocation is written.
        await tester.ensureVisible(total);
        await tester.enterText(total, '500');
        await tester.ensureVisible(amount);
        await tester.enterText(amount, '200');
        navigator.currentState!.pop();
        await settleDb();
        await tester.runAsync(
          () async => expect(await count('financial_expectations'), 0),
        );
        // Only the panel was cancelled; the route retains this target's draft.
        expect(find.byType(TransactionRelationshipPage), findsOneWidget);
        await tap(
          find.byKey(
            ValueKey('relationship-target-${plan.occurrences.first.id.value}'),
          ),
        );
        expect(tester.widget<TextField>(total).controller!.text, '500');
        expect(tester.widget<TextField>(amount).controller!.text, '200');
        await tester.ensureVisible(total);
        await tester.enterText(total, '500');
        await tester.ensureVisible(amount);
        await tester.enterText(amount, '200');
        await tap(check);
        // Change durable transaction after selection, then attempt exactly once.
        await tester.runAsync(
          () => db.customStatement(
            'UPDATE account_entries SET note = ? WHERE id = ?',
            ['تغییر هم‌زمان', first.id.value],
          ),
        );
        await tap(save);
        expect(find.text(copy.occurrenceAllocationErrorStale), findsOneWidget);
        expect(tester.widget<TextField>(total).controller!.text, '500');
        expect(tester.widget<TextField>(amount).controller!.text, '200');
        expect(tester.widget<CheckboxListTile>(check).value, isFalse);
        expect(tester.widget<FilledButton>(save).onPressed, isNull);
        await tap(find.text('بازخوانی').last);
        expect(tester.widget<CheckboxListTile>(check).value, isFalse);
        await tester.runAsync(
          () => db.customStatement(
            "CREATE TRIGGER fail_inline_allocation BEFORE INSERT ON match_allocations BEGIN SELECT RAISE(ABORT, 'test'); END",
          ),
        );
        await tap(check);
        await tap(save);
        expect(
          find.text(copy.occurrenceAllocationErrorStorage),
          findsOneWidget,
        );
        expect(tester.widget<TextField>(total).controller!.text, '500');
        expect(tester.widget<TextField>(amount).controller!.text, '200');
        expect(tester.widget<FilledButton>(save).onPressed, isNull);
        await tester.runAsync(() async {
          expect(await count('financial_expectations'), 0);
          expect(await count('transaction_matches'), 0);
          await db.customStatement('DROP TRIGGER fail_inline_allocation');
        });
        await tap(find.text('بازخوانی').last);
        await tap(check);
        await tap(save);
        expect(find.byType(TransactionRelationshipPage), findsNothing);
        await tester.runAsync(() async {
          expect(await count('financial_expectations'), 1);
          expect(
            (await repo.loadOccurrenceAllocation(
              second.id,
              plan.occurrences.first.id,
            )).expectationCapacity!.minorUnits,
            300,
          );
        });
        await open(second);
        await tap(
          find.byKey(
            ValueKey('relationship-target-${plan.occurrences.first.id.value}'),
          ),
        );
        expect(total, findsNothing);
        expect(check, findsNothing);
        await tester.ensureVisible(amount);
        await tester.enterText(amount, '300');
        await tap(
          find.widgetWithText(
            FilledButton,
            copy.transactionRelationshipPageBuildChildren13,
          ),
        );
        await tester.runAsync(() async {
          expect(await count('financial_expectations'), 1);
          expect(await count('transaction_matches'), 2);
          expect(
            (await db
                    .customSelect(
                      'SELECT minor_units FROM financial_expectations',
                    )
                    .getSingle())
                .read<int>('minor_units'),
            500,
          );
          expect((await finance.listEntries()).length, 2);
        });
        expect(tester.takeException(), isNull);
      },
    );
  }
}
