import 'package:planact/core/ids/stable_id.dart';

/// Independent corrections: schedule termination is never package credit.
class CommitmentCorrectionRequest {
  const CommitmentCorrectionRequest({
    required this.commitmentId,
    required this.reason,
    this.scheduleCount,
    this.creditDelta,
  });
  final StableId commitmentId;
  final String reason;
  final int? scheduleCount;
  final int? creditDelta;
}

class CommitmentCorrectionPreview {
  const CommitmentCorrectionPreview({
    required this.request,
    required this.fingerprint,
    required this.beforeCount,
    required this.afterCount,
    required this.futureAdded,
    required this.futureCancelled,
    required this.remainingBefore,
    required this.remainingAfter,
    required this.hasHistory,
  });
  final CommitmentCorrectionRequest request;
  final String fingerprint;
  final int? beforeCount;
  final int? afterCount;
  final int futureAdded;
  final int futureCancelled;
  final int? remainingBefore;
  final int? remainingAfter;
  final bool hasHistory;
}

class CommitmentCorrectionRecord {
  const CommitmentCorrectionRecord({
    required this.reason,
    required this.at,
    required this.beforeCount,
    required this.afterCount,
    required this.beforeRemaining,
    required this.afterRemaining,
  });
  final String reason;
  final DateTime at;
  final int? beforeCount;
  final int? afterCount;
  final int? beforeRemaining;
  final int? afterRemaining;
}

abstract interface class CommitmentCorrectionRepository {
  Future<List<CommitmentCorrectionRecord>> history(StableId commitmentId);
  Future<CommitmentCorrectionPreview> preview(
    CommitmentCorrectionRequest request,
    DateTime now,
  );
  Future<void> confirm(CommitmentCorrectionPreview preview, DateTime now);
}
