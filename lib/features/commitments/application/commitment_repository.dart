import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/commitments/domain/commitment.dart';

abstract interface class CommitmentRepository {
  Future<Commitment?> findById(StableId id);
  Future<List<Commitment>> list();
  Future<void> save(Commitment commitment);
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
