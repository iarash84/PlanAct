import 'package:planact/core/ids/stable_id.dart';

/// Descriptive metadata only. This never represents a settlement or review.
class CommitmentAssociation {
  const CommitmentAssociation({
    required this.transactionId,
    this.revision = 0,
    this.commitmentId,
  });

  final StableId transactionId;
  final int revision;
  final StableId? commitmentId;

  bool sameState(CommitmentAssociation other) =>
      transactionId == other.transactionId &&
      revision == other.revision &&
      commitmentId == other.commitmentId;
}

class CommitmentAssociationRevision {
  const CommitmentAssociationRevision({
    required this.before,
    required this.after,
    required this.recordedAt,
  });
  final CommitmentAssociation before;
  final CommitmentAssociation after;
  final DateTime recordedAt;
}
