import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/features/reconciliation/presentation/relationship_target_browser.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/commitments/application/commitment_repository.dart';
import 'package:planact/features/commitments/application/commitment_plan_use_case.dart';
import 'package:planact/features/finance/application/finance_use_cases.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/reconciliation/application/contextual_reconciliation.dart';
import 'package:planact/features/reconciliation/application/reconciliation_use_cases.dart';
import 'package:planact/features/reconciliation/presentation/transaction_relationship_page.dart';

import 'relationship_target_browser_test.dart' as fixtures;

class PageFlow extends ContextualReconciliation {
  PageFlow(this.snapshot, fixtures.PagedReader reader)
    : super(
        finance: InMemoryFinanceRepository(),
        commitments: InMemoryCommitmentRepository(),
        plans: InMemoryCommitmentPlanRepository(),
        reconciliation: ReconciliationUseCases(
          InMemoryReconciliationRepository(),
        ),
        targetReader: reader,
      );
  final TransactionRelationshipContext snapshot;
  int pageLoads = 0;
  @override
  Future<TransactionRelationshipContext> loadForPage(StableId id) async {
    pageLoads++;
    return snapshot;
  }
}

void main() {
  testWidgets(
    'page keeps allocation draft and selected target through paging search and reload',
    (tester) async {
      final reader = fixtures.PagedReader(fixtures.targets());
      final account = FinancialAccount(
        id: StableId.generate(),
        name: 'حساب پایدار',
        currency: 'IRR',
        type: FinancialAccountType.bank,
      );
      final transaction = AccountEntry(
        id: StableId.generate(),
        accountId: account.id,
        type: AccountEntryType.expense,
        amount: const Money(minorUnits: 1000, currency: 'IRR'),
        occurredAt: DateTime(2026, 11, 21, 14, 35),
        note: 'یادداشت ذخیره‌شده',
      );
      final flow = PageFlow(
        TransactionRelationshipContext(
          transaction: transaction,
          account: account,
          available: transaction.amount,
          targets: const [],
          transactionTags: const ['آموزش پایدار'],
        ),
        reader,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: PlanActTheme.light(),
          builder: (_, child) =>
              Directionality(textDirection: TextDirection.rtl, child: child!),
          home: TransactionRelationshipPage(
            transactionId: transaction.id,
            flow: flow,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('هزینه'), findsOneWidget);
      expect(find.text('یادداشت ذخیره‌شده'), findsOneWidget);
      expect(find.text('#آموزش پایدار'), findsOneWidget);
      expect(find.textContaining('۱۴:۳۵'), findsOneWidget);
      final target = find.byKey(
        ValueKey(
          'relationship-target-${reader.targets.first.occurrence.id.value}',
        ),
      );
      final cards = find.byType(RelationshipTargetCard);
      expect(
        tester.getTopLeft(cards.at(1)).dy -
            tester.getBottomLeft(cards.first).dy,
        greaterThanOrEqualTo(PlanActSpacing.md),
      );
      final allocation = find.byWidgetPredicate(
        (w) => w is TextField && w.controller != null && w.key == null,
      );
      expect(allocation, findsNothing);
      final filters = find.byType(ExpansionTile);
      await tester.ensureVisible(filters);
      await tester.tap(filters);
      await tester.pumpAndSettle();
      final minimum = find.byKey(const ValueKey('relationship-minimum'));
      final maximum = find.byKey(const ValueKey('relationship-maximum'));
      expect(
        tester.getTopLeft(maximum).dy - tester.getBottomLeft(minimum).dy,
        greaterThanOrEqualTo(PlanActSpacing.md),
      );
      await tester.ensureVisible(filters);
      await tester.tap(filters);
      await tester.pumpAndSettle();
      await tester.ensureVisible(target);
      await tester.tap(target);
      await tester.pumpAndSettle();
      final amount = allocation;
      await tester.ensureVisible(amount);
      await tester.enterText(amount, '123');
      final before = tester.widget<TextField>(amount).controller!.text;
      await tester.tap(find.text('انصراف'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('صفحهٔ بعد'));
      await tester.tap(find.text('صفحهٔ بعد'));
      await tester.pumpAndSettle();
      final search = find.byKey(const ValueKey('relationship-search'));
      await tester.ensureVisible(search);
      await tester.enterText(search, '42');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('بازخوانی'));
      await tester.tap(find.text('بازخوانی'));
      await tester.pumpAndSettle();
      expect(flow.pageLoads, 2);
      final selected = find.byKey(const ValueKey('relationship-selected'));
      expect(selected, findsOneWidget);
      expect(reader.queries.last.query, '42');
      await tester.ensureVisible(selected);
      await tester.tap(selected);
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(amount).controller!.text, before);
      expect(await flow.reconciliation.repository.list(), isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
}
