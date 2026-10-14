import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/money_unit_scope.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/finance/application/finance_use_cases.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/finance/presentation/finance_page.dart';
import 'package:planact/features/inbox/application/inbox_use_cases.dart';
import 'package:planact/features/inbox/domain/inbox.dart';
import 'package:planact/features/inbox/domain/sms_currency_evidence.dart';
import 'package:planact/features/inbox/presentation/inbox_page.dart';
import 'package:planact/features/quick_add/presentation/quick_add_sheet.dart';

Future<void> tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target.hitTestable());
  await tester.pumpAndSettle();
}

FinancialAccount account() => FinancialAccount(
  id: StableId.generate(),
  name: 'نقد',
  currency: 'IRR',
  type: FinancialAccountType.cash,
);

class _FailOnceFinance extends InMemoryFinanceRepository {
  bool fail = true;
  @override
  Future<void> saveEntry(AccountEntry entry) async {
    if (fail) {
      fail = false;
      throw StateError('injected write failure');
    }
    await super.saveEntry(entry);
  }
}

Widget app(MoneyUnitController controller, Widget home) => MaterialApp(
  theme: controller.value == IranianMoneyUnit.toman
      ? PlanActTheme.dark()
      : PlanActTheme.light(),
  builder: (_, child) => MoneyUnitScope(
    controller: controller,
    child: Directionality(textDirection: TextDirection.rtl, child: child!),
  ),
  home: Scaffold(body: home),
);

