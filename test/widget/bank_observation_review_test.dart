import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/finance/data/bank_balance_store.dart';
import 'package:planact/features/finance/data/drift_finance_repository.dart';
import 'package:planact/features/finance/domain/bank_balance.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/finance/presentation/bank_balance_panel.dart';
import 'package:planact/features/finance/presentation/bank_observation_review.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets(
      'account review cancel, save, refresh and stale retry $brightness',
      (tester) async {
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        addTearDown(db.close);
        final repo = DriftFinanceRepository(db);
        final account = FinancialAccount(
          id: StableId.generate(),
          name: 'حساب آزمایشی',
          currency: 'IRR',
          type: FinancialAccountType.bank,
        );
        await repo.saveAccount(account);
        final original = BankBalanceObservation(
          id: 'sms',
          entryId: 'entry',
          accountId: account.id.value,
          irr: null,
          sourceAmount: 100,
          sourceUnit: null,
          transactionTime: null,
        );
        await BankBalanceStore(db).observe(original);
        var snapshot = await repo.bankBalance(account.id.value);
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(brightness: brightness),
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(
                body: StatefulBuilder(
                  builder: (context, update) => SingleChildScrollView(
                    child: BankBalancePanel(
                      snapshot: snapshot,
                      repository: repo,
                      enabled: true,
                      onChanged: () async {
                        final next = await repo.bankBalance(account.id.value);
                        update(() => snapshot = next);
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        expect(find.textContaining('شاهد ناقص است'), findsOneWidget);
        await tester.tap(find.text('بررسی شاهد مانده'));
        await tester.pumpAndSettle();
        expect(find.byType(BankObservationReview), findsOneWidget);
        await tester.enterText(find.byType(TextField), '250');
        await tester.tap(find.text('انصراف'));
        await tester.pumpAndSettle();
        expect(
          (await repo.bankBalance(account.id.value))
              .observations
              .single
              .revision,
          0,
        );
        await tester.tap(find.text('بررسی شاهد مانده'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), '250');
        await tester.tap(find.widgetWithText(FilledButton, 'تأیید بررسی شاهد'));
        await tester.pumpAndSettle();
        await tester.tap(
          find.widgetWithText(FilledButton, 'تأیید بررسی شاهد').last,
        );
        await tester.pumpAndSettle();
        expect(snapshot.observations.single.sourceAmount, 250);
        expect(snapshot.observations.single.revision, 1);
        expect(await repo.listEntries(), isEmpty);
        await tester.tap(find.text('بررسی شاهد مانده'));
        await tester.pumpAndSettle();
        // Another admitted writer advances the revision while the form is open.
        await repo.reviewBankObservation(
          expected: snapshot.observations.single,
          accountId: account.id.value,
          sourceAmount: 50,
          sourceUnit: 'rial',
          transactionTime: null,
          active: true,
        );
        await tester.enterText(find.byType(TextField), '300');
        await tester.tap(find.widgetWithText(FilledButton, 'تأیید بررسی شاهد'));
        await tester.pumpAndSettle();
        await tester.tap(
          find.widgetWithText(FilledButton, 'تأیید بررسی شاهد').last,
        );
        await tester.pumpAndSettle();
        expect(find.byType(BankObservationReview), findsOneWidget);
        expect(
          tester.widget<TextField>(find.byType(TextField)).controller!.text,
          '300',
        );
        expect(
          (await repo.bankBalance(account.id.value))
              .observations
              .single
              .sourceAmount,
          50,
        );
        expect(find.textContaining('تغییر'), findsWidgets);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
