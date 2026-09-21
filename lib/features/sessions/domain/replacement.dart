import 'package:planact/core/errors/app_error.dart';
import 'package:planact/core/ids/stable_id.dart';

enum ReplacementReason {
  providerCancellation,
  allowedAbsence,
  holiday,
  freeze,
  makeup,
}

enum ReplacementStatus { planned, completed, cancelled }

class ReplacementOccurrence {
  ReplacementOccurrence({
    required this.id,
    required this.originalOccurrenceId,
    required this.scheduledAt,
    required this.reason,
    this.parentReplacementId,
    this.status = ReplacementStatus.planned,
  }) {
    if (parentReplacementId == id) {
      throw const ValidationError('A replacement cannot point to itself');
    }
  }

  factory ReplacementOccurrence.create({
    required StableId originalOccurrenceId,
    required DateTime scheduledAt,
    required ReplacementReason reason,
    StableId? parentReplacementId,
  }) => ReplacementOccurrence(
    id: StableId.generate(),
    originalOccurrenceId: originalOccurrenceId,
    scheduledAt: scheduledAt.toUtc(),
    reason: reason,
    parentReplacementId: parentReplacementId,
  );

  final StableId id;
  final StableId originalOccurrenceId;
  final StableId? parentReplacementId;
  final DateTime scheduledAt;
  final ReplacementReason reason;
  final ReplacementStatus status;

  ReplacementOccurrence complete() => _copyWith(ReplacementStatus.completed);

  ReplacementOccurrence cancel() => _copyWith(ReplacementStatus.cancelled);

  ReplacementOccurrence _copyWith(ReplacementStatus nextStatus) =>
      ReplacementOccurrence(
        id: id,
        originalOccurrenceId: originalOccurrenceId,
        parentReplacementId: parentReplacementId,
        scheduledAt: scheduledAt,
        reason: reason,
        status: nextStatus,
      );
}

class CycleEndDates {
  const CycleEndDates({required this.plannedEndDate, this.actualEndDate});

  final DateTime plannedEndDate;
  final DateTime? actualEndDate;
}

class CycleEndDateCalculator {
  const CycleEndDateCalculator();

  CycleEndDates calculate({
    required DateTime plannedEndDate,
    required Iterable<ReplacementOccurrence> replacements,
  }) {
    final completed = replacements
        .where((item) => item.status == ReplacementStatus.completed)
        .map((item) => item.scheduledAt)
        .toList();
    completed.sort();
    return CycleEndDates(
      plannedEndDate: plannedEndDate.toUtc(),
      actualEndDate: completed.isEmpty ? null : completed.last.toUtc(),
    );
  }
}
