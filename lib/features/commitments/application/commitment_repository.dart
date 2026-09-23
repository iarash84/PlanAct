import 'package:drift/drift.dart';
import 'package:planact/core/database/app_database.dart' as db;
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

class DriftCommitmentRepository implements CommitmentRepository {
  DriftCommitmentRepository(this._database);

  final db.AppDatabase _database;

  @override
  Future<Commitment?> findById(StableId id) async {
    final row = await (_database.select(
      _database.commitments,
    )..where((table) => table.id.equals(id.value))).getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<List<Commitment>> list() async {
    final rows = await _database.select(_database.commitments).get();
    return rows.map(_toDomain).toList(growable: false);
  }

  @override
  Future<void> save(Commitment commitment) async {
    await _database
        .into(_database.commitments)
        .insertOnConflictUpdate(
          db.CommitmentsCompanion(
            id: Value(commitment.id.value),
            title: Value(commitment.title),
            createdAt: Value(commitment.createdAt.toUtc()),
            status: Value(commitment.status.index),
            kind: Value(commitment.kind.index),
            priority: Value(commitment.priority.index),
            description: Value(commitment.description),
            tags: Value(commitment.tags.join('\\n')),
            attachmentIds: Value(commitment.attachmentIds.join('\\n')),
          ),
        );
  }

  Commitment _toDomain(db.Commitment row) {
    return Commitment(
      id: StableId.parse(row.id),
      title: row.title,
      createdAt: row.createdAt.toUtc(),
      status: CommitmentStatus.values[row.status],
      kind: CommitmentKind.values[row.kind],
      priority: CommitmentPriority.values[row.priority],
      description: row.description,
      tags: row.tags.isEmpty ? const {} : row.tags.split('\\n').toSet(),
      attachmentIds: row.attachmentIds.isEmpty
          ? const []
          : row.attachmentIds.split('\\n'),
    );
  }
}
