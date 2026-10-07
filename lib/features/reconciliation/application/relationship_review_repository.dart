import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/reconciliation/domain/reconciliation.dart';
import 'package:planact/features/reconciliation/domain/relationship_review.dart';

/// Optional capability: implementations must compare and mutate atomically.
/// The supplied transaction is a read hint; production reloads durable identity.
abstract interface class RelationshipReviewRepository {
  Future<RelationshipReview> loadReview(AccountEntry transaction);
  Future<List<RelationshipReviewEntry>> reviewHistory(AccountEntry transaction);
  Future<RelationshipReview> decideReview({
    required RelationshipReview expected,
    required RelationshipReviewDecision decision,
    required DateTime recordedAt,
  });
  Future<void> saveReviewedMatch(
    TransactionMatch match,
    RelationshipReview expected,
  );
}
