import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/scheduling/application/occurrence_actions.dart';
import 'package:planact/features/scheduling/domain/occurrence.dart';
import 'package:planact/features/sessions/domain/session_policy.dart';

Occurrence _occurrence(OccurrenceStatus status) => Occurrence(
  id: StableId.generate(),
  cycleId: StableId.generate(),
  scheduleDefinitionId: StableId.generate(),
  occurrenceKey: 'test',
  originalScheduledAt: DateTime(2026, 10, 1, 18),
  currentScheduledAt: DateTime(2026, 10, 1, 18),
  status: status,
);

void main() {
  test(
    'scheduled occurrence exposes completion, cancellation, and reschedule',
    () {
      final actions = availableOccurrenceActions(
        _occurrence(OccurrenceStatus.scheduled),
      );
      final types = actions.map((item) => item.type).toSet();
      expect(types, contains(OccurrenceActionType.complete));
      expect(types, contains(OccurrenceActionType.providerCancelled));
      expect(types, contains(OccurrenceActionType.reschedule));
    },
  );

  test('provider cancellation consequence follows session policy', () {
    final actions = availableOccurrenceActions(
      _occurrence(OccurrenceStatus.due),
      policy: const SessionPolicy(makeupRequired: true),
    );
    final action = actions.firstWhere(
      (item) => item.type == OccurrenceActionType.providerCancelled,
    );
    expect(action.consequence, contains('جبرانی'));
  });

  test('completed occurrence exposes explicit historical reopening only', () {
    final actions = availableOccurrenceActions(
      _occurrence(OccurrenceStatus.completed),
    );
    expect(actions.map((action) => action.type), [
      OccurrenceActionType.restore,
    ]);
    expect(actions.single.consequence, contains('نتیجهٔ قبلی محفوظ'));
    expect(actions.single.consequence, contains('اعتبار جلسه تغییر نمی‌کند'));
  });

  test('cancelled occurrence exposes restore and makeup only', () {
    final types = availableOccurrenceActions(
      _occurrence(OccurrenceStatus.cancelled),
    ).map((item) => item.type).toSet();
    expect(types, {OccurrenceActionType.restore, OccurrenceActionType.makeup});
  });
}
