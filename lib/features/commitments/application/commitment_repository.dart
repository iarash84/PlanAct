import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/application/undo_token.dart';
import 'package:planact/features/commitments/domain/commitment.dart';

abstract interface class CommitmentRepository {
  Future<Commitment?> findById(StableId id);
  Future<List<Commitment>> list();
  Future<void> save(Commitment commitment);
}

abstract interface class CommitmentLifecycleRepository {
  Future<Commitment> changeStatus(
    StableId id,
    CommitmentStatus status, {
    CommitmentStatus? expectedStatus,
  });
  Future<UndoToken?> statusUndo(StableId id);
  Future<Commitment> undoStatus(StableId id, UndoToken expected);
}

class InMemoryCommitmentRepository implements CommitmentRepository {
  final Map<StableId, Commitment> _items = {};

  @override
  Future<Commitment?> findById(StableId id) async => _items[id];

  @override
  Future<List<Commitment>> list() async => List.unmodifiable(_items.values);

  @override
  Future<void> save(Commitment commitment) async {
    _items[commitment.id] = commitment;
  }
}
