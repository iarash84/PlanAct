import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/planact_app.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/app/theme/planact_status_colors.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/commitments/data/drift_commitment_repository.dart';
import 'package:planact/features/finance/application/finance_use_cases.dart';
import 'package:planact/features/finance/data/drift_finance_repository.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/finance/presentation/transaction_direction.dart';
import 'package:planact/features/settings/presentation/settings_page.dart';
import 'package:planact/features/today/presentation/today_page.dart';

void main() {
  testWidgets('pushed settings immediately selects each display mode', (
    tester,
  ) async {
    await tester.pumpWidget(const PlanActApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('بیشتر'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('تنظیمات'));
    await tester.pumpAndSettle();
    for (final pair in [
      ('تاریک', ThemeMode.dark),
      ('روشن', ThemeMode.light),
      ('دستگاه', ThemeMode.system),
    ]) {
      await tester.tap(find.text(pair.$1));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<SegmentedButton<ThemeMode>>(
              find.byType(SegmentedButton<ThemeMode>),
            )
            .selected,
        {pair.$2},
      );
    }
    expect(find.byType(SettingsPage), findsOneWidget);
  });

  testWidgets(
    'pulling short empty Today rereads newly persisted transactions',
    (tester) async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      final finance = DriftFinanceRepository(database);
      await tester.pumpWidget(
        PlanActApp(repository: DriftCommitmentRepository(database)),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('همه‌چیز مرتب است؛ موردی نیاز به توجه ندارد.'),
        findsOneWidget,
      );
      final account = FinancialAccount(
        id: StableId.generate(),
        name: 'نقدی',
        currency: 'IRR',
        type: FinancialAccountType.cash,
      );
      await finance.saveAccount(account);
      await FinanceUseCases(finance).record(
        account: account,
        type: AccountEntryType.expense,
        amount: const Money(minorUnits: 1000, currency: 'IRR'),
        occurredAt: DateTime.now(),
      );
      final list = find
          .descendant(
            of: find.byType(TodayPage),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.drag(list, const Offset(0, 400));
      await tester.pumpAndSettle();
      expect(find.text('تعیین ارتباط'), findsWidgets);
      expect(
        find.text('همه‌چیز مرتب است؛ موردی نیاز به توجه ندارد.'),
        findsNothing,
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  for (final dark in [false, true]) {
    testWidgets(
      'ledger direction icons cover transfers and signed corrections, dark=$dark',
      (tester) async {
        for (final type in AccountEntryType.values) {
          for (final amount in [100, -100]) {
            final entry = AccountEntry(
              id: StableId.generate(),
              accountId: StableId.generate(),
              type: type,
              amount: Money(minorUnits: amount, currency: 'IRR'),
              occurredAt: DateTime(2026),
            );
            await tester.pumpWidget(
              MaterialApp(
                theme: dark ? PlanActTheme.dark() : PlanActTheme.light(),
                home: Scaffold(body: TransactionDirectionIcon(entry: entry)),
              ),
            );
            final incoming = entry.signedAmount.minorUnits > 0;
            final context = tester.element(
              find.byType(TransactionDirectionIcon),
            );
            final colors = PlanActStatusColors.of(context);
            final icon = tester.widget<Icon>(find.byType(Icon));
            expect(icon.icon, incoming ? Icons.south_west : Icons.north_east);
            expect(icon.color, incoming ? colors.success : colors.attention);
            expect(icon.semanticLabel, contains(transactionLabel(entry)));
            if (type == AccountEntryType.transferIn ||
                type == AccountEntryType.transferOut) {
              expect(transactionLabel(entry), contains('انتقال'));
            }
          }
        }
      },
    );
  }
}
