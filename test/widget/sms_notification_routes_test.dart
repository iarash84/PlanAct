import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/app_lock.dart';
import 'package:planact/app/planact_app.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/features/commitments/data/drift_commitment_repository.dart';
import 'package:planact/features/inbox/application/inbox_use_cases.dart';
import 'package:planact/features/inbox/application/sms_detection_notifications.dart';
import 'package:planact/features/inbox/data/android_sms_detection_notifications.dart';
import 'package:planact/features/inbox/data/drift_inbox_repository.dart';
import 'package:planact/features/inbox/data/drift_sms_detection_notification_store.dart';
import 'package:planact/features/inbox/presentation/inbox_page.dart';
import 'package:planact/features/inbox/presentation/sms_notification_settings.dart';

import '../fixtures/sms_provider.dart';

class _Authenticator implements AppAuthenticator {
  final request = Completer<bool>();
  @override
  Future<bool> isAvailable() async => true;
  @override
  Future<bool> authenticate() => request.future;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const channel = AndroidSmsDetectionNotifications.channel;
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  for (final dark in [false, true]) {
    testWidgets(
      'notification settings narrow large text commits generic preference ($dark)',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 740));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        addTearDown(db.close);
        var permission = false;
        messenger.setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'requestPermission') return permission;
          return null;
        });
        final store = DriftSmsDetectionNotificationStore(db);
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? PlanActTheme.dark() : PlanActTheme.light(),
            home: MediaQuery(
              data: const MediaQueryData(
                size: Size(320, 740),
                textScaler: TextScaler.linear(2),
              ),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Scaffold(
                  body: SingleChildScrollView(
                    child: SmsNotificationSettings(
                      notifications: SmsDetectionNotifications(
                        store: store,
                        platform: AndroidSmsDetectionNotifications(),
                        suggestions: () async => [],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final toggle = find.byType(SwitchListTile);
        expect(tester.widget<SwitchListTile>(toggle).value, false);
        await tester.tap(toggle);
        await tester.pumpAndSettle();
        expect(tester.widget<SwitchListTile>(toggle).value, false);
        expect(
          SmsDetectionNotificationState.decode(await store.read()).enabled,
          false,
        );
        expect(find.byIcon(Icons.refresh), findsOneWidget);
        permission = true;
        await tester.tap(toggle);
        await tester.pumpAndSettle();
        expect(tester.widget<SwitchListTile>(toggle).value, true);
        final saved = SmsDetectionNotificationState.decode(await store.read());
        expect(saved.enabled, true);
        expect(saved.showAmounts, false);
        expect(find.byIcon(Icons.refresh), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final stale in [false, true]) {
    testWidgets(
      'root notification waits for app lock and rereads ${stale ? 'stale' : 'pending'} target',
      (tester) async {
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        addTearDown(db.close);
        final inbox = InboxUseCases(DriftInboxRepository(db));
        final suggestion = await inbox.stageSms(
          rawText: 'برداشت مبلغ 1000',
          sourceKey: 'notification:route',
          currency: 'IRR',
        );
        String? target = suggestion.id.value;
        var takes = 0;
        messenger.setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'takeTap') {
            takes++;
            final result = target;
            target = null;
            return result;
          }
          if (call.method == 'permitted') return false;
          return null;
        });
        final auth = _Authenticator();
        final lock = AppLockController(authenticator: auth);
        addTearDown(lock.dispose);
        final source = TestSmsProvider();
        addTearDown(source.events.close);
        await tester.pumpWidget(
          MaterialApp(
            theme: PlanActTheme.light(),
            builder: (_, child) => Directionality(
              textDirection: TextDirection.rtl,
              child: AppLockGate(
                enabled: true,
                controller: lock,
                child: child!,
              ),
            ),
            home: HomeShell(
              repository: DriftCommitmentRepository(db),
              appLockEnabled: true,
              appLockController: lock,
              smsSource: source,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(lock.isLocked, true);
        expect(takes, 1);
        expect(find.byType(InboxPage, skipOffstage: false), findsNothing);
        if (stale) await inbox.reject(suggestion);
        auth.request.complete(true);
        await tester.pumpAndSettle();
        expect(lock.isLocked, false);
        final page = tester.widget<InboxPage>(find.byType(InboxPage));
        expect(page.pendingOnly, true);
        expect(page.initialReviewId, stale ? isNull : suggestion.id);
        final durable = await inbox.repository.listSuggestions();
        expect(durable.single.status.name, stale ? 'rejected' : 'pending');
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      },
    );
  }
}
