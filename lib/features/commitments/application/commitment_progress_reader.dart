import 'package:planact/features/commitments/application/commitment_cycles.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/commitments/application/commitment_plan_use_case.dart';
import 'package:planact/features/commitments/domain/counted_commitment_progress.dart';
import 'package:planact/features/finance/application/financial_expectation_use_cases.dart';

abstract interface class CommitmentProgressReader {
  Future<CountedCommitmentProgress?> read(StableId commitmentId);
}

/// Isolated repository fallback. Production wraps the entire read in a gated
/// database transaction, so plan and settlement inputs describe one snapshot.
class RepositoryCommitmentProgressReader implements CommitmentProgressReader {
  const RepositoryCommitmentProgressReader(this.plans, this.expectations);
  final CommitmentPlanRepository plans;
  final FinancialExpectationRepository expectations;

  Future<CountedCommitmentProgress?> readCycle(StableId cycleId) async {
    final repository = plans;
    if (repository is! CommitmentCyclesRepository) return null;
    return _project(
      await (repository as CommitmentCyclesRepository).findByCycleId(cycleId),
    );
  }

  @override
  Future<CountedCommitmentProgress?> read(StableId commitmentId) async =>
      _project(await plans.findByCommitmentId(commitmentId));

  Future<CountedCommitmentProgress?> _project(CommitmentPlan? plan) async {
    if (plan == null || plan.schedule.occurrenceCount == null) return null;
    return buildCountedCommitmentProgress(
      schedule: plan.schedule,
      occurrences: plan.occurrences,
      settlements: await FinancialExpectationUseCases(expectations)
          .settlements(),
    );
  }
}
