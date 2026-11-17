import 'dart:io';

import 'package:drift/native.dart';
import 'package:planact/features/backup/data/sqlite_backup_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/features/finance/data/drift_finance_repository.dart';
import 'package:planact/features/inbox/application/inbox_use_cases.dart';
import 'package:planact/features/inbox/application/sms_detection_notifications.dart';
import 'package:planact/features/inbox/data/drift_inbox_repository.dart';
import 'package:planact/features/inbox/data/drift_sms_detection_notification_store.dart';
import 'package:planact/features/inbox/domain/inbox.dart';

class Platform implements SmsDetectionNotificationPlatform {
  bool allowed = true;
  bool fail = false;
  int cancelled = 0;
  final deliveries = <List<InboxSuggestion>>[];
  final amountChoices = <bool>[];
  @override
  Future<bool> permitted() async => allowed;
  @override
  Future<void> cancel() async {
    cancelled++;
  }

  @override
  Future<void> show(
    List<InboxSuggestion> pending, {
    required bool showAmounts,
  }) async {
    if (fail) throw StateError('OS unavailable');
    deliveries.add(pending);
    amountChoices.add(showAmounts);
  }
}

void main() {
  test(
    'disabled backlog stays silent after opt-in and fresh detection',
    () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      final inbox = InboxUseCases(DriftInboxRepository(database));
      final platform = Platform();
      final notifications = SmsDetectionNotifications(
        store: DriftSmsDetectionNotificationStore(database),
        platform: platform,
        suggestions: inbox.repository.listSuggestions,
      );
      Future<InboxSuggestion> stage(String key) => inbox.stageSms(
        rawText: 'برداشت مبلغ ۲۵۰۰',
        sourceKey: key,
        currency: 'IRR',
        importedAt: DateTime.utc(2026),
      );
      await notifications.detected(await stage('android-sms:old'));
      await notifications.reconcile();
      expect(platform.deliveries, isEmpty);
      await notifications.configure(enabled: true, showAmounts: false);
      expect(platform.deliveries, isEmpty);
      final fresh = await stage('android-sms:fresh');
      await notifications.detected(fresh);
      await notifications.reconcile();
      expect(platform.deliveries.single.single.id, fresh.id);
    },
  );
  test(
    'durable aggregation replay stale tap and resolution never write finances',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'sms-notifications-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/state.sqlite');
      var database = AppDatabase.forTesting(NativeDatabase(file));
      var inbox = InboxUseCases(DriftInboxRepository(database));
      final platform = Platform();
      SmsDetectionNotifications owner() => SmsDetectionNotifications(
        store: DriftSmsDetectionNotificationStore(database),
        platform: platform,
        suggestions: inbox.repository.listSuggestions,
      );
      var notifications = owner();
      await notifications.configure(enabled: true, showAmounts: false);
      final first = await inbox.stageSms(
        rawText: 'برداشت مبلغ ۲۵۰۰',
        sourceKey: 'android-sms:42',
        currency: 'IRR',
        importedAt: DateTime.utc(2026, 11, 16),
      );
      final second = await inbox.stageSms(
        rawText: 'برداشت مبلغ ۲۵۰۰',
        sourceKey: 'android-sms:43',
        currency: 'IRR',
        importedAt: DateTime.utc(2026, 11, 16),
      );
      await Future.wait([
        notifications.detected(first),
        notifications.detected(second),
      ]);
      await notifications.reconcile();
      expect(platform.deliveries.single, hasLength(2));
      final expected = await notifications.store.read();
      final bytes = await sqliteBackupSnapshot(
        database: database,
        target: File('${directory.path}/snapshot.sqlite'),
        redact: true,
      );
      final restoredFile = File('${directory.path}/restored.sqlite');
      await restoredFile.writeAsBytes(bytes);
      final restored = AppDatabase.forTesting(NativeDatabase(restoredFile));
      expect(
        await DriftSmsDetectionNotificationStore(restored).read(),
        expected,
      );
      expect(
        await DriftInboxRepository(restored).listSuggestions(),
        hasLength(2),
      );
      await restored.close();
      await database.close();
      database = AppDatabase.forTesting(NativeDatabase(file));
      addTearDown(() => database.close());
      inbox = InboxUseCases(DriftInboxRepository(database));
      notifications = owner();
      await notifications.detected(first);
      await notifications.reconcile();
      expect(platform.deliveries, hasLength(1));
      await notifications.configure(enabled: true, showAmounts: true);
      expect(platform.amountChoices.last, isTrue);
      expect((await notifications.resolveTap(first.id.value))?.id, first.id);
      await inbox.reject(first);
      expect(await notifications.resolveTap(first.id.value), isNull);
      await notifications.reconcile();
      expect(platform.deliveries.last.single.id, second.id);
      await inbox.reject(second);
      await notifications.reconcile();
      expect(platform.cancelled, greaterThan(0));
      expect(await DriftFinanceRepository(database).listEntries(), isEmpty);
    },
  );

  test(
    'denied delivery and OS failure retain retryable durable intent',
    () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      final inbox = InboxUseCases(DriftInboxRepository(database));
      final platform = Platform();
      final notifications = SmsDetectionNotifications(
        store: DriftSmsDetectionNotificationStore(database),
        platform: platform,
        suggestions: inbox.repository.listSuggestions,
      );
      await notifications.configure(enabled: true, showAmounts: false);
      final item = await inbox.stageSms(
        rawText: 'برداشت مبلغ ۲۵۰۰',
        sourceKey: 'android-sms:1',
        currency: 'IRR',
        importedAt: DateTime.utc(2026),
      );
      await notifications.detected(item);
      platform.allowed = false;
      await notifications.reconcile();
      expect(platform.deliveries, isEmpty);
      platform.allowed = true;
      platform.fail = true;
      await expectLater(notifications.reconcile(), throwsStateError);
      platform.fail = false;
      await notifications.reconcile();
      expect(platform.deliveries.single.single.id, item.id);
    },
  );
}