void main() {
  for (final unit in IranianMoneyUnit.values) {
    testWidgets(
      'Inbox accepts pinned $unit default without editing; cancel writes nothing',
      (tester) async {
        final controller = MoneyUnitController(null)..value = unit;
        addTearDown(controller.dispose);
        final repo = InMemoryInboxRepository();
        final inbox = InboxUseCases(repo);
        final finance = _FailOnceFinance();
        await finance.saveAccount(account());
        await inbox.stageSms(
          rawText: 'برداشت مبلغ 2500\nتاریخ: 2026-10-14\nساعت: 12:30',
          sourceKey: 'default',
          currency: 'IRR',
        );
        var refreshes = 0;
        await tester.pumpWidget(
          app(
            controller,
            InboxPage(
              inbox: inbox,
              finance: finance,
              onDataChanged: () async {
                refreshes++;
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('پیشنهاد پیش‌فرض برنامه'), findsOneWidget);
        await tap(tester, find.text('تأیید و ثبت'));
        final expected = unit == IranianMoneyUnit.toman
            ? SmsMoneyUnit.toman
            : SmsMoneyUnit.rial;
        expect(
          tester
              .widget<DropdownButtonFormField<SmsMoneyUnit>>(
                find.byType(DropdownButtonFormField<SmsMoneyUnit>),
              )
              .initialValue,
          expected,
        );
        await tap(tester, find.text('انصراف'));
        expect((await repo.listSuggestions()).single.revision, 0);
        expect(
          (await repo.listSuggestions())
              .single
              .draft
              .currencyEvidence!
              .requiresSelection,
          isTrue,
        );
        expect(await finance.listEntries(), isEmpty);
        await tap(tester, find.text('ویرایش'));
        expect(
          tester
              .widget<DropdownButtonFormField<SmsMoneyUnit>>(
                find.byType(DropdownButtonFormField<SmsMoneyUnit>),
              )
              .initialValue,
          expected,
        );
        expect(
          tester
              .widget<TextField>(find.byType(TextField).first)
              .controller!
              .text,
          '2,500',
        );
        await tap(tester, find.text('انصراف'));
        expect((await repo.listSuggestions()).single.revision, 0);
        await tap(tester, find.text('تأیید و ثبت'));
        controller.value = unit == IranianMoneyUnit.toman
            ? IranianMoneyUnit.rial
            : IranianMoneyUnit.toman;
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<DropdownButtonFormField<SmsMoneyUnit>>(
                find.byType(DropdownButtonFormField<SmsMoneyUnit>),
              )
              .initialValue,
          expected,
        );
        await tap(
          tester,
          find.text('ثبت مالی به‌عنوان هزینه را تأیید می‌کنم.'),
        );
        await tap(
          tester,
          find.byType(DropdownButtonFormField<FinancialAccount>),
        );
        await tap(tester, find.text('نقد').last);
        await tap(tester, find.text('تأیید نهایی'));
        expect(find.textContaining('انتخاب شما حفظ شده‌اند'), findsOneWidget);
        expect((await repo.listSuggestions()).single.revision, 0);
        expect(await finance.listEntries(), isEmpty);
        await tap(tester, find.text('تأیید نهایی'));
        expect(
          (await finance.listEntries()).single.amount.minorUnits,
          unit == IranianMoneyUnit.toman ? 25000 : 2500,
        );
        final stored = (await repo.listSuggestions()).single;
        expect(stored.status, SuggestionStatus.confirmed);
        expect(stored.draft.currencyEvidence!.selectedUnit, expected);
        expect(
          stored.extractedEvidence!.draft.currencyEvidence!.requiresSelection,
          isTrue,
        );
        expect(find.text('صف بررسی خالی است'), findsOneWidget);
        expect(refreshes, 1);
      },
    );
  }

  testWidgets('detected SMS rial is preserved under app toman preference', (
    tester,
  ) async {
    final controller = MoneyUnitController(null)
      ..value = IranianMoneyUnit.toman;
    addTearDown(controller.dispose);
    final repo = InMemoryInboxRepository();
    final inbox = InboxUseCases(repo);
    final finance = InMemoryFinanceRepository();
    await finance.saveAccount(account());
    await inbox.stageSms(
      rawText: 'برداشت مبلغ 2500 ریال\nتاریخ: 2026-10-14\nساعت: 12:30',
      sourceKey: 'explicit',
      currency: 'IRR',
    );
    await tester.pumpWidget(
      app(controller, InboxPage(inbox: inbox, finance: finance)),
    );
    await tester.pumpAndSettle();
    expect(find.text('۲۵۰ تومان'), findsOneWidget);
    await tap(tester, find.text('تأیید و ثبت'));
    expect(find.byType(DropdownButtonFormField<SmsMoneyUnit>), findsNothing);
    await tap(tester, find.text('ثبت مالی به‌عنوان هزینه را تأیید می‌کنم.'));
    await tap(tester, find.byType(DropdownButtonFormField<FinancialAccount>));
    await tap(tester, find.text('نقد').last);
    await tap(tester, find.text('تأیید نهایی'));
    expect((await finance.listEntries()).single.amount.minorUnits, 2500);
  });

  testWidgets('confirmation can override app rial proposal with toman', (
    tester,
  ) async {
    final controller = MoneyUnitController(null);
    addTearDown(controller.dispose);
    final repo = InMemoryInboxRepository();
    final inbox = InboxUseCases(repo);
    final finance = InMemoryFinanceRepository();
    await finance.saveAccount(account());
    await inbox.stageSms(
      rawText: 'برداشت مبلغ 2500\nتاریخ: 2026-10-14\nساعت: 12:30',
      sourceKey: 'override',
      currency: 'IRR',
    );
    await tester.pumpWidget(
      app(controller, InboxPage(inbox: inbox, finance: finance)),
    );
    await tester.pumpAndSettle();
    await tap(tester, find.text('تأیید و ثبت'));
    await tap(tester, find.byType(DropdownButtonFormField<SmsMoneyUnit>));
    await tap(tester, find.text('تومان').last);
    expect(find.text('۲,۵۰۰ تومان'), findsOneWidget);
    await tap(tester, find.text('ثبت مالی به‌عنوان هزینه را تأیید می‌کنم.'));
    await tap(tester, find.byType(DropdownButtonFormField<FinancialAccount>));
    await tap(tester, find.text('نقد').last);
    await tap(tester, find.text('تأیید نهایی'));
    expect((await finance.listEntries()).single.amount.minorUnits, 25000);
    expect(
      (await repo.listSuggestions())
          .single
          .draft
          .currencyEvidence!
          .selectedUnit,
      SmsMoneyUnit.toman,
    );
  });

  for (final income in [false, true]) {
    testWidgets(
      'manual Finance and Quick Add use app toman default ($income)',
      (tester) async {
        final controller = MoneyUnitController(null)
          ..value = IranianMoneyUnit.toman;
        addTearDown(controller.dispose);
        final finance = InMemoryFinanceRepository();
        final selected = account();
        await finance.saveAccount(selected);
        final key = GlobalKey<FinancePageState>();
        await tester.pumpWidget(
          app(controller, FinancePage(key: key, repository: finance)),
        );
        await tester.pumpAndSettle();
        key.currentState!.openTransactionForm(income: income);
        await tester.pumpAndSettle();
        await tester.enterText(
          find.widgetWithText(TextField, 'مبلغ به تومان'),
          '2500',
        );
        await tap(
          tester,
          find.byType(DropdownButtonFormField<FinancialAccount>),
        );
        await tap(tester, find.text('نقد').last);
        await tap(tester, find.text('ثبت'));
        expect((await finance.listEntries()).single.amount.minorUnits, 25000);
        expect((await finance.listEntries()).single.amount.currency, 'IRR');
        QuickFinancialEntry? result;
        await tester.pumpWidget(
          app(
            controller,
            Builder(
              builder: (context) => TextButton(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => QuickFinancialEntrySheet(
                    accounts: [selected],
                    income: income,
                    onSave: (entry) async {
                      result = entry;
                    },
                  ),
                ),
                child: const Text('سریع'),
              ),
            ),
          ),
        );
        await tap(tester, find.text('سریع'));
        await tester.enterText(
          find.widgetWithText(TextField, 'مبلغ به تومان'),
          '2500',
        );
        await tap(tester, find.text('ثبت'));
        expect(result!.amount, 25000);
        expect(result!.account!.currency, 'IRR');
      },
    );
  }
}
