import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:planact/core/application/command_gate.dart';
import 'package:planact/core/database/app_database.dart' as db;
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/commitments/domain/commitment_color.dart';
import 'package:planact/features/notes/application/calendar_note_repository.dart';
import 'package:planact/features/notes/domain/calendar_note.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';

final class DriftCalendarNoteRepository
    implements CalendarNoteRepository, CommandGateProvider {
  DriftCalendarNoteRepository(this.database);
  final db.AppDatabase database;
  static const _head = 'calendar_note_head_v1:';
  static const _day = 'calendar_note_day_v1:';
  static const _history = 'calendar_note_revision_v1:';
  @override
  CommandGate? get commandGate => CommandGate.forOwner(database);

  static String _dateKey(LocalDate date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  static String _index(CalendarNote note) =>
      '$_day${_dateKey(note.date)}:${note.id.value}';

  @override
  Future<List<CalendarNote>> loadRange(
    LocalDate start,
    LocalDate endExclusive,
  ) => CommandGate.runFor(
    this,
    () => database.transaction(() async {
      final rows =
          await (database.select(database.schemaMetadata)
                ..where(
                  (t) =>
                      t.key.isBiggerOrEqualValue('$_day${_dateKey(start)}:') &
                      t.key.isSmallerThanValue(
                        '$_day${_dateKey(endExclusive)}:',
                      ),
                )
                ..orderBy([(t) => OrderingTerm.asc(t.key)]))
              .get();
      final notes = <CalendarNote>[];
      for (final row in rows) {
        final raw = await database.readMetadata('$_head${row.value}');
        if (raw == null) throw StateError('Missing calendar note head');
        final note = _decode(raw);
        if (_index(note) != row.key) {
          throw StateError('Invalid note date index');
        }
        notes.add(note);
      }
      return notes;
    }),
  );

  @override
  Future<void> save(
    CalendarNote note, {
    required int expectedRevision,
  }) => CommandGate.runFor(
    this,
    () => database.transaction(() async {
      // Obtain SQLite writer admission before reading the head (also across
      // repository instances). CommandGate protects backup, not serialization.
      await database.customStatement(
        'UPDATE schema_metadata SET value = value WHERE key = ?',
        ['schema_version'],
      );
      final key = '$_head${note.id.value}';
      final raw = await database.readMetadata(key);
      final previous = raw == null ? null : _decode(raw);
      if ((previous?.revision ?? 0) != expectedRevision ||
          note.revision != expectedRevision + 1) {
        throw const StaleCalendarNote();
      }
      final encoded = jsonEncode({
        'version': 1,
        'id': note.id.value,
        'title': note.title,
        'description': note.description,
        'year': note.date.year,
        'month': note.date.month,
        'day': note.date.day,
        'color': note.color.name,
        'revision': note.revision,
      });
      // Plain insert deliberately prevents replacement of an existing revision.
      await database
          .into(database.schemaMetadata)
          .insert(
            db.SchemaMetadataCompanion.insert(
              key: '$_history${note.id.value}:${note.revision}',
              value: encoded,
            ),
          );
      if (previous != null) {
        await (database.delete(
          database.schemaMetadata,
        )..where((t) => t.key.equals(_index(previous)))).go();
      }
      await database.writeMetadata(key, encoded);
      await database.writeMetadata(_index(note), note.id.value);
    }),
  );

  static CalendarNote _decode(String raw) {
    final value = jsonDecode(raw) as Map<String, dynamic>;
    if (value['version'] != 1) throw StateError('Unsupported note version');
    return CalendarNote(
      id: StableId.parse(value['id'] as String),
      title: value['title'] as String,
      description: value['description'] as String,
      date: LocalDate(
        value['year'] as int,
        value['month'] as int,
        value['day'] as int,
      ),
      color: CommitmentColor.values.byName(value['color'] as String),
      revision: value['revision'] as int,
    );
  }
}
