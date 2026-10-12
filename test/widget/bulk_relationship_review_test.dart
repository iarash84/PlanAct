import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/finance/application/finance_use_cases.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/reconciliation/application/bulk_relationship_review.dart';
import 'package:planact/features/reconciliation/application/reconciliation_use_cases.dart';
import 'package:planact/features/reconciliation/domain/relationship_review.dart';
import 'package:planact/features/reconciliation/presentation/relationship_queue_page.dart';

class ControlledReviews extends InMemoryReconciliationRepository {
  StableId? fail;
  Completer<void>? pause;
  int calls = 0;
  @override
  Future<RelationshipReview> decideReview({
    required RelationshipReview expected,
    required RelationshipReviewDecision decision,
    required DateTime recordedAt,
  }) async {
    calls++;
    final waiting = pause;
    pause = null;
    if (waiting != null) await waiting.future;
    if (expected.transactionId == fail) throw StateError('test failure');
    return super.decideReview(
      expected: expected,
      decision: decision,
      recordedAt: recordedAt,
    );
  }
}

void main() {
  late InMemoryFinanceRepository finance;
  late ControlledReviews reviews;
  late List<AccountEntry> entries;
  setUp(() {
    finance = InMemoryFinanceRepository();
    reviews = ControlledReviews();
    entries = [];
  });
  Future<void> seed(int count) async {
    final account = StableId.generate();
    for (var i = 0; i < count; i++) {
      final entry = AccountEntry(
        id: StableId.generate(),
        accountId: account,
        type: i.isEven ? AccountEntryType.income : AccountEntryType.expense,
        amount: const Money(minorUnits: 1000, currency: 'IRR'),
        occurredAt: DateTime.utc(2026).add(Duration(minutes: i)),
        note: 'شرح $i',
      );
      entries.add(entry);
      await finance.saveEntry(entry);
    }
  }

  Future<void> show(
    WidgetTester tester, {
    bool dark = false,
    double scale = 1,
    Future<void> Function(StableId)? onOpen,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: dark ? PlanActTheme.dark() : PlanActTheme.light(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: child!,
          ),
        ),
        home: RelationshipQueuePage(
          queue: RelationshipQueue(finance, reviews),
          onOpen: onOpen ?? (_) async {},
          onDataChanged: () async {},
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, String label) async {
    final finder = find.text(label);
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  for (final dark in [false, true]) {
    testWidgets(
      '50 visible not 51; cancellation filters page scope and explicit retry ($dark)',
      (tester) async {
        await seed(51);
        await show(tester, dark: dark);
        await tap(tester, 'انتخاب همین صفحه');
        await tap(tester, 'مستقل ثبت کن (۵۰)');
        expect(
          find.textContaining('۵۰ مورد انتخاب‌شده از صفحهٔ نمایش‌داده‌شده'),
          findsOneWidget,
        );
        await tap(tester, 'انصراف');
        expect(reviews.calls, 0);
        await tap(tester, 'صفحهٔ بعد');
        expect(find.text('مستقل ثبت کن (۰)'), findsOneWidget);
        await tap(tester, 'انتخاب همین صفحه');
        expect(find.text('مستقل ثبت کن (۱)'), findsOneWidget);
        await tap(tester, 'درآمد');
        expect(find.text('مستقل ثبت کن (۰)'), findsOneWidget);
        await tester.enterText(find.byType(TextField), 'شرح 0');
        await tester.pumpAndSettle();
        FocusManager.instance.primaryFocus?.unfocus();
        await tap(tester, 'انتخاب همین صفحه');
        reviews.fail = entries.first.id;
        await tap(tester, 'مستقل ثبت کن (۱)');
        await tap(tester, 'تأیید مستقل بودن');
        expect(reviews.calls, 1);
        expect(find.textContaining('ناموفق: ۱'), findsOneWidget);
        reviews.fail = null;
        await tap(tester, 'تلاش دوباره برای ناموفق‌ها');
        expect(
          find.textContaining('۱ مورد ناموفق از انتخاب قبلی'),
          findsOneWidget,
        );
        await tap(tester, 'تأیید مستقل بودن');
        expect(reviews.calls, 2);
        expect((await reviews.loadReview(entries.first)).isIndependent, true);
        expect(await reviews.reviewHistory(entries.first), hasLength(1));
        await tap(tester, 'مستقل‌های بررسی‌شده');
        await tap(tester, 'بازگشایی بررسی ارتباط');
        expect((await reviews.loadReview(entries.first)).isIndependent, false);
        expect(await reviews.reviewHistory(entries.first), hasLength(2));
        expect(await finance.listEntries(), hasLength(51));
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'progress stop allows browsing and prevents next item; fresh selection after reentry',
    (tester) async {
      await seed(3);
      await show(tester);
      await tap(tester, 'انتخاب همین صفحه');
      await tap(tester, 'مستقل ثبت کن (۳)');
      final pause = Completer<void>();
      reviews.pause = pause;
      await tester.tap(find.text('تأیید مستقل بودن'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('توقف پس از مورد جاری'), findsOneWidget);
      final refresh = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'بازخوانی'),
      );
      expect(refresh.onPressed, isNotNull);
      await tester.ensureVisible(find.text('توقف پس از مورد جاری'));
      await tester.tap(find.text('توقف پس از مورد جاری'));
      await tester.pump();
      pause.complete();
      await tester.pumpAndSettle();
      expect(reviews.calls, 1);
      expect(find.textContaining('موفق: ۱'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await show(tester);
      expect(find.text('مستقل ثبت کن (۰)'), findsOneWidget);
      expect(
        (await RelationshipQueue(finance, reviews).load()).items,
        hasLength(2),
      );
    },
  );

  testWidgets(
    'narrow large text dark filters detail and refresh drop old selection',
    (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await seed(2);
      StableId? opened;
      await show(
        tester,
        dark: true,
        scale: 1.8,
        onOpen: (id) async {
          opened = id;
        },
      );
      await tap(tester, 'انتخاب همین صفحه');
      await tap(tester, 'بازخوانی');
      await tester.ensureVisible(find.text('مستقل ثبت کن (۰)'));
      expect(find.text('مستقل ثبت کن (۰)'), findsOneWidget);
      final detail = find.text('بررسی تکی ارتباط').first;
      await tester.ensureVisible(detail);
      await tester.pumpAndSettle();
      await tester.tap(detail);
      await tester.pumpAndSettle();
      expect(opened, entries.last.id);
      expect(reviews.calls, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'stale failure retry does not replace original approval after a newer decision',
    (tester) async {
      await seed(1);
      await show(tester);
      await tap(tester, 'انتخاب همین صفحه');
      reviews.fail = entries.single.id;
      await tap(tester, 'مستقل ثبت کن (۱)');
      await tap(tester, 'تأیید مستقل بودن');
      reviews.fail = null;
      final old = await reviews.loadReview(entries.single);
      final independent = await reviews.decideReview(
        expected: old,
        decision: RelationshipReviewDecision.independent,
        recordedAt: DateTime.now(),
      );
      await reviews.decideReview(
        expected: independent,
        decision: RelationshipReviewDecision.reopened,
        recordedAt: DateTime.now(),
      );
      await tap(tester, 'تلاش دوباره برای ناموفق‌ها');
      await tap(tester, 'تأیید مستقل بودن');
      expect((await reviews.loadReview(entries.single)).isIndependent, false);
      expect(await reviews.reviewHistory(entries.single), hasLength(2));
      expect(find.textContaining('ناموفق: ۱'), findsOneWidget);
    },
  );
}
