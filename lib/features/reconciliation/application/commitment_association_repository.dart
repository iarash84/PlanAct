import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/reconciliation/domain/commitment_association.dart';

abstract interface class CommitmentAssociationRepository {
  Future<CommitmentAssociation> loadAssociation(StableId transactionId);
  Future<List<CommitmentAssociation>> listAssociations();
  Future<List<CommitmentAssociationRevision>> associationHistory(
    StableId transactionId,
  );
  Future<CommitmentAssociation> associateCommitment({
    required CommitmentAssociation expected,
    required StableId transactionId,
    required StableId? commitmentId,
  });
}
