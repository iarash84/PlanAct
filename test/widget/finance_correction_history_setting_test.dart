import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/app_settings.dart';
import 'package:planact/app/planact_app.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/commitments/data/drift_commitment_repository.dart';
import 'package:planact/features/finance/application/finance_use_cases.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/finance/presentation/finance_page.dart';
import 'package:planact/features/finance/presentation/transaction_card.dart';
import 'package:planact/features/settings/presentation/settings_page.dart';

void main() {
  testWidgets(
    'setting waits for persistence, retains prior value on failure and retries',
    (tester) async {
      var pending = Completer<void>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsPage(
              themeMode: ThemeMode.light,
              onThemeModeChanged: (_) {},
              onShowTransactionCorrectionHistoryChanged: (_) => pending.future,
            ),
          ),
        ),
      );
      final tile = find.widgetWithText(
        SwitchListTile,
        'نمایش سوابق اصلاح تراکنش‌ها',
      );
      await tester.ensureVisible(tile);
      expect(tester.widget<SwitchListTile>(tile).value, isFalse);
      await tester.tap(tile);
      await tester.pump();
      expect(tester.widget<SwitchListTile>(tile).value, isFalse);
      expect(tester.widget<SwitchListTile>(tile).onChanged, isNull);
      pending.completeError(StateError('test failure'));
      await tester.pumpAndSettle();
      expect(tester.widget<SwitchListTile>(tile).value, isFalse);
      expect(
        find.text(
          'تنظیم ذخیره نشد؛ مقدار قبلی حفظ شد. برای تلاش دوباره کلید را بزنید.',
        ),
        findsOneWidget,
      );
      pending = Completer<void>();
      await tester.tap(tile);
      await tester.pump();
      pending.complete();
      await tester.pumpAndSettle();
      expect(tester.widget<SwitchListTile>(tile).value, isTrue);
      pending = Completer<void>();
      await tester.tap(tile);
      await tester.pump();
      pending.complete();
      await tester.pumpAndSettle();
      expect(tester.widget<SwitchListTile>(tile).value, isFalse);
    },
  );

  testWidgets('root settings persist and refresh retained Finance list', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await tester.pumpWidget(
      PlanActApp(repository: DriftCommitmentRepository(db)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(NavigationDestination, 'بیشتر'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('تنظیمات'));
    await tester.pumpAndSettle();
    final tile = find.widgetWithText(
      SwitchListTile,
      'نمایش سوابق اصلاح تراکنش‌ها',
    );
    await tester.ensureVisible(tile);
    await tester.tap(tile);
    await tester.pumpAndSettle();
    expect(
      await AppSettings(db).readShowTransactionCorrectionHistory(),
      isTrue,
    );
    Navigator.of(tester.element(find.byType(SettingsPage))).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(NavigationDestination, 'مالی'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FinancePage>(find.byType(FinancePage))
          .showTransactionCorrectionHistory,
      isTrue,
    );
  });

  for (final dark in [false, true]) {
    testWidgets(
      'filter precedes pagination; focused history and full chain remain dark=$dark',
      (tester) async {
        final repository = InMemoryFinanceRepository();
        final commands = FinanceUseCases(repository);
        final account = FinancialAccount(
          id: StableId.generate(),
          name: 'نقدی',
          currency: 'IRR',
          type: FinancialAccountType.cash,
        );
        await commands.createAccount(account);
        AccountEntry? original;
        AccountEntry? current;
        for (var i = 0; i < 21; i++) {
          final entry = await commands.record(
            account: account,
            type: AccountEntryType.expense,
            amount: const Money(minorUnits: 100, currency: 'IRR'),
            occurredAt: DateTime(2026, 11, 21).subtract(Duration(minutes: i)),
            note: 'ردیف $i',
          );
          final replacement = await commands.correctEntry(
            original: entry,
            account: account,
            type: entry.type,
            amount: const Money(minorUnits: 200, currency: 'IRR'),
            occurredAt: entry.occurredAt,
            note: 'جاری $i',
          );
          if (i == 0) {
            original = entry;
            current = replacement;
          }
        }
        final key = GlobalKey<FinancePageState>();
        Future<void> open({bool show = false, String? focused}) async {
          await tester.pumpWidget(
            MaterialApp(
              theme: dark ? PlanActTheme.dark() : PlanActTheme.light(),
              home: Directionality(
                textDirection: TextDirection.rtl,
                child: FinancePage(
                  key: key,
                  repository: repository,
                  showTransactionCorrectionHistory: show,
                  focusedRecordId: focused,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
        }

        Future<void> scrollTo(Finder target) async {
          tester
              .state<ScrollableState>(find.byType(Scrollable).first)
              .position
              .jumpTo(0);
          await tester.pumpAndSettle();
          await tester.scrollUntilVisible(
            target,
            400,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.pumpAndSettle();
        }

        await open();
        await scrollTo(find.text('آخرین تراکنش‌ها'));
        expect(find.byType(TransactionCard), findsNWidgets(20));
        expect(
          tester
              .widgetList<TransactionCard>(find.byType(TransactionCard))
              .every((c) => c.entry.history!.role.replacement),
          isTrue,
        );
        final next = find.widgetWithText(OutlinedButton, 'صفحهٔ بعد').first;
        await tester.ensureVisible(next);
        await tester.tap(next);
        await tester.pumpAndSettle();
        expect(find.byType(TransactionCard), findsOneWidget);
        await open(show: true);
        expect(find.byType(TransactionCard), findsNWidgets(20));
        expect(
          tester
              .widgetList<TransactionCard>(find.byType(TransactionCard))
              .any((c) => c.entry.history!.role.corrected),
          isTrue,
        );
        await open();
        expect(find.byType(TransactionCard), findsNWidgets(20));
        await open(focused: current!.id.value);
        await scrollTo(find.text('مشاهدهٔ ثبت‌های مرتبط'));
        await tester.tap(find.text('مشاهدهٔ ثبت‌های مرتبط'));
        await tester.pumpAndSettle();
        expect(find.text('زنجیرهٔ ثبت‌های مرتبط'), findsOneWidget);
        expect(find.text('اصلاح‌شده'), findsOneWidget);
        expect(find.text('برگشت بابت اصلاح'), findsOneWidget);
        await tester.ensureVisible(find.text('بستن'));
        await tester.tap(find.text('بستن'));
        await tester.pumpAndSettle();
        await open(focused: original!.id.value);
        expect(find.byType(TransactionCard), findsOneWidget);
        expect(
          tester.widget<TransactionCard>(find.byType(TransactionCard)).entry.id,
          original.id,
        );
        expect(await repository.listEntries(), hasLength(63));
        expect((await commands.balance(account)).minorUnits, -4200);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
