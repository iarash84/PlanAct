import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/app_settings.dart';
import 'package:planact/app/money_unit_scope.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/finance/data/bank_balance_store.dart';
import 'package:planact/features/finance/data/drift_finance_repository.dart';
import 'package:planact/features/finance/domain/bank_balance.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/finance/presentation/bank_balance_panel.dart';
import 'package:planact/features/finance/presentation/bank_observation_review.dart';

void main() {
  for (final unit in IranianMoneyUnit.values) {
    testWidgets(
      'unknown report proposes persisted $unit only until confirmed',
      (tester) async {
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        addTearDown(db.close);
        final settings = AppSettings(db);
        await settings.writeMoneyUnit(unit);
        final controller = MoneyUnitController(settings);
        await controller.load();
        addTearDown(controller.dispose);
        final repo = DriftFinanceRepository(db);
        final account = FinancialAccount(
          id: StableId.generate(),
          name: 'حساب آزمایشی',
          currency: 'IRR',
          type: FinancialAccountType.bank,
        );
        await repo.saveAccount(account);
        final original = BankBalanceObservation(
          id: 'unknown',
          entryId: 'entry',
          accountId: account.id.value,
          irr: null,
          sourceAmount: 100,
          sourceUnit: null,
          transactionTime: null,
        );
        await BankBalanceStore(db).observe(original);
        await tester.pumpWidget(
          MaterialApp(
            theme: PlanActTheme.light(),
            builder: (_, child) => MoneyUnitScope(
              controller: controller,
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: child!,
              ),
            ),
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => showDialog<bool>(
                    context: context,
                    builder: (_) => BankObservationReview(
                      observation: original,
                      repository: repo,
                      accounts: [account],
                    ),
                  ),
                  child: const Text('بازکردن'),
                ),
              ),
            ),
          ),
        );
        final dropdown = find.byType(DropdownButton<String>).last;
        await tester.tap(find.text('بازکردن'));
        await tester.pumpAndSettle();
        expect(
          tester.widget<DropdownButton<String>>(dropdown).value,
          unit.name,
        );
        expect(
          (await repo.bankBalance(account.id.value))
              .observations
              .single
              .revision,
          0,
        );
        controller.value = unit == IranianMoneyUnit.rial
            ? IranianMoneyUnit.toman
            : IranianMoneyUnit.rial;
        await tester.pumpAndSettle();
        expect(
          tester.widget<DropdownButton<String>>(dropdown).value,
          unit.name,
        );
        await tester.tap(find.text('انصراف'));
        await tester.pumpAndSettle();
        expect(
          (await repo.bankBalance(account.id.value))
              .observations
              .single
              .sourceUnit,
          isNull,
        );
        controller.value = unit;
        await tester.tap(find.text('بازکردن'));
        await tester.pumpAndSettle();
        await tester.tap(
          find.widgetWithText(FilledButton, 'تأیید بررسی گزارش موجودی'),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.widgetWithText(FilledButton, 'تأیید بررسی گزارش موجودی').last,
        );
        await tester.pumpAndSettle();
        final reviewed = (await repo.bankBalance(account.id.value))
            .observations
            .single;
        expect(reviewed.sourceUnit, unit.name);
        expect(reviewed.sourceAmount, 100);
        expect(reviewed.irr, unit == IranianMoneyUnit.rial ? 100 : 1000);
        expect(reviewed.revision, 1);
        expect(await repo.listEntries(), isEmpty);
      },
    );
  }

  for (final brightness in Brightness.values) {
    testWidgets(
      'review preserves known unit and spaced narrow layout $brightness',
      (tester) async {
        tester.view.physicalSize = const Size(320, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        addTearDown(db.close);
        final controller = MoneyUnitController(null)
          ..value = IranianMoneyUnit.toman;
        addTearDown(controller.dispose);
        final account = FinancialAccount(
          id: StableId.generate(),
          name: 'حساب آزمایشی',
          currency: 'IRR',
          type: FinancialAccountType.bank,
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: brightness == Brightness.light
                ? PlanActTheme.light()
                : PlanActTheme.dark(),
            builder: (context, child) => MoneyUnitScope(
              controller: controller,
              child: MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(2)),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: child!,
                ),
              ),
            ),
            home: Scaffold(
              body: BankObservationReview(
                observation: BankBalanceObservation(
                  id: 'known',
                  entryId: 'entry',
                  accountId: account.id.value,
                  irr: 100,
                  sourceAmount: 100,
                  sourceUnit: 'rial',
                  transactionTime: DateTime(2026, 11, 21, 10, 30),
                ),
                repository: DriftFinanceRepository(db),
                accounts: [account],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final dropdowns = find.byType(DropdownButton<String>);
        expect(
          tester.widget<DropdownButton<String>>(dropdowns.last).value,
          'rial',
        );
        final amount = find.byType(TextField);
        expect(
          tester.getTopLeft(amount).dy -
              tester.getBottomLeft(dropdowns.first).dy,
          greaterThanOrEqualTo(PlanActSpacing.lg),
        );
        expect(
          tester.getTopLeft(dropdowns.last).dy -
              tester.getBottomLeft(amount).dy,
          greaterThanOrEqualTo(PlanActSpacing.lg),
        );
        await tester.ensureVisible(find.byType(SwitchListTile));
        await tester.pumpAndSettle();
        expect(find.byType(SwitchListTile).hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
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
        expect(find.textContaining('گزارش موجودی ناقص است'), findsOneWidget);
        await tester.tap(find.text('بررسی گزارش موجودی'));
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
        await tester.tap(find.text('بررسی گزارش موجودی'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), '250');
        await tester.tap(
          find.widgetWithText(FilledButton, 'تأیید بررسی گزارش موجودی'),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.widgetWithText(FilledButton, 'تأیید بررسی گزارش موجودی').last,
        );
        await tester.pumpAndSettle();
        expect(snapshot.observations.single.sourceAmount, 250);
        expect(snapshot.observations.single.revision, 1);
        expect(await repo.listEntries(), isEmpty);
        await tester.tap(find.text('بررسی گزارش موجودی'));
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
        await tester.tap(
          find.widgetWithText(FilledButton, 'تأیید بررسی گزارش موجودی'),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.widgetWithText(FilledButton, 'تأیید بررسی گزارش موجودی').last,
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
