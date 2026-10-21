import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/errors/app_error.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/finance/application/finance_use_cases.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/inbox/application/inbox_use_cases.dart';
import 'package:planact/features/inbox/domain/inbox.dart';
import 'package:planact/features/inbox/domain/sms_currency_evidence.dart';

void main() {
  test(
    'review unit proposal converts exactly and protects earlier evidence',
    () {
      TransactionDraft draft({SmsCurrencyEvidence? evidence}) =>
          TransactionDraft(
            id: StableId.generate(),
            stagedImportId: StableId.generate(),
            amount: const Money(minorUnits: 123, currency: 'IRR'),
            occurredAt: DateTime.utc(2026, 10, 14, 12, 30),
            type: 'expense',
            merchant: 'شرح',
            currencyEvidence: evidence,
          );
      final original = draft(
        evidence: const SmsCurrencyEvidence(sourceAmount: 123),
      );
      final selected = original.selectUnresolvedCurrency(SmsMoneyUnit.toman);
      expect(selected.amount, const Money(minorUnits: 1230, currency: 'IRR'));
      expect(selected.occurredAt, original.occurredAt);
      expect(selected.merchant, original.merchant);
      expect(original.currencyEvidence!.requiresSelection, isTrue);
      for (final protected in [
        selected,
        draft(),
        draft(
          evidence: const SmsCurrencyEvidence(
            sourceAmount: 123,
            detectedUnit: SmsMoneyUnit.rial,
          ),
        ),
      ]) {
        expect(
          () => protected.selectUnresolvedCurrency(SmsMoneyUnit.toman),
          throwsA(isA<ValidationError>()),
        );
      }
      expect(
        () => draft(
          evidence: const SmsCurrencyEvidence(sourceAmount: 922337203685477581),
        ).selectUnresolvedCurrency(SmsMoneyUnit.toman),
        throwsA(isA<ValidationError>()),
      );
    },
  );

  test('stages a local SMS as a Persian explainable suggestion', () async {
    final inbox = InMemoryInboxRepository();
    final useCases = InboxUseCases(inbox);

    final suggestion = await useCases.stageSms(
      rawText: 'برداشت مبلغ ۱۲,۵۰۰\nفروشگاه: نانوایی\nتاریخ: 2026-09-20\nساعت: 12:30\nref:abc',
      sourceKey: 'sms-1',
      currency: 'IRR',
      importedAt: DateTime.utc(2026, 9, 21),
    );

    expect(suggestion.draft.amount.minorUnits, 12500);
    expect(suggestion.draft.merchant, 'نانوایی');
    expect(suggestion.status, SuggestionStatus.pending);
    expect((await inbox.listImports()).single.status, StagedItemStatus.pending);
  });

  test('parses incoming Persian SMS as income without fabricating direction', () {
    final parsed = const LocalSmsParser().parse(
      text:
          'واریز مبلغ: ۱۲،۵۰۰\nبانک: نمونه\nتاریخ: 2026-09-20\nکارت: ****1234',
      currency: 'IRR',
    );
    expect(parsed.amount.minorUnits, 12500);
    expect(parsed.direction, TransactionDirection.incoming);
    expect(parsed.accountHint, '****1234');
  });

  test('supports duplicate source keys after a rescan', () async {
    final inbox = InMemoryInboxRepository();
    final useCases = InboxUseCases(inbox);
    final first = await useCases.stageSms(
      rawText:
          'type: withdrawal\namount: 1000 rial\ndate: 2026-09-20\ntime: 12:30',
      sourceKey: 'android-sms:42',
      currency: 'IRR',
    );
    final second = await useCases.stageSms(
      rawText:
          'type: withdrawal\namount: 1000 rial\ndate: 2026-09-20\ntime: 12:30',
      sourceKey: 'android-sms:42',
      currency: 'IRR',
    );
    expect(second.id, first.id);
    expect(await inbox.listSuggestions(), hasLength(1));
  });

  test(
    'allows identical raw text from distinct source rows as separate suggestions',
    () async {
      final inbox = InMemoryInboxRepository();
      final useCases = InboxUseCases(inbox);
      const raw =
          'type: withdrawal\namount: 1000 rial\ndate: 2026-09-20\ntime: 12:30';

      final first = await useCases.stageSms(
        rawText: raw,
        sourceKey: 'sms-1',
        currency: 'IRR',
      );
      final second = await useCases.stageSms(
        rawText: raw,
        sourceKey: 'sms-2',
        currency: 'IRR',
      );

      expect(second.id, isNot(first.id));
      expect(second.stagedImportId, isNot(first.stagedImportId));
      expect(await inbox.listSuggestions(), hasLength(2));
    },
  );

  test('confirm mutates the finance ledger only after explicit confirmation', () async {
    final inbox = InMemoryInboxRepository();
    final finance = InMemoryFinanceRepository();
    final useCases = InboxUseCases(inbox);
    final account = FinancialAccount(
      id: StableId.generate(),
      name: 'بانک',
      currency: 'IRR',
      type: FinancialAccountType.bank,
    );
    await finance.saveAccount(account);
    final suggestion = await useCases.stageSms(
      rawText:
          'type: withdrawal\namount: 2500 rial\ndate: 2026-09-20\ntime: 12:30',
      sourceKey: 'sms-1',
      currency: 'IRR',
    );

    expect(await finance.listEntries(), isEmpty);
    await useCases.confirm(
      suggestion: suggestion,
      account: account,
      finance: finance,
    );

    expect(await finance.listEntries(), hasLength(1));
    expect(
      (await inbox.listSuggestions()).single.status,
      SuggestionStatus.confirmed,
    );
    expect(
      (await inbox.listImports()).single.status,
      StagedItemStatus.confirmed,
    );
  });

  test('reject preserves staging history and does not write ledger', () async {
    final inbox = InMemoryInboxRepository();
    final finance = InMemoryFinanceRepository();
    final useCases = InboxUseCases(inbox);
    final suggestion = await useCases.stageSms(
      rawText:
          'type: withdrawal\namount: 2500 rial\ndate: 2026-09-20\ntime: 12:30',
      sourceKey: 'sms-1',
      currency: 'IRR',
    );

    await useCases.reject(suggestion);

    expect(await finance.listEntries(), isEmpty);
    expect(
      (await inbox.listSuggestions()).single.status,
      SuggestionStatus.rejected,
    );
    expect(
      (await inbox.listImports()).single.status,
      StagedItemStatus.rejected,
    );
  });

  test('edits a pending draft without touching the finance ledger', () async {
    final inbox = InMemoryInboxRepository();
    final useCases = InboxUseCases(inbox);
    final suggestion = await useCases.stageSms(
      rawText:
          'type: withdrawal\namount: 2500 rial\ndate: 2026-09-20\ntime: 12:30',
      sourceKey: 'sms-1',
      currency: 'IRR',
    );
    final editedDraft = TransactionDraft(
      id: suggestion.draft.id,
      stagedImportId: suggestion.stagedImportId,
      amount: const Money(minorUnits: 3000, currency: 'IRR'),
      currencyEvidence: suggestion.draft.currencyEvidence,
      occurredAt: suggestion.draft.occurredAt,
      type: 'expense',
      merchant: 'فروشگاه ویرایش‌شده',
      reference: 'edited-ref',
    );

    final edited = await useCases.edit(suggestion, editedDraft);

    expect(edited.status, SuggestionStatus.edited);
    expect(edited.draft.amount.minorUnits, 3000);
    expect(
      (await inbox.listSuggestions()).single.draft.merchant,
      'فروشگاه ویرایش‌شده',
    );
  });

  test('reject then rollback preserves the staged import as historical data', () async {
    final inbox = InMemoryInboxRepository();
    final useCases = InboxUseCases(inbox);
    final suggestion = await useCases.stageSms(
      rawText:
          'type: withdrawal\namount: 2500 rial\ndate: 2026-09-20\ntime: 12:30',
      sourceKey: 'sms-1',
      currency: 'IRR',
    );

    await useCases.reject(suggestion);
    await useCases.rollback(suggestion);

    expect(await inbox.listImports(), hasLength(1));
    expect(
      (await inbox.listImports()).single.status,
      StagedItemStatus.rolledBack,
    );
    expect(
      (await inbox.listSuggestions()).single.status,
      SuggestionStatus.pending,
    );
  });

  test('does not confirm an already confirmed suggestion twice', () async {
    final inbox = InMemoryInboxRepository();
    final finance = InMemoryFinanceRepository();
    final useCases = InboxUseCases(inbox);
    final account = FinancialAccount(
      id: StableId.generate(),
      name: 'بانک',
      currency: 'IRR',
      type: FinancialAccountType.bank,
    );
    await finance.saveAccount(account);
    final suggestion = await useCases.stageSms(
      rawText:
          'type: withdrawal\namount: 2500 rial\ndate: 2026-09-20\ntime: 12:30',
      sourceKey: 'sms-1',
      currency: 'IRR',
    );

    await useCases.confirm(
      suggestion: suggestion,
      account: account,
      finance: finance,
    );
    final stored = (await inbox.listSuggestions()).single;

    expect(
      () => useCases.confirm(
        suggestion: stored,
        account: account,
        finance: finance,
      ),
      throwsA(isA<ValidationError>()),
    );
    expect(await finance.listEntries(), hasLength(1));
  });

  test('expires raw text while preserving fingerprint and decision metadata', () async {
    final inbox = InMemoryInboxRepository();
    final useCases = InboxUseCases(inbox);
    final importedAt = DateTime.utc(2026, 1, 1);
    await useCases.stageSms(
      rawText:
          'type: withdrawal\namount: 1000 rial\ndate: 2026-01-01\ntime: 12:30',
      sourceKey: 'sms-retention',
      currency: 'IRR',
      importedAt: importedAt,
    );

    await useCases.expireRawText(now: importedAt.add(const Duration(days: 31)));
    final stored = (await inbox.listImports()).single;
    expect(stored.rawText, isEmpty);
    expect(stored.fingerprint, isNotEmpty);
    expect(stored.retentionStatus, RawTextRetentionStatus.expired);
    expect(stored.retentionUntil, importedAt.add(const Duration(days: 30)));
  });
}
