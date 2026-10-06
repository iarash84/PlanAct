import 'package:planact/core/application/command_gate.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/actuals/domain/actual.dart';
import 'package:planact/features/scheduling/domain/occurrence.dart';

abstract interface class ActualRepository {
  Future<List<Actual>> list();
  Future<void> save(Actual actual);
}

/// Commits an append-only result and its occurrence status together, rejecting
/// stale input. Production implementations must provide a database transaction.
abstract interface class OccurrenceActualWriter {
  Future<Occurrence> recordOccurrenceActual({
    required Occurrence expected,
    required ActualOutcome outcome,
    required DateTime recordedAt,
    String? note,
  });
}

class InMemoryActualRepository implements ActualRepository {
  final Map<StableId, Actual> _items = {};

  @override
  Future<List<Actual>> list() async => List.unmodifiable(_items.values);

  @override
  Future<void> save(Actual actual) async => _items[actual.id] = actual;
}

class RecordActual {
  RecordActual(this.repository);
  final ActualRepository repository;

  Future<Actual> call({
    required StableId occurrenceId,
    required ActualOutcome outcome,
    required DateTime recordedAt,
    String? note,
    List<Evidence> evidence = const [],
  }) => CommandGate.runFor(repository, () async {
    final actual = Actual(
      id: StableId.generate(timestamp: recordedAt),
      occurrenceId: occurrenceId,
      outcome: outcome,
      recordedAt: recordedAt.toUtc(),
      note: note,
      evidence: evidence,
    );
    await repository.save(actual);
    return actual;
  });
}

class HistoryProjection {
  const HistoryProjection();

  List<PlannedVsActual> build({
    required Iterable<Occurrence> occurrences,
    required Iterable<Actual> actuals,
  }) {
    // Repositories return append order; equal-second timestamps retain that
    // order rather than inventing chronology from random identifier bits.
    final byOccurrence = <StableId, Actual>{};
    for (final actual in actuals) {
      final previous = byOccurrence[actual.occurrenceId];
      if (previous == null ||
          !actual.recordedAt.isBefore(previous.recordedAt)) {
        byOccurrence[actual.occurrenceId] = actual;
      }
    }
    return occurrences
        .map((occurrence) {
          final actual = byOccurrence[occurrence.id];
          return PlannedVsActual(
            occurrenceId: occurrence.id,
            plannedAt: occurrence.currentScheduledAt,
            outcome: actual?.outcome == ActualOutcome.reopened
                ? null
                : actual?.outcome,
            recordedAt: actual?.recordedAt,
            explanation: actual == null
                ? 'برای این برنامه هنوز نتیجه‌ای ثبت نشده است.'
                : _explain(actual.outcome),
          );
        })
        .toList(growable: false);
  }

  String _explain(ActualOutcome outcome) => switch (outcome) {
    ActualOutcome.completed => 'برنامه انجام شد.',
    ActualOutcome.attended => 'حضور ثبت شد.',
    ActualOutcome.cancelled => 'برنامه لغو شد.',
    ActualOutcome.missed => 'برنامه از دست رفت.',
    ActualOutcome.noShow => 'عدم حضور ثبت شد.',
    ActualOutcome.partial => 'برنامه به‌صورت ناقص انجام شد.',
    ActualOutcome.reopened => 'نتیجه بازگردانی شد؛ سابقهٔ قبلی محفوظ است.',
  };
}
