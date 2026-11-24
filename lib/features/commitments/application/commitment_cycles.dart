import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/commitments/application/commitment_plan_use_case.dart';
import 'package:planact/features/commitments/domain/commitment_cycle.dart';

/// Explicit admission context: no owner metadata, credit or history is copied.
class NewCommitmentCycleContext {
  const NewCommitmentCycleContext({
    required this.commitmentId,
    required this.expectedCycleSet,
  });
  final StableId commitmentId;
  final String expectedCycleSet;
}

abstract interface class CommitmentCyclesRepository {
  Future<List<CommitmentPlan>> listByCommitmentId(StableId commitmentId);
  Future<CommitmentPlan?> findByCycleId(StableId cycleId);
  Future<String> cycleSetToken(StableId commitmentId);
  Future<void> admitNextCycle(
    NewCommitmentCycleContext context,
    DateTime start,
  );
  Future<CommitmentCycle> completeCycle({
    required StableId cycleId,
    required String expectedCycleSet,
    required DateTime completedAt,
  });
}

/// Legacy injected test repositories remain single-cycle seams.
extension CommitmentCycleReads on CommitmentPlanRepository {
  Future<List<CommitmentPlan>> listByCommitmentId(StableId id) async {
    final repository = this;
    if (repository is CommitmentCyclesRepository) {
      return (repository as CommitmentCyclesRepository).listByCommitmentId(id);
    }
    final plan = await findByCommitmentId(id);
    return plan == null ? const [] : [plan];
  }
}

class CompleteCommitmentCycle {
  const CompleteCommitmentCycle(this.repository);
  final CommitmentCyclesRepository repository;
  Future<CommitmentCycle> call({
    required StableId cycleId,
    required String expectedCycleSet,
    required DateTime completedAt,
  }) => repository.completeCycle(
    cycleId: cycleId,
    expectedCycleSet: expectedCycleSet,
    completedAt: completedAt,
  );
}
