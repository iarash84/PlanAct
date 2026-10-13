import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/core/errors/app_error.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/backup/data/sqlite_backup_snapshot.dart';
import 'package:planact/features/finance/data/drift_finance_repository.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/inbox/application/inbox_use_cases.dart';
import 'package:planact/features/inbox/data/drift_inbox_repository.dart';
import 'package:planact/features/inbox/domain/inbox.dart';
import 'package:planact/features/inbox/domain/sms_currency_evidence.dart';

TransactionDraft reviewed(
  TransactionDraft old, {
  String type = 'income',
  int amount = 450,
  int sourceAmount = 45,
}) => TransactionDraft(
  id: old.id,
  stagedImportId: old.stagedImportId,
  amount: Money(minorUnits: amount, currency: 'IRR'),
  occurredAt: DateTime.utc(2026, 10, 2, 11, 30),
  type: type,
  merchant: 'اصلاح',
  reference: 'reviewed',
  dateSource: TransactionDateSource.reviewer,
  currencyEvidence: SmsCurrencyEvidence(
    sourceAmount: sourceAmount,
    selectedUnit: SmsMoneyUnit.toman,
  ),
);

FinancialAccount account() => FinancialAccount(
  id: StableId.generate(),
  name: 'نمونه',
  currency: 'IRR',
  type: FinancialAccountType.bank,
);

