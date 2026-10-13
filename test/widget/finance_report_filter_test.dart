import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/classification/application/tag_repository.dart';
import 'package:planact/features/classification/data/drift_tag_repository.dart';
import 'package:planact/features/finance/data/drift_finance_repository.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/finance/presentation/finance_page.dart';

void main() {
  testWidgets(
    'Finance summary follows the same tag filter as transaction rows',
    (tester) async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      final finance = DriftFinanceRepository(database),
          tags = DriftTagRepository(database);
      final account = FinancialAccount(
        id: StableId.generate(),
        name: 'نقدی',
        currency: 'IRR',
        type: FinancialAccountType.cash,
      );
      await finance.saveAccount(account);
      final tagged = AccountEntry(
        id: StableId.generate(),
        accountId: account.id,
        type: AccountEntryType.expense,
        amount: const Money(minorUnits: 100, currency: 'IRR'),
        occurredAt: DateTime(2026, 10, 13),
        note: 'ورزش',
      );
      await finance.saveEntry(tagged);
      await finance.saveEntry(
        AccountEntry(
          id: StableId.generate(),
          accountId: account.id,
          type: AccountEntryType.expense,
          amount: const Money(minorUnits: 900, currency: 'IRR'),
          occurredAt: DateTime(2026, 10, 13),
          note: 'دیگر',
        ),
      );
      final tag = await tags.getOrCreate('ورزش');
      await tags.attach(
        recordId: tagged.id.value,
        tag: tag,
        type: TaggableType.accountEntry,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: PlanActTheme.light(),
          builder: (_, child) =>
              Directionality(textDirection: TextDirection.rtl, child: child!),
          home: FinancePage(repository: finance, tagRepository: tags),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('خروجی: ۱,۰۰۰ ریال'), findsOneWidget);
      final chip = find.widgetWithText(FilterChip, '#ورزش');
      await tester.ensureVisible(chip);
      await tester.pumpAndSettle();
      await tester.tap(chip);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('خروجی: ۱۰۰ ریال'),
        -100,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('خروجی: ۱۰۰ ریال'), findsOneWidget);
      expect(find.text('خروجی: ۱,۰۰۰ ریال'), findsNothing);
    },
  );
}
