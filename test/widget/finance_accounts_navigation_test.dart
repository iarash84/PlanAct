import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/finance/application/finance_use_cases.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/finance/presentation/account_information_card.dart';
import 'package:planact/features/finance/presentation/finance_page.dart';

class _Repository extends InMemoryFinanceRepository {
  bool fail = false;
  @override
  Future<List<FinancialAccount>> listAccounts() async {
    if (fail) throw StateError('injected read failure');
    return super.listAccounts();
  }
}

Future<_Repository> _seed() async {
  final repository = _Repository();
  for (var i = 0; i < 80; i++) {
    final account = FinancialAccount(
      id: StableId.generate(),
      name: 'حساب $i',
      currency: i == 79 ? 'USD' : 'IRR',
      type: FinancialAccountType.bank,
      bank: IranianBank.melli,
      status: i == 78
          ? FinancialAccountStatus.archived
          : FinancialAccountStatus.active,
    );
    await repository.saveAccount(account);
    for (var j = 0; j < (i == 0 ? 45 : 1); j++) {
      await repository.saveEntry(
        AccountEntry(
          id: StableId.generate(),
          accountId: account.id,
          type: j.isEven ? AccountEntryType.income : AccountEntryType.expense,
          amount: Money(minorUnits: 100, currency: account.currency),
          occurredAt: DateTime(2026, 11, 1).subtract(Duration(minutes: j)),
          note: 'سند $i/$j',
        ),
      );
    }
  }
  return repository;
}