void main() {
  test(
    'time-only evidence and reviewed invalid amounts/units cannot enter ledger',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = DriftInboxRepository(db);
      final inbox = InboxUseCases(repo);
      final finance = DriftFinanceRepository(db);
      final bank = account();
      await finance.saveAccount(bank);
      var suggestion = await inbox.stageSms(
        rawText: 'amount: 20; time: 00:00',
        sourceKey: 'time-only',
        currency: 'IRR',
      );
      expect(suggestion.extractedEvidence!.sourceDate, isNull);
      expect(suggestion.extractedEvidence!.sourceTime, '00:00');
      expect(suggestion.extractedEvidence!.occurredAt, isNull);
      for (final amount in [0, -1, 451]) {
        suggestion = await inbox.edit(
          suggestion,
          reviewed(suggestion.draft, amount: amount),
        );
        final entry = AccountEntry(
          id: StableId.generate(),
          accountId: bank.id,
          type: AccountEntryType.income,
          amount: amount == 0
              ? const Money(minorUnits: 1, currency: 'IRR')
              : suggestion.draft.amount,
          occurredAt: suggestion.draft.occurredAt,
        );
        await expectLater(
          repo.confirmAtomically(suggestionId: suggestion.id, entry: entry),
          throwsA(isA<ValidationError>()),
        );
      }
      final old = suggestion.draft;
      suggestion = await inbox.edit(
        suggestion,
        TransactionDraft(
          id: old.id,
          stagedImportId: old.stagedImportId,
          amount: const Money(minorUnits: 20, currency: 'IRR'),
          occurredAt: old.occurredAt,
          type: 'income',
          currencyEvidence: const SmsCurrencyEvidence(sourceAmount: 20),
        ),
      );
      await expectLater(
        inbox.confirm(suggestion: suggestion, account: bank, finance: finance),
        throwsA(isA<ValidationError>()),
      );
      await db.customStatement(
        "CREATE TRIGGER fail_edit BEFORE UPDATE ON inbox_suggestions BEGIN SELECT RAISE(ABORT,'injected'); END",
      );
      final before = await db.readMetadata(
        'inbox_review_v1:${suggestion.id.value}',
      );
      await expectLater(
        inbox.edit(suggestion, reviewed(suggestion.draft)),
        throwsA(anything),
      );
      expect(
        await db.readMetadata('inbox_review_v1:${suggestion.id.value}'),
        before,
      );
      await db.customStatement('DROP TRIGGER fail_edit');
      suggestion = await inbox.edit(suggestion, reviewed(suggestion.draft));
      await inbox.confirm(
        suggestion: suggestion,
        account: bank,
        finance: finance,
      );
      expect(await finance.listEntries(), hasLength(1));
    },
  );

  test('original partial evidence survives edits, expiry, reopen, confirm and logical backup', () async {
    final dir = await Directory.systemTemp.createTemp('sms-evidence-');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/live.sqlite');
    var db = AppDatabase.forTesting(NativeDatabase(file));
    var repo = DriftInboxRepository(db);
    var inbox = InboxUseCases(repo);
    final bank = account();
    await DriftFinanceRepository(db).saveAccount(bank);
    final receipt = DateTime.utc(2026, 10, 1, 15, 21);
    final original = await inbox.stageSms(
      rawText: 'amount: 20 toman; balance: 900 rial; bank: نمونه; account: ****1234; ref: original; date: 1405/07/09',
      sourceKey: 'partial',
      currency: 'USD',
      importedAt: receipt,
    );
    expect(original.draft.type, 'unknown');
    expect(original.draft.dateSource, TransactionDateSource.receipt);
    expect(original.extractedEvidence!.sourceTime, isNull);
    expect(original.extractedEvidence!.occurredAt, isNull);
    expect(original.extractedEvidence!.sourceDate, '1405/07/09');
    final extracted = original.extractedEvidence!.toJson();
    var edited = await inbox.edit(original, reviewed(original.draft));
    expect(edited.extractedEvidence!.toJson(), extracted);
    await expectLater(
      inbox.edit(original, reviewed(original.draft)),
      throwsA(isA<ValidationError>()),
    );
    await inbox.expireRawText(now: receipt.add(const Duration(days: 31)));
    await db.close();
    db = AppDatabase.forTesting(NativeDatabase(file));
    repo = DriftInboxRepository(db);
    inbox = InboxUseCases(repo);
    edited = (await repo.listSuggestions()).single;
    expect(edited.extractedEvidence!.toJson(), extracted);
    expect(edited.draft.dateSource, TransactionDateSource.reviewer);
    expect(edited.draft.amount.minorUnits, 450);
    expect((await repo.listImports()).single.rawText, isEmpty);
    final entry = await inbox.confirm(
      suggestion: edited,
      account: bank,
      finance: DriftFinanceRepository(db),
    );
    expect(entry.type, AccountEntryType.income);
    expect(entry.amount.minorUnits, 450);
    final key = 'inbox_review_v1:${edited.id.value}';
    final metadata =
        jsonDecode((await db.readMetadata(key))!) as Map<String, dynamic>;
    expect(metadata['extractedEvidence'], extracted);
    final history = metadata['history'] as List;
    expect(history.map((h) => h['action']), ['edited', 'confirmed']);
    expect(history[0]['reviewed']['minorUnits'], 450);
    expect(history[1]['reviewed'], history[0]['reviewed']);
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
    expect(jsonDecode((await db.readMetadata(key))!), metadata);
    expect(
      (await repo.listSuggestions()).single.extractedEvidence!.toJson(),
      extracted,
    );
    expect(
      (await DriftFinanceRepository(db).listEntries()).single.amount.minorUnits,
      450,
    );
    expect((await repo.listImports()).single.rawText, isEmpty);
  });

  test('fresh transactional admission blocks unknown, transfer, bad unit/amount and stale confirmation', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = DriftInboxRepository(db);
    final inbox = InboxUseCases(repo);
    final finance = DriftFinanceRepository(db);
    final bank = account();
    await finance.saveAccount(bank);
    for (final type in ['unknown', 'transfer']) {
      final original = await inbox.stageSms(
        rawText: 'amount: 20 rial; type: $type',
        sourceKey: type,
        currency: 'IRR',
      );
      final forged = AccountEntry(
        id: StableId.generate(),
        accountId: bank.id,
        type: AccountEntryType.expense,
        amount: original.draft.amount,
        occurredAt: original.draft.occurredAt,
      );
      await expectLater(
        repo.confirmAtomically(suggestionId: original.id, entry: forged),
        throwsA(isA<ValidationError>()),
      );
      var edited = await inbox.edit(original, reviewed(original.draft));
      if (type == 'transfer') {
        await expectLater(
          inbox.confirm(suggestion: edited, account: bank, finance: finance),
          throwsA(isA<ValidationError>()),
        );
        await expectLater(
          repo.confirmAtomically(suggestionId: edited.id, entry: forged),
          throwsA(isA<ValidationError>()),
        );
      } else {
        final stale = edited;
        edited = await inbox.edit(edited, reviewed(edited.draft, amount: 451));
        await expectLater(
          inbox.confirm(suggestion: edited, account: bank, finance: finance),
          throwsA(isA<ValidationError>()),
        );
        await expectLater(
          inbox.confirm(suggestion: stale, account: bank, finance: finance),
          throwsA(isA<ValidationError>()),
        );
        edited = await inbox.edit(edited, reviewed(edited.draft));
        await db.customStatement(
          "CREATE TRIGGER fail_confirm BEFORE UPDATE ON staged_imports BEGIN SELECT RAISE(ABORT,'injected'); END",
        );
        await expectLater(
          inbox.confirm(suggestion: edited, account: bank, finance: finance),
          throwsA(anything),
        );
        expect(await finance.listEntries(), isEmpty);
        expect(
          (await repo.listSuggestions())
              .firstWhere((s) => s.id == edited.id)
              .revision,
          edited.revision,
        );
        await db.customStatement('DROP TRIGGER fail_confirm');
        await inbox.confirm(
          suggestion: edited,
          account: bank,
          finance: finance,
        );
      }
    }
    expect(await finance.listEntries(), hasLength(1));
  });

  test(
    'legacy v1 absent fields remain unknown on explicit edits and backup',
    () async {
      final dir = await Directory.systemTemp.createTemp('sms-legacy-');
      addTearDown(() => dir.delete(recursive: true));
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final repo = DriftInboxRepository(db);
      final inbox = InboxUseCases(repo);
      final original = await inbox.stageSms(
        rawText: 'amount: 20 toman; type: debit',
        sourceKey: 'legacy',
        currency: 'IRR',
      );
      final key = 'inbox_review_v1:${original.id.value}';
      await db.writeMetadata(
        key,
        jsonEncode({
          'version': 1,
          'revision': 0,
          'history': [
            {'action': 'old'},
          ],
        }),
      );
      final legacy = (await repo.listSuggestions()).single;
      expect(legacy.extractedEvidence, isNull);
      expect(legacy.draft.dateSource, TransactionDateSource.unknown);
      expect(legacy.draft.amount.minorUnits, 200);
      await inbox.edit(legacy, reviewed(legacy.draft));
      expect((await repo.listSuggestions()).single.extractedEvidence, isNull);
      final bytes = await sqliteBackupSnapshot(
        database: db,
        target: File('${dir.path}/snapshot.sqlite'),
        redact: true,
      );
      await db.close();
      final file = File('${dir.path}/restore.sqlite');
      await file.writeAsBytes(bytes);
      final restored = AppDatabase.forTesting(NativeDatabase(file));
      addTearDown(restored.close);
      final hydrated = (await DriftInboxRepository(
        restored,
      ).listSuggestions()).single;
      expect(hydrated.extractedEvidence, isNull);
      expect(hydrated.draft.amount.minorUnits, 450);
      final history =
          jsonDecode((await restored.readMetadata(key))!)['history'] as List;
      expect(history.first, {'action': 'old'});
      expect(history.last['reviewed']['dateSource'], 'reviewer');
      await restored.customStatement(
        'DELETE FROM schema_metadata WHERE key = ?',
        [key],
      );
      final missing = (await DriftInboxRepository(
        restored,
      ).listSuggestions()).single;
      expect(missing.extractedEvidence, isNull);
      expect(missing.revision, 0);
      expect(missing.draft.dateSource, TransactionDateSource.unknown);
      expect(missing.draft.amount.minorUnits, 450);
    },
  );
}
