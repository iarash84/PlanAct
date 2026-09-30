import 'package:drift/drift.dart';
import 'package:planact/core/database/app_database.dart' as db;
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/classification/application/tag_repository.dart';
import 'package:planact/features/classification/domain/tag.dart';

class DriftTagRepository implements TagRepository {
  DriftTagRepository(this.database);
  final db.AppDatabase database;

  @override
  Future<Tag> getOrCreate(String label) async {
    final normalized = normalizeTagKey(label);
    final existing =
        await (database.select(database.tags)
              ..where((table) => table.normalizedLabel.equals(normalized)))
            .getSingleOrNull();
    if (existing != null) return _toDomain(existing);
    final tag = Tag(
      id: StableId.generate(),
      label: label,
      createdAt: DateTime.now().toUtc(),
    );
    await database
        .into(database.tags)
        .insert(
          db.TagsCompanion.insert(
            id: tag.id.value,
            label: tag.label,
            normalizedLabel: tag.normalizedLabel,
            createdAt: tag.createdAt,
          ),
          mode: InsertMode.insertOrIgnore,
        );
    final stored = await (database.select(
      database.tags,
    )..where((table) => table.normalizedLabel.equals(normalized))).getSingle();
    return _toDomain(stored);
  }

  @override
  Future<List<Tag>> autocomplete(String query) async {
    final normalized = normalizeTagKey(query);
    final rows =
        await (database.select(database.tags)
              ..where(
                (table) => normalized.isEmpty
                    ? const Constant(true)
                    : table.normalizedLabel.like('%$normalized%'),
              )
              ..orderBy([(table) => OrderingTerm(expression: table.label)]))
            .get();
    return rows.map(_toDomain).toList(growable: false);
  }

  @override
  Future<List<Tag>> list() async => (await database.select(database.tags).get())
      .map(_toDomain)
      .toList(growable: false);

  @override
  Future<Set<StableId>> tagsFor(String recordId, TaggableType type) async {
    if (type == TaggableType.commitment) {
      final rows = await (database.select(
        database.commitmentTags,
      )..where((row) => row.commitmentId.equals(recordId))).get();
      return rows.map((row) => StableId.parse(row.tagId)).toSet();
    }
    final rows = await (database.select(
      database.accountEntryTags,
    )..where((row) => row.accountEntryId.equals(recordId))).get();
    return rows.map((row) => StableId.parse(row.tagId)).toSet();
  }

  @override
  Future<void> attach({
    required String recordId,
    required Tag tag,
    required TaggableType type,
  }) async {
    if (type == TaggableType.commitment) {
      await database
          .into(database.commitmentTags)
          .insertOnConflictUpdate(
            db.CommitmentTagsCompanion.insert(
              commitmentId: recordId,
              tagId: tag.id.value,
            ),
          );
    } else {
      await database
          .into(database.accountEntryTags)
          .insertOnConflictUpdate(
            db.AccountEntryTagsCompanion.insert(
              accountEntryId: recordId,
              tagId: tag.id.value,
            ),
          );
    }
  }

  @override
  Future<void> detach({
    required String recordId,
    required Tag tag,
    required TaggableType type,
  }) async {
    if (type == TaggableType.commitment) {
      await (database.delete(database.commitmentTags)..where(
            (row) =>
                row.commitmentId.equals(recordId) &
                row.tagId.equals(tag.id.value),
          ))
          .go();
    } else {
      await (database.delete(database.accountEntryTags)..where(
            (row) =>
                row.accountEntryId.equals(recordId) &
                row.tagId.equals(tag.id.value),
          ))
          .go();
    }
  }

  Tag _toDomain(db.Tag row) => Tag(
    id: StableId.parse(row.id),
    label: row.label,
    createdAt: row.createdAt.toUtc(),
  );
}
