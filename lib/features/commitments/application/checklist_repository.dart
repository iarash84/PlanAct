import 'package:planact/core/application/command_gate.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/commitments/application/commitment_repository.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/commitments/domain/commitment_checklist.dart';

final class ChecklistSnapshot {
  const ChecklistSnapshot(this.list, this.status);
  final CommitmentChecklist list;
  final CommitmentStatus status;
  bool get editable =>
      status == CommitmentStatus.active || status == CommitmentStatus.paused;
}

abstract interface class ChecklistRepository {
  Future<ChecklistSnapshot> load(StableId commitmentId);
  Future<void> save(CommitmentChecklist next, {required int expectedRevision});
}

final class ChecklistConflict implements Exception {
  const ChecklistConflict();
}

/// Presentation supplies only explicit user transitions, never persistence.
final class SaveChecklist {
  const SaveChecklist(this.repository);
  final ChecklistRepository repository;

  Future<void> call(
    CommitmentChecklist next, {
    required int expectedRevision,
  }) => CommandGate.runFor(
    repository,
    () => repository.save(next, expectedRevision: expectedRevision),
  );
}

void validateChecklistWrite(
  ChecklistSnapshot current,
  CommitmentChecklist next,
  int expectedRevision,
) {
  if (!current.editable ||
      current.list.commitmentId != next.commitmentId ||
      current.list.revision != expectedRevision ||
      next.revision != expectedRevision + 1 ||
      !next.items
          .map((i) => i.id)
          .toSet()
          .containsAll(current.list.items.map((i) => i.id))) {
    throw const ChecklistConflict();
  }
}

final class InMemoryChecklistRepository implements ChecklistRepository {
  InMemoryChecklistRepository(this.owners);
  final CommitmentRepository owners;
  final _lists = <StableId, CommitmentChecklist>{};

  @override
  Future<ChecklistSnapshot> load(StableId commitmentId) async {
    final owner = await owners.findById(commitmentId);
    if (owner == null) throw const ChecklistConflict();
    return ChecklistSnapshot(
      _lists[commitmentId] ?? CommitmentChecklist(commitmentId: commitmentId),
      owner.status,
    );
  }

  @override
  Future<void> save(
    CommitmentChecklist next, {
    required int expectedRevision,
  }) async {
    final current = await load(next.commitmentId);
    validateChecklistWrite(current, next, expectedRevision);
    _lists[next.commitmentId] = next;
  }
}