Future<void> _open(
  WidgetTester tester,
  _Repository repository, {
  bool dark = false,
  double scale = 1,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: dark ? PlanActTheme.dark() : PlanActTheme.light(),
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
      ),
      home: FinancePage(repository: repository),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  for (final dark in [false, true]) {
    testWidgets(
      '80 accounts: compact root, lazy cards, search and inline actions at 320dp 2x dark=$dark',
      (tester) async {
        tester.view.physicalSize = const Size(320, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final repository = await _seed();
        final before = await repository.listEntries();
        await _open(tester, repository, dark: dark, scale: 2);
        expect(find.byType(AccountInformationCard), findsNothing);
        expect(
          find.byKey(const ValueKey('finance-accounts-entry')),
          findsOneWidget,
        );
        await _tapVisible(
          tester,
          find.byKey(const ValueKey('finance-accounts-entry')),
        );
        expect(find.byType(AccountInformationCard), findsWidgets);
        expect(
          find.byType(AccountInformationCard).evaluate().length,
          lessThan(10),
        );
        await tester.enterText(
          find.byKey(const ValueKey('accounts-search')),
          'حساب 79',
        );
        await tester.pumpAndSettle();
        final account = (await repository.listAccounts()).singleWhere(
          (a) => a.name == 'حساب 79',
        );
        final row = find.byKey(ValueKey('account-row:${account.id.value}'));
        await tester.scrollUntilVisible(
          row,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await _tapVisible(tester, find.byTooltip('ویرایش حساب'));
        expect(find.byType(FinancePage), findsOneWidget);
        await tester.tap(find.text('انصراف'));
        await tester.pumpAndSettle();
        expect(find.byType(AccountInformationCard), findsOneWidget);
        expect(find.textContaining('USD'), findsWidgets);
        expect(
          tester
                  .widget<TextField>(
                    find.byKey(const ValueKey('accounts-search')),
                  )
                  .controller
                  ?.text ??
              tester
                  .widget<EditableText>(find.byType(EditableText))
                  .controller
                  .text,
          'حساب 79',
        );
        expect(await repository.listEntries(), before);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'account transaction route retains parent page and refreshes full-ledger balance',
    (tester) async {
      final repository = await _seed();
      final account = (await repository.listAccounts()).first;
      await _open(tester, repository);
      final filter = find.byType(DropdownButtonFormField<StableId>);
      await _tapVisible(tester, filter);
      await tester.tap(find.text('حساب 0').last);
      await tester.pumpAndSettle();
      final next = find.widgetWithText(OutlinedButton, 'صفحهٔ بعد').first;
      await _tapVisible(tester, next);
      expect(find.textContaining('صفحهٔ ۲ از ۳'), findsWidgets);
      final scroll = tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position;
      scroll.jumpTo(0);
      await tester.pumpAndSettle();
      final accountsEntry = find.byKey(
        const ValueKey('finance-accounts-entry'),
      );
      await tester.ensureVisible(accountsEntry);
      await tester.pumpAndSettle();
      final retainedOffset = scroll.pixels;
      await tester.tap(accountsEntry);
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byKey(ValueKey(account.id)),
          matching: find.text('\u2066۱۰۰\u2069 ریال'),
        ),
        findsOneWidget,
      );
      await _tapVisible(
        tester,
        find.descendant(
          of: find.byKey(ValueKey(account.id)),
          matching: find.byTooltip('مشاهدهٔ تراکنش‌های این حساب'),
        ),
      );
      expect(
        tester
            .widget<DropdownButtonFormField<StableId>>(
              find.byType(DropdownButtonFormField<StableId>),
            )
            .initialValue,
        account.id,
      );
      await repository.saveEntry(
        AccountEntry(
          id: StableId.generate(),
          accountId: account.id,
          type: AccountEntryType.income,
          amount: const Money(minorUnits: 700, currency: 'IRR'),
          occurredAt: DateTime(2026, 11, 2),
        ),
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('\u2066۸۰۰\u2069 ریال'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(scroll.pixels, retainedOffset);
      await tester.scrollUntilVisible(
        find.text('آخرین تراکنش‌ها'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('صفحهٔ ۲ از ۳'), findsWidgets);
      expect(
        tester.widget<DropdownButtonFormField<StableId>>(filter).initialValue,
        account.id,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'account filter combines with type and clears without ledger writes',
    (tester) async {
      final repository = await _seed();
      final before = await repository.listEntries();
      await _open(tester, repository);
      final filter = find.byType(DropdownButtonFormField<StableId>);
      await _tapVisible(tester, filter);
      await tester.tap(find.text('حساب 0').last);
      await tester.pumpAndSettle();
      await _tapVisible(tester, find.byType(DropdownButton<AccountEntryType?>));
      await tester.tap(find.text('ورودی').hitTestable().last);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('آخرین تراکنش‌ها'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('صفحهٔ ۱ از ۲'), findsWidgets);
      await tester.scrollUntilVisible(
        filter,
        -300,
        scrollable: find.byType(Scrollable).first,
      );
      await _tapVisible(tester, filter);
      await tester.ensureVisible(find.text('همهٔ حساب‌ها').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('همهٔ حساب‌ها').hitTestable().last);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('آخرین تراکنش‌ها'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('صفحهٔ ۱ از ۶'), findsWidgets);
      expect(await repository.listEntries(), before);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('management refresh failure retains search and supports retry', (
    tester,
  ) async {
    final repository = await _seed();
    await _open(tester, repository);
    await _tapVisible(
      tester,
      find.byKey(const ValueKey('finance-accounts-entry')),
    );
    await tester.enterText(
      find.byKey(const ValueKey('accounts-search')),
      'حساب 0',
    );
    await tester.pumpAndSettle();
    repository.fail = true;
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 500));
    await tester.pumpAndSettle();
    expect(
      find.text('اطلاعات نمایش‌داده‌شده ممکن است قدیمی باشد.'),
      findsOneWidget,
    );
    repository.fail = false;
    await _tapVisible(tester, find.text('تلاش دوباره'));
    expect(
      find.text('اطلاعات نمایش‌داده‌شده ممکن است قدیمی باشد.'),
      findsNothing,
    );
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).controller.text,
      'حساب 0',
    );
    expect(tester.takeException(), isNull);
  });
}
