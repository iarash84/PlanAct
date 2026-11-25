import 'dart:convert';

import 'package:planact/features/actuals/data/actual_evidence_metadata.dart';
import 'package:planact/features/commitments/data/cycle_write_guard.dart';
import 'package:planact/core/application/command_gate.dart';
import 'package:planact/core/database/undo_journal.dart';
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
    implements
        CommandGateProvider,
        ActualRepository,
        OccurrenceActualWriter,
        ActualEvidenceWriter {
  DriftActualRepository(this.database);

  @override
  CommandGate? get commandGate => CommandGate.forOwner(database);
  final db.AppDatabase database;

  @override
  Future<List<Actual>> list() => CommandGate.runFor(
    this,
    () => database.transaction(() async {
      final actualRows = await database
          .customSelect(
            'SELECT * FROM actuals ORDER BY rowid',
            readsFrom: {database.actuals},
          )
          .get();
      final evidenceRows = await database
          .customSelect(
            'SELECT * FROM evidences ORDER BY rowid',
            readsFrom: {database.evidences},
          )
          .get();
      final originals = evidenceRows
          .map((r) => _evidence(database.evidences.map(r.data)))
          .toList();
      final metadata = await _metadata();
      final order = ActualEvidenceMetadata.order(
        metadata,
        actualIds: actualRows.map((r) => r.read<String>('id')).toList(),
        evidenceIds: originals.map((e) => e.id.value).toList(),
      );
      final evidence = ActualEvidenceMetadata.validate(
        metadata: metadata,
        actualIds: order['actuals']!,
        originals: originals,
      );
      final positions = {
        for (var i = 0; i < order['actuals']!.length; i++)
          order['actuals']![i]: i,
      };
      actualRows.sort(
        (a, b) => positions[a.read<String>('id')]!.compareTo(
          positions[b.read<String>('id')]!,
        ),
      );
      return actualRows
          .map((result) {
            final row = database.actuals.map(result.data);
            final items = order['evidence']!
                .map((id) => evidence[id]!)
                .where((item) => item.actualId.value == row.id)
                .toList(growable: false);
            return Actual(
              id: StableId.parse(row.id),
              occurrenceId: StableId.parse(row.occurrenceId),
              outcome: ActualOutcome.values[row.outcome],
              recordedAt: row.recordedAt.toUtc(),
              note: row.note,
              evidence: items,
            );
          })
          .toList(growable: false);
    }),
  );

  @override
  Future<void> save(Actual actual) => CommandGate.runFor(this, () async {
    await database.transaction(() async {
      await UndoJournal(database).admitWriter();
      await requireWritableOccurrence(
        database,
        actual.occurrenceId.value,
        requireActiveOwner: false,
      );
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
      if (existing != null) {
        final current = (await list()).singleWhere((a) => a.id == actual.id);
        for (final item in actual.evidence) {
          final durable = current.evidence
              .where((e) => e.id == item.id)
              .firstOrNull;
          if (durable == null || !_sameEvidence(durable, item)) {
            throw const ValidationError(
              'Use revision-checked evidence command',
            );
          }
        }
        return;
      }
      await _pinOrder();
      for (final item in actual.evidence) {
        if (item.actualId != actual.id ||
            item.revision != 0 ||
            item.isDiscarded ||
            item.history.isNotEmpty) {
          throw const ValidationError('Invalid original evidence');
        }
      }
      await database
          .into(database.actuals)
          .insert(
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
            .insert(
              db.EvidencesCompanion(
                id: Value(item.id.value),
                actualId: Value(item.actualId.value),
                type: Value(item.type.index),
                value: Value(item.value),
                createdAt: Value(item.createdAt.toUtc()),
              ),
            );
      }
      await _appendOrder(
        actual.id.value,
        actual.evidence.map((e) => e.id.value).toList(),
      );
    });
  });

  Future<Map<String, String>> _metadata() async => {
    for (final r
        in await database
            .customSelect('SELECT key, value FROM schema_metadata')
            .get())
      r.read<String>('key'): r.read<String>('value'),
  };

  Future<void> _pinOrder() async {
    final metadata = await _metadata();
    final actuals = await database
        .customSelect('SELECT id FROM actuals ORDER BY rowid')
        .get();
    final evidence = await database
        .customSelect('SELECT id FROM evidences ORDER BY rowid')
        .get();
    final order = ActualEvidenceMetadata.order(
      metadata,
      actualIds: actuals.map((r) => r.read<String>('id')).toList(),
      evidenceIds: evidence.map((r) => r.read<String>('id')).toList(),
    );
    if (!metadata.containsKey(ActualEvidenceMetadata.orderKey)) {
      await database.writeMetadata(
        ActualEvidenceMetadata.orderKey,
        jsonEncode({'version': 1, ...order}),
      );
    }
  }

  Future<void> _appendOrder(String? actualId, List<String> evidenceIds) async {
    final map = jsonDecode(
      (await _metadata())[ActualEvidenceMetadata.orderKey]!,
    ) as Map<String, dynamic>;
    if (actualId != null) (map['actuals'] as List).add(actualId);
    (map['evidence'] as List).addAll(evidenceIds);
    await database.writeMetadata(
      ActualEvidenceMetadata.orderKey,
      jsonEncode(map),
    );
  }

  bool _sameEvidence(Evidence a, Evidence b) =>
      a.id == b.id &&
      a.actualId == b.actualId &&
      a.type == b.type &&
      a.value == b.value &&
      a.revision == b.revision &&
      a.isDiscarded == b.isDiscarded &&
      a.createdAt.millisecondsSinceEpoch ~/ 1000 ==
          b.createdAt.millisecondsSinceEpoch ~/ 1000;

  @override
  Future<void> mutateTextEvidence({
    required StableId actualId,
    Evidence? expected,
    required String? value,
  }) => CommandGate.runFor(
    this,
    () => database.transaction(() async {
      await UndoJournal(database).admitWriter();
      final actual = await (database.select(
        database.actuals,
      )..where((t) => t.id.equals(actualId.value))).getSingleOrNull();
      if (actual == null) throw const ValidationError('Actual not found');
      await requireWritableOccurrence(
        database,
        actual.occurrenceId,
        requireActiveOwner: false,
      );
      if (value != null && value.trim().isEmpty) {
        throw const ValidationError('Evidence value cannot be empty');
      }
      final current = (await list()).singleWhere((a) => a.id == actualId);
      if (expected == null) {
        if (value == null) throw const ValidationError('Nothing to discard');
        await _pinOrder();
        final id = StableId.generate();
        await database
            .into(database.evidences)
            .insert(
              db.EvidencesCompanion.insert(
                id: id.value,
                actualId: actualId.value,
                type: EvidenceType.note.index,
                value: value,
                createdAt: DateTime.now().toUtc(),
              ),
            );
        await _appendOrder(null, [id.value]);
        return;
      }
      final durable = current.evidence
          .where((e) => e.id == expected.id)
          .firstOrNull;
      if (durable == null ||
          !_sameEvidence(durable, expected) ||
          durable.type != EvidenceType.note ||
          durable.isDiscarded) {
        throw const ValidationError('Evidence changed; reload before saving');
      }
      if (value == durable.value) return;
      await _pinOrder();
      final history = [
        ...durable.history,
        EvidenceRevision(
          revision: durable.revision + 1,
          value: value ?? durable.value,
          isDiscarded: value == null,
          recordedAt: DateTime.now().toUtc(),
        ),
      ];
      final event = history.last;
      await database.customStatement(
        'INSERT INTO schema_metadata (key, value) VALUES (?, ?)',
        [
          '${ActualEvidenceMetadata.historyPrefix}${durable.id.value}:${event.revision}',
          ActualEvidenceMetadata.encodeEvent(durable, event),
        ],
      );
      await database.writeMetadata(
        '${ActualEvidenceMetadata.headPrefix}${durable.id.value}',
        '${event.revision}',
      );
    }),
  );

  @override
  Future<Occurrence> recordOccurrenceActual({
    required Occurrence expected,
    required ActualOutcome outcome,
    required DateTime recordedAt,
    String? note,
  }) => CommandGate.runFor(
    this,
    () => database.transaction(() async {
      final journal = UndoJournal(database);
      await journal.admitWriter();
      await requireWritableOccurrence(
        database,
        expected.id.value,
        requireActiveOwner: false,
      );
      final history = (await list())
          .where((a) => a.occurrenceId == expected.id)
          .toList();
      if (history.length != expected.resultRevision ||
          (outcome == ActualOutcome.reopened &&
              expected.status == OccurrenceStatus.pendingDecision &&
              (history.isEmpty ||
                  history.last.outcome != ActualOutcome.partial))) {
        throw const ValidationError('Result changed; reload before recording');
      }
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
          .findByCycleId(StableId.parse(cycle.id));
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
        resultRevision: history.length + 1,
      );
      await _pinOrder();
      final timestamp = recordedAt.toUtc();
      final actualId = StableId.generate().value;
      await database
          .into(database.actuals)
          .insert(
            db.ActualsCompanion.insert(
              id: actualId,
              occurrenceId: expected.id.value,
              outcome: outcome.index,
              recordedAt: timestamp,
              note: Value(note),
            ),
          );
      await _appendOrder(actualId, []);
      await (database.update(database.occurrences)
            ..where((t) => t.id.equals(expected.id.value)))
          .write(db.OccurrencesCompanion(status: Value(status.index)));
      await journal.append(
        owner: 'actual:${expected.id.value}',
        before: {
          'status': expected.status.index,
          'actualId': history.isEmpty ? null : history.last.id.value,
        },
        after: {'status': status.index, 'actualId': actualId},
        undoOf: outcome == ActualOutcome.reopened && history.isNotEmpty
            ? history.last.id.value
            : null,
      );
      await database.writeMetadata(
        'reminder_reopen_v1:${expected.id.value}',
        outcome == ActualOutcome.reopened ? '1' : '0',
      );
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
