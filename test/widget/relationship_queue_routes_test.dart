import 'dart:io';

import 'package:drift/native.dart';
import 'package:planact/features/classification/data/drift_tag_repository.dart';
import 'package:planact/features/classification/application/tag_repository.dart';
import 'package:planact/features/classification/presentation/tag_controls.dart';
import 'package:planact/features/finance/presentation/transaction_card.dart';
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
      bank: IranianBank.mellat,
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
    final tags = DriftTagRepository(database);
    final tag = await tags.getOrCreate('صف ارتباط');
    await tags.attach(
      recordId: transaction.id.value,
      tag: tag,
      type: TaggableType.accountEntry,
    );
  });
  tearDown(() async {
    await database.close();
    await directory.delete(recursive: true);
  });
  testWidgets(
    'Today queue commits refreshes Attention; Finance detail discovers same queue and reopening',
    (tester) async {
      tester.view.physicalSize = const Size(360, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        PlanActApp(
          repository: DriftCommitmentRepository(database),
          planRepository: DriftCommitmentPlanRepository(database),
        ),
      );
      await tester.pumpAndSettle();
      final relationshipGroup = find.byKey(
        const PageStorageKey('today-attention:تعیین ارتباط'),
      );
      expect(relationshipGroup, findsOneWidget);
      expect(find.widgetWithText(TextButton, 'تعیین ارتباط'), findsNothing);
      await tester.ensureVisible(relationshipGroup);
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: relationshipGroup,
          matching: find.text('تعیین ارتباط'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextButton, 'تعیین ارتباط'), findsOneWidget);
      await tester.ensureVisible(find.text('صف بررسی ارتباط تراکنش‌ها'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('صف بررسی ارتباط تراکنش‌ها'));
      await tester.pumpAndSettle();
      expect(find.byType(RelationshipQueuePage), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byType(TransactionCard),
        150,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('حساب آزمون'), findsOneWidget);
      expect(find.textContaining('ملت'), findsOneWidget);
      expect(tester.widget<TagLabels>(find.byType(TagLabels)).labels, [
        'صف ارتباط',
      ]);
      expect(await finance.listEntries(), hasLength(1));
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
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextButton, 'تعیین ارتباط'), findsNothing);
      await tester.tap(find.widgetWithText(NavigationDestination, 'مالی'));
      await tester.pumpAndSettle();
      // Finance retains the explicit relationship action for reviewed history.
      final menu = find.byTooltip('عملیات تراکنش');
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
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('به تعهدی مربوط نیست'), findsOneWidget);
      expect(await finance.listEntries(), hasLength(1));
      expect(await DriftReconciliationRepository(database).list(), isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
