import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/theme/planact_radius.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/finance/application/finance_use_cases.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/finance/presentation/account_identity_icon.dart';
import 'package:planact/features/finance/presentation/account_information_card.dart';
import 'package:planact/features/finance/presentation/finance_page.dart';

Future<void> tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  for (final dark in [false, true]) {
    testWidgets(
      'durable account links identify same-bank, cash, legacy and archived entries dark=$dark',
      (tester) async {
        tester.view.physicalSize = const Size(320, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final repository = InMemoryFinanceRepository();
        final accounts = [
          FinancialAccount(
            id: StableId.generate(),
            name: 'حساب شخصی',
            currency: 'IRR',
            type: FinancialAccountType.bank,
            bank: IranianBank.melli,
          ),
          FinancialAccount(
            id: StableId.generate(),
            name: 'حساب کاری',
            currency: 'IRR',
            type: FinancialAccountType.bank,
            bank: IranianBank.melli,
            status: FinancialAccountStatus.archived,
          ),
          FinancialAccount(
            id: StableId.generate(),
            name: 'وجه نقد',
            currency: 'IRR',
            type: FinancialAccountType.cash,
          ),
          FinancialAccount(
            id: StableId.generate(),
            name: 'حساب قدیمی',
            currency: 'IRR',
            type: FinancialAccountType.bank,
          ),
          FinancialAccount(
            id: StableId.generate(),
            name: 'کیف پول روزمره',
            currency: 'IRR',
            type: FinancialAccountType.digitalWallet,
          ),
        ];
        final transferGroup = StableId.generate();
        for (final account in accounts) {
          await repository.saveAccount(account);
          await repository.saveEntry(
            AccountEntry(
              id: StableId.generate(),
              accountId: account.id,
              type: account == accounts.first
                  ? AccountEntryType.transferOut
                  : account == accounts[1]
                  ? AccountEntryType.transferIn
                  : AccountEntryType.expense,
              transferGroupId: accounts.indexOf(account) < 2
                  ? transferGroup
                  : null,
              amount: const Money(minorUnits: 100, currency: 'IRR'),
              occurredAt: DateTime(2026, 11, 14),
              note: 'شرح گمراه‌کننده بانک ملت',
            ),
          );
        }
        final entries = await repository.listEntries();
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? PlanActTheme.dark() : PlanActTheme.light(),
            builder: (context, child) => Directionality(
              textDirection: TextDirection.rtl,
              child: MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(2)),
                child: child!,
              ),
            ),
            home: FinancePage(repository: repository),
          ),
        );
        await tester.pumpAndSettle();
        for (final entry in entries) {
          final account = accounts.singleWhere((a) => a.id == entry.accountId);
          final identity = find.byKey(
            ValueKey('transaction-account:${entry.id.value}'),
          );
          await tester.scrollUntilVisible(
            identity,
            250,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.ensureVisible(identity);
          await tester.pumpAndSettle();
          expect(
            find.descendant(of: identity, matching: find.text(account.name)),
            findsOneWidget,
          );
          final icon = tester.widget<AccountIdentityIcon>(
            find.descendant(
              of: identity,
              matching: find.byType(AccountIdentityIcon),
            ),
          );
          expect(icon.account.id, account.id);
          expect(icon.account.bank, account.bank);
          expect(icon.account.type, account.type);
          if (account.status == FinancialAccountStatus.archived) {
            expect(
              find.descendant(
                of: identity,
                matching: find.textContaining('بایگانی'),
              ),
              findsOneWidget,
            );
          }
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'missing linked account is disclosed without fabricating bank identity',
    (tester) async {
      final repository = InMemoryFinanceRepository();
      await repository.saveEntry(
        AccountEntry(
          id: StableId.generate(),
          accountId: StableId.generate(),
          type: AccountEntryType.income,
          amount: const Money(minorUnits: 10, currency: 'IRR'),
          occurredAt: DateTime(2026, 11, 14),
        ),
      );
      await tester.pumpWidget(
        MaterialApp(home: FinancePage(repository: repository)),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('اطلاعات حساب در دسترس نیست'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('اطلاعات حساب در دسترس نیست'), findsOneWidget);
      expect(find.byType(AccountIdentityIcon), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'management cards are separated and archive restore delete restriction stay inline',
    (tester) async {
      final repository = InMemoryFinanceRepository();
      final accounts = List.generate(
        2,
        (i) => FinancialAccount(
          id: StableId.generate(),
          name: 'حساب $i',
          currency: 'IRR',
          type: FinancialAccountType.cash,
        ),
      );
      for (final account in accounts) {
        await FinanceUseCases(repository).createAccount(
          account,
          openingBalance: const Money(minorUnits: 10, currency: 'IRR'),
        );
      }
      await tester.pumpWidget(
        MaterialApp(
          theme: PlanActTheme.light(),
          home: FinancePage(repository: repository),
        ),
      );
      await tester.pumpAndSettle();
      await tap(tester, find.byKey(const ValueKey('finance-accounts-entry')));
      final first = find.byKey(ValueKey(accounts.first.id));
      final second = find.byKey(ValueKey(accounts.last.id));
      await tester.ensureVisible(first);
      await tester.pumpAndSettle();
      final firstCard = find.descendant(of: first, matching: find.byType(Card));
      final secondCard = find.descendant(
        of: second,
        matching: find.byType(Card),
      );
      expect(
        tester.getTopLeft(secondCard).dy - tester.getBottomLeft(firstCard).dy,
        greaterThanOrEqualTo(PlanActSpacing.lg),
      );
      expect(find.byType(FinancePage), findsOneWidget);
      await tap(
        tester,
        find.byKey(ValueKey('account-menu:${accounts.first.id.value}')),
      );
      await tap(tester, find.text('بایگانی حساب'));
      await tap(tester, find.text('انصراف'));
      expect(
        (await repository.listAccounts()).first.status,
        FinancialAccountStatus.active,
      );
      await tap(
        tester,
        find.byKey(ValueKey('account-menu:${accounts.first.id.value}')),
      );
      await tap(tester, find.text('بایگانی حساب'));
      await tap(tester, find.text('تأیید'));
      expect(
        (await repository.listAccounts()).first.status,
        FinancialAccountStatus.archived,
      );
      await tap(tester, find.byType(SwitchListTile));
      await tap(
        tester,
        find.byKey(ValueKey('account-menu:${accounts.first.id.value}')),
      );
      await tap(tester, find.text('بازگردانی حساب'));
      await tap(tester, find.text('تأیید'));
      expect(
        (await repository.listAccounts()).first.status,
        FinancialAccountStatus.active,
      );
      await tap(
        tester,
        find.byKey(ValueKey('account-menu:${accounts.first.id.value}')),
      );
      await tap(tester, find.text('حذف حساب'));
      await tap(tester, find.text('تأیید'));
      expect(await repository.listAccounts(), hasLength(2));
      expect(await repository.listEntries(), hasLength(2));
      expect(find.byType(AccountInformationCard), findsWidgets);
      expect(find.byType(FinancePage), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'account card uses shared bordered surface and centers identity',
    (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      final account = FinancialAccount(
        id: StableId.generate(),
        name: 'حساب بانکی با نام بلند برای متن بزرگ',
        currency: 'IRR',
        type: FinancialAccountType.bank,
        bank: IranianBank.mellat,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: PlanActTheme.dark(),
          builder: (context, child) => Directionality(
            textDirection: TextDirection.rtl,
            child: MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
          ),
          home: Scaffold(
            body: SingleChildScrollView(
              child: AccountInformationCard(
                account: account,
                balance: const Money(minorUnits: 1234, currency: 'IRR'),
                operations: IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.more_vert),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final card = find.byType(AccountInformationCard);
      final outerCard = find.descendant(of: card, matching: find.byType(Card));
      final cardWidget = tester.widget<Card>(outerCard);
      final theme = Theme.of(tester.element(card));
      expect(cardWidget.color, isNull);
      expect(cardWidget.shape, isNull);
      final material = find
          .descendant(of: outerCard, matching: find.byType(Material))
          .first;
      final surface = tester.widget<Material>(material);
      expect(surface.color, theme.cardTheme.color);
      final shape = surface.shape! as RoundedRectangleBorder;
      expect(shape.borderRadius, PlanActRadius.card);
      expect(shape.side.color, theme.colorScheme.outlineVariant);

      final iconRect = tester.getRect(find.byType(AccountIdentityIcon));
      final nameRect = tester.getRect(find.text(account.name));
      expect((nameRect.center.dy - iconRect.center.dy).abs(), lessThan(1));
      expect(tester.getSize(find.byType(IconButton)), const Size(48, 48));
      expect(tester.takeException(), isNull);
    },
  );
}
