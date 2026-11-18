import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/features/inbox/application/android_sms_source.dart';
import 'package:planact/features/inbox/application/sms_ingestion.dart';
import 'package:planact/features/inbox/application/sms_detection_notifications.dart';
import 'package:planact/features/inbox/data/drift_sms_detection_notification_store.dart';
import 'package:planact/features/inbox/domain/inbox.dart';

import '../fixtures/real_bank_sms.dart';

import 'package:planact/features/inbox/data/drift_inbox_repository.dart';
import 'package:planact/features/inbox/data/sms_background_entrypoint.dart';
import 'package:planact/features/inbox/data/sms_background_runtime.dart';

class _Source extends AndroidSmsSource {
  bool access = true;
  int reads = 0;
  Completer<void>? pause;
  @override
  Future<bool> hasAccess() async => access;
  @override
  Future<SmsProviderPage> readPage({
    required int from,
    required int until,
    required int afterTimestamp,
    required int afterId,
  }) async {
    reads++;
    await pause?.future;
    return SmsProviderPage([
      for (var i = 1; i <= 100; i++)
        SmsProviderRow(from, afterId + i + 1, null),
    ]);
  }
}

class _OneMessage extends AndroidSmsSource {
  @override
  Future<bool> hasAccess() async => true;
  @override
  Future<SmsProviderPage> readPage({
    required int from,
    required int until,
    required int afterTimestamp,
    required int afterId,
  }) async => SmsProviderPage([
    SmsProviderRow(
      from,
      1,
      AndroidSmsMessage(
        sourceKey: 'sms:background:1',
        body: realBankSms.first,
        receivedAt: DateTime.fromMillisecondsSinceEpoch(from),
      ),
    ),
  ]);
}

class _TwoMessages extends _OneMessage {
  @override
  Future<SmsProviderPage> readPage({
    required int from,
    required int until,
    required int afterTimestamp,
    required int afterId,
  }) async => SmsProviderPage([
    for (var id = 1; id <= 2; id++)
      SmsProviderRow(
        from,
        id,
        AndroidSmsMessage(
          sourceKey: 'sms:timed:$id',
          body: realBankSms.first,
          receivedAt: DateTime.fromMillisecondsSinceEpoch(from),
        ),
      ),
  ]);
}

class _HorizonSource extends AndroidSmsSource {
  final horizons = <int>[];
  @override
  Future<bool> hasAccess() async => true;
  @override
  Future<SmsProviderPage> readPage({
    required int from,
    required int until,
    required int afterTimestamp,
    required int afterId,
  }) async {
    horizons.add(until);
    return SmsProviderPage(
      until < 3000
          ? []
          : [
              SmsProviderRow(
                3000,
                1,
                AndroidSmsMessage(
                  sourceKey: 'sms:catchup:1',
                  body: realBankSms.first,
                  receivedAt: DateTime.fromMillisecondsSinceEpoch(3000),
                ),
              ),
            ],
    );
  }
}

class _Notifications implements SmsDetectionNotificationPlatform {
  int shown = 0;
  @override
  Future<bool> permitted() async => true;
  @override
  Future<void> cancel() async {}
  @override
  Future<void> show(
    List<InboxSuggestion> pending, {
    required bool showAmounts,
  }) async {
    expect(showAmounts, false);
    shown++;
  }
}

