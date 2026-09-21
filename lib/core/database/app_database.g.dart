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

class $ScheduleDefinitionsTable extends ScheduleDefinitions
    with TableInfo<$ScheduleDefinitionsTable, ScheduleDefinition> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ScheduleDefinitionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cycleIdMeta = const VerificationMeta(
    'cycleId',
  );
  @override
  late final GeneratedColumn<String> cycleId = GeneratedColumn<String>(
    'cycle_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES commitment_cycles (id)',
    ),
  );
  static const VerificationMeta _modeMeta = const VerificationMeta('mode');
  @override
  late final GeneratedColumn<int> mode = GeneratedColumn<int>(
    'mode',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timeSemanticsMeta = const VerificationMeta(
    'timeSemantics',
  );
  @override
  late final GeneratedColumn<int> timeSemantics = GeneratedColumn<int>(
    'time_semantics',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<String> startDate = GeneratedColumn<String>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localTimeMeta = const VerificationMeta(
    'localTime',
  );
  @override
  late final GeneratedColumn<String> localTime = GeneratedColumn<String>(
    'local_time',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timeZoneIdMeta = const VerificationMeta(
    'timeZoneId',
  );
  @override
  late final GeneratedColumn<String> timeZoneId = GeneratedColumn<String>(
    'time_zone_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fixedInstantMeta = const VerificationMeta(
    'fixedInstant',
  );
  @override
  late final GeneratedColumn<DateTime> fixedInstant = GeneratedColumn<DateTime>(
    'fixed_instant',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recurrenceRuleMeta = const VerificationMeta(
    'recurrenceRule',
  );
  @override
  late final GeneratedColumn<String> recurrenceRule = GeneratedColumn<String>(
    'recurrence_rule',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endDateMeta = const VerificationMeta(
    'endDate',
  );
  @override
  late final GeneratedColumn<String> endDate = GeneratedColumn<String>(
    'end_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _occurrenceCountMeta = const VerificationMeta(
    'occurrenceCount',
  );
  @override
  late final GeneratedColumn<int> occurrenceCount = GeneratedColumn<int>(
    'occurrence_count',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _effectiveFromMeta = const VerificationMeta(
    'effectiveFrom',
  );
  @override
  late final GeneratedColumn<String> effectiveFrom = GeneratedColumn<String>(
    'effective_from',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _generationHorizonDaysMeta =
      const VerificationMeta('generationHorizonDays');
  @override
  late final GeneratedColumn<int> generationHorizonDays = GeneratedColumn<int>(
    'generation_horizon_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    cycleId,
    mode,
    timeSemantics,
    startDate,
    localTime,
    timeZoneId,
    fixedInstant,
    recurrenceRule,
    endDate,
    occurrenceCount,
    version,
    effectiveFrom,
    generationHorizonDays,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'schedule_definitions';
  @override
  VerificationContext validateIntegrity(
    Insertable<ScheduleDefinition> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('cycle_id')) {
      context.handle(
        _cycleIdMeta,
        cycleId.isAcceptableOrUnknown(data['cycle_id']!, _cycleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cycleIdMeta);
    }
    if (data.containsKey('mode')) {
      context.handle(
        _modeMeta,
        mode.isAcceptableOrUnknown(data['mode']!, _modeMeta),
      );
    } else if (isInserting) {
      context.missing(_modeMeta);
    }
    if (data.containsKey('time_semantics')) {
      context.handle(
        _timeSemanticsMeta,
        timeSemantics.isAcceptableOrUnknown(
          data['time_semantics']!,
          _timeSemanticsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_timeSemanticsMeta);
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('local_time')) {
      context.handle(
        _localTimeMeta,
        localTime.isAcceptableOrUnknown(data['local_time']!, _localTimeMeta),
      );
    }
    if (data.containsKey('time_zone_id')) {
      context.handle(
        _timeZoneIdMeta,
        timeZoneId.isAcceptableOrUnknown(
          data['time_zone_id']!,
          _timeZoneIdMeta,
        ),
      );
    }
    if (data.containsKey('fixed_instant')) {
      context.handle(
        _fixedInstantMeta,
        fixedInstant.isAcceptableOrUnknown(
          data['fixed_instant']!,
          _fixedInstantMeta,
        ),
      );
    }
    if (data.containsKey('recurrence_rule')) {
      context.handle(
        _recurrenceRuleMeta,
        recurrenceRule.isAcceptableOrUnknown(
          data['recurrence_rule']!,
          _recurrenceRuleMeta,
        ),
      );
    }
    if (data.containsKey('end_date')) {
      context.handle(
        _endDateMeta,
        endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta),
      );
    }
    if (data.containsKey('occurrence_count')) {
      context.handle(
        _occurrenceCountMeta,
        occurrenceCount.isAcceptableOrUnknown(
          data['occurrence_count']!,
          _occurrenceCountMeta,
        ),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('effective_from')) {
      context.handle(
        _effectiveFromMeta,
        effectiveFrom.isAcceptableOrUnknown(
          data['effective_from']!,
          _effectiveFromMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_effectiveFromMeta);
    }
    if (data.containsKey('generation_horizon_days')) {
      context.handle(
        _generationHorizonDaysMeta,
        generationHorizonDays.isAcceptableOrUnknown(
          data['generation_horizon_days']!,
          _generationHorizonDaysMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_generationHorizonDaysMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ScheduleDefinition map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ScheduleDefinition(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      cycleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cycle_id'],
      )!,
      mode: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}mode'],
      )!,
      timeSemantics: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}time_semantics'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_date'],
      )!,
      localTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_time'],
      ),
      timeZoneId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}time_zone_id'],
      ),
      fixedInstant: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fixed_instant'],
      ),
      recurrenceRule: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recurrence_rule'],
      ),
      endDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}end_date'],
      ),
      occurrenceCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}occurrence_count'],
      ),
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      effectiveFrom: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}effective_from'],
      )!,
      generationHorizonDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}generation_horizon_days'],
      )!,
    );
  }

  @override
  $ScheduleDefinitionsTable createAlias(String alias) {
    return $ScheduleDefinitionsTable(attachedDatabase, alias);
  }
}

