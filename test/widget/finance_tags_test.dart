import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/classification/application/tag_repository.dart';
import 'package:planact/features/classification/data/drift_tag_repository.dart';
import 'package:planact/features/classification/presentation/tag_controls.dart';
import 'package:planact/features/finance/data/drift_finance_repository.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/finance/presentation/finance_page.dart';

void main() {
  for (final dark in [false, true]) {
    testWidgets(
      'finance assign, rename, filter and detach preserve ledger ($dark)',
      (tester) async {
        final database = AppDatabase(NativeDatabase.memory());
        addTearDown(database.close);
        final finance = DriftFinanceRepository(database);
        final tags = DriftTagRepository(database);
        final account = FinancialAccount(
          id: StableId.generate(),
          name: 'نقدی',
          currency: 'IRR',
          type: FinancialAccountType.cash,
        );
        await finance.saveAccount(account);
        final entry = AccountEntry(
          id: StableId.generate(),
          accountId: account.id,
          type: AccountEntryType.expense,
          amount: const Money(minorUnits: 100, currency: 'IRR'),
          occurredAt: DateTime.utc(2026, 10, 6),
          note: 'خرید روزانه',
        );
        await finance.saveEntry(entry);
        final ledgerBefore =
            (await database.select(database.accountEntries).get())
                .map((row) => row.toJson())
                .toList();
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? PlanActTheme.dark() : PlanActTheme.light(),
            builder: (context, child) =>
                Directionality(textDirection: TextDirection.rtl, child: child!),
            home: FinancePage(repository: finance, tagRepository: tags),
          ),
        );
        await tester.pumpAndSettle();
        final pageScroll = find.byType(Scrollable).first;
        await tester.scrollUntilVisible(
          find.byTooltip('عملیات تراکنش'),
          200,
          scrollable: pageScroll,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('عملیات تراکنش'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('برچسب‌های تراکنش'));
        await tester.pumpAndSettle();
        expect(
          find.text(
            'تغییر برچسب‌ها بلافاصله ذخیره می‌شود؛ نیازی به ذخیرهٔ فرم نیست.',
          ),
          findsOneWidget,
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'برچسب جدید'),
          'خانه',
        );
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        await tester.tap(find.text('ساخت و افزودن برچسب'));
        await tester.pumpAndSettle();
        final tag = (await tags.list()).single;
        expect(await tags.tagsFor(entry.id.value, TaggableType.accountEntry), {
          tag.id,
        });
        await tester.tap(find.text('مدیریت برچسب‌ها').last);
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('تغییر نام #خانه'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.widgetWithText(TextField, 'نام برچسب'),
          'خانواده',
        );
        await tester.tap(find.text('ذخیره'));
        await tester.pumpAndSettle();
        final renamed = (await tags.list()).single;
        expect(renamed.id, tag.id);
        expect(renamed.createdAt, tag.createdAt);
        Navigator.of(tester.element(find.byTooltip('تغییر نام #خانواده')))
            .pop();
        await tester.pumpAndSettle();
        final assignment = find.descendant(
          of: find.byType(RecordTagEditor),
          matching: find.widgetWithText(FilterChip, '#خانواده'),
        );
        expect(tester.widget<FilterChip>(assignment).selected, isTrue);
        await tester.tap(assignment);
        await tester.pumpAndSettle();
        expect(
          await tags.tagsFor(entry.id.value, TaggableType.accountEntry),
          isEmpty,
        );
        expect(await tags.list(), hasLength(1));
        Navigator.of(tester.element(find.text('برچسب‌های این مورد'))).pop();
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('همهٔ برچسب‌ها'),
          -200,
          scrollable: pageScroll,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilterChip, '#خانواده'));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('تراکنشی با این فیلترها پیدا نشد.'),
          200,
          scrollable: pageScroll,
        );
        expect(find.textContaining('خرید روزانه'), findsNothing);
        await tester.scrollUntilVisible(
          find.text('همهٔ برچسب‌ها'),
          -200,
          scrollable: pageScroll,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('همهٔ برچسب‌ها'));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.textContaining('خرید روزانه'),
          200,
          scrollable: pageScroll,
        );
        expect(find.textContaining('خرید روزانه'), findsOneWidget);
        expect(
          (await database.select(database.accountEntries).get())
              .map((row) => row.toJson())
              .toList(),
          ledgerBefore,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
