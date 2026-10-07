import 'package:planact/core/database/app_database.dart' as db;
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/reconciliation/domain/reconciliation.dart';

/// Reads all match history within the caller's command/transaction scope.
Future<List<TransactionMatch>> readTransactionMatches(
  db.AppDatabase database,
) async {
  final matches = await database.select(database.transactionMatches).get();
  final allocations = await database.select(database.matchAllocations).get();
  final byMatch = <String, List<MatchAllocation>>{};
  for (final row in allocations) {
    (byMatch[row.matchId] ??= []).add(
      MatchAllocation(
        id: StableId.parse(row.id),
        matchId: StableId.parse(row.matchId),
        occurrenceId: StableId.parse(row.occurrenceId),
        amount: Money(minorUnits: row.minorUnits, currency: row.currency),
        type: AllocationType.values[row.type],
      ),
    );
  }
  return matches
      .map(
        (row) => TransactionMatch(
          id: StableId.parse(row.id),
          transactionId: StableId.parse(row.transactionId),
          transactionAmount: Money(
            minorUnits: row.minorUnits,
            currency: row.currency,
          ),
          createdAt: row.createdAt.toUtc(),
          allocations: byMatch[row.id] ?? const [],
          status: MatchStatus.values[row.status],
          correctedMatchId: row.correctedMatchId == null
              ? null
              : StableId.parse(row.correctedMatchId!),
        ),
      )
      .toList(growable: false);
}