class ScheduleDefinition extends DataClass
    implements Insertable<ScheduleDefinition> {
  final String id;
  final String cycleId;
  final int mode;
  final int timeSemantics;
  final String startDate;
  final String? localTime;
  final String? timeZoneId;
  final DateTime? fixedInstant;
  final String? recurrenceRule;
  final String? endDate;
  final int? occurrenceCount;
  final int version;
  final String effectiveFrom;
  final int generationHorizonDays;
  const ScheduleDefinition({
    required this.id,
    required this.cycleId,
    required this.mode,
    required this.timeSemantics,
    required this.startDate,
    this.localTime,
    this.timeZoneId,
    this.fixedInstant,
    this.recurrenceRule,
    this.endDate,
    this.occurrenceCount,
    required this.version,
    required this.effectiveFrom,
    required this.generationHorizonDays,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['cycle_id'] = Variable<String>(cycleId);
    map['mode'] = Variable<int>(mode);
    map['time_semantics'] = Variable<int>(timeSemantics);
    map['start_date'] = Variable<String>(startDate);
    if (!nullToAbsent || localTime != null) {
      map['local_time'] = Variable<String>(localTime);
    }
    if (!nullToAbsent || timeZoneId != null) {
      map['time_zone_id'] = Variable<String>(timeZoneId);
    }
    if (!nullToAbsent || fixedInstant != null) {
      map['fixed_instant'] = Variable<DateTime>(fixedInstant);
    }
    if (!nullToAbsent || recurrenceRule != null) {
      map['recurrence_rule'] = Variable<String>(recurrenceRule);
    }
    if (!nullToAbsent || endDate != null) {
      map['end_date'] = Variable<String>(endDate);
    }
    if (!nullToAbsent || occurrenceCount != null) {
      map['occurrence_count'] = Variable<int>(occurrenceCount);
    }
    map['version'] = Variable<int>(version);
    map['effective_from'] = Variable<String>(effectiveFrom);
    map['generation_horizon_days'] = Variable<int>(generationHorizonDays);
    return map;
  }

  ScheduleDefinitionsCompanion toCompanion(bool nullToAbsent) {
    return ScheduleDefinitionsCompanion(
      id: Value(id),
      cycleId: Value(cycleId),
      mode: Value(mode),
      timeSemantics: Value(timeSemantics),
      startDate: Value(startDate),
      localTime: localTime == null && nullToAbsent
          ? const Value.absent()
          : Value(localTime),
      timeZoneId: timeZoneId == null && nullToAbsent
          ? const Value.absent()
          : Value(timeZoneId),
      fixedInstant: fixedInstant == null && nullToAbsent
          ? const Value.absent()
          : Value(fixedInstant),
      recurrenceRule: recurrenceRule == null && nullToAbsent
          ? const Value.absent()
          : Value(recurrenceRule),
      endDate: endDate == null && nullToAbsent
          ? const Value.absent()
          : Value(endDate),
      occurrenceCount: occurrenceCount == null && nullToAbsent
          ? const Value.absent()
          : Value(occurrenceCount),
      version: Value(version),
      effectiveFrom: Value(effectiveFrom),
      generationHorizonDays: Value(generationHorizonDays),
    );
  }

  factory ScheduleDefinition.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ScheduleDefinition(
      id: serializer.fromJson<String>(json['id']),
      cycleId: serializer.fromJson<String>(json['cycleId']),
      mode: serializer.fromJson<int>(json['mode']),
      timeSemantics: serializer.fromJson<int>(json['timeSemantics']),
      startDate: serializer.fromJson<String>(json['startDate']),
      localTime: serializer.fromJson<String?>(json['localTime']),
      timeZoneId: serializer.fromJson<String?>(json['timeZoneId']),
      fixedInstant: serializer.fromJson<DateTime?>(json['fixedInstant']),
      recurrenceRule: serializer.fromJson<String?>(json['recurrenceRule']),
      endDate: serializer.fromJson<String?>(json['endDate']),
      occurrenceCount: serializer.fromJson<int?>(json['occurrenceCount']),
      version: serializer.fromJson<int>(json['version']),
      effectiveFrom: serializer.fromJson<String>(json['effectiveFrom']),
      generationHorizonDays: serializer.fromJson<int>(
        json['generationHorizonDays'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'cycleId': serializer.toJson<String>(cycleId),
      'mode': serializer.toJson<int>(mode),
      'timeSemantics': serializer.toJson<int>(timeSemantics),
      'startDate': serializer.toJson<String>(startDate),
      'localTime': serializer.toJson<String?>(localTime),
      'timeZoneId': serializer.toJson<String?>(timeZoneId),
      'fixedInstant': serializer.toJson<DateTime?>(fixedInstant),
      'recurrenceRule': serializer.toJson<String?>(recurrenceRule),
      'endDate': serializer.toJson<String?>(endDate),
      'occurrenceCount': serializer.toJson<int?>(occurrenceCount),
      'version': serializer.toJson<int>(version),
      'effectiveFrom': serializer.toJson<String>(effectiveFrom),
      'generationHorizonDays': serializer.toJson<int>(generationHorizonDays),
    };
  }

  ScheduleDefinition copyWith({
    String? id,
    String? cycleId,
    int? mode,
    int? timeSemantics,
    String? startDate,
    Value<String?> localTime = const Value.absent(),
    Value<String?> timeZoneId = const Value.absent(),
    Value<DateTime?> fixedInstant = const Value.absent(),
    Value<String?> recurrenceRule = const Value.absent(),
    Value<String?> endDate = const Value.absent(),
    Value<int?> occurrenceCount = const Value.absent(),
    int? version,
    String? effectiveFrom,
    int? generationHorizonDays,
  }) => ScheduleDefinition(
    id: id ?? this.id,
    cycleId: cycleId ?? this.cycleId,
    mode: mode ?? this.mode,
    timeSemantics: timeSemantics ?? this.timeSemantics,
    startDate: startDate ?? this.startDate,
    localTime: localTime.present ? localTime.value : this.localTime,
    timeZoneId: timeZoneId.present ? timeZoneId.value : this.timeZoneId,
    fixedInstant: fixedInstant.present ? fixedInstant.value : this.fixedInstant,
    recurrenceRule: recurrenceRule.present
        ? recurrenceRule.value
        : this.recurrenceRule,
    endDate: endDate.present ? endDate.value : this.endDate,
    occurrenceCount: occurrenceCount.present
        ? occurrenceCount.value
        : this.occurrenceCount,
    version: version ?? this.version,
    effectiveFrom: effectiveFrom ?? this.effectiveFrom,
    generationHorizonDays: generationHorizonDays ?? this.generationHorizonDays,
  );
  ScheduleDefinition copyWithCompanion(ScheduleDefinitionsCompanion data) {
    return ScheduleDefinition(
      id: data.id.present ? data.id.value : this.id,
      cycleId: data.cycleId.present ? data.cycleId.value : this.cycleId,
      mode: data.mode.present ? data.mode.value : this.mode,
      timeSemantics: data.timeSemantics.present
          ? data.timeSemantics.value
          : this.timeSemantics,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      localTime: data.localTime.present ? data.localTime.value : this.localTime,
      timeZoneId: data.timeZoneId.present
          ? data.timeZoneId.value
          : this.timeZoneId,
      fixedInstant: data.fixedInstant.present
          ? data.fixedInstant.value
          : this.fixedInstant,
      recurrenceRule: data.recurrenceRule.present
          ? data.recurrenceRule.value
          : this.recurrenceRule,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      occurrenceCount: data.occurrenceCount.present
          ? data.occurrenceCount.value
          : this.occurrenceCount,
      version: data.version.present ? data.version.value : this.version,
      effectiveFrom: data.effectiveFrom.present
          ? data.effectiveFrom.value
          : this.effectiveFrom,
      generationHorizonDays: data.generationHorizonDays.present
          ? data.generationHorizonDays.value
          : this.generationHorizonDays,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ScheduleDefinition(')
          ..write('id: $id, ')
          ..write('cycleId: $cycleId, ')
          ..write('mode: $mode, ')
          ..write('timeSemantics: $timeSemantics, ')
          ..write('startDate: $startDate, ')
          ..write('localTime: $localTime, ')
          ..write('timeZoneId: $timeZoneId, ')
          ..write('fixedInstant: $fixedInstant, ')
          ..write('recurrenceRule: $recurrenceRule, ')
          ..write('endDate: $endDate, ')
          ..write('occurrenceCount: $occurrenceCount, ')
          ..write('version: $version, ')
          ..write('effectiveFrom: $effectiveFrom, ')
          ..write('generationHorizonDays: $generationHorizonDays')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    cycleId,
    mode,
    timeSemantics,
    startDate,
    localTime,
    timeZoneId,
    fixedInstant,
    recurrenceRule,
    endDate,
    occurrenceCount,
    version,
    effectiveFrom,
    generationHorizonDays,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScheduleDefinition &&
          other.id == this.id &&
          other.cycleId == this.cycleId &&
          other.mode == this.mode &&
          other.timeSemantics == this.timeSemantics &&
          other.startDate == this.startDate &&
          other.localTime == this.localTime &&
          other.timeZoneId == this.timeZoneId &&
          other.fixedInstant == this.fixedInstant &&
          other.recurrenceRule == this.recurrenceRule &&
          other.endDate == this.endDate &&
          other.occurrenceCount == this.occurrenceCount &&
          other.version == this.version &&
          other.effectiveFrom == this.effectiveFrom &&
          other.generationHorizonDays == this.generationHorizonDays);
}

class ScheduleDefinitionsCompanion extends UpdateCompanion<ScheduleDefinition> {
  final Value<String> id;
  final Value<String> cycleId;
  final Value<int> mode;
  final Value<int> timeSemantics;
  final Value<String> startDate;
  final Value<String?> localTime;
  final Value<String?> timeZoneId;
  final Value<DateTime?> fixedInstant;
  final Value<String?> recurrenceRule;
  final Value<String?> endDate;
  final Value<int?> occurrenceCount;
  final Value<int> version;
  final Value<String> effectiveFrom;
  final Value<int> generationHorizonDays;
  final Value<int> rowid;
  const ScheduleDefinitionsCompanion({
    this.id = const Value.absent(),
    this.cycleId = const Value.absent(),
    this.mode = const Value.absent(),
    this.timeSemantics = const Value.absent(),
    this.startDate = const Value.absent(),
    this.localTime = const Value.absent(),
    this.timeZoneId = const Value.absent(),
    this.fixedInstant = const Value.absent(),
    this.recurrenceRule = const Value.absent(),
    this.endDate = const Value.absent(),
    this.occurrenceCount = const Value.absent(),
    this.version = const Value.absent(),
    this.effectiveFrom = const Value.absent(),
    this.generationHorizonDays = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ScheduleDefinitionsCompanion.insert({
    required String id,
    required String cycleId,
    required int mode,
    required int timeSemantics,
    required String startDate,
    this.localTime = const Value.absent(),
    this.timeZoneId = const Value.absent(),
    this.fixedInstant = const Value.absent(),
    this.recurrenceRule = const Value.absent(),
    this.endDate = const Value.absent(),
    this.occurrenceCount = const Value.absent(),
    required int version,
    required String effectiveFrom,
    required int generationHorizonDays,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       cycleId = Value(cycleId),
       mode = Value(mode),
       timeSemantics = Value(timeSemantics),
       startDate = Value(startDate),
       version = Value(version),
       effectiveFrom = Value(effectiveFrom),
       generationHorizonDays = Value(generationHorizonDays);
  static Insertable<ScheduleDefinition> custom({
    Expression<String>? id,
    Expression<String>? cycleId,
    Expression<int>? mode,
    Expression<int>? timeSemantics,
    Expression<String>? startDate,
    Expression<String>? localTime,
    Expression<String>? timeZoneId,
    Expression<DateTime>? fixedInstant,
    Expression<String>? recurrenceRule,
    Expression<String>? endDate,
    Expression<int>? occurrenceCount,
    Expression<int>? version,
    Expression<String>? effectiveFrom,
    Expression<int>? generationHorizonDays,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (cycleId != null) 'cycle_id': cycleId,
      if (mode != null) 'mode': mode,
      if (timeSemantics != null) 'time_semantics': timeSemantics,
      if (startDate != null) 'start_date': startDate,
      if (localTime != null) 'local_time': localTime,
      if (timeZoneId != null) 'time_zone_id': timeZoneId,
      if (fixedInstant != null) 'fixed_instant': fixedInstant,
      if (recurrenceRule != null) 'recurrence_rule': recurrenceRule,
      if (endDate != null) 'end_date': endDate,
      if (occurrenceCount != null) 'occurrence_count': occurrenceCount,
      if (version != null) 'version': version,
      if (effectiveFrom != null) 'effective_from': effectiveFrom,
      if (generationHorizonDays != null)
        'generation_horizon_days': generationHorizonDays,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ScheduleDefinitionsCompanion copyWith({
    Value<String>? id,
    Value<String>? cycleId,
    Value<int>? mode,
    Value<int>? timeSemantics,
    Value<String>? startDate,
    Value<String?>? localTime,
    Value<String?>? timeZoneId,
    Value<DateTime?>? fixedInstant,
    Value<String?>? recurrenceRule,
    Value<String?>? endDate,
    Value<int?>? occurrenceCount,
    Value<int>? version,
    Value<String>? effectiveFrom,
    Value<int>? generationHorizonDays,
    Value<int>? rowid,
  }) {
    return ScheduleDefinitionsCompanion(
      id: id ?? this.id,
      cycleId: cycleId ?? this.cycleId,
      mode: mode ?? this.mode,
      timeSemantics: timeSemantics ?? this.timeSemantics,
      startDate: startDate ?? this.startDate,
      localTime: localTime ?? this.localTime,
      timeZoneId: timeZoneId ?? this.timeZoneId,
      fixedInstant: fixedInstant ?? this.fixedInstant,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      endDate: endDate ?? this.endDate,
      occurrenceCount: occurrenceCount ?? this.occurrenceCount,
      version: version ?? this.version,
      effectiveFrom: effectiveFrom ?? this.effectiveFrom,
      generationHorizonDays:
          generationHorizonDays ?? this.generationHorizonDays,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (cycleId.present) {
      map['cycle_id'] = Variable<String>(cycleId.value);
    }
    if (mode.present) {
      map['mode'] = Variable<int>(mode.value);
    }
    if (timeSemantics.present) {
      map['time_semantics'] = Variable<int>(timeSemantics.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<String>(startDate.value);
    }
    if (localTime.present) {
      map['local_time'] = Variable<String>(localTime.value);
    }
    if (timeZoneId.present) {
      map['time_zone_id'] = Variable<String>(timeZoneId.value);
    }
    if (fixedInstant.present) {
      map['fixed_instant'] = Variable<DateTime>(fixedInstant.value);
    }
    if (recurrenceRule.present) {
      map['recurrence_rule'] = Variable<String>(recurrenceRule.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<String>(endDate.value);
    }
    if (occurrenceCount.present) {
      map['occurrence_count'] = Variable<int>(occurrenceCount.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (effectiveFrom.present) {
      map['effective_from'] = Variable<String>(effectiveFrom.value);
    }
    if (generationHorizonDays.present) {
      map['generation_horizon_days'] = Variable<int>(
        generationHorizonDays.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScheduleDefinitionsCompanion(')
          ..write('id: $id, ')
          ..write('cycleId: $cycleId, ')
          ..write('mode: $mode, ')
          ..write('timeSemantics: $timeSemantics, ')
          ..write('startDate: $startDate, ')
          ..write('localTime: $localTime, ')
          ..write('timeZoneId: $timeZoneId, ')
          ..write('fixedInstant: $fixedInstant, ')
          ..write('recurrenceRule: $recurrenceRule, ')
          ..write('endDate: $endDate, ')
          ..write('occurrenceCount: $occurrenceCount, ')
          ..write('version: $version, ')
          ..write('effectiveFrom: $effectiveFrom, ')
          ..write('generationHorizonDays: $generationHorizonDays, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OccurrencesTable extends Occurrences
    with TableInfo<$OccurrencesTable, Occurrence> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OccurrencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cycleIdMeta = const VerificationMeta(
    'cycleId',
  );
  @override
  late final GeneratedColumn<String> cycleId = GeneratedColumn<String>(
    'cycle_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES commitment_cycles (id)',
    ),
  );
  static const VerificationMeta _scheduleDefinitionIdMeta =
      const VerificationMeta('scheduleDefinitionId');
  @override
  late final GeneratedColumn<String> scheduleDefinitionId =
      GeneratedColumn<String>(
        'schedule_definition_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES schedule_definitions (id)',
        ),
      );
  static const VerificationMeta _occurrenceKeyMeta = const VerificationMeta(
    'occurrenceKey',
  );
  @override
  late final GeneratedColumn<String> occurrenceKey = GeneratedColumn<String>(
    'occurrence_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timeSemanticsMeta = const VerificationMeta(
    'timeSemantics',
  );
  @override
  late final GeneratedColumn<int> timeSemantics = GeneratedColumn<int>(
    'time_semantics',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originalScheduledValueMeta =
      const VerificationMeta('originalScheduledValue');
  @override
  late final GeneratedColumn<String> originalScheduledValue =
      GeneratedColumn<String>(
        'original_scheduled_value',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _currentScheduledValueMeta =
      const VerificationMeta('currentScheduledValue');
  @override
  late final GeneratedColumn<String> currentScheduledValue =
      GeneratedColumn<String>(
        'current_scheduled_value',
        aliasedName,
        false,
        type: DriftSqlType.string,
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
  static const VerificationMeta _isManualOverrideMeta = const VerificationMeta(
    'isManualOverride',
  );
  @override
  late final GeneratedColumn<bool> isManualOverride = GeneratedColumn<bool>(
    'is_manual_override',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_manual_override" IN (0, 1))',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    cycleId,
    scheduleDefinitionId,
    occurrenceKey,
    timeSemantics,
    originalScheduledValue,
    currentScheduledValue,
    status,
    isManualOverride,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'occurrences';
  @override
  VerificationContext validateIntegrity(
    Insertable<Occurrence> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('cycle_id')) {
      context.handle(
        _cycleIdMeta,
        cycleId.isAcceptableOrUnknown(data['cycle_id']!, _cycleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cycleIdMeta);
    }
    if (data.containsKey('schedule_definition_id')) {
      context.handle(
        _scheduleDefinitionIdMeta,
        scheduleDefinitionId.isAcceptableOrUnknown(
          data['schedule_definition_id']!,
          _scheduleDefinitionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_scheduleDefinitionIdMeta);
    }
    if (data.containsKey('occurrence_key')) {
      context.handle(
        _occurrenceKeyMeta,
        occurrenceKey.isAcceptableOrUnknown(
          data['occurrence_key']!,
          _occurrenceKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_occurrenceKeyMeta);
    }
    if (data.containsKey('time_semantics')) {
      context.handle(
        _timeSemanticsMeta,
        timeSemantics.isAcceptableOrUnknown(
          data['time_semantics']!,
          _timeSemanticsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_timeSemanticsMeta);
    }
    if (data.containsKey('original_scheduled_value')) {
      context.handle(
        _originalScheduledValueMeta,
        originalScheduledValue.isAcceptableOrUnknown(
          data['original_scheduled_value']!,
          _originalScheduledValueMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originalScheduledValueMeta);
    }
    if (data.containsKey('current_scheduled_value')) {
      context.handle(
        _currentScheduledValueMeta,
        currentScheduledValue.isAcceptableOrUnknown(
          data['current_scheduled_value']!,
          _currentScheduledValueMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_currentScheduledValueMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('is_manual_override')) {
      context.handle(
        _isManualOverrideMeta,
        isManualOverride.isAcceptableOrUnknown(
          data['is_manual_override']!,
          _isManualOverrideMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_isManualOverrideMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {scheduleDefinitionId, occurrenceKey},
  ];
  @override
  Occurrence map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Occurrence(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      cycleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cycle_id'],
      )!,
      scheduleDefinitionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}schedule_definition_id'],
      )!,
      occurrenceKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}occurrence_key'],
      )!,
      timeSemantics: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}time_semantics'],
      )!,
      originalScheduledValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_scheduled_value'],
      )!,
      currentScheduledValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}current_scheduled_value'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}status'],
      )!,
      isManualOverride: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_manual_override'],
      )!,
    );
  }

  @override
  $OccurrencesTable createAlias(String alias) {
    return $OccurrencesTable(attachedDatabase, alias);
  }
}

class Occurrence extends DataClass implements Insertable<Occurrence> {
  final String id;
  final String cycleId;
  final String scheduleDefinitionId;
  final String occurrenceKey;
  final int timeSemantics;
  final String originalScheduledValue;
  final String currentScheduledValue;
  final int status;
  final bool isManualOverride;
  const Occurrence({
    required this.id,
    required this.cycleId,
    required this.scheduleDefinitionId,
    required this.occurrenceKey,
    required this.timeSemantics,
    required this.originalScheduledValue,
    required this.currentScheduledValue,
    required this.status,
    required this.isManualOverride,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['cycle_id'] = Variable<String>(cycleId);
    map['schedule_definition_id'] = Variable<String>(scheduleDefinitionId);
    map['occurrence_key'] = Variable<String>(occurrenceKey);
    map['time_semantics'] = Variable<int>(timeSemantics);
    map['original_scheduled_value'] = Variable<String>(originalScheduledValue);
    map['current_scheduled_value'] = Variable<String>(currentScheduledValue);
    map['status'] = Variable<int>(status);
    map['is_manual_override'] = Variable<bool>(isManualOverride);
    return map;
  }

  OccurrencesCompanion toCompanion(bool nullToAbsent) {
    return OccurrencesCompanion(
      id: Value(id),
      cycleId: Value(cycleId),
      scheduleDefinitionId: Value(scheduleDefinitionId),
      occurrenceKey: Value(occurrenceKey),
      timeSemantics: Value(timeSemantics),
      originalScheduledValue: Value(originalScheduledValue),
      currentScheduledValue: Value(currentScheduledValue),
      status: Value(status),
      isManualOverride: Value(isManualOverride),
    );
  }

  factory Occurrence.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Occurrence(
      id: serializer.fromJson<String>(json['id']),
      cycleId: serializer.fromJson<String>(json['cycleId']),
      scheduleDefinitionId: serializer.fromJson<String>(
        json['scheduleDefinitionId'],
      ),
      occurrenceKey: serializer.fromJson<String>(json['occurrenceKey']),
      timeSemantics: serializer.fromJson<int>(json['timeSemantics']),
      originalScheduledValue: serializer.fromJson<String>(
        json['originalScheduledValue'],
      ),
      currentScheduledValue: serializer.fromJson<String>(
        json['currentScheduledValue'],
      ),
      status: serializer.fromJson<int>(json['status']),
      isManualOverride: serializer.fromJson<bool>(json['isManualOverride']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'cycleId': serializer.toJson<String>(cycleId),
      'scheduleDefinitionId': serializer.toJson<String>(scheduleDefinitionId),
      'occurrenceKey': serializer.toJson<String>(occurrenceKey),
      'timeSemantics': serializer.toJson<int>(timeSemantics),
      'originalScheduledValue': serializer.toJson<String>(
        originalScheduledValue,
      ),
      'currentScheduledValue': serializer.toJson<String>(currentScheduledValue),
      'status': serializer.toJson<int>(status),
      'isManualOverride': serializer.toJson<bool>(isManualOverride),
    };
  }

  Occurrence copyWith({
    String? id,
    String? cycleId,
    String? scheduleDefinitionId,
    String? occurrenceKey,
    int? timeSemantics,
    String? originalScheduledValue,
    String? currentScheduledValue,
    int? status,
    bool? isManualOverride,
  }) => Occurrence(
    id: id ?? this.id,
    cycleId: cycleId ?? this.cycleId,
    scheduleDefinitionId: scheduleDefinitionId ?? this.scheduleDefinitionId,
    occurrenceKey: occurrenceKey ?? this.occurrenceKey,
    timeSemantics: timeSemantics ?? this.timeSemantics,
    originalScheduledValue:
        originalScheduledValue ?? this.originalScheduledValue,
    currentScheduledValue: currentScheduledValue ?? this.currentScheduledValue,
    status: status ?? this.status,
    isManualOverride: isManualOverride ?? this.isManualOverride,
  );
  Occurrence copyWithCompanion(OccurrencesCompanion data) {
    return Occurrence(
      id: data.id.present ? data.id.value : this.id,
      cycleId: data.cycleId.present ? data.cycleId.value : this.cycleId,
      scheduleDefinitionId: data.scheduleDefinitionId.present
          ? data.scheduleDefinitionId.value
          : this.scheduleDefinitionId,
      occurrenceKey: data.occurrenceKey.present
          ? data.occurrenceKey.value
          : this.occurrenceKey,
      timeSemantics: data.timeSemantics.present
          ? data.timeSemantics.value
          : this.timeSemantics,
      originalScheduledValue: data.originalScheduledValue.present
          ? data.originalScheduledValue.value
          : this.originalScheduledValue,
      currentScheduledValue: data.currentScheduledValue.present
          ? data.currentScheduledValue.value
          : this.currentScheduledValue,
      status: data.status.present ? data.status.value : this.status,
      isManualOverride: data.isManualOverride.present
          ? data.isManualOverride.value
          : this.isManualOverride,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Occurrence(')
          ..write('id: $id, ')
          ..write('cycleId: $cycleId, ')
          ..write('scheduleDefinitionId: $scheduleDefinitionId, ')
          ..write('occurrenceKey: $occurrenceKey, ')
          ..write('timeSemantics: $timeSemantics, ')
          ..write('originalScheduledValue: $originalScheduledValue, ')
          ..write('currentScheduledValue: $currentScheduledValue, ')
          ..write('status: $status, ')
          ..write('isManualOverride: $isManualOverride')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    cycleId,
    scheduleDefinitionId,
    occurrenceKey,
    timeSemantics,
    originalScheduledValue,
    currentScheduledValue,
    status,
    isManualOverride,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Occurrence &&
          other.id == this.id &&
          other.cycleId == this.cycleId &&
          other.scheduleDefinitionId == this.scheduleDefinitionId &&
          other.occurrenceKey == this.occurrenceKey &&
          other.timeSemantics == this.timeSemantics &&
          other.originalScheduledValue == this.originalScheduledValue &&
          other.currentScheduledValue == this.currentScheduledValue &&
          other.status == this.status &&
          other.isManualOverride == this.isManualOverride);
}

class OccurrencesCompanion extends UpdateCompanion<Occurrence> {
  final Value<String> id;
  final Value<String> cycleId;
  final Value<String> scheduleDefinitionId;
  final Value<String> occurrenceKey;
  final Value<int> timeSemantics;
  final Value<String> originalScheduledValue;
  final Value<String> currentScheduledValue;
  final Value<int> status;
  final Value<bool> isManualOverride;
  final Value<int> rowid;
  const OccurrencesCompanion({
    this.id = const Value.absent(),
    this.cycleId = const Value.absent(),
    this.scheduleDefinitionId = const Value.absent(),
    this.occurrenceKey = const Value.absent(),
    this.timeSemantics = const Value.absent(),
    this.originalScheduledValue = const Value.absent(),
    this.currentScheduledValue = const Value.absent(),
    this.status = const Value.absent(),
    this.isManualOverride = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OccurrencesCompanion.insert({
    required String id,
    required String cycleId,
    required String scheduleDefinitionId,
    required String occurrenceKey,
    required int timeSemantics,
    required String originalScheduledValue,
    required String currentScheduledValue,
    required int status,
    required bool isManualOverride,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       cycleId = Value(cycleId),
       scheduleDefinitionId = Value(scheduleDefinitionId),
       occurrenceKey = Value(occurrenceKey),
       timeSemantics = Value(timeSemantics),
       originalScheduledValue = Value(originalScheduledValue),
       currentScheduledValue = Value(currentScheduledValue),
       status = Value(status),
       isManualOverride = Value(isManualOverride);
  static Insertable<Occurrence> custom({
    Expression<String>? id,
    Expression<String>? cycleId,
    Expression<String>? scheduleDefinitionId,
    Expression<String>? occurrenceKey,
    Expression<int>? timeSemantics,
    Expression<String>? originalScheduledValue,
    Expression<String>? currentScheduledValue,
    Expression<int>? status,
    Expression<bool>? isManualOverride,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (cycleId != null) 'cycle_id': cycleId,
      if (scheduleDefinitionId != null)
        'schedule_definition_id': scheduleDefinitionId,
      if (occurrenceKey != null) 'occurrence_key': occurrenceKey,
      if (timeSemantics != null) 'time_semantics': timeSemantics,
      if (originalScheduledValue != null)
        'original_scheduled_value': originalScheduledValue,
      if (currentScheduledValue != null)
        'current_scheduled_value': currentScheduledValue,
      if (status != null) 'status': status,
      if (isManualOverride != null) 'is_manual_override': isManualOverride,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OccurrencesCompanion copyWith({
    Value<String>? id,
    Value<String>? cycleId,
    Value<String>? scheduleDefinitionId,
    Value<String>? occurrenceKey,
    Value<int>? timeSemantics,
    Value<String>? originalScheduledValue,
    Value<String>? currentScheduledValue,
    Value<int>? status,
    Value<bool>? isManualOverride,
    Value<int>? rowid,
  }) {
    return OccurrencesCompanion(
      id: id ?? this.id,
      cycleId: cycleId ?? this.cycleId,
      scheduleDefinitionId: scheduleDefinitionId ?? this.scheduleDefinitionId,
      occurrenceKey: occurrenceKey ?? this.occurrenceKey,
      timeSemantics: timeSemantics ?? this.timeSemantics,
      originalScheduledValue:
          originalScheduledValue ?? this.originalScheduledValue,
      currentScheduledValue:
          currentScheduledValue ?? this.currentScheduledValue,
      status: status ?? this.status,
      isManualOverride: isManualOverride ?? this.isManualOverride,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (cycleId.present) {
      map['cycle_id'] = Variable<String>(cycleId.value);
    }
    if (scheduleDefinitionId.present) {
      map['schedule_definition_id'] = Variable<String>(
        scheduleDefinitionId.value,
      );
    }
    if (occurrenceKey.present) {
      map['occurrence_key'] = Variable<String>(occurrenceKey.value);
    }
    if (timeSemantics.present) {
      map['time_semantics'] = Variable<int>(timeSemantics.value);
    }
    if (originalScheduledValue.present) {
      map['original_scheduled_value'] = Variable<String>(
        originalScheduledValue.value,
      );
    }
    if (currentScheduledValue.present) {
      map['current_scheduled_value'] = Variable<String>(
        currentScheduledValue.value,
      );
    }
    if (status.present) {
      map['status'] = Variable<int>(status.value);
    }
    if (isManualOverride.present) {
      map['is_manual_override'] = Variable<bool>(isManualOverride.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OccurrencesCompanion(')
          ..write('id: $id, ')
          ..write('cycleId: $cycleId, ')
          ..write('scheduleDefinitionId: $scheduleDefinitionId, ')
          ..write('occurrenceKey: $occurrenceKey, ')
          ..write('timeSemantics: $timeSemantics, ')
          ..write('originalScheduledValue: $originalScheduledValue, ')
          ..write('currentScheduledValue: $currentScheduledValue, ')
          ..write('status: $status, ')
          ..write('isManualOverride: $isManualOverride, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EntitlementPlansTable extends EntitlementPlans
    with TableInfo<$EntitlementPlansTable, EntitlementPlan> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EntitlementPlansTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cycleIdMeta = const VerificationMeta(
    'cycleId',
  );
  @override
  late final GeneratedColumn<String> cycleId = GeneratedColumn<String>(
    'cycle_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES commitment_cycles (id)',
    ),
  );
  static const VerificationMeta _totalUnitsMeta = const VerificationMeta(
    'totalUnits',
  );
  @override
  late final GeneratedColumn<int> totalUnits = GeneratedColumn<int>(
    'total_units',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitTypeMeta = const VerificationMeta(
    'unitType',
  );
  @override
  late final GeneratedColumn<int> unitType = GeneratedColumn<int>(
    'unit_type',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _validFromMeta = const VerificationMeta(
    'validFrom',
  );
  @override
  late final GeneratedColumn<DateTime> validFrom = GeneratedColumn<DateTime>(
    'valid_from',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _plannedExpiryMeta = const VerificationMeta(
    'plannedExpiry',
  );
  @override
  late final GeneratedColumn<DateTime> plannedExpiry =
      GeneratedColumn<DateTime>(
        'planned_expiry',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _autoExtendMeta = const VerificationMeta(
    'autoExtend',
  );
  @override
  late final GeneratedColumn<bool> autoExtend = GeneratedColumn<bool>(
    'auto_extend',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("auto_extend" IN (0, 1))',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    cycleId,
    totalUnits,
    unitType,
    validFrom,
    plannedExpiry,
    autoExtend,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'entitlement_plans';
  @override
  VerificationContext validateIntegrity(
    Insertable<EntitlementPlan> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('cycle_id')) {
      context.handle(
        _cycleIdMeta,
        cycleId.isAcceptableOrUnknown(data['cycle_id']!, _cycleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cycleIdMeta);
    }
    if (data.containsKey('total_units')) {
      context.handle(
        _totalUnitsMeta,
        totalUnits.isAcceptableOrUnknown(data['total_units']!, _totalUnitsMeta),
      );
    } else if (isInserting) {
      context.missing(_totalUnitsMeta);
    }
    if (data.containsKey('unit_type')) {
      context.handle(
        _unitTypeMeta,
        unitType.isAcceptableOrUnknown(data['unit_type']!, _unitTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_unitTypeMeta);
    }
    if (data.containsKey('valid_from')) {
      context.handle(
        _validFromMeta,
        validFrom.isAcceptableOrUnknown(data['valid_from']!, _validFromMeta),
      );
    } else if (isInserting) {
      context.missing(_validFromMeta);
    }
    if (data.containsKey('planned_expiry')) {
      context.handle(
        _plannedExpiryMeta,
        plannedExpiry.isAcceptableOrUnknown(
          data['planned_expiry']!,
          _plannedExpiryMeta,
        ),
      );
    }
    if (data.containsKey('auto_extend')) {
      context.handle(
        _autoExtendMeta,
        autoExtend.isAcceptableOrUnknown(data['auto_extend']!, _autoExtendMeta),
      );
    } else if (isInserting) {
      context.missing(_autoExtendMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EntitlementPlan map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EntitlementPlan(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      cycleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cycle_id'],
      )!,
      totalUnits: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_units'],
      )!,
      unitType: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}unit_type'],
      )!,
      validFrom: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}valid_from'],
      )!,
      plannedExpiry: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}planned_expiry'],
      ),
      autoExtend: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}auto_extend'],
      )!,
    );
  }

  @override
  $EntitlementPlansTable createAlias(String alias) {
    return $EntitlementPlansTable(attachedDatabase, alias);
  }
}

class EntitlementPlan extends DataClass implements Insertable<EntitlementPlan> {
  final String id;
  final String cycleId;
  final int totalUnits;
  final int unitType;
  final DateTime validFrom;
  final DateTime? plannedExpiry;
  final bool autoExtend;
  const EntitlementPlan({
    required this.id,
    required this.cycleId,
    required this.totalUnits,
    required this.unitType,
    required this.validFrom,
    this.plannedExpiry,
    required this.autoExtend,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['cycle_id'] = Variable<String>(cycleId);
    map['total_units'] = Variable<int>(totalUnits);
    map['unit_type'] = Variable<int>(unitType);
    map['valid_from'] = Variable<DateTime>(validFrom);
    if (!nullToAbsent || plannedExpiry != null) {
      map['planned_expiry'] = Variable<DateTime>(plannedExpiry);
    }
    map['auto_extend'] = Variable<bool>(autoExtend);
    return map;
  }

  EntitlementPlansCompanion toCompanion(bool nullToAbsent) {
    return EntitlementPlansCompanion(
      id: Value(id),
      cycleId: Value(cycleId),
      totalUnits: Value(totalUnits),
      unitType: Value(unitType),
      validFrom: Value(validFrom),
      plannedExpiry: plannedExpiry == null && nullToAbsent
          ? const Value.absent()
          : Value(plannedExpiry),
      autoExtend: Value(autoExtend),
    );
  }

  factory EntitlementPlan.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EntitlementPlan(
      id: serializer.fromJson<String>(json['id']),
      cycleId: serializer.fromJson<String>(json['cycleId']),
      totalUnits: serializer.fromJson<int>(json['totalUnits']),
      unitType: serializer.fromJson<int>(json['unitType']),
      validFrom: serializer.fromJson<DateTime>(json['validFrom']),
      plannedExpiry: serializer.fromJson<DateTime?>(json['plannedExpiry']),
      autoExtend: serializer.fromJson<bool>(json['autoExtend']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'cycleId': serializer.toJson<String>(cycleId),
      'totalUnits': serializer.toJson<int>(totalUnits),
      'unitType': serializer.toJson<int>(unitType),
      'validFrom': serializer.toJson<DateTime>(validFrom),
      'plannedExpiry': serializer.toJson<DateTime?>(plannedExpiry),
      'autoExtend': serializer.toJson<bool>(autoExtend),
    };
  }

  EntitlementPlan copyWith({
    String? id,
    String? cycleId,
    int? totalUnits,
    int? unitType,
    DateTime? validFrom,
    Value<DateTime?> plannedExpiry = const Value.absent(),
    bool? autoExtend,
  }) => EntitlementPlan(
    id: id ?? this.id,
    cycleId: cycleId ?? this.cycleId,
    totalUnits: totalUnits ?? this.totalUnits,
    unitType: unitType ?? this.unitType,
    validFrom: validFrom ?? this.validFrom,
    plannedExpiry: plannedExpiry.present
        ? plannedExpiry.value
        : this.plannedExpiry,
    autoExtend: autoExtend ?? this.autoExtend,
  );
  EntitlementPlan copyWithCompanion(EntitlementPlansCompanion data) {
    return EntitlementPlan(
      id: data.id.present ? data.id.value : this.id,
      cycleId: data.cycleId.present ? data.cycleId.value : this.cycleId,
      totalUnits: data.totalUnits.present
          ? data.totalUnits.value
          : this.totalUnits,
      unitType: data.unitType.present ? data.unitType.value : this.unitType,
      validFrom: data.validFrom.present ? data.validFrom.value : this.validFrom,
      plannedExpiry: data.plannedExpiry.present
          ? data.plannedExpiry.value
          : this.plannedExpiry,
      autoExtend: data.autoExtend.present
          ? data.autoExtend.value
          : this.autoExtend,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EntitlementPlan(')
          ..write('id: $id, ')
          ..write('cycleId: $cycleId, ')
          ..write('totalUnits: $totalUnits, ')
          ..write('unitType: $unitType, ')
          ..write('validFrom: $validFrom, ')
          ..write('plannedExpiry: $plannedExpiry, ')
          ..write('autoExtend: $autoExtend')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    cycleId,
    totalUnits,
    unitType,
    validFrom,
    plannedExpiry,
    autoExtend,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EntitlementPlan &&
          other.id == this.id &&
          other.cycleId == this.cycleId &&
          other.totalUnits == this.totalUnits &&
          other.unitType == this.unitType &&
          other.validFrom == this.validFrom &&
          other.plannedExpiry == this.plannedExpiry &&
          other.autoExtend == this.autoExtend);
}

class EntitlementPlansCompanion extends UpdateCompanion<EntitlementPlan> {
  final Value<String> id;
  final Value<String> cycleId;
  final Value<int> totalUnits;
  final Value<int> unitType;
  final Value<DateTime> validFrom;
  final Value<DateTime?> plannedExpiry;
  final Value<bool> autoExtend;
  final Value<int> rowid;
  const EntitlementPlansCompanion({
    this.id = const Value.absent(),
    this.cycleId = const Value.absent(),
    this.totalUnits = const Value.absent(),
    this.unitType = const Value.absent(),
    this.validFrom = const Value.absent(),
    this.plannedExpiry = const Value.absent(),
    this.autoExtend = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EntitlementPlansCompanion.insert({
    required String id,
    required String cycleId,
    required int totalUnits,
    required int unitType,
    required DateTime validFrom,
    this.plannedExpiry = const Value.absent(),
    required bool autoExtend,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       cycleId = Value(cycleId),
       totalUnits = Value(totalUnits),
       unitType = Value(unitType),
       validFrom = Value(validFrom),
       autoExtend = Value(autoExtend);
  static Insertable<EntitlementPlan> custom({
    Expression<String>? id,
    Expression<String>? cycleId,
    Expression<int>? totalUnits,
    Expression<int>? unitType,
    Expression<DateTime>? validFrom,
    Expression<DateTime>? plannedExpiry,
    Expression<bool>? autoExtend,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (cycleId != null) 'cycle_id': cycleId,
      if (totalUnits != null) 'total_units': totalUnits,
      if (unitType != null) 'unit_type': unitType,
      if (validFrom != null) 'valid_from': validFrom,
      if (plannedExpiry != null) 'planned_expiry': plannedExpiry,
      if (autoExtend != null) 'auto_extend': autoExtend,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EntitlementPlansCompanion copyWith({
    Value<String>? id,
    Value<String>? cycleId,
    Value<int>? totalUnits,
    Value<int>? unitType,
    Value<DateTime>? validFrom,
    Value<DateTime?>? plannedExpiry,
    Value<bool>? autoExtend,
    Value<int>? rowid,
  }) {
    return EntitlementPlansCompanion(
      id: id ?? this.id,
      cycleId: cycleId ?? this.cycleId,
      totalUnits: totalUnits ?? this.totalUnits,
      unitType: unitType ?? this.unitType,
      validFrom: validFrom ?? this.validFrom,
      plannedExpiry: plannedExpiry ?? this.plannedExpiry,
      autoExtend: autoExtend ?? this.autoExtend,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (cycleId.present) {
      map['cycle_id'] = Variable<String>(cycleId.value);
    }
    if (totalUnits.present) {
      map['total_units'] = Variable<int>(totalUnits.value);
    }
    if (unitType.present) {
      map['unit_type'] = Variable<int>(unitType.value);
    }
    if (validFrom.present) {
      map['valid_from'] = Variable<DateTime>(validFrom.value);
    }
    if (plannedExpiry.present) {
      map['planned_expiry'] = Variable<DateTime>(plannedExpiry.value);
    }
    if (autoExtend.present) {
      map['auto_extend'] = Variable<bool>(autoExtend.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EntitlementPlansCompanion(')
          ..write('id: $id, ')
          ..write('cycleId: $cycleId, ')
          ..write('totalUnits: $totalUnits, ')
          ..write('unitType: $unitType, ')
          ..write('validFrom: $validFrom, ')
          ..write('plannedExpiry: $plannedExpiry, ')
          ..write('autoExtend: $autoExtend, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EntitlementLedgerEntriesTable extends EntitlementLedgerEntries
    with TableInfo<$EntitlementLedgerEntriesTable, EntitlementLedgerEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EntitlementLedgerEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _planIdMeta = const VerificationMeta('planId');
  @override
  late final GeneratedColumn<String> planId = GeneratedColumn<String>(
    'plan_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES entitlement_plans (id)',
    ),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<int> type = GeneratedColumn<int>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitsMeta = const VerificationMeta('units');
  @override
  late final GeneratedColumn<int> units = GeneratedColumn<int>(
    'units',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _occurredAtMeta = const VerificationMeta(
    'occurredAt',
  );
  @override
  late final GeneratedColumn<DateTime> occurredAt = GeneratedColumn<DateTime>(
    'occurred_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _referenceIdMeta = const VerificationMeta(
    'referenceId',
  );
  @override
  late final GeneratedColumn<String> referenceId = GeneratedColumn<String>(
    'reference_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    planId,
    type,
    units,
    occurredAt,
    referenceId,
    note,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'entitlement_ledger_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<EntitlementLedgerEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('plan_id')) {
      context.handle(
        _planIdMeta,
        planId.isAcceptableOrUnknown(data['plan_id']!, _planIdMeta),
      );
    } else if (isInserting) {
      context.missing(_planIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('units')) {
      context.handle(
        _unitsMeta,
        units.isAcceptableOrUnknown(data['units']!, _unitsMeta),
      );
    } else if (isInserting) {
      context.missing(_unitsMeta);
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
        _occurredAtMeta,
        occurredAt.isAcceptableOrUnknown(data['occurred_at']!, _occurredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    if (data.containsKey('reference_id')) {
      context.handle(
        _referenceIdMeta,
        referenceId.isAcceptableOrUnknown(
          data['reference_id']!,
          _referenceIdMeta,
        ),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EntitlementLedgerEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EntitlementLedgerEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      planId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plan_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}type'],
      )!,
      units: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}units'],
      )!,
      occurredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}occurred_at'],
      )!,
      referenceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reference_id'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
    );
  }

  @override
  $EntitlementLedgerEntriesTable createAlias(String alias) {
    return $EntitlementLedgerEntriesTable(attachedDatabase, alias);
  }
}

class EntitlementLedgerEntry extends DataClass
    implements Insertable<EntitlementLedgerEntry> {
  final String id;
  final String planId;
  final int type;
  final int units;
  final DateTime occurredAt;
  final String? referenceId;
  final String? note;
  const EntitlementLedgerEntry({
    required this.id,
    required this.planId,
    required this.type,
    required this.units,
    required this.occurredAt,
    this.referenceId,
    this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['plan_id'] = Variable<String>(planId);
    map['type'] = Variable<int>(type);
    map['units'] = Variable<int>(units);
    map['occurred_at'] = Variable<DateTime>(occurredAt);
    if (!nullToAbsent || referenceId != null) {
      map['reference_id'] = Variable<String>(referenceId);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  EntitlementLedgerEntriesCompanion toCompanion(bool nullToAbsent) {
    return EntitlementLedgerEntriesCompanion(
      id: Value(id),
      planId: Value(planId),
      type: Value(type),
      units: Value(units),
      occurredAt: Value(occurredAt),
      referenceId: referenceId == null && nullToAbsent
          ? const Value.absent()
          : Value(referenceId),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory EntitlementLedgerEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EntitlementLedgerEntry(
      id: serializer.fromJson<String>(json['id']),
      planId: serializer.fromJson<String>(json['planId']),
      type: serializer.fromJson<int>(json['type']),
      units: serializer.fromJson<int>(json['units']),
      occurredAt: serializer.fromJson<DateTime>(json['occurredAt']),
      referenceId: serializer.fromJson<String?>(json['referenceId']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'planId': serializer.toJson<String>(planId),
      'type': serializer.toJson<int>(type),
      'units': serializer.toJson<int>(units),
      'occurredAt': serializer.toJson<DateTime>(occurredAt),
      'referenceId': serializer.toJson<String?>(referenceId),
      'note': serializer.toJson<String?>(note),
    };
  }

  EntitlementLedgerEntry copyWith({
    String? id,
    String? planId,
    int? type,
    int? units,
    DateTime? occurredAt,
    Value<String?> referenceId = const Value.absent(),
    Value<String?> note = const Value.absent(),
  }) => EntitlementLedgerEntry(
    id: id ?? this.id,
    planId: planId ?? this.planId,
    type: type ?? this.type,
    units: units ?? this.units,
    occurredAt: occurredAt ?? this.occurredAt,
    referenceId: referenceId.present ? referenceId.value : this.referenceId,
    note: note.present ? note.value : this.note,
  );
  EntitlementLedgerEntry copyWithCompanion(
    EntitlementLedgerEntriesCompanion data,
  ) {
    return EntitlementLedgerEntry(
      id: data.id.present ? data.id.value : this.id,
      planId: data.planId.present ? data.planId.value : this.planId,
      type: data.type.present ? data.type.value : this.type,
      units: data.units.present ? data.units.value : this.units,
      occurredAt: data.occurredAt.present
          ? data.occurredAt.value
          : this.occurredAt,
      referenceId: data.referenceId.present
          ? data.referenceId.value
          : this.referenceId,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EntitlementLedgerEntry(')
          ..write('id: $id, ')
          ..write('planId: $planId, ')
          ..write('type: $type, ')
          ..write('units: $units, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('referenceId: $referenceId, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, planId, type, units, occurredAt, referenceId, note);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EntitlementLedgerEntry &&
          other.id == this.id &&
          other.planId == this.planId &&
          other.type == this.type &&
          other.units == this.units &&
          other.occurredAt == this.occurredAt &&
          other.referenceId == this.referenceId &&
          other.note == this.note);
}

class EntitlementLedgerEntriesCompanion
    extends UpdateCompanion<EntitlementLedgerEntry> {
  final Value<String> id;
  final Value<String> planId;
  final Value<int> type;
  final Value<int> units;
  final Value<DateTime> occurredAt;
  final Value<String?> referenceId;
  final Value<String?> note;
  final Value<int> rowid;
  const EntitlementLedgerEntriesCompanion({
    this.id = const Value.absent(),
    this.planId = const Value.absent(),
    this.type = const Value.absent(),
    this.units = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.referenceId = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EntitlementLedgerEntriesCompanion.insert({
    required String id,
    required String planId,
    required int type,
    required int units,
    required DateTime occurredAt,
    this.referenceId = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       planId = Value(planId),
       type = Value(type),
       units = Value(units),
       occurredAt = Value(occurredAt);
  static Insertable<EntitlementLedgerEntry> custom({
    Expression<String>? id,
    Expression<String>? planId,
    Expression<int>? type,
    Expression<int>? units,
    Expression<DateTime>? occurredAt,
    Expression<String>? referenceId,
    Expression<String>? note,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (planId != null) 'plan_id': planId,
      if (type != null) 'type': type,
      if (units != null) 'units': units,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (referenceId != null) 'reference_id': referenceId,
      if (note != null) 'note': note,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EntitlementLedgerEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? planId,
    Value<int>? type,
    Value<int>? units,
    Value<DateTime>? occurredAt,
    Value<String?>? referenceId,
    Value<String?>? note,
    Value<int>? rowid,
  }) {
    return EntitlementLedgerEntriesCompanion(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      type: type ?? this.type,
      units: units ?? this.units,
      occurredAt: occurredAt ?? this.occurredAt,
      referenceId: referenceId ?? this.referenceId,
      note: note ?? this.note,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (planId.present) {
      map['plan_id'] = Variable<String>(planId.value);
    }
    if (type.present) {
      map['type'] = Variable<int>(type.value);
    }
    if (units.present) {
      map['units'] = Variable<int>(units.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<DateTime>(occurredAt.value);
    }
    if (referenceId.present) {
      map['reference_id'] = Variable<String>(referenceId.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EntitlementLedgerEntriesCompanion(')
          ..write('id: $id, ')
          ..write('planId: $planId, ')
          ..write('type: $type, ')
          ..write('units: $units, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('referenceId: $referenceId, ')
          ..write('note: $note, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SessionPoliciesTable extends SessionPolicies
    with TableInfo<$SessionPoliciesTable, SessionPolicy> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionPoliciesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cycleIdMeta = const VerificationMeta(
    'cycleId',
  );
  @override
  late final GeneratedColumn<String> cycleId = GeneratedColumn<String>(
    'cycle_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES commitment_cycles (id)',
    ),
  );
  static const VerificationMeta _providerCancellationConsumesMeta =
      const VerificationMeta('providerCancellationConsumes');
  @override
  late final GeneratedColumn<bool> providerCancellationConsumes =
      GeneratedColumn<bool>(
        'provider_cancellation_consumes',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: true,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("provider_cancellation_consumes" IN (0, 1))',
        ),
      );
  static const VerificationMeta _userCancellationNoticeHoursMeta =
      const VerificationMeta('userCancellationNoticeHours');
  @override
  late final GeneratedColumn<int> userCancellationNoticeHours =
      GeneratedColumn<int>(
        'user_cancellation_notice_hours',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _lateCancellationConsumesMeta =
      const VerificationMeta('lateCancellationConsumes');
  @override
  late final GeneratedColumn<bool> lateCancellationConsumes =
      GeneratedColumn<bool>(
        'late_cancellation_consumes',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: true,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("late_cancellation_consumes" IN (0, 1))',
        ),
      );
  static const VerificationMeta _noShowConsumesMeta = const VerificationMeta(
    'noShowConsumes',
  );
  @override
  late final GeneratedColumn<bool> noShowConsumes = GeneratedColumn<bool>(
    'no_show_consumes',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("no_show_consumes" IN (0, 1))',
    ),
  );
  static const VerificationMeta _freeAbsenceQuotaMeta = const VerificationMeta(
    'freeAbsenceQuota',
  );
  @override
  late final GeneratedColumn<int> freeAbsenceQuota = GeneratedColumn<int>(
    'free_absence_quota',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _holidayConsumesMeta = const VerificationMeta(
    'holidayConsumes',
  );
  @override
  late final GeneratedColumn<bool> holidayConsumes = GeneratedColumn<bool>(
    'holiday_consumes',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("holiday_consumes" IN (0, 1))',
    ),
  );
  static const VerificationMeta _makeupRequiredMeta = const VerificationMeta(
    'makeupRequired',
  );
  @override
  late final GeneratedColumn<bool> makeupRequired = GeneratedColumn<bool>(
    'makeup_required',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("makeup_required" IN (0, 1))',
    ),
  );
  static const VerificationMeta _autoExtendUntilUnitsConsumedMeta =
      const VerificationMeta('autoExtendUntilUnitsConsumed');
  @override
  late final GeneratedColumn<bool> autoExtendUntilUnitsConsumed =
      GeneratedColumn<bool>(
        'auto_extend_until_units_consumed',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: true,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("auto_extend_until_units_consumed" IN (0, 1))',
        ),
      );
  static const VerificationMeta _maxExtensionDateMeta = const VerificationMeta(
    'maxExtensionDate',
  );
  @override
  late final GeneratedColumn<DateTime> maxExtensionDate =
      GeneratedColumn<DateTime>(
        'max_extension_date',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _partialUnitAllowedMeta =
      const VerificationMeta('partialUnitAllowed');
  @override
  late final GeneratedColumn<bool> partialUnitAllowed = GeneratedColumn<bool>(
    'partial_unit_allowed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("partial_unit_allowed" IN (0, 1))',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    cycleId,
    providerCancellationConsumes,
    userCancellationNoticeHours,
    lateCancellationConsumes,
    noShowConsumes,
    freeAbsenceQuota,
    holidayConsumes,
    makeupRequired,
    autoExtendUntilUnitsConsumed,
    maxExtensionDate,
    partialUnitAllowed,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'session_policies';
  @override
  VerificationContext validateIntegrity(
    Insertable<SessionPolicy> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('cycle_id')) {
      context.handle(
        _cycleIdMeta,
        cycleId.isAcceptableOrUnknown(data['cycle_id']!, _cycleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cycleIdMeta);
    }
    if (data.containsKey('provider_cancellation_consumes')) {
      context.handle(
        _providerCancellationConsumesMeta,
        providerCancellationConsumes.isAcceptableOrUnknown(
          data['provider_cancellation_consumes']!,
          _providerCancellationConsumesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_providerCancellationConsumesMeta);
    }
    if (data.containsKey('user_cancellation_notice_hours')) {
      context.handle(
        _userCancellationNoticeHoursMeta,
        userCancellationNoticeHours.isAcceptableOrUnknown(
          data['user_cancellation_notice_hours']!,
          _userCancellationNoticeHoursMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_userCancellationNoticeHoursMeta);
    }
    if (data.containsKey('late_cancellation_consumes')) {
      context.handle(
        _lateCancellationConsumesMeta,
        lateCancellationConsumes.isAcceptableOrUnknown(
          data['late_cancellation_consumes']!,
          _lateCancellationConsumesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lateCancellationConsumesMeta);
    }
    if (data.containsKey('no_show_consumes')) {
      context.handle(
        _noShowConsumesMeta,
        noShowConsumes.isAcceptableOrUnknown(
          data['no_show_consumes']!,
          _noShowConsumesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_noShowConsumesMeta);
    }
    if (data.containsKey('free_absence_quota')) {
      context.handle(
        _freeAbsenceQuotaMeta,
        freeAbsenceQuota.isAcceptableOrUnknown(
          data['free_absence_quota']!,
          _freeAbsenceQuotaMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_freeAbsenceQuotaMeta);
    }
    if (data.containsKey('holiday_consumes')) {
      context.handle(
        _holidayConsumesMeta,
        holidayConsumes.isAcceptableOrUnknown(
          data['holiday_consumes']!,
          _holidayConsumesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_holidayConsumesMeta);
    }
    if (data.containsKey('makeup_required')) {
      context.handle(
        _makeupRequiredMeta,
        makeupRequired.isAcceptableOrUnknown(
          data['makeup_required']!,
          _makeupRequiredMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_makeupRequiredMeta);
    }
    if (data.containsKey('auto_extend_until_units_consumed')) {
      context.handle(
        _autoExtendUntilUnitsConsumedMeta,
        autoExtendUntilUnitsConsumed.isAcceptableOrUnknown(
          data['auto_extend_until_units_consumed']!,
          _autoExtendUntilUnitsConsumedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_autoExtendUntilUnitsConsumedMeta);
    }
    if (data.containsKey('max_extension_date')) {
      context.handle(
        _maxExtensionDateMeta,
        maxExtensionDate.isAcceptableOrUnknown(
          data['max_extension_date']!,
          _maxExtensionDateMeta,
        ),
      );
    }
    if (data.containsKey('partial_unit_allowed')) {
      context.handle(
        _partialUnitAllowedMeta,
        partialUnitAllowed.isAcceptableOrUnknown(
          data['partial_unit_allowed']!,
          _partialUnitAllowedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_partialUnitAllowedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SessionPolicy map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SessionPolicy(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      cycleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cycle_id'],
      )!,
      providerCancellationConsumes: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}provider_cancellation_consumes'],
      )!,
      userCancellationNoticeHours: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}user_cancellation_notice_hours'],
      )!,
      lateCancellationConsumes: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}late_cancellation_consumes'],
      )!,
      noShowConsumes: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}no_show_consumes'],
      )!,
      freeAbsenceQuota: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}free_absence_quota'],
      )!,
      holidayConsumes: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}holiday_consumes'],
      )!,
      makeupRequired: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}makeup_required'],
      )!,
      autoExtendUntilUnitsConsumed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}auto_extend_until_units_consumed'],
      )!,
      maxExtensionDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}max_extension_date'],
      ),
      partialUnitAllowed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}partial_unit_allowed'],
      )!,
    );
  }

  @override
  $SessionPoliciesTable createAlias(String alias) {
    return $SessionPoliciesTable(attachedDatabase, alias);
  }
}

class SessionPolicy extends DataClass implements Insertable<SessionPolicy> {
  final String id;
  final String cycleId;
  final bool providerCancellationConsumes;
  final int userCancellationNoticeHours;
  final bool lateCancellationConsumes;
  final bool noShowConsumes;
  final int freeAbsenceQuota;
  final bool holidayConsumes;
  final bool makeupRequired;
  final bool autoExtendUntilUnitsConsumed;
  final DateTime? maxExtensionDate;
  final bool partialUnitAllowed;
  const SessionPolicy({
    required this.id,
    required this.cycleId,
    required this.providerCancellationConsumes,
    required this.userCancellationNoticeHours,
    required this.lateCancellationConsumes,
    required this.noShowConsumes,
    required this.freeAbsenceQuota,
    required this.holidayConsumes,
    required this.makeupRequired,
    required this.autoExtendUntilUnitsConsumed,
    this.maxExtensionDate,
    required this.partialUnitAllowed,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['cycle_id'] = Variable<String>(cycleId);
    map['provider_cancellation_consumes'] = Variable<bool>(
      providerCancellationConsumes,
    );
    map['user_cancellation_notice_hours'] = Variable<int>(
      userCancellationNoticeHours,
    );
    map['late_cancellation_consumes'] = Variable<bool>(
      lateCancellationConsumes,
    );
    map['no_show_consumes'] = Variable<bool>(noShowConsumes);
    map['free_absence_quota'] = Variable<int>(freeAbsenceQuota);
    map['holiday_consumes'] = Variable<bool>(holidayConsumes);
    map['makeup_required'] = Variable<bool>(makeupRequired);
    map['auto_extend_until_units_consumed'] = Variable<bool>(
      autoExtendUntilUnitsConsumed,
    );
    if (!nullToAbsent || maxExtensionDate != null) {
      map['max_extension_date'] = Variable<DateTime>(maxExtensionDate);
    }
    map['partial_unit_allowed'] = Variable<bool>(partialUnitAllowed);
    return map;
  }

  SessionPoliciesCompanion toCompanion(bool nullToAbsent) {
    return SessionPoliciesCompanion(
      id: Value(id),
      cycleId: Value(cycleId),
      providerCancellationConsumes: Value(providerCancellationConsumes),
      userCancellationNoticeHours: Value(userCancellationNoticeHours),
      lateCancellationConsumes: Value(lateCancellationConsumes),
      noShowConsumes: Value(noShowConsumes),
      freeAbsenceQuota: Value(freeAbsenceQuota),
      holidayConsumes: Value(holidayConsumes),
      makeupRequired: Value(makeupRequired),
      autoExtendUntilUnitsConsumed: Value(autoExtendUntilUnitsConsumed),
      maxExtensionDate: maxExtensionDate == null && nullToAbsent
          ? const Value.absent()
          : Value(maxExtensionDate),
      partialUnitAllowed: Value(partialUnitAllowed),
    );
  }

  factory SessionPolicy.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SessionPolicy(
      id: serializer.fromJson<String>(json['id']),
      cycleId: serializer.fromJson<String>(json['cycleId']),
      providerCancellationConsumes: serializer.fromJson<bool>(
        json['providerCancellationConsumes'],
      ),
      userCancellationNoticeHours: serializer.fromJson<int>(
        json['userCancellationNoticeHours'],
      ),
      lateCancellationConsumes: serializer.fromJson<bool>(
        json['lateCancellationConsumes'],
      ),
      noShowConsumes: serializer.fromJson<bool>(json['noShowConsumes']),
      freeAbsenceQuota: serializer.fromJson<int>(json['freeAbsenceQuota']),
      holidayConsumes: serializer.fromJson<bool>(json['holidayConsumes']),
      makeupRequired: serializer.fromJson<bool>(json['makeupRequired']),
      autoExtendUntilUnitsConsumed: serializer.fromJson<bool>(
        json['autoExtendUntilUnitsConsumed'],
      ),
      maxExtensionDate: serializer.fromJson<DateTime?>(
        json['maxExtensionDate'],
      ),
      partialUnitAllowed: serializer.fromJson<bool>(json['partialUnitAllowed']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'cycleId': serializer.toJson<String>(cycleId),
      'providerCancellationConsumes': serializer.toJson<bool>(
        providerCancellationConsumes,
      ),
      'userCancellationNoticeHours': serializer.toJson<int>(
        userCancellationNoticeHours,
      ),
      'lateCancellationConsumes': serializer.toJson<bool>(
        lateCancellationConsumes,
      ),
      'noShowConsumes': serializer.toJson<bool>(noShowConsumes),
      'freeAbsenceQuota': serializer.toJson<int>(freeAbsenceQuota),
      'holidayConsumes': serializer.toJson<bool>(holidayConsumes),
      'makeupRequired': serializer.toJson<bool>(makeupRequired),
      'autoExtendUntilUnitsConsumed': serializer.toJson<bool>(
        autoExtendUntilUnitsConsumed,
      ),
      'maxExtensionDate': serializer.toJson<DateTime?>(maxExtensionDate),
      'partialUnitAllowed': serializer.toJson<bool>(partialUnitAllowed),
    };
  }

  SessionPolicy copyWith({
    String? id,
    String? cycleId,
    bool? providerCancellationConsumes,
    int? userCancellationNoticeHours,
    bool? lateCancellationConsumes,
    bool? noShowConsumes,
    int? freeAbsenceQuota,
    bool? holidayConsumes,
    bool? makeupRequired,
    bool? autoExtendUntilUnitsConsumed,
    Value<DateTime?> maxExtensionDate = const Value.absent(),
    bool? partialUnitAllowed,
  }) => SessionPolicy(
    id: id ?? this.id,
    cycleId: cycleId ?? this.cycleId,
    providerCancellationConsumes:
        providerCancellationConsumes ?? this.providerCancellationConsumes,
    userCancellationNoticeHours:
        userCancellationNoticeHours ?? this.userCancellationNoticeHours,
    lateCancellationConsumes:
        lateCancellationConsumes ?? this.lateCancellationConsumes,
    noShowConsumes: noShowConsumes ?? this.noShowConsumes,
    freeAbsenceQuota: freeAbsenceQuota ?? this.freeAbsenceQuota,
    holidayConsumes: holidayConsumes ?? this.holidayConsumes,
    makeupRequired: makeupRequired ?? this.makeupRequired,
    autoExtendUntilUnitsConsumed:
        autoExtendUntilUnitsConsumed ?? this.autoExtendUntilUnitsConsumed,
    maxExtensionDate: maxExtensionDate.present
        ? maxExtensionDate.value
        : this.maxExtensionDate,
    partialUnitAllowed: partialUnitAllowed ?? this.partialUnitAllowed,
  );
  SessionPolicy copyWithCompanion(SessionPoliciesCompanion data) {
    return SessionPolicy(
      id: data.id.present ? data.id.value : this.id,
      cycleId: data.cycleId.present ? data.cycleId.value : this.cycleId,
      providerCancellationConsumes: data.providerCancellationConsumes.present
          ? data.providerCancellationConsumes.value
          : this.providerCancellationConsumes,
      userCancellationNoticeHours: data.userCancellationNoticeHours.present
          ? data.userCancellationNoticeHours.value
          : this.userCancellationNoticeHours,
      lateCancellationConsumes: data.lateCancellationConsumes.present
          ? data.lateCancellationConsumes.value
          : this.lateCancellationConsumes,
      noShowConsumes: data.noShowConsumes.present
          ? data.noShowConsumes.value
          : this.noShowConsumes,
      freeAbsenceQuota: data.freeAbsenceQuota.present
          ? data.freeAbsenceQuota.value
          : this.freeAbsenceQuota,
      holidayConsumes: data.holidayConsumes.present
          ? data.holidayConsumes.value
          : this.holidayConsumes,
      makeupRequired: data.makeupRequired.present
          ? data.makeupRequired.value
          : this.makeupRequired,
      autoExtendUntilUnitsConsumed: data.autoExtendUntilUnitsConsumed.present
          ? data.autoExtendUntilUnitsConsumed.value
          : this.autoExtendUntilUnitsConsumed,
      maxExtensionDate: data.maxExtensionDate.present
          ? data.maxExtensionDate.value
          : this.maxExtensionDate,
      partialUnitAllowed: data.partialUnitAllowed.present
          ? data.partialUnitAllowed.value
          : this.partialUnitAllowed,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SessionPolicy(')
          ..write('id: $id, ')
          ..write('cycleId: $cycleId, ')
          ..write(
            'providerCancellationConsumes: $providerCancellationConsumes, ',
          )
          ..write('userCancellationNoticeHours: $userCancellationNoticeHours, ')
          ..write('lateCancellationConsumes: $lateCancellationConsumes, ')
          ..write('noShowConsumes: $noShowConsumes, ')
          ..write('freeAbsenceQuota: $freeAbsenceQuota, ')
          ..write('holidayConsumes: $holidayConsumes, ')
          ..write('makeupRequired: $makeupRequired, ')
          ..write(
            'autoExtendUntilUnitsConsumed: $autoExtendUntilUnitsConsumed, ',
          )
          ..write('maxExtensionDate: $maxExtensionDate, ')
          ..write('partialUnitAllowed: $partialUnitAllowed')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    cycleId,
    providerCancellationConsumes,
    userCancellationNoticeHours,
    lateCancellationConsumes,
    noShowConsumes,
    freeAbsenceQuota,
    holidayConsumes,
    makeupRequired,
    autoExtendUntilUnitsConsumed,
    maxExtensionDate,
    partialUnitAllowed,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SessionPolicy &&
          other.id == this.id &&
          other.cycleId == this.cycleId &&
          other.providerCancellationConsumes ==
              this.providerCancellationConsumes &&
          other.userCancellationNoticeHours ==
              this.userCancellationNoticeHours &&
          other.lateCancellationConsumes == this.lateCancellationConsumes &&
          other.noShowConsumes == this.noShowConsumes &&
          other.freeAbsenceQuota == this.freeAbsenceQuota &&
          other.holidayConsumes == this.holidayConsumes &&
          other.makeupRequired == this.makeupRequired &&
          other.autoExtendUntilUnitsConsumed ==
              this.autoExtendUntilUnitsConsumed &&
          other.maxExtensionDate == this.maxExtensionDate &&
          other.partialUnitAllowed == this.partialUnitAllowed);
}

class SessionPoliciesCompanion extends UpdateCompanion<SessionPolicy> {
  final Value<String> id;
  final Value<String> cycleId;
  final Value<bool> providerCancellationConsumes;
  final Value<int> userCancellationNoticeHours;
  final Value<bool> lateCancellationConsumes;
  final Value<bool> noShowConsumes;
  final Value<int> freeAbsenceQuota;
  final Value<bool> holidayConsumes;
  final Value<bool> makeupRequired;
  final Value<bool> autoExtendUntilUnitsConsumed;
  final Value<DateTime?> maxExtensionDate;
  final Value<bool> partialUnitAllowed;
  final Value<int> rowid;
  const SessionPoliciesCompanion({
    this.id = const Value.absent(),
    this.cycleId = const Value.absent(),
    this.providerCancellationConsumes = const Value.absent(),
    this.userCancellationNoticeHours = const Value.absent(),
    this.lateCancellationConsumes = const Value.absent(),
    this.noShowConsumes = const Value.absent(),
    this.freeAbsenceQuota = const Value.absent(),
    this.holidayConsumes = const Value.absent(),
    this.makeupRequired = const Value.absent(),
    this.autoExtendUntilUnitsConsumed = const Value.absent(),
    this.maxExtensionDate = const Value.absent(),
    this.partialUnitAllowed = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SessionPoliciesCompanion.insert({
    required String id,
    required String cycleId,
    required bool providerCancellationConsumes,
    required int userCancellationNoticeHours,
    required bool lateCancellationConsumes,
    required bool noShowConsumes,
    required int freeAbsenceQuota,
    required bool holidayConsumes,
    required bool makeupRequired,
    required bool autoExtendUntilUnitsConsumed,
    this.maxExtensionDate = const Value.absent(),
    required bool partialUnitAllowed,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       cycleId = Value(cycleId),
       providerCancellationConsumes = Value(providerCancellationConsumes),
       userCancellationNoticeHours = Value(userCancellationNoticeHours),
       lateCancellationConsumes = Value(lateCancellationConsumes),
       noShowConsumes = Value(noShowConsumes),
       freeAbsenceQuota = Value(freeAbsenceQuota),
       holidayConsumes = Value(holidayConsumes),
       makeupRequired = Value(makeupRequired),
       autoExtendUntilUnitsConsumed = Value(autoExtendUntilUnitsConsumed),
       partialUnitAllowed = Value(partialUnitAllowed);
  static Insertable<SessionPolicy> custom({
    Expression<String>? id,
    Expression<String>? cycleId,
    Expression<bool>? providerCancellationConsumes,
    Expression<int>? userCancellationNoticeHours,
    Expression<bool>? lateCancellationConsumes,
    Expression<bool>? noShowConsumes,
    Expression<int>? freeAbsenceQuota,
    Expression<bool>? holidayConsumes,
    Expression<bool>? makeupRequired,
    Expression<bool>? autoExtendUntilUnitsConsumed,
    Expression<DateTime>? maxExtensionDate,
    Expression<bool>? partialUnitAllowed,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (cycleId != null) 'cycle_id': cycleId,
      if (providerCancellationConsumes != null)
        'provider_cancellation_consumes': providerCancellationConsumes,
      if (userCancellationNoticeHours != null)
        'user_cancellation_notice_hours': userCancellationNoticeHours,
      if (lateCancellationConsumes != null)
        'late_cancellation_consumes': lateCancellationConsumes,
      if (noShowConsumes != null) 'no_show_consumes': noShowConsumes,
      if (freeAbsenceQuota != null) 'free_absence_quota': freeAbsenceQuota,
      if (holidayConsumes != null) 'holiday_consumes': holidayConsumes,
      if (makeupRequired != null) 'makeup_required': makeupRequired,
      if (autoExtendUntilUnitsConsumed != null)
        'auto_extend_until_units_consumed': autoExtendUntilUnitsConsumed,
      if (maxExtensionDate != null) 'max_extension_date': maxExtensionDate,
      if (partialUnitAllowed != null)
        'partial_unit_allowed': partialUnitAllowed,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SessionPoliciesCompanion copyWith({
    Value<String>? id,
    Value<String>? cycleId,
    Value<bool>? providerCancellationConsumes,
    Value<int>? userCancellationNoticeHours,
    Value<bool>? lateCancellationConsumes,
    Value<bool>? noShowConsumes,
    Value<int>? freeAbsenceQuota,
    Value<bool>? holidayConsumes,
    Value<bool>? makeupRequired,
    Value<bool>? autoExtendUntilUnitsConsumed,
    Value<DateTime?>? maxExtensionDate,
    Value<bool>? partialUnitAllowed,
    Value<int>? rowid,
  }) {
    return SessionPoliciesCompanion(
      id: id ?? this.id,
      cycleId: cycleId ?? this.cycleId,
      providerCancellationConsumes:
          providerCancellationConsumes ?? this.providerCancellationConsumes,
      userCancellationNoticeHours:
          userCancellationNoticeHours ?? this.userCancellationNoticeHours,
      lateCancellationConsumes:
          lateCancellationConsumes ?? this.lateCancellationConsumes,
      noShowConsumes: noShowConsumes ?? this.noShowConsumes,
      freeAbsenceQuota: freeAbsenceQuota ?? this.freeAbsenceQuota,
      holidayConsumes: holidayConsumes ?? this.holidayConsumes,
      makeupRequired: makeupRequired ?? this.makeupRequired,
      autoExtendUntilUnitsConsumed:
          autoExtendUntilUnitsConsumed ?? this.autoExtendUntilUnitsConsumed,
      maxExtensionDate: maxExtensionDate ?? this.maxExtensionDate,
      partialUnitAllowed: partialUnitAllowed ?? this.partialUnitAllowed,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (cycleId.present) {
      map['cycle_id'] = Variable<String>(cycleId.value);
    }
    if (providerCancellationConsumes.present) {
      map['provider_cancellation_consumes'] = Variable<bool>(
        providerCancellationConsumes.value,
      );
    }
    if (userCancellationNoticeHours.present) {
      map['user_cancellation_notice_hours'] = Variable<int>(
        userCancellationNoticeHours.value,
      );
    }
    if (lateCancellationConsumes.present) {
      map['late_cancellation_consumes'] = Variable<bool>(
        lateCancellationConsumes.value,
      );
    }
    if (noShowConsumes.present) {
      map['no_show_consumes'] = Variable<bool>(noShowConsumes.value);
    }
    if (freeAbsenceQuota.present) {
      map['free_absence_quota'] = Variable<int>(freeAbsenceQuota.value);
    }
    if (holidayConsumes.present) {
      map['holiday_consumes'] = Variable<bool>(holidayConsumes.value);
    }
    if (makeupRequired.present) {
      map['makeup_required'] = Variable<bool>(makeupRequired.value);
    }
    if (autoExtendUntilUnitsConsumed.present) {
      map['auto_extend_until_units_consumed'] = Variable<bool>(
        autoExtendUntilUnitsConsumed.value,
      );
    }
    if (maxExtensionDate.present) {
      map['max_extension_date'] = Variable<DateTime>(maxExtensionDate.value);
    }
    if (partialUnitAllowed.present) {
      map['partial_unit_allowed'] = Variable<bool>(partialUnitAllowed.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionPoliciesCompanion(')
          ..write('id: $id, ')
          ..write('cycleId: $cycleId, ')
          ..write(
            'providerCancellationConsumes: $providerCancellationConsumes, ',
          )
          ..write('userCancellationNoticeHours: $userCancellationNoticeHours, ')
          ..write('lateCancellationConsumes: $lateCancellationConsumes, ')
          ..write('noShowConsumes: $noShowConsumes, ')
          ..write('freeAbsenceQuota: $freeAbsenceQuota, ')
          ..write('holidayConsumes: $holidayConsumes, ')
          ..write('makeupRequired: $makeupRequired, ')
          ..write(
            'autoExtendUntilUnitsConsumed: $autoExtendUntilUnitsConsumed, ',
          )
          ..write('maxExtensionDate: $maxExtensionDate, ')
          ..write('partialUnitAllowed: $partialUnitAllowed, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReplacementOccurrencesTable extends ReplacementOccurrences
    with TableInfo<$ReplacementOccurrencesTable, ReplacementOccurrence> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReplacementOccurrencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originalOccurrenceIdMeta =
      const VerificationMeta('originalOccurrenceId');
  @override
  late final GeneratedColumn<String> originalOccurrenceId =
      GeneratedColumn<String>(
        'original_occurrence_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _parentReplacementIdMeta =
      const VerificationMeta('parentReplacementId');
  @override
  late final GeneratedColumn<String> parentReplacementId =
      GeneratedColumn<String>(
        'parent_replacement_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _scheduledAtMeta = const VerificationMeta(
    'scheduledAt',
  );
  @override
  late final GeneratedColumn<DateTime> scheduledAt = GeneratedColumn<DateTime>(
    'scheduled_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<int> reason = GeneratedColumn<int>(
    'reason',
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
    originalOccurrenceId,
    parentReplacementId,
    scheduledAt,
    reason,
    status,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'replacement_occurrences';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReplacementOccurrence> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('original_occurrence_id')) {
      context.handle(
        _originalOccurrenceIdMeta,
        originalOccurrenceId.isAcceptableOrUnknown(
          data['original_occurrence_id']!,
          _originalOccurrenceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originalOccurrenceIdMeta);
    }
    if (data.containsKey('parent_replacement_id')) {
      context.handle(
        _parentReplacementIdMeta,
        parentReplacementId.isAcceptableOrUnknown(
          data['parent_replacement_id']!,
          _parentReplacementIdMeta,
        ),
      );
    }
    if (data.containsKey('scheduled_at')) {
      context.handle(
        _scheduledAtMeta,
        scheduledAt.isAcceptableOrUnknown(
          data['scheduled_at']!,
          _scheduledAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_scheduledAtMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    } else if (isInserting) {
      context.missing(_reasonMeta);
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
  ReplacementOccurrence map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReplacementOccurrence(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      originalOccurrenceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_occurrence_id'],
      )!,
      parentReplacementId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_replacement_id'],
      ),
      scheduledAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}scheduled_at'],
      )!,
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reason'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}status'],
      )!,
    );
  }

  @override
  $ReplacementOccurrencesTable createAlias(String alias) {
    return $ReplacementOccurrencesTable(attachedDatabase, alias);
  }
}

class ReplacementOccurrence extends DataClass
    implements Insertable<ReplacementOccurrence> {
  final String id;
  final String originalOccurrenceId;
  final String? parentReplacementId;
  final DateTime scheduledAt;
  final int reason;
  final int status;
  const ReplacementOccurrence({
    required this.id,
    required this.originalOccurrenceId,
    this.parentReplacementId,
    required this.scheduledAt,
    required this.reason,
    required this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['original_occurrence_id'] = Variable<String>(originalOccurrenceId);
    if (!nullToAbsent || parentReplacementId != null) {
      map['parent_replacement_id'] = Variable<String>(parentReplacementId);
    }
    map['scheduled_at'] = Variable<DateTime>(scheduledAt);
    map['reason'] = Variable<int>(reason);
    map['status'] = Variable<int>(status);
    return map;
  }

  ReplacementOccurrencesCompanion toCompanion(bool nullToAbsent) {
    return ReplacementOccurrencesCompanion(
      id: Value(id),
      originalOccurrenceId: Value(originalOccurrenceId),
      parentReplacementId: parentReplacementId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentReplacementId),
      scheduledAt: Value(scheduledAt),
      reason: Value(reason),
      status: Value(status),
    );
  }

  factory ReplacementOccurrence.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReplacementOccurrence(
      id: serializer.fromJson<String>(json['id']),
      originalOccurrenceId: serializer.fromJson<String>(
        json['originalOccurrenceId'],
      ),
      parentReplacementId: serializer.fromJson<String?>(
        json['parentReplacementId'],
      ),
      scheduledAt: serializer.fromJson<DateTime>(json['scheduledAt']),
      reason: serializer.fromJson<int>(json['reason']),
      status: serializer.fromJson<int>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'originalOccurrenceId': serializer.toJson<String>(originalOccurrenceId),
      'parentReplacementId': serializer.toJson<String?>(parentReplacementId),
      'scheduledAt': serializer.toJson<DateTime>(scheduledAt),
      'reason': serializer.toJson<int>(reason),
      'status': serializer.toJson<int>(status),
    };
  }

  ReplacementOccurrence copyWith({
    String? id,
    String? originalOccurrenceId,
    Value<String?> parentReplacementId = const Value.absent(),
    DateTime? scheduledAt,
    int? reason,
    int? status,
  }) => ReplacementOccurrence(
    id: id ?? this.id,
    originalOccurrenceId: originalOccurrenceId ?? this.originalOccurrenceId,
    parentReplacementId: parentReplacementId.present
        ? parentReplacementId.value
        : this.parentReplacementId,
    scheduledAt: scheduledAt ?? this.scheduledAt,
    reason: reason ?? this.reason,
    status: status ?? this.status,
  );
  ReplacementOccurrence copyWithCompanion(
    ReplacementOccurrencesCompanion data,
  ) {
    return ReplacementOccurrence(
      id: data.id.present ? data.id.value : this.id,
      originalOccurrenceId: data.originalOccurrenceId.present
          ? data.originalOccurrenceId.value
          : this.originalOccurrenceId,
      parentReplacementId: data.parentReplacementId.present
          ? data.parentReplacementId.value
          : this.parentReplacementId,
      scheduledAt: data.scheduledAt.present
          ? data.scheduledAt.value
          : this.scheduledAt,
      reason: data.reason.present ? data.reason.value : this.reason,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReplacementOccurrence(')
          ..write('id: $id, ')
          ..write('originalOccurrenceId: $originalOccurrenceId, ')
          ..write('parentReplacementId: $parentReplacementId, ')
          ..write('scheduledAt: $scheduledAt, ')
          ..write('reason: $reason, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    originalOccurrenceId,
    parentReplacementId,
    scheduledAt,
    reason,
    status,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReplacementOccurrence &&
          other.id == this.id &&
          other.originalOccurrenceId == this.originalOccurrenceId &&
          other.parentReplacementId == this.parentReplacementId &&
          other.scheduledAt == this.scheduledAt &&
          other.reason == this.reason &&
          other.status == this.status);
}

class ReplacementOccurrencesCompanion
    extends UpdateCompanion<ReplacementOccurrence> {
  final Value<String> id;
  final Value<String> originalOccurrenceId;
  final Value<String?> parentReplacementId;
  final Value<DateTime> scheduledAt;
  final Value<int> reason;
  final Value<int> status;
  final Value<int> rowid;
  const ReplacementOccurrencesCompanion({
    this.id = const Value.absent(),
    this.originalOccurrenceId = const Value.absent(),
    this.parentReplacementId = const Value.absent(),
    this.scheduledAt = const Value.absent(),
    this.reason = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReplacementOccurrencesCompanion.insert({
    required String id,
    required String originalOccurrenceId,
    this.parentReplacementId = const Value.absent(),
    required DateTime scheduledAt,
    required int reason,
    required int status,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       originalOccurrenceId = Value(originalOccurrenceId),
       scheduledAt = Value(scheduledAt),
       reason = Value(reason),
       status = Value(status);
  static Insertable<ReplacementOccurrence> custom({
    Expression<String>? id,
    Expression<String>? originalOccurrenceId,
    Expression<String>? parentReplacementId,
    Expression<DateTime>? scheduledAt,
    Expression<int>? reason,
    Expression<int>? status,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (originalOccurrenceId != null)
        'original_occurrence_id': originalOccurrenceId,
      if (parentReplacementId != null)
        'parent_replacement_id': parentReplacementId,
      if (scheduledAt != null) 'scheduled_at': scheduledAt,
      if (reason != null) 'reason': reason,
      if (status != null) 'status': status,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReplacementOccurrencesCompanion copyWith({
    Value<String>? id,
    Value<String>? originalOccurrenceId,
    Value<String?>? parentReplacementId,
    Value<DateTime>? scheduledAt,
    Value<int>? reason,
    Value<int>? status,
    Value<int>? rowid,
  }) {
    return ReplacementOccurrencesCompanion(
      id: id ?? this.id,
      originalOccurrenceId: originalOccurrenceId ?? this.originalOccurrenceId,
      parentReplacementId: parentReplacementId ?? this.parentReplacementId,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      reason: reason ?? this.reason,
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
    if (originalOccurrenceId.present) {
      map['original_occurrence_id'] = Variable<String>(
        originalOccurrenceId.value,
      );
    }
    if (parentReplacementId.present) {
      map['parent_replacement_id'] = Variable<String>(
        parentReplacementId.value,
      );
    }
    if (scheduledAt.present) {
      map['scheduled_at'] = Variable<DateTime>(scheduledAt.value);
    }
    if (reason.present) {
      map['reason'] = Variable<int>(reason.value);
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
    return (StringBuffer('ReplacementOccurrencesCompanion(')
          ..write('id: $id, ')
          ..write('originalOccurrenceId: $originalOccurrenceId, ')
          ..write('parentReplacementId: $parentReplacementId, ')
          ..write('scheduledAt: $scheduledAt, ')
          ..write('reason: $reason, ')
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
  late final $ScheduleDefinitionsTable scheduleDefinitions =
      $ScheduleDefinitionsTable(this);
  late final $OccurrencesTable occurrences = $OccurrencesTable(this);
  late final $EntitlementPlansTable entitlementPlans = $EntitlementPlansTable(
    this,
  );
  late final $EntitlementLedgerEntriesTable entitlementLedgerEntries =
      $EntitlementLedgerEntriesTable(this);
  late final $SessionPoliciesTable sessionPolicies = $SessionPoliciesTable(
    this,
  );
  late final $ReplacementOccurrencesTable replacementOccurrences =
      $ReplacementOccurrencesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    schemaMetadata,
    commitments,
    commitmentCycles,
    scheduleDefinitions,
    occurrences,
    entitlementPlans,
    entitlementLedgerEntries,
    sessionPolicies,
    replacementOccurrences,
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

  static MultiTypedResultKey<
    $ScheduleDefinitionsTable,
    List<ScheduleDefinition>
  >
  _scheduleDefinitionsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.scheduleDefinitions,
        aliasName: 'commitment_cycles__id__schedule_definitions__cycle_id',
      );

  $$ScheduleDefinitionsTableProcessedTableManager get scheduleDefinitionsRefs {
    final manager = $$ScheduleDefinitionsTableTableManager(
      $_db,
      $_db.scheduleDefinitions,
    ).filter((f) => f.cycleId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _scheduleDefinitionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$OccurrencesTable, List<Occurrence>>
  _occurrencesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.occurrences,
    aliasName: 'commitment_cycles__id__occurrences__cycle_id',
  );

  $$OccurrencesTableProcessedTableManager get occurrencesRefs {
    final manager = $$OccurrencesTableTableManager(
      $_db,
      $_db.occurrences,
    ).filter((f) => f.cycleId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_occurrencesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$EntitlementPlansTable, List<EntitlementPlan>>
  _entitlementPlansRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.entitlementPlans,
    aliasName: 'commitment_cycles__id__entitlement_plans__cycle_id',
  );

  $$EntitlementPlansTableProcessedTableManager get entitlementPlansRefs {
    final manager = $$EntitlementPlansTableTableManager(
      $_db,
      $_db.entitlementPlans,
    ).filter((f) => f.cycleId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _entitlementPlansRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SessionPoliciesTable, List<SessionPolicy>>
  _sessionPoliciesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.sessionPolicies,
    aliasName: 'commitment_cycles__id__session_policies__cycle_id',
  );

  $$SessionPoliciesTableProcessedTableManager get sessionPoliciesRefs {
    final manager = $$SessionPoliciesTableTableManager(
      $_db,
      $_db.sessionPolicies,
    ).filter((f) => f.cycleId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _sessionPoliciesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
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

  Expression<bool> scheduleDefinitionsRefs(
    Expression<bool> Function($$ScheduleDefinitionsTableFilterComposer f) f,
  ) {
    final $$ScheduleDefinitionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.scheduleDefinitions,
      getReferencedColumn: (t) => t.cycleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScheduleDefinitionsTableFilterComposer(
            $db: $db,
            $table: $db.scheduleDefinitions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> occurrencesRefs(
    Expression<bool> Function($$OccurrencesTableFilterComposer f) f,
  ) {
    final $$OccurrencesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.occurrences,
      getReferencedColumn: (t) => t.cycleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OccurrencesTableFilterComposer(
            $db: $db,
            $table: $db.occurrences,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> entitlementPlansRefs(
    Expression<bool> Function($$EntitlementPlansTableFilterComposer f) f,
  ) {
    final $$EntitlementPlansTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.entitlementPlans,
      getReferencedColumn: (t) => t.cycleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntitlementPlansTableFilterComposer(
            $db: $db,
            $table: $db.entitlementPlans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> sessionPoliciesRefs(
    Expression<bool> Function($$SessionPoliciesTableFilterComposer f) f,
  ) {
    final $$SessionPoliciesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sessionPolicies,
      getReferencedColumn: (t) => t.cycleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionPoliciesTableFilterComposer(
            $db: $db,
            $table: $db.sessionPolicies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
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

  Expression<T> scheduleDefinitionsRefs<T extends Object>(
    Expression<T> Function($$ScheduleDefinitionsTableAnnotationComposer a) f,
  ) {
    final $$ScheduleDefinitionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.scheduleDefinitions,
          getReferencedColumn: (t) => t.cycleId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ScheduleDefinitionsTableAnnotationComposer(
                $db: $db,
                $table: $db.scheduleDefinitions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> occurrencesRefs<T extends Object>(
    Expression<T> Function($$OccurrencesTableAnnotationComposer a) f,
  ) {
    final $$OccurrencesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.occurrences,
      getReferencedColumn: (t) => t.cycleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OccurrencesTableAnnotationComposer(
            $db: $db,
            $table: $db.occurrences,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> entitlementPlansRefs<T extends Object>(
    Expression<T> Function($$EntitlementPlansTableAnnotationComposer a) f,
  ) {
    final $$EntitlementPlansTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.entitlementPlans,
      getReferencedColumn: (t) => t.cycleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntitlementPlansTableAnnotationComposer(
            $db: $db,
            $table: $db.entitlementPlans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> sessionPoliciesRefs<T extends Object>(
    Expression<T> Function($$SessionPoliciesTableAnnotationComposer a) f,
  ) {
    final $$SessionPoliciesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sessionPolicies,
      getReferencedColumn: (t) => t.cycleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionPoliciesTableAnnotationComposer(
            $db: $db,
            $table: $db.sessionPolicies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
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
          PrefetchHooks Function({
            bool commitmentId,
            bool scheduleDefinitionsRefs,
            bool occurrencesRefs,
            bool entitlementPlansRefs,
            bool sessionPoliciesRefs,
          })
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
          prefetchHooksCallback:
              ({
                commitmentId = false,
                scheduleDefinitionsRefs = false,
                occurrencesRefs = false,
                entitlementPlansRefs = false,
                sessionPoliciesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (scheduleDefinitionsRefs) db.scheduleDefinitions,
                    if (occurrencesRefs) db.occurrences,
                    if (entitlementPlansRefs) db.entitlementPlans,
                    if (sessionPoliciesRefs) db.sessionPolicies,
                  ],
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
                    return [
                      if (scheduleDefinitionsRefs)
                        await $_getPrefetchedData<
                          CommitmentCycle,
                          $CommitmentCyclesTable,
                          ScheduleDefinition
                        >(
                          currentTable: table,
                          referencedTable: $$CommitmentCyclesTableReferences
                              ._scheduleDefinitionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CommitmentCyclesTableReferences(
                                db,
                                table,
                                p0,
                              ).scheduleDefinitionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.cycleId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (occurrencesRefs)
                        await $_getPrefetchedData<
                          CommitmentCycle,
                          $CommitmentCyclesTable,
                          Occurrence
                        >(
                          currentTable: table,
                          referencedTable: $$CommitmentCyclesTableReferences
                              ._occurrencesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CommitmentCyclesTableReferences(
                                db,
                                table,
                                p0,
                              ).occurrencesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.cycleId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (entitlementPlansRefs)
                        await $_getPrefetchedData<
                          CommitmentCycle,
                          $CommitmentCyclesTable,
                          EntitlementPlan
                        >(
                          currentTable: table,
                          referencedTable: $$CommitmentCyclesTableReferences
                              ._entitlementPlansRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CommitmentCyclesTableReferences(
                                db,
                                table,
                                p0,
                              ).entitlementPlansRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.cycleId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (sessionPoliciesRefs)
                        await $_getPrefetchedData<
                          CommitmentCycle,
                          $CommitmentCyclesTable,
                          SessionPolicy
                        >(
                          currentTable: table,
                          referencedTable: $$CommitmentCyclesTableReferences
                              ._sessionPoliciesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CommitmentCyclesTableReferences(
                                db,
                                table,
                                p0,
                              ).sessionPoliciesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.cycleId == item.id,
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
      PrefetchHooks Function({
        bool commitmentId,
        bool scheduleDefinitionsRefs,
        bool occurrencesRefs,
        bool entitlementPlansRefs,
        bool sessionPoliciesRefs,
      })
    >;
typedef $$ScheduleDefinitionsTableCreateCompanionBuilder =
    ScheduleDefinitionsCompanion Function({
      required String id,
      required String cycleId,
      required int mode,
      required int timeSemantics,
      required String startDate,
      Value<String?> localTime,
      Value<String?> timeZoneId,
      Value<DateTime?> fixedInstant,
      Value<String?> recurrenceRule,
      Value<String?> endDate,
      Value<int?> occurrenceCount,
      required int version,
      required String effectiveFrom,
      required int generationHorizonDays,
      Value<int> rowid,
    });
typedef $$ScheduleDefinitionsTableUpdateCompanionBuilder =
    ScheduleDefinitionsCompanion Function({
      Value<String> id,
      Value<String> cycleId,
      Value<int> mode,
      Value<int> timeSemantics,
      Value<String> startDate,
      Value<String?> localTime,
      Value<String?> timeZoneId,
      Value<DateTime?> fixedInstant,
      Value<String?> recurrenceRule,
      Value<String?> endDate,
      Value<int?> occurrenceCount,
      Value<int> version,
      Value<String> effectiveFrom,
      Value<int> generationHorizonDays,
      Value<int> rowid,
    });

final class $$ScheduleDefinitionsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ScheduleDefinitionsTable,
          ScheduleDefinition
        > {
  $$ScheduleDefinitionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CommitmentCyclesTable _cycleIdTable(_$AppDatabase db) => db
      .commitmentCycles
      .createAlias('schedule_definitions__cycle_id__commitment_cycles__id');

  $$CommitmentCyclesTableProcessedTableManager get cycleId {
    final $_column = $_itemColumn<String>('cycle_id')!;

    final manager = $$CommitmentCyclesTableTableManager(
      $_db,
      $_db.commitmentCycles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_cycleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$OccurrencesTable, List<Occurrence>>
  _occurrencesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.occurrences,
    aliasName: 'schedule_definitions__id__occurrences__schedule_definition_id',
  );

  $$OccurrencesTableProcessedTableManager get occurrencesRefs {
    final manager = $$OccurrencesTableTableManager($_db, $_db.occurrences)
        .filter(
          (f) =>
              f.scheduleDefinitionId.id.sqlEquals($_itemColumn<String>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(_occurrencesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ScheduleDefinitionsTableFilterComposer
    extends Composer<_$AppDatabase, $ScheduleDefinitionsTable> {
  $$ScheduleDefinitionsTableFilterComposer({
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

  ColumnFilters<int> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timeSemantics => $composableBuilder(
    column: $table.timeSemantics,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localTime => $composableBuilder(
    column: $table.localTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timeZoneId => $composableBuilder(
    column: $table.timeZoneId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fixedInstant => $composableBuilder(
    column: $table.fixedInstant,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recurrenceRule => $composableBuilder(
    column: $table.recurrenceRule,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get occurrenceCount => $composableBuilder(
    column: $table.occurrenceCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get effectiveFrom => $composableBuilder(
    column: $table.effectiveFrom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get generationHorizonDays => $composableBuilder(
    column: $table.generationHorizonDays,
    builder: (column) => ColumnFilters(column),
  );

  $$CommitmentCyclesTableFilterComposer get cycleId {
    final $$CommitmentCyclesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cycleId,
      referencedTable: $db.commitmentCycles,
      getReferencedColumn: (t) => t.id,
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
    return composer;
  }

  Expression<bool> occurrencesRefs(
    Expression<bool> Function($$OccurrencesTableFilterComposer f) f,
  ) {
    final $$OccurrencesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.occurrences,
      getReferencedColumn: (t) => t.scheduleDefinitionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OccurrencesTableFilterComposer(
            $db: $db,
            $table: $db.occurrences,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ScheduleDefinitionsTableOrderingComposer
    extends Composer<_$AppDatabase, $ScheduleDefinitionsTable> {
  $$ScheduleDefinitionsTableOrderingComposer({
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

  ColumnOrderings<int> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timeSemantics => $composableBuilder(
    column: $table.timeSemantics,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localTime => $composableBuilder(
    column: $table.localTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timeZoneId => $composableBuilder(
    column: $table.timeZoneId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fixedInstant => $composableBuilder(
    column: $table.fixedInstant,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recurrenceRule => $composableBuilder(
    column: $table.recurrenceRule,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get occurrenceCount => $composableBuilder(
    column: $table.occurrenceCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get effectiveFrom => $composableBuilder(
    column: $table.effectiveFrom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get generationHorizonDays => $composableBuilder(
    column: $table.generationHorizonDays,
    builder: (column) => ColumnOrderings(column),
  );

  $$CommitmentCyclesTableOrderingComposer get cycleId {
    final $$CommitmentCyclesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cycleId,
      referencedTable: $db.commitmentCycles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CommitmentCyclesTableOrderingComposer(
            $db: $db,
            $table: $db.commitmentCycles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ScheduleDefinitionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ScheduleDefinitionsTable> {
  $$ScheduleDefinitionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

  GeneratedColumn<int> get timeSemantics => $composableBuilder(
    column: $table.timeSemantics,
    builder: (column) => column,
  );

  GeneratedColumn<String> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<String> get localTime =>
      $composableBuilder(column: $table.localTime, builder: (column) => column);

  GeneratedColumn<String> get timeZoneId => $composableBuilder(
    column: $table.timeZoneId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get fixedInstant => $composableBuilder(
    column: $table.fixedInstant,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recurrenceRule => $composableBuilder(
    column: $table.recurrenceRule,
    builder: (column) => column,
  );

  GeneratedColumn<String> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<int> get occurrenceCount => $composableBuilder(
    column: $table.occurrenceCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get effectiveFrom => $composableBuilder(
    column: $table.effectiveFrom,
    builder: (column) => column,
  );

  GeneratedColumn<int> get generationHorizonDays => $composableBuilder(
    column: $table.generationHorizonDays,
    builder: (column) => column,
  );

  $$CommitmentCyclesTableAnnotationComposer get cycleId {
    final $$CommitmentCyclesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cycleId,
      referencedTable: $db.commitmentCycles,
      getReferencedColumn: (t) => t.id,
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
    return composer;
  }

  Expression<T> occurrencesRefs<T extends Object>(
    Expression<T> Function($$OccurrencesTableAnnotationComposer a) f,
  ) {
    final $$OccurrencesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.occurrences,
      getReferencedColumn: (t) => t.scheduleDefinitionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OccurrencesTableAnnotationComposer(
            $db: $db,
            $table: $db.occurrences,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ScheduleDefinitionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ScheduleDefinitionsTable,
          ScheduleDefinition,
          $$ScheduleDefinitionsTableFilterComposer,
          $$ScheduleDefinitionsTableOrderingComposer,
          $$ScheduleDefinitionsTableAnnotationComposer,
          $$ScheduleDefinitionsTableCreateCompanionBuilder,
          $$ScheduleDefinitionsTableUpdateCompanionBuilder,
          (ScheduleDefinition, $$ScheduleDefinitionsTableReferences),
          ScheduleDefinition,
          PrefetchHooks Function({bool cycleId, bool occurrencesRefs})
        > {
  $$ScheduleDefinitionsTableTableManager(
    _$AppDatabase db,
    $ScheduleDefinitionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ScheduleDefinitionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ScheduleDefinitionsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ScheduleDefinitionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> cycleId = const Value.absent(),
                Value<int> mode = const Value.absent(),
                Value<int> timeSemantics = const Value.absent(),
                Value<String> startDate = const Value.absent(),
                Value<String?> localTime = const Value.absent(),
                Value<String?> timeZoneId = const Value.absent(),
                Value<DateTime?> fixedInstant = const Value.absent(),
                Value<String?> recurrenceRule = const Value.absent(),
                Value<String?> endDate = const Value.absent(),
                Value<int?> occurrenceCount = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String> effectiveFrom = const Value.absent(),
                Value<int> generationHorizonDays = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ScheduleDefinitionsCompanion(
                id: id,
                cycleId: cycleId,
                mode: mode,
                timeSemantics: timeSemantics,
                startDate: startDate,
                localTime: localTime,
                timeZoneId: timeZoneId,
                fixedInstant: fixedInstant,
                recurrenceRule: recurrenceRule,
                endDate: endDate,
                occurrenceCount: occurrenceCount,
                version: version,
                effectiveFrom: effectiveFrom,
                generationHorizonDays: generationHorizonDays,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String cycleId,
                required int mode,
                required int timeSemantics,
                required String startDate,
                Value<String?> localTime = const Value.absent(),
                Value<String?> timeZoneId = const Value.absent(),
                Value<DateTime?> fixedInstant = const Value.absent(),
                Value<String?> recurrenceRule = const Value.absent(),
                Value<String?> endDate = const Value.absent(),
                Value<int?> occurrenceCount = const Value.absent(),
                required int version,
                required String effectiveFrom,
                required int generationHorizonDays,
                Value<int> rowid = const Value.absent(),
              }) => ScheduleDefinitionsCompanion.insert(
                id: id,
                cycleId: cycleId,
                mode: mode,
                timeSemantics: timeSemantics,
                startDate: startDate,
                localTime: localTime,
                timeZoneId: timeZoneId,
                fixedInstant: fixedInstant,
                recurrenceRule: recurrenceRule,
                endDate: endDate,
                occurrenceCount: occurrenceCount,
                version: version,
                effectiveFrom: effectiveFrom,
                generationHorizonDays: generationHorizonDays,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ScheduleDefinitionsTable, ScheduleDefinition>(
                    table,
                  ),
                  $$ScheduleDefinitionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({cycleId = false, occurrencesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (occurrencesRefs) db.occurrences],
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
                    if (cycleId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.cycleId,
                        referencedTable: $$ScheduleDefinitionsTableReferences
                            ._cycleIdTable(db),
                        referencedColumn: $$ScheduleDefinitionsTableReferences
                            ._cycleIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (occurrencesRefs)
                    await $_getPrefetchedData<
                      ScheduleDefinition,
                      $ScheduleDefinitionsTable,
                      Occurrence
                    >(
                      currentTable: table,
                      referencedTable: $$ScheduleDefinitionsTableReferences
                          ._occurrencesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$ScheduleDefinitionsTableReferences(
                            db,
                            table,
                            p0,
                          ).occurrencesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.scheduleDefinitionId == item.id,
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

typedef $$ScheduleDefinitionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ScheduleDefinitionsTable,
      ScheduleDefinition,
      $$ScheduleDefinitionsTableFilterComposer,
      $$ScheduleDefinitionsTableOrderingComposer,
      $$ScheduleDefinitionsTableAnnotationComposer,
      $$ScheduleDefinitionsTableCreateCompanionBuilder,
      $$ScheduleDefinitionsTableUpdateCompanionBuilder,
      (ScheduleDefinition, $$ScheduleDefinitionsTableReferences),
      ScheduleDefinition,
      PrefetchHooks Function({bool cycleId, bool occurrencesRefs})
    >;
typedef $$OccurrencesTableCreateCompanionBuilder =
    OccurrencesCompanion Function({
      required String id,
      required String cycleId,
      required String scheduleDefinitionId,
      required String occurrenceKey,
      required int timeSemantics,
      required String originalScheduledValue,
      required String currentScheduledValue,
      required int status,
      required bool isManualOverride,
      Value<int> rowid,
    });
typedef $$OccurrencesTableUpdateCompanionBuilder =
    OccurrencesCompanion Function({
      Value<String> id,
      Value<String> cycleId,
      Value<String> scheduleDefinitionId,
      Value<String> occurrenceKey,
      Value<int> timeSemantics,
      Value<String> originalScheduledValue,
      Value<String> currentScheduledValue,
      Value<int> status,
      Value<bool> isManualOverride,
      Value<int> rowid,
    });

final class $$OccurrencesTableReferences
    extends BaseReferences<_$AppDatabase, $OccurrencesTable, Occurrence> {
  $$OccurrencesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CommitmentCyclesTable _cycleIdTable(_$AppDatabase db) => db
      .commitmentCycles
      .createAlias('occurrences__cycle_id__commitment_cycles__id');

  $$CommitmentCyclesTableProcessedTableManager get cycleId {
    final $_column = $_itemColumn<String>('cycle_id')!;

    final manager = $$CommitmentCyclesTableTableManager(
      $_db,
      $_db.commitmentCycles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_cycleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ScheduleDefinitionsTable _scheduleDefinitionIdTable(
    _$AppDatabase db,
  ) => db.scheduleDefinitions.createAlias(
    'occurrences__schedule_definition_id__schedule_definitions__id',
  );

  $$ScheduleDefinitionsTableProcessedTableManager get scheduleDefinitionId {
    final $_column = $_itemColumn<String>('schedule_definition_id')!;

    final manager = $$ScheduleDefinitionsTableTableManager(
      $_db,
      $_db.scheduleDefinitions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(
      _scheduleDefinitionIdTable($_db),
    );
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$OccurrencesTableFilterComposer
    extends Composer<_$AppDatabase, $OccurrencesTable> {
  $$OccurrencesTableFilterComposer({
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

  ColumnFilters<String> get occurrenceKey => $composableBuilder(
    column: $table.occurrenceKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timeSemantics => $composableBuilder(
    column: $table.timeSemantics,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalScheduledValue => $composableBuilder(
    column: $table.originalScheduledValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currentScheduledValue => $composableBuilder(
    column: $table.currentScheduledValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isManualOverride => $composableBuilder(
    column: $table.isManualOverride,
    builder: (column) => ColumnFilters(column),
  );

  $$CommitmentCyclesTableFilterComposer get cycleId {
    final $$CommitmentCyclesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cycleId,
      referencedTable: $db.commitmentCycles,
      getReferencedColumn: (t) => t.id,
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
    return composer;
  }

  $$ScheduleDefinitionsTableFilterComposer get scheduleDefinitionId {
    final $$ScheduleDefinitionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scheduleDefinitionId,
      referencedTable: $db.scheduleDefinitions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScheduleDefinitionsTableFilterComposer(
            $db: $db,
            $table: $db.scheduleDefinitions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OccurrencesTableOrderingComposer
    extends Composer<_$AppDatabase, $OccurrencesTable> {
  $$OccurrencesTableOrderingComposer({
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

  ColumnOrderings<String> get occurrenceKey => $composableBuilder(
    column: $table.occurrenceKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timeSemantics => $composableBuilder(
    column: $table.timeSemantics,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalScheduledValue => $composableBuilder(
    column: $table.originalScheduledValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currentScheduledValue => $composableBuilder(
    column: $table.currentScheduledValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isManualOverride => $composableBuilder(
    column: $table.isManualOverride,
    builder: (column) => ColumnOrderings(column),
  );

  $$CommitmentCyclesTableOrderingComposer get cycleId {
    final $$CommitmentCyclesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cycleId,
      referencedTable: $db.commitmentCycles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CommitmentCyclesTableOrderingComposer(
            $db: $db,
            $table: $db.commitmentCycles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ScheduleDefinitionsTableOrderingComposer get scheduleDefinitionId {
    final $$ScheduleDefinitionsTableOrderingComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.scheduleDefinitionId,
          referencedTable: $db.scheduleDefinitions,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ScheduleDefinitionsTableOrderingComposer(
                $db: $db,
                $table: $db.scheduleDefinitions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$OccurrencesTableAnnotationComposer
    extends Composer<_$AppDatabase, $OccurrencesTable> {
  $$OccurrencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get occurrenceKey => $composableBuilder(
    column: $table.occurrenceKey,
    builder: (column) => column,
  );

  GeneratedColumn<int> get timeSemantics => $composableBuilder(
    column: $table.timeSemantics,
    builder: (column) => column,
  );

  GeneratedColumn<String> get originalScheduledValue => $composableBuilder(
    column: $table.originalScheduledValue,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currentScheduledValue => $composableBuilder(
    column: $table.currentScheduledValue,
    builder: (column) => column,
  );

  GeneratedColumn<int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<bool> get isManualOverride => $composableBuilder(
    column: $table.isManualOverride,
    builder: (column) => column,
  );

  $$CommitmentCyclesTableAnnotationComposer get cycleId {
    final $$CommitmentCyclesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cycleId,
      referencedTable: $db.commitmentCycles,
      getReferencedColumn: (t) => t.id,
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
    return composer;
  }

  $$ScheduleDefinitionsTableAnnotationComposer get scheduleDefinitionId {
    final $$ScheduleDefinitionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.scheduleDefinitionId,
          referencedTable: $db.scheduleDefinitions,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ScheduleDefinitionsTableAnnotationComposer(
                $db: $db,
                $table: $db.scheduleDefinitions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$OccurrencesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OccurrencesTable,
          Occurrence,
          $$OccurrencesTableFilterComposer,
          $$OccurrencesTableOrderingComposer,
          $$OccurrencesTableAnnotationComposer,
          $$OccurrencesTableCreateCompanionBuilder,
          $$OccurrencesTableUpdateCompanionBuilder,
          (Occurrence, $$OccurrencesTableReferences),
          Occurrence,
          PrefetchHooks Function({bool cycleId, bool scheduleDefinitionId})
        > {
  $$OccurrencesTableTableManager(_$AppDatabase db, $OccurrencesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OccurrencesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OccurrencesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OccurrencesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> cycleId = const Value.absent(),
                Value<String> scheduleDefinitionId = const Value.absent(),
                Value<String> occurrenceKey = const Value.absent(),
                Value<int> timeSemantics = const Value.absent(),
                Value<String> originalScheduledValue = const Value.absent(),
                Value<String> currentScheduledValue = const Value.absent(),
                Value<int> status = const Value.absent(),
                Value<bool> isManualOverride = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OccurrencesCompanion(
                id: id,
                cycleId: cycleId,
                scheduleDefinitionId: scheduleDefinitionId,
                occurrenceKey: occurrenceKey,
                timeSemantics: timeSemantics,
                originalScheduledValue: originalScheduledValue,
                currentScheduledValue: currentScheduledValue,
                status: status,
                isManualOverride: isManualOverride,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String cycleId,
                required String scheduleDefinitionId,
                required String occurrenceKey,
                required int timeSemantics,
                required String originalScheduledValue,
                required String currentScheduledValue,
                required int status,
                required bool isManualOverride,
                Value<int> rowid = const Value.absent(),
              }) => OccurrencesCompanion.insert(
                id: id,
                cycleId: cycleId,
                scheduleDefinitionId: scheduleDefinitionId,
                occurrenceKey: occurrenceKey,
                timeSemantics: timeSemantics,
                originalScheduledValue: originalScheduledValue,
                currentScheduledValue: currentScheduledValue,
                status: status,
                isManualOverride: isManualOverride,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OccurrencesTable, Occurrence>(table),
                  $$OccurrencesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({cycleId = false, scheduleDefinitionId = false}) {
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
                        if (cycleId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.cycleId,
                            referencedTable: $$OccurrencesTableReferences
                                ._cycleIdTable(db),
                            referencedColumn: $$OccurrencesTableReferences
                                ._cycleIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (scheduleDefinitionId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.scheduleDefinitionId,
                            referencedTable: $$OccurrencesTableReferences
                                ._scheduleDefinitionIdTable(db),
                            referencedColumn: $$OccurrencesTableReferences
                                ._scheduleDefinitionIdTable(db)
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

typedef $$OccurrencesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OccurrencesTable,
      Occurrence,
      $$OccurrencesTableFilterComposer,
      $$OccurrencesTableOrderingComposer,
      $$OccurrencesTableAnnotationComposer,
      $$OccurrencesTableCreateCompanionBuilder,
      $$OccurrencesTableUpdateCompanionBuilder,
      (Occurrence, $$OccurrencesTableReferences),
      Occurrence,
      PrefetchHooks Function({bool cycleId, bool scheduleDefinitionId})
    >;
typedef $$EntitlementPlansTableCreateCompanionBuilder =
    EntitlementPlansCompanion Function({
      required String id,
      required String cycleId,
      required int totalUnits,
      required int unitType,
      required DateTime validFrom,
      Value<DateTime?> plannedExpiry,
      required bool autoExtend,
      Value<int> rowid,
    });
typedef $$EntitlementPlansTableUpdateCompanionBuilder =
    EntitlementPlansCompanion Function({
      Value<String> id,
      Value<String> cycleId,
      Value<int> totalUnits,
      Value<int> unitType,
      Value<DateTime> validFrom,
      Value<DateTime?> plannedExpiry,
      Value<bool> autoExtend,
      Value<int> rowid,
    });

final class $$EntitlementPlansTableReferences
    extends
        BaseReferences<_$AppDatabase, $EntitlementPlansTable, EntitlementPlan> {
  $$EntitlementPlansTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CommitmentCyclesTable _cycleIdTable(_$AppDatabase db) => db
      .commitmentCycles
      .createAlias('entitlement_plans__cycle_id__commitment_cycles__id');

  $$CommitmentCyclesTableProcessedTableManager get cycleId {
    final $_column = $_itemColumn<String>('cycle_id')!;

    final manager = $$CommitmentCyclesTableTableManager(
      $_db,
      $_db.commitmentCycles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_cycleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $EntitlementLedgerEntriesTable,
    List<EntitlementLedgerEntry>
  >
  _entitlementLedgerEntriesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.entitlementLedgerEntries,
        aliasName: 'entitlement_plans__id__entitlement_ledger_entries__plan_id',
      );

  $$EntitlementLedgerEntriesTableProcessedTableManager
  get entitlementLedgerEntriesRefs {
    final manager = $$EntitlementLedgerEntriesTableTableManager(
      $_db,
      $_db.entitlementLedgerEntries,
    ).filter((f) => f.planId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _entitlementLedgerEntriesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$EntitlementPlansTableFilterComposer
    extends Composer<_$AppDatabase, $EntitlementPlansTable> {
  $$EntitlementPlansTableFilterComposer({
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

  ColumnFilters<int> get totalUnits => $composableBuilder(
    column: $table.totalUnits,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get unitType => $composableBuilder(
    column: $table.unitType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get validFrom => $composableBuilder(
    column: $table.validFrom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get plannedExpiry => $composableBuilder(
    column: $table.plannedExpiry,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get autoExtend => $composableBuilder(
    column: $table.autoExtend,
    builder: (column) => ColumnFilters(column),
  );

  $$CommitmentCyclesTableFilterComposer get cycleId {
    final $$CommitmentCyclesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cycleId,
      referencedTable: $db.commitmentCycles,
      getReferencedColumn: (t) => t.id,
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
    return composer;
  }

  Expression<bool> entitlementLedgerEntriesRefs(
    Expression<bool> Function($$EntitlementLedgerEntriesTableFilterComposer f)
    f,
  ) {
    final $$EntitlementLedgerEntriesTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.entitlementLedgerEntries,
          getReferencedColumn: (t) => t.planId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$EntitlementLedgerEntriesTableFilterComposer(
                $db: $db,
                $table: $db.entitlementLedgerEntries,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$EntitlementPlansTableOrderingComposer
    extends Composer<_$AppDatabase, $EntitlementPlansTable> {
  $$EntitlementPlansTableOrderingComposer({
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

  ColumnOrderings<int> get totalUnits => $composableBuilder(
    column: $table.totalUnits,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get unitType => $composableBuilder(
    column: $table.unitType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get validFrom => $composableBuilder(
    column: $table.validFrom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get plannedExpiry => $composableBuilder(
    column: $table.plannedExpiry,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get autoExtend => $composableBuilder(
    column: $table.autoExtend,
    builder: (column) => ColumnOrderings(column),
  );

  $$CommitmentCyclesTableOrderingComposer get cycleId {
    final $$CommitmentCyclesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cycleId,
      referencedTable: $db.commitmentCycles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CommitmentCyclesTableOrderingComposer(
            $db: $db,
            $table: $db.commitmentCycles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EntitlementPlansTableAnnotationComposer
    extends Composer<_$AppDatabase, $EntitlementPlansTable> {
  $$EntitlementPlansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get totalUnits => $composableBuilder(
    column: $table.totalUnits,
    builder: (column) => column,
  );

  GeneratedColumn<int> get unitType =>
      $composableBuilder(column: $table.unitType, builder: (column) => column);

  GeneratedColumn<DateTime> get validFrom =>
      $composableBuilder(column: $table.validFrom, builder: (column) => column);

  GeneratedColumn<DateTime> get plannedExpiry => $composableBuilder(
    column: $table.plannedExpiry,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get autoExtend => $composableBuilder(
    column: $table.autoExtend,
    builder: (column) => column,
  );

  $$CommitmentCyclesTableAnnotationComposer get cycleId {
    final $$CommitmentCyclesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cycleId,
      referencedTable: $db.commitmentCycles,
      getReferencedColumn: (t) => t.id,
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
    return composer;
  }

  Expression<T> entitlementLedgerEntriesRefs<T extends Object>(
    Expression<T> Function($$EntitlementLedgerEntriesTableAnnotationComposer a)
    f,
  ) {
    final $$EntitlementLedgerEntriesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.entitlementLedgerEntries,
          getReferencedColumn: (t) => t.planId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$EntitlementLedgerEntriesTableAnnotationComposer(
                $db: $db,
                $table: $db.entitlementLedgerEntries,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$EntitlementPlansTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EntitlementPlansTable,
          EntitlementPlan,
          $$EntitlementPlansTableFilterComposer,
          $$EntitlementPlansTableOrderingComposer,
          $$EntitlementPlansTableAnnotationComposer,
          $$EntitlementPlansTableCreateCompanionBuilder,
          $$EntitlementPlansTableUpdateCompanionBuilder,
          (EntitlementPlan, $$EntitlementPlansTableReferences),
          EntitlementPlan,
          PrefetchHooks Function({
            bool cycleId,
            bool entitlementLedgerEntriesRefs,
          })
        > {
  $$EntitlementPlansTableTableManager(
    _$AppDatabase db,
    $EntitlementPlansTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EntitlementPlansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EntitlementPlansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EntitlementPlansTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> cycleId = const Value.absent(),
                Value<int> totalUnits = const Value.absent(),
                Value<int> unitType = const Value.absent(),
                Value<DateTime> validFrom = const Value.absent(),
                Value<DateTime?> plannedExpiry = const Value.absent(),
                Value<bool> autoExtend = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EntitlementPlansCompanion(
                id: id,
                cycleId: cycleId,
                totalUnits: totalUnits,
                unitType: unitType,
                validFrom: validFrom,
                plannedExpiry: plannedExpiry,
                autoExtend: autoExtend,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String cycleId,
                required int totalUnits,
                required int unitType,
                required DateTime validFrom,
                Value<DateTime?> plannedExpiry = const Value.absent(),
                required bool autoExtend,
                Value<int> rowid = const Value.absent(),
              }) => EntitlementPlansCompanion.insert(
                id: id,
                cycleId: cycleId,
                totalUnits: totalUnits,
                unitType: unitType,
                validFrom: validFrom,
                plannedExpiry: plannedExpiry,
                autoExtend: autoExtend,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$EntitlementPlansTable, EntitlementPlan>(table),
                  $$EntitlementPlansTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({cycleId = false, entitlementLedgerEntriesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (entitlementLedgerEntriesRefs)
                      db.entitlementLedgerEntries,
                  ],
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
                        if (cycleId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.cycleId,
                            referencedTable: $$EntitlementPlansTableReferences
                                ._cycleIdTable(db),
                            referencedColumn: $$EntitlementPlansTableReferences
                                ._cycleIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (entitlementLedgerEntriesRefs)
                        await $_getPrefetchedData<
                          EntitlementPlan,
                          $EntitlementPlansTable,
                          EntitlementLedgerEntry
                        >(
                          currentTable: table,
                          referencedTable: $$EntitlementPlansTableReferences
                              ._entitlementLedgerEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EntitlementPlansTableReferences(
                                db,
                                table,
                                p0,
                              ).entitlementLedgerEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.planId == item.id,
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

typedef $$EntitlementPlansTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EntitlementPlansTable,
      EntitlementPlan,
      $$EntitlementPlansTableFilterComposer,
      $$EntitlementPlansTableOrderingComposer,
      $$EntitlementPlansTableAnnotationComposer,
      $$EntitlementPlansTableCreateCompanionBuilder,
      $$EntitlementPlansTableUpdateCompanionBuilder,
      (EntitlementPlan, $$EntitlementPlansTableReferences),
      EntitlementPlan,
      PrefetchHooks Function({bool cycleId, bool entitlementLedgerEntriesRefs})
    >;
typedef $$EntitlementLedgerEntriesTableCreateCompanionBuilder =
    EntitlementLedgerEntriesCompanion Function({
      required String id,
      required String planId,
      required int type,
      required int units,
      required DateTime occurredAt,
      Value<String?> referenceId,
      Value<String?> note,
      Value<int> rowid,
    });
typedef $$EntitlementLedgerEntriesTableUpdateCompanionBuilder =
    EntitlementLedgerEntriesCompanion Function({
      Value<String> id,
      Value<String> planId,
      Value<int> type,
      Value<int> units,
      Value<DateTime> occurredAt,
      Value<String?> referenceId,
      Value<String?> note,
      Value<int> rowid,
    });

final class $$EntitlementLedgerEntriesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $EntitlementLedgerEntriesTable,
          EntitlementLedgerEntry
        > {
  $$EntitlementLedgerEntriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $EntitlementPlansTable _planIdTable(_$AppDatabase db) =>
      db.entitlementPlans.createAlias(
        'entitlement_ledger_entries__plan_id__entitlement_plans__id',
      );

  $$EntitlementPlansTableProcessedTableManager get planId {
    final $_column = $_itemColumn<String>('plan_id')!;

    final manager = $$EntitlementPlansTableTableManager(
      $_db,
      $_db.entitlementPlans,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_planIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$EntitlementLedgerEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $EntitlementLedgerEntriesTable> {
  $$EntitlementLedgerEntriesTableFilterComposer({
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

  ColumnFilters<int> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get units => $composableBuilder(
    column: $table.units,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get referenceId => $composableBuilder(
    column: $table.referenceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  $$EntitlementPlansTableFilterComposer get planId {
    final $$EntitlementPlansTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.planId,
      referencedTable: $db.entitlementPlans,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntitlementPlansTableFilterComposer(
            $db: $db,
            $table: $db.entitlementPlans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EntitlementLedgerEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $EntitlementLedgerEntriesTable> {
  $$EntitlementLedgerEntriesTableOrderingComposer({
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

  ColumnOrderings<int> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get units => $composableBuilder(
    column: $table.units,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get referenceId => $composableBuilder(
    column: $table.referenceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  $$EntitlementPlansTableOrderingComposer get planId {
    final $$EntitlementPlansTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.planId,
      referencedTable: $db.entitlementPlans,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntitlementPlansTableOrderingComposer(
            $db: $db,
            $table: $db.entitlementPlans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EntitlementLedgerEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $EntitlementLedgerEntriesTable> {
  $$EntitlementLedgerEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get units =>
      $composableBuilder(column: $table.units, builder: (column) => column);

  GeneratedColumn<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get referenceId => $composableBuilder(
    column: $table.referenceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  $$EntitlementPlansTableAnnotationComposer get planId {
    final $$EntitlementPlansTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.planId,
      referencedTable: $db.entitlementPlans,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntitlementPlansTableAnnotationComposer(
            $db: $db,
            $table: $db.entitlementPlans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EntitlementLedgerEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EntitlementLedgerEntriesTable,
          EntitlementLedgerEntry,
          $$EntitlementLedgerEntriesTableFilterComposer,
          $$EntitlementLedgerEntriesTableOrderingComposer,
          $$EntitlementLedgerEntriesTableAnnotationComposer,
          $$EntitlementLedgerEntriesTableCreateCompanionBuilder,
          $$EntitlementLedgerEntriesTableUpdateCompanionBuilder,
          (EntitlementLedgerEntry, $$EntitlementLedgerEntriesTableReferences),
          EntitlementLedgerEntry,
          PrefetchHooks Function({bool planId})
        > {
  $$EntitlementLedgerEntriesTableTableManager(
    _$AppDatabase db,
    $EntitlementLedgerEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EntitlementLedgerEntriesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$EntitlementLedgerEntriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$EntitlementLedgerEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> planId = const Value.absent(),
                Value<int> type = const Value.absent(),
                Value<int> units = const Value.absent(),
                Value<DateTime> occurredAt = const Value.absent(),
                Value<String?> referenceId = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EntitlementLedgerEntriesCompanion(
                id: id,
                planId: planId,
                type: type,
                units: units,
                occurredAt: occurredAt,
                referenceId: referenceId,
                note: note,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String planId,
                required int type,
                required int units,
                required DateTime occurredAt,
                Value<String?> referenceId = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EntitlementLedgerEntriesCompanion.insert(
                id: id,
                planId: planId,
                type: type,
                units: units,
                occurredAt: occurredAt,
                referenceId: referenceId,
                note: note,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $EntitlementLedgerEntriesTable,
                    EntitlementLedgerEntry
                  >(table),
                  $$EntitlementLedgerEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({planId = false}) {
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
                    if (planId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.planId,
                        referencedTable:
                            $$EntitlementLedgerEntriesTableReferences
                                ._planIdTable(db),
                        referencedColumn:
                            $$EntitlementLedgerEntriesTableReferences
                                ._planIdTable(db)
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

typedef $$EntitlementLedgerEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EntitlementLedgerEntriesTable,
      EntitlementLedgerEntry,
      $$EntitlementLedgerEntriesTableFilterComposer,
      $$EntitlementLedgerEntriesTableOrderingComposer,
      $$EntitlementLedgerEntriesTableAnnotationComposer,
      $$EntitlementLedgerEntriesTableCreateCompanionBuilder,
      $$EntitlementLedgerEntriesTableUpdateCompanionBuilder,
      (EntitlementLedgerEntry, $$EntitlementLedgerEntriesTableReferences),
      EntitlementLedgerEntry,
      PrefetchHooks Function({bool planId})
    >;
typedef $$SessionPoliciesTableCreateCompanionBuilder =
    SessionPoliciesCompanion Function({
      required String id,
      required String cycleId,
      required bool providerCancellationConsumes,
      required int userCancellationNoticeHours,
      required bool lateCancellationConsumes,
      required bool noShowConsumes,
      required int freeAbsenceQuota,
      required bool holidayConsumes,
      required bool makeupRequired,
      required bool autoExtendUntilUnitsConsumed,
      Value<DateTime?> maxExtensionDate,
      required bool partialUnitAllowed,
      Value<int> rowid,
    });
typedef $$SessionPoliciesTableUpdateCompanionBuilder =
    SessionPoliciesCompanion Function({
      Value<String> id,
      Value<String> cycleId,
      Value<bool> providerCancellationConsumes,
      Value<int> userCancellationNoticeHours,
      Value<bool> lateCancellationConsumes,
      Value<bool> noShowConsumes,
      Value<int> freeAbsenceQuota,
      Value<bool> holidayConsumes,
      Value<bool> makeupRequired,
      Value<bool> autoExtendUntilUnitsConsumed,
      Value<DateTime?> maxExtensionDate,
      Value<bool> partialUnitAllowed,
      Value<int> rowid,
    });

final class $$SessionPoliciesTableReferences
    extends
        BaseReferences<_$AppDatabase, $SessionPoliciesTable, SessionPolicy> {
  $$SessionPoliciesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CommitmentCyclesTable _cycleIdTable(_$AppDatabase db) => db
      .commitmentCycles
      .createAlias('session_policies__cycle_id__commitment_cycles__id');

  $$CommitmentCyclesTableProcessedTableManager get cycleId {
    final $_column = $_itemColumn<String>('cycle_id')!;

    final manager = $$CommitmentCyclesTableTableManager(
      $_db,
      $_db.commitmentCycles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_cycleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SessionPoliciesTableFilterComposer
    extends Composer<_$AppDatabase, $SessionPoliciesTable> {
  $$SessionPoliciesTableFilterComposer({
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

  ColumnFilters<bool> get providerCancellationConsumes => $composableBuilder(
    column: $table.providerCancellationConsumes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get userCancellationNoticeHours => $composableBuilder(
    column: $table.userCancellationNoticeHours,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get lateCancellationConsumes => $composableBuilder(
    column: $table.lateCancellationConsumes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get noShowConsumes => $composableBuilder(
    column: $table.noShowConsumes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get freeAbsenceQuota => $composableBuilder(
    column: $table.freeAbsenceQuota,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get holidayConsumes => $composableBuilder(
    column: $table.holidayConsumes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get makeupRequired => $composableBuilder(
    column: $table.makeupRequired,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get autoExtendUntilUnitsConsumed => $composableBuilder(
    column: $table.autoExtendUntilUnitsConsumed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get maxExtensionDate => $composableBuilder(
    column: $table.maxExtensionDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get partialUnitAllowed => $composableBuilder(
    column: $table.partialUnitAllowed,
    builder: (column) => ColumnFilters(column),
  );

  $$CommitmentCyclesTableFilterComposer get cycleId {
    final $$CommitmentCyclesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cycleId,
      referencedTable: $db.commitmentCycles,
      getReferencedColumn: (t) => t.id,
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
    return composer;
  }
}

class $$SessionPoliciesTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionPoliciesTable> {
  $$SessionPoliciesTableOrderingComposer({
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

  ColumnOrderings<bool> get providerCancellationConsumes => $composableBuilder(
    column: $table.providerCancellationConsumes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get userCancellationNoticeHours => $composableBuilder(
    column: $table.userCancellationNoticeHours,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get lateCancellationConsumes => $composableBuilder(
    column: $table.lateCancellationConsumes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get noShowConsumes => $composableBuilder(
    column: $table.noShowConsumes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get freeAbsenceQuota => $composableBuilder(
    column: $table.freeAbsenceQuota,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get holidayConsumes => $composableBuilder(
    column: $table.holidayConsumes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get makeupRequired => $composableBuilder(
    column: $table.makeupRequired,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get autoExtendUntilUnitsConsumed => $composableBuilder(
    column: $table.autoExtendUntilUnitsConsumed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get maxExtensionDate => $composableBuilder(
    column: $table.maxExtensionDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get partialUnitAllowed => $composableBuilder(
    column: $table.partialUnitAllowed,
    builder: (column) => ColumnOrderings(column),
  );

  $$CommitmentCyclesTableOrderingComposer get cycleId {
    final $$CommitmentCyclesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cycleId,
      referencedTable: $db.commitmentCycles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CommitmentCyclesTableOrderingComposer(
            $db: $db,
            $table: $db.commitmentCycles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SessionPoliciesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionPoliciesTable> {
  $$SessionPoliciesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<bool> get providerCancellationConsumes => $composableBuilder(
    column: $table.providerCancellationConsumes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get userCancellationNoticeHours => $composableBuilder(
    column: $table.userCancellationNoticeHours,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get lateCancellationConsumes => $composableBuilder(
    column: $table.lateCancellationConsumes,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get noShowConsumes => $composableBuilder(
    column: $table.noShowConsumes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get freeAbsenceQuota => $composableBuilder(
    column: $table.freeAbsenceQuota,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get holidayConsumes => $composableBuilder(
    column: $table.holidayConsumes,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get makeupRequired => $composableBuilder(
    column: $table.makeupRequired,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get autoExtendUntilUnitsConsumed => $composableBuilder(
    column: $table.autoExtendUntilUnitsConsumed,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get maxExtensionDate => $composableBuilder(
    column: $table.maxExtensionDate,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get partialUnitAllowed => $composableBuilder(
    column: $table.partialUnitAllowed,
    builder: (column) => column,
  );

  $$CommitmentCyclesTableAnnotationComposer get cycleId {
    final $$CommitmentCyclesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cycleId,
      referencedTable: $db.commitmentCycles,
      getReferencedColumn: (t) => t.id,
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
    return composer;
  }
}

class $$SessionPoliciesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SessionPoliciesTable,
          SessionPolicy,
          $$SessionPoliciesTableFilterComposer,
          $$SessionPoliciesTableOrderingComposer,
          $$SessionPoliciesTableAnnotationComposer,
          $$SessionPoliciesTableCreateCompanionBuilder,
          $$SessionPoliciesTableUpdateCompanionBuilder,
          (SessionPolicy, $$SessionPoliciesTableReferences),
          SessionPolicy,
          PrefetchHooks Function({bool cycleId})
        > {
  $$SessionPoliciesTableTableManager(
    _$AppDatabase db,
    $SessionPoliciesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionPoliciesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionPoliciesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionPoliciesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> cycleId = const Value.absent(),
                Value<bool> providerCancellationConsumes = const Value.absent(),
                Value<int> userCancellationNoticeHours = const Value.absent(),
                Value<bool> lateCancellationConsumes = const Value.absent(),
                Value<bool> noShowConsumes = const Value.absent(),
                Value<int> freeAbsenceQuota = const Value.absent(),
                Value<bool> holidayConsumes = const Value.absent(),
                Value<bool> makeupRequired = const Value.absent(),
                Value<bool> autoExtendUntilUnitsConsumed = const Value.absent(),
                Value<DateTime?> maxExtensionDate = const Value.absent(),
                Value<bool> partialUnitAllowed = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionPoliciesCompanion(
                id: id,
                cycleId: cycleId,
                providerCancellationConsumes: providerCancellationConsumes,
                userCancellationNoticeHours: userCancellationNoticeHours,
                lateCancellationConsumes: lateCancellationConsumes,
                noShowConsumes: noShowConsumes,
                freeAbsenceQuota: freeAbsenceQuota,
                holidayConsumes: holidayConsumes,
                makeupRequired: makeupRequired,
                autoExtendUntilUnitsConsumed: autoExtendUntilUnitsConsumed,
                maxExtensionDate: maxExtensionDate,
                partialUnitAllowed: partialUnitAllowed,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String cycleId,
                required bool providerCancellationConsumes,
                required int userCancellationNoticeHours,
                required bool lateCancellationConsumes,
                required bool noShowConsumes,
                required int freeAbsenceQuota,
                required bool holidayConsumes,
                required bool makeupRequired,
                required bool autoExtendUntilUnitsConsumed,
                Value<DateTime?> maxExtensionDate = const Value.absent(),
                required bool partialUnitAllowed,
                Value<int> rowid = const Value.absent(),
              }) => SessionPoliciesCompanion.insert(
                id: id,
                cycleId: cycleId,
                providerCancellationConsumes: providerCancellationConsumes,
                userCancellationNoticeHours: userCancellationNoticeHours,
                lateCancellationConsumes: lateCancellationConsumes,
                noShowConsumes: noShowConsumes,
                freeAbsenceQuota: freeAbsenceQuota,
                holidayConsumes: holidayConsumes,
                makeupRequired: makeupRequired,
                autoExtendUntilUnitsConsumed: autoExtendUntilUnitsConsumed,
                maxExtensionDate: maxExtensionDate,
                partialUnitAllowed: partialUnitAllowed,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SessionPoliciesTable, SessionPolicy>(table),
                  $$SessionPoliciesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({cycleId = false}) {
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
                    if (cycleId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.cycleId,
                        referencedTable: $$SessionPoliciesTableReferences
                            ._cycleIdTable(db),
                        referencedColumn: $$SessionPoliciesTableReferences
                            ._cycleIdTable(db)
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

typedef $$SessionPoliciesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SessionPoliciesTable,
      SessionPolicy,
      $$SessionPoliciesTableFilterComposer,
      $$SessionPoliciesTableOrderingComposer,
      $$SessionPoliciesTableAnnotationComposer,
      $$SessionPoliciesTableCreateCompanionBuilder,
      $$SessionPoliciesTableUpdateCompanionBuilder,
      (SessionPolicy, $$SessionPoliciesTableReferences),
      SessionPolicy,
      PrefetchHooks Function({bool cycleId})
    >;
typedef $$ReplacementOccurrencesTableCreateCompanionBuilder =
    ReplacementOccurrencesCompanion Function({
      required String id,
      required String originalOccurrenceId,
      Value<String?> parentReplacementId,
      required DateTime scheduledAt,
      required int reason,
      required int status,
      Value<int> rowid,
    });
typedef $$ReplacementOccurrencesTableUpdateCompanionBuilder =
    ReplacementOccurrencesCompanion Function({
      Value<String> id,
      Value<String> originalOccurrenceId,
      Value<String?> parentReplacementId,
      Value<DateTime> scheduledAt,
      Value<int> reason,
      Value<int> status,
      Value<int> rowid,
    });

class $$ReplacementOccurrencesTableFilterComposer
    extends Composer<_$AppDatabase, $ReplacementOccurrencesTable> {
  $$ReplacementOccurrencesTableFilterComposer({
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

  ColumnFilters<String> get originalOccurrenceId => $composableBuilder(
    column: $table.originalOccurrenceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parentReplacementId => $composableBuilder(
    column: $table.parentReplacementId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get scheduledAt => $composableBuilder(
    column: $table.scheduledAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReplacementOccurrencesTableOrderingComposer
    extends Composer<_$AppDatabase, $ReplacementOccurrencesTable> {
  $$ReplacementOccurrencesTableOrderingComposer({
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

  ColumnOrderings<String> get originalOccurrenceId => $composableBuilder(
    column: $table.originalOccurrenceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parentReplacementId => $composableBuilder(
    column: $table.parentReplacementId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get scheduledAt => $composableBuilder(
    column: $table.scheduledAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReplacementOccurrencesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReplacementOccurrencesTable> {
  $$ReplacementOccurrencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get originalOccurrenceId => $composableBuilder(
    column: $table.originalOccurrenceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get parentReplacementId => $composableBuilder(
    column: $table.parentReplacementId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get scheduledAt => $composableBuilder(
    column: $table.scheduledAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);
}

class $$ReplacementOccurrencesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReplacementOccurrencesTable,
          ReplacementOccurrence,
          $$ReplacementOccurrencesTableFilterComposer,
          $$ReplacementOccurrencesTableOrderingComposer,
          $$ReplacementOccurrencesTableAnnotationComposer,
          $$ReplacementOccurrencesTableCreateCompanionBuilder,
          $$ReplacementOccurrencesTableUpdateCompanionBuilder,
          (
            ReplacementOccurrence,
            BaseReferences<
              _$AppDatabase,
              $ReplacementOccurrencesTable,
              ReplacementOccurrence
            >,
          ),
          ReplacementOccurrence,
          PrefetchHooks Function()
        > {
  $$ReplacementOccurrencesTableTableManager(
    _$AppDatabase db,
    $ReplacementOccurrencesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReplacementOccurrencesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$ReplacementOccurrencesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ReplacementOccurrencesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> originalOccurrenceId = const Value.absent(),
                Value<String?> parentReplacementId = const Value.absent(),
                Value<DateTime> scheduledAt = const Value.absent(),
                Value<int> reason = const Value.absent(),
                Value<int> status = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReplacementOccurrencesCompanion(
                id: id,
                originalOccurrenceId: originalOccurrenceId,
                parentReplacementId: parentReplacementId,
                scheduledAt: scheduledAt,
                reason: reason,
                status: status,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String originalOccurrenceId,
                Value<String?> parentReplacementId = const Value.absent(),
                required DateTime scheduledAt,
                required int reason,
                required int status,
                Value<int> rowid = const Value.absent(),
              }) => ReplacementOccurrencesCompanion.insert(
                id: id,
                originalOccurrenceId: originalOccurrenceId,
                parentReplacementId: parentReplacementId,
                scheduledAt: scheduledAt,
                reason: reason,
                status: status,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $ReplacementOccurrencesTable,
                    ReplacementOccurrence
                  >(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ReplacementOccurrencesTable,
                    ReplacementOccurrence
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReplacementOccurrencesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReplacementOccurrencesTable,
      ReplacementOccurrence,
      $$ReplacementOccurrencesTableFilterComposer,
      $$ReplacementOccurrencesTableOrderingComposer,
      $$ReplacementOccurrencesTableAnnotationComposer,
      $$ReplacementOccurrencesTableCreateCompanionBuilder,
      $$ReplacementOccurrencesTableUpdateCompanionBuilder,
      (
        ReplacementOccurrence,
        BaseReferences<
          _$AppDatabase,
          $ReplacementOccurrencesTable,
          ReplacementOccurrence
        >,
      ),
      ReplacementOccurrence,
      PrefetchHooks Function()
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
  $$ScheduleDefinitionsTableTableManager get scheduleDefinitions =>
      $$ScheduleDefinitionsTableTableManager(_db, _db.scheduleDefinitions);
  $$OccurrencesTableTableManager get occurrences =>
      $$OccurrencesTableTableManager(_db, _db.occurrences);
  $$EntitlementPlansTableTableManager get entitlementPlans =>
      $$EntitlementPlansTableTableManager(_db, _db.entitlementPlans);
  $$EntitlementLedgerEntriesTableTableManager get entitlementLedgerEntries =>
      $$EntitlementLedgerEntriesTableTableManager(
        _db,
        _db.entitlementLedgerEntries,
      );
  $$SessionPoliciesTableTableManager get sessionPolicies =>
      $$SessionPoliciesTableTableManager(_db, _db.sessionPolicies);
  $$ReplacementOccurrencesTableTableManager get replacementOccurrences =>
      $$ReplacementOccurrencesTableTableManager(
        _db,
        _db.replacementOccurrences,
      );
}
