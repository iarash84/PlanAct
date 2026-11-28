import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/core/presentation/planact_form_sheet.dart';
import 'package:planact/features/commitments/data/drift_commitment_plan_repository.dart';
import 'package:planact/features/commitments/data/drift_commitment_repository.dart';
import 'package:planact/features/finance/data/drift_finance_repository.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/reconciliation/application/atomic_occurrence_allocation_repository.dart';
import 'package:planact/features/reconciliation/data/drift_reconciliation_repository.dart';
import 'package:planact/features/reconciliation/presentation/transaction_relationship_page.dart';
import 'package:planact/features/scheduling/domain/occurrence.dart';
import 'package:planact/l10n/generated/app_localizations_fa.dart';

import '../fixtures/counted_commitment.dart';
import 'inline_occurrence_allocation_test.dart' show DelayedSelectionFlow;

import 'package:planact/features/reconciliation/domain/relationship_review.dart';

class PendingAllocationFlow extends DelayedSelectionFlow {
  PendingAllocationFlow(super.db);

  Completer<void>? pendingSave;

  @override
  Future<void> confirmSelectedOccurrence({
    required OccurrenceAllocationSnapshot? snapshot,
    required StableId transactionId,
    required StableId occurrenceId,
    required Money allocation,
    Money? total,
    RelationshipReview? expectedReview,
  }) async {
    final pending = pendingSave;
    pendingSave = null;
    if (pending != null) await pending.future;
    await super.confirmSelectedOccurrence(
      snapshot: snapshot,
      transactionId: transactionId,
      occurrenceId: occurrenceId,
      allocation: allocation,
      total: total,
      expectedReview: expectedReview,
    );
  }
}

