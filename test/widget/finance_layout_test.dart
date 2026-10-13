import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/planact_app.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/commitments/data/drift_commitment_repository.dart';
import 'package:planact/features/finance/application/finance_use_cases.dart';
import 'package:planact/features/finance/data/drift_finance_repository.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/finance/presentation/finance_page.dart';

Future<void> _settleDatabase(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.pumpAndSettle();
  // The native reminder adapter is unavailable in widget tests. Allow the
  // shell's transient synchronization feedback to expire before hit testing.
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

void main() {
  for (final width in [320.0, 360.0, 430.0]) {
    for (final scale in [1.0, 2.0]) {
      for (final dark in [false, true]) {
        for (final count in [1, 40]) {
          testWidgets(
            'Finance last-row tap: width=$width scale=$scale dark=$dark entries=$count',
            (tester) async {
              tester.view.physicalSize = Size(width, 900);
              tester.view.devicePixelRatio = 1;
              addTearDown(tester.view.resetPhysicalSize);
              addTearDown(tester.view.resetDevicePixelRatio);
              final database = AppDatabase.forTesting(NativeDatabase.memory());
              final finance = DriftFinanceRepository(database);
              addTearDown(() async {
                await tester.pumpWidget(const SizedBox.shrink());
                await tester.runAsync(database.close);
              });
              await tester.runAsync(() async {
                final account = FinancialAccount(
                  id: StableId.generate(),
                  name: 'نقدی',
                  currency: 'IRR',
                  type: FinancialAccountType.cash,
                );
                await finance.saveAccount(account);
                for (var i = 0; i < count; i++) {
                  await FinanceUseCases(finance).record(
                    account: account,
                    type: AccountEntryType.expense,
                    amount: const Money(minorUnits: 10, currency: 'IRR'),
                    occurredAt: DateTime(
                      2026,
                      10,
                      11,
                    ).subtract(Duration(days: i)),
                    note: i == count - 1 ? 'آخرین ردیف آزمون' : 'تراکنش آزمون',
                  );
                }
              });
              final textScale = ValueNotifier<double>(1);
              addTearDown(textScale.dispose);
              await tester.pumpWidget(
                MaterialApp(
                  theme: dark ? PlanActTheme.dark() : PlanActTheme.light(),
                  builder: (context, child) => ValueListenableBuilder<double>(
                    valueListenable: textScale,
                    builder: (context, value, _) => MediaQuery(
                      data: MediaQuery.of(context).copyWith(
                        textScaler: TextScaler.linear(value),
                        padding: const EdgeInsets.only(top: 24, bottom: 34),
                        viewPadding: const EdgeInsets.only(top: 24, bottom: 34),
                      ),
                      child: Directionality(
                        textDirection: TextDirection.rtl,
                        child: child!,
                      ),
                    ),
                  ),
                  home: HomeShell(
                    repository: DriftCommitmentRepository(database),
                  ),
                ),
              );
              await _settleDatabase(tester);
              await tester.tap(find.text('مالی').last);
              await _settleDatabase(tester);
              // Scope large-text evidence to Finance, not the unrelated Today
              // relationship-review cards shown on the shell's initial tab.
              textScale.value = scale;
              await tester.pumpAndSettle();
              final list = find.descendant(
                of: find.byType(FinancePage),
                matching: find.byType(ListView),
              );
              final scrollable = find
                  .descendant(of: list, matching: find.byType(Scrollable))
                  .first;
              final position = tester
                  .state<ScrollableState>(scrollable)
                  .position;
              final typeFilter = find.byType(DropdownButton<AccountEntryType?>);
              await tester.scrollUntilVisible(
                typeFilter,
                100,
                scrollable: scrollable,
              );
              await tester.pumpAndSettle();
              await tester.tap(typeFilter);
              await tester.pumpAndSettle();
              await tester.tap(find.text('خروجی').last);
              await tester.pumpAndSettle();
              expect(
                tester
                    .widget<DropdownButton<AccountEntryType?>>(typeFilter)
                    .value,
                AccountEntryType.expense,
              );
              // Reach the actual list end, rather than ensureVisible on a
              // control that could still be hit-tested behind a shell FAB.
              for (var i = 0; i < 100; i++) {
                position.jumpTo(position.maxScrollExtent);
                await tester.pumpAndSettle();
                if (position.extentAfter == 0 &&
                    position.pixels == position.maxScrollExtent) {
                  break;
                }
              }
              await tester.pumpAndSettle();
              final row = find
                  .ancestor(
                    of: find.textContaining('آخرین ردیف آزمون'),
                    matching: find.byType(Card),
                  )
                  .first;
              final menu = find.descendant(
                of: row,
                matching: find.byTooltip('عملیات تراکنش'),
              );
              final rowRect = tester.getRect(row);
              final menuRect = tester.getRect(menu);
              final listRect = tester.getRect(list);
              final add = find.byTooltip('افزودن سریع');
              final addRect = tester.getRect(add);
              final navigationRect = tester.getRect(find.byType(NavigationBar));
              expect(rowRect.top, greaterThanOrEqualTo(listRect.top));
              expect(rowRect.bottom, lessThanOrEqualTo(listRect.bottom));
              expect(rowRect.bottom, lessThanOrEqualTo(addRect.top));
              expect(menuRect.width, greaterThanOrEqualTo(48));
              expect(menuRect.height, greaterThanOrEqualTo(48));
              expect(menuRect.overlaps(addRect), isFalse);
              expect(menuRect.overlaps(navigationRect), isFalse);
              expect(addRect.bottom, lessThanOrEqualTo(navigationRect.top));
              expect(
                tester.getRect(find.text('مالی').last).bottom,
                lessThanOrEqualTo(900 - 34),
              );
              await tester.tap(menu, warnIfMissed: true);
              await tester.pumpAndSettle();
              expect(find.text('حذف امن تراکنش'), findsOneWidget);
              await tester.tap(find.text('حذف امن تراکنش'));
              await tester.pumpAndSettle();
              expect(find.byType(AlertDialog), findsOneWidget);
              await tester.tap(find.text('انصراف'));
              await tester.pumpAndSettle();
              await tester.tap(add);
              await tester.pumpAndSettle();
              expect(
                find.byKey(const ValueKey('quick-add-expense')),
                findsOneWidget,
              );
              // Dismiss the existing quick-add sheet without creating data.
              Navigator.of(tester.element(find.text('هزینه'))).pop();
              await tester.pumpAndSettle();
              await tester.runAsync(() async {
                expect(await finance.listEntries(), hasLength(count));
              });
              expect(tester.takeException(), isNull);
            },
          );
        }
      }
    }
  }
}
