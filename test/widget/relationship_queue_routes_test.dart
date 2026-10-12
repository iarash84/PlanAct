import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/planact_app.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/commitments/data/drift_commitment_plan_repository.dart';
import 'package:planact/features/commitments/data/drift_commitment_repository.dart';
import 'package:planact/features/finance/data/drift_finance_repository.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/reconciliation/data/drift_reconciliation_repository.dart';
import 'package:planact/features/reconciliation/presentation/relationship_queue_page.dart';
import 'package:planact/features/reconciliation/presentation/transaction_relationship_page.dart';

void main() {
  late Directory directory;
  late AppDatabase database;
  late DriftFinanceRepository finance;
  late AccountEntry transaction;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp(
      'relationship-queue-route-',
    );
    database = AppDatabase.forTesting(
      NativeDatabase(File('${directory.path}/state.sqlite')),
    );
    finance = DriftFinanceRepository(database);
    final account = FinancialAccount(
      id: StableId.generate(),
      name: 'حساب آزمون',
      currency: 'IRR',
      type: FinancialAccountType.bank,
    );
    await finance.saveAccount(account);
    transaction = AccountEntry(
      id: StableId.generate(),
      accountId: account.id,
      type: AccountEntryType.expense,
      amount: const Money(minorUnits: 1000, currency: 'IRR'),
      occurredAt: DateTime.now(),
      note: 'پرداخت مستقل آزمون',
    );
    await finance.saveEntry(transaction);
  });
  tearDown(() async {
    await database.close();
    await directory.delete(recursive: true);
  });
  testWidgets(
    'Today queue commits refreshes Attention; Finance detail discovers same queue and reopening',
    (tester) async {
      await tester.pumpWidget(
        PlanActApp(
          repository: DriftCommitmentRepository(database),
          planRepository: DriftCommitmentPlanRepository(database),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextButton, 'تعیین ارتباط'), findsOneWidget);
      await tester.tap(find.text('صف بررسی ارتباط تراکنش‌ها'));
      await tester.pumpAndSettle();
      expect(find.byType(RelationshipQueuePage), findsOneWidget);
      await tester.tap(find.text('انتخاب همین صفحه'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('مستقل ثبت کن (۱)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('تأیید مستقل بودن'));
      await tester.pumpAndSettle();
      expect(
        (await DriftReconciliationRepository(database).loadReview(transaction))
            .isIndependent,
        true,
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextButton, 'تعیین ارتباط'), findsNothing);
      await tester.tap(find.text('مالی'));
      await tester.pumpAndSettle();
      // Finance retains the explicit relationship action for reviewed history.
      final menu = find.byType(PopupMenuButton<String>);
      await tester.scrollUntilVisible(
        menu,
        300,
        scrollable: find.byType(Scrollable).last,
      );
      expect(menu, findsWidgets);
      await tester.ensureVisible(menu.last);
      await tester.pumpAndSettle();
      await tester.tap(menu.last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('تعیین ارتباط'));
      await tester.pumpAndSettle();
      expect(find.byType(TransactionRelationshipPage), findsOneWidget);
      await tester.tap(find.text('صف بررسی ارتباط تراکنش‌ها'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('مستقل‌های بررسی‌شده'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('بازگشایی بررسی ارتباط'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('بازگشایی بررسی ارتباط'));
      await tester.pumpAndSettle();
      expect(
        (await DriftReconciliationRepository(database).loadReview(transaction))
            .isIndependent,
        false,
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('به تعهدی مربوط نیست'), findsOneWidget);
      expect(await finance.listEntries(), hasLength(1));
      expect(await DriftReconciliationRepository(database).list(), isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
