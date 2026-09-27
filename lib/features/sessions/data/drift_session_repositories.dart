import 'package:drift/drift.dart';
import 'package:planact/core/database/app_database.dart' as db;
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/sessions/domain/entitlement.dart';
import 'package:planact/features/sessions/domain/replacement.dart';
import 'package:planact/features/sessions/domain/session_policy.dart';

abstract interface class EntitlementPlanRepository {
  Future<EntitlementPlan?> findById(StableId id);
  Future<List<EntitlementPlan>> listByCycle(StableId cycleId);
  Future<void> save(EntitlementPlan plan);
}

abstract interface class EntitlementLedgerRepository {
  Future<List<EntitlementLedgerEntry>> listByPlan(StableId planId);
  Future<void> append(EntitlementLedgerEntry entry);
}

abstract interface class SessionPolicyRepository {
  Future<SessionPolicy?> findByCycle(StableId cycleId);
  Future<void> save(StableId cycleId, SessionPolicy policy);
}

abstract interface class ReplacementRepository {
  Future<List<ReplacementOccurrence>> listByOriginal(StableId occurrenceId);
  Future<void> save(ReplacementOccurrence replacement);
}

class DriftEntitlementPlanRepository implements EntitlementPlanRepository {
  DriftEntitlementPlanRepository(this._database);
  final db.AppDatabase _database;

  @override
  Future<EntitlementPlan?> findById(StableId id) async {
    final row = await (_database.select(
      _database.entitlementPlans,
    )..where((table) => table.id.equals(id.value))).getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<List<EntitlementPlan>> listByCycle(StableId cycleId) async {
    final rows = await (_database.select(
      _database.entitlementPlans,
    )..where((table) => table.cycleId.equals(cycleId.value))).get();
    return rows.map(_toDomain).toList(growable: false);
  }

  @override
  Future<void> save(EntitlementPlan plan) => _database
      .into(_database.entitlementPlans)
      .insertOnConflictUpdate(
        db.EntitlementPlansCompanion(
          id: Value(plan.id.value),
          cycleId: Value(plan.cycleId.value),
          totalUnits: Value(plan.totalUnits),
          unitType: Value(plan.unitType.index),
          validFrom: Value(plan.validFrom.toUtc()),
          plannedExpiry: Value(plan.plannedExpiry?.toUtc()),
          autoExtend: Value(plan.autoExtend),
        ),
      );

  EntitlementPlan _toDomain(db.EntitlementPlan row) => EntitlementPlan(
    id: StableId.parse(row.id),
    cycleId: StableId.parse(row.cycleId),
    totalUnits: row.totalUnits,
    unitType: EntitlementUnitType.values[row.unitType],
    validFrom: row.validFrom.toUtc(),
    plannedExpiry: row.plannedExpiry?.toUtc(),
    autoExtend: row.autoExtend,
  );
}

class DriftEntitlementLedgerRepository implements EntitlementLedgerRepository {
  DriftEntitlementLedgerRepository(this._database);
  final db.AppDatabase _database;

  @override
  Future<List<EntitlementLedgerEntry>> listByPlan(StableId planId) async {
    final rows =
        await (_database.select(_database.entitlementLedgerEntries)
              ..where((table) => table.planId.equals(planId.value))
              ..orderBy([(table) => OrderingTerm.asc(table.occurredAt)]))
            .get();
    return rows.map(_toDomain).toList(growable: false);
  }

  @override
  Future<void> append(EntitlementLedgerEntry entry) => _database
      .into(_database.entitlementLedgerEntries)
      .insert(
        db.EntitlementLedgerEntriesCompanion.insert(
          id: entry.id.value,
          planId: entry.planId.value,
          type: entry.type.index,
          units: entry.units,
          occurredAt: entry.occurredAt.toUtc(),
          referenceId: Value(entry.referenceId?.value),
          note: Value(entry.note),
        ),
      );

  EntitlementLedgerEntry _toDomain(db.EntitlementLedgerEntry row) =>
      EntitlementLedgerEntry(
        id: StableId.parse(row.id),
        planId: StableId.parse(row.planId),
        type: EntitlementEntryType.values[row.type],
        units: row.units,
        occurredAt: row.occurredAt.toUtc(),
        referenceId: row.referenceId == null
            ? null
            : StableId.parse(row.referenceId!),
        note: row.note,
      );
}

class DriftSessionPolicyRepository implements SessionPolicyRepository {
  DriftSessionPolicyRepository(this._database);
  final db.AppDatabase _database;

