import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/features/finance/application/finance_use_cases.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/finance/presentation/finance_page.dart';

class _FailingFinanceRepository extends InMemoryFinanceRepository {
  bool fail = true;
  @override
  Future<List<FinancialAccount>> listAccounts() async {
    if (fail) throw StateError('offline read failed');
    return super.listAccounts();
  }
}

void main() {
  testWidgets('initial finance failure shows retry, not an empty ledger', (
    tester,
  ) async {
    final repository = _FailingFinanceRepository();
    await tester.pumpWidget(
      MaterialApp(home: FinancePage(repository: repository)),
    );
    await tester.pumpAndSettle();
    expect(
      find.textContaining('بارگذاری اطلاعات مالی انجام نشد'),
      findsOneWidget,
    );
    expect(find.text('هنوز حسابی ثبت نشده است.'), findsNothing);
    repository.fail = false;
    await tester.tap(find.text('تلاش دوباره'));
    await tester.pumpAndSettle();
    expect(find.text('هنوز حسابی ثبت نشده است.'), findsOneWidget);
  });

  testWidgets('failed refresh keeps prior finance data and warns it is stale', (
    tester,
  ) async {
    final repository = _FailingFinanceRepository()..fail = false;
    await tester.pumpWidget(
      MaterialApp(home: FinancePage(repository: repository)),
    );
    await tester.pumpAndSettle();
    expect(find.text('هنوز حسابی ثبت نشده است.'), findsOneWidget);

    repository.fail = true;
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 400));
    await tester.pumpAndSettle();
    expect(find.text('هنوز حسابی ثبت نشده است.'), findsOneWidget);
    expect(
      find.text('اطلاعات نمایش‌داده‌شده ممکن است قدیمی باشد.'),
      findsOneWidget,
    );

    repository.fail = false;
    await tester.tap(find.text('تلاش دوباره'));
    await tester.pumpAndSettle();
    expect(
      find.text('اطلاعات نمایش‌داده‌شده ممکن است قدیمی باشد.'),
      findsNothing,
    );
  });
}
