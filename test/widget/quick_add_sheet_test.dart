import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/quick_add/presentation/quick_add_sheet.dart';

void main() {
  final account = FinancialAccount(
    id: StableId.generate(),
    name: 'حساب اصلی',
    currency: 'تومان',
    type: FinancialAccountType.bank,
  );

  Widget host(Widget child) => MaterialApp(
    locale: const Locale('fa'),
    home: Directionality(textDirection: TextDirection.rtl, child: child),
  );

  testWidgets('shows only supported quick add actions', (tester) async {
    await tester.pumpWidget(host(const Scaffold(body: QuickAddSheet())));

    expect(find.text('افزودن سریع'), findsOneWidget);
    expect(find.text('هزینه'), findsOneWidget);
    expect(find.text('درآمد'), findsOneWidget);
    expect(find.text('انتقال'), findsOneWidget);
    expect(find.text('تعهد'), findsOneWidget);
    expect(find.text('یادداشت'), findsNothing);
  });

  testWidgets('quick expense validates and preserves input on failure', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        Scaffold(
          body: QuickFinancialEntrySheet(accounts: [account], income: false),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('quick-financial-save')));
    await tester.pump();
    expect(find.text('مبلغ معتبر وارد کنید.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('quick-financial-amount')),
      '۳۸۰',
    );
    final amountField = tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(const ValueKey('quick-financial-amount')),
        matching: find.byType(EditableText),
      ),
    );
    expect(amountField.controller.text, isNotEmpty);
  });

  testWidgets('quick income returns a shared command payload', (tester) async {
    await tester.pumpWidget(
      host(
        Scaffold(
          body: QuickFinancialEntrySheet(accounts: [account], income: true),
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey('quick-financial-amount')),
      '120',
    );
    await tester.tap(find.byKey(const ValueKey('quick-financial-save')));
    await tester.pumpAndSettle();

    expect(find.text('ثبت سریع درآمد'), findsNothing);
  });
}
