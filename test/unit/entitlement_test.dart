import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/errors/app_error.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/sessions/domain/entitlement.dart';

void main() {
  final cycleId = StableId.generate(timestamp: DateTime.utc(2026, 1, 1));

  test('folds the ledger as the only source of remaining units', () {
    final plan = EntitlementPlan.create(
      cycleId: cycleId,
      totalUnits: 10,
      unitType: EntitlementUnitType.session,
      validFrom: DateTime.utc(2026, 1, 1),
    );
    final entries = [
      EntitlementLedgerEntry.create(
        planId: plan.id,
        type: EntitlementEntryType.grant,
        units: 10,
      ),
      EntitlementLedgerEntry.create(
        planId: plan.id,
        type: EntitlementEntryType.consume,
        units: 3,
      ),
      EntitlementLedgerEntry.create(
        planId: plan.id,
        type: EntitlementEntryType.restore,
        units: 1,
      ),
      EntitlementLedgerEntry.create(
        planId: plan.id,
        type: EntitlementEntryType.expire,
        units: 2,
      ),
    ];

    final balance = const EntitlementLedger().fold(entries);

    expect(balance.granted, 11);
    expect(balance.consumed, 5);
    expect(balance.remaining, 6);
  });

  test('rejects invalid plan and ledger units', () {
    expect(
      () => EntitlementPlan.create(
        cycleId: cycleId,
        totalUnits: 0,
        unitType: EntitlementUnitType.visit,
        validFrom: DateTime.utc(2026, 1, 1),
      ),
      throwsA(isA<ValidationError>()),
    );
    expect(
      () => EntitlementLedgerEntry.create(
        planId: cycleId,
        type: EntitlementEntryType.consume,
        units: 0,
      ),
      throwsA(isA<ValidationError>()),
    );
  });
}
