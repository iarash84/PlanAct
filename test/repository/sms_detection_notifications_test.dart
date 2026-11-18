import 'dart:io';
import 'dart:async';

import 'package:planact/core/application/command_gate.dart';

import 'package:drift/native.dart';
import 'package:planact/features/backup/data/sqlite_backup_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/features/inbox/application/inbox_use_cases.dart';
import 'package:planact/features/inbox/application/android_sms_source.dart';
import 'package:planact/features/inbox/application/sms_ingestion.dart';
import 'package:planact/features/inbox/application/sms_detection_notifications.dart';
import 'package:planact/features/inbox/data/drift_inbox_repository.dart';
import 'package:planact/features/inbox/data/drift_sms_detection_notification_store.dart';
import 'package:planact/features/inbox/domain/inbox.dart';

class Platform
    implements
        SmsDetectionNotificationPlatform,
        SmsDetectionNotificationBatchPlatform {
  bool allowed = true, fail = false, reject = false;
  int cancelled = 0;
  Completer<void>? showStarted, finishShow;
  final dismissedIds = <String>{};
  final calls = <({String id, bool silent})>[];
  @override
  Future<bool> permitted() async => allowed;
  @override
  Future<void> cancel() async {
    cancelled++;
  }

  @override
  Future<bool> dismissed({required String batchId}) async =>
      dismissedIds.contains(batchId);
  @override
  Future<void> dismiss({required String batchId}) async {
    dismissedIds.add(batchId);
  }

  @override
  Future<bool> showBatch({
    required String batchId,
    required bool silent,
  }) async {
    calls.add((id: batchId, silent: silent));
    showStarted?.complete();
    await finishShow?.future;
    if (fail) throw StateError('OS unavailable');
    return !reject;
  }

  @override
  Future<void> show(
    List<InboxSuggestion> pending, {
    required bool showAmounts,
  }) async {
    throw StateError('Production must use batch interface');
  }
}

class Source extends AndroidSmsSource {
  Source(this.rows);
  final List<SmsProviderRow> rows;
  int reads = 0;
  @override
  Future<bool> hasAccess() async => true;
  @override
  Future<SmsProviderPage> readPage({
    required int from,
    required int until,
    required int afterTimestamp,
    required int afterId,
  }) async {
    reads++;
    return SmsProviderPage(
      rows
          .where(
            (row) =>
                row.timestamp >= from &&
                row.timestamp <= until &&
                (row.timestamp > afterTimestamp ||
                    row.timestamp == afterTimestamp && row.id > afterId),
          )
          .take(100)
          .toList(),
    );
  }
}