class _Database extends AppDatabase {
  _Database() : super(NativeDatabase.memory());
  bool closed = false;
  @override
  Future<void> close() async {
    await super.close();
    closed = true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('test/sms-runtime');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test(
    'foreground denial never runs or releases; errors release after work',
    () async {
      final calls = <String>[];
      var admit = false;
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call.method);
        return call.method == 'acquire' ? admit : null;
      });
      const runtime = SmsBackgroundRuntime(
        channel: channel,
        supportedOverride: true,
      );
      await expectLater(
        runtime.withForegroundLease(() async => calls.add('work')),
        throwsStateError,
      );
      expect(calls, ['acquire']);
      admit = true;
      await expectLater(
        runtime.withForegroundLease(() async {
          calls.add('work');
          throw StateError('failed');
        }),
        throwsStateError,
      );
      expect(calls, ['acquire', 'acquire', 'work', 'release']);
    },
  );

  test('non-Android fallback requires no plugin', () async {
    const runtime = SmsBackgroundRuntime(
      channel: channel,
      supportedOverride: false,
    );
    await runtime.configure('unused');
    await runtime.suspend();
    await runtime.resume();
    expect(await runtime.withForegroundLease(() async => 7), 7);
  });

  Future<_Database> prepared({bool automatic = true}) async {
    final db = _Database();
    await DriftInboxRepository(db).writeAutomaticSmsScan(
      null,
      SmsScan(
        from: 1000,
        until: 2000,
        newOnly: true,
        automatic: automatic,
      ).encode(),
    );
    return db;
  }

  test('headless caps pages at ten and completes only after close', () async {
    final db = await prepared();
    final source = _Source();
    bool? retry;
    messenger.setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'ready':
          return {'maxPages': 99, 'budgetMillis': 35000};
        case 'isCancelled':
          return false;
        case 'complete':
          expect(db.closed, true);
          retry = (call.arguments as Map)['retry'] as bool;
      }
      return null;
    });
    await runSmsBackgroundWorker(
      worker: channel,
      openDatabase: () async => db,
      source: source,
    );
    expect(source.reads, 10);
    expect(retry, true);
  });

  for (final pages in [1, 2]) {
    test(
      'old completed horizon catches up or requests retry, pages=$pages',
      () async {
        final directory = await Directory.systemTemp.createTemp('sms-catchup-');
        final file = File('${directory.path}/state.sqlite');
        final db = AppDatabase(NativeDatabase(file));
        await DriftInboxRepository(db).writeAutomaticSmsScan(
          null,
          SmsScan(
            from: 1000,
            until: 2000,
            newOnly: true,
            automatic: true,
          ).encode(),
        );
        final source = _HorizonSource();
        bool? retry;
        messenger.setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'ready') return {'maxPages': pages};
          if (call.method == 'isCancelled') return false;
          if (call.method == 'complete') {
            retry = (call.arguments as Map)['retry'] as bool;
          }
          return null;
        });
        await runSmsBackgroundWorker(
          worker: channel,
          openDatabase: () async => db,
          source: source,
          notificationPlatform: _Notifications(),
          now: () => DateTime.fromMillisecondsSinceEpoch(4000),
        );
        final reopened = AppDatabase(NativeDatabase(file));
        try {
          final repository = DriftInboxRepository(reopened);
          final scan = SmsScan.decode(
            (await repository.readAutomaticSmsScan())!,
          );
          expect(source.horizons, pages == 1 ? [2000] : [2000, 4000]);
          expect(retry, pages == 1);
          expect(scan.complete, isTrue);
          expect(scan.until, pages == 1 ? 2000 : 4000);
          expect(
            await repository.listSuggestions(),
            hasLength(pages == 1 ? 0 : 1),
          );
        } finally {
          await reopened.close();
          await directory.delete(recursive: true);
        }
      },
    );
  }

  test(
    'headless detection clock advances independently of fixed scan horizon',
    () async {
      final directory = await Directory.systemTemp.createTemp('sms-timed-');
      final file = File('${directory.path}/planact.sqlite');
      final db = AppDatabase(NativeDatabase(file));
      final repository = DriftInboxRepository(db);
      await repository.writeAutomaticSmsScan(
        null,
        SmsScan(
          from: 1000,
          until: 2000,
          newOnly: true,
          automatic: true,
        ).encode(),
      );
      await DriftSmsDetectionNotificationStore(db).compareAndWrite(
        null,
        const SmsDetectionNotificationState(enabled: true).encode(),
      );
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'ready') return <String, dynamic>{};
        if (call.method == 'isCancelled') return false;
        return null;
      });
      var tick = 0;
      await runSmsBackgroundWorker(
        worker: channel,
        openDatabase: () async => db,
        source: _TwoMessages(),
        notificationPlatform: _Notifications(),
        now: () => DateTime.fromMillisecondsSinceEpoch(2000 + 30000 * tick++),
      );
      final reopened = AppDatabase(NativeDatabase(file));
      try {
        final state = SmsDetectionNotificationState.decode(
          await DriftSmsDetectionNotificationStore(reopened).read(),
        );
        expect(state.eligible, hasLength(2));
        expect(state.members, hasLength(1));
        expect(state.startedAt, 62000);
        expect(state.delivered, containsAll(state.eligible));
        final scan = SmsScan.decode(
          (await DriftInboxRepository(reopened).readAutomaticSmsScan())!,
        );
        expect(scan.until, 2000);
      } finally {
        await reopened.close();
        await directory.delete(recursive: true);
      }
    },
  );

  test('disabled durable automatic consent never reads provider', () async {
    final db = await prepared(automatic: false);
    final source = _Source();
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'ready') return <String, dynamic>{};
      if (call.method == 'isCancelled') return false;
      if (call.method == 'complete') expect(db.closed, true);
      return null;
    });
    await runSmsBackgroundWorker(
      worker: channel,
      openDatabase: () async => db,
      source: source,
    );
    expect(source.reads, 0);
    expect(db.closed, true);
  });

  test('native cancellation is rechecked before every provider page', () async {
    final db = await prepared();
    final source = _Source();
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'ready') return <String, dynamic>{};
      if (call.method == 'isCancelled') return source.reads > 0;
      if (call.method == 'complete') {
        expect(db.closed, true);
        expect((call.arguments as Map)['retry'], false);
      }
      return null;
    });
    await runSmsBackgroundWorker(
      worker: channel,
      openDatabase: () async => db,
      source: source,
    );
    expect(source.reads, 1);
  });

  test('same parser stages durable suggestion and drains atomic outbox before close', () async {
    final directory = await Directory.systemTemp.createTemp('sms-headless-');
    final file = File('${directory.path}/planact.sqlite');
    final db = AppDatabase(NativeDatabase(file));
    final repository = DriftInboxRepository(db);
    await repository.writeAutomaticSmsScan(
      null,
      SmsScan(from: 1000, until: 2000, newOnly: true, automatic: true).encode(),
    );
    await DriftSmsDetectionNotificationStore(db).compareAndWrite(
      null,
      const SmsDetectionNotificationState(enabled: true).encode(),
    );
    final platform = _Notifications();
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'ready') return <String, dynamic>{};
      if (call.method == 'isCancelled') return false;
      if (call.method == 'complete') {
        expect((call.arguments as Map)['retry'], false);
      }
      return null;
    });
    await runSmsBackgroundWorker(
      worker: channel,
      source: _OneMessage(),
      openDatabase: () async => db,
      notificationPlatform: platform,
    );
    final reopened = AppDatabase(NativeDatabase(file));
    try {
      final suggestions = await DriftInboxRepository(reopened)
          .listSuggestions();
      expect(suggestions, hasLength(1));
      expect(suggestions.single.status, SuggestionStatus.pending);
      final state = SmsDetectionNotificationState.decode(
        await DriftSmsDetectionNotificationStore(reopened).read(),
      );
      expect(state.delivered, contains(suggestions.single.id.value));
      expect(platform.shown, 1);
    } finally {
      await reopened.close();
      await directory.delete(recursive: true);
    }
  });

  test(
    'stop callback waits for in-flight provider and database close',
    () async {
      final db = await prepared();
      final source = _Source()..pause = Completer<void>();
      var completed = false;
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'ready') return <String, dynamic>{};
        if (call.method == 'isCancelled') return false;
        if (call.method == 'complete') {
          expect(db.closed, true);
          expect((call.arguments as Map)['retry'], false);
          completed = true;
        }
        return null;
      });
      final running = runSmsBackgroundWorker(
        worker: channel,
        source: source,
        openDatabase: () async => db,
      );
      while (source.reads == 0) {
        await Future<void>.delayed(Duration.zero);
      }
      await messenger.handlePlatformMessage(
        channel.name,
        const StandardMethodCodec().encodeMethodCall(const MethodCall('stop')),
        (_) {},
      );
      expect(completed, false);
      expect(db.closed, false);
      source.pause!.complete();
      await running;
      expect(completed, true);
    },
  );

  test('revoked permission never opens personal database', () async {
    var opened = false;
    messenger.setMockMethodCallHandler(
      channel,
      (call) async => call.method == 'ready' ? <String, dynamic>{} : null,
    );
    await runSmsBackgroundWorker(
      worker: channel,
      source: _Source()..access = false,
      openDatabase: () async {
        opened = true;
        return _Database();
      },
    );
    expect(opened, false);
  });
}
