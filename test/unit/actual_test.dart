import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/actuals/application/actual_use_cases.dart';
import 'package:planact/features/actuals/domain/actual.dart';
import 'package:planact/features/scheduling/domain/occurrence.dart';

void main() {
  final occurrenceId = StableId.generate(timestamp: DateTime.utc(2026, 1, 1));

  test(
    'records actuals with evidence and preserves explanatory outcome',
    () async {
      final repository = InMemoryActualRepository();
      final actual = await RecordActual(repository)(
        occurrenceId: occurrenceId,
        outcome: ActualOutcome.completed,
        recordedAt: DateTime.utc(2026, 1, 2),
        note: 'انجام شد',
      );
      final withEvidence = actual.addEvidence(
        Evidence(
          id: StableId.generate(timestamp: DateTime.utc(2026, 1, 2)),
          actualId: actual.id,
          type: EvidenceType.note,
          value: 'رسید محلی',
          createdAt: DateTime.utc(2026, 1, 2),
        ),
      );
      await repository.save(withEvidence);

      expect((await repository.list()).single.evidence, hasLength(1));
      expect(withEvidence.note, 'انجام شد');
    },
  );

  test(
    'history projection distinguishes unresolved from completed occurrence',
    () {
      final occurrence = Occurrence(
        id: occurrenceId,
        cycleId: StableId.generate(timestamp: DateTime.utc(2026, 1, 1)),
        scheduleDefinitionId: StableId.generate(
          timestamp: DateTime.utc(2026, 1, 1),
        ),
        occurrenceKey: 'm6-test',
        originalScheduledAt: DateTime.utc(2026, 1, 3),
        currentScheduledAt: DateTime.utc(2026, 1, 3),
      );
      final actual = Actual(
        id: StableId.generate(timestamp: DateTime.utc(2026, 1, 3)),
        occurrenceId: occurrence.id,
        outcome: ActualOutcome.partial,
        recordedAt: DateTime.utc(2026, 1, 4),
      );

      final result = const HistoryProjection()
          .build(occurrences: [occurrence], actuals: [actual])
          .single;

      expect(result.isResolved, isTrue);
      expect(result.outcome, ActualOutcome.partial);
      expect(result.explanation, contains('ناقص'));
    },
  );
}
