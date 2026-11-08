import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/classification/application/tag_repository.dart';
import 'package:planact/features/classification/data/drift_tag_repository.dart';
import 'package:planact/features/finance/data/drift_finance_repository.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/inbox/application/inbox_use_cases.dart';
import 'package:planact/features/inbox/data/drift_inbox_repository.dart';

void main() {
  test('Inbox membership failure rolls back ledger, tags and review; retry reuses normalized labels', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final finance = DriftFinanceRepository(database);
    final repository = DriftInboxRepository(database);
    final inbox = InboxUseCases(repository);
    final tags = DriftTagRepository(database);
    final existing = await tags.getOrCreate('Work');
    final account = FinancialAccount(
      id: StableId.generate(),
      name: 'نقد',
      currency: 'IRR',
      type: FinancialAccountType.cash,
    );
    await finance.saveAccount(account);
    final suggestion = await inbox.stageSms(
      rawText: 'برداشت مبلغ ۲۵۰۰ rial\nتاریخ: 2026-09-20\nساعت: 12:30',
      sourceKey: 'sms:atomic-tags',
      currency: 'IRR',
    );
    final before = (await repository.listSuggestions()).single;
    await database.customStatement(
      "CREATE TRIGGER fail_tag BEFORE INSERT ON account_entry_tags BEGIN SELECT RAISE(ABORT, 'injected'); END",
    );
    Future<AccountEntry> confirm() => inbox.confirm(
      suggestion: suggestion,
      account: account,
      finance: finance,
      tags: {'#WORK', 'work', 'جدید'},
    );
    await expectLater(confirm(), throwsA(anything));
    expect(await finance.listEntries(), isEmpty);
    expect((await tags.list()).map((tag) => tag.id), [existing.id]);
    final after = (await repository.listSuggestions()).single;
    expect(after.status, before.status);
    expect(after.revision, before.revision);
    expect(
      await tags.recordsWithTag(existing.id, TaggableType.accountEntry),
      isEmpty,
    );
    await database.customStatement('DROP TRIGGER fail_tag');
    final entry = await confirm();
    expect(await tags.list(), hasLength(2));
    expect(
      await tags.tagsFor(entry.id.value, TaggableType.accountEntry),
      hasLength(2),
    );
    expect(await tags.recordsWithTag(existing.id, TaggableType.accountEntry), {
      entry.id.value,
    });
    await confirm();
    expect(await finance.listEntries(), hasLength(1));
    expect(await tags.list(), hasLength(2));
  });
}
