import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/scheduling/domain/occurrence.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';

/// Separate recorded history and calculated future slots, keyed by commitment ID.
/// Neither reading this projection nor navigating to it materializes anything.
class PlannedOccurrenceRange {
  PlannedOccurrenceRange({
    required Map<String, List<Occurrence>> recorded,
    required Map<String, List<PlannedOccurrenceSlot>> preview,
  }) : recorded = Map.unmodifiable({
         for (final entry in recorded.entries)
           entry.key: List<Occurrence>.unmodifiable(entry.value),
       }),
       preview = Map.unmodifiable({
         for (final entry in preview.entries)
           entry.key: List<PlannedOccurrenceSlot>.unmodifiable(entry.value),
       });

  final Map<String, List<Occurrence>> recorded;
  final Map<String, List<PlannedOccurrenceSlot>> preview;
}

abstract interface class PlannedOccurrencesRepository {
  /// Half-open range of 1–31 dates; previews are restricted to today onward.
  Future<PlannedOccurrenceRange> loadPlannedRange(
    LocalDate start,
    LocalDate endExclusive,
    LocalDate today, {
    StableId? commitmentId,
  });

  /// Explicit write admission. Rejects stale, occupied, past or inactive slots.
  /// Commits one occurrence and its dependent intent atomically, without platform
  /// delivery. Callers refresh the projection and reconcile reminders afterwards.
  /// Busy/failed transactions may be explicitly retried after reloading the slot.
  Future<Occurrence> preparePlannedOccurrence(
    PlannedOccurrenceSlot slot,
    LocalDate today,
  );
}
