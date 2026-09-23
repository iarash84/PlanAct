import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/errors/app_error.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/commitments/domain/commitment_cycle.dart';

void main() {
  final commitmentId = StableId.generate(timestamp: DateTime.utc(2026, 9, 20));
  final start = DateTime.utc(2026, 9, 20);
  final end = DateTime.utc(2026, 10, 20);

  test('keeps planned and actual end dates separate', () {
    final cycle = CommitmentCycle.create(
      commitmentId: commitmentId,
      cycleType: CommitmentCycleType.fixedDateRange,
      startDate: start,
      plannedEndDate: end,
      completionRule: CompletionRule.byDate,
    ).activate();

    final completed = cycle.complete(completedAt: DateTime.utc(2026, 10, 10));

    expect(completed.plannedEndDate, end);
    expect(completed.actualEndDate, DateTime.utc(2026, 10, 10));
    expect(completed.status, CommitmentCycleStatus.completed);
  });

  test('evaluates by-units and whichever-first semantics', () {
    final byUnits = CommitmentCycle.create(
      commitmentId: commitmentId,
      cycleType: CommitmentCycleType.fixedCount,
      startDate: start,
      targetUnits: 4,
      completionRule: CompletionRule.byUnits,
    );
    final whicheverFirst = CommitmentCycle.create(
      commitmentId: commitmentId,
      cycleType: CommitmentCycleType.hybrid,
      startDate: start,
      plannedEndDate: end,
      targetUnits: 4,
      completionRule: CompletionRule.whicheverFirst,
    );

    expect(byUnits.shouldComplete(onDate: start, unitsConsumed: 4), isTrue);
    expect(
      whicheverFirst.shouldComplete(onDate: end, unitsConsumed: 0),
      isTrue,
    );
  });

  test('rejects incomplete completion configuration', () {
    expect(
      () => CommitmentCycle.create(
        commitmentId: commitmentId,
        cycleType: CommitmentCycleType.fixedCount,
        startDate: start,
        completionRule: CompletionRule.byUnits,
      ),
      throwsA(isA<ValidationError>()),
    );
  });
}
