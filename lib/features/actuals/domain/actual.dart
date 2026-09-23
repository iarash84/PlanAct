import 'package:planact/core/errors/app_error.dart';
import 'package:planact/core/ids/stable_id.dart';

/// The outcome recorded for one planned occurrence.
enum ActualOutcome { completed, attended, cancelled, missed, noShow, partial }

enum EvidenceType { note, document, localReference }

class Evidence {
  Evidence({
    required this.id,
    required this.actualId,
    required this.type,
    required this.value,
    required this.createdAt,
  }) {
    if (value.trim().isEmpty) {
      throw const ValidationError('Evidence value cannot be empty');
    }
  }

  final StableId id;
  final StableId actualId;
  final EvidenceType type;
  final String value;
  final DateTime createdAt;
}

class Actual {
  Actual({
    required this.id,
    required this.occurrenceId,
    required this.outcome,
    required this.recordedAt,
    this.note,
    this.evidence = const [],
  }) {
    if (note != null && note!.trim().isEmpty) {
      throw const ValidationError('Actual note cannot be empty');
    }
  }

  final StableId id;
  final StableId occurrenceId;
  final ActualOutcome outcome;
  final DateTime recordedAt;
  final String? note;
  final List<Evidence> evidence;

  Actual addEvidence(Evidence item) {
    if (item.actualId != id) {
      throw const ValidationError('Evidence belongs to another actual');
    }
    return Actual(
      id: id,
      occurrenceId: occurrenceId,
      outcome: outcome,
      recordedAt: recordedAt,
      note: note,
      evidence: [...evidence, item],
    );
  }
}

class PlannedVsActual {
  const PlannedVsActual({
    required this.occurrenceId,
    required this.plannedAt,
    required this.outcome,
    required this.recordedAt,
    required this.explanation,
  });

  final StableId occurrenceId;
  final Object plannedAt;
  final ActualOutcome? outcome;
  final DateTime? recordedAt;
  final String explanation;

  bool get isResolved => outcome != null;
}
