import 'package:drift/drift.dart';

part 'app_database.g.dart';

class SchemaMetadata extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

@DriftDatabase(tables: [SchemaMetadata])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      await _writeSchemaMetadata();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      // Future schema versions add explicit, forward-only migration steps.
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
