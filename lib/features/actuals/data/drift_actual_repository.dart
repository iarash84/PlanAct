import 'package:planact/core/application/command_gate.dart';
import 'package:drift/drift.dart';
import 'package:planact/core/database/app_database.dart' as db;
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/actuals/application/actual_use_cases.dart';
import 'package:planact/features/actuals/domain/actual.dart';
import 'package:planact/core/errors/app_error.dart';
import 'package:planact/features/scheduling/domain/occurrence.dart';
import 'package:planact/features/commitments/data/drift_commitment_plan_repository.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';

class DriftActualRepository
    implements CommandGateProvider, ActualRepository, OccurrenceActualWriter {
  DriftActualRepository(this.database);

  @override
  CommandGate? get commandGate => CommandGate.forOwner(database);
  final db.AppDatabase database;

  @override
  Future<List<Actual>> list() => CommandGate.runFor(this, () async {
    final actualRows = await database
        .customSelect(
          'SELECT * FROM actuals ORDER BY rowid',
          readsFrom: {database.actuals},
        )
        .get();
    final evidenceRows = await database.select(database.evidences).get();
    return actualRows
        .map((result) {
          final row = database.actuals.map(result.data);
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
  });

  @override
  Future<void> save(Actual actual) => CommandGate.runFor(this, () async {
    await database.transaction(() async {
      final existing = await (database.select(
        database.actuals,
      )..where((t) => t.id.equals(actual.id.value))).getSingleOrNull();
      if (existing != null &&
          (existing.occurrenceId != actual.occurrenceId.value ||
              existing.outcome != actual.outcome.index ||
              existing.recordedAt.millisecondsSinceEpoch ~/ 1000 !=
                  actual.recordedAt.millisecondsSinceEpoch ~/ 1000 ||
              existing.note != actual.note)) {
        throw const ValidationError(
          'Historical actuals cannot be overwritten.',
        );
      }
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
  });

  @override
  Future<Occurrence> recordOccurrenceActual({
    required Occurrence expected,
    required ActualOutcome outcome,
    required DateTime recordedAt,
    String? note,
  }) => CommandGate.runFor(
    this,
    () => database.transaction(() async {
      final row = await (database.select(
        database.occurrences,
      )..where((t) => t.id.equals(expected.id.value))).getSingleOrNull();
      if (row == null ||
          row.status != expected.status.index ||
          row.isManualOverride != expected.isManualOverride ||
          row.scheduleDefinitionId != expected.scheduleDefinitionId.value) {
        throw const ValidationError(
          'Occurrence changed; reload before recording.',
        );
      }
      final cycle = await (database.select(
        database.commitmentCycles,
      )..where((t) => t.id.equals(row.cycleId))).getSingle();
      final plan = await DriftCommitmentPlanRepository(database)
          .findByCommitmentId(StableId.parse(cycle.commitmentId));
      final current = plan?.occurrences
          .where((item) => item.id == expected.id)
          .firstOrNull;
      if (current == null ||
          current.cycleId != expected.cycleId ||
          current.occurrenceKey != expected.occurrenceKey ||
          !_sameValue(
            current.originalScheduledAt,
            expected.originalScheduledAt,
          ) ||
          !_sameValue(
            current.currentScheduledAt,
            expected.currentScheduledAt,
          )) {
        throw const ValidationError('Occurrence time changed; reload first.');
      }
      final status = statusForActual(current, outcome);
      if (note != null && note.trim().isEmpty) {
        throw const ValidationError('Actual note cannot be empty');
      }
      final updated = Occurrence(
        id: expected.id,
        cycleId: expected.cycleId,
        scheduleDefinitionId: expected.scheduleDefinitionId,
        occurrenceKey: expected.occurrenceKey,
        originalScheduledAt: expected.originalScheduledAt,
        currentScheduledAt: expected.currentScheduledAt,
        status: status,
        isManualOverride: expected.isManualOverride,
      );
      final timestamp = recordedAt.toUtc();
      await database
          .into(database.actuals)
          .insert(
            db.ActualsCompanion.insert(
              id: StableId.generate().value,
              occurrenceId: expected.id.value,
              outcome: outcome.index,
              recordedAt: timestamp,
              note: Value(note),
            ),
          );
      await (database.update(database.occurrences)
            ..where((t) => t.id.equals(expected.id.value)))
          .write(db.OccurrencesCompanion(status: Value(status.index)));
      return updated;
    }),
  );

  bool _sameValue(Object a, Object b) {
    if (a is LocalDate || b is LocalDate) return a == b;
    return a is DateTime && b is DateTime && a == b && a.isUtc == b.isUtc;
  }

  Evidence _evidence(db.Evidence row) => Evidence(
    id: StableId.parse(row.id),
    actualId: StableId.parse(row.actualId),
    type: EvidenceType.values[row.type],
    value: row.value,
    createdAt: row.createdAt.toUtc(),
  );
}
