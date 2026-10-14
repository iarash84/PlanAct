import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/finance/domain/financial_expectation.dart';
import 'package:planact/features/scheduling/domain/occurrence.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';

enum ProgressPart { completed, partial, cancelled, skipped, remaining, unknown }

/// Count-based progress, never entitlement credit or an amount-weighted ratio.
class CountedProgress {
  CountedProgress(this.total, Map<ProgressPart, int> counts)
    : assert(total > 0),
      counts = Map.unmodifiable(counts);
  final int total;
  final Map<ProgressPart, int> counts;
  int count(ProgressPart part) => counts[part] ?? 0;
  bool get consistent => counts.values.fold(0, (a, b) => a + b) == total;
  int percent(ProgressPart part) => (count(part) * 100) ~/ total;
}

class CountedCommitmentProgress {
  const CountedCommitmentProgress({
    required this.outcomes,
    required this.payments,
    required this.excludedCancellations,
    required this.ambiguous,
  });
  final CountedProgress outcomes;
  final CountedProgress? payments;
  final int excludedCancellations;
  final bool ambiguous;
  bool get consistent =>
      !ambiguous && outcomes.consistent && (payments?.consistent ?? true);
}

CountedCommitmentProgress? buildCountedCommitmentProgress({
  required ScheduleDefinition schedule,
  required Iterable<Occurrence> occurrences,
  required Iterable<FinancialExpectationSettlement> settlements,
}) {
  final target = schedule.occurrenceCount;
  if (target == null || target <= 0) return null;
  final records = occurrences.where((o) => o.cycleId == schedule.cycleId);
  final outcomes = <ProgressPart, int>{};
  final payments = <ProgressPart, int>{};
  final byOccurrence = <StableId, List<FinancialExpectationSettlement>>{};
  for (final item in settlements) {
    if (item.expectation.status != FinancialExpectationStatus.active) continue;
    (byOccurrence[item.expectation.occurrenceId] ??= []).add(item);
  }
  var financial =
      schedule.generationFinancialExpectation?.direction ==
      FinancialExpectationDirection.outgoing;
  var excluded = 0;
  var recorded = 0;
  var ambiguous = false;
  final originalDates = <LocalDate>{};
  void add(Map<ProgressPart, int> counts, ProgressPart part) =>
      counts.update(part, (n) => n + 1, ifAbsent: () => 1);
  for (final occurrence in records) {
    // Count reduction retains cancelled rows beyond the new logical prefix.
    // Those rows are disclosed separately rather than inflating progress.
    if (schedule.version > 1 &&
        occurrence.status == OccurrenceStatus.cancelled &&
        !_insideCurrentPrefix(schedule, occurrence)) {
      excluded++;
      continue;
    }
    recorded++;
    final original = _date(occurrence.originalScheduledAt);
    if (!originalDates.add(original)) ambiguous = true;
    final outcome = switch (occurrence.status) {
      OccurrenceStatus.completed => ProgressPart.completed,
      OccurrenceStatus.cancelled => ProgressPart.cancelled,
      OccurrenceStatus.skipped => ProgressPart.skipped,
      _ => ProgressPart.remaining,
    };
    add(outcomes, outcome);
    final expected = byOccurrence[occurrence.id] ?? const [];
    final outgoing = expected
        .where(
          (e) =>
              e.expectation.direction == FinancialExpectationDirection.outgoing,
        )
        .toList();
    if (outgoing.isNotEmpty) financial = true;
    if (outgoing.length == 1 && expected.length == 1) {
      // Cancelling/skipping attendance does not waive a financial obligation.
      add(payments, _paymentPart(outgoing.single));
    } else {
      // Missing/ambiguous recorded expectations cannot prove payment status.
      add(payments, ProgressPart.unknown);
    }
  }
  final unrecorded = (target - recorded).clamp(0, target);
  outcomes.update(
    ProgressPart.remaining,
    (n) => n + unrecorded,
    ifAbsent: () => unrecorded,
  );
  final futureTemplate = schedule.generationFinancialExpectation;
  final futurePaymentPart =
      futureTemplate?.direction == FinancialExpectationDirection.outgoing &&
          futureTemplate?.currency != null
      ? ProgressPart.remaining
      : ProgressPart.unknown;
  payments.update(
    futurePaymentPart,
    (n) => n + unrecorded,
    ifAbsent: () => unrecorded,
  );
  return CountedCommitmentProgress(
    outcomes: CountedProgress(target, outcomes),
    payments: financial ? CountedProgress(target, payments) : null,
    excludedCancellations: excluded,
    ambiguous: ambiguous,
  );
}

LocalDate _date(Object value) =>
    value is LocalDate ? value : LocalDate.fromDateTime(value as DateTime);

ProgressPart _paymentPart(FinancialExpectationSettlement item) {
  if (item.expectation.currency == null) return ProgressPart.unknown;
  if (item.settled) return ProgressPart.completed;
  if ((item.allocatedAmount?.minorUnits ?? 0) > 0) return ProgressPart.partial;
  return ProgressPart.remaining;
}

bool _insideCurrentPrefix(ScheduleDefinition schedule, Occurrence occurrence) {
  final date = _date(occurrence.originalScheduledAt);
  // Preserve reference calendar, anchors and count phase; the progress prefix
  // includes recorded history before the newest effective boundary.
  final prefix = ScheduleDefinition(
    id: schedule.id,
    cycleId: schedule.cycleId,
    mode: schedule.mode,
    timeSemantics: schedule.timeSemantics,
    startDate: schedule.startDate,
    version: schedule.version,
    effectiveFrom: schedule.startDate,
    generationHorizonDays: schedule.generationHorizonDays,
    localTime: schedule.localTime,
    timeZoneId: schedule.timeZoneId,
    fixedInstant: schedule.fixedInstant,
    recurrenceRule: schedule.recurrenceRule,
    endDate: schedule.endDate,
    occurrenceCount: schedule.occurrenceCount,
  );
  return const OccurrenceGenerator()
      .plannedSlots(
        schedule: prefix,
        start: date,
        endExclusive: date.addDays(1),
        scheduleFingerprint: '',
      )
      .isNotEmpty;
}
