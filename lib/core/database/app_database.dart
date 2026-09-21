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

class EntitlementPlans extends Table {
  TextColumn get id => text()();
  TextColumn get cycleId => text().references(CommitmentCycles, #id)();
  IntColumn get totalUnits => integer()();
  IntColumn get unitType => integer()();
  DateTimeColumn get validFrom => dateTime()();
  DateTimeColumn get plannedExpiry => dateTime().nullable()();
  BoolColumn get autoExtend => boolean()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class EntitlementLedgerEntries extends Table {
  TextColumn get id => text()();
  TextColumn get planId => text().references(EntitlementPlans, #id)();
  IntColumn get type => integer()();
  IntColumn get units => integer()();
  DateTimeColumn get occurredAt => dateTime()();
  TextColumn get referenceId => text().nullable()();
  TextColumn get note => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class SessionPolicies extends Table {
  TextColumn get id => text()();
  TextColumn get cycleId => text().references(CommitmentCycles, #id)();
  BoolColumn get providerCancellationConsumes => boolean()();
  IntColumn get userCancellationNoticeHours => integer()();
  BoolColumn get lateCancellationConsumes => boolean()();
  BoolColumn get noShowConsumes => boolean()();
  IntColumn get freeAbsenceQuota => integer()();
  BoolColumn get holidayConsumes => boolean()();
  BoolColumn get makeupRequired => boolean()();
  BoolColumn get autoExtendUntilUnitsConsumed => boolean()();
  DateTimeColumn get maxExtensionDate => dateTime().nullable()();
  BoolColumn get partialUnitAllowed => boolean()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class ReplacementOccurrences extends Table {
  TextColumn get id => text()();
  TextColumn get originalOccurrenceId => text()();
  TextColumn get parentReplacementId => text().nullable()();
  DateTimeColumn get scheduledAt => dateTime()();
  IntColumn get reason => integer()();
  IntColumn get status => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class ReminderRules extends Table {
  TextColumn get id => text()();
  TextColumn get occurrenceId => text()();
  IntColumn get anchor => integer()();
  IntColumn get offsetSeconds => integer()();
  DateTimeColumn get absoluteAt => dateTime().nullable()();
  TextColumn get title => text().nullable()();
  TextColumn get body => text().nullable()();
  BoolColumn get enabled => boolean()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class ReminderInstances extends Table {
  TextColumn get id => text()();
  TextColumn get ruleId => text().references(ReminderRules, #id)();
  TextColumn get occurrenceId => text()();
  DateTimeColumn get scheduledAt => dateTime()();
  IntColumn get status => integer()();
  DateTimeColumn get snoozedUntil => dateTime().nullable()();
  TextColumn get platformNotificationId => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    SchemaMetadata,
    Commitments,
    CommitmentCycles,
    ScheduleDefinitions,
    Occurrences,
    EntitlementPlans,
    EntitlementLedgerEntries,
    SessionPolicies,
    ReplacementOccurrences,
    ReminderRules,
    ReminderInstances,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 5;

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
      if (from < 4) {
        await m.createTable(entitlementPlans);
        await m.createTable(entitlementLedgerEntries);
        await m.createTable(sessionPolicies);
        await m.createTable(replacementOccurrences);
      }
      if (from < 5) {
        await m.createTable(reminderRules);
        await m.createTable(reminderInstances);
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
