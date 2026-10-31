import 'package:planact/core/presentation/planact_form_sheet.dart';
import 'package:planact/app/app_settings.dart';
import 'package:planact/app/money_unit_scope.dart';
import 'package:planact/features/inbox/domain/sms_currency_evidence.dart';
import 'package:planact/features/inbox/presentation/sms_review_editor.dart';
import 'package:planact/features/classification/data/drift_tag_repository.dart';
import 'package:planact/features/classification/application/tag_repository.dart';
import 'package:planact/features/classification/presentation/tag_controls.dart';

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/finance/data/drift_finance_repository.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/inbox/application/inbox_use_cases.dart';
import 'package:planact/features/inbox/data/drift_inbox_repository.dart';
import 'package:planact/features/inbox/domain/inbox.dart';
import 'package:planact/features/inbox/presentation/inbox_page.dart';

class _ReadFailureFinance extends DriftFinanceRepository {
  _ReadFailureFinance(super.database);
  bool fail = false;
  @override
  Future<List<FinancialAccount>> listAccounts() {
    if (fail) throw StateError('injected account read failure');
    return super.listAccounts();
  }
}

FinancialAccount account(String name, {bool archived = false}) =>
    FinancialAccount(
      id: StableId.generate(),
      name: name,
      currency: 'IRR',
      type: FinancialAccountType.cash,
      status: archived
          ? FinancialAccountStatus.archived
          : FinancialAccountStatus.active,
    );

