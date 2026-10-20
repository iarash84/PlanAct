import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/application/command_gate.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/core/errors/app_error.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/backup/application/backup_service.dart';
import 'package:planact/features/backup/data/secure_backup_keys.dart';
import 'package:planact/features/backup/data/sqlite_backup_snapshot.dart';
import 'package:planact/features/backup/data/sqlite_backup_storage.dart';
import 'package:planact/features/backup/domain/backup_encryption.dart';
import 'package:planact/features/backup/domain/backup_package.dart';
import 'package:planact/features/commitments/domain/commitment_color.dart';
import 'package:planact/features/notes/application/calendar_note_repository.dart';
import 'package:planact/features/notes/data/drift_calendar_note_repository.dart';
import 'package:planact/features/notes/domain/calendar_note.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';
import 'package:sqlite3/sqlite3.dart';

import 'sqlite_backup_restore_test.dart' show Keys, Rebuild;

void main() {
  final day = LocalDate(2026, 10, 14);
  CalendarNote note({String title = 'روز خاطره', int revision = 1}) =>
      CalendarNote(
        id: StableId.generate(),
        title: title,
        description: 'توضیح',
        date: day,
        color: CommitmentColor.rose,
        revision: revision,
      );

  test(
    'civil date and title validation are independent of occurrence lifecycle',
    () {
      expect(() => note(title: '  '), throwsA(isA<ValidationError>()));
      expect(() => note(revision: 0), throwsA(isA<ValidationError>()));
      expect(note(title: '  خاطره  ').title, 'خاطره');
      expect(note().date, LocalDate(2026, 10, 14));
    },
  );

  test('bounded reads, competing revisions, failed writes, date move and cold reopen', () async {
    final directory = await Directory.systemTemp.createTemp('calendar-note-');
    final file = File('${directory.path}/notes.sqlite');
    var database = AppDatabase.forTesting(NativeDatabase(file));
    try {
      var repository = DriftCalendarNoteRepository(database);
      final first = note();
      await repository.save(first, expectedRevision: 0);
      final next = CalendarNote(
        id: first.id,
        title: 'تاریخ تازه',
        description: 'متن تازه',
        date: day.addDays(1),
        color: CommitmentColor.blue,
        revision: 2,
      );
      final competing = DriftCalendarNoteRepository(database);
      final results = await Future.wait([
        repository
            .save(next, expectedRevision: 1)
            .then((_) => true, onError: (_) => false),
        competing
            .save(next, expectedRevision: 1)
            .then((_) => true, onError: (_) => false),
      ]);
      expect(results.where((result) => result), hasLength(1));
      await expectLater(
        repository.save(first, expectedRevision: 0),
        throwsA(isA<StaleCalendarNote>()),
      );
      expect(await repository.loadRange(day, day.addDays(1)), isEmpty);
      expect(
        (await repository.loadRange(
          day.addDays(1),
          day.addDays(2),
        )).single.color,
        CommitmentColor.blue,
      );

      // Inject a failure after the revision insert; all three projections roll back.
      await database.customStatement(
        "CREATE TEMP TRIGGER fail_note_head BEFORE UPDATE ON schema_metadata WHEN NEW.key LIKE 'calendar_note_head_v1:%' BEGIN SELECT RAISE(ABORT, 'injected failure'); END",
      );
      final failed = CalendarNote(
        id: first.id,
        title: 'نباید بماند',
        description: '',
        date: day.addDays(3),
        color: CommitmentColor.teal,
        revision: 3,
      );
      await expectLater(
        repository.save(failed, expectedRevision: 2),
        throwsA(anything),
      );
      expect(
        await database.readMetadata(
          'calendar_note_revision_v1:${first.id.value}:3',
        ),
        isNull,
      );
      expect(
        await repository.loadRange(day.addDays(3), day.addDays(4)),
        isEmpty,
      );
      await database.close();
      database = AppDatabase.forTesting(NativeDatabase(file));
      repository = DriftCalendarNoteRepository(database);
      final restored = (await repository.loadRange(day, day.addDays(2))).single;
      expect(restored.title, next.title);
      expect(restored.description, next.description);
      expect(restored.date, day.addDays(1));
      expect(restored.revision, 2);
      expect(
        jsonDecode(
          (await database.readMetadata(
            'calendar_note_revision_v1:${first.id.value}:1',
          ))!,
        )['title'],
        first.title,
      );
      for (final rows in [
        await database.select(database.commitments).get(),
        await database.select(database.occurrences).get(),
        await database.select(database.reminderRules).get(),
        await database.select(database.reminderInstances).get(),
        await database.select(database.accountEntries).get(),
        await database.select(database.entitlementLedgerEntries).get(),
      ]) {
        expect(rows, isEmpty);
      }
      final gate = CommandGate();
      CommandGate.bind(database, gate);
      await gate.retire();
      await expectLater(
        repository.save(failed, expectedRevision: 2),
        throwsA(isA<StaleApplicationCommand>()),
      );
    } finally {
      await database.close();
      await directory.delete(recursive: true);
    }
  });

  test('migrated v17 data coexists with notes; encrypted restore keeps head, index and revisions', () async {
    final directory = await Directory.systemTemp.createTemp('note-backup-');
    addTearDown(() => directory.delete(recursive: true));
    final live = File('${directory.path}/live.sqlite');
    final legacy = jsonDecode(
      await File('test/fixtures/backup_schema/fresh-v17.json').readAsString(),
    ) as Map<String, dynamic>;
    final old = sqlite3.open(live.path);
    for (final declaration in (legacy['sql'] as List).cast<String>().where(
      (sql) => sql.startsWith('CREATE TABLE'),
    )) {
      old.execute(declaration);
    }
    for (final declaration in (legacy['sql'] as List).cast<String>().where(
      (sql) => !sql.startsWith('CREATE TABLE'),
    )) {
      old.execute(declaration);
    }
    old.execute('PRAGMA user_version = 17');
    old.execute(
      "INSERT INTO schema_metadata(key,value) VALUES ('legacy_marker','preserved')",
    );
    old.close();
    final database = AppDatabase.forTesting(NativeDatabase(live));
    final repository = DriftCalendarNoteRepository(database);
    final first = note();
    await repository.save(first, expectedRevision: 0);
    await SaveCalendarNote(repository)(
      id: first.id,
      title: 'اصلاح',
      description: 'سابقه',
      date: day.addDays(1),
      color: CommitmentColor.violet,
      expectedRevision: 1,
    );
    final expected = {
      for (final row in await database.select(database.schemaMetadata).get())
        row.key: row.value,
    };
    final bytes = await sqliteBackupSnapshot(
      database: database,
      target: File('${directory.path}/snapshot.sqlite'),
      redact: true,
    );
    await database.close();
    final sql = sqlite3.open(live.path);
    final schema = SqliteBackupStorage.schema(sql);
    sql.close();
    final storage = SqliteBackupStorage(
      live: live,
      schemaVersion: 19,
      expectedSchema: schema,
      snapshot: live.readAsBytes,
      closeLive: () async {},
    );
    final service = BackupService(
      storage: storage,
      validator: BackupValidator(currentSchemaVersion: 19),
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
      "DELETE FROM schema_metadata WHERE key LIKE 'calendar_note_%'",
    );
    mutate.close();
    await service.restore(BackupPackage.decode(package.encode()));
    final reopened = AppDatabase.forTesting(NativeDatabase(live));
    try {
      expect({
        for (final row in await reopened.select(reopened.schemaMetadata).get())
          row.key: row.value,
      }, expected);
      expect(
        (await DriftCalendarNoteRepository(
          reopened,
        ).loadRange(day, day.addDays(2))).single.title,
        'اصلاح',
      );
      expect(await reopened.readMetadata('legacy_marker'), 'preserved');
    } finally {
      await reopened.close();
    }
    storage.validateFile(live);
  });
}
