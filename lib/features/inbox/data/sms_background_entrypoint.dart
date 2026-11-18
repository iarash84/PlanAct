import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:planact/core/database/app_database.dart';
import 'package:planact/features/inbox/application/android_sms_source.dart';
import 'package:planact/features/inbox/application/inbox_use_cases.dart';
import 'package:planact/features/inbox/application/sms_detection_notifications.dart';
import 'package:planact/features/inbox/application/sms_ingestion.dart';
import 'package:planact/features/inbox/data/android_sms_detection_notifications.dart';
import 'package:planact/features/inbox/data/drift_inbox_repository.dart';
import 'package:planact/features/inbox/data/drift_sms_detection_notification_store.dart';

@pragma('vm:entry-point')
Future<void> smsBackgroundMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  await runSmsBackgroundWorker();
}

/// The close handshake is deliberately outside error recovery: a failed close
/// must never acknowledge quiescence to native restore admission.
Future<void> runSmsBackgroundWorker({
  MethodChannel worker = const MethodChannel('planact/sms-background-worker'),
  Future<AppDatabase> Function()? openDatabase,
  AndroidSmsSource? source,
  SmsDetectionNotificationPlatform? notificationPlatform,
  DateTime Function()? now,
}) async {
  AppDatabase? database;
  SmsIngestion? ingestion;
  var stopped = false;
  var retry = false;
  final clock = now ?? DateTime.now;
  final wakeAt = clock();
  final elapsed = Stopwatch()..start();
  var budget = 35000;
  bool canRun() => !stopped && elapsed.elapsedMilliseconds < budget;
  worker.setMethodCallHandler((call) async {
    if (call.method == 'stop') {
      stopped = true;
      ingestion?.cancel();
    }
  });
  try {
    final options = await worker.invokeMapMethod<String, dynamic>('ready');
    budget = ((options?['budgetMillis'] as int?) ?? 35000).clamp(0, 35000);
    final pages = ((options?['maxPages'] as int?) ?? 10).clamp(1, 10);
    stopped = stopped || options?['cancelled'] == true;
    final provider = source ?? AndroidSmsSource();
    if (!canRun() || !await provider.hasAccess()) return;
    if (openDatabase != null) {
      database = await openDatabase();
    } else {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/planact.sqlite');
      // Never create a new personal database or open an interrupted restore.
      if (!await file.exists() ||
          await File('${file.path}.restore-marker').exists()) {
        return;
      }
      database = AppDatabase(NativeDatabase(file));
    }
    final repository = DriftInboxRepository(database);
    final store = AutomaticSmsScanAdapter(repository);
    Future<bool> admitted() async {
      if (!canRun() || await worker.invokeMethod<bool>('isCancelled') == true) {
        stopped = true;
        return false;
      }
      final raw = await store.readSmsScan();
      if (raw == null) return false;
      final consent = SmsScan.decode(raw);
      return consent.automatic && consent.newOnly && await provider.hasAccess();
    }

    if (!await admitted()) return;
    final inbox = InboxUseCases(repository);
    final admittedSource = _AdmittedSmsSource(provider, admitted);
    ingestion = SmsIngestion(inbox, admittedSource, store: store);
    final notifications = SmsDetectionNotifications(
      store: DriftSmsDetectionNotificationStore(database),
      platform: notificationPlatform ?? AndroidSmsDetectionNotifications(),
      suggestions: repository.listSuggestions,
    );
    // Atomic staging owns intent. Drain it even after a previous delivery failure.
    try {
      await notifications.reconcile();
    } catch (_) {
      retry = true;
    }
    Future<void> refresh() => ingestion!.run(
      onProgress: (_) {},
      now: () => wakeAt,
      notificationNow: clock,
      maxPages: pages - admittedSource.reads,
      canRun: canRun,
      onDetected: (_) async {
        if (!canRun()) return;
        try {
          await notifications.reconcile();
        } catch (_) {
          retry = true;
        }
      },
    );
    await refresh();
    var scan = await ingestion.load();
    if (scan != null &&
        scan.complete &&
        scan.until < wakeAt.millisecondsSinceEpoch &&
        canRun() &&
        admittedSource.reads < pages) {
      await refresh();
      scan = await ingestion.load();
    }
    retry =
        retry ||
        (scan != null &&
            (!scan.complete || scan.until < wakeAt.millisecondsSinceEpoch));
    try {
      await notifications.reconcile();
    } catch (_) {
      retry = true;
    }
  } on _ScanNotAdmitted {
    retry = false;
  } catch (_) {
    // No private SMS, identifiers or financial values enter runtime logs.
    retry = !stopped;
  } finally {
    elapsed.stop();
    await database?.close();
    worker.setMethodCallHandler(null);
    await worker.invokeMethod<void>('complete', {'retry': retry && !stopped});
  }
}

class _ScanNotAdmitted implements Exception {}

class _AdmittedSmsSource extends AndroidSmsSource {
  _AdmittedSmsSource(this.delegate, this.admitted);
  final AndroidSmsSource delegate;
  final Future<bool> Function() admitted;
  int reads = 0;
  @override
  Future<bool> hasAccess() => admitted();
  @override
  Future<SmsProviderPage> readPage({
    required int from,
    required int until,
    required int afterTimestamp,
    required int afterId,
  }) async {
    if (!await admitted()) throw _ScanNotAdmitted();
    reads++;
    return delegate.readPage(
      from: from,
      until: until,
      afterTimestamp: afterTimestamp,
      afterId: afterId,
    );
  }
}
