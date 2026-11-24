import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/scheduling/domain/occurrence.dart';
import 'package:planact/features/sessions/domain/session_policy.dart';

/// Infrastructure seam, not an approval flag supplied by presentation code.
/// Implementations must read explicit durable approval for this exact current
/// policy using the writer's database transaction. A legacy policy row alone is
/// not approval. No production implementation exists until that contract is set.
abstract interface class SessionPolicyApprovalReader {
  Future<bool> isExplicitlyApproved({
    required StableId cycleId,
    required SessionPolicy policy,
  });
}

/// Foundation only: callers must separately reconcile reminders after commit.
/// Reopening remains the existing actual command and never restores credit.
abstract interface class SessionOutcomeWriter {
  Future<Occurrence> recordSessionOutcome({
    required Occurrence expected,
    required SessionOutcome outcome,
    required DateTime recordedAt,
    String? note,
  });
}
