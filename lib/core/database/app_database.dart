import 'package:drift/drift.dart';

part 'app_database.g.dart';

class SchemaMetadata extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

class Commitments extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get status => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class CommitmentCycles extends Table {
  TextColumn get id => text()();
  TextColumn get commitmentId => text().references(Commitments, #id)();
  IntColumn get cycleType => integer()();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get plannedEndDate => dateTime().nullable()();
  DateTimeColumn get actualEndDate => dateTime().nullable()();
  IntColumn get targetUnits => integer().nullable()();
  IntColumn get consumedUnits => integer()();
  IntColumn get completionRule => integer()();
  IntColumn get status => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(tables: [SchemaMetadata, Commitments, CommitmentCycles])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      await _writeSchemaMetadata();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        await m.createTable(commitments);
        await m.createTable(commitmentCycles);
      }
      await _writeSchemaMetadata();
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  Future<void> _writeSchemaMetadata() async {
    await into(schemaMetadata).insertOnConflictUpdate(
      SchemaMetadataCompanion.insert(
        key: 'schema_version',
        value: schemaVersion.toString(),
      ),
    );
  }

  Future<String?> readMetadata(String key) async {
    final row = await (select(
      schemaMetadata,
    )..where((table) => table.key.equals(key))).getSingleOrNull();
    return row?.value;
  }
}
