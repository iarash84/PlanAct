import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/finance/application/finance_use_cases.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/reconciliation/application/relationship_review_repository.dart';
import 'package:planact/features/reconciliation/domain/relationship_review.dart';

class RelationshipQueueItem {
  const RelationshipQueueItem(this.transaction, this.review);
  final AccountEntry transaction;
  final RelationshipReview review;
  bool get selectable =>
      review.remainderMinorUnits > 0 && !review.isIndependent;
}

class RelationshipQueueSnapshot {
  const RelationshipQueueSnapshot(this.items, this.hasNext);
  final List<RelationshipQueueItem> items;
  final bool hasNext;
}

/// Reads only review projections, never commitment plans or matching targets.
/// Selection is bounded; the existing finance list API still reads all entries.
class RelationshipQueue {
  const RelationshipQueue(this.finance, this.reviews);
  final FinanceRepository finance;
  final RelationshipReviewRepository reviews;

  Future<RelationshipQueueSnapshot> load({
    int page = 0,
    String query = '',
    AccountEntryType? type,
    bool independent = false,
  }) async {
    if (page < 0) throw ArgumentError('Invalid page');
    final entries = await finance.listEntries();
    final reversed = entries
        .where((e) => e.type == AccountEntryType.reversal)
        .map((e) => e.referenceId)
        .toSet();
    final candidates =
        entries
            .where(
              (e) =>
                  (e.type == AccountEntryType.income ||
                      e.type == AccountEntryType.expense) &&
                  !reversed.contains(e.id.value) &&
                  (type == null || e.type == type) &&
                  (e.note ?? '').contains(query),
            )
            .toList()
          ..sort((a, b) {
            final date = b.occurredAt.compareTo(a.occurredAt);
            return date != 0 ? date : a.id.value.compareTo(b.id.value);
          });
    final items = <RelationshipQueueItem>[];
    var skipped = 0;
    for (final entry in candidates) {
      // A read failure is surfaced, not silently interpreted as ineligibility.
      final review = await reviews.loadReview(entry);
      if (review.remainderMinorUnits <= 0 ||
          review.isIndependent != independent) {
        continue;
      }
      if (skipped++ < page * BulkRelationshipReview.pageSize) continue;
      if (items.length == BulkRelationshipReview.pageSize) {
        return RelationshipQueueSnapshot(List.unmodifiable(items), true);
      }
      items.add(RelationshipQueueItem(entry, review));
    }
    return RelationshipQueueSnapshot(List.unmodifiable(items), false);
  }
}

/// Temporary explicitly confirmed tokens. Retry never upgrades stale approval.
class BulkRelationshipReview {
  BulkRelationshipReview(this.reviews);
  static const pageSize = 50;
  final RelationshipReviewRepository reviews;
  bool cancelled = false;
  void cancel() => cancelled = true;

  Future<void> run(
    Iterable<RelationshipQueueItem> selection, {
    required void Function(RelationshipQueueItem) onStarted,
    required void Function(RelationshipQueueItem, RelationshipReview?)
    onFinished,
  }) async {
    final snapshots = List<RelationshipQueueItem>.unmodifiable(selection);
    final ids = <StableId>{};
    if (snapshots.length > pageSize ||
        snapshots.any(
          (item) =>
              !ids.add(item.transaction.id) ||
              !item.selectable ||
              item.transaction.id != item.review.transactionId ||
              (item.transaction.type != AccountEntryType.income &&
                  item.transaction.type != AccountEntryType.expense),
        )) {
      throw ArgumentError('Expected bounded eligible relationship selection');
    }
    for (final item in snapshots) {
      if (cancelled) break;
      onStarted(item);
      RelationshipReview? result;
      try {
        result = await reviews.decideReview(
          expected: item.review,
          decision: RelationshipReviewDecision.independent,
          recordedAt: DateTime.now().toUtc(),
        );
      } catch (_) {
        // Caller displays per-item failure and retains the original token.
      }
      onFinished(item, result);
      await Future<void>.delayed(Duration.zero);
    }
  }
}
