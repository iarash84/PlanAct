import 'package:planact/core/application/command_gate.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/commitments/domain/commitment_color.dart';
import 'package:planact/features/notes/domain/calendar_note.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';

abstract interface class CalendarNoteRepository {
  /// Current snapshots only, for read-only discovery across every date.
  Future<List<CalendarNote>> list();

  Future<List<CalendarNote>> loadRange(LocalDate start, LocalDate endExclusive);

  /// Atomically compare the current revision and append the new snapshot.
  Future<void> save(CalendarNote note, {required int expectedRevision});
}

final class SaveCalendarNote {
  const SaveCalendarNote(this.repository);
  final CalendarNoteRepository repository;

  Future<CalendarNote> call({
    required StableId id,
    required String title,
    required String description,
    required LocalDate date,
    required CommitmentColor color,
    required int expectedRevision,
  }) => CommandGate.runFor(repository, () async {
    final note = CalendarNote(
      id: id,
      title: title,
      description: description,
      date: date,
      color: color,
      revision: expectedRevision + 1,
    );
    await repository.save(note, expectedRevision: expectedRevision);
    return note;
  });
}

final class InMemoryCalendarNoteRepository implements CalendarNoteRepository {
  final _notes = <StableId, CalendarNote>{};
  @override
  Future<List<CalendarNote>> list() async => _notes.values.toList();

  @override
  Future<List<CalendarNote>> loadRange(
    LocalDate start,
    LocalDate endExclusive,
  ) async =>
      _notes.values
          .where(
            (note) =>
                note.date.compareTo(start) >= 0 &&
                note.date.compareTo(endExclusive) < 0,
          )
          .toList()
        ..sort((a, b) => a.id.value.compareTo(b.id.value));

  @override
  Future<void> save(CalendarNote note, {required int expectedRevision}) async {
    if ((_notes[note.id]?.revision ?? 0) != expectedRevision ||
        note.revision != expectedRevision + 1) {
      throw const StaleCalendarNote();
    }
    _notes[note.id] = note;
  }
}
