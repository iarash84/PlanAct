import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/localization/persian_copy.g.dart';
import 'package:planact/features/capture/presentation/quick_capture_sheet.dart';
import 'package:planact/features/commitments/application/commitment_draft.dart';
import 'package:planact/features/finance/application/finance_use_cases.dart';
import 'package:planact/features/finance/domain/finance.dart';

Future<void> tap(WidgetTester tester, Finder finder) async {
  await Scrollable.ensureVisible(tester.element(finder), alignment: 0.3);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

class Accounts extends InMemoryFinanceRepository {
  bool fail = false;
  @override
  Future<List<FinancialAccount>> listAccounts() async {
    if (fail) throw StateError('read failed');
    return super.listAccounts();
  }
}

void main() {
  for (final dark in [false, true]) {
    testWidgets('optional account fits narrow RTL large text ($dark)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = Accounts();
      await repository.saveAccount(
        FinancialAccount(
          id: StableId.generate(),
          name: 'حساب پرداخت هزینه‌های شخصی و تعهدهای دوره‌ای',
          currency: 'IRR',
          type: FinancialAccountType.cash,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: PlanActTheme.light(),
          darkTheme: PlanActTheme.dark(),
          themeMode: dark ? ThemeMode.dark : ThemeMode.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.8)),
            child: child!,
          ),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: QuickCaptureSheet(financeRepository: repository),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tap(tester, find.text('اطلاعات مالی'));
      await tap(
        tester,
        find.text(PersianCopy.quickCaptureSheetFinancialFieldsLabel2),
      );
      await tap(tester, find.byType(DropdownButtonFormField<FinancialAccount>));
      await tap(
        tester,
        find.text('حساب پرداخت هزینه‌های شخصی و تعهدهای دوره‌ای').last,
      );
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'creation retains explicit optional account through collapse and retry',
    (tester) async {
      final repository = Accounts();
      final selected = FinancialAccount(
        id: StableId.generate(),
        name: 'حساب دوم',
        currency: 'IRR',
        type: FinancialAccountType.cash,
      );
      await repository.saveAccount(
        FinancialAccount(
          id: StableId.generate(),
          name: 'حساب اول',
          currency: 'IRR',
          type: FinancialAccountType.cash,
        ),
      );
      await repository.saveAccount(selected);
      await repository.saveAccount(
        FinancialAccount(
          id: StableId.generate(),
          name: 'حساب بایگانی',
          currency: 'IRR',
          type: FinancialAccountType.cash,
          status: FinancialAccountStatus.archived,
        ),
      );
      await repository.saveAccount(
        FinancialAccount(
          id: StableId.generate(),
          name: 'حساب دلار',
          currency: 'USD',
          type: FinancialAccountType.cash,
        ),
      );
      final submissions = <CommitmentDraft>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: QuickCaptureSheet(
                financeRepository: repository,
                onSave: (draft) async {
                  submissions.add(draft);
                  throw StateError('retain form');
                },
              ),
            ),
          ),
        ),
      );
      await tester.enterText(
        find.byKey(const ValueKey('commitment-title-field')),
        'پرداخت',
      );
      await tap(tester, find.text('انتخاب تاریخ'));
      await tap(tester, find.byKey(const ValueKey('capture-date-1')));
      await tap(tester, find.text('تأیید تاریخ'));
      await tap(tester, find.text('انتخاب زمان'));
      await tap(tester, find.byType(TextButton).last);
      final section = find.byKey(const ValueKey('commitment-finance-section'));
      final header = find
          .descendant(of: section, matching: find.byType(ListTile))
          .first;
      await tap(tester, header);
      await tap(
        tester,
        find.text(PersianCopy.quickCaptureSheetFinancialFieldsLabel2),
      );
      final dropdown = find.byType(DropdownButtonFormField<FinancialAccount>);
      expect(
        tester
            .widget<DropdownButtonFormField<FinancialAccount>>(dropdown)
            .initialValue,
        isNull,
      );
      await tap(tester, dropdown);
      expect(find.text('حساب بایگانی'), findsNothing);
      expect(find.text('حساب دلار'), findsNothing);
      await tap(tester, find.text('حساب دوم').last);
      await tester.enterText(
        find.widgetWithText(
          TextField,
          PersianCopy.quickCaptureSheetFinancialFieldsLabelText('ریال'),
        ),
        '1200',
      );
      await tap(tester, header);
      await tap(tester, header);
      expect(
        tester
            .widget<DropdownButtonFormField<FinancialAccount>>(dropdown)
            .initialValue
            ?.id,
        selected.id,
      );
      await tap(tester, find.text('ثبت تعهد'));
      expect(submissions.single.financialAccountId, selected.id);
      await tap(tester, find.text('ثبت تعهد'));
      expect(submissions.last.financialAccountId, selected.id);
      await tap(tester, dropdown);
      await tap(tester, find.text('بدون حساب').last);
      await tap(tester, find.text('ثبت تعهد'));
      expect(submissions.last.financialAccountId, isNull);
      expect(await repository.listEntries(), isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'optional picker has recoverable read failure and empty no-account choice',
    (tester) async {
      final repository = Accounts()..fail = true;
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: QuickCaptureSheet(financeRepository: repository),
            ),
          ),
        ),
      );
      final section = find.byKey(const ValueKey('commitment-finance-section'));
      await tap(
        tester,
        find.descendant(of: section, matching: find.byType(ListTile)).first,
      );
      await tap(
        tester,
        find.text(PersianCopy.quickCaptureSheetFinancialFieldsLabel2),
      );
      expect(
        find.text(PersianCopy.financialAccountPickerLoadMessage),
        findsOneWidget,
      );
      repository.fail = false;
      await tap(tester, find.text('تلاش دوباره'));
      final dropdown = find.byType(DropdownButtonFormField<FinancialAccount>);
      expect(dropdown, findsOneWidget);
      expect(
        tester
            .widget<DropdownButtonFormField<FinancialAccount>>(dropdown)
            .initialValue,
        isNull,
      );
      await tap(tester, dropdown);
      expect(find.text('بدون حساب'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );
}
