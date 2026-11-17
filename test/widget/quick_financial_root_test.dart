import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/planact_app.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/presentation/planact_jalali_date_picker.dart';
import 'package:planact/features/classification/data/drift_tag_repository.dart';
import 'package:planact/features/classification/application/tag_repository.dart';
import 'package:planact/features/commitments/data/drift_commitment_repository.dart';
import 'package:planact/features/finance/data/drift_finance_repository.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/quick_add/presentation/quick_add_sheet.dart';

import 'quick_financial_options_test.dart' show key, tap;
import 'tagged_creation_test.dart' show addTag;

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.pumpAndSettle();
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

void main() {
  for (final income in [false, true]) {
    testWidgets(
      'root inline financial save keeps tab and persists date: $income',
      (tester) async {
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        final finance = DriftFinanceRepository(db);
        final tags = DriftTagRepository(db);
        addTearDown(() async {
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.runAsync(db.close);
        });
        final account = FinancialAccount(
          id: StableId.generate(),
          name: 'حساب آزمون',
          currency: 'IRR',
          type: FinancialAccountType.cash,
        );
        await tester.runAsync(() => finance.saveAccount(account));
        await tester.pumpWidget(
          MaterialApp(
            theme: PlanActTheme.light(),
            home: HomeShell(repository: DriftCommitmentRepository(db)),
          ),
        );
        await settle(tester);
        final initialTab = tester
            .widget<NavigationBar>(find.byType(NavigationBar))
            .selectedIndex;
        Future<void> open() async {
          await tap(tester, find.byTooltip('افزودن سریع'));
          await tap(
            tester,
            find.byKey(
              ValueKey(income ? 'quick-add-income' : 'quick-add-expense'),
            ),
          );
          await settle(tester);
        }

        await open();
        await tester.enterText(key('amount'), '2700');
        await tester.enterText(key('note'), 'ثبت از ریشه');
        await addTag(tester, 'آزمون');
        await tap(tester, key('more-options'));
        await tap(tester, key('more-options'));
        await tester.runAsync(() async {
          expect(await finance.listEntries(), isEmpty);
          expect(await tags.list(), isEmpty);
        });
        await tap(tester, find.text('انصراف'));
        await settle(tester);
        expect(
          tester
              .widget<NavigationBar>(find.byType(NavigationBar))
              .selectedIndex,
          initialTab,
        );
        await tester.runAsync(() async {
          expect(await finance.listEntries(), isEmpty);
          expect(await tags.list(), isEmpty);
        });
        await open();
        await tester.enterText(key('amount'), '2700');
        await tester.enterText(key('note'), 'ثبت از ریشه');
        await addTag(tester, 'آزمون');
        await tap(tester, key('more-options'));
        await tap(tester, key('date'));
        Navigator.of(tester.element(find.byType(PlanActJalaliDatePicker)))
            .pop(DateTime(2026, 10, 3));
        await tester.pumpAndSettle();
        await tap(tester, key('time'));
        Navigator.of(tester.element(find.byType(TimePickerDialog)))
            .pop(const TimeOfDay(hour: 8, minute: 21));
        await tester.pumpAndSettle();
        await tap(tester, key('more-options'));
        await tap(tester, key('save'));
        await settle(tester);
        expect(find.byType(QuickFinancialEntrySheet), findsNothing);
        expect(
          tester
              .widget<NavigationBar>(find.byType(NavigationBar))
              .selectedIndex,
          initialTab,
        );
        await tester.runAsync(() async {
          final entries = await finance.listEntries();
          expect(entries, hasLength(1));
          final entry = entries.single;
          expect(
            entry.type,
            income ? AccountEntryType.income : AccountEntryType.expense,
          );
          expect(entry.accountId, account.id);
          expect(entry.amount.minorUnits, 2700);
          expect(entry.note, 'ثبت از ریشه');
          expect(entry.occurredAt.toLocal(), DateTime(2026, 10, 3, 8, 21));
          expect(await tags.list(), hasLength(1));
          expect(
            await tags.tagsFor(entry.id.value, TaggableType.accountEntry),
            {(await tags.list()).single.id},
          );
        });
        expect(tester.takeException(), isNull);
      },
    );
  }
}
