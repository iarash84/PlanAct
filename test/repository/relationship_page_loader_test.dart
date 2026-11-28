import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/application/command_gate.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/classification/application/tag_repository.dart';
import 'package:planact/features/classification/data/drift_tag_repository.dart';
import 'package:planact/features/commitments/application/commitment_plan_use_case.dart';
import 'package:planact/features/commitments/data/drift_commitment_plan_repository.dart';
import 'package:planact/features/commitments/data/drift_commitment_repository.dart';
import 'package:planact/features/finance/data/drift_finance_repository.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/reconciliation/application/contextual_reconciliation.dart';
import 'package:planact/features/reconciliation/application/reconciliation_use_cases.dart';
import 'package:planact/features/reconciliation/data/drift_reconciliation_repository.dart';
import 'package:planact/features/reconciliation/data/drift_relationship_page_loader.dart';
import 'package:planact/features/reconciliation/data/drift_relationship_target_reader.dart';
import 'package:planact/features/reconciliation/domain/reconciliation.dart';
import 'package:planact/features/reconciliation/domain/relationship_review.dart';

import '../fixtures/counted_commitment.dart';

class NoEagerPlans extends DriftCommitmentPlanRepository {
  NoEagerPlans(super.database);
  int calls = 0;

  @override
  Future<List<CommitmentPlan>> listByCommitmentId(StableId id) async {
    calls++;
    throw StateError('Page must never enumerate plans');
  }
}

void main() {
  test('production page retains durable tags and match history without eager plans', () async {
    final directory = await Directory.systemTemp.createTemp(
      'relationship-page-',
    );
    final file = File('${directory.path}/state.sqlite');
    var database = AppDatabase.forTesting(NativeDatabase(file));
    try {
      final plan = countedPlan();
      await DriftCommitmentRepository(database).save(plan.commitment);
      await DriftCommitmentPlanRepository(database).save(plan);
      final finance = DriftFinanceRepository(database);
      final account = FinancialAccount(
        id: StableId.generate(),
        name: 'حساب',
        currency: 'IRR',
        type: FinancialAccountType.cash,
      );
      await finance.saveAccount(account);
      final transaction = AccountEntry(
        id: StableId.generate(),
        accountId: account.id,
        type: AccountEntryType.expense,
        amount: const Money(minorUnits: 1000, currency: 'IRR'),
        occurredAt: DateTime.utc(2026, 11, 28),
        note: 'یادداشت پایدار',
      );
      await finance.saveEntry(transaction);
      final tags = DriftTagRepository(database);
      final tag = await tags.getOrCreate('آموزش');
      await tags.attach(
        recordId: transaction.id.value,
        type: TaggableType.accountEntry,
        tag: tag,
      );
      await database.customStatement(
        'INSERT INTO financial_expectations(id,occurrence_id,direction,minor_units,currency,status,created_at,updated_at) VALUES (?, ?, 0, 1000, ?, 0, 0, 0)',
        [StableId.generate().value, plan.occurrences.first.id.value, 'IRR'],
      );
      final repository = DriftReconciliationRepository(database);
      final matchId = StableId.generate();
      await repository.save(
        TransactionMatch(
          id: matchId,
          transactionId: transaction.id,
          transactionAmount: transaction.amount,
          createdAt: DateTime.now().toUtc(),
          allocations: [
            MatchAllocation(
              id: StableId.generate(),
              matchId: matchId,
              occurrenceId: plan.occurrences.first.id,
              amount: const Money(minorUnits: 200, currency: 'IRR'),
              type: AllocationType.payment,
            ),
          ],
        ),
      );
      final match = (await repository.list()).single;
      await repository.removeMatch(match);
      await repository.associateCommitment(
        expected: await repository.loadAssociation(transaction.id),
        transactionId: transaction.id,
        commitmentId: plan.commitment.id,
      );
      await repository.decideReview(
        expected: await repository.loadReview(transaction),
        decision: RelationshipReviewDecision.independent,
        recordedAt: DateTime.now().toUtc(),
      );
      await database.close();
      database = AppDatabase.forTesting(NativeDatabase(file));
      final gate = CommandGate();
      CommandGate.bind(database, gate);
      final plans = NoEagerPlans(database);
      final flow = ContextualReconciliation(
        finance: DriftFinanceRepository(database),
        commitments: DriftCommitmentRepository(database),
        plans: plans,
        reconciliation: ReconciliationUseCases(
          DriftReconciliationRepository(database),
        ),
        tags: DriftTagRepository(database),
        targetReader: DriftRelationshipTargetReader(database),
        pageLoader: DriftRelationshipPageLoader(database).load,
      );
      final before =
          (await database
                  .customSelect('SELECT total_changes() AS n')
                  .getSingle())
              .read<int>('n');
      final context = await flow.loadForPage(transaction.id);
      expect(plans.calls, 0);
      expect(context.transaction.note, 'یادداشت پایدار');
      expect(context.account!.id, account.id);
      expect(context.transactionTags, ['آموزش']);
      expect(context.association!.commitmentId, plan.commitment.id);
      expect(context.review!.isIndependent, isTrue);
      expect(context.available.minorUnits, 1000);
      expect(context.matches.single.status, MatchStatus.reversed);
      expect(context.targets.map((t) => t.occurrence.id), [
        plan.occurrences.first.id,
      ]);
      expect(context.commitments.single.id, plan.commitment.id);
      expect(
        (await database.customSelect('SELECT total_changes() AS n').getSingle())
            .read<int>('n'),
        before,
      );
      await expectLater(flow.load(transaction.id), throwsStateError);
      expect(plans.calls, 1);
      await gate.retire();
      await expectLater(
        flow.loadForPage(transaction.id),
        throwsA(isA<StaleApplicationCommand>()),
      );
    } finally {
      await database.close();
      await directory.delete(recursive: true);
    }
  });
}
