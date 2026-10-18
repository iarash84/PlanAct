import 'dart:convert';

import 'package:planact/core/application/command_gate.dart';
import 'package:planact/core/database/app_database.dart' as db;
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/commitments/application/checklist_repository.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/commitments/domain/commitment_checklist.dart';

final class DriftChecklistRepository
    implements ChecklistRepository, CommandGateProvider {
  DriftChecklistRepository(this.database);
  final db.AppDatabase database;
  static const headPrefix = 'commitment_checklist_head_v1:';
  static const historyPrefix = 'commitment_checklist_revision_v1:';

  @override
  CommandGate? get commandGate => CommandGate.forOwner(database);

  Future<ChecklistSnapshot> _load(StableId id) async {
    final owner = await (database.select(
      database.commitments,
    )..where((t) => t.id.equals(id.value))).getSingleOrNull();
    if (owner == null) throw const ChecklistConflict();
    final raw = await database.readMetadata('$headPrefix${id.value}');
    final list = raw == null
        ? CommitmentChecklist(commitmentId: id)
        : _decode(raw);
    if (list.commitmentId != id) throw const ChecklistConflict();
    return ChecklistSnapshot(list, CommitmentStatus.values[owner.status]);
  }

  @override
  Future<ChecklistSnapshot> load(StableId commitmentId) => CommandGate.runFor(
    this,
    () => database.transaction(() => _load(commitmentId)),
  );

  @override
  Future<void> save(
    CommitmentChecklist next, {
    required int expectedRevision,
  }) => CommandGate.runFor(
    this,
    () => database.transaction(() async {
      // CommandGate excludes restore; SQLite writer admission serializes writers.
      await database.customStatement(
        'UPDATE schema_metadata SET value = value WHERE key = ?',
        ['schema_version'],
      );
      final current = await _load(next.commitmentId);
      validateChecklistWrite(current, next, expectedRevision);
      final raw = jsonEncode({
        'version': 1,
        'commitmentId': next.commitmentId.value,
        'revision': next.revision,
        'at': DateTime.now().toUtc().toIso8601String(),
        'items': [
          for (final item in next.items)
            {
              'id': item.id.value,
              'title': item.title,
              'checked': item.checked,
              'removed': item.removed,
            },
        ],
      });
      await database
          .into(database.schemaMetadata)
          .insert(
            db.SchemaMetadataCompanion.insert(
              key: '$historyPrefix${next.commitmentId.value}:${next.revision}',
              value: raw,
            ),
          );
      await database.writeMetadata(
        '$headPrefix${next.commitmentId.value}',
        raw,
      );
    }),
  );

  static CommitmentChecklist _decode(String raw) {
    final map = jsonDecode(raw) as Map<String, dynamic>;
    if (map['version'] != 1) throw StateError('Unsupported checklist version');
    return CommitmentChecklist(
      commitmentId: StableId.parse(map['commitmentId'] as String),
      revision: map['revision'] as int,
      items: [
        for (final item in map['items'] as List)
          ChecklistItem(
            id: StableId.parse(item['id'] as String),
            title: item['title'] as String,
            checked: item['checked'] as bool,
            removed: item['removed'] as bool,
          ),
      ],
    );
  }
}
