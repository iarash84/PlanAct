import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/features/finance/data/drift_finance_repository.dart';
import 'package:planact/features/inbox/application/inbox_use_cases.dart';
import 'package:planact/features/inbox/data/drift_inbox_repository.dart';
import 'package:planact/features/inbox/presentation/inbox_page.dart';
import 'package:planact/l10n/generated/app_localizations_fa.dart';

import '../fixtures/sms_provider.dart';

class PermissionSource extends TestSmsProvider {
  Completer<bool>? response;
  bool failSettings = false;
  int settings = 0;

  @override
  Future<bool> requestAccess() async {
    requests++;
    return response == null ? access : await response!.future;
  }

  @override
  Future<void> openSettings() async {
    settings++;
    if (failSettings) throw PlatformException(code: 'settings_unavailable');
  }
}

void main() {
  final copy = AppLocalizationsFa();
  late AppDatabase db;
  late DriftInboxRepository repo;
  late PermissionSource source;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DriftInboxRepository(db);
    source = PermissionSource()..access = false;
  });
  tearDown(() async {
    await source.events.close();
    await db.close();
  });

  Future<void> show(WidgetTester tester, {bool dark = false}) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
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
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, String text) async {
    final finder = find.text(text);
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> request(WidgetTester tester) async {
    await tap(tester, copy.inboxPageBuildTrailing);
    await tap(tester, copy.planactAppShowCommitmentDetailsTitle3);
  }

  for (final dark in [false, true]) {
    testWidgets(
      'denial immediately exposes optional recovery; settings return rechecks without import; dark=$dark',
      (tester) async {
        await show(tester, dark: dark);
        expect(source.requests, 0);
        await request(tester);
        expect(source.requests, 1);
        expect(source.settings, 0);
        expect(find.text(copy.smsPermissionNotGranted), findsOneWidget);
        expect(find.text(copy.smsPermissionHelpBody), findsOneWidget);
        expect(find.text(copy.inboxPageBuildTrailing), findsOneWidget);

        await tap(tester, copy.smsPermissionOpenSettings);
        expect(source.settings, 1);
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pumpAndSettle();
        expect(find.text(copy.smsPermissionHelpBody), findsOneWidget);
        expect(source.requests, 1);

        source.access = true;
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pumpAndSettle();
        expect(find.text(copy.smsPermissionHelpTitle), findsNothing);
        expect(find.text(copy.inboxPageBuildSubtitle4), findsOneWidget);
        expect(source.reads, 0);
        expect(await repo.readSmsScan(), isNull);
        expect(await repo.readAutomaticSmsScan(), isNull);
        expect(await repo.listSuggestions(), isEmpty);
        expect(await DriftFinanceRepository(db).listEntries(), isEmpty);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  testWidgets(
    'cancel never requests; settings failure is retryable; retry accepts ordinary grant',
    (tester) async {
      await show(tester);
      await tap(tester, copy.inboxPageBuildTrailing);
      await tap(tester, copy.inboxPageConsentActions);
      expect(source.requests, 0);
      await tap(tester, copy.smsPermissionHelpTitle);
      source.failSettings = true;
      await tap(tester, copy.smsPermissionOpenSettings);
      expect(find.text(copy.smsPermissionSettingsFailed), findsOneWidget);
      source.failSettings = false;
      await tap(tester, copy.smsPermissionOpenSettings);
      expect(source.settings, 2);

      source.response = Completer<bool>();
      await request(tester);
      expect(source.requests, 1);
      expect(find.text(copy.inboxPageBuildSubtitle4), findsNothing);
      // A system dialog lifecycle transition must not block later access refresh.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      source.access = true;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      source.response!.complete(true);
      await tester.pumpAndSettle();
      expect(find.text(copy.inboxPageBuildSubtitle4), findsOneWidget);
      expect(source.reads, 0);
      expect(await repo.readAutomaticSmsScan(), isNull);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'missing native response has bounded recovery and later resume works',
    (tester) async {
      source.response = Completer<bool>();
      await show(tester);
      await request(tester);
      await tester.pump(const Duration(seconds: 51));
      await tester.pumpAndSettle();
      expect(find.text(copy.smsPermissionRequestFailed), findsOneWidget);
      expect(find.text(copy.smsPermissionHelpBody), findsOneWidget);
      source.access = true;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.text(copy.inboxPageBuildSubtitle4), findsOneWidget);
      expect(source.requests, 1);
      expect(source.reads, 0);
      source.response!.complete(true);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
