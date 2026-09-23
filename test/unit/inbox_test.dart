import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/errors/app_error.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/finance/application/finance_use_cases.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/inbox/application/inbox_use_cases.dart';
import 'package:planact/features/inbox/domain/inbox.dart';

void main() {
  test('stages a local SMS as a Persian explainable suggestion', () async {
    final inbox = InMemoryInboxRepository();
    final useCases = InboxUseCases(inbox);

    final suggestion = await useCases.stageSms(
      rawText: 'برداشت مبلغ ۱۲,۵۰۰ فروشگاه: نانوایی 2026-09-20 ref:abc',
      sourceKey: 'sms-1',
      currency: 'IRR',
      importedAt: DateTime.utc(2026, 9, 21),
    );

    expect(suggestion.draft.amount.minorUnits, 12500);
    expect(suggestion.draft.merchant, 'نانوایی 2026-09-20 ref:abc');
    expect(suggestion.status, SuggestionStatus.pending);
    expect((await inbox.listImports()).single.status, StagedItemStatus.pending);
  });

  test(
    'rejects duplicate raw source without creating a second suggestion',
    () async {
      final inbox = InMemoryInboxRepository();
      final useCases = InboxUseCases(inbox);
      const raw = 'amount 1000 2026-09-20';

      await useCases.stageSms(
        rawText: raw,
        sourceKey: 'sms-1',
        currency: 'IRR',
      );

      expect(
        () => useCases.stageSms(
          rawText: raw,
          sourceKey: 'sms-2',
          currency: 'IRR',
        ),
        throwsA(isA<ValidationError>()),
      );
      expect(await inbox.listSuggestions(), hasLength(1));
    },
  );

  test(
    'confirm mutates the finance ledger only after explicit confirmation',
    () async {
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
        rawText: 'amount 2500 2026-09-20',
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
    },
  );

  test('reject preserves staging history and does not write ledger', () async {
    final inbox = InMemoryInboxRepository();
    final finance = InMemoryFinanceRepository();
    final useCases = InboxUseCases(inbox);
    final suggestion = await useCases.stageSms(
      rawText: 'amount 2500 2026-09-20',
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
      rawText: 'amount 2500 2026-09-20',
      sourceKey: 'sms-1',
      currency: 'IRR',
    );
    final editedDraft = TransactionDraft(
      id: suggestion.draft.id,
      stagedImportId: suggestion.stagedImportId,
      amount: const Money(minorUnits: 3000, currency: 'IRR'),
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

  test(
    'reject then rollback preserves the staged import as historical data',
    () async {
      final inbox = InMemoryInboxRepository();
      final useCases = InboxUseCases(inbox);
      final suggestion = await useCases.stageSms(
        rawText: 'amount 2500 2026-09-20',
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
        SuggestionStatus.rejected,
      );
    },
  );

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
      rawText: 'amount 2500 2026-09-20',
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
}
