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

  @override
  Future<CountedCommitmentProgress?> read(StableId commitmentId) async {
    final plan = await plans.findByCommitmentId(commitmentId);
    if (plan == null || plan.schedule.occurrenceCount == null) return null;
    return buildCountedCommitmentProgress(
      schedule: plan.schedule,
      occurrences: plan.occurrences,
      settlements: await FinancialExpectationUseCases(expectations)
          .settlements(),
    );
  }
}
