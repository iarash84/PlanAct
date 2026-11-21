import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/classification/data/drift_tag_repository.dart';
import 'package:planact/features/finance/application/finance_use_cases.dart';
import 'package:planact/features/finance/data/drift_finance_repository.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/finance/presentation/finance_page.dart';

void main() {
  for (final dark in [false, true]) {
    testWidgets(
      'original metadata remains visible from replacement dark=$dark',
      (tester) async {
        tester.view.physicalSize = const Size(320, 1200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final database = AppDatabase.forTesting(NativeDatabase.memory());
        addTearDown(database.close);
        final repository = DriftFinanceRepository(database);
        final commands = FinanceUseCases(repository);
        final account = FinancialAccount(
          id: StableId.generate(),
          name: 'حساب',
          currency: 'IRR',
          type: FinancialAccountType.cash,
        );
        await commands.createAccount(account);
        final original = await commands.record(
          account: account,
          type: AccountEntryType.expense,
          amount: const Money(minorUnits: 100, currency: 'IRR'),
          occurredAt: DateTime.utc(2026, 11),
          note: 'شرح اصلی محفوظ',
          category: 'دسته اصلی محفوظ',
          tags: {'برچسب اصلی محفوظ'},
        );
        final replacement = await commands.correctEntry(
          original: original,
          account: account,
          type: AccountEntryType.expense,
          amount: const Money(minorUnits: 200, currency: 'IRR'),
          occurredAt: original.occurredAt,
          note: 'شرح جایگزین مستقل',
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
            home: FinancePage(
              repository: repository,
              tagRepository: DriftTagRepository(database),
              focusedRecordId: replacement.id.value,
            ),
          ),
        );
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 200));
        });
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('مشاهدهٔ ثبت‌های مرتبط'));
        await tester.tap(find.text('مشاهدهٔ ثبت‌های مرتبط'));
        await tester.pumpAndSettle();
        expect(find.text('شرح اصلی محفوظ'), findsOneWidget);
        expect(find.text('دسته اصلی محفوظ'), findsOneWidget);
        expect(find.text('#برچسب اصلی محفوظ'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
