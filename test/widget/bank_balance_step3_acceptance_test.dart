import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/features/finance/data/drift_finance_repository.dart';
import 'package:planact/features/finance/presentation/bank_observation_review.dart';
import 'package:planact/features/finance/presentation/finance_page.dart';
import 'package:planact/features/inbox/application/inbox_use_cases.dart';
import 'package:planact/features/inbox/data/drift_inbox_repository.dart';
import 'package:planact/features/inbox/domain/inbox.dart';
import 'package:planact/features/inbox/presentation/inbox_page.dart';

import '../repository/bank_recovery_test.dart' show account, chain;
import 'inbox_account_selection_test.dart' show selectAccount;

const recovery = 'بررسی تطبیق‌های قبلی';
Future<void> tap(WidgetTester tester, Finder finder) async {
  await tester.pumpAndSettle();
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find.byType(Scrollable).last,
    );
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Widget host(Widget child, bool dark) => MaterialApp(
  theme: dark ? PlanActTheme.dark() : PlanActTheme.light(),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(2)),
    child: Directionality(textDirection: TextDirection.rtl, child: child!),
  ),
  home: Scaffold(body: child),
);

void main() {
  for (final dark in [false, true]) {
    testWidgets(
      'evidence recovery cancellation retains form; recovery never saves 320dp scale2 $dark',
      (tester) async {
        tester.view.physicalSize = const Size(320, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        addTearDown(db.close);
        final repo = DriftFinanceRepository(db);
        final a = account('حساب شاهد');
        await chain(db, repo, a);
        final observation = (await repo.bankBalance(a.id.value))
            .observations
            .first;
        await tester.pumpWidget(host(FinancePage(repository: repo), dark));
        await tap(tester, find.byKey(const ValueKey('finance-accounts-entry')));
        await tap(tester, find.text('بررسی گزارش موجودی').first);
        await tester.enterText(
          find.descendant(
            of: find.byType(BankObservationReview),
            matching: find.byType(TextField),
          ),
          '350',
        );
        await tap(
          tester,
          find.widgetWithText(FilledButton, 'تأیید بررسی گزارش موجودی'),
        );
        await tap(
          tester,
          find.widgetWithText(FilledButton, 'تأیید بررسی گزارش موجودی').last,
        );
        await tap(tester, find.widgetWithText(TextButton, recovery).last);
        expect(find.textContaining(observation.id), findsWidgets);
        await tap(tester, find.widgetWithText(TextButton, 'انصراف').last);
        expect((await repo.listEntries()).length, 2);
        expect(
          tester
              .widget<TextField>(
                find.descendant(
                  of: find.byType(BankObservationReview),
                  matching: find.byType(TextField),
                ),
              )
              .controller!
              .text,
          '350',
        );
        await tap(tester, find.widgetWithText(TextButton, recovery).last);
        await tap(
          tester,
          find.widgetWithText(FilledButton, 'لغو ۲ تطبیق قبلی'),
        );
        expect(find.byType(BankObservationReview), findsOneWidget);
        expect((await repo.listEntries()).length, 4);
        expect(
          (await repo.bankBalance(a.id.value)).observations.first.revision,
          0,
        );
        expect(
          tester
              .widget<TextField>(
                find.descendant(
                  of: find.byType(BankObservationReview),
                  matching: find.byType(TextField),
                ),
              )
              .controller!
              .text,
          '350',
        );
        await tap(
          tester,
          find.widgetWithText(FilledButton, 'تأیید بررسی گزارش موجودی'),
        );
        await tap(
          tester,
          find.widgetWithText(FilledButton, 'تأیید بررسی گزارش موجودی').last,
        );
        expect(
          (await repo.bankBalance(a.id.value)).observations.first.sourceAmount,
          350,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Inbox backdated draft retained through cancel and recovery; explicit retry 320dp scale2 $dark',
      (tester) async {
        tester.view.physicalSize = const Size(320, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        addTearDown(db.close);
        final repo = DriftFinanceRepository(db);
        final a = account('حساب پیامک');
        await chain(db, repo, a);
        final inbox = InboxUseCases(DriftInboxRepository(db));
        await inbox.stageSms(
          rawText: 'برداشت مبلغ ۲۵۰۰ rial\nتاریخ: 2025-09-20\nساعت: 12:30',
          sourceKey: 'backdated-recovery',
          currency: 'IRR',
        );
        await tester.pumpWidget(
          host(InboxPage(inbox: inbox, finance: repo), dark),
        );
        await tester.pumpAndSettle();
        await tap(tester, find.text('تأیید و ثبت'));
        await selectAccount(tester, a.name);
        await tap(tester, find.byType(Checkbox).last);
        await tap(tester, find.text('تأیید نهایی'));
        await tap(tester, find.widgetWithText(TextButton, recovery).last);
        await tap(tester, find.widgetWithText(TextButton, 'انصراف').last);
        expect((await repo.listEntries()).length, 2);
        expect(
          (await inbox.repository.listSuggestions()).single.status,
          isNot(SuggestionStatus.confirmed),
        );
        await tap(tester, find.widgetWithText(TextButton, recovery).last);
        await tap(
          tester,
          find.widgetWithText(FilledButton, 'لغو ۲ تطبیق قبلی'),
        );
        expect((await repo.listEntries()).length, 4);
        expect(
          (await inbox.repository.listSuggestions()).single.status,
          isNot(SuggestionStatus.confirmed),
        );
        expect(
          tester.widget<Checkbox>(find.byType(Checkbox).last).value,
          isTrue,
        );
        expect(find.text(a.name), findsWidgets);
        await tap(tester, find.text('تأیید نهایی'));
        expect(
          (await inbox.repository.listSuggestions()).single.status,
          SuggestionStatus.confirmed,
        );
        expect((await repo.listEntries()).length, 5);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
