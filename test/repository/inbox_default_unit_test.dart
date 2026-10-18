import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/core/errors/app_error.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/backup/data/sqlite_backup_snapshot.dart';
import 'package:planact/features/finance/data/drift_finance_repository.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/inbox/application/inbox_use_cases.dart';
import 'package:planact/features/inbox/data/drift_inbox_repository.dart';
import 'package:planact/features/inbox/domain/inbox.dart';
import 'package:planact/features/inbox/domain/sms_currency_evidence.dart';

void main() {
  for (final unit in SmsMoneyUnit.values) {
    test('confirmed $unit proposal is atomic, retryable and durable', () async {
      final dir = await Directory.systemTemp.createTemp('inbox-default-unit-');
      addTearDown(() => dir.delete(recursive: true));
      final file = File('${dir.path}/live.sqlite');
      var db = AppDatabase.forTesting(NativeDatabase(file));
      final repo = DriftInboxRepository(db);
      final inbox = InboxUseCases(repo);
      final finance = DriftFinanceRepository(db);
      final account = FinancialAccount(
        id: StableId.generate(),
        name: 'نقد',
        currency: 'IRR',
        type: FinancialAccountType.cash,
      );
      await finance.saveAccount(account);
      final suggestion = await inbox.stageSms(
        rawText: 'برداشت مبلغ 2500\nتاریخ: 2026-10-14\nساعت: 12:30',
        sourceKey: 'default',
        currency: 'IRR',
      );
      Future<AccountEntry> confirm() => inbox.confirm(
        suggestion: suggestion,
        account: account,
        finance: finance,
        selectedUnit: unit,
      );
      // Fail after the ledger insert, proving selection/history roll back too.
      await db.customStatement(
        "CREATE TRIGGER fail_unit BEFORE UPDATE ON staged_imports BEGIN SELECT RAISE(ABORT, 'injected'); END",
      );
      await expectLater(confirm(), throwsA(anything));
      expect(await finance.listEntries(), isEmpty);
      var stored = (await repo.listSuggestions()).single;
      expect(stored.revision, 0);
      expect(stored.draft.currencyEvidence!.requiresSelection, isTrue);
      await db.customStatement('DROP TRIGGER fail_unit');
      final entry = await confirm();
      expect(entry.amount.currency, 'IRR');
      expect(
        entry.amount.minorUnits,
        unit == SmsMoneyUnit.toman ? 25000 : 2500,
      );
      expect((await confirm()).id, entry.id);
      expect(await finance.listEntries(), hasLength(1));
      await db.close();

      db = AppDatabase.forTesting(NativeDatabase(file));
      stored = (await DriftInboxRepository(db).listSuggestions()).single;
      expect(stored.status, SuggestionStatus.confirmed);
      expect(stored.draft.currencyEvidence!.selectedUnit, unit);
      expect(stored.draft.amount, entry.amount);
      expect(
        stored.extractedEvidence!.draft.currencyEvidence!.requiresSelection,
        isTrue,
      );
      expect(stored.extractedEvidence!.draft.amount.minorUnits, 2500);
      final metadata = jsonDecode(
        (await db.readMetadata('inbox_review_v1:${stored.id.value}'))!,
      ) as Map<String, dynamic>;
      final history = metadata['history'] as List;
      expect(history, hasLength(1));
      expect(history.single['action'], 'confirmed');
      expect(
        history.single['reviewed']['currencyEvidence']['selectedUnit'],
        unit.name,
      );
      final bytes = await sqliteBackupSnapshot(
        database: db,
        target: File('${dir.path}/snapshot.sqlite'),
        redact: true,
      );
      await db.close();
      final restoredFile = File('${dir.path}/restored.sqlite');
      await restoredFile.writeAsBytes(bytes);
      final restored = AppDatabase.forTesting(NativeDatabase(restoredFile));
      addTearDown(restored.close);
      final restoredRepo = DriftInboxRepository(restored);
      expect((await restoredRepo.listImports()).single.rawText, isEmpty);
      expect(
        (await restoredRepo.listSuggestions()).single.draft.toReviewJson(),
        stored.draft.toReviewJson(),
      );
      expect(
        (await DriftFinanceRepository(restored).listEntries()).single.amount,
        entry.amount,
      );
    });
  }

  test('stale proposal cannot replace a newly selected unit', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = DriftInboxRepository(db);
    final inbox = InboxUseCases(repo);
    final finance = DriftFinanceRepository(db);
    final account = FinancialAccount(
      id: StableId.generate(),
      name: 'نقد',
      currency: 'IRR',
      type: FinancialAccountType.cash,
    );
    await finance.saveAccount(account);
    final old = await inbox.stageSms(
      rawText: 'برداشت مبلغ 2500',
      sourceKey: 'stale',
      currency: 'IRR',
    );
    await inbox.edit(
      old,
      old.draft.selectUnresolvedCurrency(SmsMoneyUnit.rial),
    );
    await expectLater(
      inbox.confirm(
        suggestion: old,
        account: account,
        finance: finance,
        selectedUnit: SmsMoneyUnit.toman,
      ),
      throwsA(isA<ValidationError>()),
    );
    expect(await finance.listEntries(), isEmpty);
    expect((await repo.listSuggestions()).single.draft.amount.minorUnits, 2500);
    expect(
      () => old.draft
          .selectUnresolvedCurrency(SmsMoneyUnit.toman)
          .selectUnresolvedCurrency(SmsMoneyUnit.rial),
      throwsA(isA<ValidationError>()),
    );
  });
}
