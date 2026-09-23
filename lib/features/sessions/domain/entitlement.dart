import 'package:planact/core/errors/app_error.dart';
import 'package:planact/core/ids/stable_id.dart';

/// The unit in which an entitlement is consumed.
enum EntitlementUnitType { session, hour, visit, credit }

enum EntitlementEntryType {
  grant,
  consume,
  restore,
  adjustment,
  expire,
  refund,
}

class EntitlementPlan {
  EntitlementPlan({
    required this.id,
    required this.cycleId,
    required this.totalUnits,
    required this.unitType,
    required this.validFrom,
    this.plannedExpiry,
    this.autoExtend = false,
  }) {
    if (totalUnits <= 0) {
      throw const ValidationError('Total entitlement units must be positive');
    }
    if (plannedExpiry != null && plannedExpiry!.isBefore(validFrom)) {
      throw const ValidationError('Entitlement expiry cannot precede validity');
    }
  }

  factory EntitlementPlan.create({
    required StableId cycleId,
    required int totalUnits,
    required EntitlementUnitType unitType,
    required DateTime validFrom,
    DateTime? plannedExpiry,
    bool autoExtend = false,
  }) => EntitlementPlan(
    id: StableId.generate(),
    cycleId: cycleId,
    totalUnits: totalUnits,
    unitType: unitType,
    validFrom: validFrom.toUtc(),
    plannedExpiry: plannedExpiry?.toUtc(),
    autoExtend: autoExtend,
  );

  final StableId id;
  final StableId cycleId;
  final int totalUnits;
  final EntitlementUnitType unitType;
  final DateTime validFrom;
  final DateTime? plannedExpiry;
  final bool autoExtend;
}

class EntitlementLedgerEntry {
  EntitlementLedgerEntry({
    required this.id,
    required this.planId,
    required this.type,
    required this.units,
    required this.occurredAt,
    this.referenceId,
    this.note,
  }) {
    if (units <= 0) {
      throw const ValidationError('Ledger units must be positive');
    }
  }

  factory EntitlementLedgerEntry.create({
    required StableId planId,
    required EntitlementEntryType type,
    required int units,
    DateTime? occurredAt,
    StableId? referenceId,
    String? note,
  }) => EntitlementLedgerEntry(
    id: StableId.generate(),
    planId: planId,
    type: type,
    units: units,
    occurredAt: (occurredAt ?? DateTime.now()).toUtc(),
    referenceId: referenceId,
    note: note,
  );

  final StableId id;
  final StableId planId;
  final EntitlementEntryType type;
  final int units;
  final DateTime occurredAt;
  final StableId? referenceId;
  final String? note;

  int get signedUnits => switch (type) {
    EntitlementEntryType.grant => units,
    EntitlementEntryType.restore => units,
    EntitlementEntryType.adjustment => units,
    EntitlementEntryType.consume => -units,
    EntitlementEntryType.expire => -units,
    EntitlementEntryType.refund => units,
  };
}

class EntitlementBalance {
  const EntitlementBalance({required this.granted, required this.consumed});

  final int granted;
  final int consumed;

  int get remaining => granted - consumed;
}

class EntitlementLedger {
  const EntitlementLedger();

  EntitlementBalance fold(Iterable<EntitlementLedgerEntry> entries) {
    var granted = 0;
    var consumed = 0;
    for (final entry in entries) {
      if (entry.signedUnits >= 0) {
        granted += entry.signedUnits;
      } else {
        consumed += -entry.signedUnits;
      }
    }
    return EntitlementBalance(granted: granted, consumed: consumed);
  }

  int remaining(Iterable<EntitlementLedgerEntry> entries) =>
      fold(entries).remaining;
}
