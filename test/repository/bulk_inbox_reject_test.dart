import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/finance/application/finance_use_cases.dart';
import 'package:planact/features/finance/data/drift_finance_repository.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/inbox/application/bulk_inbox_reject.dart';
import 'package:planact/features/inbox/application/inbox_use_cases.dart';
import 'package:planact/features/inbox/data/drift_inbox_repository.dart';
import 'package:planact/features/inbox/domain/inbox.dart';

void main() {
  test('independent failure/retry, stale history, replay and cold file reopen', () async {
    final dir = await Directory.systemTemp.createTemp('bulk-inbox-');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/live.sqlite');
    var db = AppDatabase.forTesting(NativeDatabase(file));
    var repo = DriftInboxRepository(db);
    var inbox = InboxUseCases(repo);
    final account = FinancialAccount(
      id: StableId.generate(),
      name: 'حساب موجود',
      currency: 'IRR',
      type: FinancialAccountType.bank,
    );
    await FinanceUseCases(DriftFinanceRepository(db)).createAccount(
      account,
      openingBalance: Money(minorUnits: 123456, currency: 'IRR'),
      occurredAt: DateTime(2026, 10, 1),
    );
    final originalEntries = await DriftFinanceRepository(db).listEntries();
    final snapshots = <InboxSuggestion>[];
    for (var i = 0; i < 3; i++) {
      snapshots.add(
        await inbox.stageSms(
          rawText: 'برداشت مبلغ ${1000 + i}',
          sourceKey: '$i',
          currency: 'IRR',
        ),
      );
    }
    // One row fails after suggestion update: its entire item transaction rolls back.
    await db.customStatement(
      "CREATE TRIGGER fail_one BEFORE UPDATE ON staged_imports WHEN OLD.id = '${snapshots[1].stagedImportId.value}' BEGIN SELECT RAISE(ABORT,'injected'); END",
    );
    final failures = <InboxSuggestion>[];
    final successes = <InboxSuggestion>[];
    await BulkInboxReject(inbox).run(
      snapshots,
      onStarted: (_) {},
      onFinished: (s, ok) => (ok ? successes : failures).add(s),
    );
    expect(successes, hasLength(2));
    expect(failures, [snapshots[1]]);
    expect(
      (await repo.listSuggestions())
          .firstWhere((s) => s.id == snapshots[1].id)
          .revision,
      0,
    );
    await db.customStatement('DROP TRIGGER fail_one');
    await BulkInboxReject(inbox).run(
      failures,
      onStarted: (_) {},
      onFinished: (_, ok) => expect(ok, isTrue),
    );
    var current = (await repo.listSuggestions()).firstWhere(
      (s) => s.id == snapshots[0].id,
    );
    await inbox.rollback(current);
    // Newer reopening must not be undone by retrying the original selection.
    await BulkInboxReject(inbox).run(
      [snapshots[0]],
      onStarted: (_) {},
      onFinished: (_, ok) => expect(ok, isFalse),
    );
    final entries = await DriftFinanceRepository(db).listEntries();
    expect(entries.map((e) => e.id), originalEntries.map((e) => e.id));
    expect(rebuildBalance(account, entries).minorUnits, 123456);
    final accounts = await DriftFinanceRepository(db).listAccounts();
    await db.close();
    db = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(db.close);
    repo = DriftInboxRepository(db);
    inbox = InboxUseCases(repo);
    current = (await repo.listSuggestions()).firstWhere(
      (s) => s.id == snapshots[0].id,
    );
    expect(current.status, SuggestionStatus.pending);
    expect(current.revision, 2);
    final history = jsonDecode(
      (await db.readMetadata('inbox_review_v1:${current.id.value}'))!,
    ) as Map<String, dynamic>;
    expect((history['history'] as List).map((e) => e['action']), [
      'rejected',
      'reopened',
    ]);
    final replay = await inbox.stageSms(
      rawText: 'برداشت مبلغ 1001',
      sourceKey: '1',
      currency: 'IRR',
    );
    expect(replay.status, SuggestionStatus.rejected);
    expect(replay.revision, 1);
    final reopenedEntries = await DriftFinanceRepository(db).listEntries();
    expect(reopenedEntries.map((e) => e.id), originalEntries.map((e) => e.id));
    expect(rebuildBalance(account, reopenedEntries).minorUnits, 123456);
    expect(
      (await DriftFinanceRepository(db).listAccounts()).length,
      accounts.length,
    );
  });

  test(
    'cancel is between items; eligible, unique, bounded admission',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = DriftInboxRepository(db);
      final inbox = InboxUseCases(repo);
      final snapshots = <InboxSuggestion>[];
      for (var i = 0; i < 3; i++) {
        snapshots.add(
          await inbox.stageSms(
            rawText: 'برداشت مبلغ ${2000 + i}',
            sourceKey: '$i',
            currency: 'IRR',
          ),
        );
      }
      final runner = BulkInboxReject(inbox);
      await runner.run(
        snapshots,
        onStarted: (_) {},
        onFinished: (_, ok) {
          expect(ok, isTrue);
          runner.cancel();
        },
      );
      expect(
        (await repo.listSuggestions()).where(
          (s) => s.status == SuggestionStatus.rejected,
        ),
        hasLength(1),
      );
      final rejected = (await repo.listSuggestions()).firstWhere(
        (s) => s.status == SuggestionStatus.rejected,
      );
      for (final selection in [
        [rejected],
        [snapshots[1], snapshots[1]],
        List.filled(51, snapshots[1]),
      ]) {
        await expectLater(
          BulkInboxReject(inbox)
              .run(selection, onStarted: (_) {}, onFinished: (_, _) {}),
          throwsArgumentError,
        );
      }
    },
  );
}