  @override
  Future<SessionPolicy?> findByCycle(StableId cycleId) async {
    final row = await (_database.select(
      _database.sessionPolicies,
    )..where((table) => table.cycleId.equals(cycleId.value))).getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<void> save(StableId cycleId, SessionPolicy policy) async {
    final existing = await (_database.select(
      _database.sessionPolicies,
    )..where((table) => table.cycleId.equals(cycleId.value))).getSingleOrNull();
    await _database
        .into(_database.sessionPolicies)
        .insertOnConflictUpdate(
          db.SessionPoliciesCompanion(
            id: Value(existing?.id ?? StableId.generate().value),
            cycleId: Value(cycleId.value),
            providerCancellationConsumes: Value(
              policy.providerCancellationConsumes,
            ),
            userCancellationNoticeHours: Value(
              policy.userCancellationNoticeHours,
            ),
            lateCancellationConsumes: Value(policy.lateCancellationConsumes),
            noShowConsumes: Value(policy.noShowConsumes),
            freeAbsenceQuota: Value(policy.freeAbsenceQuota),
            holidayConsumes: Value(policy.holidayConsumes),
            makeupRequired: Value(policy.makeupRequired),
            autoExtendUntilUnitsConsumed: Value(
              policy.autoExtendUntilUnitsConsumed,
            ),
            maxExtensionDate: Value(policy.maxExtensionDate?.toUtc()),
            partialUnitAllowed: Value(policy.partialUnitAllowed),
          ),
        );
  }

  SessionPolicy _toDomain(db.SessionPolicy row) => SessionPolicy(
    providerCancellationConsumes: row.providerCancellationConsumes,
    userCancellationNoticeHours: row.userCancellationNoticeHours,
    lateCancellationConsumes: row.lateCancellationConsumes,
    noShowConsumes: row.noShowConsumes,
    freeAbsenceQuota: row.freeAbsenceQuota,
    holidayConsumes: row.holidayConsumes,
    makeupRequired: row.makeupRequired,
    autoExtendUntilUnitsConsumed: row.autoExtendUntilUnitsConsumed,
    maxExtensionDate: row.maxExtensionDate?.toUtc(),
    partialUnitAllowed: row.partialUnitAllowed,
  );
}

class DriftReplacementRepository implements ReplacementRepository {
  DriftReplacementRepository(this._database);
  final db.AppDatabase _database;

  @override
  Future<List<ReplacementOccurrence>> listByOriginal(
    StableId occurrenceId,
  ) async {
    final rows =
        await (_database.select(_database.replacementOccurrences)
              ..where(
                (table) =>
                    table.originalOccurrenceId.equals(occurrenceId.value),
              )
              ..orderBy([(table) => OrderingTerm.asc(table.scheduledAt)]))
            .get();
    return rows.map(_toDomain).toList(growable: false);
  }

  @override
  Future<void> save(ReplacementOccurrence replacement) => _database
      .into(_database.replacementOccurrences)
      .insertOnConflictUpdate(
        db.ReplacementOccurrencesCompanion(
          id: Value(replacement.id.value),
          originalOccurrenceId: Value(replacement.originalOccurrenceId.value),
          parentReplacementId: Value(replacement.parentReplacementId?.value),
          scheduledAt: Value(replacement.scheduledAt.toUtc()),
          reason: Value(replacement.reason.index),
          status: Value(replacement.status.index),
        ),
      );

  ReplacementOccurrence _toDomain(db.ReplacementOccurrence row) =>
      ReplacementOccurrence(
        id: StableId.parse(row.id),
        originalOccurrenceId: StableId.parse(row.originalOccurrenceId),
        parentReplacementId: row.parentReplacementId == null
            ? null
            : StableId.parse(row.parentReplacementId!),
        scheduledAt: row.scheduledAt.toUtc(),
        reason: ReplacementReason.values[row.reason],
        status: ReplacementStatus.values[row.status],
      );
}
