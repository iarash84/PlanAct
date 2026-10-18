import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/planact_app.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/features/commitments/data/drift_commitment_repository.dart';
import 'package:planact/features/finance/data/drift_finance_repository.dart';
import 'package:planact/features/inbox/application/inbox_use_cases.dart';
import 'package:planact/features/inbox/application/sms_ingestion.dart';
import 'package:planact/features/inbox/data/drift_inbox_repository.dart';
import 'package:planact/features/inbox/presentation/inbox_page.dart';
import 'package:planact/features/today/application/attention_engine.dart';
import 'package:planact/features/today/presentation/today_page.dart';

import '../fixtures/sms_provider.dart';

int pendingOnToday(WidgetTester tester) => tester
    .widget<TodayPage>(find.byType(TodayPage, skipOffstage: false))
    .actionCenter!
    .attention
    .where((a) => a.type == TodayActionItemType.inboxReview)
    .length;

Future<void> settle(WidgetTester tester) async {
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'root startup, resume, delayed broadcast and Today/Inbox pulls synchronize without Inbox being open',
    (tester) async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = DriftInboxRepository(db);
      final inbox = InboxUseCases(repo);
      final source = TestSmsProvider();
      addTearDown(source.events.close);
      final from = DateTime.now().subtract(const Duration(hours: 1));
      final start = from.millisecondsSinceEpoch;
      await SmsIngestion(
        inbox,
        source,
        store: AutomaticSmsScanAdapter(repo),
      ).consent(
        from: from,
        until: DateTime.now(),
        newOnly: true,
        automatic: true,
      );
      source.add(1, start + 10);
      await tester.pumpWidget(
        PlanActApp(
          repository: DriftCommitmentRepository(db),
          smsSource: source,
        ),
      );
      await settle(tester);
      expect(find.byType(InboxPage), findsNothing);
      expect(await repo.listSuggestions(), hasLength(1));
      expect(pendingOnToday(tester), 1);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      final reads = source.reads;
      source.add(2, start + 30);
      source.events.add(source.rows.last.message!);
      await tester.pump(const Duration(seconds: 9));
      expect(source.reads, reads);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await settle(tester);
      expect(pendingOnToday(tester), 2);

      // Broadcast arrives before its provider row. The second scheduled check
      // must recover a row behind the old completed cursor without a new event.
      source.events.add(source.rows.first.message!);
      await tester.pump(const Duration(seconds: 2));
      await settle(tester);
      expect(pendingOnToday(tester), 2);
      source.add(3, start + 20);
      await tester.pump(const Duration(seconds: 6));
      await settle(tester);
      expect(pendingOnToday(tester), 3);
      expect(find.byType(InboxPage), findsNothing);

      source.add(4, start + 40);
      final todayList = find
          .descendant(
            of: find.byType(TodayPage),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.drag(todayList, const Offset(0, 500));
      await settle(tester);
      expect(pendingOnToday(tester), 4);

      await tester.tap(find.text('بیشتر').last);
      await settle(tester);
      await tester.tap(find.text('صندوق ورودی').last);
      await settle(tester);
      expect(find.byType(InboxPage), findsOneWidget);
      source.add(5, start + 50);
      final inboxList = find
          .descendant(
            of: find.byType(InboxPage),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.drag(inboxList, const Offset(0, 500));
      await settle(tester);
      expect(await repo.listSuggestions(), hasLength(5));
      await tester.binding.handlePopRoute();
      await settle(tester);
      await tester.tap(find.text('امروز').last);
      await settle(tester);
      expect(pendingOnToday(tester), 5);
      expect(source.requests, 0);
      expect(await DriftFinanceRepository(db).listEntries(), isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  for (final dark in [false, true]) {
    testWidgets(
      'explicit opt-in and empty Inbox pull work in narrow RTL large text; dark=$dark',
      (tester) async {
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.binding.setSurfaceSize(const Size(320, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        addTearDown(db.close);
        final repo = DriftInboxRepository(db);
        final source = TestSmsProvider();
        addTearDown(source.events.close);
        source.add(
          1,
          DateTime.now()
              .subtract(const Duration(hours: 1))
              .millisecondsSinceEpoch,
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? PlanActTheme.dark() : PlanActTheme.light(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.8)),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: child!,
              ),
            ),
            home: Scaffold(
              body: InboxPage(
                inbox: InboxUseCases(repo),
                finance: DriftFinanceRepository(db),
                smsSource: source,
              ),
            ),
          ),
        );
        await settle(tester);
        expect(source.reads, 0);
        expect(source.subscriptions, 0);
        final initialList = find
            .descendant(
              of: find.byType(InboxPage),
              matching: find.byType(Scrollable),
            )
            .first;
        await tester.drag(initialList, const Offset(0, 500));
        await settle(tester);
        expect(source.reads, 0);
        expect(await repo.readAutomaticSmsScan(), isNull);
        final switchTile = find.byType(SwitchListTile);
        expect(tester.widget<SwitchListTile>(switchTile).value, isFalse);
        await tester.ensureVisible(switchTile);
        await settle(tester);
        await tester.tap(switchTile);
        await settle(tester);
        expect(tester.widget<SwitchListTile>(switchTile).value, isTrue);
        expect(source.subscriptions, 1);
        expect(await repo.listSuggestions(), isEmpty);

        final consent = SmsScan.decode((await repo.readAutomaticSmsScan())!);
        source.add(2, consent.from);
        final list = find
            .descendant(
              of: find.byType(InboxPage),
              matching: find.byType(Scrollable),
            )
            .first;
        // Return to the top before pulling the initially empty review list.
        tester.state<ScrollableState>(list).position.jumpTo(0);
        await tester.pump();
        await tester.drag(list, const Offset(0, 500));
        await settle(tester);
        expect(await repo.listSuggestions(), hasLength(1));
        expect(source.bounds.every((b) => b.$1 >= consent.from), isTrue);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  testWidgets(
    'revoked permission reports an error without hiding Today data or prompting',
    (tester) async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = DriftInboxRepository(db);
      final source = TestSmsProvider()..access = false;
      addTearDown(source.events.close);
      final at = DateTime.now();
      await SmsIngestion(
        InboxUseCases(repo),
        source,
        store: AutomaticSmsScanAdapter(repo),
      ).consent(from: at, until: at, newOnly: true, automatic: true);
      await tester.pumpWidget(
        PlanActApp(
          repository: DriftCommitmentRepository(db),
          smsSource: source,
        ),
      );
      await settle(tester);
      expect(
        find.text(
          'برای دریافت پیامک‌های جدید، دسترسی پیامک را در صندوق بررسی فعال کنید.',
        ),
        findsOneWidget,
      );
      expect(
        find.text('همه‌چیز مرتب است؛ موردی نیاز به توجه ندارد.'),
        findsOneWidget,
      );
      expect(source.requests, 0);
      expect(source.reads, 0);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
