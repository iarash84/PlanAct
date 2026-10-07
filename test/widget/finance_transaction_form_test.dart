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
