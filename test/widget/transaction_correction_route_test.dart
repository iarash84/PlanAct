import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/finance/application/finance_use_cases.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/finance/presentation/finance_page.dart';

void main() {
  testWidgets(
    'Finance correction confirms, refreshes and browses projected roles',
    (tester) async {
      final repository = InMemoryFinanceRepository();
      final commands = FinanceUseCases(repository);
      final account = FinancialAccount(
        id: StableId.generate(),
        name: 'حساب',
        currency: 'IRR',
        type: FinancialAccountType.bank,
      );
      await commands.createAccount(account);
      final original = await commands.record(
        account: account,
        type: AccountEntryType.expense,
        amount: const Money(minorUnits: 500, currency: 'IRR'),
        occurredAt: DateTime.utc(2026, 11, 1),
        note: 'یادداشت اصلی',
      );
      var refreshes = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: FinancePage(
            repository: repository,
            onDataChanged: () async {
              refreshes++;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      final menu = find.byKey(ValueKey('entry-menu:${original.id.value}'));
      await tester.ensureVisible(menu);
      await tester.pumpAndSettle();
      await tester.tap(menu);
      await tester.pumpAndSettle();
      await tester.tap(find.text('اصلاح تراکنش'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'مبلغ به ریال'),
        '700',
      );
      await tester.tap(find.text('ثبت'));
      // The form intentionally stays saving while confirmation is outstanding.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(await repository.listEntries(), hasLength(1));
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(FilledButton),
        ),
      );
      await tester.pumpAndSettle();
      expect(refreshes, 1);
      expect(await repository.listEntries(), hasLength(3));
      expect((await commands.balance(account)).minorUnits, -700);
      final open = find.text('مشاهدهٔ ثبت‌های مرتبط').first;
      await tester.ensureVisible(open);
      await tester.pumpAndSettle();
      await tester.tap(open);
      await tester.pumpAndSettle();
      expect(find.text('زنجیرهٔ ثبت‌های مرتبط'), findsOneWidget);
      expect(find.text('اصلاح‌شده'), findsWidgets);
      expect(find.text('برگشت بابت اصلاح'), findsWidgets);
      expect(find.text('ثبت اصلاحی — جایگزین تراکنش قبلی'), findsWidgets);
      expect(find.text('یادداشت اصلی'), findsWidgets);
      await tester.tap(find.text('بستن'));
      await tester.pumpAndSettle();
      expect(await repository.listEntries(), hasLength(3));
      expect((await commands.balance(account)).minorUnits, -700);
      expect(tester.takeException(), isNull);
    },
  );
}
