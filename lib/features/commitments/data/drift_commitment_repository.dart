import 'package:drift/drift.dart';
import 'package:planact/core/database/app_database.dart' as db;
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/commitments/application/commitment_repository.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/classification/data/drift_tag_repository.dart';
import 'package:planact/features/classification/application/tag_repository.dart';

class DriftCommitmentRepository implements CommitmentRepository {
  DriftCommitmentRepository(this._database);

  final db.AppDatabase _database;

  db.AppDatabase get database => _database;

  @override
  Future<Commitment?> findById(StableId id) async {
    final row = await (_database.select(
      _database.commitments,
    )..where((table) => table.id.equals(id.value))).getSingleOrNull();
    return row == null ? null : _toDomain(row, await _tagsFor(row.id));
  }

  @override
  Future<List<Commitment>> list() async {
    final rows = await _database.select(_database.commitments).get();
    final result = <Commitment>[];
    for (final row in rows) {
      result.add(_toDomain(row, await _tagsFor(row.id)));
    }
    return result;
  }

  @override
  Future<void> save(Commitment commitment) async {
    await _database.transaction(() async {
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
      final repository = DriftTagRepository(_database);
      final existing = await repository.tagsFor(
        commitment.id.value,
        TaggableType.commitment,
      );
      final desired = <StableId>{};
      for (final label in commitment.tags) {
        final tag = await repository.getOrCreate(label);
        desired.add(tag.id);
        await repository.attach(
          recordId: commitment.id.value,
          tag: tag,
          type: TaggableType.commitment,
        );
      }
      for (final id in existing.difference(desired)) {
        final tag = (await repository.list()).firstWhere(
          (item) => item.id == id,
        );
        await repository.detach(
          recordId: commitment.id.value,
          tag: tag,
          type: TaggableType.commitment,
        );
      }
    });
  }

  Future<Set<String>> _tagsFor(String id) async {
    final repository = DriftTagRepository(_database);
    final ids = await repository.tagsFor(id, TaggableType.commitment);
    final all = await repository.list();
    return all
        .where((tag) => ids.contains(tag.id))
        .map((tag) => tag.label)
        .toSet();
  }

  Commitment _toDomain(db.Commitment row, Set<String> tags) {
    return Commitment(
      id: StableId.parse(row.id),
      title: row.title,
      createdAt: row.createdAt.toUtc(),
      status: CommitmentStatus.values[row.status],
      kind: CommitmentKind.values[row.kind],
      priority: CommitmentPriority.values[row.priority],
      description: row.description,
      tags: tags,
      attachmentIds: row.attachmentIds.isEmpty
          ? const []
          : row.attachmentIds.split('\\n'),
    );
  }
}
