import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/classification/application/tag_repository.dart';
import 'package:planact/features/classification/data/drift_tag_repository.dart';
import 'package:planact/features/finance/application/finance_use_cases.dart';
import 'package:planact/features/finance/data/drift_finance_repository.dart';
import 'package:planact/features/finance/domain/finance.dart';

void main() {
  test('tag copy failure rolls back money, journal and memberships; retry succeeds', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = DriftFinanceRepository(database);
    final commands = FinanceUseCases(repository);
    final account = FinancialAccount(
      id: StableId.generate(),
      name: 'حساب',
      currency: 'IRR',
      type: FinancialAccountType.cash,
    );
    await commands.createAccount(account);
    final original = await commands.record(
      account: account,
      type: AccountEntryType.expense,
      amount: const Money(minorUnits: 100, currency: 'IRR'),
      occurredAt: DateTime.utc(2026, 11),
      note: 'شرح قبلی',
      category: 'دسته قبلی',
      tags: {'برچسب'},
    );
    final tags = DriftTagRepository(database);
    final originalTags = await tags.tagsFor(
      original.id.value,
      TaggableType.accountEntry,
    );
    final metadataBefore = await database.select(database.schemaMetadata).get();
    await database.customStatement('''
      CREATE TRIGGER fail_correction_tag BEFORE INSERT ON account_entry_tags
      BEGIN SELECT RAISE(ABORT, 'injected tag copy failure'); END
    ''');
    Future<AccountEntry> correct() => commands.correctEntry(
      original: original,
      account: account,
      type: AccountEntryType.expense,
      amount: const Money(minorUnits: 200, currency: 'IRR'),
      occurredAt: original.occurredAt,
      note: null,
    );
    await expectLater(correct(), throwsA(anything));
    expect((await repository.listEntries()).map((e) => e.id), [original.id]);
    expect((await commands.balance(account)).minorUnits, -100);
    expect(
      await tags.tagsFor(original.id.value, TaggableType.accountEntry),
      originalTags,
    );
    expect(
      await database.select(database.schemaMetadata).get(),
      metadataBefore,
    );
    await database.customStatement('DROP TRIGGER fail_correction_tag');
    final replacement = await correct();
    expect(replacement.category, 'دسته قبلی');
    expect(replacement.note, isNull);
    expect(
      (await repository.listEntries())
          .singleWhere((e) => e.id == original.id)
          .note,
      'شرح قبلی',
    );
    expect(
      await tags.tagsFor(replacement.id.value, TaggableType.accountEntry),
      originalTags,
    );
    expect((await commands.balance(account)).minorUnits, -200);
  });
}
