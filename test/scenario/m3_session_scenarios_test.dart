import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/sessions/domain/entitlement.dart';
import 'package:planact/features/sessions/domain/replacement.dart';
import 'package:planact/features/sessions/domain/session_policy.dart';

void main() {
  final cycleId = StableId.generate(timestamp: DateTime.utc(2026, 1, 1));

  test('fixed-term language class has explicit planned end', () {
    final plan = EntitlementPlan.create(
      cycleId: cycleId,
      totalUnits: 12,
      unitType: EntitlementUnitType.session,
      validFrom: DateTime.utc(2026, 1, 1),
      plannedExpiry: DateTime.utc(2026, 3, 31),
    );

    expect(plan.plannedExpiry, DateTime.utc(2026, 3, 31));
    expect(
      const EntitlementLedger().remaining([
        EntitlementLedgerEntry.create(
          planId: plan.id,
          type: EntitlementEntryType.grant,
          units: 12,
        ),
      ]),
      12,
    );
  });

  test('four-session music package preserves a teacher-cancelled unit', () {
    final plan = EntitlementPlan.create(
      cycleId: cycleId,
      totalUnits: 4,
      unitType: EntitlementUnitType.session,
      validFrom: DateTime.utc(2026, 1, 1),
    );
    const policy = SessionPolicy(providerCancellationConsumes: false);
    final resolution = policy.resolve(
      outcome: SessionOutcome.providerCancelled,
    );
    final entries = [
      EntitlementLedgerEntry.create(
        planId: plan.id,
        type: EntitlementEntryType.grant,
        units: 4,
      ),
      if (resolution.consumesEntitlement)
        EntitlementLedgerEntry.create(
          planId: plan.id,
          type: EntitlementEntryType.consume,
          units: 1,
        ),
    ];

    expect(resolution.requiresMakeup, isTrue);
    expect(const EntitlementLedger().remaining(entries), 4);
  });

  test('ten-session swimming package allows two free absences', () {
    final plan = EntitlementPlan.create(
      cycleId: cycleId,
      totalUnits: 10,
      unitType: EntitlementUnitType.session,
      validFrom: DateTime.utc(2026, 1, 1),
    );
    const policy = SessionPolicy(freeAbsenceQuota: 2);
    final entries = <EntitlementLedgerEntry>[
      EntitlementLedgerEntry.create(
        planId: plan.id,
        type: EntitlementEntryType.grant,
        units: 10,
      ),
    ];
    for (var count = 1; count <= 3; count++) {
      final resolution = policy.resolve(
        outcome: SessionOutcome.absent,
        absenceCount: count,
      );
      if (resolution.consumesEntitlement) {
        entries.add(
          EntitlementLedgerEntry.create(
            planId: plan.id,
            type: EntitlementEntryType.consume,
            units: 1,
          ),
        );
      }
    }

    expect(const EntitlementLedger().remaining(entries), 8);
  });

  test('freeze creates a replacement and leaves the original audit trail', () {
    final original = ReplacementOccurrence.create(
      originalOccurrenceId: cycleId,
      scheduledAt: DateTime.utc(2026, 2, 1),
      reason: ReplacementReason.freeze,
    );
    final replacement = ReplacementOccurrence.create(
      originalOccurrenceId: cycleId,
      scheduledAt: DateTime.utc(2026, 3, 1),
      reason: ReplacementReason.freeze,
      parentReplacementId: original.id,
    ).complete();

    expect(replacement.parentReplacementId, original.id);
    expect(replacement.status, ReplacementStatus.completed);
    expect(original.status, ReplacementStatus.planned);
  });
}
