import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/commitments/domain/commitment_progress.dart';
import 'package:planact/features/scheduling/domain/occurrence.dart';

void main() {
  test('درصد فقط از target ثابت و occurrence تکمیل‌شده محاسبه می‌شود', () {
    final cycle = StableId.generate();
    final schedule = StableId.generate();
    Occurrence occurrence(OccurrenceStatus status, String key) => Occurrence(
      id: StableId.generate(),
      cycleId: cycle,
      scheduleDefinitionId: schedule,
      occurrenceKey: key,
      originalScheduledAt: DateTime(2026, 1, 1),
      currentScheduledAt: DateTime(2026, 1, 1),
      status: status,
    );

    expect(
      completedOccurrencePercent(
        occurrences: [
          occurrence(OccurrenceStatus.completed, 'one'),
          occurrence(OccurrenceStatus.cancelled, 'two'),
          occurrence(OccurrenceStatus.rescheduled, 'three'),
        ],
        fixedTarget: 4,
      ),
      25,
    );
  });

  test('target نامعلوم درصد ندارد و زمان سپری‌شده completion نیست', () {
    expect(
      completedOccurrencePercent(occurrences: const [], fixedTarget: null),
      isNull,
    );
  });
}