void main() {
  late AppDatabase db;
  late InboxUseCases inbox;
  late Platform platform;
  late SmsDetectionNotifications notifications;
  final start = DateTime.utc(2026, 11, 18);
  void bind() {
    inbox = InboxUseCases(DriftInboxRepository(db));
    notifications = SmsDetectionNotifications(
      store: DriftSmsDetectionNotificationStore(db),
      platform: platform,
      suggestions: inbox.repository.listSuggestions,
    );
  }

  Future<InboxSuggestion> stage(
    int id, {
    int milliseconds = 0,
    bool historical = false,
  }) => inbox.stageSms(
    rawText: 'برداشت مبلغ 1000',
    sourceKey: 'android-sms:$id',
    currency: 'IRR',
    importedAt: start,
    notificationDetectedAt: historical
        ? null
        : start.add(Duration(milliseconds: milliseconds)),
  );
  Future<SmsDetectionNotificationState> state() async =>
      SmsDetectionNotificationState.decode(
        await DriftSmsDetectionNotificationStore(db).read(),
      );
  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    platform = Platform();
    bind();
  });
  tearDown(() => db.close());

  test(
    'first immediate, fixed non-sliding boundary, old pending irrelevant',
    () async {
      await notifications.configure(enabled: true);
      final first = await stage(1);
      await notifications.reconcile();
      expect(platform.calls, [(id: first.id.value, silent: false)]);
      await stage(2, milliseconds: 29999);
      await notifications.reconcile();
      expect(platform.calls.last, (id: first.id.value, silent: true));
      expect((await state()).startedAt, start.millisecondsSinceEpoch);
      final next = await stage(3, milliseconds: 30000);
      await notifications.reconcile();
      expect(platform.calls.last, (id: next.id.value, silent: false));
      expect((await state()).members, {next.id.value});
      final before = await DriftSmsDetectionNotificationStore(db).read();
      await stage(1, milliseconds: 90000);
      expect(await DriftSmsDetectionNotificationStore(db).read(), before);
    },
  );

  test('historical replay and disabled period never flood on enable', () async {
    final historical = await stage(1, historical: true);
    await stage(2);
    await notifications.configure(enabled: true, showAmounts: true);
    await stage(1, milliseconds: 40000);
    await notifications.detected(historical);
    await notifications.reconcile();
    expect(platform.calls, isEmpty);
    expect((await state()).showAmounts, isFalse);
    await stage(3, milliseconds: 50000);
    await notifications.reconcile();
    expect(platform.calls, hasLength(1));
  });

  test(
    'permission retry, ambiguous submission retries silently, resolution quiet',
    () async {
      await notifications.configure(enabled: true);
      final first = await stage(1);
      platform.allowed = false;
      await notifications.reconcile();
      expect((await state()).attempted, isFalse);
      platform.allowed = true;
      platform.fail = true;
      await expectLater(notifications.reconcile(), throwsStateError);
      platform.fail = false;
      await notifications.reconcile();
      expect(platform.calls.map((c) => c.silent), [false, true]);
      final second = await stage(2, milliseconds: 1);
      await notifications.reconcile();
      await inbox.reject(first);
      await notifications.reconcile();
      expect(platform.calls.last.silent, isTrue);
      await inbox.reject(second);
      await notifications.reconcile();
      expect(platform.cancelled, greaterThan(0));
      expect(await notifications.resolveTap(first.id.value), isNull);
      await stage(3, milliseconds: 2);
      await notifications.reconcile();
      expect(platform.calls.last.silent, isTrue);
      expect((await state()).isDismissed, isFalse);
    },
  );

  test('native swipe and false show suppress same batch, boundary allows new alert', () async {
    await notifications.configure(enabled: true);
    final first = await stage(1);
    await notifications.reconcile();
    platform.dismissedIds.add(first.id.value);
    await stage(2, milliseconds: 20000);
    await notifications.reconcile();
    expect(platform.calls, hasLength(1));
    platform.reject = true;
    await stage(3, milliseconds: 30000);
    await notifications.reconcile();
    await notifications.reconcile();
    expect(platform.calls, hasLength(2));
    expect((await state()).isDismissed, isTrue);
  });

  for (final attempted in [false, true]) {
    test(
      'cross-window outbox retains older intent, attempted=$attempted',
      () async {
        await notifications.configure(enabled: true);
        final first = await stage(1);
        if (attempted) {
          platform.fail = true;
          await expectLater(notifications.reconcile(), throwsStateError);
          platform.fail = false;
        } else {
          platform.allowed = false;
          await notifications.reconcile();
        }
        final joined = await stage(2, milliseconds: 29999);
        final second = await stage(3, milliseconds: 30000);
        final third = await stage(4, milliseconds: 60000);
        final saved = await state();
        expect(saved.backlog.map((batch) => batch.id), [
          first.id.value,
          second.id.value,
        ]);
        expect(saved.backlog.first.members, {first.id.value, joined.id.value});
        expect(saved.backlog.first.attempted, attempted);
        expect(
          SmsDetectionNotificationState.decode(saved.encode()).backlog,
          hasLength(2),
        );
        platform.allowed = true;
        bind();
        await notifications.reconcile();
        expect(platform.calls.skip(attempted ? 1 : 0).toList(), [
          (id: first.id.value, silent: attempted),
          (id: second.id.value, silent: false),
          (id: third.id.value, silent: false),
        ]);
        expect((await state()).backlog, isEmpty);
        expect(
          (await state()).delivered,
          containsAll([
            first.id.value,
            joined.id.value,
            second.id.value,
            third.id.value,
          ]),
        );
        final count = platform.calls.length;
        await notifications.reconcile();
        expect(platform.calls, hasLength(count));
      },
    );
  }

  test(
    'superseded ambiguous retry stays durable until success or suppression',
    () async {
      await notifications.configure(enabled: true);
      final first = await stage(1);
      final next = await stage(2, milliseconds: 30000);
      platform.fail = true;
      await expectLater(notifications.reconcile(), throwsStateError);
      expect((await state()).backlog.single.attempted, isTrue);
      await expectLater(notifications.reconcile(), throwsStateError);
      expect(platform.calls, [
        (id: first.id.value, silent: false),
        (id: first.id.value, silent: true),
      ]);
      platform.fail = false;
      platform.dismissedIds.add(first.id.value);
      await notifications.reconcile();
      expect(platform.calls.last, (id: next.id.value, silent: false));
      expect((await state()).backlog, isEmpty);
      expect((await state()).delivered, contains(first.id.value));
    },
  );

  test(
    'retirement drains notification submission and final metadata write',
    () async {
      final gate = CommandGate();
      CommandGate.bind(db, gate);
      await notifications.configure(enabled: true);
      final first = await stage(1);
      platform.showStarted = Completer<void>();
      platform.finishShow = Completer<void>();
      final delivering = notifications.reconcile();
      await platform.showStarted!.future;
      var drained = false;
      final retiring = gate.retire().then((_) => drained = true);
      await Future<void>.delayed(Duration.zero);
      expect(drained, false);
      await expectLater(
        notifications.reconcile(),
        throwsA(isA<StaleApplicationCommand>()),
      );
      platform.finishShow!.complete();
      await delivering;
      await retiring;
      expect(drained, true);
      final persisted = SmsDetectionNotificationState.decode(
        await db.readMetadata(DriftSmsDetectionNotificationStore.metadataKey),
      );
      expect(persisted.delivered, contains(first.id.value));
    },
  );

  test('disable explicitly suppresses all retained batches', () async {
    await notifications.configure(enabled: true);
    await stage(1);
    await stage(2, milliseconds: 30000);
    await notifications.configure(enabled: false);
    expect((await state()).backlog, isEmpty);
    await notifications.configure(enabled: true);
    expect(platform.calls, isEmpty);
  });

  test(
    'multiple undelivered windows survive cold reopen with retry reservations',
    () async {
      await db.close();
      final directory = await Directory.systemTemp.createTemp(
        'sms-outbox-reopen-',
      );
      final file = File('${directory.path}/state.sqlite');
      addTearDown(() async {
        await db.close();
        db = AppDatabase.forTesting(NativeDatabase.memory());
        await directory.delete(recursive: true);
      });
      db = AppDatabase.forTesting(NativeDatabase(file));
      bind();
      await notifications.configure(enabled: true);
      final first = await stage(1);
      platform.fail = true;
      await expectLater(notifications.reconcile(), throwsStateError);
      final second = await stage(2, milliseconds: 30000);
      final third = await stage(3, milliseconds: 60000);
      await db.close();
      db = AppDatabase.forTesting(NativeDatabase(file));
      bind();
      expect((await state()).backlog, hasLength(2));
      platform.fail = false;
      await notifications.reconcile();
      expect(platform.calls, [
        (id: first.id.value, silent: false),
        (id: first.id.value, silent: true),
        (id: second.id.value, silent: false),
        (id: third.id.value, silent: false),
      ]);
      expect((await state()).backlog, isEmpty);
    },
  );

  test('outbox cold reopen, CAS stale writer and staging rollback', () async {
    await db.close();
    final directory = await Directory.systemTemp.createTemp('sms-batch-');
    addTearDown(() async {
      await db.close();
      db = AppDatabase.forTesting(NativeDatabase.memory());
      await directory.delete(recursive: true);
    });
    final file = File('${directory.path}/state.sqlite');
    db = AppDatabase.forTesting(NativeDatabase(file));
    bind();
    await notifications.configure(enabled: true);
    final first = await stage(1);
    final raw = await DriftSmsDetectionNotificationStore(db).read();
    final bytes = await sqliteBackupSnapshot(
      database: db,
      target: File('${directory.path}/snapshot.sqlite'),
      redact: true,
    );
    final restoredFile = File('${directory.path}/restored.sqlite');
    await restoredFile.writeAsBytes(bytes);
    final restored = AppDatabase.forTesting(NativeDatabase(restoredFile));
    expect(await DriftSmsDetectionNotificationStore(restored).read(), raw);
    expect(
      await DriftInboxRepository(restored).listSuggestions(),
      hasLength(1),
    );
    await restored.close();
    await db.close();
    db = AppDatabase.forTesting(NativeDatabase(file));
    bind();
    expect(await DriftSmsDetectionNotificationStore(db).read(), raw);
    await notifications.reconcile();
    expect(platform.calls.single, (id: first.id.value, silent: false));
    await expectLater(
      DriftSmsDetectionNotificationStore(db).compareAndWrite(raw, raw!),
      throwsStateError,
    );
    final before = await DriftSmsDetectionNotificationStore(db).read();
    await db.customStatement(
      "CREATE TRIGGER fail_outbox BEFORE UPDATE ON schema_metadata WHEN NEW.key = 'sms_detection_notifications_v1' BEGIN SELECT RAISE(ABORT, 'injected'); END",
    );
    await expectLater(stage(2), throwsA(anything));
    expect(await inbox.repository.listImports(), hasLength(1));
    expect(await inbox.repository.listSuggestions(), hasLength(1));
    expect(await DriftSmsDetectionNotificationStore(db).read(), before);
    await db.customStatement('DROP TRIGGER fail_outbox');
    await stage(2);
    expect(await inbox.repository.listSuggestions(), hasLength(2));
  });

  test('new-only ingestion stages without callback; bounded pages resume; historical stays silent', () async {
    await notifications.configure(enabled: true);
    final timestamp = start.millisecondsSinceEpoch;
    final source = Source(
      List.generate(
        101,
        (i) => SmsProviderRow(
          timestamp,
          i,
          AndroidSmsMessage(
            sourceKey: 'android-sms:$i',
            body: 'برداشت مبلغ 1000',
            address: 'bank',
            receivedAt: start,
          ),
        ),
      ),
    );
    final ingestion = SmsIngestion(inbox, source);
    await ingestion.consent(from: start, until: start, newOnly: true);
    await ingestion.run(onProgress: (_) {}, now: () => start, maxPages: 1);
    expect(source.reads, 1);
    expect((await ingestion.load())!.complete, isFalse);
    expect((await state()).members, hasLength(100));
    await notifications.reconcile();
    expect(platform.calls.single.silent, isFalse);
    await ingestion.run(onProgress: (_) {}, now: () => start, maxPages: 1);
    expect((await ingestion.load())!.complete, isTrue);
    expect((await state()).members, hasLength(101));
    await notifications.reconcile();
    expect(platform.calls.last.silent, isTrue);
    await ingestion.run(
      onProgress: (_) {},
      now: () => start.add(const Duration(minutes: 1)),
    );
    await notifications.reconcile();
    expect(platform.calls, hasLength(2));
    final historicalSource = Source([
      SmsProviderRow(
        timestamp,
        999,
        AndroidSmsMessage(
          sourceKey: 'android-sms:999',
          body: 'برداشت مبلغ 1000',
          address: 'bank',
          receivedAt: start,
        ),
      ),
    ]);
    final historical = SmsIngestion(inbox, historicalSource);
    await historical.consent(from: start, until: start, newOnly: false);
    await historical.run(onProgress: (_) {}, now: () => start);
    expect((await state()).eligible, hasLength(101));
    expect(await inbox.repository.listSuggestions(), hasLength(102));
  });

  test('legacy amount flag ignored and legacy backlog suppressed', () {
    final state = SmsDetectionNotificationState.decode(
      '{"version":1,"enabled":true,"showAmounts":true,"eligible":["old"],"delivered":[],"visible":["old"]}',
    );
    expect(state.showAmounts, isFalse);
    expect(state.delivered, {'old'});
    expect(state.batchId, isNull);
    expect(
      SmsDetectionNotificationState.decode(state.encode()).showAmounts,
      isFalse,
    );
  });
}
