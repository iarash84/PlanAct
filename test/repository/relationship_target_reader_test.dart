import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/database/app_database.dart' as db;
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/commitments/data/drift_commitment_plan_repository.dart';
import 'package:planact/features/commitments/data/drift_commitment_repository.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/finance/application/financial_expectation_use_cases.dart';
import 'package:planact/features/finance/data/drift_finance_repository.dart';
import 'package:planact/features/finance/data/drift_financial_expectation_repository.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/finance/domain/financial_expectation.dart';
import 'package:planact/features/reconciliation/application/relationship_target_reader.dart';
import 'package:planact/features/reconciliation/data/drift_reconciliation_repository.dart';
import 'package:planact/features/reconciliation/data/drift_relationship_target_reader.dart';
import 'package:planact/features/reconciliation/domain/reconciliation.dart';
import 'package:planact/features/scheduling/domain/occurrence.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';

import '../fixtures/counted_commitment.dart';

void main() {
  test('production count/pages/filters are deterministic and read-only after cold reopen', () async {
    final directory = await Directory.systemTemp.createTemp(
      'relationship-targets-',
    );
    final file = File('${directory.path}/targets.sqlite');
    var database = db.AppDatabase.forTesting(NativeDatabase(file));
    try {
      final plan = countedPlan(
        target: 45,
        statuses: List.filled(45, OccurrenceStatus.scheduled),
        start: LocalDate(2026, 1, 1),
      );
      await DriftCommitmentRepository(database).save(plan.commitment);
      await DriftCommitmentPlanRepository(database).save(plan);
      await (database.update(
        database.commitments,
      )..where((t) => t.id.equals(plan.commitment.id.value))).write(
        const db.CommitmentsCompanion(
          title: Value('كلاس يک ۱۲'),
          description: Value('توضیح آزمایشی'),
          status: Value(2),
        ),
      );
      final tagId = StableId.generate();
      await database
          .into(database.tags)
          .insert(
            db.TagsCompanion.insert(
              id: tagId.value,
              label: 'برچسب ویژه',
              normalizedLabel: 'برچسب ویژه',
              createdAt: DateTime.now(),
            ),
          );
      await database
          .into(database.commitmentTags)
          .insert(
            db.CommitmentTagsCompanion.insert(
              commitmentId: plan.commitment.id.value,
              tagId: tagId.value,
            ),
          );
      final instant = DateTime(2026, 1, 3, 9).toUtc();
      await (database.update(
        database.occurrences,
      )..where((t) => t.id.equals(plan.occurrences[2].id.value))).write(
        db.OccurrencesCompanion(
          currentScheduledValue: Value('instant:${instant.toIso8601String()}'),
          timeSemantics: Value(TimeSemantics.fixedInstant.index),
          status: Value(OccurrenceStatus.completed.index),
        ),
      );
      await (database.update(
        database.occurrences,
      )..where((t) => t.id.equals(plan.occurrences[1].id.value))).write(
        const db.OccurrencesCompanion(
          currentScheduledValue: Value('date:2026-01-02'),
        ),
      );
      await database.close();
      database = db.AppDatabase.forTesting(NativeDatabase(file));
      final reader = DriftRelationshipTargetReader(database);
      final before =
          (await database
                  .customSelect('SELECT total_changes() AS n')
                  .getSingle())
              .read<int>('n');
      final all = <String>[];
      for (var page = 0; page < 4; page++) {
        final result = await reader.read(
          RelationshipTargetQuery(page: page),
          'IRR',
        );
        expect(result.total, 45);
        expect(result.items.length, [20, 20, 5, 0][page]);
        all.addAll(result.items.map((t) => t.occurrence.id.value));
        expect(result.cycles.single.id, plan.cycle.id);
        expect(result.cycles.single.label, contains('۱۴۰۴'));
      }
      expect(all, plan.occurrences.map((o) => o.id.value).toList());
      for (final query in ['کلاس یک 12', 'توضيح', 'برچسب ويژه']) {
        expect(
          (await reader.read(
            RelationshipTargetQuery(query: query),
            'IRR',
          )).total,
          45,
        );
      }
      expect(
        (await reader.read(
          const RelationshipTargetQuery(query: '%'),
          'IRR',
        )).total,
        0,
      );
      final range = await reader.read(
        RelationshipTargetQuery(
          from: LocalDate(2026, 1, 2),
          to: LocalDate(2026, 1, 3),
          cycleId: plan.cycle.id,
          commitmentStatus: CommitmentStatus.archived,
        ),
        'IRR',
      );
      expect(range.total, 2);
      expect(range.items.first.occurrence.currentScheduledAt, isA<LocalDate>());
      expect(range.items.last.occurrence.currentScheduledAt, instant);
      expect(
        (await reader.read(
          const RelationshipTargetQuery(
            occurrenceStatus: OccurrenceStatus.completed,
          ),
          'IRR',
        )).total,
        1,
      );
      expect(
        (await reader.read(
          const RelationshipTargetQuery(
            commitmentStatus: CommitmentStatus.active,
          ),
          'IRR',
        )).total,
        0,
      );
      expect(
        (await reader.read(
          const RelationshipTargetQuery(
            sort: RelationshipTargetSort.dateDescending,
          ),
          'IRR',
        )).items.first.occurrence.id,
        plan.occurrences.last.id,
      );
      final retained = await reader.byIds([
        plan.occurrences.last.id,
        plan.occurrences.first.id,
        StableId.generate(),
      ], 'IRR');
      expect(retained.map((t) => t.occurrence.id), [
        plan.occurrences.last.id,
        plan.occurrences.first.id,
      ]);
      expect(retained.first.expected, isNull);
      expect(
        (await database.customSelect('SELECT total_changes() AS n').getSingle())
            .read<int>('n'),
        before,
      );
    } finally {
      await database.close();
      await directory.delete(recursive: true);
    }
  });

  test('amounts use only known same-currency active expectations and unreversed active allocations', () async {
    final database = db.AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final plan = countedPlan();
    await DriftCommitmentRepository(database).save(plan.commitment);
    await DriftCommitmentPlanRepository(database).save(plan);
    final expectations = FinancialExpectationUseCases(
      DriftFinancialExpectationRepository(database),
    );
    for (var i = 0; i < 4; i++) {
      final item = await expectations.create(
        occurrenceId: plan.occurrences[i].id,
        direction: FinancialExpectationDirection.outgoing,
        amount: (i + 1) * 1000,
        currency: i == 2
            ? 'USD'
            : i == 3
            ? null
            : 'IRR',
      );
      if (i == 3) await expectations.archive(item);
    }
    final finance = DriftFinanceRepository(database);
    final account = FinancialAccount(
      id: StableId.generate(),
      name: 'حساب',
      currency: 'IRR',
      type: FinancialAccountType.cash,
    );
    await finance.saveAccount(account);
    final entries = <AccountEntry>[];
    for (var i = 0; i < 3; i++) {
      final tx = AccountEntry(
        id: StableId.generate(),
        accountId: account.id,
        type: AccountEntryType.expense,
        amount: const Money(minorUnits: 300, currency: 'IRR'),
        occurredAt: DateTime.now(),
      );
      entries.add(tx);
      await finance.saveEntry(tx);
      final matchId = StableId.generate();
      await DriftReconciliationRepository(database).save(
        TransactionMatch(
          id: matchId,
          transactionId: tx.id,
          transactionAmount: tx.amount,
          createdAt: DateTime.now(),
          status: MatchStatus.active,
          allocations: [
            MatchAllocation(
              id: StableId.generate(),
              matchId: matchId,
              occurrenceId: plan.occurrences.first.id,
              amount: tx.amount,
              type: AllocationType.payment,
            ),
          ],
        ),
      );
      if (i == 2) {
        await (database.update(
          database.transactionMatches,
        )..where((t) => t.id.equals(matchId.value))).write(
          db.TransactionMatchesCompanion(
            status: Value(MatchStatus.reversed.index),
          ),
        );
      }
    }
    await finance.saveEntry(
      AccountEntry(
        id: StableId.generate(),
        accountId: account.id,
        type: AccountEntryType.reversal,
        amount: entries[1].amount,
        occurredAt: DateTime.now(),
        referenceId: entries[1].id.value,
      ),
    );
    final reader = DriftRelationshipTargetReader(database);
    final result = await reader.read(const RelationshipTargetQuery(), 'IRR');
    expect(result.items.first.expected!.minorUnits, 1000);
    expect(result.items.first.allocated!.minorUnits, 300);
    expect(result.items.first.outstanding!.minorUnits, 700);
    expect(result.items[2].expected, isNull);
    expect(result.items[3].expected, isNull);
    expect(
      (await reader.read(
        const RelationshipTargetQuery(
          minimumOutstanding: 700,
          maximumOutstanding: 700,
        ),
        'IRR',
      )).total,
      1,
    );
    expect(
      (await reader.read(
        const RelationshipTargetQuery(
          sort: RelationshipTargetSort.amountAscending,
        ),
        'IRR',
      )).items.take(2).map((t) => t.outstanding!.minorUnits),
      [700, 2000],
    );
    expect(
      (await reader.read(
        const RelationshipTargetQuery(
          sort: RelationshipTargetSort.amountDescending,
        ),
        'IRR',
      )).items.take(2).map((t) => t.outstanding!.minorUnits),
      [2000, 700],
    );
    expect(
      (await reader.read(
        const RelationshipTargetQuery(),
        'USD',
      )).items[2].expected!.minorUnits,
      3000,
    );
  });
}
