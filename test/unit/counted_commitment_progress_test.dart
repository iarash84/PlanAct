import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/commitments/application/commitment_progress_reader.dart';
import 'package:planact/features/commitments/application/commitment_plan_use_case.dart';
import 'package:planact/features/commitments/domain/counted_commitment_progress.dart';
import 'package:planact/features/finance/application/financial_expectation_use_cases.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/reconciliation/domain/reconciliation.dart';
import 'package:planact/features/scheduling/domain/occurrence.dart';
import 'package:planact/features/finance/domain/financial_expectation.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';

import '../fixtures/counted_commitment.dart';

void main() {
  test('no explicit count never infers a target from rows or cycle units', () {
    final plan = countedPlan();
    final schedule = ScheduleDefinition.create(
      cycleId: plan.cycle.id,
      mode: ScheduleMode.openEndedRecurring,
      timeSemantics: TimeSemantics.allDayLocalDate,
      startDate: plan.schedule.startDate,
      recurrenceRule: plan.schedule.recurrenceRule,
    );
    expect(
      buildCountedCommitmentProgress(
        schedule: schedule,
        occurrences: plan.occurrences,
        settlements: const [],
      ),
      isNull,
    );
  });

  test(
    'attendance cancellation does not waive unpaid financial expectations',
    () async {
      final plan = countedPlan(
        target: 3,
        payments: true,
        statuses: [
          OccurrenceStatus.cancelled,
          OccurrenceStatus.skipped,
          OccurrenceStatus.completed,
        ],
      );
      final plans = InMemoryCommitmentPlanRepository();
      await plans.save(plan);
      final finance = InMemoryFinancialExpectationRepository();
      for (final o in plan.occurrences) {
        await FinancialExpectationUseCases(finance).create(
          occurrenceId: o.id,
          direction: FinancialExpectationDirection.outgoing,
          amount: 1000,
          currency: 'IRR',
        );
      }
      final result = (await RepositoryCommitmentProgressReader(
        plans,
        finance,
      ).read(plan.commitment.id))!;
      expect(result.outcomes.count(ProgressPart.cancelled), 1);
      expect(result.outcomes.count(ProgressPart.skipped), 1);
      expect(result.payments!.count(ProgressPart.remaining), 3);
      expect(result.payments!.count(ProgressPart.completed), 0);
    },
  );
  test(
    'music: 2 completed, 1 cancelled, 1 remaining of 4; credit is irrelevant',
    () {
      final plan = countedPlan();
      final result = buildCountedCommitmentProgress(
        schedule: plan.schedule,
        occurrences: plan.occurrences,
        settlements: const [],
      )!;
      expect(result.consistent, isTrue);
      expect(result.outcomes.count(ProgressPart.completed), 2);
      expect(result.outcomes.count(ProgressPart.cancelled), 1);
      expect(result.outcomes.count(ProgressPart.remaining), 1);
      expect(result.outcomes.percent(ProgressPart.completed), 50);
      expect(result.payments, isNull);
    },
  );

  test(
    'loan: 10 paid, 40 remain of 50 despite only 10 materialized rows',
    () async {
      final plan = countedPlan(
        target: 50,
        statuses: List.filled(10, OccurrenceStatus.scheduled),
        payments: true,
      );
      final plans = InMemoryCommitmentPlanRepository();
      await plans.save(plan);
      final finance = InMemoryFinancialExpectationRepository();
      final useCases = FinancialExpectationUseCases(finance);
      for (final o in plan.occurrences) {
        await useCases.create(
          occurrenceId: o.id,
          direction: FinancialExpectationDirection.outgoing,
          amount: 1000,
          currency: 'IRR',
        );
        finance.matches = [...finance.matches, match(o, 1000)];
      }
      final result = (await RepositoryCommitmentProgressReader(
        plans,
        finance,
      ).read(plan.commitment.id))!;
      expect(result.payments!.count(ProgressPart.completed), 10);
      expect(result.payments!.count(ProgressPart.remaining), 40);
      expect(result.payments!.percent(ProgressPart.completed), 20);
      expect(result.payments!.percent(ProgressPart.remaining), 80);
      expect(result.outcomes.count(ProgressPart.completed), 0);
      expect(result.consistent, isTrue);
    },
  );

  test('partial, reversal, mismatched currency and removed match never prove full payment', () async {
    final plan = countedPlan(
      target: 6,
      statuses: List.filled(6, OccurrenceStatus.completed),
      payments: true,
    );
    final plans = InMemoryCommitmentPlanRepository();
    await plans.save(plan);
    final finance = InMemoryFinancialExpectationRepository();
    for (final o in plan.occurrences.take(5)) {
      await FinancialExpectationUseCases(finance).create(
        occurrenceId: o.id,
        direction: FinancialExpectationDirection.outgoing,
        amount: 1000,
        currency: 'IRR',
      );
    }
    final reversed = match(plan.occurrences[2], 1000);
    finance.matches = [
      match(plan.occurrences[0], 1000),
      match(plan.occurrences[1], 400),
      reversed,
      match(plan.occurrences[3], 1000, currency: 'USD'),
      match(plan.occurrences[4], 1000, status: MatchStatus.reversed),
    ];
    finance.entries = [
      AccountEntry(
        id: StableId.generate(),
        accountId: StableId.generate(),
        type: AccountEntryType.reversal,
        amount: const Money(minorUnits: -1000, currency: 'IRR'),
        occurredAt: DateTime.now(),
        referenceId: reversed.transactionId.value,
      ),
    ];
    final result = (await RepositoryCommitmentProgressReader(
      plans,
      finance,
    ).read(plan.commitment.id))!;
    expect(result.outcomes.count(ProgressPart.completed), 6);
    expect(result.payments!.count(ProgressPart.completed), 1);
    expect(result.payments!.count(ProgressPart.partial), 1);
    expect(result.payments!.count(ProgressPart.remaining), 3);
    expect(result.payments!.count(ProgressPart.unknown), 1);
    expect(result.consistent, isTrue);
  });

  test('rescheduled/due/overdue/deferred/pending slots remain unresolved; skipped stays separate', () {
    final plan = countedPlan(
      target: 6,
      statuses: [
        OccurrenceStatus.rescheduled,
        OccurrenceStatus.due,
        OccurrenceStatus.overdue,
        OccurrenceStatus.deferred,
        OccurrenceStatus.pendingDecision,
        OccurrenceStatus.skipped,
      ],
    );
    final result = buildCountedCommitmentProgress(
      schedule: plan.schedule,
      occurrences: plan.occurrences,
      settlements: const [],
    )!;
    expect(result.outcomes.count(ProgressPart.remaining), 5);
    expect(result.outcomes.count(ProgressPart.skipped), 1);
    expect(result.outcomes.count(ProgressPart.completed), 0);
  });

  test(
    'count reduction excludes retained cancellations outside current prefix',
    () {
      final plan = countedPlan(
        target: 3,
        version: 2,
        statuses: [
          OccurrenceStatus.completed,
          OccurrenceStatus.cancelled,
          OccurrenceStatus.scheduled,
          OccurrenceStatus.cancelled,
        ],
      );
      final result = buildCountedCommitmentProgress(
        schedule: plan.schedule,
        occurrences: plan.occurrences,
        settlements: const [],
      )!;
      expect(result.consistent, isTrue);
      expect(result.excludedCancellations, 1);
      expect(result.outcomes.count(ProgressPart.cancelled), 1);
      expect(result.outcomes.count(ProgressPart.completed), 1);
      expect(result.outcomes.count(ProgressPart.remaining), 1);
    },
  );

  test('over-target or duplicated lineage is disclosed instead of clamped percentages', () {
    final plan = countedPlan(target: 2);
    expect(
      buildCountedCommitmentProgress(
        schedule: plan.schedule,
        occurrences: plan.occurrences,
        settlements: const [],
      )!.consistent,
      isFalse,
    );
    final result = buildCountedCommitmentProgress(
      schedule: plan.schedule,
      occurrences: [plan.occurrences.first, plan.occurrences.first],
      settlements: const [],
    )!;
    expect(result.ambiguous, isTrue);
    expect(result.consistent, isFalse);
  });
}

TransactionMatch match(
  Occurrence o,
  int amount, {
  String currency = 'IRR',
  MatchStatus status = MatchStatus.active,
}) {
  final id = StableId.generate();
  final money = Money(minorUnits: amount, currency: currency);
  return TransactionMatch(
    id: id,
    transactionId: StableId.generate(),
    transactionAmount: money,
    createdAt: DateTime.now(),
    status: status,
    allocations: [
      MatchAllocation(
        id: StableId.generate(),
        matchId: id,
        occurrenceId: o.id,
        amount: money,
      ),
    ],
  );
}
