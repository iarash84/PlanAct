import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:planact/app/planact_app.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/localization/planact_localizations.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/commitments/data/drift_checklist_repository.dart';
import 'package:planact/features/commitments/data/drift_commitment_repository.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/finance/data/drift_finance_repository.dart';
import 'package:planact/features/finance/application/finance_use_cases.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/finance/presentation/finance_page.dart';
import 'package:planact/features/search/presentation/search_page.dart';

import 'global_search_test.dart' show query, settleIo, queryKey;

const _notificationsChannel = MethodChannel(
  'dexterous.com/flutter/local_notifications',
);
const _alarmsChannel = MethodChannel('planact/alarms');
const _timezoneChannel = MethodChannel('flutter_timezone');

Future<void> withStubbedReminderPlatform(
  WidgetTester tester,
  Future<void> Function() run,
) async {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final previousPlatform = debugDefaultTargetPlatformOverride;
  debugDefaultTargetPlatformOverride = TargetPlatform.android;
  AndroidFlutterLocalNotificationsPlugin.registerWith();
  messenger.setMockMethodCallHandler(
    _timezoneChannel,
    (_) async => 'Asia/Tehran',
  );
  messenger.setMockMethodCallHandler(_notificationsChannel, (call) async {
    return switch (call.method) {
      'initialize' ||
      'areNotificationsEnabled' ||
      'canScheduleExactNotifications' => true,
      'pendingNotificationRequests' => <Object>[],
      _ => null,
    };
  });
  messenger.setMockMethodCallHandler(_alarmsChannel, (call) async {
    return call.method == 'available'
        ? true
        : call.method == 'schedule'
        ? true
        : null;
  });
  try {
    await run();
  } finally {
    debugDefaultTargetPlatformOverride = previousPlatform;
    for (final channel in [
      _notificationsChannel,
      _alarmsChannel,
      _timezoneChannel,
    ]) {
      messenger.setMockMethodCallHandler(channel, null);
    }
  }
}

Future<void> openResult(WidgetTester tester, String type, String id) async {
  await tester.tap(find.byKey(ValueKey('search-result-$type-$id')));
  await settleIo(tester);
}

Future<void> waitForFinder(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final watch = Stopwatch()..start();
  while (finder.evaluate().isEmpty && watch.elapsed < timeout) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
  }
  expect(finder, findsOneWidget);
}

Future<void> waitForSearchText(WidgetTester tester, String text) =>
    waitForFinder(tester, find.textContaining(text));

class SlowFinance extends InMemoryFinanceRepository {
  final commit = Completer<void>();
  @override
  Future<AccountEntry> reverseEntry({
    required AccountEntry expected,
    required StableId accountId,
    required DateTime occurredAt,
    AccountEntry? corrected,
  }) async {
    await commit.future;
    return super.reverseEntry(
      expected: expected,
      accountId: accountId,
      occurredAt: occurredAt,
      corrected: corrected,
    );
  }
}

