import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/core/database/app_database.dart';
import 'package:planact/l10n/generated/app_localizations_fa.dart';
import 'package:planact/features/finance/data/drift_finance_repository.dart';
import 'package:planact/features/inbox/application/inbox_use_cases.dart';
import 'package:planact/features/inbox/application/sms_ingestion.dart';
import 'package:planact/features/inbox/data/drift_inbox_repository.dart';
import 'package:planact/features/inbox/presentation/inbox_page.dart';
import 'package:planact/features/inbox/presentation/sms_sync_controller.dart';

import '../fixtures/sms_provider.dart';

void main() {
  final copy = AppLocalizationsFa();
  late AppDatabase db;
  late DriftInboxRepository repo;
  late TestSmsProvider source;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DriftInboxRepository(db);
    source = TestSmsProvider();
  });
  tearDown(() async {
    await source.events.close();
    await db.close();
  });

  Future<void> show(
    WidgetTester tester, {
    bool dark = false,
    SmsSyncController? sync,
  }) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
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
            smsSync: sync,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, String text) async {
    final target = find.text(text);
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  Future<void> pull(WidgetTester tester) async {
    final list = find
        .descendant(
          of: find.byType(InboxPage),
          matching: find.byType(Scrollable),
        )
        .first;
    tester.state<ScrollableState>(list).position.jumpTo(0);
    await tester.pump();
    await tester.dragFrom(const Offset(160, 300), const Offset(0, 500));
    await tester.pumpAndSettle();
  }

  for (final dark in [false, true]) {
    testWidgets(
      '7-day auto-off setup, remount, manual button and pull; dark=$dark',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        source.add(
          1,
          DateTime.now()
              .subtract(const Duration(days: 1))
              .millisecondsSinceEpoch,
        );
        await show(tester, dark: dark);
        await tap(tester, copy.smsSetupOpen);
        expect(
          tester
              .widget<FilledButton>(
                find.widgetWithText(FilledButton, copy.smsSetupStart),
              )
              .onPressed,
          isNull,
        );
        expect(
          tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
          isFalse,
        );
        expect(
          tester
              .widgetList<ChoiceChip>(find.byType(ChoiceChip))
              .every((c) => !c.selected),
          isTrue,
        );
        await tap(tester, copy.smsScanCardDaysActions3);
        expect(
          tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
          isFalse,
        );
        await tester.ensureVisible(find.byType(SwitchListTile));
        await tester.tap(find.byType(SwitchListTile));
        await tester.pumpAndSettle();
        expect(
          tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
          isTrue,
        );
        await tap(tester, copy.smsScanCardDaysActions2);
        expect(
          tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
          isTrue,
        );
        expect(source.reads, 0);
        await tap(tester, copy.commonCancel);
        expect(await repo.readSmsScan(), isNull);
        expect(await repo.readManualSmsScan(), isNull);
        await tap(tester, copy.smsSetupOpen);
        await tap(tester, copy.smsScanCardDaysActions2);
        await tap(tester, copy.smsSetupStart);
        expect(await repo.listSuggestions(), hasLength(1));
        expect(find.text(copy.smsNewSuggestionsCount('۱')), findsOneWidget);
        final history = await repo.readSmsScan();
        expect(await repo.readAutomaticSmsScan(), isNull);
        expect(
          tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
          isFalse,
        );
        await tester.pumpWidget(const SizedBox.shrink());
        final reads = source.reads;
        source.add(2, DateTime.now().millisecondsSinceEpoch);
        await show(tester, dark: dark);
        expect(source.reads, reads);
        await tap(tester, copy.smsCheckNewMessages);
        expect(await repo.listSuggestions(), hasLength(2));
        expect(find.text(copy.smsNewSuggestionsCount('۱')), findsOneWidget);
        source.add(3, DateTime.now().millisecondsSinceEpoch);
        await pull(tester);
        expect(await repo.listSuggestions(), hasLength(3));
        expect(await repo.readSmsScan(), history);
        await tap(tester, copy.smsCheckNewMessages);
        expect(find.text(copy.smsNoNewSuggestions), findsOneWidget);
        expect(await DriftFinanceRepository(db).listEntries(), isEmpty);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  for (final legacy in [false, true]) {
    testWidgets(
      'dialog tap captures Start before dialog future: legacy=$legacy',
      (tester) async {
        var now = DateTime(2026, 11, 1, 10);
        final start = now.millisecondsSinceEpoch;
        if (legacy) {
          await repo.writeSmsScan(
            null,
            SmsScan(from: start - 1000, until: start, newOnly: false).encode(),
          );
        }
        final sync = SmsSyncController(
          inbox: InboxUseCases(repo),
          source: source,
          now: () => now,
        );
        addTearDown(sync.dispose);
        await sync.refresh(checkAccess: true);
        await show(tester, sync: sync);
        await tap(
          tester,
          legacy ? copy.smsManualActivationTitle : copy.smsSetupOpen,
        );
        if (!legacy) await tap(tester, copy.smsScanCardDaysActions);
        final button = find.widgetWithText(
          FilledButton,
          legacy ? copy.smsManualActivate : copy.smsSetupStart,
        );
        await tester.ensureVisible(button);
        await tester.pumpAndSettle();
        // Invoke the actual dialog callback, then advance time before any async continuation.
        tester.widget<FilledButton>(button).onPressed!();
        now = now.add(const Duration(minutes: 2));
        source.add(1, start + const Duration(minutes: 1).inMilliseconds);
        await tester.pumpAndSettle();
        expect(SmsScan.decode((await repo.readManualSmsScan())!).from, start);
        expect(await repo.listSuggestions(), hasLength(1));
        expect(find.text(copy.smsNewSuggestionsCount('۱')), findsOneWidget);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  testWidgets('empty setup reports zero suggestions', (tester) async {
    await show(tester);
    await tap(tester, copy.smsSetupOpen);
    await tap(tester, copy.smsScanCardDaysActions2);
    await tap(tester, copy.smsSetupStart);
    expect(find.text(copy.smsNoNewSuggestions), findsOneWidget);
    expect(await repo.listSuggestions(), isEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'enabled legacy automatic consent hides setup and preserves boundary',
    (tester) async {
      final from = DateTime.now()
          .subtract(const Duration(days: 2))
          .millisecondsSinceEpoch;
      await repo.writeAutomaticSmsScan(
        null,
        SmsScan(
          from: from,
          until: from,
          newOnly: true,
          automatic: true,
        ).encode(),
      );
      await show(tester);
      expect(find.text(copy.smsSetupOpen), findsNothing);
      expect(find.text(copy.smsManualActivationTitle), findsNothing);
      expect(
        tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
        isTrue,
      );
      await tap(tester, copy.smsCheckNewMessages);
      expect(SmsScan.decode((await repo.readAutomaticSmsScan())!).from, from);
      expect(SmsScan.decode((await repo.readManualSmsScan())!).from, from);
      expect(await repo.readSmsScan(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'range-only legacy activation is explicit; history resumes only by its action',
    (tester) async {
      final command = SmsIngestion(InboxUseCases(repo), source);
      final now = DateTime.now();
      await command.consent(
        from: now.subtract(const Duration(days: 7)),
        until: now,
        newOnly: false,
      );
      final history = await repo.readSmsScan();
      source.add(
        1,
        now.subtract(const Duration(days: 1)).millisecondsSinceEpoch,
      );
      await show(tester);
      await pull(tester);
      expect(source.reads, 0);
      await tap(tester, copy.smsManualActivationTitle);
      await tap(tester, copy.commonCancel);
      expect(await repo.readManualSmsScan(), isNull);
      await tap(tester, copy.smsManualActivationTitle);
      await tap(tester, copy.smsManualActivate);
      expect(await repo.listSuggestions(), isEmpty);
      expect(await repo.readSmsScan(), history);
      source.add(2, DateTime.now().millisecondsSinceEpoch);
      await pull(tester);
      expect(await repo.listSuggestions(), hasLength(1));
      expect(await repo.readSmsScan(), history);
      await tap(tester, copy.smsOlderMessages);
      await tap(tester, copy.smsScanCardBuildChildren9);
      expect(await repo.listSuggestions(), hasLength(2));
      expect(SmsScan.decode((await repo.readSmsScan())!).complete, isTrue);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'manual busy, error and retry, revoked permission never prompts or reads',
    (tester) async {
      await SmsIngestion(
        InboxUseCases(repo),
        source,
      ).setup(days: 0, automatic: false, now: DateTime.now());
      await show(tester);
      source.add(1, DateTime.now().millisecondsSinceEpoch);
      source.blockRead = Completer<void>();
      final button = find.widgetWithText(
        OutlinedButton,
        copy.smsCheckNewMessages,
      );
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text(copy.smsCheckingMessages), findsOneWidget);
      expect(tester.widget<OutlinedButton>(button).onPressed, isNull);
      source.failRead = source.reads;
      source.blockRead!.complete();
      await tester.pumpAndSettle();
      expect(find.text(copy.smsAutomaticSyncFailed), findsOneWidget);
      source.failRead = null;
      await tap(tester, copy.smsCheckNewMessages);
      expect(await repo.listSuggestions(), hasLength(1));
      source.access = false;
      final reads = source.reads;
      await pull(tester);
      expect(source.reads, reads);
      expect(source.requests, 0);
      expect(find.text(copy.smsAutomaticPermissionRequired), findsWidgets);
      expect(await DriftFinanceRepository(db).listEntries(), isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
