import 'package:planact/app/planact_app.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/commitments/data/drift_commitment_repository.dart';
import 'package:planact/features/finance/data/drift_finance_repository.dart';
import 'package:planact/features/finance/presentation/finance_page.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/app_settings.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/core/time/jalali_date.dart';
import 'package:planact/features/calendar/domain/calendar_visibility.dart';
import 'package:planact/features/calendar/domain/calendar_transaction.dart';
import 'package:planact/features/calendar/presentation/calendar_page.dart';
import 'package:planact/features/calendar/presentation/calendar_transaction_tile.dart';
import 'package:planact/features/calendar/presentation/calendar_visibility_controller.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/settings/presentation/calendar_visibility_settings.dart';

import '../unit/calendar_transaction_test.dart' show calendarEntry;

void main() {
  testWidgets('production Settings → Calendar → Finance details and restart', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final finance = DriftFinanceRepository(db);
    final account = FinancialAccount(
      id: StableId.generate(),
      name: 'حساب آزمون',
      currency: 'IRR',
      type: FinancialAccountType.bank,
    );
    await finance.saveAccount(account);
    final source = calendarEntry(AccountEntryType.income, DateTime.now());
    final entry = AccountEntry(
      id: source.id,
      accountId: account.id,
      type: source.type,
      amount: source.amount,
      occurredAt: source.occurredAt,
      note: 'درآمد قطعی آزمون',
    );
    await finance.saveEntry(entry);
    await tester.pumpWidget(
      PlanActApp(repository: DriftCommitmentRepository(db)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(NavigationDestination, 'بیشتر'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('تنظیمات'));
    await tester.pumpAndSettle();
    final settings = find.byKey(const ValueKey('calendar-visibility-settings'));
    await tester.ensureVisible(settings);
    await tester.tap(find.text('موارد نمایان'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.widgetWithText(SwitchListTile, 'درآمد'));
    await tester.tap(find.widgetWithText(SwitchListTile, 'درآمد'));
    await tester.pumpAndSettle();
    expect((await AppSettings(db).readCalendarVisibility()).income, isTrue);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(NavigationDestination, 'تقویم'));
    await tester.pumpAndSettle();
    final tile = find.byType(CalendarTransactionTile);
    await tester.scrollUntilVisible(
      tile,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(tile);
    await tester.pumpAndSettle();
    expect(find.byType(FinancePage), findsOneWidget);
    expect(
      tester.widget<FinancePage>(find.byType(FinancePage)).focusedRecordId,
      entry.id.value,
    );
    expect(find.textContaining('درآمد قطعی آزمون'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect((await finance.listEntries()), hasLength(1));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      PlanActApp(repository: DriftCommitmentRepository(db)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(NavigationDestination, 'تقویم'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      tile,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tile, findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
    'settings defaults and failed saving retain effective selection',
    (tester) async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      final controller = CalendarVisibilityController(AppSettings(database));
      addTearDown(controller.dispose);
      await controller.load();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CalendarVisibilitySettings(controller: controller),
            ),
          ),
        ),
      );
      await tester.tap(find.text('موارد نمایان'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<SwitchListTile>(
              find.widgetWithText(SwitchListTile, 'تعهدها'),
            )
            .value,
        isTrue,
      );
      expect(
        tester
            .widget<SwitchListTile>(
              find.widgetWithText(SwitchListTile, 'درآمد'),
            )
            .value,
        isFalse,
      );
      await tester.tap(find.text('درآمد'));
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();
      expect(controller.value.income, isTrue);
      await database.customStatement(
        "CREATE TEMP TRIGGER fail_visibility BEFORE UPDATE ON schema_metadata WHEN NEW.key = 'calendar_visibility_v1' BEGIN SELECT RAISE(ABORT, 'injected'); END",
      );
      await tester.tap(find.text('درآمد'));
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();
      expect(controller.value.income, isTrue);
      expect(
        find.text('تنظیم نمایش تقویم ذخیره نشد؛ دوباره تلاش کنید.'),
        findsOneWidget,
      );
      expect(
        (await AppSettings(database).readCalendarVisibility()).income,
        isTrue,
      );
    },
  );

  for (final dark in [false, true]) {
    testWidgets(
      'month and week financial rows and taps, RTL large text dark=$dark',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 1200));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        const jalali = JalaliDate(1405, 8, 23);
        final item = CalendarTransaction(
          entry: calendarEntry(
            AccountEntryType.income,
            jalali.toDateTime().add(const Duration(hours: 14)),
          ),
          kind: CalendarTransactionKind.income,
          reversed: false,
        );
        CalendarTransaction? opened;
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? PlanActTheme.dark() : PlanActTheme.light(),
            home: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2)),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Scaffold(
                  body: CalendarPage(
                    commitments: const [],
                    scheduledDates: const {},
                    initialDate: jalali,
                    visibility: const CalendarVisibility(income: true),
                    transactionLoader: (start, end) async => [item],
                    onTransactionTap: (value) => opened = value,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('درآمد ثبت‌شده'), findsWidgets);
        await tester.scrollUntilVisible(
          find.byType(CalendarTransactionTile),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byType(CalendarTransactionTile));
        expect(opened, item);
        await tester.drag(find.byType(Scrollable).first, const Offset(0, 4000));
        await tester.pumpAndSettle();
        await tester.tap(find.text('هفته'));
        await tester.pumpAndSettle();
        expect(find.byType(CalendarTransactionTile), findsOneWidget);
        await tester.ensureVisible(find.byType(CalendarTransactionTile));
        await tester.tap(find.byType(CalendarTransactionTile));
        expect(tester.takeException(), isNull);
      },
    );
  }
}
