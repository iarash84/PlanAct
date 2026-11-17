import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/finance/application/finance_use_cases.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/finance/presentation/finance_page.dart';
import 'package:planact/features/finance/presentation/transaction_card.dart';

void main() {
  for (final dark in [false, true]) {
    for (final focused in [false, true]) {
      testWidgets(
        'transaction composition retains content and operations at 320dp/2x '
        '${dark ? 'dark' : 'light'} ${focused ? 'focused' : 'root'}',
        (tester) async {
          tester.view.physicalSize = const Size(320, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final repository = InMemoryFinanceRepository();
          final account = FinancialAccount(
            id: StableId.generate(),
            name: 'کیف پول روزمره با نام بلند برای بررسی خوانایی',
            currency: 'IRR',
            type: FinancialAccountType.cash,
          );
          final entry = AccountEntry(
            id: StableId.generate(),
            accountId: account.id,
            type: AccountEntryType.expense,
            amount: const Money(minorUnits: 123456789, currency: 'IRR'),
            occurredAt: DateTime(2026, 11, 14, 18, 37),
            category: 'خریدهای خانه',
            note: 'شرح کامل خرید روزانه با متن طولانی بدون حذف اطلاعات',
          );
          await repository.saveAccount(account);
          await repository.saveEntry(entry);
          StableId? relationship;
          await tester.pumpWidget(
            MaterialApp(
              theme: dark ? PlanActTheme.dark() : PlanActTheme.light(),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(2)),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: child!,
                ),
              ),
              home: FinancePage(
                repository: repository,
                focusedRecordId: focused ? entry.id.value : null,
                onDetermineRelationship: (id) async => relationship = id,
              ),
            ),
          );
          await tester.pumpAndSettle();
          final card = find.byType(TransactionCard);
          await tester.scrollUntilVisible(
            card,
            300,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.pumpAndSettle();
          Finder within(Finder matching) =>
              find.descendant(of: card, matching: matching);
          final amount = within(find.textContaining('۱۲۳,۴۵۶,۷۸۹'));
          final date = within(find.textContaining('۱۸:۳۷'));
          final description = within(
            find.text('${entry.category} · ${entry.note}'),
          );
          final identity = within(find.text(account.name));
          expect(amount, findsOneWidget);
          expect(date, findsOneWidget);
          expect(description, findsOneWidget);
          expect(identity, findsOneWidget);
          expect(
            tester.getTopLeft(amount).dy,
            lessThan(tester.getTopLeft(date).dy),
          );
          expect(
            tester.getTopLeft(date).dy,
            lessThan(tester.getTopLeft(description).dy),
          );
          expect(
            tester.getBottomLeft(description).dy,
            lessThan(tester.getTopLeft(identity).dy),
          );
          for (final finder in [amount, date, description, identity]) {
            final text = tester.widget<Text>(finder);
            expect(text.maxLines, isNull);
            expect(text.overflow, isNull);
            final rect = tester.getRect(finder);
            expect(rect.left, greaterThanOrEqualTo(0));
            expect(rect.right, lessThanOrEqualTo(320));
          }
          final menu = find.byKey(ValueKey('entry-menu:${entry.id.value}'));
          await tester.ensureVisible(menu);
          await tester.pumpAndSettle();
          expect(tester.getSize(menu).width, greaterThanOrEqualTo(48));
          expect(tester.getSize(menu).height, greaterThanOrEqualTo(48));
          await tester.tap(menu);
          await tester.pumpAndSettle();
          final items = tester.widgetList<PopupMenuItem<String>>(
            find.byType(PopupMenuItem<String>),
          );
          expect(
            items.map((item) => item.value),
            containsAll(['relationship', 'correct', 'void']),
          );
          await tester.tap(
            find.byWidgetPredicate(
              (widget) =>
                  widget is PopupMenuItem<String> &&
                  widget.value == 'relationship',
            ),
          );
          await tester.pumpAndSettle();
          expect(relationship, entry.id);
          await tester.tap(menu);
          await tester.pumpAndSettle();
          // Dismissing the operations menu is browsing, not a durable write.
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          final saved = (await repository.listEntries()).single;
          expect(saved.id, entry.id);
          expect(saved.amount, entry.amount);
          expect(saved.occurredAt, entry.occurredAt);
          expect(saved.note, entry.note);
          expect(saved.category, entry.category);
          expect(saved.accountId, account.id);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
