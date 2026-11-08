import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:planact/core/application/command_gate.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/features/backup/data/sqlite_backup_snapshot.dart';
import 'package:planact/features/finance/data/drift_finance_repository.dart';
import 'package:planact/features/inbox/application/inbox_use_cases.dart';
import 'package:planact/features/inbox/application/sms_ingestion.dart';
import 'package:planact/features/inbox/data/drift_inbox_repository.dart';
import 'package:planact/features/inbox/presentation/sms_sync_controller.dart';

import '../fixtures/sms_provider.dart';

Future<void> waitForRead(TestSmsProvider source, int previous) async {
  while (source.reads == previous) {
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
}

class DelayedSetupRepository extends DriftInboxRepository {
  DelayedSetupRepository(super.database);
  final entered = Completer<void>();
  final release = Completer<void>();

  @override
  Future<void> writeSmsSetup({
    required String? expectedHistory,
    required String? expectedManual,
    required String? expectedAutomatic,
    required String history,
    required String manual,
    required String? automatic,
  }) async {
    entered.complete();
    await release.future;
    await super.writeSmsSetup(
      expectedHistory: expectedHistory,
      expectedManual: expectedManual,
      expectedAutomatic: expectedAutomatic,
      history: history,
      manual: manual,
      automatic: automatic,
    );
  }
}

class DelayedAccessProvider extends TestSmsProvider {
  Completer<void>? accessWait;
  int accessChecks = 0;
  @override
  Future<bool> hasAccess() async {
    accessChecks++;
    await accessWait?.future;
    return access;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('7-day setup off, during-setup delivery, later manual, cold reopen and redacted backup', () async {
    final directory = await Directory.systemTemp.createTemp('sms-manual-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/live.sqlite');
    var db = AppDatabase.forTesting(NativeDatabase(file));
    var repo = DriftInboxRepository(db);
    final source = TestSmsProvider();
    addTearDown(source.events.close);
    var now = DateTime.now().subtract(const Duration(hours: 1));
    final start = now.millisecondsSinceEpoch;
    source.add(1, start - const Duration(days: 8).inMilliseconds);
    source.add(2, start - const Duration(days: 6).inMilliseconds);
    var sync = SmsSyncController(
      inbox: InboxUseCases(repo),
      source: source,
      now: () => now,
    );
    await sync.refresh(checkAccess: true);
    expect(sync.setupRequired, isTrue);
    expect(source.reads, 0);
    source.blockRead = Completer<void>();
    final setup = sync.setup(days: 7, automatic: false);
    while (source.reads == 0) {
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
    // Both consents exist before the first provider read finishes.
    expect(SmsScan.decode((await repo.readSmsScan())!).until, start);
    expect(SmsScan.decode((await repo.readManualSmsScan())!).from, start);
    expect(await repo.readAutomaticSmsScan(), isNull);
    now = now.add(const Duration(minutes: 1));
    source.add(3, now.millisecondsSinceEpoch);
    source.blockRead!.complete();
    await setup;
    expect(sync.error, isNull);
    expect(sync.manualReady, isTrue);
    expect(sync.enabled, isFalse);
    expect(await repo.listSuggestions(), hasLength(2));
    expect(sync.lastNewSuggestions, 2);
    final history = await repo.readSmsScan();
    final auto = await repo.readAutomaticSmsScan();
    final first = (await repo.listSuggestions()).first;
    await InboxUseCases(repo).reject(first);
    now = now.add(const Duration(minutes: 1));
    source.add(4, now.millisecondsSinceEpoch);
    final reads = source.reads;
    await sync.refresh(checkAccess: true);
    expect(source.reads, reads);
    source.blockRead = Completer<void>();
    final a = sync.checkNewMessages();
    final b = sync.checkNewMessages();
    expect(identical(a, b), isTrue);
    source.blockRead!.complete();
    await Future.wait([a, b]);
    expect(sync.lastNewSuggestions, 1);
    await sync.checkNewMessages();
    expect(sync.lastNewSuggestions, 0);
    expect(await repo.readSmsScan(), history);
    expect(await repo.readAutomaticSmsScan(), auto);
    expect(await DriftFinanceRepository(db).listEntries(), isEmpty);
    expect(source.requests, 0);
    expect(source.maxConcurrentReads, 1);
    final manual = await repo.readManualSmsScan();
    sync.dispose();
    await db.close();
    db = AppDatabase.forTesting(NativeDatabase(file));
    repo = DriftInboxRepository(db);
    sync = SmsSyncController(
      inbox: InboxUseCases(repo),
      source: source,
      now: () => now,
    );
    await sync.refresh();
    expect(sync.manualReady, isTrue);
    expect(sync.enabled, isFalse);
    expect(await repo.readManualSmsScan(), manual);
    final bytes = await sqliteBackupSnapshot(
      database: db,
      target: File('${directory.path}/snapshot.sqlite'),
      redact: true,
    );
    sync.dispose();
    await db.close();
    final restored = File('${directory.path}/restored.sqlite');
    await restored.writeAsBytes(bytes);
    db = AppDatabase.forTesting(NativeDatabase(restored));
    addTearDown(db.close);
    repo = DriftInboxRepository(db);
    expect(await repo.readManualSmsScan(), manual);
    expect(await repo.readSmsScan(), history);
    expect(await repo.readAutomaticSmsScan(), auto);
    expect(
      (await repo.listSuggestions())
          .singleWhere((s) => s.id == first.id)
          .revision,
      1,
    );
    now = now.add(const Duration(minutes: 1));
    source.add(5, now.millisecondsSinceEpoch);
    sync = SmsSyncController(
      inbox: InboxUseCases(repo),
      source: source,
      now: () => now,
    );
    addTearDown(sync.dispose);
    await sync.refresh();
    await sync.checkNewMessages();
    expect(sync.lastNewSuggestions, 1);
    expect(await repo.listSuggestions(), hasLength(4));
  });

  test('manual cancellation, auto refresh overlap and admission retirement are safe', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = DriftInboxRepository(db);
    final source = TestSmsProvider();
    addTearDown(source.events.close);
    var now = DateTime.now().subtract(const Duration(hours: 1));
    final sync = SmsSyncController(
      inbox: InboxUseCases(repo),
      source: source,
      now: () => now,
    );
    addTearDown(sync.dispose);
    await sync.setup(days: 7, automatic: false);
    final history = await repo.readSmsScan();
    now = now.add(const Duration(minutes: 1));
    source.add(1, now.millisecondsSinceEpoch);
    source.blockRead = Completer<void>();
    final reads = source.reads;
    final check = sync.checkNewMessages();
    await waitForRead(source, reads);
    await sync.refresh(checkAccess: true);
    expect(sync.busy, isTrue);
    sync.didChangeAppLifecycleState(AppLifecycleState.paused);
    source.blockRead!.complete();
    await check;
    expect(sync.lastNewSuggestions, isNull);
    expect((await repo.listSuggestions()), isEmpty);
    expect(SmsScan.decode((await repo.readManualSmsScan())!).complete, isFalse);
    sync.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await sync.refresh();
    await sync.checkNewMessages();
    expect(sync.lastNewSuggestions, 1);
    expect(await repo.readSmsScan(), history);
    final gate = CommandGate();
    CommandGate.bind(db, gate);
    await gate.retire();
    final before = source.reads;
    await sync.checkNewMessages();
    expect(sync.error, isNotNull);
    expect(source.reads, before);
    expect(sync.busy, isFalse);
  });

  test(
    'historical failure is retained and manual retry never resumes history',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = DriftInboxRepository(db);
      final source = TestSmsProvider();
      addTearDown(source.events.close);
      var now = DateTime.now().subtract(const Duration(hours: 1));
      source.add(
        1,
        now.subtract(const Duration(days: 1)).millisecondsSinceEpoch,
      );
      source.failRead = 1;
      final sync = SmsSyncController(
        inbox: InboxUseCases(repo),
        source: source,
        now: () => now,
      );
      addTearDown(sync.dispose);
      await sync.setup(days: 7, automatic: true);
      expect(sync.error, isNotNull);
      expect(sync.manualReady, isTrue);
      expect(sync.enabled, isTrue);
      final history = await repo.readSmsScan();
      expect(SmsScan.decode(history!).complete, isFalse);
      source.failRead = null;
      now = now.add(const Duration(minutes: 1));
      source.add(2, now.millisecondsSinceEpoch);
      await sync.checkNewMessages();
      expect(sync.lastNewSuggestions, 1);
      expect(await repo.listSuggestions(), hasLength(1));
      expect(await repo.readSmsScan(), history);
    },
  );

  test(
    'legacy automatic boundary survives re-enable before first manual check',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = DriftInboxRepository(db);
      final source = TestSmsProvider();
      addTearDown(source.events.close);
      var now = DateTime.now().subtract(const Duration(hours: 1));
      final old = now.subtract(const Duration(days: 1)).millisecondsSinceEpoch;
      await repo.writeAutomaticSmsScan(
        null,
        SmsScan(
          from: old,
          until: old,
          newOnly: true,
          automatic: false,
        ).encode(),
      );
      final sync = SmsSyncController(
        inbox: InboxUseCases(repo),
        source: source,
        now: () => now,
      );
      addTearDown(sync.dispose);
      await sync.refresh();
      await sync.setEnabled(true);
      expect(SmsScan.decode((await repo.readManualSmsScan())!).from, old);
      expect(
        SmsScan.decode((await repo.readAutomaticSmsScan())!).from,
        now.millisecondsSinceEpoch,
      );
      source.add(1, old + 1);
      now = now.add(const Duration(minutes: 1));
      await sync.checkNewMessages();
      expect(sync.lastNewSuggestions, 1);
    },
  );

  for (final dispose in [false, true]) {
    test(
      'cancel while setup consent is pending never starts read: dispose=$dispose',
      () async {
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        addTearDown(db.close);
        final repo = DelayedSetupRepository(db);
        final source = TestSmsProvider();
        addTearDown(source.events.close);
        final sync = SmsSyncController(
          inbox: InboxUseCases(repo),
          source: source,
        );
        final command = sync.setup(days: 7, automatic: false);
        await repo.entered.future;
        if (dispose) {
          sync.dispose();
        } else {
          sync.didChangeAppLifecycleState(AppLifecycleState.paused);
          sync.didChangeAppLifecycleState(AppLifecycleState.resumed);
        }
        repo.release.complete();
        await command;
        expect(source.reads, 0);
        expect(sync.lastNewSuggestions, isNull);
        expect(await repo.readManualSmsScan(), isNotNull);
        if (!dispose) {
          await sync.refresh();
          sync.dispose();
        }
      },
    );
  }

  test(
    'setup count includes history and shared boundary exactly once',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = DriftInboxRepository(db);
      final source = TestSmsProvider();
      addTearDown(source.events.close);
      final now = DateTime(2026, 11, 1);
      source.add(
        1,
        now.subtract(const Duration(days: 1)).millisecondsSinceEpoch,
      );
      source.add(2, now.millisecondsSinceEpoch);
      final sync = SmsSyncController(
        inbox: InboxUseCases(repo),
        source: source,
        now: () => now,
      );
      addTearDown(sync.dispose);
      await sync.setup(days: 7, automatic: false);
      expect(sync.lastNewSuggestions, 2);
      expect(await repo.listSuggestions(), hasLength(2));
    },
  );

  for (final legacy in [false, true]) {
    for (final queued in [false, true]) {
      test(
        'Start precedes delayed access/queued refresh: legacy=$legacy queued=$queued',
        () async {
          final db = AppDatabase.forTesting(NativeDatabase.memory());
          addTearDown(db.close);
          final repo = DriftInboxRepository(db);
          final source = DelayedAccessProvider();
          addTearDown(source.events.close);
          var now = DateTime(2026, 11, 1, 10);
          final start = now.millisecondsSinceEpoch;
          if (legacy) {
            await repo.writeSmsScan(
              null,
              SmsScan(
                from: start - 1000,
                until: start,
                newOnly: false,
              ).encode(),
            );
          }
          final sync = SmsSyncController(
            inbox: InboxUseCases(repo),
            source: source,
            now: () => now,
          );
          addTearDown(sync.dispose);
          await sync.refresh(checkAccess: true);
          source.accessWait = Completer<void>();
          Future<void>? refresh;
          final checks = source.accessChecks;
          if (queued) {
            refresh = sync.refresh(checkAccess: true);
            while (source.accessChecks == checks) {
              await Future<void>.delayed(Duration.zero);
            }
          }
          final command = legacy
              ? sync.activateManualFromNow()
              : sync.setup(days: 0, automatic: false);
          if (!queued) {
            while (source.accessChecks == checks) {
              await Future<void>.delayed(Duration.zero);
            }
          }
          now = now.add(const Duration(minutes: 2));
          source.add(1, start + const Duration(minutes: 1).inMilliseconds);
          source.accessWait!.complete();
          await refresh;
          await command;
          expect(SmsScan.decode((await repo.readManualSmsScan())!).from, start);
          expect(await repo.listSuggestions(), hasLength(1));
          expect(sync.lastNewSuggestions, 1);
        },
      );
    }
  }

  for (final dispose in [false, true]) {
    for (final phase in ['controller-access', 'ingestion-access']) {
      test('cancel before read: dispose=$dispose phase=$phase', () async {
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        addTearDown(db.close);
        final repo = DriftInboxRepository(db);
        final source = DelayedAccessProvider();
        addTearDown(source.events.close);
        final now = DateTime(2026, 11, 1);
        final sync = SmsSyncController(
          inbox: InboxUseCases(repo),
          source: source,
          now: () => now,
        );
        await sync.setup(days: 0, automatic: false);
        final reads = source.reads;
        final checks = source.accessChecks;
        source.accessWait = Completer<void>();
        final command = sync.checkNewMessages();
        while (source.accessChecks == checks) {
          await Future<void>.delayed(Duration.zero);
        }
        if (phase == 'ingestion-access') {
          source.accessWait!.complete();
          source.accessWait = Completer<void>();
          while (source.accessChecks < checks + 2) {
            await Future<void>.delayed(Duration.zero);
          }
        }
        if (dispose) {
          sync.dispose();
        } else {
          sync.didChangeAppLifecycleState(AppLifecycleState.paused);
          sync.didChangeAppLifecycleState(AppLifecycleState.resumed);
        }
        source.accessWait!.complete();
        await command;
        expect(source.reads, reads);
        expect(sync.lastNewSuggestions, isNull);
        if (!dispose) {
          await sync.refresh();
          sync.dispose();
        }
      });
    }
  }

  for (final legacy in ['range', 'newOnly', 'auto']) {
    test(
      'legacy $legacy preserves consent and never resumes history',
      () async {
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        addTearDown(db.close);
        final repo = DriftInboxRepository(db);
        final inbox = InboxUseCases(repo);
        final source = TestSmsProvider();
        addTearDown(source.events.close);
        final now = DateTime.now().subtract(const Duration(hours: 1));
        final old = now.subtract(const Duration(days: 7));
        final scan = SmsScan(
          from: old.millisecondsSinceEpoch,
          until: now.millisecondsSinceEpoch,
          newOnly: legacy != 'range',
          automatic: legacy == 'auto',
        );
        if (legacy == 'auto') {
          await repo.writeAutomaticSmsScan(null, scan.encode());
        } else {
          await repo.writeSmsScan(null, scan.encode());
        }
        final history = await repo.readSmsScan();
        source.add(1, old.millisecondsSinceEpoch + 1);
        final sync = SmsSyncController(
          inbox: inbox,
          source: source,
          now: () => now,
        );
        addTearDown(sync.dispose);
        await sync.refresh(checkAccess: true);
        expect(sync.enabled, legacy == 'auto');
        expect(sync.manualReady, legacy != 'range');
        expect(await repo.readManualSmsScan(), isNull);
        if (legacy == 'range') {
          await sync.checkNewMessages();
          expect(source.reads, 0);
          expect(sync.lastNewSuggestions, isNull);
          await sync.activateManualFromNow();
          expect(
            SmsScan.decode((await repo.readManualSmsScan())!).from,
            now.millisecondsSinceEpoch,
          );
          expect(await repo.listSuggestions(), isEmpty);
        } else {
          await sync.checkNewMessages();
          expect(
            SmsScan.decode((await repo.readManualSmsScan())!).from,
            old.millisecondsSinceEpoch,
          );
          expect(await repo.listSuggestions(), hasLength(1));
        }
        expect(await repo.readSmsScan(), history);
      },
    );
  }

  test('manual permission failure and interrupted scan retry preserve decisions and history', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = DriftInboxRepository(db);
    final source = TestSmsProvider();
    addTearDown(source.events.close);
    var now = DateTime.now().subtract(const Duration(hours: 1));
    final sync = SmsSyncController(
      inbox: InboxUseCases(repo),
      source: source,
      now: () => now,
    );
    addTearDown(sync.dispose);
    source.access = false;
    await sync.setup(days: 7, automatic: true);
    expect(await repo.readManualSmsScan(), isNull);
    expect(await repo.readSmsScan(), isNull);
    expect(await repo.readAutomaticSmsScan(), isNull);
    expect(source.requests, 0);
    source.access = true;
    await sync.setup(days: 0, automatic: false);
    final history = await repo.readSmsScan();
    final boundary = SmsScan.decode((await repo.readManualSmsScan())!).from;
    for (var i = 0; i < 120; i++) {
      source.add(i, boundary + 1);
    }
    now = now.add(const Duration(minutes: 1));
    source.failRead = source.reads + 2;
    await sync.checkNewMessages();
    expect(sync.error, isNotNull);
    expect(sync.lastNewSuggestions, isNull);
    expect(await repo.listSuggestions(), hasLength(100));
    final first = (await repo.listSuggestions()).first;
    await InboxUseCases(repo).reject(first);
    final checkpoint = await repo.readManualSmsScan();
    source.access = false;
    final reads = source.reads;
    await sync.checkNewMessages();
    expect(sync.access, isFalse);
    expect(source.reads, reads);
    expect(await repo.readManualSmsScan(), checkpoint);
    source.access = true;
    source.failRead = null;
    // Catch up a later horizon in the same retry, without resuming history.
    now = now.add(const Duration(minutes: 1));
    source.add(121, now.millisecondsSinceEpoch);
    await sync.checkNewMessages();
    expect(sync.error, isNull);
    expect(sync.lastNewSuggestions, 21);
    expect(await repo.listSuggestions(), hasLength(121));
    expect(
      (await repo.listSuggestions())
          .singleWhere((s) => s.id == first.id)
          .revision,
      1,
    );
    expect(await repo.readSmsScan(), history);
    expect(SmsScan.decode((await repo.readManualSmsScan())!).from, boundary);
    expect(source.maxConcurrentReads, 1);
  });

  test(
    'atomic setup rejects stale state and rolls back all keys on write failure',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = DriftInboxRepository(db);
      final source = TestSmsProvider();
      addTearDown(source.events.close);
      final inbox = InboxUseCases(repo);
      final sync = SmsSyncController(inbox: inbox, source: source);
      addTearDown(sync.dispose);
      await sync.refresh();
      await db.customStatement(
        "CREATE TRIGGER fail_manual BEFORE INSERT ON schema_metadata WHEN NEW.key = 'sms_manual_scan_v1' BEGIN SELECT RAISE(ABORT, 'injected'); END",
      );
      await sync.setup(days: 30, automatic: true);
      expect(sync.error, isNotNull);
      expect(sync.manualReady, isFalse);
      expect(await repo.readSmsScan(), isNull);
      expect(await repo.readAutomaticSmsScan(), isNull);
      expect(await repo.readManualSmsScan(), isNull);
      expect(source.reads, 0);
      await db.customStatement('DROP TRIGGER fail_manual');
      await sync.setup(days: 30, automatic: false);
      expect(sync.error, isNull);
      final history = await repo.readSmsScan();
      final manual = await repo.readManualSmsScan();
      await expectLater(
        repo.writeSmsSetup(
          expectedHistory: null,
          expectedManual: manual,
          expectedAutomatic: null,
          history: history!,
          manual: manual!,
          automatic: null,
        ),
        throwsStateError,
      );
      expect(await repo.readSmsScan(), history);
      expect(await repo.readManualSmsScan(), manual);
      await expectLater(
        repo.writeManualSmsScan(null, manual),
        throwsStateError,
      );
      expect(await repo.readManualSmsScan(), manual);
    },
  );

  test(
    'automatic toggles and repeated setup never narrow manual boundary',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = DriftInboxRepository(db);
      final source = TestSmsProvider();
      addTearDown(source.events.close);
      var now = DateTime.now().subtract(const Duration(hours: 2));
      final sync = SmsSyncController(
        inbox: InboxUseCases(repo),
        source: source,
        now: () => now,
      );
      addTearDown(sync.dispose);
      await sync.setup(days: 7, automatic: true);
      final from = SmsScan.decode((await repo.readManualSmsScan())!).from;
      final autoFrom = SmsScan.decode((await repo.readAutomaticSmsScan())!)
          .from;
      now = now.add(const Duration(minutes: 1));
      await sync.setup(days: 7, automatic: true);
      expect(
        SmsScan.decode((await repo.readAutomaticSmsScan())!).from,
        autoFrom,
      );
      await sync.setEnabled(false);
      now = now.add(const Duration(minutes: 1));
      source.add(1, now.millisecondsSinceEpoch);
      now = now.add(const Duration(minutes: 1));
      await sync.setEnabled(true);
      expect(
        SmsScan.decode((await repo.readAutomaticSmsScan())!).from,
        now.millisecondsSinceEpoch,
      );
      expect(await repo.listSuggestions(), isEmpty);
      await sync.checkNewMessages();
      expect(sync.lastNewSuggestions, 1);
      expect(SmsScan.decode((await repo.readManualSmsScan())!).from, from);
      final saved = await repo.readAutomaticSmsScan();
      await db.customStatement(
        "CREATE TRIGGER fail_auto BEFORE UPDATE ON schema_metadata WHEN NEW.key = 'sms_automatic_scan_v1' BEGIN SELECT RAISE(ABORT, 'injected'); END",
      );
      await sync.setEnabled(false);
      expect(sync.enabled, isTrue);
      expect(sync.error, isNotNull);
      expect(await repo.readAutomaticSmsScan(), saved);
      expect(SmsScan.decode((await repo.readManualSmsScan())!).from, from);
    },
  );
}
