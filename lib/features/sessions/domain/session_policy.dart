import 'package:planact/core/errors/app_error.dart';

enum CancellationActor { provider, user }

enum SessionOutcome {
  completed,
  providerCancelled,
  userCancelled,
  lateCancelled,
  noShow,
  holiday,
  absent,
  makeup,
}

class SessionPolicy {
  const SessionPolicy({
    this.providerCancellationConsumes = false,
    this.userCancellationNoticeHours = 24,
    this.lateCancellationConsumes = true,
    this.noShowConsumes = true,
    this.freeAbsenceQuota = 0,
    this.holidayConsumes = false,
    this.makeupRequired = true,
    this.autoExtendUntilUnitsConsumed = false,
    this.maxExtensionDate,
    this.partialUnitAllowed = false,
  }) : assert(userCancellationNoticeHours >= 0),
       assert(freeAbsenceQuota >= 0);

  final bool providerCancellationConsumes;
  final int userCancellationNoticeHours;
  final bool lateCancellationConsumes;
  final bool noShowConsumes;
  final int freeAbsenceQuota;
  final bool holidayConsumes;
  final bool makeupRequired;
  final bool autoExtendUntilUnitsConsumed;
  final DateTime? maxExtensionDate;
  final bool partialUnitAllowed;

  SessionResolution resolve({
    required SessionOutcome outcome,
    int absenceCount = 0,
    bool cancellationWithinNotice = true,
  }) {
    if (absenceCount < 0) {
      throw const ValidationError('Absence count cannot be negative');
    }
    final consumes = switch (outcome) {
      SessionOutcome.completed => true,
      SessionOutcome.providerCancelled => providerCancellationConsumes,
      SessionOutcome.userCancelled =>
        cancellationWithinNotice ? false : lateCancellationConsumes,
      SessionOutcome.lateCancelled => lateCancellationConsumes,
      SessionOutcome.noShow => noShowConsumes,
      SessionOutcome.holiday => holidayConsumes,
      SessionOutcome.absent => absenceCount >= freeAbsenceQuota,
      SessionOutcome.makeup => true,
    };
    final requiresMakeup = switch (outcome) {
      SessionOutcome.providerCancelled => makeupRequired,
      SessionOutcome.userCancelled => !consumes && makeupRequired,
      SessionOutcome.lateCancelled => false,
      SessionOutcome.noShow => false,
      SessionOutcome.holiday => !consumes && makeupRequired,
      SessionOutcome.absent => !consumes && makeupRequired,
      SessionOutcome.completed => false,
      SessionOutcome.makeup => false,
    };
    return SessionResolution(
      outcome: outcome,
      consumesEntitlement: consumes,
      requiresMakeup: requiresMakeup,
      absenceQuotaUsed: outcome == SessionOutcome.absent && !consumes,
    );
  }
}

class SessionResolution {
  const SessionResolution({
    required this.outcome,
    required this.consumesEntitlement,
    required this.requiresMakeup,
    required this.absenceQuotaUsed,
  });

  final SessionOutcome outcome;
  final bool consumesEntitlement;
  final bool requiresMakeup;
  final bool absenceQuotaUsed;
}
