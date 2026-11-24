import 'package:planact/core/errors/app_error.dart';
import 'package:planact/features/actuals/domain/actual.dart';
import 'package:planact/features/sessions/domain/session_policy.dart';

/// Deliberately excludes rules requiring timing, quota, replacement or extension
/// orchestration. The caller must first establish fresh durable policy approval.
class SessionOutcomeAccounting {
  const SessionOutcomeAccounting();

  SessionResolution resolve(SessionPolicy policy, SessionOutcome outcome) {
    if (policy.autoExtendUntilUnitsConsumed ||
        policy.maxExtensionDate != null ||
        policy.partialUnitAllowed ||
        policy.userCancellationNoticeHours < 0 ||
        policy.freeAbsenceQuota < 0) {
      throw const ValidationError('Unsupported session policy accounting');
    }
    if (outcome == SessionOutcome.userCancelled ||
        outcome == SessionOutcome.lateCancelled ||
        outcome == SessionOutcome.absent ||
        outcome == SessionOutcome.makeup) {
      throw const ValidationError('Outcome requires unsupported orchestration');
    }
    final resolution = policy.resolve(outcome: outcome);
    if (resolution.requiresMakeup || resolution.absenceQuotaUsed) {
      throw const ValidationError(
        'Makeup and quota accounting are not enabled',
      );
    }
    return resolution;
  }

  ActualOutcome actualOutcome(SessionOutcome outcome) => switch (outcome) {
    SessionOutcome.completed => ActualOutcome.completed,
    SessionOutcome.providerCancelled ||
    SessionOutcome.holiday => ActualOutcome.cancelled,
    SessionOutcome.noShow => ActualOutcome.noShow,
    _ => throw const ValidationError('Unsupported session outcome'),
  };
}
