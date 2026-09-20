import 'package:planact/core/errors/app_error.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/commitments/application/commitment_repository.dart';
import 'package:planact/features/commitments/domain/commitment.dart';

class CreateCommitment {
  const CreateCommitment(this.repository);

  final CommitmentRepository repository;

  Future<Commitment> call({required String title, DateTime? now}) async {
    final commitment = Commitment.create(title: title, now: now);
    await repository.save(commitment);
    return commitment;
  }
}

class PauseCommitment {
  const PauseCommitment(this.repository);

  final CommitmentRepository repository;

  Future<Commitment> call(StableId id) => _update(id, (item) => item.pause());

  Future<Commitment> _update(
    StableId id,
    Commitment Function(Commitment) transition,
  ) async {
    final current = await repository.findById(id);
    if (current == null) {
      throw NotFoundError('Commitment was not found');
    }
    final updated = transition(current);
    await repository.save(updated);
    return updated;
  }
}

class ResumeCommitment {
  const ResumeCommitment(this.repository);

  final CommitmentRepository repository;

  Future<Commitment> call(StableId id) async {
    final current = await repository.findById(id);
    if (current == null) {
      throw NotFoundError('Commitment was not found');
    }
    final updated = current.resume();
    await repository.save(updated);
    return updated;
  }
}

class ArchiveCommitment {
  const ArchiveCommitment(this.repository);

  final CommitmentRepository repository;

  Future<Commitment> call(StableId id) async {
    final current = await repository.findById(id);
    if (current == null) {
      throw NotFoundError('Commitment was not found');
    }
    final updated = current.archive();
    await repository.save(updated);
    return updated;
  }
}
