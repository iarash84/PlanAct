import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/features/finance/application/finance_use_cases.dart';
import 'package:planact/features/inbox/application/inbox_use_cases.dart';
import 'package:planact/features/inbox/domain/sms_currency_evidence.dart';
import 'package:planact/features/inbox/presentation/inbox_page.dart';

Future<void> _tap(WidgetTester tester, Finder target) async {
  expect(target, findsOneWidget);
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  expect(target.hitTestable(), findsOneWidget);
  await tester.tap(target.hitTestable());
  await tester.pumpAndSettle();
}

void main() {
  for (final dark in [false, true]) {
    testWidgets('ambiguous SMS explicit toman edit and cancellation ($dark)', (
      tester,
    ) async {
      final repository = InMemoryInboxRepository();
      final inbox = InboxUseCases(repository);
      final finance = InMemoryFinanceRepository();
      await inbox.stageSms(
        rawText: 'برداشت مبلغ 2500\nمانده: 900 ریال',
        sourceKey: 'ambiguous',
        currency: 'IRR',
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: dark ? PlanActTheme.dark() : PlanActTheme.light(),
          builder: (context, child) =>
              Directionality(textDirection: TextDirection.rtl, child: child!),
          home: Scaffold(
            body: InboxPage(inbox: inbox, finance: finance),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _tap(tester, find.text('ویرایش'));
      await _tap(tester, find.text('ذخیره و بررسی'));
      expect(
        find.text('واحد مبلغ نامشخص است؛ ریال یا تومان را انتخاب کنید.'),
        findsOneWidget,
      );
      expect(
        (await repository.listSuggestions())
            .single
            .draft
            .currencyEvidence!
            .requiresSelection,
        isTrue,
      );
      expect(find.text('ویرایش پیشنهاد تراکنش'), findsOneWidget);
      await _tap(tester, find.byType(DropdownButtonFormField<SmsMoneyUnit>));
      await _tap(tester, find.text('تومان').last);
      await _tap(tester, find.text('ذخیره و بررسی'));
      final selected = (await repository.listSuggestions()).single;
      expect(selected.draft.amount.minorUnits, 25000);
      expect(selected.draft.currencyEvidence!.selectedUnit, SmsMoneyUnit.toman);
      expect(await finance.listEntries(), isEmpty);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await _tap(tester, find.text('ویرایش'));
      Navigator.of(tester.element(find.byType(TextField).first)).pop();
      await tester.pumpAndSettle();
      expect(
        (await repository.listSuggestions()).single.revision,
        selected.revision,
      );
      expect(
        (await repository.listSuggestions()).single.draft.amount.minorUnits,
        25000,
      );
    });
  }
}
