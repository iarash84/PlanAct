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

class ScheduleDefinitions extends Table {
  TextColumn get id => text()();
  TextColumn get cycleId => text().references(CommitmentCycles, #id)();
  IntColumn get mode => integer()();
  IntColumn get timeSemantics => integer()();
  TextColumn get startDate => text()();
  TextColumn get localTime => text().nullable()();
  TextColumn get timeZoneId => text().nullable()();
  DateTimeColumn get fixedInstant => dateTime().nullable()();
  TextColumn get recurrenceRule => text().nullable()();
  TextColumn get endDate => text().nullable()();
  IntColumn get occurrenceCount => integer().nullable()();
  IntColumn get version => integer()();
  TextColumn get effectiveFrom => text()();
  IntColumn get generationHorizonDays => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Occurrences extends Table {
  TextColumn get id => text()();
  TextColumn get cycleId => text().references(CommitmentCycles, #id)();
  TextColumn get scheduleDefinitionId =>
      text().references(ScheduleDefinitions, #id)();
  TextColumn get occurrenceKey => text()();
  IntColumn get timeSemantics => integer()();
  TextColumn get originalScheduledValue => text()();
  TextColumn get currentScheduledValue => text()();
  IntColumn get status => integer()();
  BoolColumn get isManualOverride => boolean()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {scheduleDefinitionId, occurrenceKey},
  ];
}

@DriftDatabase(
  tables: [
    SchemaMetadata,
    Commitments,
    CommitmentCycles,
    ScheduleDefinitions,
    Occurrences,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 3;

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
      if (from < 3) {
        await m.createTable(scheduleDefinitions);
        await m.createTable(occurrences);
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
