import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/database/app_database.dart' hide Commitment;
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/classification/application/tag_repository.dart';
import 'package:planact/features/classification/data/drift_tag_repository.dart';
import 'package:planact/features/commitments/data/drift_commitment_repository.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

void main() {
  test(
    'reuses Persian tags and persists attach/removal across restart',
    () async {
      final directory = await Directory.systemTemp.createTemp('planact-tags-');
      final file = File(
        '${directory.path}${Platform.pathSeparator}data.sqlite',
      );
      final database = AppDatabase.forTesting(NativeDatabase(file));
      final commitments = DriftCommitmentRepository(database);
      final created = Commitment.create(title: 'کلاس', tags: {'#آموزش', 'کار'});
      await commitments.save(created);
      final tags = DriftTagRepository(database);
      final education = await tags.getOrCreate('  آموزش  ');
      expect((await tags.getOrCreate('#آموزش')).id, education.id);
      expect(
        (await tags.autocomplete('#آمو')).map((tag) => tag.id),
        contains(education.id),
      );
      final stored = await commitments.findById(created.id);
      expect(stored!.tags, contains('آموزش'));
      await tags.detach(
        recordId: created.id.value,
        tag: education,
        type: TaggableType.commitment,
      );
      expect(
        (await commitments.findById(created.id))!.tags,
        isNot(contains('آموزش')),
      );
      await database.close();
      final restarted = AppDatabase.forTesting(NativeDatabase(file));
      expect(
        (await DriftTagRepository(restarted).getOrCreate('آموزش')).id,
        education.id,
      );
      expect(
        (await DriftCommitmentRepository(restarted).findById(created.id))!.tags,
        {'کار'},
      );
      await restarted.close();
      await directory.delete(recursive: true);
    },
  );

  test('upgrades v14 commitment tags without losing records', () async {
    final directory = await Directory.systemTemp.createTemp(
      'planact-tags-v14-',
    );
    final file = File('${directory.path}${Platform.pathSeparator}data.sqlite');
    final old = sqlite.sqlite3.open(file.path);
    old.execute(
      'CREATE TABLE schema_metadata (key TEXT PRIMARY KEY, value TEXT NOT NULL)',
    );
    old.execute(
      'CREATE TABLE commitments (id TEXT PRIMARY KEY, title TEXT NOT NULL, created_at INTEGER NOT NULL, status INTEGER NOT NULL, kind INTEGER NOT NULL DEFAULT 0, priority INTEGER NOT NULL DEFAULT 1, description TEXT, tags TEXT NOT NULL DEFAULT \'\', attachment_ids TEXT NOT NULL DEFAULT \'\')',
    );
    old.execute('CREATE TABLE account_entries (id TEXT PRIMARY KEY)');
    old.execute(
      'CREATE TABLE financial_accounts (id TEXT PRIMARY KEY, name TEXT NOT NULL, currency TEXT NOT NULL, type INTEGER NOT NULL, status INTEGER NOT NULL)',
    );
    old.execute(
      'INSERT INTO commitments(id, title, created_at, status, tags) VALUES (?, ?, ?, ?, ?)',
      [
        StableId.generate().value,
        'قدیمی',
        1780000000,
        0,
        'آموزش\\n#آموزش\\nکار',
      ],
    );
    old.execute('PRAGMA user_version = 14');
    old.close();
    final database = AppDatabase.forTesting(NativeDatabase(file));
    final rows = await DriftTagRepository(database).list();
    expect(rows.map((tag) => tag.label).toSet(), {'آموزش', 'کار'});
    expect(await database.readMetadata('schema_version'), '18');
    await database.close();
    await directory.delete(recursive: true);
  });

  test(
    'repairs the schema-15 tag migration before the v16 bank_code upgrade',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'planact-tags-v15-',
      );
      final file = File(
        '${directory.path}${Platform.pathSeparator}data.sqlite',
      );
      final old = sqlite.sqlite3.open(file.path);
      old.execute(
        'CREATE TABLE schema_metadata (key TEXT PRIMARY KEY, value TEXT NOT NULL)',
      );
      old.execute(
        'CREATE TABLE commitments (id TEXT PRIMARY KEY, title TEXT NOT NULL, created_at INTEGER NOT NULL, status INTEGER NOT NULL, kind INTEGER NOT NULL DEFAULT 0, priority INTEGER NOT NULL DEFAULT 1, description TEXT, tags TEXT NOT NULL DEFAULT \'\', attachment_ids TEXT NOT NULL DEFAULT \'\')',
      );
      old.execute('CREATE TABLE account_entries (id TEXT PRIMARY KEY)');
      old.execute(
        'CREATE TABLE financial_accounts (id TEXT PRIMARY KEY, name TEXT NOT NULL, currency TEXT NOT NULL, type INTEGER NOT NULL, status INTEGER NOT NULL)',
      );
      old.execute(
        'INSERT INTO commitments(id, title, created_at, status, tags) VALUES (?, ?, ?, ?, ?)',
        [
          StableId.generate().value,
          'قدیمی',
          1780000000,
          0,
          'آموزش\\n#آموزش\\nکار',
        ],
      );
      old.execute('PRAGMA user_version = 15');
      old.close();

      final database = AppDatabase.forTesting(NativeDatabase(file));
      final rows = await DriftTagRepository(database).list();
      expect(rows.map((tag) => tag.label).toSet(), {'آموزش', 'کار'});
      final columns = await database
          .customSelect('PRAGMA table_info(financial_accounts)')
          .get();
      expect(
        columns.map((row) => row.read<String>('name')),
        contains('bank_code'),
      );
      expect(await database.readMetadata('schema_version'), '18');
      await database.close();
      await directory.delete(recursive: true);
    },
  );
}
