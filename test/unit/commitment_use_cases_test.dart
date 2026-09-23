import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/errors/app_error.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/commitments/application/commitment_repository.dart';
import 'package:planact/features/commitments/application/commitment_use_cases.dart';
import 'package:planact/features/commitments/domain/commitment.dart';

void main() {
  late InMemoryCommitmentRepository repository;

  setUp(() {
    repository = InMemoryCommitmentRepository();
  });

  test('creates and changes a commitment through use cases', () async {
    final created = await CreateCommitment(repository).call(title: 'کلاس زبان');
    final paused = await PauseCommitment(repository).call(created.id);
    final resumed = await ResumeCommitment(repository).call(created.id);
    final archived = await ArchiveCommitment(repository).call(created.id);

    expect(paused.status, CommitmentStatus.paused);
    expect(resumed.status, CommitmentStatus.active);
    expect(archived.status, CommitmentStatus.archived);
    expect((await repository.list()), hasLength(1));
  });

  test('reports a missing commitment without mutating storage', () async {
    final missingId = createdId();

    expect(
      () => PauseCommitment(repository).call(missingId),
      throwsA(isA<NotFoundError>()),
    );
    expect(await repository.list(), isEmpty);
  });
}

// Kept local to avoid creating a test-only ID abstraction.
StableId createdId() => StableId.generate();
