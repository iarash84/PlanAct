import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/app_settings.dart';
import 'package:planact/app/money_unit_scope.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/finance/application/finance_use_cases.dart';
import 'package:planact/features/finance/data/drift_finance_repository.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/finance/presentation/account_information_card.dart';
import 'package:planact/features/finance/presentation/finance_page.dart';

void main() {
  for (final unit in IranianMoneyUnit.values) {
    for (final dark in [false, true]) {
      testWidgets('Finance RTL signs and labels: $unit dark=$dark', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(320, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        final repository = DriftFinanceRepository(db);
        final controller = MoneyUnitController(AppSettings(db));
        addTearDown(() async {
          await tester.pumpWidget(const SizedBox.shrink());
          controller.dispose();
          await tester.runAsync(db.close);
        });
        await tester.runAsync(() async {
          await controller.load();
          await controller.select(unit);
          final account = FinancialAccount(
            id: StableId.generate(),
            name: 'حساب آزمون',
            currency: 'IRR',
            type: FinancialAccountType.cash,
          );
          await repository.saveAccount(account);
          for (final (type, amount) in [
            (AccountEntryType.expense, 13000),
            (AccountEntryType.income, 659),
          ]) {
            await FinanceUseCases(repository).record(
              account: account,
              type: type,
              amount: Money(minorUnits: amount, currency: 'IRR'),
              occurredAt: DateTime(2026, 11, 10),
            );
          }
        });
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? PlanActTheme.dark() : PlanActTheme.light(),
            builder: (context, child) => MoneyUnitScope(
              controller: controller,
              child: MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(2)),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: child!,
                ),
              ),
            ),
            home: FinancePage(repository: repository),
          ),
        );
        for (var i = 0; i < 12; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)),
          );
          await tester.pump(const Duration(milliseconds: 100));
        }
        await tester.pumpAndSettle();
        final balance = find.descendant(
          of: find.byType(AccountInformationCard),
          matching: find.text(
            unit == IranianMoneyUnit.rial
                ? '\u2066-۱۲,۳۴۱\u2069 ریال'
                : '\u2066-۱,۲۳۴٫۱\u2069 تومان',
          ),
        );
        await tester.scrollUntilVisible(balance, 150);
        await tester.pumpAndSettle();
        expect(balance, findsOneWidget);
        final paragraph = tester.renderObject<RenderParagraph>(
          find.descendant(of: balance, matching: find.byType(RichText)),
        );
        final minus = paragraph
            .getBoxesForSelection(
              const TextSelection(baseOffset: 1, extentOffset: 2),
            )
            .single;
        final firstDigit = paragraph
            .getBoxesForSelection(
              const TextSelection(baseOffset: 2, extentOffset: 3),
            )
            .single;
        expect(minus.right, lessThanOrEqualTo(firstDigit.left));
        for (final (label, amount) in [
          (
            'برداشت',
            unit == IranianMoneyUnit.rial
                ? '\u2066۱۳,۰۰۰\u2069 ریال'
                : '\u2066۱,۳۰۰\u2069 تومان',
          ),
          (
            'واریز',
            unit == IranianMoneyUnit.rial
                ? '\u2066۶۵۹\u2069 ریال'
                : '\u2066۶۵٫۹\u2069 تومان',
          ),
        ]) {
          await tester.scrollUntilVisible(find.text(label), 150);
          await tester.pumpAndSettle();
          final card = find.ancestor(
            of: find.text(label),
            matching: find.byType(Card),
          );
          final amountText = find.descendant(
            of: card,
            matching: find.text(amount),
          );
          expect(amountText, findsOneWidget);
          expect(
            tester.getRect(amountText).top,
            greaterThanOrEqualTo(tester.getRect(find.text(label)).bottom),
          );
          expect(find.textContaining('$label ·'), findsNothing);
        }
        await tester.runAsync(() async {
          final entries = await repository.listEntries();
          expect(entries, hasLength(2));
          expect(
            rebuildBalance(
              (await repository.listAccounts()).single,
              entries,
            ).minorUnits,
            -12341,
          );
        });
        expect(tester.takeException(), isNull);
      });
    }
  }
}
