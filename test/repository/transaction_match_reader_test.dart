import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/database/app_database.dart' as db;
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/finance/data/drift_financial_expectation_repository.dart';
import 'package:planact/features/reconciliation/data/drift_reconciliation_repository.dart';
import 'package:planact/features/reconciliation/domain/reconciliation.dart';

void main() {
  test('both readers map interleaved allocations and all history after restart', () async {
    final directory = await Directory.systemTemp.createTemp('match-reader-');
    final file = File('${directory.path}/state.sqlite');
    var database = db.AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(() async {
      await database.close();
      await directory.delete(recursive: true);
    });
    expect(await DriftReconciliationRepository(database).list(), isEmpty);
    expect(
      await DriftFinancialExpectationRepository(database).listMatches(),
      isEmpty,
    );
    final account = StableId.generate().value;
    final transaction = StableId.generate().value;
    final commitment = StableId.generate().value;
    final cycle = StableId.generate().value;
    final schedule = StableId.generate().value;
    final occurrences = List.generate(3, (_) => StableId.generate().value);
    final matches = List.generate(3, (_) => StableId.generate().value);
    final allocations = List.generate(6, (_) => StableId.generate().value);
    final createdAt = DateTime.utc(2026, 10, 7, 12, 34, 56);
    await database.transaction(() async {
      await database.customStatement(
        "INSERT INTO financial_accounts(id,name,currency,type,status) VALUES (?, 'حساب', 'IRR', 0, 0)",
        [account],
      );
      await database.customStatement(
        "INSERT INTO account_entries(id,account_id,type,minor_units,currency,occurred_at) VALUES (?, ?, 1, 1000, 'IRR', 0)",
        [transaction, account],
      );
      await database.customStatement(
        "INSERT INTO commitments(id,title,created_at,status) VALUES (?, 'کلاس', 0, 0)",
        [commitment],
      );
      await database.customStatement(
        'INSERT INTO commitment_cycles VALUES (?, ?, 0, 0, NULL, NULL, NULL, 0, 0, 0)',
        [cycle, commitment],
      );
      await database.customStatement(
        "INSERT INTO schedule_definitions VALUES (?, ?, 0, 0, '2026-01-01', NULL, NULL, NULL, NULL, NULL, NULL, 1, '2026-01-01', 90)",
        [schedule, cycle],
      );
      for (var i = 0; i < occurrences.length; i++) {
        await database.customStatement(
          "INSERT INTO occurrences VALUES (?, ?, ?, ?, 0, '2026-01-01', '2026-01-01', 0, 0)",
          [occurrences[i], cycle, schedule, 'key-$i'],
        );
      }
      for (var i = 0; i < matches.length; i++) {
        await database
            .into(database.transactionMatches)
            .insert(
              db.TransactionMatchesCompanion.insert(
                id: matches[i],
                transactionId: transaction,
                minorUnits: 1000,
                currency: 'IRR',
                createdAt: createdAt.toLocal(),
                status: MatchStatus.values[i].index,
                correctedMatchId: Value(i == 1 ? matches[0] : null),
              ),
            );
      }
      // Two rounds deliberately interleave rows belonging to different matches.
      for (var i = 0; i < allocations.length; i++) {
        await database
            .into(database.matchAllocations)
            .insert(
              db.MatchAllocationsCompanion.insert(
                id: allocations[i],
                matchId: matches[i % 3],
                occurrenceId: occurrences[i % 3],
                minorUnits: 100 + i,
                currency: 'IRR',
                type: AllocationType.values[i % 3].index,
              ),
            );
      }
    });
    Future<void> verify() async {
      for (final loaded in [
        await DriftReconciliationRepository(database).list(),
        await DriftFinancialExpectationRepository(database).listMatches(),
      ]) {
        expect(loaded.map((m) => m.id.value), matches);
        for (var i = 0; i < loaded.length; i++) {
          final match = loaded[i];
          expect(match.transactionId.value, transaction);
          expect(match.transactionAmount.minorUnits, 1000);
          expect(match.transactionAmount.currency, 'IRR');
          expect(match.createdAt, createdAt);
          expect(match.createdAt.isUtc, true);
          expect(match.status, MatchStatus.values[i]);
          expect(match.correctedMatchId?.value, i == 1 ? matches[0] : null);
          expect(match.allocations.map((a) => a.id.value), [
            allocations[i],
            allocations[i + 3],
          ]);
          for (var j = 0; j < match.allocations.length; j++) {
            final allocation = match.allocations[j];
            expect(allocation.matchId, match.id);
            expect(allocation.occurrenceId.value, occurrences[i]);
            expect(allocation.amount.minorUnits, 100 + i + j * 3);
            expect(allocation.amount.currency, 'IRR');
            expect(allocation.type, AllocationType.values[i]);
          }
        }
      }
    }

    await verify();
    await database.close();
    database = db.AppDatabase.forTesting(NativeDatabase(file));
    await verify();
  });
}
