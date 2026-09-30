import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/finance/application/finance_use_cases.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/inbox/application/inbox_review_projection.dart';
import 'package:planact/features/inbox/application/inbox_use_cases.dart';

void main() {
  test(
    'projects source, deterministic reason, account and duplicate warning',
    () async {
      final inboxRepository = InMemoryInboxRepository();
      final finance = InMemoryFinanceRepository();
      final account = FinancialAccount(
        id: StableId.generate(),
        name: 'حساب بانک',
        currency: 'IRR',
        type: FinancialAccountType.bank,
      );
      await finance.saveAccount(account);
      await finance.saveEntry(
        AccountEntry(
          id: StableId.generate(),
          accountId: account.id,
          type: AccountEntryType.expense,
          amount: const Money(minorUnits: 1000, currency: 'IRR'),
          occurredAt: DateTime.utc(2026, 9, 20),
        ),
      );
      final useCases = InboxUseCases(inboxRepository);
      await useCases.stageSms(
        rawText: 'برداشت مبلغ 1000 2026-09-20',
        sourceKey: 'sms-1',
        currency: 'IRR',
      );

      final items = const InboxReviewProjection().build(
        suggestions: await inboxRepository.listSuggestions(),
        imports: await inboxRepository.listImports(),
        accounts: await finance.listAccounts(),
        entries: await finance.listEntries(),
      );

      expect(items, hasLength(1));
      expect(items.single.sourceLabel, 'پیامک بانکی');
      expect(items.single.account, account);
      expect(
        items.single.reasons,
        contains('مبلغ و جهت تراکنش از متن پیامک بانکی تشخیص داده شد'),
      );
      expect(
        items.single.warnings,
        contains('تراکنش دیگری با همین مبلغ و نوع قبلاً ثبت شده است'),
      );
    },
  );

  test('confirmation failure does not resolve pending review', () async {
    final inboxRepository = InMemoryInboxRepository();
    final finance = InMemoryFinanceRepository();
    final useCases = InboxUseCases(inboxRepository);
    final suggestion = await useCases.stageSms(
      rawText: 'amount 1000 2026-09-20',
      sourceKey: 'sms-1',
      currency: 'IRR',
    );
    final archived = FinancialAccount(
      id: StableId.generate(),
      name: 'بایگانی',
      currency: 'IRR',
      type: FinancialAccountType.bank,
      status: FinancialAccountStatus.archived,
    );

    expect(
      () => useCases.confirm(
        suggestion: suggestion,
        account: archived,
        finance: finance,
      ),
      throwsA(isA<Exception>()),
    );
    expect((await inboxRepository.listSuggestions()).single.status.index, 0);
    expect(await finance.listEntries(), isEmpty);
  });
}
