import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/inbox/application/inbox_use_cases.dart';
import 'package:planact/features/inbox/domain/inbox.dart';

/// One explicitly confirmed, temporary page selection. Never persists a batch or
/// refreshes snapshots on retry: the atomic writer must reject stale revisions.
class BulkInboxReject {
  BulkInboxReject(this.inbox);

  static const pageSize = 50;
  final InboxUseCases inbox;
  bool cancelled = false;

  static bool eligible(InboxSuggestion suggestion) =>
      suggestion.status == SuggestionStatus.pending ||
      suggestion.status == SuggestionStatus.edited;

  void cancel() => cancelled = true;

  Future<void> run(
    Iterable<InboxSuggestion> selection, {
    required void Function(InboxSuggestion) onStarted,
    required void Function(InboxSuggestion, bool) onFinished,
  }) async {
    final snapshots = List<InboxSuggestion>.unmodifiable(selection);
    if (snapshots.length > pageSize ||
        snapshots.map((s) => s.id).toSet().length != snapshots.length ||
        snapshots.any((s) => !eligible(s))) {
      throw ArgumentError('Expected a bounded eligible Inbox selection');
    }
    for (final snapshot in snapshots) {
      if (cancelled) break;
      onStarted(snapshot);
      var success = false;
      try {
        await inbox.reject(snapshot);
        success = true;
      } catch (_) {
        // Per-item failure is surfaced by the caller; keep the original snapshot.
      }
      onFinished(snapshot, success);
      // Yield between items so cancellation/navigation can stop future writes.
      await Future<void>.delayed(Duration.zero);
    }
  }
}

class InboxRejectProgress {
  final Map<StableId, InboxSuggestion> failures = {};
  int attempted = 0;
  int succeeded = 0;
}
