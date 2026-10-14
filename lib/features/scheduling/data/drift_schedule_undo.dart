import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:planact/core/application/command_gate.dart';
import 'package:planact/core/application/undo_token.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/core/database/undo_journal.dart';
import 'package:planact/core/errors/app_error.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/commitments/data/drift_commitment_plan_repository.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/scheduling/application/schedule_undo.dart';
import 'package:planact/features/scheduling/domain/occurrence.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';

mixin ScheduleUndoPersistence
    implements ScheduleUndoRepository, CommandGateProvider {
  AppDatabase get database;

  Future<Map<String, dynamic>> _snapshot(StableId id) async {
    Future<List<Map<String, dynamic>>> rows(String sql) async =>
        (await database
                .customSelect(sql, variables: [Variable(id.value)])
                .get())
            .map((r) => r.data)
            .toList();
    const cycles = 'SELECT id FROM commitment_cycles WHERE commitment_id = ?';
    const occurrences =
        'SELECT id FROM occurrences WHERE cycle_id IN ($cycles)';
    return {
      'owner': await rows('SELECT id,status FROM commitments WHERE id = ?'),
      'cycles': await rows(
        'SELECT * FROM commitment_cycles WHERE commitment_id = ? ORDER BY id',
      ),
      'schedules': await rows(
        'SELECT * FROM schedule_definitions WHERE cycle_id IN ($cycles) ORDER BY version,id',
      ),
      'occurrences': await rows(
        'SELECT * FROM occurrences WHERE cycle_id IN ($cycles) ORDER BY id',
      ),
      'actuals': await rows(
        'SELECT * FROM actuals WHERE occurrence_id IN ($occurrences) ORDER BY rowid',
      ),
      'allocations': await rows(
        'SELECT * FROM match_allocations WHERE occurrence_id IN ($occurrences) ORDER BY id',
      ),
      'credit': await rows(
        'SELECT * FROM entitlement_ledger_entries WHERE plan_id IN (SELECT id FROM entitlement_plans WHERE cycle_id IN ($cycles)) ORDER BY id',
      ),
      'expectations': await rows(
        'SELECT * FROM financial_expectations WHERE occurrence_id IN ($occurrences) ORDER BY id',
      ),
      'rules': await rows(
        'SELECT * FROM reminder_rules WHERE occurrence_id IN ($occurrences) ORDER BY id',
      ),
      'replacements': await rows(
        'SELECT * FROM replacement_occurrences WHERE original_occurrence_id IN ($occurrences) ORDER BY id',
      ),
    };
  }

  @override
  Future<T> recordScheduleEdit<T>(StableId id, Future<T> Function() edit) =>
      CommandGate.runFor(
        this,
        () => database.transaction(() async {
          final journal = UndoJournal(database);
          await journal.admitWriter();
          final before = await _snapshot(id);
          final result = await edit();
          final after = await _snapshot(id);
          if (jsonEncode(before) != jsonEncode(after)) {
            await journal.append(
              owner: 'schedule:${id.value}',
              before: before,
              after: after,
            );
          }
          return result;
        }),
      );

  @override
  Future<UndoToken?> scheduleUndo(StableId id) =>
      CommandGate.runFor(this, () async {
        final event = await UndoJournal(database)
            .latest('schedule:${id.value}');
        return event != null && event['undoOf'] == null
            ? UndoToken(event['id'] as String)
            : null;
      });

  @override
  Future<List<Occurrence>> undoSchedule(
    StableId id,
    UndoToken expected,
    DateTime now,
  ) => CommandGate.runFor(
    this,
    () => database.transaction(() async {
      final journal = UndoJournal(database);
      await journal.admitWriter();
      final current = await _snapshot(id);
      final event = await journal.latest('schedule:${id.value}');
      journal.requireCurrent(event, expected.id, current);
      final before = event!['before'] as Map<String, dynamic>;
      final owners = current['owner'] as List;
      if (owners.length != 1 ||
          (owners.single as Map)['status'] != CommitmentStatus.active.index) {
        throw const ValidationError(
          'Only an active commitment can undo its schedule',
        );
      }
      final previousRows = {
        for (final r in before['occurrences'] as List)
          (r as Map)['id'] as String: Map<String, dynamic>.from(r),
      };
      final changed = <Map<String, dynamic>>[];
      final today = LocalDate.fromDateTime(now);
      for (final raw in current['occurrences'] as List) {
        final row = Map<String, dynamic>.from(raw as Map);
        final prior = previousRows[row['id']];
        if (prior == null || jsonEncode(prior) == jsonEncode(row)) continue;
        if ({
              OccurrenceStatus.completed.index,
              OccurrenceStatus.cancelled.index,
              OccurrenceStatus.skipped.index,
              OccurrenceStatus.pendingDecision.index,
            }.contains(row['status']) ||
            _isPast(row['current_scheduled_value'] as String, now) ||
            _isPast(prior['current_scheduled_value'] as String, now) ||
            (current['actuals'] as List).any(
              (a) => (a as Map)['occurrence_id'] == row['id'],
            ) ||
            (current['allocations'] as List).any(
              (a) => (a as Map)['occurrence_id'] == row['id'],
            ) ||
            (current['credit'] as List).any(
              (a) => (a as Map)['reference_id'] == row['id'],
            ) ||
            (current['replacements'] as List).any(
              (a) => (a as Map)['original_occurrence_id'] == row['id'],
            )) {
          throw const ValidationError(
            'Changed, past or protected schedule effects cannot be undone',
          );
        }
        changed.add(prior);
      }
      if (changed.isEmpty) {
        throw const ValidationError('No editable schedule change');
      }
      String? newScheduleId;
      final schedules = current['schedules'] as List;
      final oldSchedules = before['schedules'] as List;
      if (schedules.length != oldSchedules.length) {
        final source = Map<String, dynamic>.from(oldSchedules.last as Map);
        final latest = schedules.last as Map;
        newScheduleId = StableId.generate().value;
        source['id'] = newScheduleId;
        source['version'] = (latest['version'] as int) + 1;
        final boundary = _dateOnly(latest['effective_from'] as String);
        source['effective_from'] = _formatDate(
          boundary.compareTo(today) < 0 ? today : boundary,
        );
        await _insert('schedule_definitions', source);
      }
      for (final row in changed) {
        await database.customStatement(
          'UPDATE occurrences SET current_scheduled_value = ?, status = ?, is_manual_override = ?, schedule_definition_id = ? WHERE id = ?',
          [
            row['current_scheduled_value'],
            row['status'],
            row['is_manual_override'],
            newScheduleId ?? row['schedule_definition_id'],
            row['id'],
          ],
        );
        await database.writeMetadata('reminder_reopen_v1:${row['id']}', '1');
      }
      final after = await _snapshot(id);
      await journal.append(
        owner: 'schedule:${id.value}',
        before: current,
        after: after,
        undoOf: expected.id,
      );
      final plan = await DriftCommitmentPlanRepository(database)
          .findByCommitmentId(id);
      final ids = changed.map((r) => r['id']).toSet();
      return plan!.occurrences.where((o) => ids.contains(o.id.value)).toList();
    }),
  );

  Future<void> _insert(String table, Map<String, dynamic> row) {
    final columns = database.scheduleDefinitions.$columns
        .map((c) => c.$name)
        .toSet();
    if (table != 'schedule_definitions' ||
        row.keys.toSet().difference(columns).isNotEmpty ||
        row.length != columns.length) {
      throw const ValidationError('Unsupported schedule Undo snapshot');
    }
    return database.customStatement(
      'INSERT INTO schedule_definitions (${row.keys.map((k) => '"$k"').join(',')}) VALUES (${List.filled(row.length, '?').join(',')})',
      row.values.toList(),
    );
  }

  LocalDate _date(String value) => value.startsWith('date:')
      ? _dateOnly(value.substring(5))
      : value.startsWith('local:')
      ? _dateOnly(value.substring(6).split('T').first)
      : LocalDate.fromDateTime(DateTime.parse(value.substring(8)).toLocal());
  bool _isPast(String value, DateTime now) {
    if (value.startsWith('date:')) {
      return _date(value).compareTo(LocalDate.fromDateTime(now)) < 0;
    }
    if (value.startsWith('instant:')) {
      return DateTime.parse(value.substring(8)).isBefore(now);
    }
    final parts = value.substring(6).split('T');
    final date = _dateOnly(parts[0]);
    final clock = parts[1].split(RegExp(r'[:.]')).map(int.parse).toList();
    final scheduled = DateTime(
      date.year,
      date.month,
      date.day,
      clock[0],
      clock[1],
      clock[2],
      clock[3],
    );
    final wallNow = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute,
      now.second,
      now.millisecond,
    );
    return scheduled.isBefore(wallNow);
  }

  LocalDate _dateOnly(String value) {
    final p = value.split('-').map(int.parse).toList();
    return LocalDate(p[0], p[1], p[2]);
  }

  String _formatDate(LocalDate d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
