import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/sessions/domain/replacement.dart';

void main() {
  final originalId = StableId.generate(timestamp: DateTime.utc(2026, 1, 1));

  test('preserves a makeup cancellation chain without deleting history', () {
    final first = ReplacementOccurrence.create(
      originalOccurrenceId: originalId,
      scheduledAt: DateTime.utc(2026, 1, 8),
      reason: ReplacementReason.providerCancellation,
    ).complete();
    final second = ReplacementOccurrence.create(
      originalOccurrenceId: originalId,
      scheduledAt: DateTime.utc(2026, 1, 15),
      reason: ReplacementReason.makeup,
      parentReplacementId: first.id,
    ).cancel();
    final third = ReplacementOccurrence.create(
      originalOccurrenceId: originalId,
      scheduledAt: DateTime.utc(2026, 1, 22),
      reason: ReplacementReason.makeup,
      parentReplacementId: second.id,
    ).complete();

    expect(second.parentReplacementId, first.id);
    expect(third.parentReplacementId, second.id);
    expect(second.status, ReplacementStatus.cancelled);
  });

  test('keeps planned end and actual end separate', () {
    final completed = ReplacementOccurrence.create(
      originalOccurrenceId: originalId,
      scheduledAt: DateTime.utc(2026, 2, 10),
      reason: ReplacementReason.makeup,
    ).complete();
    final dates = const CycleEndDateCalculator().calculate(
      plannedEndDate: DateTime.utc(2026, 1, 31),
      replacements: [completed],
    );

    expect(dates.plannedEndDate, DateTime.utc(2026, 1, 31));
    expect(dates.actualEndDate, DateTime.utc(2026, 2, 10));
  });
}
