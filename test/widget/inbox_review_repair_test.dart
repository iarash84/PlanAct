import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/features/finance/application/finance_use_cases.dart';
import 'package:planact/features/inbox/application/inbox_use_cases.dart';
import 'package:planact/features/inbox/domain/inbox.dart';
import 'package:planact/features/inbox/presentation/inbox_page.dart';

class DelayedInbox extends InboxUseCases {
  DelayedInbox(super.repository);
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

class DelayedReadRepository extends InMemoryInboxRepository {
  Completer<void>? readDelay;
  @override
  Future<List<InboxSuggestion>> listSuggestions() async {
    final snapshot = await super.listSuggestions();
    final delay = readDelay;
    readDelay = null;
    await delay?.future;
    return snapshot;
  }
}

void main() {
  testWidgets(
    'different rows run concurrently; stale refresh cannot restore rejected rows',
    (tester) async {
      final repository = DelayedReadRepository();
      final inbox = DelayedInbox(repository);
      for (var i = 0; i < 3; i++) {
        await inbox.stageSms(
          rawText: 'برداشت مبلغ ${1000 + i}',
          sourceKey: '$i',
          currency: 'IRR',
          importedAt: DateTime.utc(2026, 10, 1),
        );
      }
      await tester.pumpWidget(
        MaterialApp(
          theme: PlanActTheme.light(),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: InboxPage(
                inbox: inbox,
                finance: InMemoryFinanceRepository(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final staleRead = Completer<void>();
      repository.readDelay = staleRead;
      await tester.tap(find.byTooltip('بازخوانی'));
      await tester.pump();
      inbox.delay = Completer<void>();
      await tester.ensureVisible(find.text('رد کردن').first);
      await tester.tap(find.text('رد کردن').first);
      await tester.pump();
      final second = find.text('رد کردن').at(1);
      await tester.ensureVisible(second);
      await tester.pumpAndSettle();
      await tester.tap(second);
      await tester.pump();
      expect(inbox.calls, 2);
      // Lazy rendering may evict the first pending row while reaching the next.
      expect(find.text('در حال ذخیره…'), findsWidgets);
      inbox.delay!.complete();
      await tester.pumpAndSettle();
      staleRead.complete();
      await tester.pumpAndSettle();
      expect(
        (await repository.listSuggestions()).where(
          (s) => s.status == SuggestionStatus.rejected,
        ),
        hasLength(2),
      );
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('رد کردن'));
      expect(find.text('رد کردن'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'bank/status filters survive refresh and rejected recovery; open form survives lifecycle',
    (tester) async {
      final repository = InMemoryInboxRepository();
      final inbox = InboxUseCases(repository);
      final finance = InMemoryFinanceRepository();
      final at = DateTime.utc(2026, 10, 1);
      final rejected = await inbox.stageSms(
        rawText: 'بانک: نمونه\nبرداشت مبلغ 1000',
        sourceKey: 'a',
        currency: 'IRR',
        importedAt: at,
      );
      await inbox.stageSms(
        rawText: 'برداشت مبلغ 2000',
        sourceKey: 'b',
        currency: 'IRR',
        importedAt: at,
      );
      await inbox.reject(rejected);
      await tester.pumpWidget(
        MaterialApp(
          theme: PlanActTheme.dark(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(1.5)),
            child: child!,
          ),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: InboxPage(inbox: inbox, finance: finance),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<SuggestionStatus>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ردشده').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('نمونه').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('بازخوانی'));
      await tester.pumpAndSettle();
      expect(find.text('نمونه'), findsOneWidget);
      expect(find.text('ردشده'), findsOneWidget);
      await tester.ensureVisible(find.text('بازگردانی به صف بررسی'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('بازگردانی به صف بررسی'));
      await tester.pumpAndSettle();
      expect(
        (await repository.listSuggestions()).every(
          (s) => s.status == SuggestionStatus.pending,
        ),
        isTrue,
      );
      // Let recovery feedback expire before interacting with covered controls.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView).first, const Offset(0, 1200));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<SuggestionStatus>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('نیازمند بررسی').last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('ویرایش'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ویرایش'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '9999');
      final editedText = tester
          .widget<TextField>(find.byType(TextField).first)
          .controller!
          .text;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        editedText,
      );
      await tester.tap(find.text('انصراف'));
      await tester.pumpAndSettle();
      expect(find.text('نمونه'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    '1000-row queue stays lazy and scrollable during pending rejection, retry and Undo',
    (tester) async {
      final repository = InMemoryInboxRepository();
      final inbox = DelayedInbox(repository);
      final finance = InMemoryFinanceRepository();
      final at = DateTime.utc(2026, 10, 1);
      for (var i = 0; i < 1000; i++) {
        await inbox.stageSms(
          rawText: 'برداشت مبلغ ${1000 + i}',
          sourceKey: '$i',
          currency: 'IRR',
          importedAt: at,
        );
      }
      await tester.pumpWidget(
        MaterialApp(
          theme: PlanActTheme.light(),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: InboxPage(inbox: inbox, finance: finance),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('بانک: نامشخص'), findsWidgets);
      expect(
        find.text(
          'تاریخ تراکنش نامشخص؛ تاریخ دریافت برای ثبت پیشنهاد شده است.',
        ),
        findsWidgets,
      );
      final list = find.byType(ListView).first;
      await tester.drag(list, const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(find.text('رد کردن').evaluate().length, lessThan(15));
      inbox.delay = Completer<void>();
      inbox.fail = true;
      final reject = find.text('رد کردن').first;
      await tester.ensureVisible(reject);
      await tester.tap(reject);
      await tester.pump();
      await tester.tap(reject);
      await tester.pump();
      expect(inbox.calls, 1);
      expect(find.text('در حال ذخیره…'), findsOneWidget);
      final otherButtons = tester
          .widgetList<TextButton>(find.byType(TextButton))
          .where((b) => b.onPressed != null);
      expect(otherButtons.length, greaterThan(1));
      final scrollable = tester.state<ScrollableState>(
        find.byType(Scrollable).first,
      );
      final before = scrollable.position.pixels;
      await tester.drag(list, const Offset(0, -500));
      await tester.pumpAndSettle();
      expect(scrollable.position.pixels, greaterThan(before));
      inbox.delay!.complete();
      await tester.pumpAndSettle();
      expect(
        (await repository.listSuggestions()).where(
          (s) => s.status == SuggestionStatus.rejected,
        ),
        isEmpty,
      );
      expect(find.text('تلاش دوباره'), findsOneWidget);
      inbox.fail = false;
      inbox.delay = null;
      await tester.tap(find.text('تلاش دوباره'));
      await tester.pumpAndSettle();
      expect(
        (await repository.listSuggestions()).where(
          (s) => s.status == SuggestionStatus.rejected,
        ),
        hasLength(1),
      );
      expect(scrollable.position.pixels, greaterThan(0));
      await tester.tap(find.text('بازگردانی'));
      await tester.pumpAndSettle();
      expect(
        (await repository.listSuggestions()).where(
          (s) => s.status == SuggestionStatus.rejected,
        ),
        isEmpty,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
