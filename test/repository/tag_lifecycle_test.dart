import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/actuals/data/drift_actual_repository.dart';
import 'package:planact/features/actuals/domain/actual.dart';
import 'package:planact/features/classification/application/tag_repository.dart';
import 'package:planact/features/classification/data/drift_tag_repository.dart';
import 'package:planact/features/commitments/application/commitment_plan_use_case.dart';
import 'package:planact/features/commitments/data/drift_commitment_plan_repository.dart';
import 'package:planact/features/commitments/data/drift_commitment_repository.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/finance/data/drift_finance_repository.dart';
import 'package:planact/features/finance/domain/finance.dart';

void main() {
  test('file restart preserves typed links/history and prevents legacy resurrection or stale saves', () async {
    final directory = await Directory.systemTemp.createTemp('tag-lifecycle-');
    final file = File('${directory.path}/app.sqlite');
    var database = AppDatabase.forTesting(NativeDatabase(file));
    try {
      var commitments = DriftCommitmentRepository(database);
      final plan = await CreateCommitmentPlan(
        commitments: commitments,
        plans: DriftCommitmentPlanRepository(database),
      )(title: 'کلاس', startAt: DateTime(2027, 1, 2, 18), tags: {'Work'});
      final stale = (await commitments.findById(plan.commitment.id))!;
      await DriftActualRepository(database).recordOccurrenceActual(
        expected: plan.occurrences.single,
        outcome: ActualOutcome.completed,
        recordedAt: DateTime.utc(2026, 10, 6),
      );
      await commitments.save(stale.archive());
      final other = Commitment.create(title: 'دیگر');
      await commitments.save(other);
      final finance = DriftFinanceRepository(database);
      final account = FinancialAccount(
        id: StableId.generate(),
        name: 'حساب',
        currency: 'IRR',
        type: FinancialAccountType.bank,
      );
      await finance.saveAccount(account);
      final entry = AccountEntry(
        id: StableId.generate(),
        accountId: account.id,
        type: AccountEntryType.expense,
        amount: Money(minorUnits: 1200, currency: 'IRR'),
        occurredAt: DateTime.utc(2026, 10, 6),
      );
      await finance.saveEntry(entry);
      var tags = DriftTagRepository(database);
      final work = await tags.getOrCreate('work');
      final retained = await tags.getOrCreate('آموزش');
      await tags.attach(
        recordId: entry.id.value,
        tag: work,
        type: TaggableType.accountEntry,
      );
      await tags.attach(
        recordId: other.id.value,
        tag: retained,
        type: TaggableType.commitment,
      );
      await tags.attach(
        recordId: stale.id.value,
        tag: retained,
        type: TaggableType.commitment,
      );
      final beforeHistory = (await database.select(database.actuals).get())
          .map((row) => row.toJson())
          .toList();
      final beforeOccurrences =
          (await database.select(database.occurrences).get())
              .map((row) => row.toJson())
              .toList();
      final beforeEntries =
          (await database.select(database.accountEntries).get())
              .map((row) => row.toJson())
              .toList();
      final renamed = await tags.rename(work.id, 'Office');
      await database.close();
      database = AppDatabase.forTesting(NativeDatabase(file));
      tags = DriftTagRepository(database);
      commitments = DriftCommitmentRepository(database);
      final persistedRename = await tags.getOrCreate('Office');
      expect(persistedRename.id, work.id);
      expect(persistedRename.createdAt, work.createdAt);
      expect(await tags.tagsFor(entry.id.value, TaggableType.accountEntry), {
        work.id,
      });
      // Stale metadata saves preserve canonical links, including newly attached tags.
      await commitments.save(stale.archive().updateMetadata(title: 'ویرایش'));
      expect((await commitments.findById(stale.id))!.tags, {'Office', 'آموزش'});
      expect(await tags.recordsWithTag(renamed.id, TaggableType.commitment), {
        stale.id.value,
      });
      expect(await tags.recordsWithTag(renamed.id, TaggableType.accountEntry), {
        entry.id.value,
      });
      expect(await tags.recordsWithTag(retained.id, TaggableType.commitment), {
        stale.id.value,
        other.id.value,
      });
      expect(
        (await database.select(database.commitments).get())
            .firstWhere((row) => row.id == stale.id.value)
            .tags
            .split(r'\n')
            .toSet(),
        {'Office', 'آموزش'},
      );
      await tags.detach(
        recordId: stale.id.value,
        tag: retained,
        type: TaggableType.commitment,
      );
      await tags.remove(work.id);
      await commitments.save(
        stale.archive().updateMetadata(title: 'پس از حذف'),
      );
      expect((await commitments.findById(stale.id))!.tags, isEmpty);
      expect(
        (await database.select(database.commitments).get())
            .firstWhere((row) => row.id == stale.id.value)
            .tags,
        '',
      );
      expect(
        (await database.select(database.actuals).get())
            .map((row) => row.toJson())
            .toList(),
        beforeHistory,
      );
      expect(
        (await database.select(database.occurrences).get())
            .map((row) => row.toJson())
            .toList(),
        beforeOccurrences,
      );
      expect(
        (await database.select(database.accountEntries).get())
            .map((row) => row.toJson())
            .toList(),
        beforeEntries,
      );
      await database.close();
      database = AppDatabase.forTesting(NativeDatabase(file));
      tags = DriftTagRepository(database);
      expect((await tags.list()).map((tag) => tag.id), [retained.id]);
      expect(
        await tags.tagsFor(entry.id.value, TaggableType.accountEntry),
        isEmpty,
      );
      expect(await tags.recordsWithTag(retained.id, TaggableType.commitment), {
        other.id.value,
      });
      expect(
        (await DriftCommitmentRepository(database).findById(stale.id))!.tags,
        isEmpty,
      );
      expect(
        (await database.select(database.actuals).get())
            .map((row) => row.toJson())
            .toList(),
        beforeHistory,
      );
      expect(
        (await database.select(database.accountEntries).get())
            .map((row) => row.toJson())
            .toList(),
        beforeEntries,
      );
      expect((await tags.getOrCreate('Work')).id, isNot(work.id));
    } finally {
      await database.close();
      await directory.delete(recursive: true);
    }
  });

  test(
    'projection failure rolls back attach detach rename and global remove',
    () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      var commitments = DriftCommitmentRepository(database);
      final commitment = Commitment.create(title: 'کلاس', tags: {'Work'});
      await commitments.save(commitment);
      final tags = DriftTagRepository(database);
      final tag = await tags.getOrCreate('work');
      final extra = await tags.getOrCreate('extra');
      await database.customStatement(
        "CREATE TRIGGER reject_tag_projection BEFORE UPDATE OF tags ON commitments BEGIN SELECT RAISE(ABORT, 'injected'); END",
      );
      for (final operation in <Future<Object?> Function()>[
        () => tags.attach(
          recordId: commitment.id.value,
          tag: extra,
          type: TaggableType.commitment,
        ),
        () => tags.detach(
          recordId: commitment.id.value,
          tag: tag,
          type: TaggableType.commitment,
        ),
        () => tags.rename(tag.id, 'Office'),
        () => tags.remove(tag.id),
      ]) {
        await expectLater(operation(), throwsA(anything));
        expect(
          await tags.tagsFor(commitment.id.value, TaggableType.commitment),
          {tag.id},
        );
        expect((await tags.getOrCreate('Work')).id, tag.id);
        expect((await tags.list()).map((tag) => tag.label).toSet(), {
          'Work',
          'extra',
        });
        expect((await commitments.findById(commitment.id))!.tags, {'Work'});
      }
    },
  );
}
