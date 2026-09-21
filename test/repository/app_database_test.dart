import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/database/app_database.dart' as db;
import 'package:planact/features/commitments/application/commitment_repository.dart';
import 'package:planact/features/commitments/domain/commitment.dart';

void main() {
  late db.AppDatabase database;

  setUp(() {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test('creates the database and records its schema version', () async {
    expect(await database.readMetadata('schema_version'), '3');
    expect(await database.select(database.scheduleDefinitions).get(), isEmpty);
    expect(await database.select(database.occurrences).get(), isEmpty);
  });

  test(
    'persists and updates commitments through the Drift repository',
    () async {
      final repository = DriftCommitmentRepository(database);
      final created = Commitment.create(
        title: 'کلاس زبان',
        now: DateTime.utc(2026, 9, 20, 10),
      );

      await repository.save(created);
      expect(await repository.findById(created.id), isNotNull);

      final paused = created.pause();
      await repository.save(paused);
      final stored = await repository.findById(created.id);

      expect(stored?.title, 'کلاس زبان');
      expect(stored?.status, CommitmentStatus.paused);
      expect(
        (await repository.list()).map((item) => item.id),
        contains(created.id),
      );
    },
  );
}
