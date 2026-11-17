import 'package:planact/core/application/command_gate.dart';
import 'package:drift/drift.dart';
import 'package:planact/core/database/app_database.dart' as db;
import 'package:planact/core/errors/app_error.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/classification/application/tag_repository.dart';
import 'package:planact/features/classification/domain/tag.dart';

class DriftTagRepository
    implements CommandGateProvider, TagRepository, BatchTagRepository {
  DriftTagRepository(this.database);

  @override
  CommandGate? get commandGate => CommandGate.forOwner(database);
  final db.AppDatabase database;

  @override
  Future<Tag> getOrCreate(String label) => CommandGate.runFor(
    this,
    () => database.transaction(() async {
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
      final stored =
          await (database.select(database.tags)
                ..where((table) => table.normalizedLabel.equals(normalized)))
              .getSingle();
      return _toDomain(stored);
    }),
  );

  Future<db.Tag> _requireTag(StableId id) async {
    final row = await (database.select(
      database.tags,
    )..where((table) => table.id.equals(id.value))).getSingleOrNull();
    if (row == null) throw const ValidationError('Tag does not exist');
    return row;
  }

  @override
  Future<Tag> rename(StableId id, String label) => CommandGate.runFor(
    this,
    () => database.transaction(() async {
      final existing = await _requireTag(id);
      final renamed = Tag(
        id: id,
        label: label,
        createdAt: existing.createdAt.toUtc(),
      );
      final duplicate =
          await (database.select(database.tags)..where(
                (table) =>
                    table.normalizedLabel.equals(renamed.normalizedLabel),
              ))
              .getSingleOrNull();
      if (duplicate != null && duplicate.id != id.value) {
        throw const ValidationError('Tag label already exists');
      }
      final records = await recordsWithTag(id, TaggableType.commitment);
      await (database.update(
        database.tags,
      )..where((table) => table.id.equals(id.value))).write(
        db.TagsCompanion(
          label: Value(renamed.label),
          normalizedLabel: Value(renamed.normalizedLabel),
        ),
      );
      for (final record in records) {
        await _syncLegacyProjection(record);
      }
      return renamed;
    }),
  );

  @override
  Future<void> remove(StableId id) => CommandGate.runFor(
    this,
    () => database.transaction(() async {
      final records = await recordsWithTag(id, TaggableType.commitment);
      await (database.delete(
        database.commitmentTags,
      )..where((row) => row.tagId.equals(id.value))).go();
      await (database.delete(
        database.accountEntryTags,
      )..where((row) => row.tagId.equals(id.value))).go();
      await (database.delete(
        database.tags,
      )..where((row) => row.id.equals(id.value))).go();
      for (final record in records) {
        await _syncLegacyProjection(record);
      }
    }),
  );

  @override
  Future<Set<String>> recordsWithTag(StableId id, TaggableType type) =>
      CommandGate.runFor(this, () async {
        if (type == TaggableType.commitment) {
          final rows = await (database.select(
            database.commitmentTags,
          )..where((row) => row.tagId.equals(id.value))).get();
          return rows.map((row) => row.commitmentId).toSet();
        }
        final rows = await (database.select(
          database.accountEntryTags,
        )..where((row) => row.tagId.equals(id.value))).get();
        return rows.map((row) => row.accountEntryId).toSet();
      });

  // Keep the pre-normalization column rebuildable from canonical memberships.
  // Old-schema imports must never resurrect a detached/renamed/deleted label.
  Future<void> _syncLegacyProjection(String recordId) async {
    final query = database.select(database.tags).join([
      innerJoin(
        database.commitmentTags,
        database.commitmentTags.tagId.equalsExp(database.tags.id),
      ),
    ])..where(database.commitmentTags.commitmentId.equals(recordId));
    final labels =
        (await query.get())
            .map((row) => row.readTable(database.tags).label)
            .toList()
          ..sort();
    await (database.update(database.commitments)
          ..where((row) => row.id.equals(recordId)))
        .write(db.CommitmentsCompanion(tags: Value(labels.join('\\n'))));
  }

  @override
  Future<List<Tag>> autocomplete(String query) =>
      CommandGate.runFor(this, () async {
        final normalized = normalizeTagKey(query);
        final rows =
            await (database.select(database.tags)
                  ..where(
                    (table) => normalized.isEmpty
                        ? const Constant(true)
                        : FunctionCallExpression<int>('instr', [
                            table.normalizedLabel,
                            Variable<String>(normalized),
                          ]).isBiggerThanValue(0),
                  )
                  ..orderBy([(table) => OrderingTerm(expression: table.label)]))
                .get();
        return rows.map(_toDomain).toList(growable: false);
      });

  @override
  Future<List<Tag>> list() => CommandGate.runFor(
    this,
    () async => (await database.select(database.tags).get())
        .map(_toDomain)
        .toList(growable: false),
  );

  @override
  Future<List<Tag>> mostUsed({int limit = 5}) =>
      CommandGate.runFor(this, () async {
        final usageRows = await database
            .customSelect(
              '''SELECT t.id,
                  (SELECT COUNT(*) FROM commitment_tags c WHERE c.tag_id = t.id) +
                  (SELECT COUNT(*) FROM account_entry_tags a WHERE a.tag_id = t.id)
                    AS usage_count,
                  MAX(
                    COALESCE(
                      (SELECT MAX(c.last_used_at) FROM commitment_tags c
                       WHERE c.tag_id = t.id), 0),
                    COALESCE(
                      (SELECT MAX(a.last_used_at) FROM account_entry_tags a
                       WHERE a.tag_id = t.id), 0)
                  ) AS last_used_at
           FROM tags t
           ORDER BY usage_count DESC, last_used_at DESC, t.created_at DESC
           LIMIT ?''',
              variables: [Variable.withInt(limit)],
              readsFrom: {
                database.tags,
                database.commitmentTags,
                database.accountEntryTags,
              },
            )
            .get();
        final rankById = {
          for (var index = 0; index < usageRows.length; index++)
            usageRows[index].read<String>('id'): index,
        };
        final tags = await database.select(database.tags).get();
        tags.sort(
          (a, b) => (rankById[a.id] ?? usageRows.length).compareTo(
            rankById[b.id] ?? usageRows.length,
          ),
        );
        return tags.take(limit).map(_toDomain).toList(growable: false);
      });

  @override
  Future<Set<StableId>> tagsFor(String recordId, TaggableType type) =>
      CommandGate.runFor(this, () async {
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
      });

  @override
  Future<Map<String, Set<StableId>>> tagsForMany(
    Iterable<String> recordIds,
    TaggableType type,
  ) => CommandGate.runFor(this, () async {
    final requested = recordIds.toSet();
    if (requested.isEmpty) return const {};

    final result = <String, Set<StableId>>{};
    for (final recordId in requested) {
      result[recordId] = <StableId>{};
    }
    if (type == TaggableType.commitment) {
      final rows = await (database.select(
        database.commitmentTags,
      )..where((row) => row.commitmentId.isIn(requested))).get();
      for (final row in rows) {
        result[row.commitmentId]?.add(StableId.parse(row.tagId));
      }
    } else {
      final rows = await (database.select(
        database.accountEntryTags,
      )..where((row) => row.accountEntryId.isIn(requested))).get();
      for (final row in rows) {
        result[row.accountEntryId]?.add(StableId.parse(row.tagId));
      }
    }
    return {
      for (final entry in result.entries)
        entry.key: Set.unmodifiable(entry.value),
    };
  });

  @override
  Future<void> attach({
    required String recordId,
    required Tag tag,
    required TaggableType type,
  }) => CommandGate.runFor(
    this,
    () => database.transaction(() async {
      await _requireTag(tag.id);
      if (type == TaggableType.commitment) {
        await database
            .into(database.commitmentTags)
            .insertOnConflictUpdate(
              db.CommitmentTagsCompanion.insert(
                commitmentId: recordId,
                tagId: tag.id.value,
                lastUsedAt: Value(DateTime.now().toUtc()),
              ),
            );
      } else {
        await database
            .into(database.accountEntryTags)
            .insertOnConflictUpdate(
              db.AccountEntryTagsCompanion.insert(
                accountEntryId: recordId,
                tagId: tag.id.value,
                lastUsedAt: Value(DateTime.now().toUtc()),
              ),
            );
      }
      if (type == TaggableType.commitment) {
        await _syncLegacyProjection(recordId);
      }
    }),
  );

  @override
  Future<void> detach({
    required String recordId,
    required Tag tag,
    required TaggableType type,
  }) => CommandGate.runFor(
    this,
    () => database.transaction(() async {
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
      if (type == TaggableType.commitment) {
        await _syncLegacyProjection(recordId);
      }
    }),
  );

  Tag _toDomain(db.Tag row) => Tag(
    id: StableId.parse(row.id),
    label: row.label,
    createdAt: row.createdAt.toUtc(),
  );
}
