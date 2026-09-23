import 'package:drift/drift.dart';
import 'package:planact/core/database/app_database.dart' as db;
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/actuals/application/actual_use_cases.dart';
import 'package:planact/features/actuals/domain/actual.dart';

class DriftActualRepository implements ActualRepository {
  DriftActualRepository(this.database);
  final db.AppDatabase database;

  @override
  Future<List<Actual>> list() async {
    final actualRows = await database.select(database.actuals).get();
    final evidenceRows = await database.select(database.evidences).get();
    return actualRows
        .map((row) {
          final evidence = evidenceRows
              .where((item) => item.actualId == row.id)
              .map(_evidence)
              .toList(growable: false);
          return Actual(
            id: StableId.parse(row.id),
            occurrenceId: StableId.parse(row.occurrenceId),
            outcome: ActualOutcome.values[row.outcome],
            recordedAt: row.recordedAt.toUtc(),
            note: row.note,
            evidence: evidence,
          );
        })
        .toList(growable: false);
  }

  @override
  Future<void> save(Actual actual) async {
    await database.transaction(() async {
      await database
          .into(database.actuals)
          .insertOnConflictUpdate(
            db.ActualsCompanion(
              id: Value(actual.id.value),
              occurrenceId: Value(actual.occurrenceId.value),
              outcome: Value(actual.outcome.index),
              recordedAt: Value(actual.recordedAt.toUtc()),
              note: Value(actual.note),
            ),
          );
      for (final item in actual.evidence) {
        await database
            .into(database.evidences)
            .insertOnConflictUpdate(
              db.EvidencesCompanion(
                id: Value(item.id.value),
                actualId: Value(item.actualId.value),
                type: Value(item.type.index),
                value: Value(item.value),
                createdAt: Value(item.createdAt.toUtc()),
              ),
            );
      }
    });
  }

  Evidence _evidence(db.Evidence row) => Evidence(
    id: StableId.parse(row.id),
    actualId: StableId.parse(row.actualId),
    type: EvidenceType.values[row.type],
    value: row.value,
    createdAt: row.createdAt.toUtc(),
  );
}
