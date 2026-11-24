import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:planact/core/application/command_gate.dart';
import 'package:planact/core/database/app_database.dart' as db;
import 'package:planact/core/database/undo_journal.dart';
import 'package:planact/core/errors/app_error.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/reconciliation/application/commitment_association_repository.dart';
import 'package:planact/features/reconciliation/data/commitment_association_metadata.dart';
import 'package:planact/features/reconciliation/domain/commitment_association.dart';

class DriftCommitmentAssociationRepository
    implements CommitmentAssociationRepository, CommandGateProvider {
  DriftCommitmentAssociationRepository(this.database);
  final db.AppDatabase database;
  @override
  CommandGate? get commandGate => CommandGate.forOwner(database);

  Future<List<CommitmentAssociationRevision>> _history() async {
    final rows =
        await (database.select(database.schemaMetadata)..where(
              (t) =>
                  t.key.like('${CommitmentAssociationMetadata.headPrefix}%') |
                  t.key.like('${CommitmentAssociationMetadata.historyPrefix}%'),
            ))
            .get();
    return CommitmentAssociationMetadata.validate(
      metadata: {for (final row in rows) row.key: row.value},
      // Retain historical metadata after reversal or account archival.
      eligibleTransactionIds: {
        for (final row in await database.select(database.accountEntries).get())
          if (row.type == AccountEntryType.income.index ||
              row.type == AccountEntryType.expense.index)
            row.id,
      },
      commitmentIds: {
        for (final row in await database.select(database.commitments).get())
          row.id,
      },
    );
  }

  Future<CommitmentAssociation> _load(StableId id) async {
    final events = await _history();
    return events.where((e) => e.after.transactionId == id).lastOrNull?.after ??
        CommitmentAssociation(transactionId: id);
  }

  @override
  Future<CommitmentAssociation> loadAssociation(StableId transactionId) =>
      CommandGate.runFor(
        this,
        () => database.transaction(() => _load(transactionId)),
      );

  @override
  Future<List<CommitmentAssociation>> listAssociations() => CommandGate.runFor(
    this,
    () => database.transaction(() async {
      final heads = <StableId, CommitmentAssociation>{};
      for (final event in await _history()) {
        heads[event.after.transactionId] = event.after;
      }
      return List.unmodifiable(heads.values);
    }),
  );

  @override
  Future<List<CommitmentAssociationRevision>> associationHistory(
    StableId transactionId,
  ) => CommandGate.runFor(
    this,
    () => database.transaction(
      () async => List.unmodifiable(
        (await _history()).where((e) => e.after.transactionId == transactionId),
      ),
    ),
  );

  @override
  Future<CommitmentAssociation> associateCommitment({
    required CommitmentAssociation expected,
    required StableId transactionId,
    required StableId? commitmentId,
  }) => CommandGate.runFor(
    this,
    () => database.transaction(() async {
      await UndoJournal(database).admitWriter();
      final transaction = await (database.select(
        database.accountEntries,
      )..where((t) => t.id.equals(transactionId.value))).getSingleOrNull();
      final reversals =
          await (database.select(database.accountEntries)..where(
                (t) =>
                    t.type.equals(AccountEntryType.reversal.index) &
                    t.referenceId.equals(transactionId.value),
              ))
              .get();
      if (transaction == null ||
          reversals.isNotEmpty ||
          transaction.minorUnits <= 0 ||
          (transaction.type != AccountEntryType.income.index &&
              transaction.type != AccountEntryType.expense.index)) {
        throw const ValidationError(
          'Transaction is unavailable for association',
        );
      }
      final account = await (database.select(
        database.financialAccounts,
      )..where((t) => t.id.equals(transaction.accountId))).getSingleOrNull();
      if (account == null ||
          account.status != FinancialAccountStatus.active.index ||
          account.currency != transaction.currency) {
        throw const ValidationError('Account is unavailable for association');
      }
      // Archived/paused owners are valid explicitly selected historical subjects.
      // No cycle or occurrence is required and no owner is reactivated.
      if (commitmentId != null &&
          await (database.select(database.commitments)
                    ..where((t) => t.id.equals(commitmentId.value)))
                  .getSingleOrNull() ==
              null) {
        throw const ValidationError(
          'Commitment is unavailable for association',
        );
      }
      final current = await _load(transactionId);
      if (!current.sameState(expected)) {
        throw const ValidationError('Association changed; reload first');
      }
      if (current.commitmentId == commitmentId) return current;
      final next = CommitmentAssociation(
        transactionId: transactionId,
        revision: current.revision + 1,
        commitmentId: commitmentId,
      );
      final event = CommitmentAssociationRevision(
        before: current,
        after: next,
        recordedAt: DateTime.now().toUtc(),
      );
      await database
          .into(database.schemaMetadata)
          .insert(
            db.SchemaMetadataCompanion.insert(
              key:
                  '${CommitmentAssociationMetadata.historyPrefix}${transactionId.value}:${next.revision}',
              value: jsonEncode(CommitmentAssociationMetadata.event(event)),
            ),
          );
      await database.writeMetadata(
        '${CommitmentAssociationMetadata.headPrefix}${transactionId.value}',
        jsonEncode(CommitmentAssociationMetadata.state(next)),
      );
      return next;
    }),
  );
}
