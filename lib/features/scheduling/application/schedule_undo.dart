import 'package:planact/core/application/undo_token.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/reminders/application/reminder_service.dart';
import 'package:planact/features/scheduling/domain/occurrence.dart';

abstract interface class ScheduleUndoRepository {
  Future<T> recordScheduleEdit<T>(
    StableId commitmentId,
    Future<T> Function() edit,
  );
  Future<UndoToken?> scheduleUndo(StableId commitmentId);
  Future<List<Occurrence>> undoSchedule(
    StableId commitmentId,
    UndoToken expected,
    DateTime now,
  );
}

class UndoScheduleChange {
  const UndoScheduleChange(this.repository, {this.reminders});
  final ScheduleUndoRepository repository;
  final ReminderService? reminders;

  Future<bool> call(StableId id, UndoToken expected, DateTime now) async {
    final changed = await repository.undoSchedule(id, expected, now);
    var pending = false;
    for (final occurrence in changed) {
      try {
        await reminders?.synchronizeOccurrence(
          occurrenceId: occurrence.id,
          occurrenceStart: occurrence.currentScheduledAt is DateTime
              ? occurrence.currentScheduledAt as DateTime
              : null,
          resolved: false,
        );
      } catch (_) {
        pending = true;
      }
    }
    return pending;
  }
}
