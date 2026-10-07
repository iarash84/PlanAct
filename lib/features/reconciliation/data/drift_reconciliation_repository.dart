import 'package:planact/core/application/command_gate.dart';
import 'package:drift/drift.dart';
import 'package:planact/core/database/app_database.dart' as db;
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/errors/app_error.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/reconciliation/domain/relationship_review.dart';
import 'package:planact/features/reconciliation/application/relationship_review_repository.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/reconciliation/application/reconciliation_use_cases.dart';
import 'package:planact/features/reconciliation/domain/reconciliation.dart';
import 'package:planact/features/reconciliation/data/drift_transaction_match_reader.dart';

class DriftReconciliationRepository
    implements
        CommandGateProvider,
        ReconciliationRepository,
        AtomicMatchCorrection,
        RelationshipReviewRepository {
  DriftReconciliationRepository(this.database);

  @override
  CommandGate? get commandGate => CommandGate.forOwner(database);
  final db.AppDatabase database;

  @override
  Future<List<TransactionMatch>> list() =>
      CommandGate.runFor(this, () => readTransactionMatches(database));

  RelationshipReviewEntry _entry(db.RelationshipReview row) =>
      RelationshipReviewEntry(
        id: StableId.parse(row.id),
        transactionId: StableId.parse(row.transactionId),
        revision: row.revision,
        decision: RelationshipReviewDecision.values[row.decision],
        transactionAmount: Money(
          minorUnits: row.minorUnits,
          currency: row.currency,
        ),
        allocationFingerprint: row.allocationFingerprint,
        allocationHistoryFingerprint: row.allocationHistoryFingerprint,
        remainderMinorUnits: row.remainderMinorUnits,
        recordedAt: row.recordedAt.toUtc(),
      );

  Future<RelationshipReview> _loadReview(StableId id) async {
    final transaction = await (database.select(
      database.accountEntries,
    )..where((t) => t.id.equals(id.value))).getSingleOrNull();
    final reversal =
        await (database.select(database.accountEntries)..where(
              (t) =>
                  t.type.equals(AccountEntryType.reversal.index) &
                  t.referenceId.equals(id.value),
            ))
            .get();
    if (transaction == null ||
        (transaction.type != AccountEntryType.income.index &&
            transaction.type != AccountEntryType.expense.index) ||
        reversal.isNotEmpty) {
      throw const ValidationError('Transaction is unavailable for matching');
    }
    final history =
        await (database.select(database.relationshipReviews)
              ..where((t) => t.transactionId.equals(id.value))
              ..orderBy([(t) => OrderingTerm.desc(t.revision)])
              ..limit(1))
            .get();
    return RelationshipReview.project(
      transactionId: id,
      transactionAmount: Money(
        minorUnits: transaction.minorUnits,
        currency: transaction.currency,
      ),
      matches: await list(),
      latestDecision: history.isEmpty ? null : _entry(history.single),
    );
  }

  @override
  Future<RelationshipReview> loadReview(AccountEntry transaction) =>
      CommandGate.runFor(
        this,
        () => database.transaction(() => _loadReview(transaction.id)),
      );

  @override
  Future<List<RelationshipReviewEntry>> reviewHistory(
    AccountEntry transaction,
  ) => CommandGate.runFor(this, () async {
    final rows =
        await (database.select(database.relationshipReviews)
              ..where((t) => t.transactionId.equals(transaction.id.value))
              ..orderBy([(t) => OrderingTerm.asc(t.revision)]))
            .get();
    return List.unmodifiable(rows.map(_entry));
  });

  @override
  Future<RelationshipReview> decideReview({
    required RelationshipReview expected,
    required RelationshipReviewDecision decision,
    required DateTime recordedAt,
  }) => CommandGate.runFor(
    this,
    () => database.transaction(() async {
      final current = await _loadReview(expected.transactionId);
      current.requireExpected(expected);
      final entry = current.append(decision, recordedAt);
      await database
          .into(database.relationshipReviews)
          .insert(
            db.RelationshipReviewsCompanion.insert(
              id: entry.id.value,
              transactionId: entry.transactionId.value,
              revision: entry.revision,
              decision: entry.decision.index,
              minorUnits: entry.transactionAmount.minorUnits,
              currency: entry.transactionAmount.currency,
              allocationFingerprint: entry.allocationFingerprint,
              allocationHistoryFingerprint: entry.allocationHistoryFingerprint,
              remainderMinorUnits: entry.remainderMinorUnits,
              recordedAt: entry.recordedAt,
            ),
          );
      return _loadReview(expected.transactionId);
    }),
  );

  @override
  Future<void> saveReviewedMatch(
    TransactionMatch match,
    RelationshipReview expected,
  ) => CommandGate.runFor(
    this,
    () => database.transaction(() async {
      final current = await _loadReview(match.transactionId);
      current.requireExpected(expected);
      await save(match);
    }),
  );

  Future<void> _validateSave(TransactionMatch match) async {
    final old = (await list()).where((m) => m.id == match.id).firstOrNull;
    // Allocation history is immutable. Only explicit active -> resolved state
    // transitions are accepted; a resolved match cannot be silently reactivated.
    if (old != null) {
      if (old.transactionId != match.transactionId ||
          old.transactionAmount != match.transactionAmount ||
          allocationFingerprintFor([
                TransactionMatch(
                  id: old.id,
                  transactionId: old.transactionId,
                  transactionAmount: old.transactionAmount,
                  createdAt: old.createdAt,
                  allocations: old.allocations,
                ),
              ]) !=
              allocationFingerprintFor([
                TransactionMatch(
                  id: match.id,
                  transactionId: match.transactionId,
                  transactionAmount: match.transactionAmount,
                  createdAt: match.createdAt,
                  allocations: match.allocations,
                ),
              ]) ||
          old.createdAt.millisecondsSinceEpoch ~/ 1000 !=
              match.createdAt.millisecondsSinceEpoch ~/ 1000 ||
          (old.status == MatchStatus.active &&
              match.status == MatchStatus.active &&
              old.correctedMatchId != match.correctedMatchId) ||
          (old.status != MatchStatus.active &&
              (old.status != match.status ||
                  old.correctedMatchId != match.correctedMatchId))) {
        throw const ValidationError('Match history cannot be rewritten');
      }
    }
    if (match.status != MatchStatus.active) {
      if (old == null) {
        throw const ValidationError('Only existing matches can be resolved');
      }
      return;
    }
    final review = await _loadReview(match.transactionId);
    if (review.transactionAmount != match.transactionAmount) {
      throw const ValidationError('Transaction amount changed');
    }
    if (old == null && review.isIndependent) {
      throw const ValidationError(
        'Reopen the relationship review before matching',
      );
    }
    final used =
        review.allocatedMinorUnits -
        (old?.status == MatchStatus.active ? old!.allocatedMinorUnits : 0);
    if (used + match.allocatedMinorUnits >
        review.transactionAmount.minorUnits) {
      throw const ValidationError(
        'Cumulative allocation exceeds transaction amount',
      );
    }
  }

  @override
  Future<void> saveCorrection({
    required TransactionMatch original,
    required TransactionMatch corrected,
  }) => CommandGate.runFor(
    this,
    () => database.transaction(() async {
      await save(original);
      await save(corrected);
    }),
  );

  @override
  Future<void> save(TransactionMatch match) =>
      CommandGate.runFor(this, () async {
        await CommandGate.runFor(
          this,
          () => database.transaction(() async {
            await _validateSave(match);
            await database
                .into(database.transactionMatches)
                .insertOnConflictUpdate(
                  db.TransactionMatchesCompanion(
                    id: Value(match.id.value),
                    transactionId: Value(match.transactionId.value),
                    minorUnits: Value(match.transactionAmount.minorUnits),
                    currency: Value(match.transactionAmount.currency),
                    createdAt: Value(match.createdAt.toUtc()),
                    status: Value(match.status.index),
                    correctedMatchId: Value(match.correctedMatchId?.value),
                  ),
                );
            await (database.delete(
              database.matchAllocations,
            )..where((table) => table.matchId.equals(match.id.value))).go();
            for (final allocation in match.allocations) {
              await database
                  .into(database.matchAllocations)
                  .insert(
                    db.MatchAllocationsCompanion(
                      id: Value(allocation.id.value),
                      matchId: Value(allocation.matchId.value),
                      occurrenceId: Value(allocation.occurrenceId.value),
                      minorUnits: Value(allocation.amount.minorUnits),
                      currency: Value(allocation.amount.currency),
                      type: Value(allocation.type.index),
                    ),
                  );
            }
          }),
        );
      });
}
