import 'package:planact/core/application/command_gate.dart';
import 'package:planact/core/database/app_database.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/commitments/application/commitment_progress_reader.dart';
import 'package:planact/features/commitments/data/drift_commitment_plan_repository.dart';
import 'package:planact/features/commitments/domain/counted_commitment_progress.dart';
import 'package:planact/features/finance/data/drift_financial_expectation_repository.dart';

class DriftCommitmentProgressReader
    implements CommitmentProgressReader, CommandGateProvider {
  const DriftCommitmentProgressReader(this.database);
  final AppDatabase database;
  @override
  CommandGate? get commandGate => CommandGate.forOwner(database);

  @override
  Future<CountedCommitmentProgress?> read(StableId commitmentId) =>
      CommandGate.runFor(
        this,
        () => database.transaction(
          () => RepositoryCommitmentProgressReader(
            DriftCommitmentPlanRepository(database),
            DriftFinancialExpectationRepository(database),
          ).read(commitmentId),
        ),
      );
}
