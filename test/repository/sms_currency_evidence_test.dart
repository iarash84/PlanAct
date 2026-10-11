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

void main() {
  const parser = LocalSmsParser();
  for (final token in [
    'ریال',
    'rial',
    'RIALS',
    'IRR',
    'تومان',
    'toman',
    'TOMANS',
  ]) {
    test(
      'amount-bound $token produces canonical IRR independently of caller',
      () {
        final parsed = parser.parse(
          text: 'برداشت مبلغ ۱۲۳،۴۵۶ $token\nمانده 990 تومان',
          currency: 'USD',
        );
        final toman = ['تومان', 'toman', 'TOMANS'].contains(token);
        expect(
          parsed.amount,
          Money(minorUnits: toman ? 1234560 : 123456, currency: 'IRR'),
        );
        expect(
          parsed.currencyEvidence!.detectedUnit,
          toman ? SmsMoneyUnit.toman : SmsMoneyUnit.rial,
        );
        expect(parsed.currencyEvidence!.sourceAmount, 123456);
      },
    );
  }
  for (final text in [
    'برداشت مبلغ 2500\nمانده 5000 تومان',
    'withdrawal amount 2500 balance: 5000 rial',
    'برداشت مبلغ 2500 ریال/تومان',
    'withdrawal amount rial 2500 toman',
    'برداشت مبلغ 2500',
    'withdrawal amount 2500 tomanAccount',
  ]) {
    test('ambiguous/misleading evidence remains unresolved: $text', () {
      final parsed = parser.parse(text: text, currency: 'IRR');
      expect(parsed.amount.minorUnits, 2500);
      expect(parsed.currencyEvidence!.requiresSelection, isTrue);
    });
  }
  test(
    'Arabic digits and prefix units are supported; exact overflow rejected',
    () {
      expect(
        parser
            .parse(text: 'amount toman ١٢٣', currency: 'IRR')
            .amount
            .minorUnits,
        1230,
      );
      expect(
        SmsMoneyUnit.toman.canonicalIrr(922337203685477580),
        9223372036854775800,
      );
      expect(
        () => SmsMoneyUnit.toman.canonicalIrr(922337203685477581),
        throwsA(isA<ValidationError>()),
      );
    },
  );

  test(
    'unresolved admission, explicit selection, cold reopen and redacted backup',
    () async {
      final dir = await Directory.systemTemp.createTemp('sms-currency-');
      addTearDown(() => dir.delete(recursive: true));
      final file = File('${dir.path}/live.sqlite');
      var database = AppDatabase.forTesting(NativeDatabase(file));
      var repository = DriftInboxRepository(database);
      var inbox = InboxUseCases(repository);
      final finance = DriftFinanceRepository(database);
      final account = FinancialAccount(
        id: StableId.generate(),
        name: 'نقد',
        currency: 'IRR',
        type: FinancialAccountType.cash,
      );
      await finance.saveAccount(account);
      var suggestion = await inbox.stageSms(
        rawText: 'برداشت مبلغ 2500\nمانده 900 تومان',
        sourceKey: '1',
        currency: 'IRR',
      );
      await expectLater(
        inbox.confirm(
          suggestion: suggestion,
          account: account,
          finance: finance,
        ),
        throwsA(isA<ValidationError>()),
      );
      final entry = AccountEntry(
        id: StableId.generate(),
        accountId: account.id,
        type: AccountEntryType.expense,
        amount: suggestion.draft.amount,
        occurredAt: suggestion.draft.occurredAt,
      );
      await expectLater(
        repository.confirmAtomically(suggestionId: suggestion.id, entry: entry),
        throwsA(isA<ValidationError>()),
      );
      final old = suggestion.draft;
      suggestion = await inbox.edit(
        suggestion,
        TransactionDraft(
          id: old.id,
          stagedImportId: old.stagedImportId,
          amount: Money(
            minorUnits: SmsMoneyUnit.toman.canonicalIrr(
              old.currencyEvidence!.sourceAmount,
            ),
            currency: 'IRR',
          ),
          occurredAt: old.occurredAt,
          type: old.type,
          currencyEvidence: old.currencyEvidence!.select(SmsMoneyUnit.toman),
        ),
      );
      await database.close();
      database = AppDatabase.forTesting(NativeDatabase(file));
      repository = DriftInboxRepository(database);
      inbox = InboxUseCases(repository);
      suggestion = (await repository.listSuggestions()).single;
      expect(suggestion.draft.amount.minorUnits, 25000);
      expect(
        suggestion.draft.currencyEvidence!.selectedUnit,
        SmsMoneyUnit.toman,
      );
      expect(suggestion.draft.currencyEvidence!.sourceAmount, 2500);
      final bytes = await sqliteBackupSnapshot(
        database: database,
        target: File('${dir.path}/snapshot.sqlite'),
        redact: true,
      );
      await database.close();
      final restored = File('${dir.path}/restored.sqlite');
      await restored.writeAsBytes(bytes);
      database = AppDatabase.forTesting(NativeDatabase(restored));
      addTearDown(database.close);
      repository = DriftInboxRepository(database);
      suggestion = (await repository.listSuggestions()).single;
      expect((await repository.listImports()).single.rawText, isEmpty);
      expect(
        suggestion.draft.currencyEvidence!.selectedUnit,
        SmsMoneyUnit.toman,
      );
      final confirmed = await InboxUseCases(repository).confirm(
        suggestion: suggestion,
        account: account,
        finance: DriftFinanceRepository(database),
      );
      expect(confirmed.amount.minorUnits, 25000);
    },
  );

  test(
    'detected units survive hydration without duplicate conversion',
    () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      final repository = DriftInboxRepository(database);
      final inbox = InboxUseCases(repository);
      for (final unit in ['rial', 'toman']) {
        await inbox.stageSms(
          rawText: 'amount 100 $unit',
          sourceKey: unit,
          currency: 'USD',
        );
      }
      final rows = await DriftInboxRepository(database).listSuggestions();
      expect(rows.map((s) => s.draft.amount.minorUnits), [100, 1000]);
      expect(rows.map((s) => s.draft.currencyEvidence!.detectedUnit), [
        SmsMoneyUnit.rial,
        SmsMoneyUnit.toman,
      ]);
      expect(
        rows.every((s) => s.draft.currencyEvidence!.selectedUnit == null),
        isTrue,
      );
    },
  );

  test('legacy absent evidence never reparses raw toman or reinterprets stored amount', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = DriftInboxRepository(database);
    final inbox = InboxUseCases(repository);
    final suggestion = await inbox.stageSms(
      rawText: 'برداشت مبلغ 800 تومان',
      sourceKey: 'legacy',
      currency: 'IRR',
    );
    await database.customStatement(
      'DELETE FROM schema_metadata WHERE key = ?',
      ['inbox_review_v1:${suggestion.id.value}'],
    );
    // A pre-evidence parser stored the numeric token as IRR even when the raw
    // text said toman. Upgrade must preserve that historical value, not fix it.
    await database.customStatement(
      'UPDATE inbox_suggestions SET minor_units = 800 WHERE id = ?',
      [suggestion.id.value],
    );
    final legacy = (await repository.listSuggestions()).single;
    expect(legacy.draft.currencyEvidence, isNull);
    expect(legacy.draft.amount.minorUnits, 800);
    final replay = await inbox.stageSms(
      rawText: 'برداشت مبلغ 800 تومان',
      sourceKey: 'legacy',
      currency: 'IRR',
    );
    expect(replay.draft.currencyEvidence, isNull);
    expect(replay.draft.amount.minorUnits, 800);
  });
}
