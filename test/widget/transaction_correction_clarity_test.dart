import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/finance/domain/transaction_history.dart';
import 'package:planact/features/finance/presentation/transaction_card.dart';

void main() {
  for (final dark in [false, true]) {
    testWidgets('correction roles and read-only chain at 320dp/2x dark=$dark', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final account = StableId.generate();
      AccountEntry entry(
        AccountEntryType type,
        int amount, {
        String? reference,
        String? note,
      }) => AccountEntry(
        id: StableId.generate(),
        accountId: account,
        type: type,
        amount: Money(minorUnits: amount, currency: 'IRR'),
        occurredAt: DateTime.utc(2026, 11),
        referenceId: reference,
        note: note,
      );
      final original = entry(
        AccountEntryType.expense,
        100,
        note: 'یادداشت قبلی',
      );
      final reversal = entry(
        AccountEntryType.reversal,
        100,
        reference: original.id.value,
      );
      final replacement = entry(
        AccountEntryType.expense,
        200,
        reference: original.id.value,
        note: 'یادداشت کاربر',
      );
      final entries = projectTransactionHistory(
        [original, reversal, replacement],
        [
          FinanceHistoryOperation(
            before: [original.id.value],
            after: [reversal.id.value, replacement.id.value],
          ),
        ],
      );
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
          home: Scaffold(
            body: SingleChildScrollView(
              child: TransactionCard(
                entry: entries.last,
                label: 'هزینه',
                amount: '۲۰۰ ریال',
                children: [Text(entries.last.note!)],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('ثبت اصلاحی — جایگزین تراکنش قبلی'), findsOneWidget);
      expect(
        find.text('این ثبت، تراکنش مالی معتبرِ جایگزین است.'),
        findsOneWidget,
      );
      expect(find.text('یادداشت کاربر'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('مشاهدهٔ ثبت‌های مرتبط'));
      await tester.tap(find.text('مشاهدهٔ ثبت‌های مرتبط'));
      await tester.pumpAndSettle();
      expect(find.text('زنجیرهٔ ثبت‌های مرتبط'), findsOneWidget);
      expect(find.text('اصلاح‌شده'), findsOneWidget);
      await tester.ensureVisible(find.text('برگشت بابت اصلاح'));
      expect(
        find.text(
          'این ثبت اثر تراکنش قبلی را خنثی می‌کند و پرداخت مستقلی نیست.',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('بستن'));
      await tester.tap(find.text('بستن'));
      await tester.pumpAndSettle();
      expect(find.text('زنجیرهٔ ثبت‌های مرتبط'), findsNothing);
      expect(entries.last.note, 'یادداشت کاربر');
    });
  }
  testWidgets('reversed replacement never described as current valid entry', (
    tester,
  ) async {
    final raw = AccountEntry(
      id: StableId.generate(),
      accountId: StableId.generate(),
      type: AccountEntryType.income,
      amount: const Money(minorUnits: 200, currency: 'IRR'),
      occurredAt: DateTime.utc(2026),
    );
    final entry = raw.withHistory(
      const TransactionHistory(
        role: TransactionHistoryRole(replacement: true, reversed: true),
        chain: [],
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TransactionCard(
            entry: entry,
            label: 'درآمد',
            amount: '۲۰۰',
            children: const [],
          ),
        ),
      ),
    );
    expect(find.text('ثبت اصلاحی — جایگزین تراکنش قبلی'), findsOneWidget);
    expect(find.text('برگشت‌خورده — فقط سابقه؛ ثبت جاری نیست'), findsOneWidget);
    expect(find.text('این ثبت، تراکنش مالی معتبرِ جایگزین است.'), findsNothing);
  });
}
