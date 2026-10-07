import 'package:planact/core/application/command_gate.dart';
import 'package:planact/core/errors/app_error.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/commitments/application/commitment_repository.dart';
import 'package:planact/features/commitments/domain/commitment.dart';

class CreateCommitment {
  const CreateCommitment(this.repository);

  final CommitmentRepository repository;

  Future<Commitment> call({
    required String title,
    DateTime? now,
    CommitmentKind kind = CommitmentKind.oneOff,
    CommitmentPriority priority = CommitmentPriority.normal,
    String? description,
    CommitmentColor? color,
    Set<String> tags = const {},
    List<String> attachmentIds = const [],
  }) => CommandGate.runFor(repository, () async {
    final commitment = Commitment.create(
      title: title,
      now: now,
      kind: kind,
      priority: priority,
      description: description,
      color: color,
      tags: tags,
      attachmentIds: attachmentIds,
    );
    await repository.save(commitment);
    return commitment;
  });
}

class PauseCommitment {
  const PauseCommitment(this.repository);

  final CommitmentRepository repository;

  Future<Commitment> call(StableId id) => _update(id, (item) => item.pause());

  Future<Commitment> _update(
    StableId id,
    Commitment Function(Commitment) transition,
  ) => CommandGate.runFor(repository, () async {
    final current = await repository.findById(id);
    if (current == null) {
      throw NotFoundError('Commitment was not found');
    }
    final updated = transition(current);
    await repository.save(updated);
    return updated;
  });
}

class ResumeCommitment {
  const ResumeCommitment(this.repository);

  final CommitmentRepository repository;

  Future<Commitment> call(StableId id) =>
      CommandGate.runFor(repository, () async {
        final current = await repository.findById(id);
        if (current == null) {
          throw NotFoundError('Commitment was not found');
        }
        final updated = current.resume();
        await repository.save(updated);
        return updated;
      });
}

class ArchiveCommitment {
  const ArchiveCommitment(this.repository);

  final CommitmentRepository repository;

  Future<Commitment> call(StableId id) =>
      CommandGate.runFor(repository, () async {
        final current = await _load(id);
        final updated = current.archive();
        await repository.save(updated);
        return updated;
      });

  Future<Commitment> _load(StableId id) =>
      CommandGate.runFor(repository, () async {
        final current = await repository.findById(id);
        if (current == null) throw NotFoundError('Commitment was not found');
        return current;
      });
}

class RestoreCommitment {
  const RestoreCommitment(this.repository);

  final CommitmentRepository repository;

  Future<Commitment> call(StableId id) =>
      CommandGate.runFor(repository, () async {
        final current = await repository.findById(id);
        if (current == null) throw NotFoundError('Commitment was not found');
        final updated = current.restore();
        await repository.save(updated);
        return updated;
      });
}

class CompleteCommitment {
  const CompleteCommitment(this.repository);

  final CommitmentRepository repository;

  Future<Commitment> call(StableId id) =>
      CommandGate.runFor(repository, () async {
        final current = await repository.findById(id);
        if (current == null) throw NotFoundError('Commitment was not found');
        final updated = current.complete();
        await repository.save(updated);
        return updated;
      });
}

class CancelCommitment {
  const CancelCommitment(this.repository);

  final CommitmentRepository repository;

  Future<Commitment> call(StableId id) =>
      CommandGate.runFor(repository, () async {
        final current = await repository.findById(id);
        if (current == null) throw NotFoundError('Commitment was not found');
        final updated = current.cancel();
        await repository.save(updated);
        return updated;
      });
}

class UpdateCommitmentMetadata {
  const UpdateCommitmentMetadata(this.repository);

  final CommitmentRepository repository;

  Future<Commitment> call({
    required StableId commitmentId,
    required String title,
    required String? description,
    required CommitmentPriority priority,
    CommitmentColor? color,
    bool updateColor = false,
  }) => CommandGate.runFor(repository, () async {
    final current = await repository.findById(commitmentId);
    if (current == null) throw NotFoundError('Commitment was not found');
    final updated = (updateColor ? current.withColor(color) : current)
        .updateMetadata(
          title: title,
          description: description,
          priority: priority,
        );
    await repository.save(updated);
    return updated;
  });
}
