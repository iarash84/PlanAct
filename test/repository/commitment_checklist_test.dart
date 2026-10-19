import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/application/command_gate.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/features/backup/application/backup_service.dart';
import 'package:planact/features/backup/data/secure_backup_keys.dart';
import 'package:planact/features/backup/data/sqlite_backup_snapshot.dart';
import 'package:planact/features/backup/data/sqlite_backup_storage.dart';
import 'package:planact/features/backup/domain/backup_encryption.dart';
import 'package:planact/features/backup/domain/backup_package.dart';
import 'package:planact/features/commitments/application/checklist_repository.dart';
import 'package:planact/features/commitments/application/commitment_plan_use_case.dart';
import 'package:planact/features/commitments/data/drift_checklist_repository.dart';
import 'package:planact/features/commitments/data/drift_commitment_repository.dart';
import 'package:planact/features/commitments/data/drift_commitment_plan_repository.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/commitments/domain/commitment_checklist.dart';
import 'package:sqlite3/sqlite3.dart';

import 'sqlite_backup_restore_test.dart' show Keys, Rebuild;

void main() {
  test(
    'creation stores draft checklist in the same plan transaction',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final owners = DriftCommitmentRepository(db);
      final plans = DriftCommitmentPlanRepository(db);
      final checklists = DriftChecklistRepository(db);
      final plan =
          await CreateCommitmentPlan(
            commitments: owners,
            plans: plans,
            checklists: checklists,
          ).call(
            title: 'لیست خرید',
            startAt: DateTime(2026, 9, 22, 9),
            checklistTitles: const ['نان', 'شیر'],
          );
      final list = (await checklists.load(plan.commitment.id)).list;
      expect(list.items.map((item) => item.title), ['نان', 'شیر']);
      expect(list.revision, 2);
    },
  );

  test('fresh transactional admission, isolated owners, retained revisions, rollback and restart', () async {
    final dir = await Directory.systemTemp.createTemp('planact-checklist-');
    final file = File('${dir.path}/live.sqlite');
    var db = AppDatabase.forTesting(NativeDatabase(file));
    try {
      final owners = DriftCommitmentRepository(db);
      final owner = Commitment.create(title: 'لیست خرید');
      final other = Commitment.create(title: 'کارهای سفر');
      await owners.save(owner);
      await owners.save(other);
      var repo = DriftChecklistRepository(db);
      final empty = (await repo.load(owner.id)).list;
      expect(empty.revision, 0);
      expect(empty.items, isEmpty);
      final added = empty.add('نان');
      final competition = await Future.wait([
        repo
            .save(added, expectedRevision: 0)
            .then((_) => true, onError: (_) => false),
        DriftChecklistRepository(db)
            .save(empty.add('شیر'), expectedRevision: 0)
            .then((_) => true, onError: (_) => false),
      ]);
      expect(competition.where((won) => won), hasLength(1));
      var current = (await repo.load(owner.id)).list;
      expect(current.revision, 1);
      expect((await repo.load(other.id)).list.items, isEmpty);
      await expectLater(
        repo.save(added, expectedRevision: 0),
        throwsA(isA<ChecklistConflict>()),
      );
      await expectLater(
        repo.save(
          CommitmentChecklist(commitmentId: owner.id, revision: 2),
          expectedRevision: 1,
        ),
        throwsA(isA<ChecklistConflict>()),
      );
      final id = current.items.single.id;
      current = current.change(id, checked: true);
      await repo.save(current, expectedRevision: 1);
      await owners.changeStatus(owner.id, CommitmentStatus.paused);
      current = current.change(id, removed: true);
      await repo.save(current, expectedRevision: 2);
      await owners.changeStatus(owner.id, CommitmentStatus.archived);
      expect((await repo.load(owner.id)).editable, isFalse);
      await expectLater(
        repo.save(current.change(id, removed: false), expectedRevision: 3),
        throwsA(isA<ChecklistConflict>()),
      );
      await owners.changeStatus(owner.id, CommitmentStatus.active);
      await db.customStatement(
        "CREATE TEMP TRIGGER fail_checklist_head BEFORE UPDATE ON schema_metadata WHEN NEW.key LIKE 'commitment_checklist_head_v1:%' BEGIN SELECT RAISE(ABORT, 'injected failure'); END",
      );
      await expectLater(
        repo.save(current.change(id, removed: false), expectedRevision: 3),
        throwsA(anything),
      );
      expect(
        await db.readMetadata(
          '${DriftChecklistRepository.historyPrefix}${owner.id.value}:4',
        ),
        isNull,
      );
      expect((await repo.load(owner.id)).list.revision, 3);
      await db.close();
      db = AppDatabase.forTesting(NativeDatabase(file));
      repo = DriftChecklistRepository(db);
      current = (await repo.load(owner.id)).list;
      expect(current.items.single.checked, isTrue);
      expect(current.items.single.removed, isTrue);
      await repo.save(current.change(id, removed: false), expectedRevision: 3);
      final original = jsonDecode(
        (await db.readMetadata(
          '${DriftChecklistRepository.historyPrefix}${owner.id.value}:1',
        ))!,
      );
      expect(original['items'][0]['checked'], isFalse);
      expect(original['items'][0]['removed'], isFalse);
      for (final rows in [
        await db.select(db.occurrences).get(),
        await db.select(db.reminderRules).get(),
        await db.select(db.reminderInstances).get(),
        await db.select(db.accountEntries).get(),
        await db.select(db.entitlementLedgerEntries).get(),
      ]) {
        expect(rows, isEmpty);
      }
      expect(
        (await DriftCommitmentRepository(db).findById(owner.id))!.status,
        CommitmentStatus.paused,
      );
      final gate = CommandGate();
      CommandGate.bind(db, gate);
      await gate.retire();
      await expectLater(
        repo.save(current.add('نباید بماند'), expectedRevision: 3),
        throwsA(isA<StaleApplicationCommand>()),
      );
    } finally {
      await db.close();
      await dir.delete(recursive: true);
    }
  });

  test('legacy v17 migration and encrypted personal backup restore preserve head and every snapshot', () async {
    final dir = await Directory.systemTemp.createTemp('checklist-backup-');
    addTearDown(() => dir.delete(recursive: true));
    final live = File('${dir.path}/live.sqlite');
    final legacy = jsonDecode(
      await File('test/fixtures/backup_schema/fresh-v17.json').readAsString(),
    ) as Map<String, dynamic>;
    final old = sqlite3.open(live.path);
    final sql = (legacy['sql'] as List).cast<String>();
    for (final statement in [
      ...sql.where((s) => s.startsWith('CREATE TABLE')),
      ...sql.where((s) => !s.startsWith('CREATE TABLE')),
    ]) {
      old.execute(statement);
    }
    old.execute('PRAGMA user_version = 17');
    old.execute(
      "INSERT INTO schema_metadata (key,value) VALUES ('schema_version','17')",
    );
    old.close();
    final db = AppDatabase.forTesting(NativeDatabase(live));
    final owner = Commitment.create(title: 'لیست خرید');
    await DriftCommitmentRepository(db).save(owner);
    final repo = DriftChecklistRepository(db);
    final first = (await repo.load(owner.id)).list.add('نان');
    await repo.save(first, expectedRevision: 0);
    await repo.save(
      first.change(first.items.single.id, checked: true),
      expectedRevision: 1,
    );
    final before = {
      for (final row in await db.select(db.schemaMetadata).get())
        row.key: row.value,
    };
    final bytes = await sqliteBackupSnapshot(
      database: db,
      target: File('${dir.path}/snapshot.sqlite'),
      redact: true,
    );
    await db.close();
    final inspect = sqlite3.open(live.path);
    final schema = SqliteBackupStorage.schema(inspect);
    inspect.close();
    final storage = SqliteBackupStorage(
      live: live,
      schemaVersion: 18,
      expectedSchema: schema,
      snapshot: live.readAsBytes,
      closeLive: () async {},
    );
    final service = BackupService(
      storage: storage,
      validator: BackupValidator(currentSchemaVersion: 18),
      rebuildHook: Rebuild(),
      keyStorage: Keys(),
      encryptor: AesGcmBackupEncryptor(),
      nonceGenerator: SecureBackupNonce(),
    );
    final package = await service.create(
      payload: bytes,
      appVersion: 'test',
      createdAt: DateTime.utc(2026, 10, 14),
    );
    final mutate = sqlite3.open(live.path);
    mutate.execute(
      "DELETE FROM schema_metadata WHERE key LIKE 'commitment_checklist_%'",
    );
    mutate.close();
    await service.restore(BackupPackage.decode(package.encode()));
    final restored = AppDatabase.forTesting(NativeDatabase(live));
    try {
      expect({
        for (final row in await restored.select(restored.schemaMetadata).get())
          row.key: row.value,
      }, before);
      final list = (await DriftChecklistRepository(restored).load(owner.id))
          .list;
      expect(list.revision, 2);
      expect(list.items.single.id, first.items.single.id);
      expect(list.items.single.checked, isTrue);
    } finally {
      await restored.close();
    }
  });
}
