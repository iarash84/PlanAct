import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/database/app_database.dart' as db;
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/sessions/application/session_repositories.dart';
import 'package:planact/features/sessions/domain/entitlement.dart';
import 'package:planact/features/sessions/domain/replacement.dart';
import 'package:planact/features/sessions/domain/session_policy.dart';

void main() {
  late db.AppDatabase database;
  late StableId cycleId;

  setUp(() async {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    cycleId = StableId.generate();
    final commitmentId = StableId.generate();
    await database
        .into(database.commitments)
        .insert(
          db.CommitmentsCompanion.insert(
            id: commitmentId.value,
            title: 'کلاس آزمایشی',
            createdAt: DateTime.utc(2026, 1, 1),
            status: 0,
          ),
        );
    await database
        .into(database.commitmentCycles)
        .insert(
          db.CommitmentCyclesCompanion.insert(
            id: cycleId.value,
            commitmentId: commitmentId.value,
            cycleType: 0,
            startDate: DateTime.utc(2026, 1, 1),
            consumedUnits: 0,
            completionRule: 0,
            status: 0,
          ),
        );
  });

  tearDown(() => database.close());

  test('round-trips entitlement plan and append-only ledger', () async {
    final planRepository = DriftEntitlementPlanRepository(database);
    final ledgerRepository = DriftEntitlementLedgerRepository(database);
    final plan = EntitlementPlan.create(
      cycleId: cycleId,
      totalUnits: 10,
      unitType: EntitlementUnitType.session,
      validFrom: DateTime.utc(2026, 1, 1),
    );
    await planRepository.save(plan);
    final grant = EntitlementLedgerEntry.create(
      planId: plan.id,
      type: EntitlementEntryType.grant,
      units: 10,
      occurredAt: DateTime.utc(2026, 1, 1),
    );
    final consume = EntitlementLedgerEntry.create(
      planId: plan.id,
      type: EntitlementEntryType.consume,
      units: 3,
      occurredAt: DateTime.utc(2026, 1, 2),
    );
    await ledgerRepository.append(grant);
    await ledgerRepository.append(consume);

    final stored = await planRepository.findById(plan.id);
    final entries = await ledgerRepository.listByPlan(plan.id);
    expect(stored?.totalUnits, 10);
    expect(const EntitlementLedger().remaining(entries), 7);
  });

  test('round-trips session policy and replacement history', () async {
    final policyRepository = DriftSessionPolicyRepository(database);
    final replacementRepository = DriftReplacementRepository(database);
    const policy = SessionPolicy(freeAbsenceQuota: 2);
    await policyRepository.save(cycleId, policy);

    final originalId = StableId.generate();
    final replacement = ReplacementOccurrence.create(
      originalOccurrenceId: originalId,
      scheduledAt: DateTime.utc(2026, 2, 1),
      reason: ReplacementReason.freeze,
    ).complete();
    await replacementRepository.save(replacement);

    final storedPolicy = await policyRepository.findByCycle(cycleId);
    final history = await replacementRepository.listByOriginal(originalId);
    expect(storedPolicy?.freeAbsenceQuota, 2);
    expect(history.single.status, ReplacementStatus.completed);
  });
}