void main() {
  for (final dark in [false, true]) {
    testWidgets(
      'production panel original total, retained drafts, swipe, saving guard, stale, queue and keyboard $dark',
      (tester) async {
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        addTearDown(db.close);
        final plan = countedPlan(
          target: 3,
          statuses: const [
            OccurrenceStatus.scheduled,
            OccurrenceStatus.scheduled,
            OccurrenceStatus.scheduled,
          ],
        );
        final finance = DriftFinanceRepository(db);
        final repo = DriftReconciliationRepository(db);
        final flow = PendingAllocationFlow(db);
        final account = FinancialAccount(
          id: StableId.generate(),
          name: 'حساب',
          currency: 'IRR',
          type: FinancialAccountType.cash,
        );
        final entry = AccountEntry(
          id: StableId.generate(),
          accountId: account.id,
          type: AccountEntryType.expense,
          amount: const Money(minorUnits: 200, currency: 'IRR'),
          occurredAt: DateTime.now(),
        );
        await tester.runAsync(() async {
          await DriftCommitmentRepository(db).save(plan.commitment);
          await DriftCommitmentPlanRepository(db).save(plan);
          await finance.saveAccount(account);
          await finance.saveEntry(entry);
          final snapshot = await repo.loadOccurrenceAllocation(
            entry.id,
            plan.occurrences[0].id,
          );
          await repo.confirmOccurrenceAllocation(
            snapshot,
            total: const Money(minorUnits: 100, currency: 'IRR'),
            allocation: const Money(minorUnits: 50, currency: 'IRR'),
          );
        });
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetViewInsets);
        final navigator = GlobalKey<NavigatorState>();
        final copy = AppLocalizationsFa();
        await tester.pumpWidget(
          MaterialApp(
            navigatorKey: navigator,
            theme: dark ? PlanActTheme.dark() : PlanActTheme.light(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.8)),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: child!,
              ),
            ),
            home: const Scaffold(body: Text('مبدأ')),
          ),
        );
        Future<void> settle() async {
          for (var i = 0; i < 12; i++) {
            await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 20)),
            );
            await tester.pump();
          }
          await tester.pumpAndSettle();
        }

        Future<void> tap(Finder finder) async {
          await tester.ensureVisible(finder);
          await tester.tap(finder);
          await settle();
        }

        final total = find.byKey(
          const ValueKey('occurrence-expectation-total'),
        );
        final confirm = find.byKey(
          const ValueKey('occurrence-expectation-confirm'),
        );
        final amount = find.descendant(
          of: find.byType(PlanActFormSheet),
          matching: find.byWidgetPredicate(
            (w) => w is TextField && w.key == null,
          ),
        );
        final save = find.byKey(const ValueKey('occurrence-allocation-save'));
        Future<void> select(int index) => tap(
          find.byKey(
            ValueKey('relationship-target-${plan.occurrences[index].id.value}'),
          ),
        );
        Future<int> changes() async =>
            (await db.customSelect('SELECT total_changes() AS n').getSingle())
                .read<int>('n');
        final before = await tester.runAsync(changes);
        bool? returned;
        unawaited(
          navigator.currentState!
              .push<bool>(
                MaterialPageRoute(
                  builder: (_) => TransactionRelationshipPage(
                    transactionId: entry.id,
                    flow: flow,
                    reviewRemaining: 1,
                  ),
                ),
              )
              .then((value) => returned = value),
        );
        await settle();
        expect(find.byType(PlanActFormSheet), findsNothing);
        final delayed = Completer<OccurrenceAllocationSnapshot?>();
        flow.delayed = delayed;
        final delayedTarget = find.byKey(
          ValueKey('relationship-target-${plan.occurrences[2].id.value}'),
        );
        await tester.ensureVisible(delayedTarget);
        await tester.tap(delayedTarget);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.byType(PlanActFormSheet), findsOneWidget);
        expect(find.byType(LinearProgressIndicator), findsOneWidget);
        expect(tester.widget<FilledButton>(save).onPressed, isNull);
        await tester.tap(find.text(copy.commonCancel));
        await settle();
        await select(1);
        delayed.complete(
          await tester.runAsync(
            () =>
                repo.loadOccurrenceAllocation(entry.id, plan.occurrences[2].id),
          ),
        );
        await settle();
        // The form opens automatically, independently of the target list offset.
        expect(find.byType(PlanActFormSheet), findsOneWidget);
        expect(find.text(copy.occurrenceAllocationSuggestion), findsOneWidget);
        expect(tester.widget<TextField>(amount).controller!.text, '150');
        expect(tester.widget<TextField>(total).controller!.text, '200');
        expect(tester.widget<CheckboxListTile>(confirm).value, isFalse);
        expect(tester.widget<FilledButton>(save).onPressed, isNull);
        expect(await tester.runAsync(changes), before);
        expect(find.text(copy.occurrenceAllocationTotalHelper), findsOneWidget);
        expect(tester.widget<TextField>(amount).controller!.text, '150');
        expect(tester.widget<CheckboxListTile>(confirm).value, isFalse);
        await tester.ensureVisible(total);
        await tester.enterText(total, '500');
        await tester.ensureVisible(amount);
        await tester.enterText(amount, '120');
        await tap(confirm);
        // Realistic keyboard geometry: the action remains above the keyboard.
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        await tester.pumpAndSettle();
        expect(tester.getBottomRight(save).dy, lessThanOrEqualTo(500));
        expect(save.hitTestable(), findsOneWidget);
        tester.view.resetViewInsets();
        await tester.pumpAndSettle();
        Future<void> swipeDown() async {
          final sheet = find.byType(PlanActFormSheet);
          await tester.flingFrom(
            tester.getTopLeft(sheet) + const Offset(180, 12),
            const Offset(0, 650),
            1400,
          );
          await settle();
        }

        await swipeDown();
        expect(find.byType(PlanActFormSheet), findsNothing);
        expect(find.byType(TransactionRelationshipPage), findsOneWidget);
        expect(returned, isNull);
        expect(await tester.runAsync(changes), before);
        await select(2);
        expect(tester.widget<TextField>(total).controller!.text, '200');
        expect(tester.widget<CheckboxListTile>(confirm).value, isFalse);
        await tester.ensureVisible(total);
        await tester.enterText(total, '');
        await tester.ensureVisible(amount);
        await tester.enterText(amount, '');
        await swipeDown();
        await select(2);
        expect(tester.widget<TextField>(total).controller!.text, isEmpty);
        expect(tester.widget<TextField>(amount).controller!.text, isEmpty);
        await tap(
          find.descendant(
            of: find.byType(PlanActFormSheet),
            matching: find.widgetWithText(
              TextButton,
              copy.inboxPageBuildTooltip,
            ),
          ),
        );
        expect(tester.widget<TextField>(total).controller!.text, isEmpty);
        expect(tester.widget<TextField>(amount).controller!.text, isEmpty);
        expect(tester.widget<CheckboxListTile>(confirm).value, isFalse);
        expect(await tester.runAsync(changes), before);
        await tap(find.text(copy.commonCancel));
        await select(1);
        expect(tester.widget<TextField>(total).controller!.text, '500');
        expect(tester.widget<TextField>(amount).controller!.text, '120');
        expect(tester.widget<CheckboxListTile>(confirm).value, isTrue);
        await tap(find.text(copy.commonCancel));
        await tester.runAsync(
          () => db.customStatement(
            'UPDATE account_entries SET note = ? WHERE id = ?',
            ['تغییر هم‌زمان', entry.id.value],
          ),
        );
        await select(1);
        expect(find.text(copy.occurrenceAllocationErrorStale), findsOneWidget);
        expect(tester.widget<TextField>(total).controller!.text, '500');
        expect(tester.widget<TextField>(amount).controller!.text, '120');
        expect(tester.widget<CheckboxListTile>(confirm).value, isFalse);
        expect(tester.widget<FilledButton>(save).onPressed, isNull);
        await tap(
          find.descendant(
            of: find.byType(PlanActFormSheet),
            matching: find.widgetWithText(
              TextButton,
              copy.inboxPageBuildTooltip,
            ),
          ),
        );
        expect(tester.widget<CheckboxListTile>(confirm).value, isFalse);
        await tap(find.text(copy.commonCancel));
        final afterConcurrentChange = await tester.runAsync(changes);
        await select(0);
        expect(total, findsNothing);
        expect(confirm, findsNothing);
        expect(tester.widget<TextField>(amount).controller!.text, '150');
        expect(
          find.text(copy.occurrenceAllocationCapacityDifference),
          findsOneWidget,
        );
        await tap(save);
        expect(
          find.text(copy.occurrenceAllocationAmountOverCapacity),
          findsOneWidget,
        );
        expect(await tester.runAsync(changes), afterConcurrentChange);
        expect(tester.widget<TextField>(amount).controller!.text, '150');
        await tap(find.byKey(const ValueKey('occurrence-use-outstanding')));
        expect(tester.widget<TextField>(amount).controller!.text, '50');
        await tap(save);
        // Partial allocation closes only the panel; sequential review retains route.
        expect(find.byType(PlanActFormSheet), findsNothing);
        expect(find.byType(TransactionRelationshipPage), findsOneWidget);
        expect(returned, isNull);
        await tester.runAsync(() async {
          final snapshot = await repo.loadOccurrenceAllocation(
            entry.id,
            plan.occurrences[0].id,
          );
          expect(snapshot.transactionCapacity.minorUnits, 100);
          expect(snapshot.expectedTotal!.minorUnits, 100);
          expect(snapshot.expectationCapacity!.minorUnits, 0);
        });
        await select(1);
        expect(tester.widget<TextField>(amount).controller!.text, '100');
        expect(tester.widget<TextField>(total).controller!.text, '200');
        expect(tester.widget<CheckboxListTile>(confirm).value, isFalse);
        await tap(confirm);
        final pendingSave = Completer<void>();
        flow.pendingSave = pendingSave;
        await tester.tap(save);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        final beforePending = await tester.runAsync(changes);
        // Do not settle the indeterminate saving indicator.
        await tester.flingFrom(
          tester.getTopLeft(find.byType(PlanActFormSheet)) +
              const Offset(180, 12),
          const Offset(0, 650),
          1400,
        );
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.byType(PlanActFormSheet), findsOneWidget);
        expect(
          tester
              .widget<PlanActFormSheet>(find.byType(PlanActFormSheet))
              .isLoading,
          isTrue,
        );
        expect(tester.widget<FilledButton>(save).onPressed, isNull);
        expect(
          tester
              .widget<OutlinedButton>(
                find.widgetWithText(OutlinedButton, copy.commonCancel),
              )
              .onPressed,
          isNull,
        );
        await navigator.currentState!.maybePop();
        await tester.pump();
        expect(find.byType(PlanActFormSheet), findsOneWidget);
        expect(returned, isNull);
        expect(await tester.runAsync(changes), beforePending);
        pendingSave.complete();
        await settle();
        expect(find.byType(TransactionRelationshipPage), findsNothing);
        expect(returned, isTrue);
        await tester.runAsync(() async {
          expect(
            (await repo.loadOccurrenceAllocation(
              entry.id,
              plan.occurrences[1].id,
            )).transactionCapacity.minorUnits,
            0,
          );
          expect((await finance.listEntries()).single.id, entry.id);
        });
        expect(tester.takeException(), isNull);
      },
    );
  }
}
