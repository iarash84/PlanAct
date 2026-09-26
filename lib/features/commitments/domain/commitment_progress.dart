import 'package:planact/features/scheduling/domain/occurrence.dart';

/// Truthful progress for a cycle based only on its explicit occurrence set.
///
/// This deliberately does not use generated-horizon size, entitlement ledger
/// units, elapsed time, cancelled occurrences, or rescheduled occurrences.
int? completedOccurrencePercent({
  required Iterable<Occurrence> occurrences,
  required int? fixedTarget,
}) {
  if (fixedTarget == null || fixedTarget <= 0) return null;
  final completed = occurrences
      .where((item) => item.status == OccurrenceStatus.completed)
      .length;
  final percent = (completed * 100) ~/ fixedTarget;
  return percent.clamp(0, 100);
}
