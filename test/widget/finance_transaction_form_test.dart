import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/finance/application/finance_use_cases.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/finance/presentation/finance_page.dart';

class _RetryFinanceRepository extends InMemoryFinanceRepository {
  int attempts = 0;
  bool failRefresh = false;

  @override
  Future<void> saveEntry(AccountEntry entry) async {
    attempts++;
    if (attempts == 1) throw StateError('write unavailable');
    await super.saveEntry(entry);
  }

  @override
  Future<List<AccountEntry>> listEntries() async {
    if (failRefresh) throw StateError('read unavailable');
    return super.listEntries();
  }
}

void main() {
  testWidgets(
    'manual draft survives account creation and still requires selection',
    (tester) async {
      final repository = InMemoryFinanceRepository();
      final key = GlobalKey<FinancePageState>();
      await tester.pumpWidget(
        MaterialApp(
          home: FinancePage(key: key, repository: repository),
        ),
      );
      await tester.pumpAndSettle();
      key.currentState!.openTransactionForm(income: false);
      await tester.pumpAndSettle();
      expect(find.textContaining('برای ثبت، حساب بسازید'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextField, 'مبلغ به ریال'),
        '500',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'شرح هزینه'),
        'پیش‌نویس',
      );
      await tester.tap(find.text('ساخت حساب'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'نام حساب'),
        'حساب تازه',
      );
      await tester.tap(find.text('افزودن').last);
      await tester.pumpAndSettle();
      expect(find.text('500'), findsOneWidget);
      expect(find.text('پیش‌نویس'), findsOneWidget);
      await tester.tap(find.text('ثبت'));
      await tester.pumpAndSettle();
      expect(find.text('حساب مالی را انتخاب کنید.'), findsOneWidget);
      expect(await repository.listEntries(), isEmpty);
      await tester.tap(find.byType(DropdownButtonFormField<FinancialAccount>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('حساب تازه').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('ثبت'));
      await tester.tap(find.text('ثبت'));
      await tester.pumpAndSettle();
      final entries = await repository.listEntries();
      expect(entries, hasLength(1));
      expect(entries.single.amount.minorUnits, 500);
      expect(entries.single.note, 'پیش‌نویس');
    },
  );

  testWidgets('failed write retains transaction draft and retry writes once', (
    tester,
  ) async {
    final repository = _RetryFinanceRepository();
    await repository.saveAccount(
      FinancialAccount(
        id: StableId.generate(),
        name: 'حساب آزمایشی',
        currency: 'IRR',
        type: FinancialAccountType.cash,
      ),
    );
    final key = GlobalKey<FinancePageState>();
    await tester.pumpWidget(
      MaterialApp(
        home: FinancePage(key: key, repository: repository),
      ),
    );
    await tester.pumpAndSettle();
    key.currentState!.openTransactionForm(income: false);
    await tester.pumpAndSettle();
    await tester.tap(find.text('ثبت'));
    await tester.pumpAndSettle();
    expect(find.text('حساب مالی را انتخاب کنید.'), findsOneWidget);
    expect(repository.attempts, 0);
    await tester.tap(find.byType(DropdownButtonFormField<FinancialAccount>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('حساب آزمایشی').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'مبلغ به ریال'),
      '12345',
    );
    await tester.enterText(find.widgetWithText(TextField, 'شرح هزینه'), 'خرید');
    await tester.tap(find.text('ثبت'));
    await tester.pumpAndSettle();
    expect(find.textContaining('اطلاعات شما حفظ شده است'), findsOneWidget);
    expect(find.text('خرید'), findsOneWidget);
    expect(repository.attempts, 1);

    await tester.tap(find.text('ثبت'));
    await tester.pumpAndSettle();
    expect(repository.attempts, 2);
    final entries = await repository.listEntries();
    expect(entries, hasLength(1));
    expect(entries.single.amount.minorUnits, 12345);
    expect(entries.single.note, 'خرید');
  });

  testWidgets('refresh failure after write cannot trigger duplicate save', (
    tester,
  ) async {
    final repository = _RetryFinanceRepository();
    await repository.saveAccount(
      FinancialAccount(
        id: StableId.generate(),
        name: 'حساب آزمایشی',
        currency: 'IRR',
        type: FinancialAccountType.cash,
      ),
    );
    final key = GlobalKey<FinancePageState>();
    await tester.pumpWidget(
      MaterialApp(
        home: FinancePage(key: key, repository: repository),
      ),
    );
    await tester.pumpAndSettle();
    key.currentState!.openTransactionForm(income: true);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<FinancialAccount>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('حساب آزمایشی').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'مبلغ به ریال'),
      '100',
    );
    await tester.tap(find.text('ثبت'));
    await tester.pumpAndSettle();
    expect(repository.attempts, 1);
    repository.failRefresh = true;
    await tester.tap(find.text('ثبت'));
    await tester.pumpAndSettle();
    expect(repository.attempts, 2);
    expect(find.text('ثبت درآمد / واریز'), findsNothing);
    expect(
      find.text('اطلاعات نمایش‌داده‌شده ممکن است قدیمی باشد.'),
      findsOneWidget,
    );
  });
}
