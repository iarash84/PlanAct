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
          await tester.ensureVisible(find.text('ویرایش'));
          await tester.pumpAndSettle();
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
          await tester.tap(find.text('تأیید و ثبت'));
          await tester.pumpAndSettle();
          for (
            var i = 0;
            i < 8 && tester.getCenter(find.byType(Checkbox)).dy > 430;
            i++
          ) {
            await tester.drag(
              find.byType(Scrollable).last,
              const Offset(0, -200),
            );
            await tester.pumpAndSettle();
          }
          await tester.ensureVisible(find.byType(Checkbox));
          await tester.tap(find.byType(Checkbox));
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
          final entries = await finance.listEntries();
          expect(entries, hasLength(1));
          expect(entries.single.accountId, second.id);
          expect(
            entries.single.type,
            incoming ? AccountEntryType.income : AccountEntryType.expense,
          );
          expect(refreshes, 1);
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
        await tester.tap(find.text('تأیید و ثبت'));
        await tester.pumpAndSettle();
        expect(find.textContaining('خواندن حساب‌ها انجام نشد'), findsOneWidget);
        finance.fail = false;
        await tester.ensureVisible(find.text('تلاش دوباره'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('تلاش دوباره'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byType(Checkbox));
        await tester.tap(find.byType(Checkbox));
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
        await finance.saveAccount(
          FinancialAccount(
            id: selected.id,
            name: selected.name,
            currency: selected.currency,
            type: selected.type,
            status: FinancialAccountStatus.archived,
          ),
        );
        await tester.tap(find.text('تأیید نهایی'));
        await tester.pumpAndSettle();
        expect(await finance.listEntries(), isEmpty);
        await finance.saveAccount(selected);
        await tester.tap(find.text('تأیید نهایی'));
        await tester.pumpAndSettle();
        expect(await finance.listEntries(), hasLength(1));
      });
    },
  );
}
