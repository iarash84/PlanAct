import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/backup/data/sqlite_backup_snapshot.dart';
import 'package:planact/features/finance/data/drift_finance_repository.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/inbox/application/inbox_use_cases.dart';
import 'package:planact/features/inbox/application/sms_ingestion.dart';
import 'package:planact/features/inbox/data/drift_inbox_repository.dart';
import 'package:planact/features/inbox/domain/inbox.dart';
import 'package:planact/features/inbox/presentation/sms_sync_controller.dart';

import '../fixtures/sms_provider.dart';

class FailingSyncStore extends DriftInboxRepository {
  FailingSyncStore(super.database);
  bool failWrite = false;
  @override
  Future<void> writeAutomaticSmsScan(String? expected, String value) {
    if (failWrite) throw StateError('Injected persistence failure');
    return super.writeAutomaticSmsScan(expected, value);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'permission and old import consent never enable automatic ingestion',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = DriftInboxRepository(db);
      final inbox = InboxUseCases(repo);
      final source = TestSmsProvider();
      addTearDown(source.events.close);
      final old = DateTime.now().subtract(const Duration(days: 1));
      source.add(1, old.millisecondsSinceEpoch);
      await SmsIngestion(
        inbox,
        source,
      ).consent(from: old, until: old, newOnly: true);
      final sync = SmsSyncController(inbox: inbox, source: source);
      addTearDown(sync.dispose);
      await sync.refresh(checkAccess: true);
      expect(sync.enabled, isFalse);
      expect(sync.access, isTrue);
      expect(source.reads, 0);
      expect(source.requests, 0);
      expect(await repo.readAutomaticSmsScan(), isNull);
      expect(await repo.listSuggestions(), isEmpty);
    },
  );

  test('consented boundary, concurrent refresh/manual scan and delayed insertion preserve decisions', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = DriftInboxRepository(db);
    final inbox = InboxUseCases(repo);
    final source = TestSmsProvider();
    addTearDown(source.events.close);
    final at = DateTime.now().subtract(const Duration(hours: 1));
    final start = at.millisecondsSinceEpoch;
    source.add(1, start - 1);
    final sync = SmsSyncController(inbox: inbox, source: source, now: () => at);
    addTearDown(sync.dispose);
    await sync.refresh(checkAccess: true);
    await sync.setEnabled(true);
    source.add(2, start + 20);
    await sync.refresh();
    final original = (await repo.listSuggestions()).single;
    await inbox.reject(original);
    // A later insertion sorts before the previously completed cursor.
    source.add(3, start + 10);
    final manual = SmsIngestion(inbox, source);
    await manual.consent(from: at, until: DateTime.now(), newOnly: false);
    await Future.wait([
      sync.refresh(),
      sync.refresh(),
      sync.refresh(),
      manual.run(onProgress: (_) {}),
    ]);
    final items = await repo.listSuggestions();
    expect(items, hasLength(2));
    expect(
      items.singleWhere((s) => s.id == original.id).status,
      SuggestionStatus.rejected,
    );
    expect(source.maxConcurrentReads, 1);
    expect(source.bounds.every((b) => b.$1 == start), isTrue);
    expect(await DriftFinanceRepository(db).listEntries(), isEmpty);
    expect(source.requests, 0);
  });

  test('revocation and failed setting write preserve consent; re-enable starts a fresh boundary', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = FailingSyncStore(db);
    final source = TestSmsProvider();
    addTearDown(source.events.close);
    var now = DateTime.now().subtract(const Duration(hours: 1));
    final sync = SmsSyncController(
      inbox: InboxUseCases(repo),
      source: source,
      now: () => now,
    );
    addTearDown(sync.dispose);
    await sync.refresh(checkAccess: true);
    source.access = false;
    await sync.setEnabled(true);
    expect(sync.enabled, isFalse);
    expect(sync.error, isNotNull);
    expect(await repo.readAutomaticSmsScan(), isNull);
    expect(source.reads, 0);
    source.access = true;
    await sync.setEnabled(true);
    expect(sync.enabled, isTrue);
    final saved = await repo.readAutomaticSmsScan();
    source.access = false;
    final reads = source.reads;
    await sync.refresh();
    expect(source.reads, reads);
    expect(sync.enabled, isTrue);
    expect(sync.error, isNotNull);
    repo.failWrite = true;
    await sync.setEnabled(false);
    expect(sync.enabled, isTrue);
    expect(sync.error, contains('ذخیره نشد'));
    expect(await repo.readAutomaticSmsScan(), saved);
    repo.failWrite = false;
    await sync.setEnabled(false);
    source.access = true;
    source.add(1, now.millisecondsSinceEpoch + 1);
    await sync.refresh();
    expect(source.reads, reads);
    now = now.add(const Duration(minutes: 30));
    await sync.setEnabled(true);
    expect((await repo.listSuggestions()), isEmpty);
    expect(
      SmsScan.decode((await repo.readAutomaticSmsScan())!).from,
      now.millisecondsSinceEpoch,
    );
  });

  test('provider failure retries from checkpoint and coalesces triggers without duplicate rows', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = DriftInboxRepository(db);
    final inbox = InboxUseCases(repo);
    final source = TestSmsProvider();
    addTearDown(source.events.close);
    final from = DateTime.now().subtract(const Duration(hours: 1));
    for (var i = 0; i < 120; i++) {
      source.add(i, from.millisecondsSinceEpoch + 1);
    }
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
    source.failRead = 2;
    final sync = SmsSyncController(inbox: inbox, source: source);
    addTearDown(sync.dispose);
    await sync.refresh();
    expect(sync.error, isNotNull);
    expect(await repo.listSuggestions(), hasLength(100));
    expect(SmsScan.decode((await repo.readAutomaticSmsScan())!).id, 99);
    source.failRead = null;
    source.blockRead = Completer<void>();
    final first = sync.refresh();
    final second = sync.refresh();
    source.blockRead!.complete();
    await Future.wait([first, second]);
    expect(sync.error, isNull);
    expect(await repo.listSuggestions(), hasLength(120));
    expect(
      SmsScan.decode((await repo.readAutomaticSmsScan())!).complete,
      isTrue,
    );
    expect(source.maxConcurrentReads, 1);
    expect(await repo.readSmsScan(), isNull);
  });

  test(
    'opening catches up beyond an interrupted scan horizon in the same refresh',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = DriftInboxRepository(db);
      final source = TestSmsProvider();
      addTearDown(source.events.close);
      final from = DateTime.now().subtract(const Duration(hours: 1));
      final start = from.millisecondsSinceEpoch;
      source.add(1, start + 1);
      source.add(2, start + 2);
      final inbox = InboxUseCases(repo);
      await SmsIngestion(
        inbox,
        source,
        store: AutomaticSmsScanAdapter(repo),
      ).consent(
        from: from,
        until: from.add(const Duration(milliseconds: 1)),
        newOnly: true,
        automatic: true,
      );
      final sync = SmsSyncController(inbox: inbox, source: source);
      addTearDown(sync.dispose);
      await sync.refresh();
      expect(await repo.listSuggestions(), hasLength(2));
      expect(source.bounds.first.$2, start + 1);
      expect(source.bounds.last.$2, greaterThan(start + 2));
    },
  );

  test('cold reopen and redacted backup retain automatic consent and resolved suggestions', () async {
    final directory = await Directory.systemTemp.createTemp('sms-automatic-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/live.sqlite');
    var db = AppDatabase.forTesting(NativeDatabase(file));
    var repo = DriftInboxRepository(db);
    var inbox = InboxUseCases(repo);
    final source = TestSmsProvider();
    addTearDown(source.events.close);
    final from = DateTime.now().subtract(const Duration(hours: 1));
    source.add(1, from.millisecondsSinceEpoch);
    source.add(2, from.millisecondsSinceEpoch);
    var sync = SmsSyncController(inbox: inbox, source: source, now: () => from);
    await sync.refresh();
    await sync.setEnabled(true);
    final suggestions = await repo.listSuggestions();
    await inbox.reject(suggestions.first);
    final finance = DriftFinanceRepository(db);
    final account = FinancialAccount(
      id: StableId.generate(),
      name: 'نمونه',
      currency: 'IRR',
      type: FinancialAccountType.bank,
    );
    await finance.saveAccount(account);
    await inbox.confirm(
      suggestion: suggestions.last,
      account: account,
      finance: finance,
    );
    final history = {
      for (final s in await repo.listSuggestions())
        s.id: (s.status, s.revision),
    };
    sync.dispose();
    await db.close();
    db = AppDatabase.forTesting(NativeDatabase(file));
    repo = DriftInboxRepository(db);
    inbox = InboxUseCases(repo);
    sync = SmsSyncController(inbox: inbox, source: source);
    await sync.refresh();
    expect(sync.enabled, isTrue);
    expect({
      for (final s in await repo.listSuggestions())
        s.id: (s.status, s.revision),
    }, history);
    final saved = await repo.readAutomaticSmsScan();
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
    expect(await repo.readAutomaticSmsScan(), saved);
    sync = SmsSyncController(inbox: InboxUseCases(repo), source: source);
    addTearDown(sync.dispose);
    await sync.refresh();
    expect(sync.enabled, isTrue);
    expect({
      for (final s in await repo.listSuggestions())
        s.id: (s.status, s.revision),
    }, history);
    expect(await DriftFinanceRepository(db).listEntries(), hasLength(1));
    expect((await repo.listImports()).every((s) => s.rawText.isEmpty), isTrue);
  });
}
