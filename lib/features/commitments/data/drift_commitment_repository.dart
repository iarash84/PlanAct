import 'package:planact/core/application/command_gate.dart';

import 'dart:convert';

import 'package:planact/core/application/undo_token.dart';
import 'package:planact/core/database/undo_journal.dart';
import 'package:planact/core/errors/app_error.dart';
import 'package:planact/features/reminders/domain/reminder.dart';
import 'package:drift/drift.dart';
import 'package:planact/core/database/app_database.dart' as db;
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/commitments/application/commitment_repository.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/classification/data/drift_tag_repository.dart';
import 'package:planact/features/classification/application/tag_repository.dart';

class DriftCommitmentRepository
    implements
        CommandGateProvider,
        CommitmentRepository,
        CommitmentLifecycleRepository {
  DriftCommitmentRepository(this._database);

  @override
  CommandGate? get commandGate => CommandGate.forOwner(_database);

  final db.AppDatabase _database;

  db.AppDatabase get database => _database;

  @override
  Future<UndoToken?> statusUndo(StableId id) =>
      CommandGate.runFor(this, () async {
        final event = await UndoJournal(_database)
            .latest('commitment:${id.value}');
        final current = await findById(id);
        return event != null &&
                event['undoOf'] == null &&
                event['after'] == current?.status.index
            ? UndoToken(event['id'] as String)
            : null;
      });

  @override
  Future<Commitment> undoStatus(StableId id, UndoToken expected) =>
      CommandGate.runFor(
        this,
        () => _database.transaction(() async {
          final journal = UndoJournal(_database);
          await journal.admitWriter();
          final current = await findById(id);
          if (current == null) {
            throw const ValidationError('Commitment missing');
          }
          final event = await journal.latest('commitment:${id.value}');
          journal.requireCurrent(event, expected.id, current.status.index);
          final previous = CommitmentStatus.values[event!['before'] as int];
          await (_database.update(_database.commitments)
                ..where((t) => t.id.equals(id.value)))
              .write(db.CommitmentsCompanion(status: Value(previous.index)));
          await journal.append(
            owner: 'commitment:${id.value}',
            before: current.status.index,
            after: previous.index,
            undoOf: expected.id,
          );
          await _reminderIntent(id, previous);
          return current.restoreRecordedStatus(previous);
        }),
      );

  @override
  Future<Commitment> changeStatus(
    StableId id,
    CommitmentStatus status, {
    CommitmentStatus? expectedStatus,
  }) => CommandGate.runFor(
    this,
    () => _database.transaction(() async {
      final journal = UndoJournal(_database);
      await journal.admitWriter();
      final current = await findById(id);
      if (current == null) {
        throw const ValidationError('Commitment missing');
      }
      final event = await journal.latest('commitment:${id.value}');
      if (expectedStatus != null && current.status != expectedStatus) {
        throw const ValidationError('Commitment status changed; reload first');
      }
      final updated = switch (status) {
        CommitmentStatus.paused => current.pause(),
        CommitmentStatus.completed => current.complete(),
        CommitmentStatus.cancelled => current.cancel(),
        CommitmentStatus.archived => current.archive(),
        CommitmentStatus.active =>
          current.status == CommitmentStatus.archived
              ? current.restore(
                  previousStatus:
                      event != null &&
                          event['after'] == CommitmentStatus.archived.index
                      ? CommitmentStatus.values[event['before'] as int]
                      : CommitmentStatus.active,
                )
              : current.resume(),
      };
      await save(updated);
      return updated;
    }),
  );

  @override
  Future<Commitment?> findById(StableId id) =>
      CommandGate.runFor(this, () async {
        final row = await (_database.select(
          _database.commitments,
        )..where((table) => table.id.equals(id.value))).getSingleOrNull();
        return row == null ? null : _toDomain(row, await _tagsFor(row.id));
      });

  @override
  Future<List<Commitment>> list() => CommandGate.runFor(this, () async {
    final rows = await _database.select(_database.commitments).get();
    final tags = DriftTagRepository(_database);
    final allTags = await tags.list();
    final memberships = await tags.tagsForMany(
      rows.map((row) => row.id),
      TaggableType.commitment,
    );
    final labelsById = {for (final tag in allTags) tag.id: tag.label};
    return [
      for (final row in rows)
        _toDomain(row, {
          for (final id in memberships[row.id] ?? const <StableId>{})
            if (labelsById[id] case final label?) label,
        }),
    ];
  });

  @override
  Future<void> save(Commitment commitment) =>
      CommandGate.runFor(this, () async {
        await _database.transaction(() async {
          await UndoJournal(_database).admitWriter();
          final stored =
              await (_database.select(_database.commitments)
                    ..where((row) => row.id.equals(commitment.id.value)))
                  .getSingleOrNull();
          // Existing memberships are edited through TagRepository. Metadata or
          // lifecycle saves can carry an obsolete label snapshot after a rename
          // or removal and must not recreate it or overwrite concurrent links.
          final labels = stored == null
              ? commitment.tags
              : await _tagsFor(commitment.id.value);
          await _database
              .into(_database.commitments)
              .insertOnConflictUpdate(
                db.CommitmentsCompanion(
                  id: Value(commitment.id.value),
                  title: Value(commitment.title),
                  createdAt: Value(commitment.createdAt.toUtc()),
                  status: Value(commitment.status.index),
                  kind: Value(commitment.kind.index),
                  priority: Value(commitment.priority.index),
                  description: Value(commitment.description),
                  colorKey: Value(commitment.color?.name),
                  tags: Value(labels.join('\\n')),
                  attachmentIds: Value(commitment.attachmentIds.join('\\n')),
                ),
              );
          if (stored != null) {
            if (stored.status != commitment.status.index) {
              await UndoJournal(_database).append(
                owner: 'commitment:${commitment.id.value}',
                before: stored.status,
                after: commitment.status.index,
              );
              await _reminderIntent(commitment.id, commitment.status);
            }
            return;
          }
          final repository = DriftTagRepository(_database);
          final existing = await repository.tagsFor(
            commitment.id.value,
            TaggableType.commitment,
          );
          final desired = <StableId>{};
          for (final label in commitment.tags) {
            final tag = await repository.getOrCreate(label);
            desired.add(tag.id);
            await repository.attach(
              recordId: commitment.id.value,
              tag: tag,
              type: TaggableType.commitment,
            );
          }
          for (final id in existing.difference(desired)) {
            final tag = (await repository.list()).firstWhere(
              (item) => item.id == id,
            );
            await repository.detach(
              recordId: commitment.id.value,
              tag: tag,
              type: TaggableType.commitment,
            );
          }
        });
      });

  Future<Set<String>> _tagsFor(String id) => CommandGate.runFor(this, () async {
    final repository = DriftTagRepository(_database);
    final ids = await repository.tagsFor(id, TaggableType.commitment);
    final all = await repository.list();
    return all
        .where((tag) => ids.contains(tag.id))
        .map((tag) => tag.label)
        .toSet();
  });

  Future<void> _reminderIntent(StableId id, CommitmentStatus status) async {
    final key = 'lifecycle_reminders_v1:${id.value}';
    final stored = await _database.readMetadata(key);
    final suspended = stored == null
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(jsonDecode(stored) as Map);
    final rows = await _database
        .customSelect(
          'SELECT r.* FROM reminder_instances r WHERE occurrence_id IN (SELECT id FROM occurrences WHERE cycle_id IN (SELECT id FROM commitment_cycles WHERE commitment_id = ?))',
          variables: [Variable(id.value)],
        )
        .get();
    if (status != CommitmentStatus.active) {
      for (final row in rows) {
        if ({
          ReminderInstanceStatus.scheduled.index,
          ReminderInstanceStatus.snoozed.index,
        }.contains(row.read<int>('status'))) {
          final rule =
              await (_database.select(_database.reminderRules)
                    ..where((t) => t.id.equals(row.read<String>('rule_id'))))
                  .getSingle();
          suspended[row.read<String>('id')] = {
            'instance': row.data,
            'rule': rule.toJson(),
          };
        }
      }
      await _database.writeMetadata(key, jsonEncode(suspended));
      await _database.customStatement(
        'UPDATE reminder_instances SET status = ?, snoozed_until = NULL WHERE occurrence_id IN (SELECT id FROM occurrences WHERE cycle_id IN (SELECT id FROM commitment_cycles WHERE commitment_id = ?)) AND status IN (?, ?)',
        [
          ReminderInstanceStatus.cancelled.index,
          id.value,
          ReminderInstanceStatus.scheduled.index,
          ReminderInstanceStatus.snoozed.index,
        ],
      );
    } else {
      for (final row in rows) {
        final saved = suspended[row.read<String>('id')] as Map?;
        if (saved == null ||
            row.read<int>('status') != ReminderInstanceStatus.cancelled.index) {
          continue;
        }
        final prior = saved['instance'] as Map;
        final rule =
            await (_database.select(_database.reminderRules)
                  ..where((t) => t.id.equals(row.read<String>('rule_id'))))
                .getSingleOrNull();
        if (rule == null ||
            !rule.enabled ||
            jsonEncode(rule.toJson()) != jsonEncode(saved['rule']) ||
            prior['scheduled_at'] != row.data['scheduled_at'] ||
            row.data['snoozed_until'] != null) {
          continue;
        }
        await _database.customStatement(
          'UPDATE reminder_instances SET status = ?, snoozed_until = ? WHERE id = ?',
          [prior['status'], prior['snoozed_until'], row.read<String>('id')],
        );
      }
      await _database.writeMetadata(key, '{}');
    }
  }

  Commitment _toDomain(db.Commitment row, Set<String> tags) {
    return Commitment(
      id: StableId.parse(row.id),
      title: row.title,
      createdAt: row.createdAt.toUtc(),
      status: CommitmentStatus.values[row.status],
      kind: CommitmentKind.values[row.kind],
      priority: CommitmentPriority.values[row.priority],
      description: row.description,
      color: row.colorKey == null
          ? null
          : CommitmentColor.values.byName(row.colorKey!),
      tags: tags,
      attachmentIds: row.attachmentIds.isEmpty
          ? const []
          : row.attachmentIds.split('\\n'),
    );
  }
}
