import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/classification/application/tag_repository.dart';
import 'package:planact/features/classification/data/drift_tag_repository.dart';
import 'package:planact/features/commitments/application/commitment_plan_use_case.dart';
import 'package:planact/features/commitments/data/drift_commitment_plan_repository.dart';
import 'package:planact/features/commitments/data/drift_commitment_repository.dart';
import 'package:planact/features/finance/application/finance_use_cases.dart';
import 'package:planact/features/finance/data/drift_finance_repository.dart';
import 'package:planact/features/finance/domain/finance.dart';

void main() {
  test(
    'created commitment and expense share normalized tags after restart',
    () async {
      final directory = await Directory.systemTemp.createTemp('tagged-create-');
      final file = File('${directory.path}/app.sqlite');
      var database = AppDatabase.forTesting(NativeDatabase(file));
      try {
        final plan =
            await CreateCommitmentPlan(
              commitments: DriftCommitmentRepository(database),
              plans: DriftCommitmentPlanRepository(database),
            )(
              title: 'کلاس',
              startAt: DateTime(2027, 1, 2, 18),
              tags: {' #Work ', 'خانه'},
            );
        final finance = DriftFinanceRepository(database);
        final account = FinancialAccount(
          id: StableId.generate(),
          name: 'نقد',
          currency: 'IRR',
          type: FinancialAccountType.cash,
        );
        await finance.saveAccount(account);
        final entry = await FinanceUseCases(finance).record(
          account: account,
          type: AccountEntryType.expense,
          amount: const Money(minorUnits: 100, currency: 'IRR'),
          occurredAt: DateTime.utc(2026, 10, 6),
          tags: {'work', '#WORK', 'خانه'},
        );
        final ids = await DriftTagRepository(database)
            .tagsFor(plan.commitment.id.value, TaggableType.commitment);
        await database.close();
        database = AppDatabase.forTesting(NativeDatabase(file));
        final tags = DriftTagRepository(database);
        expect(await tags.list(), hasLength(2));
        expect(
          await tags.tagsFor(entry.id.value, TaggableType.accountEntry),
          ids,
        );
        expect(
          (await DriftCommitmentRepository(database)
                  .findById(plan.commitment.id))!
              .tags,
          {'Work', 'خانه'},
        );
        expect(
          await DriftCommitmentPlanRepository(database)
              .findByCommitmentId(plan.commitment.id),
          isNotNull,
        );
        final entries = await DriftFinanceRepository(database).listEntries();
        expect(entries.single.id, entry.id);
        expect(rebuildBalance(account, entries).minorUnits, -100);
      } finally {
        await database.close();
        await directory.delete(recursive: true);
      }
    },
  );

  for (final commitment in [false, true]) {
    test('membership failure rolls back creation and new labels ($commitment)', () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      final finance = DriftFinanceRepository(database);
      final account = FinancialAccount(
        id: StableId.generate(),
        name: 'نقد',
        currency: 'IRR',
        type: FinancialAccountType.cash,
      );
      await finance.saveAccount(account);
      final table = commitment ? 'commitment_tags' : 'account_entry_tags';
      await database.customStatement(
        'CREATE TRIGGER reject_tag BEFORE INSERT ON $table BEGIN SELECT RAISE(ABORT, \'injected\'); END',
      );
      Future<Object?> create() => commitment
          ? CreateCommitmentPlan(
              commitments: DriftCommitmentRepository(database),
              plans: DriftCommitmentPlanRepository(database),
            )(title: 'کلاس', startAt: DateTime(2027, 1, 2, 18), tags: {'جدید'})
          : FinanceUseCases(finance).record(
              account: account,
              type: AccountEntryType.expense,
              amount: const Money(minorUnits: 100, currency: 'IRR'),
              occurredAt: DateTime.utc(2026),
              tags: {'جدید'},
            );
      await expectLater(create(), throwsA(anything));
      expect(await DriftTagRepository(database).list(), isEmpty);
      expect(await finance.listEntries(), isEmpty);
      expect(await DriftCommitmentRepository(database).list(), isEmpty);
      expect(await database.select(database.occurrences).get(), isEmpty);
      await database.customStatement('DROP TRIGGER reject_tag');
      await create();
      expect(await DriftTagRepository(database).list(), hasLength(1));
      expect(
        commitment
            ? (await DriftCommitmentRepository(database).list()).length
            : (await finance.listEntries()).length,
        1,
      );
    });
  }

  test(
    'unsupported atomic adapter rejects tags before creating entry',
    () async {
      final repository = InMemoryFinanceRepository();
      final account = FinancialAccount(
        id: StableId.generate(),
        name: 'نقد',
        currency: 'IRR',
        type: FinancialAccountType.cash,
      );
      await expectLater(
        FinanceUseCases(repository).record(
          account: account,
          type: AccountEntryType.expense,
          amount: const Money(minorUnits: 100, currency: 'IRR'),
          occurredAt: DateTime.utc(2026),
          tags: {'خانه'},
        ),
        throwsStateError,
      );
      expect(await repository.listEntries(), isEmpty);
    },
  );
}