void main() {
  for (final confirm in [false, true]) {
    testWidgets(
      'search refreshes snackbar Undo only after confirmation ($confirm)',
      (tester) async {
        await withStubbedReminderPlatform(tester, () async {
          await tester.binding.setSurfaceSize(const Size(800, 1200));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final db = AppDatabase.forTesting(NativeDatabase.memory());
          addTearDown(db.close);
          final owners = DriftCommitmentRepository(db);
          final owner = Commitment.create(title: 'خرید');
          await owners.save(owner);
          await tester.pumpWidget(PlanActApp(repository: owners));
          await settleIo(tester);
          await tester.tap(find.byKey(const ValueKey('shell-search')));
          await settleIo(tester);
          await query(tester, 'خرید');
          await tester.tap(
            find.byKey(const ValueKey('search-filter-commitment')),
          );
          await openResult(tester, 'commitment', owner.id.value);
          await tester.tap(find.text('توقف موقت'));
          final undo = find.byType(SnackBarAction);
          await waitForFinder(tester, undo);
          await tester.pump(const Duration(milliseconds: 500));
          await tester.tap(undo);
          await tester.pumpAndSettle();
          expect(
            (await owners.findById(owner.id))!.status,
            CommitmentStatus.paused,
          );
          await tester.tap(
            confirm
                ? find.widgetWithText(FilledButton, 'تأیید')
                : find.widgetWithText(TextButton, 'انصراف'),
          );
          await settleIo(tester);
          expect(
            (await owners.findById(owner.id))!.status,
            confirm ? CommitmentStatus.active : CommitmentStatus.paused,
          );
          await waitForSearchText(tester, confirm ? 'فعال' : 'متوقف‌شده');
          expect(
            find.textContaining('متوقف‌شده'),
            confirm ? findsNothing : findsOneWidget,
          );
          expect(
            tester.widget<TextField>(find.byKey(queryKey)).controller!.text,
            'خرید',
          );
          expect(
            tester
                .widget<FilterChip>(
                  find.byKey(const ValueKey('search-filter-commitment')),
                )
                .selected,
            isTrue,
          );
        });
      },
    );
  }

  testWidgets(
    'shell search → lifecycle actions and durable Undo → checklist tasks without parent completion',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final owners = DriftCommitmentRepository(db);
      final owner = Commitment.create(title: 'لیست خرید');
      await owners.save(owner);
      await tester.pumpWidget(PlanActApp(repository: owners));
      await settleIo(tester);
      await tester.tap(find.byKey(const ValueKey('shell-search')));
      await settleIo(tester);
      await query(tester, 'خرید');
      await openResult(tester, 'commitment', owner.id.value);
      expect(find.byType(CommitmentDetailsPage), findsNothing);
      await tester.binding.handlePopRoute();
      await settleIo(tester);
      expect(
        (await owners.findById(owner.id))!.status,
        CommitmentStatus.active,
      );
      await openResult(tester, 'commitment', owner.id.value);
      await tester.tap(find.text('توقف موقت'));
      await settleIo(tester);
      expect(
        (await owners.findById(owner.id))!.status,
        CommitmentStatus.paused,
      );
      expect(find.textContaining('متوقف‌شده'), findsWidgets);
      await openResult(tester, 'commitment', owner.id.value);
      await tester.tap(find.text('بایگانی'));
      await settleIo(tester);
      expect(
        (await owners.findById(owner.id))!.status,
        CommitmentStatus.archived,
      );
      expect(find.textContaining('بایگانی‌شده'), findsOneWidget);
      await openResult(tester, 'commitment', owner.id.value);
      await tester.tap(find.text('بازگردانی آخرین تغییر وضعیت'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'تأیید'));
      await settleIo(tester);
      expect(
        (await owners.findById(owner.id))!.status,
        CommitmentStatus.paused,
      );
      await openResult(tester, 'commitment', owner.id.value);
      await tester.tap(find.text('جزئیات و ویرایش'));
      await settleIo(tester);
      await tester.tap(find.byKey(const ValueKey('checklist-add')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('checklist-item-title')),
        'پیش‌نویس',
      );
      await tester.tap(find.text('انصراف'));
      await tester.pumpAndSettle();
      final repo = DriftChecklistRepository(db);
      expect((await repo.load(owner.id)).list.revision, 0);
      await tester.tap(find.byKey(const ValueKey('checklist-add')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('checklist-item-save')));
      await tester.pumpAndSettle();
      expect(find.text('عنوان کار را وارد کنید.'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('checklist-item-title')),
        'نان',
      );
      await tester.tap(find.byKey(const ValueKey('checklist-item-save')));
      await settleIo(tester);
      final item = (await repo.load(owner.id)).list.items.single;
      await tester.tap(find.byKey(ValueKey('checklist-item-${item.id.value}')));
      await settleIo(tester);
      expect((await repo.load(owner.id)).list.items.single.checked, isTrue);
      expect(find.text('۱ از ۱ کار انجام شده'), findsOneWidget);
      expect(
        (await owners.findById(owner.id))!.status,
        CommitmentStatus.paused,
      );
      await tester.tap(find.byTooltip('اقدام‌های این کار'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ویرایش کار'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('checklist-item-title')),
        'نان سنگک',
      );
      await tester.tap(find.byKey(const ValueKey('checklist-item-save')));
      await settleIo(tester);
      await tester.tap(find.byTooltip('اقدام‌های این کار'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('کنار گذاشتن کار'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'تأیید'));
      await settleIo(tester);
      expect((await repo.load(owner.id)).list.items.single.removed, isTrue);
      await tester.tap(find.text('کارهای کنارگذاشته‌شده'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('بازگرداندن کار'));
      await settleIo(tester);
      expect((await repo.load(owner.id)).list.items.single.removed, isFalse);
      expect(find.text('نان سنگک'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await settleIo(tester);
      expect(find.byType(SearchPage), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byKey(queryKey)).controller!.text,
        'خرید',
      );
      await openResult(tester, 'commitment', owner.id.value);
      await tester.tap(find.text('جزئیات و ویرایش'));
      await settleIo(tester);
      expect(
        tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
        isTrue,
      );
      expect(await db.select(db.occurrences).get(), isEmpty);
      expect(await db.select(db.accountEntries).get(), isEmpty);
      expect(await db.select(db.entitlementLedgerEntries).get(), isEmpty);
    },
  );

  testWidgets(
    'search financial result exposes confirmed cancellation and account archive; return refreshes source',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final finance = DriftFinanceRepository(db);
      final account = FinancialAccount(
        id: StableId.generate(),
        name: 'حساب خرید',
        currency: 'IRR',
        type: FinancialAccountType.cash,
      );
      await finance.saveAccount(account);
      final entry = AccountEntry(
        // Separate tables permit equal IDs; Search must retain the target kind.
        id: account.id,
        accountId: account.id,
        type: AccountEntryType.expense,
        amount: Money(minorUnits: 250000, currency: 'IRR'),
        occurredAt: DateTime.now().toUtc(),
        note: 'خرید نان',
      );
      await finance.saveEntry(entry);
      await tester.pumpWidget(
        PlanActApp(repository: DriftCommitmentRepository(db)),
      );
      await settleIo(tester);
      await tester.tap(find.byKey(const ValueKey('shell-search')));
      await settleIo(tester);
      await query(tester, 'خرید');
      await openResult(tester, 'transaction', entry.id.value);
      expect(
        find.byKey(ValueKey('account-menu:${account.id.value}')),
        findsNothing,
      );
      await tester.tap(find.byKey(ValueKey('entry-menu:${entry.id.value}')));
      await tester.pumpAndSettle();
      expect(find.text('اصلاح تراکنش'), findsOneWidget);
      await tester.tap(find.text('حذف امن تراکنش'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('انصراف'));
      await tester.pumpAndSettle();
      expect(await finance.listEntries(), hasLength(1));
      await tester.tap(find.byKey(ValueKey('entry-menu:${entry.id.value}')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('حذف امن تراکنش'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'تأیید'));
      await settleIo(tester);
      expect(
        (await finance.listEntries()).where(
          (e) => e.type == AccountEntryType.reversal,
        ),
        hasLength(1),
      );
      await tester.tap(find.byKey(ValueKey('entry-menu:${entry.id.value}')));
      await tester.pumpAndSettle();
      expect(find.text('حذف امن تراکنش'), findsNothing);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await settleIo(tester);
      await openResult(tester, 'account', account.id.value);
      expect(
        find.byKey(ValueKey('entry-menu:${entry.id.value}')),
        findsNothing,
      );
      await tester.tap(
        find.byKey(ValueKey('account-menu:${account.id.value}')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('بایگانی حساب'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'تأیید'));
      await settleIo(tester);
      expect(
        (await finance.listAccounts()).single.status,
        FinancialAccountStatus.archived,
      );
      await tester.binding.handlePopRoute();
      await settleIo(tester);
      expect(find.textContaining('بایگانی‌شده'), findsWidgets);
    },
  );

  testWidgets(
    'focused finance waits for admitted cancellation before Back can refresh search',
    (tester) async {
      final finance = SlowFinance();
      final account = FinancialAccount(
        id: StableId.generate(),
        name: 'حساب',
        currency: 'IRR',
        type: FinancialAccountType.cash,
      );
      await finance.saveAccount(account);
      final entry = AccountEntry(
        id: StableId.generate(),
        accountId: account.id,
        type: AccountEntryType.expense,
        amount: Money(minorUnits: 100, currency: 'IRR'),
        occurredAt: DateTime.now(),
      );
      await finance.saveEntry(entry);
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('fa'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) => FinancePage(
                      repository: finance,
                      focusedRecordId: entry.id.value,
                    ),
                  ),
                ),
                child: const Text('باز کردن نتیجه'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('باز کردن نتیجه'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey('entry-menu:${entry.id.value}')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('حذف امن تراکنش'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'تأیید'));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(FinancePage), findsOneWidget);
      expect(await finance.listEntries(), hasLength(1));
      finance.commit.complete();
      await tester.pumpAndSettle();
      expect(await finance.listEntries(), hasLength(2));
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(FinancePage), findsNothing);
    },
  );
}
