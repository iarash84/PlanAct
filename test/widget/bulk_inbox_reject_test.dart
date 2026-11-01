import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/features/finance/application/finance_use_cases.dart';
import 'package:planact/features/inbox/application/inbox_use_cases.dart';
import 'package:planact/features/inbox/domain/inbox.dart';
import 'package:planact/features/inbox/presentation/inbox_page.dart';

class ControlledInbox extends InboxUseCases {
  ControlledInbox(super.repository);
  Completer<void>? delay;
  bool fail = false;
  int calls = 0;
  @override
  Future<void> reject(InboxSuggestion suggestion) async {
    calls++;
    await delay?.future;
    if (fail) throw StateError('injected');
    await super.reject(suggestion);
  }
}

Future<void> mount(
  WidgetTester tester,
  ControlledInbox inbox, {
  bool dark = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: dark ? PlanActTheme.dark() : PlanActTheme.light(),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: InboxPage(inbox: inbox, finance: InMemoryFinanceRepository()),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> press(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text).last);
  await tester.pumpAndSettle();
  await tester.tap(find.text(text).last);
  await tester.pump();
}

void main() {
  testWidgets('Inbox keeps a minimum gap between independent sections', (
    tester,
  ) async {
    final inbox = ControlledInbox(InMemoryInboxRepository());

    await mount(tester, inbox);

    final status = find.byType(DropdownButtonFormField<SuggestionStatus>);
    final bank = find.byType(DropdownButtonFormField<String>);
    expect(status, findsOneWidget);
    expect(bank, findsOneWidget);
    expect(
      tester.getTopLeft(bank).dy - tester.getBottomLeft(status).dy,
      greaterThanOrEqualTo(PlanActSpacing.lg),
    );
  });

  testWidgets(
    'refresh invalidates stale selection and filters clear selection',
    (tester) async {
      final inbox = ControlledInbox(InMemoryInboxRepository());
      final first = await inbox.stageSms(
        rawText: 'برداشت مبلغ 3000',
        sourceKey: 'first',
        currency: 'IRR',
      );
      await inbox.stageSms(
        rawText: 'برداشت مبلغ 4000',
        sourceKey: 'second',
        currency: 'IRR',
      );
      await mount(tester, inbox);
      await press(tester, 'انتخاب موارد همین صفحه');
      expect(find.textContaining('انتخاب‌شده: ۲'), findsOneWidget);
      await inbox.reject(first);
      await tester
          .widget<RefreshIndicator>(find.byType(RefreshIndicator))
          .onRefresh();
      await tester.pumpAndSettle();
      expect(find.textContaining('انتخاب‌شده: ۱'), findsOneWidget);
      await tester.ensureVisible(
        find.byType(DropdownButtonFormField<SuggestionStatus>),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('نیازمند بررسی').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('ردشده').last);
      await tester.pumpAndSettle();
      expect(find.textContaining('انتخاب‌شده: ۰'), findsOneWidget);
      expect(find.text('انتخاب برای رد گروهی'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    '50-row page scope, count, confirmation cancellation and page clears selection',
    (tester) async {
      final inbox = ControlledInbox(InMemoryInboxRepository());
      for (var i = 0; i < 51; i++) {
        await inbox.stageSms(
          rawText: 'برداشت مبلغ ${1000 + i}',
          sourceKey: '$i',
          currency: 'IRR',
        );
      }
      await mount(tester, inbox);
      await press(tester, 'انتخاب موارد همین صفحه');
      expect(find.textContaining('انتخاب‌شده: ۵۰'), findsOneWidget);
      await press(tester, 'رد کردن گروهی');
      await tester.pumpAndSettle();
      expect(find.textContaining('۵۰ پیشنهاد از همین صفحه'), findsOneWidget);
      await tester.tap(find.text('انصراف'));
      await tester.pumpAndSettle();
      expect(inbox.calls, 0);
      await press(tester, 'صفحهٔ بعد');
      expect(find.textContaining('انتخاب‌شده: ۰'), findsOneWidget);
      await press(tester, 'انتخاب موارد همین صفحه');
      expect(find.textContaining('انتخاب‌شده: ۱'), findsOneWidget);
      await press(tester, 'رد کردن گروهی');
      await tester.pumpAndSettle();
      await tester.tap(find.text('رد کردن انتخاب‌ها'));
      await tester.pumpAndSettle();
      expect(inbox.calls, 1);
      expect(
        (await inbox.repository.listSuggestions()).where(
          (s) => s.status == SuggestionStatus.rejected,
        ),
        hasLength(1),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'progress cancellation preserves remaining rows; failure retry reconfirms',
    (tester) async {
      final inbox = ControlledInbox(InMemoryInboxRepository());
      for (var i = 0; i < 3; i++) {
        await inbox.stageSms(
          rawText: 'برداشت مبلغ ${2000 + i}',
          sourceKey: '$i',
          currency: 'IRR',
        );
      }
      await mount(tester, inbox, dark: true);
      await press(tester, 'انتخاب موارد همین صفحه');
      await press(tester, 'رد کردن گروهی');
      await tester.pumpAndSettle();
      inbox.delay = Completer<void>();
      await tester.tap(find.text('رد کردن انتخاب‌ها'));
      await tester.pump();
      await press(tester, 'توقف پس از مورد جاری');
      inbox.delay!.complete();
      inbox.delay = null;
      await tester.pumpAndSettle();
      expect(inbox.calls, 1);
      expect(
        (await inbox.repository.listSuggestions()).where(
          (s) => s.status == SuggestionStatus.pending,
        ),
        hasLength(2),
      );
      inbox.fail = true;
      await press(tester, 'انتخاب موارد همین صفحه');
      await press(tester, 'رد کردن گروهی');
      await tester.pumpAndSettle();
      await tester.tap(find.text('رد کردن انتخاب‌ها'));
      await tester.pumpAndSettle();
      expect(find.textContaining('ناموفق: ۲'), findsOneWidget);
      inbox.fail = false;
      await press(tester, 'تلاش دوباره برای موارد ناموفق');
      await tester.pumpAndSettle();
      expect(find.textContaining('۲ پیشنهاد از همین صفحه'), findsOneWidget);
      await tester.tap(find.text('رد کردن انتخاب‌ها'));
      await tester.pumpAndSettle();
      expect(
        (await inbox.repository.listSuggestions()).every(
          (s) => s.status == SuggestionStatus.rejected,
        ),
        isTrue,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
