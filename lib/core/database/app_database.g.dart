// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SchemaMetadataTable extends SchemaMetadata
    with TableInfo<$SchemaMetadataTable, SchemaMetadataData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SchemaMetadataTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'schema_metadata';
  @override
  VerificationContext validateIntegrity(
    Insertable<SchemaMetadataData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SchemaMetadataData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SchemaMetadataData(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SchemaMetadataTable createAlias(String alias) {
    return $SchemaMetadataTable(attachedDatabase, alias);
  }
}

class SchemaMetadataData extends DataClass
    implements Insertable<SchemaMetadataData> {
  final String key;
  final String value;
  const SchemaMetadataData({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SchemaMetadataCompanion toCompanion(bool nullToAbsent) {
    return SchemaMetadataCompanion(key: Value(key), value: Value(value));
  }

  factory SchemaMetadataData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SchemaMetadataData(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  SchemaMetadataData copyWith({String? key, String? value}) =>
      SchemaMetadataData(key: key ?? this.key, value: value ?? this.value);
  SchemaMetadataData copyWithCompanion(SchemaMetadataCompanion data) {
    return SchemaMetadataData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SchemaMetadataData(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SchemaMetadataData &&
          other.key == this.key &&
          other.value == this.value);
}

class SchemaMetadataCompanion extends UpdateCompanion<SchemaMetadataData> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SchemaMetadataCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SchemaMetadataCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<SchemaMetadataData> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SchemaMetadataCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SchemaMetadataCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SchemaMetadataCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CommitmentsTable extends Commitments
    with TableInfo<$CommitmentsTable, Commitment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CommitmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<int> status = GeneratedColumn<int>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, title, createdAt, status];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'commitments';
  @override
  VerificationContext validateIntegrity(
    Insertable<Commitment> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Commitment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Commitment(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}status'],
      )!,
    );
  }

  @override
  $CommitmentsTable createAlias(String alias) {
    return $CommitmentsTable(attachedDatabase, alias);
  }
}

class Commitment extends DataClass implements Insertable<Commitment> {
  final String id;
  final String title;
  final DateTime createdAt;
  final int status;
  const Commitment({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['status'] = Variable<int>(status);
    return map;
  }

  CommitmentsCompanion toCompanion(bool nullToAbsent) {
    return CommitmentsCompanion(
      id: Value(id),
      title: Value(title),
      createdAt: Value(createdAt),
      status: Value(status),
    );
  }

  factory Commitment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Commitment(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      status: serializer.fromJson<int>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'status': serializer.toJson<int>(status),
    };
  }

  Commitment copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    int? status,
  }) => Commitment(
    id: id ?? this.id,
    title: title ?? this.title,
    createdAt: createdAt ?? this.createdAt,
    status: status ?? this.status,
  );
  Commitment copyWithCompanion(CommitmentsCompanion data) {
    return Commitment(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Commitment(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('createdAt: $createdAt, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, title, createdAt, status);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Commitment &&
          other.id == this.id &&
          other.title == this.title &&
          other.createdAt == this.createdAt &&
          other.status == this.status);
}

class CommitmentsCompanion extends UpdateCompanion<Commitment> {
  final Value<String> id;
  final Value<String> title;
  final Value<DateTime> createdAt;
  final Value<int> status;
  final Value<int> rowid;
  const CommitmentsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CommitmentsCompanion.insert({
    required String id,
    required String title,
    required DateTime createdAt,
    required int status,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       createdAt = Value(createdAt),
       status = Value(status);
  static Insertable<Commitment> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<DateTime>? createdAt,
    Expression<int>? status,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (createdAt != null) 'created_at': createdAt,
      if (status != null) 'status': status,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CommitmentsCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<DateTime>? createdAt,
    Value<int>? status,
    Value<int>? rowid,
  }) {
    return CommitmentsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (status.present) {
      map['status'] = Variable<int>(status.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CommitmentsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('createdAt: $createdAt, ')
          ..write('status: $status, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CommitmentCyclesTable extends CommitmentCycles
    with TableInfo<$CommitmentCyclesTable, CommitmentCycle> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CommitmentCyclesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _commitmentIdMeta = const VerificationMeta(
    'commitmentId',
  );
  @override
  late final GeneratedColumn<String> commitmentId = GeneratedColumn<String>(
    'commitment_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES commitments (id)',
    ),
  );
  static const VerificationMeta _cycleTypeMeta = const VerificationMeta(
    'cycleType',
  );
  @override
  late final GeneratedColumn<int> cycleType = GeneratedColumn<int>(
    'cycle_type',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _plannedEndDateMeta = const VerificationMeta(
    'plannedEndDate',
  );
  @override
  late final GeneratedColumn<DateTime> plannedEndDate =
      GeneratedColumn<DateTime>(
        'planned_end_date',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _actualEndDateMeta = const VerificationMeta(
    'actualEndDate',
  );
  @override
  late final GeneratedColumn<DateTime> actualEndDate =
      GeneratedColumn<DateTime>(
        'actual_end_date',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _targetUnitsMeta = const VerificationMeta(
    'targetUnits',
  );
  @override
  late final GeneratedColumn<int> targetUnits = GeneratedColumn<int>(
    'target_units',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _consumedUnitsMeta = const VerificationMeta(
    'consumedUnits',
  );
  @override
  late final GeneratedColumn<int> consumedUnits = GeneratedColumn<int>(
    'consumed_units',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completionRuleMeta = const VerificationMeta(
    'completionRule',
  );
  @override
  late final GeneratedColumn<int> completionRule = GeneratedColumn<int>(
    'completion_rule',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<int> status = GeneratedColumn<int>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    commitmentId,
    cycleType,
    startDate,
    plannedEndDate,
    actualEndDate,
    targetUnits,
    consumedUnits,
    completionRule,
    status,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'commitment_cycles';
  @override
  VerificationContext validateIntegrity(
    Insertable<CommitmentCycle> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('commitment_id')) {
      context.handle(
        _commitmentIdMeta,
        commitmentId.isAcceptableOrUnknown(
          data['commitment_id']!,
          _commitmentIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_commitmentIdMeta);
    }
    if (data.containsKey('cycle_type')) {
      context.handle(
        _cycleTypeMeta,
        cycleType.isAcceptableOrUnknown(data['cycle_type']!, _cycleTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_cycleTypeMeta);
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('planned_end_date')) {
      context.handle(
        _plannedEndDateMeta,
        plannedEndDate.isAcceptableOrUnknown(
          data['planned_end_date']!,
          _plannedEndDateMeta,
        ),
      );
    }
    if (data.containsKey('actual_end_date')) {
      context.handle(
        _actualEndDateMeta,
        actualEndDate.isAcceptableOrUnknown(
          data['actual_end_date']!,
          _actualEndDateMeta,
        ),
      );
    }
    if (data.containsKey('target_units')) {
      context.handle(
        _targetUnitsMeta,
        targetUnits.isAcceptableOrUnknown(
          data['target_units']!,
          _targetUnitsMeta,
        ),
      );
    }
    if (data.containsKey('consumed_units')) {
      context.handle(
        _consumedUnitsMeta,
        consumedUnits.isAcceptableOrUnknown(
          data['consumed_units']!,
          _consumedUnitsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_consumedUnitsMeta);
    }
    if (data.containsKey('completion_rule')) {
      context.handle(
        _completionRuleMeta,
        completionRule.isAcceptableOrUnknown(
          data['completion_rule']!,
          _completionRuleMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_completionRuleMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CommitmentCycle map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CommitmentCycle(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      commitmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}commitment_id'],
      )!,
      cycleType: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cycle_type'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_date'],
      )!,
      plannedEndDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}planned_end_date'],
      ),
      actualEndDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}actual_end_date'],
      ),
      targetUnits: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_units'],
      ),
      consumedUnits: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}consumed_units'],
      )!,
      completionRule: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}completion_rule'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}status'],
      )!,
    );
  }

  @override
  $CommitmentCyclesTable createAlias(String alias) {
    return $CommitmentCyclesTable(attachedDatabase, alias);
  }
}

class CommitmentCycle extends DataClass implements Insertable<CommitmentCycle> {
  final String id;
  final String commitmentId;
  final int cycleType;
  final DateTime startDate;
  final DateTime? plannedEndDate;
  final DateTime? actualEndDate;
  final int? targetUnits;
  final int consumedUnits;
  final int completionRule;
  final int status;
  const CommitmentCycle({
    required this.id,
    required this.commitmentId,
    required this.cycleType,
    required this.startDate,
    this.plannedEndDate,
    this.actualEndDate,
    this.targetUnits,
    required this.consumedUnits,
    required this.completionRule,
    required this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['commitment_id'] = Variable<String>(commitmentId);
    map['cycle_type'] = Variable<int>(cycleType);
    map['start_date'] = Variable<DateTime>(startDate);
    if (!nullToAbsent || plannedEndDate != null) {
      map['planned_end_date'] = Variable<DateTime>(plannedEndDate);
    }
    if (!nullToAbsent || actualEndDate != null) {
      map['actual_end_date'] = Variable<DateTime>(actualEndDate);
    }
    if (!nullToAbsent || targetUnits != null) {
      map['target_units'] = Variable<int>(targetUnits);
    }
    map['consumed_units'] = Variable<int>(consumedUnits);
    map['completion_rule'] = Variable<int>(completionRule);
    map['status'] = Variable<int>(status);
    return map;
  }

  CommitmentCyclesCompanion toCompanion(bool nullToAbsent) {
    return CommitmentCyclesCompanion(
      id: Value(id),
      commitmentId: Value(commitmentId),
      cycleType: Value(cycleType),
      startDate: Value(startDate),
      plannedEndDate: plannedEndDate == null && nullToAbsent
          ? const Value.absent()
          : Value(plannedEndDate),
      actualEndDate: actualEndDate == null && nullToAbsent
          ? const Value.absent()
          : Value(actualEndDate),
      targetUnits: targetUnits == null && nullToAbsent
          ? const Value.absent()
          : Value(targetUnits),
      consumedUnits: Value(consumedUnits),
      completionRule: Value(completionRule),
      status: Value(status),
    );
  }

  factory CommitmentCycle.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CommitmentCycle(
      id: serializer.fromJson<String>(json['id']),
      commitmentId: serializer.fromJson<String>(json['commitmentId']),
      cycleType: serializer.fromJson<int>(json['cycleType']),
      startDate: serializer.fromJson<DateTime>(json['startDate']),
      plannedEndDate: serializer.fromJson<DateTime?>(json['plannedEndDate']),
      actualEndDate: serializer.fromJson<DateTime?>(json['actualEndDate']),
      targetUnits: serializer.fromJson<int?>(json['targetUnits']),
      consumedUnits: serializer.fromJson<int>(json['consumedUnits']),
      completionRule: serializer.fromJson<int>(json['completionRule']),
      status: serializer.fromJson<int>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'commitmentId': serializer.toJson<String>(commitmentId),
      'cycleType': serializer.toJson<int>(cycleType),
      'startDate': serializer.toJson<DateTime>(startDate),
      'plannedEndDate': serializer.toJson<DateTime?>(plannedEndDate),
      'actualEndDate': serializer.toJson<DateTime?>(actualEndDate),
      'targetUnits': serializer.toJson<int?>(targetUnits),
      'consumedUnits': serializer.toJson<int>(consumedUnits),
      'completionRule': serializer.toJson<int>(completionRule),
      'status': serializer.toJson<int>(status),
    };
  }

  CommitmentCycle copyWith({
    String? id,
    String? commitmentId,
    int? cycleType,
    DateTime? startDate,
    Value<DateTime?> plannedEndDate = const Value.absent(),
    Value<DateTime?> actualEndDate = const Value.absent(),
    Value<int?> targetUnits = const Value.absent(),
    int? consumedUnits,
    int? completionRule,
    int? status,
  }) => CommitmentCycle(
    id: id ?? this.id,
    commitmentId: commitmentId ?? this.commitmentId,
    cycleType: cycleType ?? this.cycleType,
    startDate: startDate ?? this.startDate,
    plannedEndDate: plannedEndDate.present
        ? plannedEndDate.value
        : this.plannedEndDate,
    actualEndDate: actualEndDate.present
        ? actualEndDate.value
        : this.actualEndDate,
    targetUnits: targetUnits.present ? targetUnits.value : this.targetUnits,
    consumedUnits: consumedUnits ?? this.consumedUnits,
    completionRule: completionRule ?? this.completionRule,
    status: status ?? this.status,
  );
  CommitmentCycle copyWithCompanion(CommitmentCyclesCompanion data) {
    return CommitmentCycle(
      id: data.id.present ? data.id.value : this.id,
      commitmentId: data.commitmentId.present
          ? data.commitmentId.value
          : this.commitmentId,
      cycleType: data.cycleType.present ? data.cycleType.value : this.cycleType,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      plannedEndDate: data.plannedEndDate.present
          ? data.plannedEndDate.value
          : this.plannedEndDate,
      actualEndDate: data.actualEndDate.present
          ? data.actualEndDate.value
          : this.actualEndDate,
      targetUnits: data.targetUnits.present
          ? data.targetUnits.value
          : this.targetUnits,
      consumedUnits: data.consumedUnits.present
          ? data.consumedUnits.value
          : this.consumedUnits,
      completionRule: data.completionRule.present
          ? data.completionRule.value
          : this.completionRule,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CommitmentCycle(')
          ..write('id: $id, ')
          ..write('commitmentId: $commitmentId, ')
          ..write('cycleType: $cycleType, ')
          ..write('startDate: $startDate, ')
          ..write('plannedEndDate: $plannedEndDate, ')
          ..write('actualEndDate: $actualEndDate, ')
          ..write('targetUnits: $targetUnits, ')
          ..write('consumedUnits: $consumedUnits, ')
          ..write('completionRule: $completionRule, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    commitmentId,
    cycleType,
    startDate,
    plannedEndDate,
    actualEndDate,
    targetUnits,
    consumedUnits,
    completionRule,
    status,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CommitmentCycle &&
          other.id == this.id &&
          other.commitmentId == this.commitmentId &&
          other.cycleType == this.cycleType &&
          other.startDate == this.startDate &&
          other.plannedEndDate == this.plannedEndDate &&
          other.actualEndDate == this.actualEndDate &&
          other.targetUnits == this.targetUnits &&
          other.consumedUnits == this.consumedUnits &&
          other.completionRule == this.completionRule &&
          other.status == this.status);
}

class CommitmentCyclesCompanion extends UpdateCompanion<CommitmentCycle> {
  final Value<String> id;
  final Value<String> commitmentId;
  final Value<int> cycleType;
  final Value<DateTime> startDate;
  final Value<DateTime?> plannedEndDate;
  final Value<DateTime?> actualEndDate;
  final Value<int?> targetUnits;
  final Value<int> consumedUnits;
  final Value<int> completionRule;
  final Value<int> status;
  final Value<int> rowid;
  const CommitmentCyclesCompanion({
    this.id = const Value.absent(),
    this.commitmentId = const Value.absent(),
    this.cycleType = const Value.absent(),
    this.startDate = const Value.absent(),
    this.plannedEndDate = const Value.absent(),
    this.actualEndDate = const Value.absent(),
    this.targetUnits = const Value.absent(),
    this.consumedUnits = const Value.absent(),
    this.completionRule = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CommitmentCyclesCompanion.insert({
    required String id,
    required String commitmentId,
    required int cycleType,
    required DateTime startDate,
    this.plannedEndDate = const Value.absent(),
    this.actualEndDate = const Value.absent(),
    this.targetUnits = const Value.absent(),
    required int consumedUnits,
    required int completionRule,
    required int status,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       commitmentId = Value(commitmentId),
       cycleType = Value(cycleType),
       startDate = Value(startDate),
       consumedUnits = Value(consumedUnits),
       completionRule = Value(completionRule),
       status = Value(status);
  static Insertable<CommitmentCycle> custom({
    Expression<String>? id,
    Expression<String>? commitmentId,
    Expression<int>? cycleType,
    Expression<DateTime>? startDate,
    Expression<DateTime>? plannedEndDate,
    Expression<DateTime>? actualEndDate,
    Expression<int>? targetUnits,
    Expression<int>? consumedUnits,
    Expression<int>? completionRule,
    Expression<int>? status,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (commitmentId != null) 'commitment_id': commitmentId,
      if (cycleType != null) 'cycle_type': cycleType,
      if (startDate != null) 'start_date': startDate,
      if (plannedEndDate != null) 'planned_end_date': plannedEndDate,
      if (actualEndDate != null) 'actual_end_date': actualEndDate,
      if (targetUnits != null) 'target_units': targetUnits,
      if (consumedUnits != null) 'consumed_units': consumedUnits,
      if (completionRule != null) 'completion_rule': completionRule,
      if (status != null) 'status': status,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CommitmentCyclesCompanion copyWith({
    Value<String>? id,
    Value<String>? commitmentId,
    Value<int>? cycleType,
    Value<DateTime>? startDate,
    Value<DateTime?>? plannedEndDate,
    Value<DateTime?>? actualEndDate,
    Value<int?>? targetUnits,
    Value<int>? consumedUnits,
    Value<int>? completionRule,
    Value<int>? status,
    Value<int>? rowid,
  }) {
    return CommitmentCyclesCompanion(
      id: id ?? this.id,
      commitmentId: commitmentId ?? this.commitmentId,
      cycleType: cycleType ?? this.cycleType,
      startDate: startDate ?? this.startDate,
      plannedEndDate: plannedEndDate ?? this.plannedEndDate,
      actualEndDate: actualEndDate ?? this.actualEndDate,
      targetUnits: targetUnits ?? this.targetUnits,
      consumedUnits: consumedUnits ?? this.consumedUnits,
      completionRule: completionRule ?? this.completionRule,
      status: status ?? this.status,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (commitmentId.present) {
      map['commitment_id'] = Variable<String>(commitmentId.value);
    }
    if (cycleType.present) {
      map['cycle_type'] = Variable<int>(cycleType.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (plannedEndDate.present) {
      map['planned_end_date'] = Variable<DateTime>(plannedEndDate.value);
    }
    if (actualEndDate.present) {
      map['actual_end_date'] = Variable<DateTime>(actualEndDate.value);
    }
    if (targetUnits.present) {
      map['target_units'] = Variable<int>(targetUnits.value);
    }
    if (consumedUnits.present) {
      map['consumed_units'] = Variable<int>(consumedUnits.value);
    }
    if (completionRule.present) {
      map['completion_rule'] = Variable<int>(completionRule.value);
    }
    if (status.present) {
      map['status'] = Variable<int>(status.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CommitmentCyclesCompanion(')
          ..write('id: $id, ')
          ..write('commitmentId: $commitmentId, ')
          ..write('cycleType: $cycleType, ')
          ..write('startDate: $startDate, ')
          ..write('plannedEndDate: $plannedEndDate, ')
          ..write('actualEndDate: $actualEndDate, ')
          ..write('targetUnits: $targetUnits, ')
          ..write('consumedUnits: $consumedUnits, ')
          ..write('completionRule: $completionRule, ')
          ..write('status: $status, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SchemaMetadataTable schemaMetadata = $SchemaMetadataTable(this);
  late final $CommitmentsTable commitments = $CommitmentsTable(this);
  late final $CommitmentCyclesTable commitmentCycles = $CommitmentCyclesTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    schemaMetadata,
    commitments,
    commitmentCycles,
  ];
}

typedef $$SchemaMetadataTableCreateCompanionBuilder =
    SchemaMetadataCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$SchemaMetadataTableUpdateCompanionBuilder =
    SchemaMetadataCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$SchemaMetadataTableFilterComposer
    extends Composer<_$AppDatabase, $SchemaMetadataTable> {
  $$SchemaMetadataTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SchemaMetadataTableOrderingComposer
    extends Composer<_$AppDatabase, $SchemaMetadataTable> {
  $$SchemaMetadataTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SchemaMetadataTableAnnotationComposer
    extends Composer<_$AppDatabase, $SchemaMetadataTable> {
  $$SchemaMetadataTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SchemaMetadataTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SchemaMetadataTable,
          SchemaMetadataData,
          $$SchemaMetadataTableFilterComposer,
          $$SchemaMetadataTableOrderingComposer,
          $$SchemaMetadataTableAnnotationComposer,
          $$SchemaMetadataTableCreateCompanionBuilder,
          $$SchemaMetadataTableUpdateCompanionBuilder,
          (
            SchemaMetadataData,
            BaseReferences<
              _$AppDatabase,
              $SchemaMetadataTable,
              SchemaMetadataData
            >,
          ),
          SchemaMetadataData,
          PrefetchHooks Function()
        > {
  $$SchemaMetadataTableTableManager(
    _$AppDatabase db,
    $SchemaMetadataTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SchemaMetadataTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SchemaMetadataTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SchemaMetadataTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => SchemaMetadataCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => SchemaMetadataCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SchemaMetadataTable, SchemaMetadataData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $SchemaMetadataTable,
                    SchemaMetadataData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SchemaMetadataTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SchemaMetadataTable,
      SchemaMetadataData,
      $$SchemaMetadataTableFilterComposer,
      $$SchemaMetadataTableOrderingComposer,
      $$SchemaMetadataTableAnnotationComposer,
      $$SchemaMetadataTableCreateCompanionBuilder,
      $$SchemaMetadataTableUpdateCompanionBuilder,
      (
        SchemaMetadataData,
        BaseReferences<_$AppDatabase, $SchemaMetadataTable, SchemaMetadataData>,
      ),
      SchemaMetadataData,
      PrefetchHooks Function()
    >;
typedef $$CommitmentsTableCreateCompanionBuilder =
    CommitmentsCompanion Function({
      required String id,
      required String title,
      required DateTime createdAt,
      required int status,
      Value<int> rowid,
    });
typedef $$CommitmentsTableUpdateCompanionBuilder =
    CommitmentsCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<DateTime> createdAt,
      Value<int> status,
      Value<int> rowid,
    });

final class $$CommitmentsTableReferences
    extends BaseReferences<_$AppDatabase, $CommitmentsTable, Commitment> {
  $$CommitmentsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$CommitmentCyclesTable, List<CommitmentCycle>>
  _commitmentCyclesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.commitmentCycles,
    aliasName: 'commitments__id__commitment_cycles__commitment_id',
  );

  $$CommitmentCyclesTableProcessedTableManager get commitmentCyclesRefs {
    final manager = $$CommitmentCyclesTableTableManager(
      $_db,
      $_db.commitmentCycles,
    ).filter((f) => f.commitmentId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _commitmentCyclesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CommitmentsTableFilterComposer
    extends Composer<_$AppDatabase, $CommitmentsTable> {
  $$CommitmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> commitmentCyclesRefs(
    Expression<bool> Function($$CommitmentCyclesTableFilterComposer f) f,
  ) {
    final $$CommitmentCyclesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.commitmentCycles,
      getReferencedColumn: (t) => t.commitmentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CommitmentCyclesTableFilterComposer(
            $db: $db,
            $table: $db.commitmentCycles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CommitmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $CommitmentsTable> {
  $$CommitmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CommitmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CommitmentsTable> {
  $$CommitmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  Expression<T> commitmentCyclesRefs<T extends Object>(
    Expression<T> Function($$CommitmentCyclesTableAnnotationComposer a) f,
  ) {
    final $$CommitmentCyclesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.commitmentCycles,
      getReferencedColumn: (t) => t.commitmentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CommitmentCyclesTableAnnotationComposer(
            $db: $db,
            $table: $db.commitmentCycles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CommitmentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CommitmentsTable,
          Commitment,
          $$CommitmentsTableFilterComposer,
          $$CommitmentsTableOrderingComposer,
          $$CommitmentsTableAnnotationComposer,
          $$CommitmentsTableCreateCompanionBuilder,
          $$CommitmentsTableUpdateCompanionBuilder,
          (Commitment, $$CommitmentsTableReferences),
          Commitment,
          PrefetchHooks Function({bool commitmentCyclesRefs})
        > {
  $$CommitmentsTableTableManager(_$AppDatabase db, $CommitmentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CommitmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CommitmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CommitmentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> status = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CommitmentsCompanion(
                id: id,
                title: title,
                createdAt: createdAt,
                status: status,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                required DateTime createdAt,
                required int status,
                Value<int> rowid = const Value.absent(),
              }) => CommitmentsCompanion.insert(
                id: id,
                title: title,
                createdAt: createdAt,
                status: status,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CommitmentsTable, Commitment>(table),
                  $$CommitmentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({commitmentCyclesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (commitmentCyclesRefs) db.commitmentCycles,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (commitmentCyclesRefs)
                    await $_getPrefetchedData<
                      Commitment,
                      $CommitmentsTable,
                      CommitmentCycle
                    >(
                      currentTable: table,
                      referencedTable: $$CommitmentsTableReferences
                          ._commitmentCyclesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$CommitmentsTableReferences(
                            db,
                            table,
                            p0,
                          ).commitmentCyclesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.commitmentId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$CommitmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CommitmentsTable,
      Commitment,
      $$CommitmentsTableFilterComposer,
      $$CommitmentsTableOrderingComposer,
      $$CommitmentsTableAnnotationComposer,
      $$CommitmentsTableCreateCompanionBuilder,
      $$CommitmentsTableUpdateCompanionBuilder,
      (Commitment, $$CommitmentsTableReferences),
      Commitment,
      PrefetchHooks Function({bool commitmentCyclesRefs})
    >;
typedef $$CommitmentCyclesTableCreateCompanionBuilder =
    CommitmentCyclesCompanion Function({
      required String id,
      required String commitmentId,
      required int cycleType,
      required DateTime startDate,
      Value<DateTime?> plannedEndDate,
      Value<DateTime?> actualEndDate,
      Value<int?> targetUnits,
      required int consumedUnits,
      required int completionRule,
      required int status,
      Value<int> rowid,
    });
typedef $$CommitmentCyclesTableUpdateCompanionBuilder =
    CommitmentCyclesCompanion Function({
      Value<String> id,
      Value<String> commitmentId,
      Value<int> cycleType,
      Value<DateTime> startDate,
      Value<DateTime?> plannedEndDate,
      Value<DateTime?> actualEndDate,
      Value<int?> targetUnits,
      Value<int> consumedUnits,
      Value<int> completionRule,
      Value<int> status,
      Value<int> rowid,
    });

final class $$CommitmentCyclesTableReferences
    extends
        BaseReferences<_$AppDatabase, $CommitmentCyclesTable, CommitmentCycle> {
  $$CommitmentCyclesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CommitmentsTable _commitmentIdTable(_$AppDatabase db) => db
      .commitments
      .createAlias('commitment_cycles__commitment_id__commitments__id');

  $$CommitmentsTableProcessedTableManager get commitmentId {
    final $_column = $_itemColumn<String>('commitment_id')!;

    final manager = $$CommitmentsTableTableManager(
      $_db,
      $_db.commitments,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_commitmentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CommitmentCyclesTableFilterComposer
    extends Composer<_$AppDatabase, $CommitmentCyclesTable> {
  $$CommitmentCyclesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cycleType => $composableBuilder(
    column: $table.cycleType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get plannedEndDate => $composableBuilder(
    column: $table.plannedEndDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get actualEndDate => $composableBuilder(
    column: $table.actualEndDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetUnits => $composableBuilder(
    column: $table.targetUnits,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get consumedUnits => $composableBuilder(
    column: $table.consumedUnits,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get completionRule => $composableBuilder(
    column: $table.completionRule,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  $$CommitmentsTableFilterComposer get commitmentId {
    final $$CommitmentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.commitmentId,
      referencedTable: $db.commitments,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CommitmentsTableFilterComposer(
            $db: $db,
            $table: $db.commitments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CommitmentCyclesTableOrderingComposer
    extends Composer<_$AppDatabase, $CommitmentCyclesTable> {
  $$CommitmentCyclesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cycleType => $composableBuilder(
    column: $table.cycleType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get plannedEndDate => $composableBuilder(
    column: $table.plannedEndDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get actualEndDate => $composableBuilder(
    column: $table.actualEndDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetUnits => $composableBuilder(
    column: $table.targetUnits,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get consumedUnits => $composableBuilder(
    column: $table.consumedUnits,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get completionRule => $composableBuilder(
    column: $table.completionRule,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  $$CommitmentsTableOrderingComposer get commitmentId {
    final $$CommitmentsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.commitmentId,
      referencedTable: $db.commitments,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CommitmentsTableOrderingComposer(
            $db: $db,
            $table: $db.commitments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CommitmentCyclesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CommitmentCyclesTable> {
  $$CommitmentCyclesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get cycleType =>
      $composableBuilder(column: $table.cycleType, builder: (column) => column);

  GeneratedColumn<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<DateTime> get plannedEndDate => $composableBuilder(
    column: $table.plannedEndDate,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get actualEndDate => $composableBuilder(
    column: $table.actualEndDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get targetUnits => $composableBuilder(
    column: $table.targetUnits,
    builder: (column) => column,
  );

  GeneratedColumn<int> get consumedUnits => $composableBuilder(
    column: $table.consumedUnits,
    builder: (column) => column,
  );

  GeneratedColumn<int> get completionRule => $composableBuilder(
    column: $table.completionRule,
    builder: (column) => column,
  );

  GeneratedColumn<int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  $$CommitmentsTableAnnotationComposer get commitmentId {
    final $$CommitmentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.commitmentId,
      referencedTable: $db.commitments,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CommitmentsTableAnnotationComposer(
            $db: $db,
            $table: $db.commitments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CommitmentCyclesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CommitmentCyclesTable,
          CommitmentCycle,
          $$CommitmentCyclesTableFilterComposer,
          $$CommitmentCyclesTableOrderingComposer,
          $$CommitmentCyclesTableAnnotationComposer,
          $$CommitmentCyclesTableCreateCompanionBuilder,
          $$CommitmentCyclesTableUpdateCompanionBuilder,
          (CommitmentCycle, $$CommitmentCyclesTableReferences),
          CommitmentCycle,
          PrefetchHooks Function({bool commitmentId})
        > {
  $$CommitmentCyclesTableTableManager(
    _$AppDatabase db,
    $CommitmentCyclesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CommitmentCyclesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CommitmentCyclesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CommitmentCyclesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> commitmentId = const Value.absent(),
                Value<int> cycleType = const Value.absent(),
                Value<DateTime> startDate = const Value.absent(),
                Value<DateTime?> plannedEndDate = const Value.absent(),
                Value<DateTime?> actualEndDate = const Value.absent(),
                Value<int?> targetUnits = const Value.absent(),
                Value<int> consumedUnits = const Value.absent(),
                Value<int> completionRule = const Value.absent(),
                Value<int> status = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CommitmentCyclesCompanion(
                id: id,
                commitmentId: commitmentId,
                cycleType: cycleType,
                startDate: startDate,
                plannedEndDate: plannedEndDate,
                actualEndDate: actualEndDate,
                targetUnits: targetUnits,
                consumedUnits: consumedUnits,
                completionRule: completionRule,
                status: status,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String commitmentId,
                required int cycleType,
                required DateTime startDate,
                Value<DateTime?> plannedEndDate = const Value.absent(),
                Value<DateTime?> actualEndDate = const Value.absent(),
                Value<int?> targetUnits = const Value.absent(),
                required int consumedUnits,
                required int completionRule,
                required int status,
                Value<int> rowid = const Value.absent(),
              }) => CommitmentCyclesCompanion.insert(
                id: id,
                commitmentId: commitmentId,
                cycleType: cycleType,
                startDate: startDate,
                plannedEndDate: plannedEndDate,
                actualEndDate: actualEndDate,
                targetUnits: targetUnits,
                consumedUnits: consumedUnits,
                completionRule: completionRule,
                status: status,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CommitmentCyclesTable, CommitmentCycle>(table),
                  $$CommitmentCyclesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({commitmentId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (commitmentId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.commitmentId,
                        referencedTable: $$CommitmentCyclesTableReferences
                            ._commitmentIdTable(db),
                        referencedColumn: $$CommitmentCyclesTableReferences
                            ._commitmentIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CommitmentCyclesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CommitmentCyclesTable,
      CommitmentCycle,
      $$CommitmentCyclesTableFilterComposer,
      $$CommitmentCyclesTableOrderingComposer,
      $$CommitmentCyclesTableAnnotationComposer,
      $$CommitmentCyclesTableCreateCompanionBuilder,
      $$CommitmentCyclesTableUpdateCompanionBuilder,
      (CommitmentCycle, $$CommitmentCyclesTableReferences),
      CommitmentCycle,
      PrefetchHooks Function({bool commitmentId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SchemaMetadataTableTableManager get schemaMetadata =>
      $$SchemaMetadataTableTableManager(_db, _db.schemaMetadata);
  $$CommitmentsTableTableManager get commitments =>
      $$CommitmentsTableTableManager(_db, _db.commitments);
  $$CommitmentCyclesTableTableManager get commitmentCycles =>
      $$CommitmentCyclesTableTableManager(_db, _db.commitmentCycles);
}
