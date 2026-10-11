import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/features/backup/data/sqlite_backup_snapshot.dart';
import 'package:planact/features/finance/data/drift_finance_repository.dart';
import 'package:planact/features/inbox/application/inbox_review_projection.dart';
import 'package:planact/features/inbox/application/inbox_use_cases.dart';
import 'package:planact/features/inbox/data/drift_inbox_repository.dart';
import 'package:planact/features/inbox/domain/inbox.dart';

void main() {
  test(
    'mistake recovery, revisions, rescan, cold reopen and redacted backup',
    () async {
      final dir = await Directory.systemTemp.createTemp('inbox-review-');
      addTearDown(() => dir.delete(recursive: true));
      final file = File('${dir.path}/live.sqlite');
      var db = AppDatabase.forTesting(NativeDatabase(file));
      var repo = DriftInboxRepository(db);
      var inbox = InboxUseCases(repo);
      final at = DateTime.utc(2026, 10, 1);
      final original = await inbox.stageSms(
        rawText: 'بانک: نمونه\nبرداشت مبلغ 2500',
        sourceKey: 'row:1',
        currency: 'IRR',
        importedAt: at,
      );
      await inbox.reject(original);
      await expectLater(inbox.reject(original), throwsA(isA<Exception>()));
      var current = (await repo.listSuggestions()).single;
      expect(current.revision, 1);
      expect(current.status, SuggestionStatus.rejected);
      await inbox.rollback(current);
      await expectLater(inbox.reject(original), throwsA(isA<Exception>()));
      current = (await repo.listSuggestions()).single;
      expect(current.status, SuggestionStatus.pending);
      expect(current.revision, 2);
      expect(current.draft.bank, 'نمونه');
      expect(current.draft.dateSource, TransactionDateSource.receipt);
      await inbox.reject(current);
      await db.close();
      db = AppDatabase.forTesting(NativeDatabase(file));
      repo = DriftInboxRepository(db);
      inbox = InboxUseCases(repo);
      final replay = await inbox.stageSms(
        rawText: 'بانک: نمونه\nبرداشت مبلغ 2500',
        sourceKey: 'row:1',
        currency: 'IRR',
        importedAt: at,
      );
      expect(replay.status, SuggestionStatus.rejected);
      expect(replay.revision, 3);
      expect(await DriftFinanceRepository(db).listEntries(), isEmpty);
      final bytes = await sqliteBackupSnapshot(
        database: db,
        target: File('${dir.path}/snapshot.sqlite'),
        redact: true,
      );
      await db.close();
      final restored = File('${dir.path}/restored.sqlite');
      await restored.writeAsBytes(bytes);
      db = AppDatabase.forTesting(NativeDatabase(restored));
      addTearDown(db.close);
      repo = DriftInboxRepository(db);
      final backed = (await repo.listSuggestions()).single;
      expect(backed.revision, 3);
      expect(backed.status, SuggestionStatus.rejected);
      expect(backed.draft.bank, 'نمونه');
      final history = jsonDecode(
        (await db.readMetadata('inbox_review_v1:${backed.id.value}'))!,
      ) as Map<String, dynamic>;
      expect((history['history'] as List).map((e) => e['action']), [
        'rejected',
        'reopened',
        'rejected',
      ]);
      expect((await repo.listImports()).single.rawText, isEmpty);
      await InboxUseCases(repo).rollback(backed);
      expect(
        (await repo.listSuggestions()).single.status,
        SuggestionStatus.pending,
      );
    },
  );

  test(
    'failed atomic rejection retains row, retry works, different items commit',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = DriftInboxRepository(db);
      final inbox = InboxUseCases(repo);
      final a = await inbox.stageSms(
        rawText: 'برداشت مبلغ 1000',
        sourceKey: 'a',
        currency: 'IRR',
      );
      final b = await inbox.stageSms(
        rawText: 'برداشت مبلغ 2000',
        sourceKey: 'b',
        currency: 'IRR',
      );
      await db.customStatement(
        "CREATE TRIGGER fail_review BEFORE UPDATE ON staged_imports BEGIN SELECT RAISE(ABORT,'injected'); END",
      );
      await expectLater(inbox.reject(a), throwsA(isA<Exception>()));
      expect(
        (await repo.listSuggestions()).first.status,
        SuggestionStatus.pending,
      );
      expect((await repo.listSuggestions()).first.revision, 0);
      await db.customStatement('DROP TRIGGER fail_review');
      await Future.wait([inbox.reject(a), inbox.reject(b)]);
      expect(
        (await repo.listSuggestions()).every(
          (s) => s.status == SuggestionStatus.rejected && s.revision == 1,
        ),
        isTrue,
      );
    },
  );

  test(
    'legacy metadata absence stays unknown; equal receipt ordering is stable',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = DriftInboxRepository(db);
      final inbox = InboxUseCases(repo);
      final at = DateTime.utc(2026, 1, 1);
      await inbox.stageSms(
        rawText: 'برداشت مبلغ 1000 2026-01-01',
        sourceKey: 'a',
        currency: 'IRR',
        importedAt: at,
      );
      await inbox.stageSms(
        rawText: 'برداشت مبلغ 2000',
        sourceKey: 'b',
        currency: 'IRR',
        importedAt: at,
      );
      await db.customStatement(
        "DELETE FROM schema_metadata WHERE key LIKE 'inbox_review_v1:%'",
      );
      final suggestions = await repo.listSuggestions();
      expect(
        suggestions.every(
          (s) =>
              s.draft.bank == null &&
              s.draft.dateSource == TransactionDateSource.unknown &&
              s.revision == 0,
        ),
        isTrue,
      );
      const projection = InboxReviewProjection();
      final imports = await repo.listImports();
      final first = projection.build(
        suggestions: suggestions,
        imports: imports,
        accounts: [],
        entries: [],
        bank: '',
      );
      final second = projection.build(
        suggestions: suggestions.reversed,
        imports: imports,
        accounts: [],
        entries: [],
        bank: '',
      );
      expect(
        first.map((s) => s.suggestion.id),
        second.map((s) => s.suggestion.id),
      );
      expect(first, hasLength(2));
    },
  );
}
