import 'package:drift/drift.dart';
import 'package:planact/core/database/app_database.dart';
import 'package:planact/core/errors/app_error.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/commitments/domain/commitment_cycle.dart';

/// Use only inside the mutation transaction. Admission precedes all reads.
Future<void> requireWritableCycle(
  AppDatabase database,
  String cycleId, {
  bool requireActiveOwner = true,
}) async {
  await database.customStatement(
    'UPDATE schema_metadata SET value = value WHERE key = ?',
    ['schema_version'],
  );
  final row = await database
      .customSelect(
        'SELECT c.status AS cycle_status, p.status AS owner_status '
        'FROM commitment_cycles c JOIN commitments p ON p.id = c.commitment_id '
        'WHERE c.id = ?',
        variables: [Variable(cycleId)],
      )
      .getSingleOrNull();
  if (row == null ||
      row.read<int>('cycle_status') != CommitmentCycleStatus.active.index ||
      (requireActiveOwner &&
          row.read<int>('owner_status') != CommitmentStatus.active.index)) {
    throw const ValidationError('Historical or inactive cycles are read-only');
  }
}

Future<void> requireWritableOccurrence(
  AppDatabase database,
  String id, {
  bool requireActiveOwner = true,
}) async {
  await database.customStatement(
    'UPDATE schema_metadata SET value = value WHERE key = ?',
    ['schema_version'],
  );
  final row = await (database.select(
    database.occurrences,
  )..where((t) => t.id.equals(id))).getSingleOrNull();
  if (row == null) throw const ValidationError('Occurrence not found');
  await requireWritableCycle(
    database,
    row.cycleId,
    requireActiveOwner: requireActiveOwner,
  );
}
