import 'package:drift/drift.dart';
import 'package:planact/core/database/app_database.dart' as db;
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/reconciliation/application/reconciliation_use_cases.dart';
import 'package:planact/features/reconciliation/domain/reconciliation.dart';

class DriftReconciliationRepository implements ReconciliationRepository {
  DriftReconciliationRepository(this.database);
  final db.AppDatabase database;

  @override
  Future<List<TransactionMatch>> list() async {
    final matches = await database.select(database.transactionMatches).get();
    final allocations = await database.select(database.matchAllocations).get();
    return matches
        .map((row) {
          final items = allocations
              .where((item) => item.matchId == row.id)
              .map(
                (item) => MatchAllocation(
                  id: StableId.parse(item.id),
                  matchId: StableId.parse(item.matchId),
                  occurrenceId: StableId.parse(item.occurrenceId),
                  amount: Money(
                    minorUnits: item.minorUnits,
                    currency: item.currency,
                  ),
                  type: AllocationType.values[item.type],
                ),
              )
              .toList(growable: false);
          return TransactionMatch(
            id: StableId.parse(row.id),
            transactionId: StableId.parse(row.transactionId),
            transactionAmount: Money(
              minorUnits: row.minorUnits,
              currency: row.currency,
            ),
            createdAt: row.createdAt.toUtc(),
            allocations: items,
            status: MatchStatus.values[row.status],
            correctedMatchId: row.correctedMatchId == null
                ? null
                : StableId.parse(row.correctedMatchId!),
          );
        })
        .toList(growable: false);
  }

  @override
  Future<void> save(TransactionMatch match) async {
    await database.transaction(() async {
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
      for (final allocation in match.allocations) {
        await database
            .into(database.matchAllocations)
            .insertOnConflictUpdate(
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
    });
  }
}
