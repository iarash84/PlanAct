import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:planact/core/database/app_database.dart';
import 'package:planact/core/errors/app_error.dart';
import 'package:planact/core/ids/stable_id.dart';

/// Versioned append-only audit in the existing personal-backup extension store.
/// Callers acquire writer admission and commit state and journal together.
class UndoJournal {
  const UndoJournal(this.database);
  final AppDatabase database;

  Future<void> admitWriter() => database.customStatement(
    'UPDATE schema_metadata SET value = value WHERE key = ?',
    ['schema_version'],
  );

  Future<Map<String, dynamic>?> latest(String owner) async {
    final head = await (database.select(
      database.schemaMetadata,
    )..where((t) => t.key.equals('undo_head_v1:$owner'))).getSingleOrNull();
    if (head == null) return null;
    final row = await (database.select(
      database.schemaMetadata,
    )..where((t) => t.key.equals('undo_event_v1:${head.value}'))).getSingle();
    final event = jsonDecode(row.value) as Map<String, dynamic>;
    if (event['version'] != 1 ||
        event['owner'] != owner ||
        event['id'] != head.value) {
      throw const ValidationError('Unsupported or invalid Undo history');
    }
    return event;
  }

  Future<String> append({
    required String owner,
    required Object before,
    required Object after,
    String? undoOf,
  }) async {
    final id = StableId.generate().value;
    await database
        .into(database.schemaMetadata)
        .insert(
          SchemaMetadataCompanion.insert(
            key: 'undo_event_v1:$id',
            value: jsonEncode({
              'version': 1,
              'id': id,
              'owner': owner,
              'at': DateTime.now().toUtc().toIso8601String(),
              'before': before,
              'after': after,
              'undoOf': undoOf,
            }),
          ),
        );
    await database
        .into(database.schemaMetadata)
        .insertOnConflictUpdate(
          SchemaMetadataCompanion(
            key: Value('undo_head_v1:$owner'),
            value: Value(id),
          ),
        );
    return id;
  }

  void requireCurrent(
    Map<String, dynamic>? event,
    String expectedId,
    Object current,
  ) {
    if (event == null ||
        event['id'] != expectedId ||
        event['undoOf'] != null ||
        jsonEncode(event['after']) != jsonEncode(current)) {
      throw const ValidationError(
        'Undo conflicts with a newer change; reload first.',
      );
    }
  }
}