Future<void> selectAccount(WidgetTester tester, String name) async {
  await tester.ensureVisible(
    find.byType(DropdownButtonFormField<FinancialAccount>),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byType(DropdownButtonFormField<FinancialAccount>));
  await tester.pumpAndSettle();
  await tester.tap(find.text(name).last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('ambiguous SMS suggests default only until explicit save', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final inbox = InboxUseCases(DriftInboxRepository(db));
    final controller = MoneyUnitController(AppSettings(db));
    await controller.load();
    await controller.select(IranianMoneyUnit.toman);
    await inbox.stageSms(
      rawText: '\u0628\u0631\u062f\u0627\u0634\u062a \u0645\u0628\u0644\u063a 1234567',
      sourceKey: 'default-unit',
      currency: 'IRR',
    );
    final suggestion = (await inbox.repository.listSuggestions()).single;
    expect(suggestion.draft.currencyEvidence!.requiresSelection, isTrue);
    Widget editor() => MaterialApp(
      builder: (_, child) =>
          MoneyUnitScope(controller: controller, child: child!),
      home: Scaffold(
        body: SmsReviewEditor(suggestion: suggestion, inbox: inbox),
      ),
    );
    await tester.pumpWidget(editor());
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<DropdownButtonFormField<SmsMoneyUnit>>(
            find.byType(DropdownButtonFormField<SmsMoneyUnit>),
          )
          .initialValue,
      SmsMoneyUnit.toman,
    );
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller!.text,
      '1,234,567',
    );
    // Leaving the form without saving never persists the suggested unit.
    await tester.pumpWidget(const SizedBox());
    expect(
      (await inbox.repository.listSuggestions())
          .single
          .draft
          .currencyEvidence!
          .requiresSelection,
      isTrue,
    );
    await tester.pumpWidget(editor());
    await tester.pumpAndSettle();
    final saveLabel = tester
        .widget<PlanActFormSheet>(find.byType(PlanActFormSheet))
        .primaryLabel;
    await tester.tap(find.text(saveLabel));
    await tester.pumpAndSettle();
    final reviewed = (await inbox.repository.listSuggestions()).single;
    expect(reviewed.draft.currencyEvidence!.selectedUnit, SmsMoneyUnit.toman);
    expect(reviewed.draft.amount.minorUnits, 12345670);
    expect(
      reviewed.extractedEvidence!.draft.currencyEvidence!.requiresSelection,
      isTrue,
    );
    expect(await DriftFinanceRepository(db).listEntries(), isEmpty);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
    await db.close();
  });

  for (final incoming in [false, true]) {
    testWidgets(
      'SMS route explicitly selects account, confirms once and cold reopens ($incoming)',
      (tester) async {
        await tester.runAsync(() async {
          final directory = await Directory.systemTemp.createTemp(
            'planact-account-route-',
          );
          final file = File('${directory.path}/state.sqlite');
          final database = AppDatabase.forTesting(NativeDatabase(file));
          final finance = DriftFinanceRepository(database);
          final inbox = InboxUseCases(DriftInboxRepository(database));
          final first = account('حساب اول');
          final second = account('حساب دوم');
          await finance.saveAccount(first);
          await finance.saveAccount(second);
          await finance.saveAccount(account('بایگانی', archived: true));
          await inbox.stageSms(
            rawText:
                '${incoming ? 'واریز' : 'برداشت'} مبلغ ۲۵۰۰ rial\nتاریخ: 2026-09-20\nساعت: 12:30',
            sourceKey: 'sms:route',
            currency: 'IRR',
          );
          var refreshes = 0;
          StableId? relationshipId;
          await tester.pumpWidget(
            MaterialApp(
              theme: incoming ? PlanActTheme.dark() : PlanActTheme.light(),
              builder: (context, child) => Directionality(
                textDirection: TextDirection.rtl,
                child: MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(incoming ? 1.5 : 1.0),
                  ),
                  child: child!,
                ),
              ),
              home: Scaffold(
                body: InboxPage(
                  inbox: inbox,
                  tagRepository: incoming ? DriftTagRepository(database) : null,
                  finance: finance,
                  onDataChanged: () async {
                    refreshes++;
                  },
                  onDetermineRelationship: (id) async {
                    relationshipId = id;
                  },
                ),
              ),
            ),
          );
          await Future<void>.delayed(const Duration(milliseconds: 100));
          await tester.pumpAndSettle();
          await tester.dragUntilVisible(
            find.text('ویرایش'),
            find.byType(ListView).first,
            const Offset(0, -400),
          );
          await tester.tap(find.text('ویرایش'));
          await tester.pumpAndSettle();
          final bankField = find.widgetWithText(TextField, 'نام بانک');
          await tester.ensureVisible(bankField);
          await tester.enterText(bankField, 'بانک بررسی‌شده');
          await tester.tap(find.text('ذخیره و بررسی'));
          await Future<void>.delayed(const Duration(milliseconds: 100));
          await tester.pumpAndSettle();
          ScaffoldMessenger.of(tester.element(find.byType(InboxPage)))
              .removeCurrentSnackBar();
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.text('تأیید و ثبت'));
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.text('تأیید و ثبت'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('تأیید و ثبت'));
          await tester.pumpAndSettle();
          for (
            var i = 0;
            i < 8 && tester.getCenter(find.byType(Checkbox).last).dy > 430;
            i++
          ) {
            await tester.drag(
              find.byType(Scrollable).last,
              const Offset(0, -200),
            );
            await tester.pumpAndSettle();
          }
          await tester.ensureVisible(find.byType(Checkbox).last);
          await tester.tap(find.byType(Checkbox).last);
          await tester.pumpAndSettle();
          await tester.tap(find.text('تأیید نهایی'));
          await tester.pumpAndSettle();
          expect(find.text('حساب مالی را انتخاب کنید.'), findsOneWidget);
          expect(await finance.listEntries(), isEmpty);
          await selectAccount(tester, 'حساب دوم');
          expect(find.text('بایگانی'), findsNothing);
          await tester.tap(find.text('تأیید نهایی'));
          await tester.tap(find.text('تأیید نهایی'));
          await Future<void>.delayed(const Duration(milliseconds: 100));
          await tester.pumpAndSettle();
          if (incoming) {
            expect(find.byType(RecordTagEditor), findsOneWidget);
            await tester.enterText(find.byType(TextField).last, 'route-tag');
            await tester.testTextInput.receiveAction(TextInputAction.done);
            await Future<void>.delayed(const Duration(milliseconds: 100));
            await tester.pumpAndSettle();
            Navigator.of(tester.element(find.byType(RecordTagEditor))).pop();
            await tester.pumpAndSettle();
          }
          final entries = await finance.listEntries();
          expect(entries, hasLength(1));
          expect(entries.single.accountId, second.id);
          expect(
            entries.single.type,
            incoming ? AccountEntryType.income : AccountEntryType.expense,
          );
          expect(refreshes, incoming ? 2 : 1);
          expect(find.text('صف بررسی خالی است'), findsOneWidget);
          await tester.tap(find.text('تعیین ارتباط'));
          expect(relationshipId, entries.single.id);
          await tester.pumpWidget(const SizedBox());
          await database.close();
          final reopened = AppDatabase.forTesting(NativeDatabase(file));
          expect(
            (await DriftFinanceRepository(
              reopened,
            ).listEntries()).single.accountId,
            second.id,
          );
          expect(
            (await DriftInboxRepository(
              reopened,
            ).listSuggestions()).single.status,
            SuggestionStatus.confirmed,
          );
          final durableSuggestion = (await DriftInboxRepository(
            reopened,
          ).listSuggestions()).single;
          expect(durableSuggestion.draft.bank, 'بانک بررسی‌شده');
          expect(durableSuggestion.extractedEvidence!.draft.bank, isNull);
          if (incoming) {
            final tags = DriftTagRepository(reopened);
            final assigned = await tags.tagsFor(
              entries.single.id.value,
              TaggableType.accountEntry,
            );
            expect(assigned, hasLength(1));
            expect(
              await tags.recordsWithTag(
                assigned.single,
                TaggableType.accountEntry,
              ),
              contains(entries.single.id.value),
            );
          }
          await reopened.close();
          await directory.delete(recursive: true);
        });
      },
    );
  }

  testWidgets(
    'empty/archived accounts, create and return, cancel creates no transaction',
    (tester) async {
      await tester.runAsync(() async {
        final database = AppDatabase.forTesting(NativeDatabase.memory());
        addTearDown(database.close);
        final finance = DriftFinanceRepository(database);
        final inbox = InboxUseCases(DriftInboxRepository(database));
        await finance.saveAccount(account('قدیمی', archived: true));
        await inbox.stageSms(
          rawText: 'برداشت مبلغ ۲۵۰۰ rial\nتاریخ: 2026-09-20\nساعت: 12:30',
          sourceKey: 'sms:empty',
          currency: 'IRR',
        );
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: InboxPage(inbox: inbox, finance: finance),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('تأیید و ثبت'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('تأیید و ثبت'));
        await tester.pumpAndSettle();
        expect(find.textContaining('برای ثبت، حساب بسازید'), findsOneWidget);
        await tester.ensureVisible(find.text('ساخت حساب'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('ساخت حساب'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.widgetWithText(TextField, 'نام حساب'),
          'حساب تازه',
        );
        await tester.tap(find.text('افزودن').last);
        await tester.pumpAndSettle();
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();
        expect(find.text('تأیید پیشنهاد تراکنش'), findsOneWidget);
        await selectAccount(tester, 'حساب تازه');
        await tester.tap(find.text('انصراف'));
        await tester.pumpAndSettle();
        expect(await finance.listEntries(), isEmpty);
        expect(await finance.listAccounts(), hasLength(2));
        expect(await inbox.listPendingSuggestions(), hasLength(1));
      });
    },
  );

  testWidgets(
    'read retry and failed atomic save retain account; stale archival rejected',
    (tester) async {
      await tester.runAsync(() async {
        final database = AppDatabase.forTesting(NativeDatabase.memory());
        addTearDown(database.close);
        final finance = _ReadFailureFinance(database);
        final inbox = InboxUseCases(DriftInboxRepository(database));
        final selected = account('حساب معتبر');
        await finance.saveAccount(selected);
        await inbox.stageSms(
          rawText: 'برداشت مبلغ ۲۵۰۰ rial\nتاریخ: 2026-09-20\nساعت: 12:30',
          sourceKey: 'sms:retry',
          currency: 'IRR',
        );
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: InboxPage(inbox: inbox, finance: finance),
            ),
          ),
        );
        await tester.pumpAndSettle();
        finance.fail = true;
        await tester.ensureVisible(find.text('تأیید و ثبت'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('تأیید و ثبت'));
        await tester.pumpAndSettle();
        expect(find.textContaining('خواندن حساب‌ها انجام نشد'), findsOneWidget);
        finance.fail = false;
        await tester.ensureVisible(find.text('تلاش دوباره'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('تلاش دوباره'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byType(Checkbox).last);
        await tester.tap(find.byType(Checkbox).last);
        await tester.pumpAndSettle();
        await selectAccount(tester, selected.name);
        await database.customStatement(
          "CREATE TRIGGER fail_confirmation BEFORE UPDATE ON inbox_suggestions BEGIN SELECT RAISE(ABORT, 'injected failure'); END",
        );
        await tester.tap(find.text('تأیید نهایی'));
        await tester.pumpAndSettle();
        expect(find.textContaining('انتخاب شما حفظ شده‌اند'), findsOneWidget);
        expect(find.text(selected.name), findsOneWidget);
        expect(await finance.listEntries(), isEmpty);
        await database.customStatement('DROP TRIGGER fail_confirmation');
        await finance.setAccountStatus(
          selected.id,
          FinancialAccountStatus.archived,
        );
        await tester.tap(find.text('تأیید نهایی'));
        await tester.pumpAndSettle();
        expect(await finance.listEntries(), isEmpty);
        await finance.setAccountStatus(
          selected.id,
          FinancialAccountStatus.active,
        );
        await tester.tap(find.text('تأیید نهایی'));
        await tester.pumpAndSettle();
        expect(await finance.listEntries(), hasLength(1));
      });
    },
  );
}
