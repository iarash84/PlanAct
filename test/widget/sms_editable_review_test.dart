import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/money_unit_scope.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/core/presentation/planact_jalali_date_picker.dart';
import 'package:planact/features/finance/application/finance_use_cases.dart';
import 'package:planact/features/inbox/application/inbox_use_cases.dart';
import 'package:planact/features/inbox/domain/inbox.dart';
import 'package:planact/features/inbox/presentation/inbox_page.dart';

class _FailingEdit extends InboxUseCases {
  _FailingEdit(super.repository);
  bool fail = true;
  @override
  Future<InboxSuggestion> edit(
    InboxSuggestion suggestion,
    TransactionDraft draft,
  ) async {
    if (fail) throw StateError('injected edit failure');
    return super.edit(suggestion, draft);
  }
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  if (find.byType(SnackBar).evaluate().isNotEmpty) {
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  }
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      250,
      scrollable: find.byType(Scrollable).last,
    );
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  if (finder.hitTestable().evaluate().isEmpty) {
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -180));
    await tester.pumpAndSettle();
  }
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _mount(
  WidgetTester tester,
  InboxUseCases inbox,
  InMemoryFinanceRepository finance, {
  bool dark = false,
  bool narrow = false,
}) async {
  if (narrow) {
    await tester.binding.setSurfaceSize(const Size(320, 740));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }
  final controller = MoneyUnitController(null)..value = IranianMoneyUnit.toman;
  addTearDown(controller.dispose);
  await tester.pumpWidget(
    MoneyUnitScope(
      controller: controller,
      child: MaterialApp(
        theme: dark ? PlanActTheme.dark() : PlanActTheme.light(),
        builder: (context, child) => Directionality(
          textDirection: TextDirection.rtl,
          child: MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(narrow ? 1.8 : 1)),
            child: child!,
          ),
        ),
        home: Scaffold(
          body: InboxPage(inbox: inbox, finance: finance),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'bank/account edits survive failed save and preserve original evidence',
    (tester) async {
      final repository = InMemoryInboxRepository();
      final inbox = _FailingEdit(repository);
      final finance = InMemoryFinanceRepository();
      final original = await inbox.stageSms(
        rawText: 'برداشت مبلغ 2500 ریال\nبانک: نمونه\nحساب: 123456789012\nپیگیری: 987654321098\nتاریخ: 1405/07/19',
        sourceKey: 'editable',
        currency: 'IRR',
        importedAt: DateTime(2026, 10, 11, 16, 45),
      );
      await _mount(tester, inbox, finance);
      await _tap(tester, find.text('جزئیات پیشنهاد'));
      expect(find.textContaining('123456789012'), findsNothing);
      expect(find.textContaining('987654321098'), findsNothing);
      expect(find.text('ساعت پیامک: نامشخص'), findsOneWidget);
      await _tap(tester, find.text('ویرایش'));
      final bank = find.widgetWithText(TextField, 'نام بانک');
      final hint = find.widgetWithText(TextField, 'راهنمای حساب یا کارت');
      await tester.ensureVisible(bank);
      await tester.enterText(bank, 'بانک اصلاح‌شده');
      await tester.ensureVisible(hint);
      await tester.enterText(hint, 'حساب شخصی');
      expect(find.text('انتخاب ساعت تراکنش (نامشخص)'), findsOneWidget);
      await _tap(tester, find.text('ذخیره و بررسی'));
      expect(find.textContaining('مقادیر فرم حفظ شده‌اند'), findsOneWidget);
      expect(tester.widget<TextField>(bank).controller!.text, 'بانک اصلاح‌شده');
      expect(tester.widget<TextField>(hint).controller!.text, 'حساب شخصی');
      expect(
        (await repository.listSuggestions()).single.revision,
        original.revision,
      );
      inbox.fail = false;
      await _tap(tester, find.text('ذخیره و بررسی'));
      final edited = (await repository.listSuggestions()).single;
      expect(edited.draft.bank, 'بانک اصلاح‌شده');
      expect(edited.draft.accountHint, 'حساب شخصی');
      expect(
        edited.draft.amount.minorUnits,
        2500,
      ); // Settings is toman, SMS remains rial.
      expect(edited.draft.dateSource, TransactionDateSource.receipt);
      expect(
        edited.extractedEvidence!.toJson(),
        original.extractedEvidence!.toJson(),
      );
      expect(await finance.listEntries(), isEmpty);
      await _tap(tester, find.text('تأیید و ثبت'));
      await _tap(tester, find.text('تأیید نهایی'));
      expect(
        find.text('طبقه‌بندی درآمد یا هزینه را صریحاً تأیید کنید.'),
        findsOneWidget,
      );
      await _tap(tester, find.byType(Checkbox).first);
      await _tap(tester, find.text('تأیید نهایی'));
      expect(
        find.textContaining('زمان پیشنهادی را صریحاً تأیید کنید'),
        findsOneWidget,
      );
      await _tap(tester, find.text('انصراف'));
      expect(await finance.listEntries(), isEmpty);
    },
  );

  testWidgets(
    'Jalali date and explicit time selection create reviewer timestamp, unknown stays selectable',
    (tester) async {
      final repository = InMemoryInboxRepository();
      final inbox = InboxUseCases(repository);
      final finance = InMemoryFinanceRepository();
      final original = await inbox.stageSms(
        rawText: 'برداشت مبلغ 2500 ریال\nتاریخ: 1405/07/19',
        sourceKey: 'date',
        currency: 'IRR',
        importedAt: DateTime(2026, 10, 11, 16, 45),
      );
      await _mount(tester, inbox, finance);
      await _tap(tester, find.text('ویرایش'));
      await _tap(tester, find.textContaining('تاریخ تراکنش:'));
      expect(find.byType(PlanActJalaliDatePicker), findsOneWidget);
      await _tap(tester, find.text('تأیید تاریخ'));
      await _tap(tester, find.text('ذخیره و بررسی'));
      expect(
        find.textContaining('تاریخ و ساعت را صریحاً انتخاب کنید'),
        findsOneWidget,
      );
      expect(
        (await repository.listSuggestions()).single.revision,
        original.revision,
      );
      await _tap(tester, find.text('انتخاب ساعت تراکنش (نامشخص)'));
      expect(find.byType(TimePickerDialog), findsOneWidget);
      await _tap(tester, find.text('تأیید ساعت'));
      final direction = find.byType(
        DropdownButtonFormField<TransactionDirection>,
      );
      await _tap(tester, direction);
      await _tap(tester, find.text('نامشخص').last);
      await _tap(tester, find.text('ذخیره و بررسی'));
      final edited = (await repository.listSuggestions()).single;
      expect(edited.draft.dateSource, TransactionDateSource.reviewer);
      expect(edited.draft.occurredAt, DateTime(2026, 10, 11, 16, 45));
      expect(edited.draft.direction, TransactionDirection.unknown);
      expect(edited.draft.type, 'unknown');
      expect(edited.extractedEvidence!.occurredAt, isNull);
      expect(edited.extractedEvidence!.sourceTime, isNull);
      await _tap(tester, find.text('تأیید و ثبت'));
      await _tap(tester, find.text('تأیید نهایی'));
      expect(
        find.textContaining('نوع تراکنش نامشخص است؛ در ویرایش'),
        findsOneWidget,
      );
      expect(await finance.listEntries(), isEmpty);
    },
  );

  for (final dark in [false, true]) {
    testWidgets(
      'transfer evidence remains blocking on narrow RTL large-text ($dark)',
      (tester) async {
        final repository = InMemoryInboxRepository();
        final inbox = InboxUseCases(repository);
        final finance = InMemoryFinanceRepository();
        final original = await inbox.stageSms(
          rawText: 'نوع: انتقال\nمبلغ: 2500 ریال\nحساب: 123456789012\nپیگیری: 987654321098',
          sourceKey: 'transfer',
          currency: 'IRR',
          importedAt: DateTime(2026, 10, 11, 16, 45),
        );
        await _mount(tester, inbox, finance, dark: dark, narrow: true);
        await _tap(tester, find.text('جزئیات پیشنهاد'));
        expect(find.textContaining('123456789012'), findsNothing);
        expect(find.textContaining('987654321098'), findsNothing);
        await _tap(tester, find.text('ویرایش'));
        await _tap(
          tester,
          find.byType(DropdownButtonFormField<TransactionDirection>),
        );
        await _tap(tester, find.text('واریز').last);
        await _tap(tester, find.text('ذخیره و بررسی'));
        final edited = (await repository.listSuggestions()).single;
        expect(edited.draft.type, 'income');
        expect(
          edited.extractedEvidence!.toJson(),
          original.extractedEvidence!.toJson(),
        );
        await _tap(tester, find.text('تأیید و ثبت'));
        await _tap(tester, find.text('تأیید نهایی'));
        expect(
          find.textContaining(
            'این پیامک انتقال است؛ درآمد یا هزینه ثبت نمی‌شود.',
          ),
          findsWidgets,
        );
        expect(await finance.listEntries(), isEmpty);
        await _tap(tester, find.text('انصراف'));
        expect(tester.takeException(), isNull);
      },
    );
  }
}
