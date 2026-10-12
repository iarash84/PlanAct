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

import '../fixtures/real_bank_sms.dart';

void main() {
  test('all 18 stage, replay, cold reopen and redacted production backup preserve evidence without ledger writes', () async {
    final dir = await Directory.systemTemp.createTemp('real-sms-');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/live.sqlite');
    var db = AppDatabase.forTesting(NativeDatabase(file));
    var repo = DriftInboxRepository(db);
    var inbox = InboxUseCases(repo);
    final receipt = DateTime.utc(2026, 10, 1, 12);
    final originals = <Map<String, Object?>>[];
    for (var i = 0; i < realBankSms.length; i++) {
      final suggestion = await inbox.stageSms(
        rawText: realBankSms[i],
        sourceKey: 'corpus-$i',
        currency: 'IRR',
        importedAt: receipt,
      );
      originals.add(suggestion.extractedEvidence!.toJson());
      expect(suggestion.draft.amount.minorUnits, realBankAmounts[i]);
      expect(suggestion.draft.bank, realBankNames[i]);
      expect(
        suggestion.draft.dateSource,
        [0, 1, 12, 13, 14].contains(i)
            ? TransactionDateSource.extracted
            : TransactionDateSource.receipt,
      );
      final replay = await inbox.stageSms(
        rawText: realBankSms[i],
        sourceKey: 'corpus-$i',
        currency: 'IRR',
        importedAt: receipt,
      );
      expect(replay.id, suggestion.id);
      expect(replay.extractedEvidence!.toJson(), originals.last);
    }
    expect(await DriftFinanceRepository(db).listEntries(), isEmpty);
    await db.close();
    db = AppDatabase.forTesting(NativeDatabase(file));
    repo = DriftInboxRepository(db);
    inbox = InboxUseCases(repo);
    var suggestions = await repo.listSuggestions();
    expect(suggestions, hasLength(18));
    for (var i = 0; i < 18; i++) {
      final item = suggestions.singleWhere(
        (s) =>
            s.extractedEvidence!.draft.amount.minorUnits ==
                realBankAmounts[i] &&
            s.extractedEvidence!.sourceTime ==
                const LocalSmsParser()
                    .parse(text: realBankSms[i], currency: 'IRR')
                    .sourceTime,
      );
      expect(item.extractedEvidence!.toJson(), originals[i]);
    }
    final transfer = suggestions.singleWhere(
      (s) => s.extractedEvidence!.isTransfer,
    );
    final old = transfer.draft;
    final edited = await inbox.edit(
      transfer,
      TransactionDraft(
        id: old.id,
        stagedImportId: old.stagedImportId,
        amount: old.amount,
        occurredAt: receipt,
        type: 'income',
        direction: TransactionDirection.incoming,
        dateSource: TransactionDateSource.reviewer,
        currencyEvidence: SmsCurrencyEvidence(
          sourceAmount: old.amount.minorUnits,
          selectedUnit: SmsMoneyUnit.rial,
        ),
      ),
    );
    final finance = DriftFinanceRepository(db);
    final account = FinancialAccount(
      id: StableId.generate(),
      name: 'نمونه',
      currency: 'IRR',
      type: FinancialAccountType.bank,
    );
    await finance.saveAccount(account);
    await expectLater(
      inbox.confirm(suggestion: edited, account: account, finance: finance),
      throwsA(isA<ValidationError>()),
    );
    await expectLater(
      repo.confirmAtomically(
        suggestionId: edited.id,
        entry: AccountEntry(
          id: StableId.generate(),
          accountId: account.id,
          type: AccountEntryType.income,
          amount: old.amount,
          occurredAt: receipt,
        ),
      ),
      throwsA(isA<ValidationError>()),
    );
    expect(await finance.listEntries(), isEmpty);
    final beforeBackup = {
      for (final s in await repo.listSuggestions())
        s.id.value: s.extractedEvidence!.toJson(),
    };
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
    suggestions = await repo.listSuggestions();
    expect({
      for (final s in suggestions) s.id.value: s.extractedEvidence!.toJson(),
    }, beforeBackup);
    expect((await repo.listImports()).every((s) => s.rawText.isEmpty), isTrue);
    expect(await DriftFinanceRepository(db).listEntries(), isEmpty);
    expect(
      suggestions.singleWhere((s) => s.id == edited.id).revision,
      edited.revision,
    );
  });
}
