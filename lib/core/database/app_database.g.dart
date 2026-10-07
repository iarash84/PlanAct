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
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<int> kind = GeneratedColumn<int>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
    'tags',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _attachmentIdsMeta = const VerificationMeta(
    'attachmentIds',
  );
  @override
  late final GeneratedColumn<String> attachmentIds = GeneratedColumn<String>(
    'attachment_ids',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    createdAt,
    status,
    kind,
    priority,
    description,
    tags,
    attachmentIds,
  ];
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
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('tags')) {
      context.handle(
        _tagsMeta,
        tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta),
      );
    }
    if (data.containsKey('attachment_ids')) {
      context.handle(
        _attachmentIdsMeta,
        attachmentIds.isAcceptableOrUnknown(
          data['attachment_ids']!,
          _attachmentIdsMeta,
        ),
      );
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
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}kind'],
      )!,
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}priority'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      tags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags'],
      )!,
      attachmentIds: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}attachment_ids'],
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
  final int kind;
  final int priority;
  final String? description;
  final String tags;
  final String attachmentIds;
  const Commitment({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.status,
    required this.kind,
    required this.priority,
    this.description,
    required this.tags,
    required this.attachmentIds,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['status'] = Variable<int>(status);
    map['kind'] = Variable<int>(kind);
    map['priority'] = Variable<int>(priority);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['tags'] = Variable<String>(tags);
    map['attachment_ids'] = Variable<String>(attachmentIds);
    return map;
  }

  CommitmentsCompanion toCompanion(bool nullToAbsent) {
    return CommitmentsCompanion(
      id: Value(id),
      title: Value(title),
      createdAt: Value(createdAt),
      status: Value(status),
      kind: Value(kind),
      priority: Value(priority),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      tags: Value(tags),
      attachmentIds: Value(attachmentIds),
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
      kind: serializer.fromJson<int>(json['kind']),
      priority: serializer.fromJson<int>(json['priority']),
      description: serializer.fromJson<String?>(json['description']),
      tags: serializer.fromJson<String>(json['tags']),
      attachmentIds: serializer.fromJson<String>(json['attachmentIds']),
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
      'kind': serializer.toJson<int>(kind),
      'priority': serializer.toJson<int>(priority),
      'description': serializer.toJson<String?>(description),
      'tags': serializer.toJson<String>(tags),
      'attachmentIds': serializer.toJson<String>(attachmentIds),
    };
  }

  Commitment copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    int? status,
    int? kind,
    int? priority,
    Value<String?> description = const Value.absent(),
    String? tags,
    String? attachmentIds,
  }) => Commitment(
    id: id ?? this.id,
    title: title ?? this.title,
    createdAt: createdAt ?? this.createdAt,
    status: status ?? this.status,
    kind: kind ?? this.kind,
    priority: priority ?? this.priority,
    description: description.present ? description.value : this.description,
    tags: tags ?? this.tags,
    attachmentIds: attachmentIds ?? this.attachmentIds,
  );
  Commitment copyWithCompanion(CommitmentsCompanion data) {
    return Commitment(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      status: data.status.present ? data.status.value : this.status,
      kind: data.kind.present ? data.kind.value : this.kind,
      priority: data.priority.present ? data.priority.value : this.priority,
      description: data.description.present
          ? data.description.value
          : this.description,
      tags: data.tags.present ? data.tags.value : this.tags,
      attachmentIds: data.attachmentIds.present
          ? data.attachmentIds.value
          : this.attachmentIds,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Commitment(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('createdAt: $createdAt, ')
          ..write('status: $status, ')
          ..write('kind: $kind, ')
          ..write('priority: $priority, ')
          ..write('description: $description, ')
          ..write('tags: $tags, ')
          ..write('attachmentIds: $attachmentIds')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    createdAt,
    status,
    kind,
    priority,
    description,
    tags,
    attachmentIds,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Commitment &&
          other.id == this.id &&
          other.title == this.title &&
          other.createdAt == this.createdAt &&
          other.status == this.status &&
          other.kind == this.kind &&
          other.priority == this.priority &&
          other.description == this.description &&
          other.tags == this.tags &&
          other.attachmentIds == this.attachmentIds);
}

class CommitmentsCompanion extends UpdateCompanion<Commitment> {
  final Value<String> id;
  final Value<String> title;
  final Value<DateTime> createdAt;
  final Value<int> status;
  final Value<int> kind;
  final Value<int> priority;
  final Value<String?> description;
  final Value<String> tags;
  final Value<String> attachmentIds;
  final Value<int> rowid;
  const CommitmentsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.status = const Value.absent(),
    this.kind = const Value.absent(),
    this.priority = const Value.absent(),
    this.description = const Value.absent(),
    this.tags = const Value.absent(),
    this.attachmentIds = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CommitmentsCompanion.insert({
    required String id,
    required String title,
    required DateTime createdAt,
    required int status,
    this.kind = const Value.absent(),
    this.priority = const Value.absent(),
    this.description = const Value.absent(),
    this.tags = const Value.absent(),
    this.attachmentIds = const Value.absent(),
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
    Expression<int>? kind,
    Expression<int>? priority,
    Expression<String>? description,
    Expression<String>? tags,
    Expression<String>? attachmentIds,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (createdAt != null) 'created_at': createdAt,
      if (status != null) 'status': status,
      if (kind != null) 'kind': kind,
      if (priority != null) 'priority': priority,
      if (description != null) 'description': description,
      if (tags != null) 'tags': tags,
      if (attachmentIds != null) 'attachment_ids': attachmentIds,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CommitmentsCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<DateTime>? createdAt,
    Value<int>? status,
    Value<int>? kind,
    Value<int>? priority,
    Value<String?>? description,
    Value<String>? tags,
    Value<String>? attachmentIds,
    Value<int>? rowid,
  }) {
    return CommitmentsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      kind: kind ?? this.kind,
      priority: priority ?? this.priority,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      attachmentIds: attachmentIds ?? this.attachmentIds,
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
    if (kind.present) {
      map['kind'] = Variable<int>(kind.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (attachmentIds.present) {
      map['attachment_ids'] = Variable<String>(attachmentIds.value);
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
          ..write('kind: $kind, ')
          ..write('priority: $priority, ')
          ..write('description: $description, ')
          ..write('tags: $tags, ')
          ..write('attachmentIds: $attachmentIds, ')
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

class $ReminderRulesTable extends ReminderRules
    with TableInfo<$ReminderRulesTable, ReminderRule> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReminderRulesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _occurrenceIdMeta = const VerificationMeta(
    'occurrenceId',
  );
  @override
  late final GeneratedColumn<String> occurrenceId = GeneratedColumn<String>(
    'occurrence_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES occurrences (id)',
    ),
  );
  static const VerificationMeta _anchorMeta = const VerificationMeta('anchor');
  @override
  late final GeneratedColumn<int> anchor = GeneratedColumn<int>(
    'anchor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _offsetSecondsMeta = const VerificationMeta(
    'offsetSeconds',
  );
  @override
  late final GeneratedColumn<int> offsetSeconds = GeneratedColumn<int>(
    'offset_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _absoluteAtMeta = const VerificationMeta(
    'absoluteAt',
  );
  @override
  late final GeneratedColumn<DateTime> absoluteAt = GeneratedColumn<DateTime>(
    'absolute_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    occurrenceId,
    anchor,
    offsetSeconds,
    absoluteAt,
    title,
    body,
    enabled,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reminder_rules';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReminderRule> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('occurrence_id')) {
      context.handle(
        _occurrenceIdMeta,
        occurrenceId.isAcceptableOrUnknown(
          data['occurrence_id']!,
          _occurrenceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_occurrenceIdMeta);
    }
    if (data.containsKey('anchor')) {
      context.handle(
        _anchorMeta,
        anchor.isAcceptableOrUnknown(data['anchor']!, _anchorMeta),
      );
    } else if (isInserting) {
      context.missing(_anchorMeta);
    }
    if (data.containsKey('offset_seconds')) {
      context.handle(
        _offsetSecondsMeta,
        offsetSeconds.isAcceptableOrUnknown(
          data['offset_seconds']!,
          _offsetSecondsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_offsetSecondsMeta);
    }
    if (data.containsKey('absolute_at')) {
      context.handle(
        _absoluteAtMeta,
        absoluteAt.isAcceptableOrUnknown(data['absolute_at']!, _absoluteAtMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    } else if (isInserting) {
      context.missing(_enabledMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReminderRule map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReminderRule(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      occurrenceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}occurrence_id'],
      )!,
      anchor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}anchor'],
      )!,
      offsetSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}offset_seconds'],
      )!,
      absoluteAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}absolute_at'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      ),
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
    );
  }

  @override
  $ReminderRulesTable createAlias(String alias) {
    return $ReminderRulesTable(attachedDatabase, alias);
  }
}

class ReminderRule extends DataClass implements Insertable<ReminderRule> {
  final String id;
  final String occurrenceId;
  final int anchor;
  final int offsetSeconds;
  final DateTime? absoluteAt;
  final String? title;
  final String? body;
  final bool enabled;
  const ReminderRule({
    required this.id,
    required this.occurrenceId,
    required this.anchor,
    required this.offsetSeconds,
    this.absoluteAt,
    this.title,
    this.body,
    required this.enabled,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['occurrence_id'] = Variable<String>(occurrenceId);
    map['anchor'] = Variable<int>(anchor);
    map['offset_seconds'] = Variable<int>(offsetSeconds);
    if (!nullToAbsent || absoluteAt != null) {
      map['absolute_at'] = Variable<DateTime>(absoluteAt);
    }
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    if (!nullToAbsent || body != null) {
      map['body'] = Variable<String>(body);
    }
    map['enabled'] = Variable<bool>(enabled);
    return map;
  }

  ReminderRulesCompanion toCompanion(bool nullToAbsent) {
    return ReminderRulesCompanion(
      id: Value(id),
      occurrenceId: Value(occurrenceId),
      anchor: Value(anchor),
      offsetSeconds: Value(offsetSeconds),
      absoluteAt: absoluteAt == null && nullToAbsent
          ? const Value.absent()
          : Value(absoluteAt),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      body: body == null && nullToAbsent ? const Value.absent() : Value(body),
      enabled: Value(enabled),
    );
  }

  factory ReminderRule.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReminderRule(
      id: serializer.fromJson<String>(json['id']),
      occurrenceId: serializer.fromJson<String>(json['occurrenceId']),
      anchor: serializer.fromJson<int>(json['anchor']),
      offsetSeconds: serializer.fromJson<int>(json['offsetSeconds']),
      absoluteAt: serializer.fromJson<DateTime?>(json['absoluteAt']),
      title: serializer.fromJson<String?>(json['title']),
      body: serializer.fromJson<String?>(json['body']),
      enabled: serializer.fromJson<bool>(json['enabled']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'occurrenceId': serializer.toJson<String>(occurrenceId),
      'anchor': serializer.toJson<int>(anchor),
      'offsetSeconds': serializer.toJson<int>(offsetSeconds),
      'absoluteAt': serializer.toJson<DateTime?>(absoluteAt),
      'title': serializer.toJson<String?>(title),
      'body': serializer.toJson<String?>(body),
      'enabled': serializer.toJson<bool>(enabled),
    };
  }

  ReminderRule copyWith({
    String? id,
    String? occurrenceId,
    int? anchor,
    int? offsetSeconds,
    Value<DateTime?> absoluteAt = const Value.absent(),
    Value<String?> title = const Value.absent(),
    Value<String?> body = const Value.absent(),
    bool? enabled,
  }) => ReminderRule(
    id: id ?? this.id,
    occurrenceId: occurrenceId ?? this.occurrenceId,
    anchor: anchor ?? this.anchor,
    offsetSeconds: offsetSeconds ?? this.offsetSeconds,
    absoluteAt: absoluteAt.present ? absoluteAt.value : this.absoluteAt,
    title: title.present ? title.value : this.title,
    body: body.present ? body.value : this.body,
    enabled: enabled ?? this.enabled,
  );
  ReminderRule copyWithCompanion(ReminderRulesCompanion data) {
    return ReminderRule(
      id: data.id.present ? data.id.value : this.id,
      occurrenceId: data.occurrenceId.present
          ? data.occurrenceId.value
          : this.occurrenceId,
      anchor: data.anchor.present ? data.anchor.value : this.anchor,
      offsetSeconds: data.offsetSeconds.present
          ? data.offsetSeconds.value
          : this.offsetSeconds,
      absoluteAt: data.absoluteAt.present
          ? data.absoluteAt.value
          : this.absoluteAt,
      title: data.title.present ? data.title.value : this.title,
      body: data.body.present ? data.body.value : this.body,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReminderRule(')
          ..write('id: $id, ')
          ..write('occurrenceId: $occurrenceId, ')
          ..write('anchor: $anchor, ')
          ..write('offsetSeconds: $offsetSeconds, ')
          ..write('absoluteAt: $absoluteAt, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('enabled: $enabled')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    occurrenceId,
    anchor,
    offsetSeconds,
    absoluteAt,
    title,
    body,
    enabled,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReminderRule &&
          other.id == this.id &&
          other.occurrenceId == this.occurrenceId &&
          other.anchor == this.anchor &&
          other.offsetSeconds == this.offsetSeconds &&
          other.absoluteAt == this.absoluteAt &&
          other.title == this.title &&
          other.body == this.body &&
          other.enabled == this.enabled);
}

class ReminderRulesCompanion extends UpdateCompanion<ReminderRule> {
  final Value<String> id;
  final Value<String> occurrenceId;
  final Value<int> anchor;
  final Value<int> offsetSeconds;
  final Value<DateTime?> absoluteAt;
  final Value<String?> title;
  final Value<String?> body;
  final Value<bool> enabled;
  final Value<int> rowid;
  const ReminderRulesCompanion({
    this.id = const Value.absent(),
    this.occurrenceId = const Value.absent(),
    this.anchor = const Value.absent(),
    this.offsetSeconds = const Value.absent(),
    this.absoluteAt = const Value.absent(),
    this.title = const Value.absent(),
    this.body = const Value.absent(),
    this.enabled = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReminderRulesCompanion.insert({
    required String id,
    required String occurrenceId,
    required int anchor,
    required int offsetSeconds,
    this.absoluteAt = const Value.absent(),
    this.title = const Value.absent(),
    this.body = const Value.absent(),
    required bool enabled,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       occurrenceId = Value(occurrenceId),
       anchor = Value(anchor),
       offsetSeconds = Value(offsetSeconds),
       enabled = Value(enabled);
  static Insertable<ReminderRule> custom({
    Expression<String>? id,
    Expression<String>? occurrenceId,
    Expression<int>? anchor,
    Expression<int>? offsetSeconds,
    Expression<DateTime>? absoluteAt,
    Expression<String>? title,
    Expression<String>? body,
    Expression<bool>? enabled,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (occurrenceId != null) 'occurrence_id': occurrenceId,
      if (anchor != null) 'anchor': anchor,
      if (offsetSeconds != null) 'offset_seconds': offsetSeconds,
      if (absoluteAt != null) 'absolute_at': absoluteAt,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (enabled != null) 'enabled': enabled,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReminderRulesCompanion copyWith({
    Value<String>? id,
    Value<String>? occurrenceId,
    Value<int>? anchor,
    Value<int>? offsetSeconds,
    Value<DateTime?>? absoluteAt,
    Value<String?>? title,
    Value<String?>? body,
    Value<bool>? enabled,
    Value<int>? rowid,
  }) {
    return ReminderRulesCompanion(
      id: id ?? this.id,
      occurrenceId: occurrenceId ?? this.occurrenceId,
      anchor: anchor ?? this.anchor,
      offsetSeconds: offsetSeconds ?? this.offsetSeconds,
      absoluteAt: absoluteAt ?? this.absoluteAt,
      title: title ?? this.title,
      body: body ?? this.body,
      enabled: enabled ?? this.enabled,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (occurrenceId.present) {
      map['occurrence_id'] = Variable<String>(occurrenceId.value);
    }
    if (anchor.present) {
      map['anchor'] = Variable<int>(anchor.value);
    }
    if (offsetSeconds.present) {
      map['offset_seconds'] = Variable<int>(offsetSeconds.value);
    }
    if (absoluteAt.present) {
      map['absolute_at'] = Variable<DateTime>(absoluteAt.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReminderRulesCompanion(')
          ..write('id: $id, ')
          ..write('occurrenceId: $occurrenceId, ')
          ..write('anchor: $anchor, ')
          ..write('offsetSeconds: $offsetSeconds, ')
          ..write('absoluteAt: $absoluteAt, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('enabled: $enabled, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReminderInstancesTable extends ReminderInstances
    with TableInfo<$ReminderInstancesTable, ReminderInstance> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReminderInstancesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ruleIdMeta = const VerificationMeta('ruleId');
  @override
  late final GeneratedColumn<String> ruleId = GeneratedColumn<String>(
    'rule_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES reminder_rules (id)',
    ),
  );
  static const VerificationMeta _occurrenceIdMeta = const VerificationMeta(
    'occurrenceId',
  );
  @override
  late final GeneratedColumn<String> occurrenceId = GeneratedColumn<String>(
    'occurrence_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES occurrences (id)',
    ),
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
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<int> status = GeneratedColumn<int>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _snoozedUntilMeta = const VerificationMeta(
    'snoozedUntil',
  );
  @override
  late final GeneratedColumn<DateTime> snoozedUntil = GeneratedColumn<DateTime>(
    'snoozed_until',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _platformNotificationIdMeta =
      const VerificationMeta('platformNotificationId');
  @override
  late final GeneratedColumn<String> platformNotificationId =
      GeneratedColumn<String>(
        'platform_notification_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    ruleId,
    occurrenceId,
    scheduledAt,
    status,
    snoozedUntil,
    platformNotificationId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reminder_instances';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReminderInstance> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('rule_id')) {
      context.handle(
        _ruleIdMeta,
        ruleId.isAcceptableOrUnknown(data['rule_id']!, _ruleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ruleIdMeta);
    }
    if (data.containsKey('occurrence_id')) {
      context.handle(
        _occurrenceIdMeta,
        occurrenceId.isAcceptableOrUnknown(
          data['occurrence_id']!,
          _occurrenceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_occurrenceIdMeta);
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
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('snoozed_until')) {
      context.handle(
        _snoozedUntilMeta,
        snoozedUntil.isAcceptableOrUnknown(
          data['snoozed_until']!,
          _snoozedUntilMeta,
        ),
      );
    }
    if (data.containsKey('platform_notification_id')) {
      context.handle(
        _platformNotificationIdMeta,
        platformNotificationId.isAcceptableOrUnknown(
          data['platform_notification_id']!,
          _platformNotificationIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {ruleId, occurrenceId, scheduledAt},
  ];
  @override
  ReminderInstance map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReminderInstance(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      ruleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rule_id'],
      )!,
      occurrenceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}occurrence_id'],
      )!,
      scheduledAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}scheduled_at'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}status'],
      )!,
      snoozedUntil: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}snoozed_until'],
      ),
      platformNotificationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}platform_notification_id'],
      ),
    );
  }

  @override
  $ReminderInstancesTable createAlias(String alias) {
    return $ReminderInstancesTable(attachedDatabase, alias);
  }
}

class ReminderInstance extends DataClass
    implements Insertable<ReminderInstance> {
  final String id;
  final String ruleId;
  final String occurrenceId;
  final DateTime scheduledAt;
  final int status;
  final DateTime? snoozedUntil;
  final String? platformNotificationId;
  const ReminderInstance({
    required this.id,
    required this.ruleId,
    required this.occurrenceId,
    required this.scheduledAt,
    required this.status,
    this.snoozedUntil,
    this.platformNotificationId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['rule_id'] = Variable<String>(ruleId);
    map['occurrence_id'] = Variable<String>(occurrenceId);
    map['scheduled_at'] = Variable<DateTime>(scheduledAt);
    map['status'] = Variable<int>(status);
    if (!nullToAbsent || snoozedUntil != null) {
      map['snoozed_until'] = Variable<DateTime>(snoozedUntil);
    }
    if (!nullToAbsent || platformNotificationId != null) {
      map['platform_notification_id'] = Variable<String>(
        platformNotificationId,
      );
    }
    return map;
  }

  ReminderInstancesCompanion toCompanion(bool nullToAbsent) {
    return ReminderInstancesCompanion(
      id: Value(id),
      ruleId: Value(ruleId),
      occurrenceId: Value(occurrenceId),
      scheduledAt: Value(scheduledAt),
      status: Value(status),
      snoozedUntil: snoozedUntil == null && nullToAbsent
          ? const Value.absent()
          : Value(snoozedUntil),
      platformNotificationId: platformNotificationId == null && nullToAbsent
          ? const Value.absent()
          : Value(platformNotificationId),
    );
  }

  factory ReminderInstance.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReminderInstance(
      id: serializer.fromJson<String>(json['id']),
      ruleId: serializer.fromJson<String>(json['ruleId']),
      occurrenceId: serializer.fromJson<String>(json['occurrenceId']),
      scheduledAt: serializer.fromJson<DateTime>(json['scheduledAt']),
      status: serializer.fromJson<int>(json['status']),
      snoozedUntil: serializer.fromJson<DateTime?>(json['snoozedUntil']),
      platformNotificationId: serializer.fromJson<String?>(
        json['platformNotificationId'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'ruleId': serializer.toJson<String>(ruleId),
      'occurrenceId': serializer.toJson<String>(occurrenceId),
      'scheduledAt': serializer.toJson<DateTime>(scheduledAt),
      'status': serializer.toJson<int>(status),
      'snoozedUntil': serializer.toJson<DateTime?>(snoozedUntil),
      'platformNotificationId': serializer.toJson<String?>(
        platformNotificationId,
      ),
    };
  }

  ReminderInstance copyWith({
    String? id,
    String? ruleId,
    String? occurrenceId,
    DateTime? scheduledAt,
    int? status,
    Value<DateTime?> snoozedUntil = const Value.absent(),
    Value<String?> platformNotificationId = const Value.absent(),
  }) => ReminderInstance(
    id: id ?? this.id,
    ruleId: ruleId ?? this.ruleId,
    occurrenceId: occurrenceId ?? this.occurrenceId,
    scheduledAt: scheduledAt ?? this.scheduledAt,
    status: status ?? this.status,
    snoozedUntil: snoozedUntil.present ? snoozedUntil.value : this.snoozedUntil,
    platformNotificationId: platformNotificationId.present
        ? platformNotificationId.value
        : this.platformNotificationId,
  );
  ReminderInstance copyWithCompanion(ReminderInstancesCompanion data) {
    return ReminderInstance(
      id: data.id.present ? data.id.value : this.id,
      ruleId: data.ruleId.present ? data.ruleId.value : this.ruleId,
      occurrenceId: data.occurrenceId.present
          ? data.occurrenceId.value
          : this.occurrenceId,
      scheduledAt: data.scheduledAt.present
          ? data.scheduledAt.value
          : this.scheduledAt,
      status: data.status.present ? data.status.value : this.status,
      snoozedUntil: data.snoozedUntil.present
          ? data.snoozedUntil.value
          : this.snoozedUntil,
      platformNotificationId: data.platformNotificationId.present
          ? data.platformNotificationId.value
          : this.platformNotificationId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReminderInstance(')
          ..write('id: $id, ')
          ..write('ruleId: $ruleId, ')
          ..write('occurrenceId: $occurrenceId, ')
          ..write('scheduledAt: $scheduledAt, ')
          ..write('status: $status, ')
          ..write('snoozedUntil: $snoozedUntil, ')
          ..write('platformNotificationId: $platformNotificationId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    ruleId,
    occurrenceId,
    scheduledAt,
    status,
    snoozedUntil,
    platformNotificationId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReminderInstance &&
          other.id == this.id &&
          other.ruleId == this.ruleId &&
          other.occurrenceId == this.occurrenceId &&
          other.scheduledAt == this.scheduledAt &&
          other.status == this.status &&
          other.snoozedUntil == this.snoozedUntil &&
          other.platformNotificationId == this.platformNotificationId);
}

class ReminderInstancesCompanion extends UpdateCompanion<ReminderInstance> {
  final Value<String> id;
  final Value<String> ruleId;
  final Value<String> occurrenceId;
  final Value<DateTime> scheduledAt;
  final Value<int> status;
  final Value<DateTime?> snoozedUntil;
  final Value<String?> platformNotificationId;
  final Value<int> rowid;
  const ReminderInstancesCompanion({
    this.id = const Value.absent(),
    this.ruleId = const Value.absent(),
    this.occurrenceId = const Value.absent(),
    this.scheduledAt = const Value.absent(),
    this.status = const Value.absent(),
    this.snoozedUntil = const Value.absent(),
    this.platformNotificationId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReminderInstancesCompanion.insert({
    required String id,
    required String ruleId,
    required String occurrenceId,
    required DateTime scheduledAt,
    required int status,
    this.snoozedUntil = const Value.absent(),
    this.platformNotificationId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       ruleId = Value(ruleId),
       occurrenceId = Value(occurrenceId),
       scheduledAt = Value(scheduledAt),
       status = Value(status);
  static Insertable<ReminderInstance> custom({
    Expression<String>? id,
    Expression<String>? ruleId,
    Expression<String>? occurrenceId,
    Expression<DateTime>? scheduledAt,
    Expression<int>? status,
    Expression<DateTime>? snoozedUntil,
    Expression<String>? platformNotificationId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ruleId != null) 'rule_id': ruleId,
      if (occurrenceId != null) 'occurrence_id': occurrenceId,
      if (scheduledAt != null) 'scheduled_at': scheduledAt,
      if (status != null) 'status': status,
      if (snoozedUntil != null) 'snoozed_until': snoozedUntil,
      if (platformNotificationId != null)
        'platform_notification_id': platformNotificationId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReminderInstancesCompanion copyWith({
    Value<String>? id,
    Value<String>? ruleId,
    Value<String>? occurrenceId,
    Value<DateTime>? scheduledAt,
    Value<int>? status,
    Value<DateTime?>? snoozedUntil,
    Value<String?>? platformNotificationId,
    Value<int>? rowid,
  }) {
    return ReminderInstancesCompanion(
      id: id ?? this.id,
      ruleId: ruleId ?? this.ruleId,
      occurrenceId: occurrenceId ?? this.occurrenceId,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      status: status ?? this.status,
      snoozedUntil: snoozedUntil ?? this.snoozedUntil,
      platformNotificationId:
          platformNotificationId ?? this.platformNotificationId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (ruleId.present) {
      map['rule_id'] = Variable<String>(ruleId.value);
    }
    if (occurrenceId.present) {
      map['occurrence_id'] = Variable<String>(occurrenceId.value);
    }
    if (scheduledAt.present) {
      map['scheduled_at'] = Variable<DateTime>(scheduledAt.value);
    }
    if (status.present) {
      map['status'] = Variable<int>(status.value);
    }
    if (snoozedUntil.present) {
      map['snoozed_until'] = Variable<DateTime>(snoozedUntil.value);
    }
    if (platformNotificationId.present) {
      map['platform_notification_id'] = Variable<String>(
        platformNotificationId.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReminderInstancesCompanion(')
          ..write('id: $id, ')
          ..write('ruleId: $ruleId, ')
          ..write('occurrenceId: $occurrenceId, ')
          ..write('scheduledAt: $scheduledAt, ')
          ..write('status: $status, ')
          ..write('snoozedUntil: $snoozedUntil, ')
          ..write('platformNotificationId: $platformNotificationId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ActualsTable extends Actuals with TableInfo<$ActualsTable, Actual> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ActualsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _occurrenceIdMeta = const VerificationMeta(
    'occurrenceId',
  );
  @override
  late final GeneratedColumn<String> occurrenceId = GeneratedColumn<String>(
    'occurrence_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES occurrences (id)',
    ),
  );
  static const VerificationMeta _outcomeMeta = const VerificationMeta(
    'outcome',
  );
  @override
  late final GeneratedColumn<int> outcome = GeneratedColumn<int>(
    'outcome',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordedAtMeta = const VerificationMeta(
    'recordedAt',
  );
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
    'recorded_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
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
    occurrenceId,
    outcome,
    recordedAt,
    note,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'actuals';
  @override
  VerificationContext validateIntegrity(
    Insertable<Actual> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('occurrence_id')) {
      context.handle(
        _occurrenceIdMeta,
        occurrenceId.isAcceptableOrUnknown(
          data['occurrence_id']!,
          _occurrenceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_occurrenceIdMeta);
    }
    if (data.containsKey('outcome')) {
      context.handle(
        _outcomeMeta,
        outcome.isAcceptableOrUnknown(data['outcome']!, _outcomeMeta),
      );
    } else if (isInserting) {
      context.missing(_outcomeMeta);
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
        _recordedAtMeta,
        recordedAt.isAcceptableOrUnknown(data['recorded_at']!, _recordedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_recordedAtMeta);
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
  Actual map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Actual(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      occurrenceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}occurrence_id'],
      )!,
      outcome: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}outcome'],
      )!,
      recordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}recorded_at'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
    );
  }

  @override
  $ActualsTable createAlias(String alias) {
    return $ActualsTable(attachedDatabase, alias);
  }
}

class Actual extends DataClass implements Insertable<Actual> {
  final String id;
  final String occurrenceId;
  final int outcome;
  final DateTime recordedAt;
  final String? note;
  const Actual({
    required this.id,
    required this.occurrenceId,
    required this.outcome,
    required this.recordedAt,
    this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['occurrence_id'] = Variable<String>(occurrenceId);
    map['outcome'] = Variable<int>(outcome);
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  ActualsCompanion toCompanion(bool nullToAbsent) {
    return ActualsCompanion(
      id: Value(id),
      occurrenceId: Value(occurrenceId),
      outcome: Value(outcome),
      recordedAt: Value(recordedAt),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory Actual.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Actual(
      id: serializer.fromJson<String>(json['id']),
      occurrenceId: serializer.fromJson<String>(json['occurrenceId']),
      outcome: serializer.fromJson<int>(json['outcome']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'occurrenceId': serializer.toJson<String>(occurrenceId),
      'outcome': serializer.toJson<int>(outcome),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
      'note': serializer.toJson<String?>(note),
    };
  }

  Actual copyWith({
    String? id,
    String? occurrenceId,
    int? outcome,
    DateTime? recordedAt,
    Value<String?> note = const Value.absent(),
  }) => Actual(
    id: id ?? this.id,
    occurrenceId: occurrenceId ?? this.occurrenceId,
    outcome: outcome ?? this.outcome,
    recordedAt: recordedAt ?? this.recordedAt,
    note: note.present ? note.value : this.note,
  );
  Actual copyWithCompanion(ActualsCompanion data) {
    return Actual(
      id: data.id.present ? data.id.value : this.id,
      occurrenceId: data.occurrenceId.present
          ? data.occurrenceId.value
          : this.occurrenceId,
      outcome: data.outcome.present ? data.outcome.value : this.outcome,
      recordedAt: data.recordedAt.present
          ? data.recordedAt.value
          : this.recordedAt,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Actual(')
          ..write('id: $id, ')
          ..write('occurrenceId: $occurrenceId, ')
          ..write('outcome: $outcome, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, occurrenceId, outcome, recordedAt, note);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Actual &&
          other.id == this.id &&
          other.occurrenceId == this.occurrenceId &&
          other.outcome == this.outcome &&
          other.recordedAt == this.recordedAt &&
          other.note == this.note);
}

class ActualsCompanion extends UpdateCompanion<Actual> {
  final Value<String> id;
  final Value<String> occurrenceId;
  final Value<int> outcome;
  final Value<DateTime> recordedAt;
  final Value<String?> note;
  final Value<int> rowid;
  const ActualsCompanion({
    this.id = const Value.absent(),
    this.occurrenceId = const Value.absent(),
    this.outcome = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ActualsCompanion.insert({
    required String id,
    required String occurrenceId,
    required int outcome,
    required DateTime recordedAt,
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       occurrenceId = Value(occurrenceId),
       outcome = Value(outcome),
       recordedAt = Value(recordedAt);
  static Insertable<Actual> custom({
    Expression<String>? id,
    Expression<String>? occurrenceId,
    Expression<int>? outcome,
    Expression<DateTime>? recordedAt,
    Expression<String>? note,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (occurrenceId != null) 'occurrence_id': occurrenceId,
      if (outcome != null) 'outcome': outcome,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (note != null) 'note': note,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ActualsCompanion copyWith({
    Value<String>? id,
    Value<String>? occurrenceId,
    Value<int>? outcome,
    Value<DateTime>? recordedAt,
    Value<String?>? note,
    Value<int>? rowid,
  }) {
    return ActualsCompanion(
      id: id ?? this.id,
      occurrenceId: occurrenceId ?? this.occurrenceId,
      outcome: outcome ?? this.outcome,
      recordedAt: recordedAt ?? this.recordedAt,
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
    if (occurrenceId.present) {
      map['occurrence_id'] = Variable<String>(occurrenceId.value);
    }
    if (outcome.present) {
      map['outcome'] = Variable<int>(outcome.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
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
    return (StringBuffer('ActualsCompanion(')
          ..write('id: $id, ')
          ..write('occurrenceId: $occurrenceId, ')
          ..write('outcome: $outcome, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('note: $note, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EvidencesTable extends Evidences
    with TableInfo<$EvidencesTable, Evidence> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EvidencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actualIdMeta = const VerificationMeta(
    'actualId',
  );
  @override
  late final GeneratedColumn<String> actualId = GeneratedColumn<String>(
    'actual_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES actuals (id)',
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
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
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
  @override
  List<GeneratedColumn> get $columns => [id, actualId, type, value, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'evidences';
  @override
  VerificationContext validateIntegrity(
    Insertable<Evidence> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('actual_id')) {
      context.handle(
        _actualIdMeta,
        actualId.isAcceptableOrUnknown(data['actual_id']!, _actualIdMeta),
      );
    } else if (isInserting) {
      context.missing(_actualIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Evidence map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Evidence(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      actualId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}actual_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}type'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $EvidencesTable createAlias(String alias) {
    return $EvidencesTable(attachedDatabase, alias);
  }
}

class Evidence extends DataClass implements Insertable<Evidence> {
  final String id;
  final String actualId;
  final int type;
  final String value;
  final DateTime createdAt;
  const Evidence({
    required this.id,
    required this.actualId,
    required this.type,
    required this.value,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['actual_id'] = Variable<String>(actualId);
    map['type'] = Variable<int>(type);
    map['value'] = Variable<String>(value);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  EvidencesCompanion toCompanion(bool nullToAbsent) {
    return EvidencesCompanion(
      id: Value(id),
      actualId: Value(actualId),
      type: Value(type),
      value: Value(value),
      createdAt: Value(createdAt),
    );
  }

  factory Evidence.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Evidence(
      id: serializer.fromJson<String>(json['id']),
      actualId: serializer.fromJson<String>(json['actualId']),
      type: serializer.fromJson<int>(json['type']),
      value: serializer.fromJson<String>(json['value']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'actualId': serializer.toJson<String>(actualId),
      'type': serializer.toJson<int>(type),
      'value': serializer.toJson<String>(value),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Evidence copyWith({
    String? id,
    String? actualId,
    int? type,
    String? value,
    DateTime? createdAt,
  }) => Evidence(
    id: id ?? this.id,
    actualId: actualId ?? this.actualId,
    type: type ?? this.type,
    value: value ?? this.value,
    createdAt: createdAt ?? this.createdAt,
  );
  Evidence copyWithCompanion(EvidencesCompanion data) {
    return Evidence(
      id: data.id.present ? data.id.value : this.id,
      actualId: data.actualId.present ? data.actualId.value : this.actualId,
      type: data.type.present ? data.type.value : this.type,
      value: data.value.present ? data.value.value : this.value,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Evidence(')
          ..write('id: $id, ')
          ..write('actualId: $actualId, ')
          ..write('type: $type, ')
          ..write('value: $value, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, actualId, type, value, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Evidence &&
          other.id == this.id &&
          other.actualId == this.actualId &&
          other.type == this.type &&
          other.value == this.value &&
          other.createdAt == this.createdAt);
}

class EvidencesCompanion extends UpdateCompanion<Evidence> {
  final Value<String> id;
  final Value<String> actualId;
  final Value<int> type;
  final Value<String> value;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const EvidencesCompanion({
    this.id = const Value.absent(),
    this.actualId = const Value.absent(),
    this.type = const Value.absent(),
    this.value = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EvidencesCompanion.insert({
    required String id,
    required String actualId,
    required int type,
    required String value,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       actualId = Value(actualId),
       type = Value(type),
       value = Value(value),
       createdAt = Value(createdAt);
  static Insertable<Evidence> custom({
    Expression<String>? id,
    Expression<String>? actualId,
    Expression<int>? type,
    Expression<String>? value,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (actualId != null) 'actual_id': actualId,
      if (type != null) 'type': type,
      if (value != null) 'value': value,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EvidencesCompanion copyWith({
    Value<String>? id,
    Value<String>? actualId,
    Value<int>? type,
    Value<String>? value,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return EvidencesCompanion(
      id: id ?? this.id,
      actualId: actualId ?? this.actualId,
      type: type ?? this.type,
      value: value ?? this.value,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (actualId.present) {
      map['actual_id'] = Variable<String>(actualId.value);
    }
    if (type.present) {
      map['type'] = Variable<int>(type.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EvidencesCompanion(')
          ..write('id: $id, ')
          ..write('actualId: $actualId, ')
          ..write('type: $type, ')
          ..write('value: $value, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FinancialAccountsTable extends FinancialAccounts
    with TableInfo<$FinancialAccountsTable, FinancialAccount> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FinancialAccountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _bankCodeMeta = const VerificationMeta(
    'bankCode',
  );
  @override
  late final GeneratedColumn<String> bankCode = GeneratedColumn<String>(
    'bank_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
    name,
    currency,
    type,
    bankCode,
    status,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'financial_accounts';
  @override
  VerificationContext validateIntegrity(
    Insertable<FinancialAccount> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    } else if (isInserting) {
      context.missing(_currencyMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('bank_code')) {
      context.handle(
        _bankCodeMeta,
        bankCode.isAcceptableOrUnknown(data['bank_code']!, _bankCodeMeta),
      );
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
  FinancialAccount map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FinancialAccount(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}type'],
      )!,
      bankCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bank_code'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}status'],
      )!,
    );
  }

  @override
  $FinancialAccountsTable createAlias(String alias) {
    return $FinancialAccountsTable(attachedDatabase, alias);
  }
}

class FinancialAccount extends DataClass
    implements Insertable<FinancialAccount> {
  final String id;
  final String name;
  final String currency;
  final int type;
  final String? bankCode;
  final int status;
  const FinancialAccount({
    required this.id,
    required this.name,
    required this.currency,
    required this.type,
    this.bankCode,
    required this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['currency'] = Variable<String>(currency);
    map['type'] = Variable<int>(type);
    if (!nullToAbsent || bankCode != null) {
      map['bank_code'] = Variable<String>(bankCode);
    }
    map['status'] = Variable<int>(status);
    return map;
  }

  FinancialAccountsCompanion toCompanion(bool nullToAbsent) {
    return FinancialAccountsCompanion(
      id: Value(id),
      name: Value(name),
      currency: Value(currency),
      type: Value(type),
      bankCode: bankCode == null && nullToAbsent
          ? const Value.absent()
          : Value(bankCode),
      status: Value(status),
    );
  }

  factory FinancialAccount.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FinancialAccount(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      currency: serializer.fromJson<String>(json['currency']),
      type: serializer.fromJson<int>(json['type']),
      bankCode: serializer.fromJson<String?>(json['bankCode']),
      status: serializer.fromJson<int>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'currency': serializer.toJson<String>(currency),
      'type': serializer.toJson<int>(type),
      'bankCode': serializer.toJson<String?>(bankCode),
      'status': serializer.toJson<int>(status),
    };
  }

  FinancialAccount copyWith({
    String? id,
    String? name,
    String? currency,
    int? type,
    Value<String?> bankCode = const Value.absent(),
    int? status,
  }) => FinancialAccount(
    id: id ?? this.id,
    name: name ?? this.name,
    currency: currency ?? this.currency,
    type: type ?? this.type,
    bankCode: bankCode.present ? bankCode.value : this.bankCode,
    status: status ?? this.status,
  );
  FinancialAccount copyWithCompanion(FinancialAccountsCompanion data) {
    return FinancialAccount(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      currency: data.currency.present ? data.currency.value : this.currency,
      type: data.type.present ? data.type.value : this.type,
      bankCode: data.bankCode.present ? data.bankCode.value : this.bankCode,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FinancialAccount(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('currency: $currency, ')
          ..write('type: $type, ')
          ..write('bankCode: $bankCode, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, currency, type, bankCode, status);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FinancialAccount &&
          other.id == this.id &&
          other.name == this.name &&
          other.currency == this.currency &&
          other.type == this.type &&
          other.bankCode == this.bankCode &&
          other.status == this.status);
}

class FinancialAccountsCompanion extends UpdateCompanion<FinancialAccount> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> currency;
  final Value<int> type;
  final Value<String?> bankCode;
  final Value<int> status;
  final Value<int> rowid;
  const FinancialAccountsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.currency = const Value.absent(),
    this.type = const Value.absent(),
    this.bankCode = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FinancialAccountsCompanion.insert({
    required String id,
    required String name,
    required String currency,
    required int type,
    this.bankCode = const Value.absent(),
    required int status,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       currency = Value(currency),
       type = Value(type),
       status = Value(status);
  static Insertable<FinancialAccount> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? currency,
    Expression<int>? type,
    Expression<String>? bankCode,
    Expression<int>? status,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (currency != null) 'currency': currency,
      if (type != null) 'type': type,
      if (bankCode != null) 'bank_code': bankCode,
      if (status != null) 'status': status,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FinancialAccountsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? currency,
    Value<int>? type,
    Value<String?>? bankCode,
    Value<int>? status,
    Value<int>? rowid,
  }) {
    return FinancialAccountsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      currency: currency ?? this.currency,
      type: type ?? this.type,
      bankCode: bankCode ?? this.bankCode,
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
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (type.present) {
      map['type'] = Variable<int>(type.value);
    }
    if (bankCode.present) {
      map['bank_code'] = Variable<String>(bankCode.value);
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
    return (StringBuffer('FinancialAccountsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('currency: $currency, ')
          ..write('type: $type, ')
          ..write('bankCode: $bankCode, ')
          ..write('status: $status, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AccountEntriesTable extends AccountEntries
    with TableInfo<$AccountEntriesTable, AccountEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccountEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES financial_accounts (id)',
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
  static const VerificationMeta _minorUnitsMeta = const VerificationMeta(
    'minorUnits',
  );
  @override
  late final GeneratedColumn<int> minorUnits = GeneratedColumn<int>(
    'minor_units',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
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
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<int> source = GeneratedColumn<int>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _transferGroupIdMeta = const VerificationMeta(
    'transferGroupId',
  );
  @override
  late final GeneratedColumn<String> transferGroupId = GeneratedColumn<String>(
    'transfer_group_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    accountId,
    type,
    minorUnits,
    currency,
    occurredAt,
    referenceId,
    note,
    category,
    source,
    transferGroupId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'account_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<AccountEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('minor_units')) {
      context.handle(
        _minorUnitsMeta,
        minorUnits.isAcceptableOrUnknown(data['minor_units']!, _minorUnitsMeta),
      );
    } else if (isInserting) {
      context.missing(_minorUnitsMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    } else if (isInserting) {
      context.missing(_currencyMeta);
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
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('transfer_group_id')) {
      context.handle(
        _transferGroupIdMeta,
        transferGroupId.isAcceptableOrUnknown(
          data['transfer_group_id']!,
          _transferGroupIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AccountEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AccountEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}type'],
      )!,
      minorUnits: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}minor_units'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
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
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}source'],
      )!,
      transferGroupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transfer_group_id'],
      ),
    );
  }

  @override
  $AccountEntriesTable createAlias(String alias) {
    return $AccountEntriesTable(attachedDatabase, alias);
  }
}

class AccountEntry extends DataClass implements Insertable<AccountEntry> {
  final String id;
  final String accountId;
  final int type;
  final int minorUnits;
  final String currency;
  final DateTime occurredAt;
  final String? referenceId;
  final String? note;
  final String? category;
  final int source;
  final String? transferGroupId;
  const AccountEntry({
    required this.id,
    required this.accountId,
    required this.type,
    required this.minorUnits,
    required this.currency,
    required this.occurredAt,
    this.referenceId,
    this.note,
    this.category,
    required this.source,
    this.transferGroupId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['account_id'] = Variable<String>(accountId);
    map['type'] = Variable<int>(type);
    map['minor_units'] = Variable<int>(minorUnits);
    map['currency'] = Variable<String>(currency);
    map['occurred_at'] = Variable<DateTime>(occurredAt);
    if (!nullToAbsent || referenceId != null) {
      map['reference_id'] = Variable<String>(referenceId);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    map['source'] = Variable<int>(source);
    if (!nullToAbsent || transferGroupId != null) {
      map['transfer_group_id'] = Variable<String>(transferGroupId);
    }
    return map;
  }

  AccountEntriesCompanion toCompanion(bool nullToAbsent) {
    return AccountEntriesCompanion(
      id: Value(id),
      accountId: Value(accountId),
      type: Value(type),
      minorUnits: Value(minorUnits),
      currency: Value(currency),
      occurredAt: Value(occurredAt),
      referenceId: referenceId == null && nullToAbsent
          ? const Value.absent()
          : Value(referenceId),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      source: Value(source),
      transferGroupId: transferGroupId == null && nullToAbsent
          ? const Value.absent()
          : Value(transferGroupId),
    );
  }

  factory AccountEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AccountEntry(
      id: serializer.fromJson<String>(json['id']),
      accountId: serializer.fromJson<String>(json['accountId']),
      type: serializer.fromJson<int>(json['type']),
      minorUnits: serializer.fromJson<int>(json['minorUnits']),
      currency: serializer.fromJson<String>(json['currency']),
      occurredAt: serializer.fromJson<DateTime>(json['occurredAt']),
      referenceId: serializer.fromJson<String?>(json['referenceId']),
      note: serializer.fromJson<String?>(json['note']),
      category: serializer.fromJson<String?>(json['category']),
      source: serializer.fromJson<int>(json['source']),
      transferGroupId: serializer.fromJson<String?>(json['transferGroupId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'accountId': serializer.toJson<String>(accountId),
      'type': serializer.toJson<int>(type),
      'minorUnits': serializer.toJson<int>(minorUnits),
      'currency': serializer.toJson<String>(currency),
      'occurredAt': serializer.toJson<DateTime>(occurredAt),
      'referenceId': serializer.toJson<String?>(referenceId),
      'note': serializer.toJson<String?>(note),
      'category': serializer.toJson<String?>(category),
      'source': serializer.toJson<int>(source),
      'transferGroupId': serializer.toJson<String?>(transferGroupId),
    };
  }

  AccountEntry copyWith({
    String? id,
    String? accountId,
    int? type,
    int? minorUnits,
    String? currency,
    DateTime? occurredAt,
    Value<String?> referenceId = const Value.absent(),
    Value<String?> note = const Value.absent(),
    Value<String?> category = const Value.absent(),
    int? source,
    Value<String?> transferGroupId = const Value.absent(),
  }) => AccountEntry(
    id: id ?? this.id,
    accountId: accountId ?? this.accountId,
    type: type ?? this.type,
    minorUnits: minorUnits ?? this.minorUnits,
    currency: currency ?? this.currency,
    occurredAt: occurredAt ?? this.occurredAt,
    referenceId: referenceId.present ? referenceId.value : this.referenceId,
    note: note.present ? note.value : this.note,
    category: category.present ? category.value : this.category,
    source: source ?? this.source,
    transferGroupId: transferGroupId.present
        ? transferGroupId.value
        : this.transferGroupId,
  );
  AccountEntry copyWithCompanion(AccountEntriesCompanion data) {
    return AccountEntry(
      id: data.id.present ? data.id.value : this.id,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      type: data.type.present ? data.type.value : this.type,
      minorUnits: data.minorUnits.present
          ? data.minorUnits.value
          : this.minorUnits,
      currency: data.currency.present ? data.currency.value : this.currency,
      occurredAt: data.occurredAt.present
          ? data.occurredAt.value
          : this.occurredAt,
      referenceId: data.referenceId.present
          ? data.referenceId.value
          : this.referenceId,
      note: data.note.present ? data.note.value : this.note,
      category: data.category.present ? data.category.value : this.category,
      source: data.source.present ? data.source.value : this.source,
      transferGroupId: data.transferGroupId.present
          ? data.transferGroupId.value
          : this.transferGroupId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AccountEntry(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('type: $type, ')
          ..write('minorUnits: $minorUnits, ')
          ..write('currency: $currency, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('referenceId: $referenceId, ')
          ..write('note: $note, ')
          ..write('category: $category, ')
          ..write('source: $source, ')
          ..write('transferGroupId: $transferGroupId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    accountId,
    type,
    minorUnits,
    currency,
    occurredAt,
    referenceId,
    note,
    category,
    source,
    transferGroupId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AccountEntry &&
          other.id == this.id &&
          other.accountId == this.accountId &&
          other.type == this.type &&
          other.minorUnits == this.minorUnits &&
          other.currency == this.currency &&
          other.occurredAt == this.occurredAt &&
          other.referenceId == this.referenceId &&
          other.note == this.note &&
          other.category == this.category &&
          other.source == this.source &&
          other.transferGroupId == this.transferGroupId);
}

class AccountEntriesCompanion extends UpdateCompanion<AccountEntry> {
  final Value<String> id;
  final Value<String> accountId;
  final Value<int> type;
  final Value<int> minorUnits;
  final Value<String> currency;
  final Value<DateTime> occurredAt;
  final Value<String?> referenceId;
  final Value<String?> note;
  final Value<String?> category;
  final Value<int> source;
  final Value<String?> transferGroupId;
  final Value<int> rowid;
  const AccountEntriesCompanion({
    this.id = const Value.absent(),
    this.accountId = const Value.absent(),
    this.type = const Value.absent(),
    this.minorUnits = const Value.absent(),
    this.currency = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.referenceId = const Value.absent(),
    this.note = const Value.absent(),
    this.category = const Value.absent(),
    this.source = const Value.absent(),
    this.transferGroupId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AccountEntriesCompanion.insert({
    required String id,
    required String accountId,
    required int type,
    required int minorUnits,
    required String currency,
    required DateTime occurredAt,
    this.referenceId = const Value.absent(),
    this.note = const Value.absent(),
    this.category = const Value.absent(),
    this.source = const Value.absent(),
    this.transferGroupId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       accountId = Value(accountId),
       type = Value(type),
       minorUnits = Value(minorUnits),
       currency = Value(currency),
       occurredAt = Value(occurredAt);
  static Insertable<AccountEntry> custom({
    Expression<String>? id,
    Expression<String>? accountId,
    Expression<int>? type,
    Expression<int>? minorUnits,
    Expression<String>? currency,
    Expression<DateTime>? occurredAt,
    Expression<String>? referenceId,
    Expression<String>? note,
    Expression<String>? category,
    Expression<int>? source,
    Expression<String>? transferGroupId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (accountId != null) 'account_id': accountId,
      if (type != null) 'type': type,
      if (minorUnits != null) 'minor_units': minorUnits,
      if (currency != null) 'currency': currency,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (referenceId != null) 'reference_id': referenceId,
      if (note != null) 'note': note,
      if (category != null) 'category': category,
      if (source != null) 'source': source,
      if (transferGroupId != null) 'transfer_group_id': transferGroupId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AccountEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? accountId,
    Value<int>? type,
    Value<int>? minorUnits,
    Value<String>? currency,
    Value<DateTime>? occurredAt,
    Value<String?>? referenceId,
    Value<String?>? note,
    Value<String?>? category,
    Value<int>? source,
    Value<String?>? transferGroupId,
    Value<int>? rowid,
  }) {
    return AccountEntriesCompanion(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      type: type ?? this.type,
      minorUnits: minorUnits ?? this.minorUnits,
      currency: currency ?? this.currency,
      occurredAt: occurredAt ?? this.occurredAt,
      referenceId: referenceId ?? this.referenceId,
      note: note ?? this.note,
      category: category ?? this.category,
      source: source ?? this.source,
      transferGroupId: transferGroupId ?? this.transferGroupId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (type.present) {
      map['type'] = Variable<int>(type.value);
    }
    if (minorUnits.present) {
      map['minor_units'] = Variable<int>(minorUnits.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
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
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (source.present) {
      map['source'] = Variable<int>(source.value);
    }
    if (transferGroupId.present) {
      map['transfer_group_id'] = Variable<String>(transferGroupId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccountEntriesCompanion(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('type: $type, ')
          ..write('minorUnits: $minorUnits, ')
          ..write('currency: $currency, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('referenceId: $referenceId, ')
          ..write('note: $note, ')
          ..write('category: $category, ')
          ..write('source: $source, ')
          ..write('transferGroupId: $transferGroupId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TransactionMatchesTable extends TransactionMatches
    with TableInfo<$TransactionMatchesTable, TransactionMatche> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionMatchesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _transactionIdMeta = const VerificationMeta(
    'transactionId',
  );
  @override
  late final GeneratedColumn<String> transactionId = GeneratedColumn<String>(
    'transaction_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES account_entries (id)',
    ),
  );
  static const VerificationMeta _minorUnitsMeta = const VerificationMeta(
    'minorUnits',
  );
  @override
  late final GeneratedColumn<int> minorUnits = GeneratedColumn<int>(
    'minor_units',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
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
  static const VerificationMeta _correctedMatchIdMeta = const VerificationMeta(
    'correctedMatchId',
  );
  @override
  late final GeneratedColumn<String> correctedMatchId = GeneratedColumn<String>(
    'corrected_match_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    transactionId,
    minorUnits,
    currency,
    createdAt,
    status,
    correctedMatchId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transaction_matches';
  @override
  VerificationContext validateIntegrity(
    Insertable<TransactionMatche> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('transaction_id')) {
      context.handle(
        _transactionIdMeta,
        transactionId.isAcceptableOrUnknown(
          data['transaction_id']!,
          _transactionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_transactionIdMeta);
    }
    if (data.containsKey('minor_units')) {
      context.handle(
        _minorUnitsMeta,
        minorUnits.isAcceptableOrUnknown(data['minor_units']!, _minorUnitsMeta),
      );
    } else if (isInserting) {
      context.missing(_minorUnitsMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    } else if (isInserting) {
      context.missing(_currencyMeta);
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
    if (data.containsKey('corrected_match_id')) {
      context.handle(
        _correctedMatchIdMeta,
        correctedMatchId.isAcceptableOrUnknown(
          data['corrected_match_id']!,
          _correctedMatchIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TransactionMatche map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransactionMatche(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      transactionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transaction_id'],
      )!,
      minorUnits: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}minor_units'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}status'],
      )!,
      correctedMatchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}corrected_match_id'],
      ),
    );
  }

  @override
  $TransactionMatchesTable createAlias(String alias) {
    return $TransactionMatchesTable(attachedDatabase, alias);
  }
}

class TransactionMatche extends DataClass
    implements Insertable<TransactionMatche> {
  final String id;
  final String transactionId;
  final int minorUnits;
  final String currency;
  final DateTime createdAt;
  final int status;
  final String? correctedMatchId;
  const TransactionMatche({
    required this.id,
    required this.transactionId,
    required this.minorUnits,
    required this.currency,
    required this.createdAt,
    required this.status,
    this.correctedMatchId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['transaction_id'] = Variable<String>(transactionId);
    map['minor_units'] = Variable<int>(minorUnits);
    map['currency'] = Variable<String>(currency);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['status'] = Variable<int>(status);
    if (!nullToAbsent || correctedMatchId != null) {
      map['corrected_match_id'] = Variable<String>(correctedMatchId);
    }
    return map;
  }

  TransactionMatchesCompanion toCompanion(bool nullToAbsent) {
    return TransactionMatchesCompanion(
      id: Value(id),
      transactionId: Value(transactionId),
      minorUnits: Value(minorUnits),
      currency: Value(currency),
      createdAt: Value(createdAt),
      status: Value(status),
      correctedMatchId: correctedMatchId == null && nullToAbsent
          ? const Value.absent()
          : Value(correctedMatchId),
    );
  }

  factory TransactionMatche.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransactionMatche(
      id: serializer.fromJson<String>(json['id']),
      transactionId: serializer.fromJson<String>(json['transactionId']),
      minorUnits: serializer.fromJson<int>(json['minorUnits']),
      currency: serializer.fromJson<String>(json['currency']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      status: serializer.fromJson<int>(json['status']),
      correctedMatchId: serializer.fromJson<String?>(json['correctedMatchId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'transactionId': serializer.toJson<String>(transactionId),
      'minorUnits': serializer.toJson<int>(minorUnits),
      'currency': serializer.toJson<String>(currency),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'status': serializer.toJson<int>(status),
      'correctedMatchId': serializer.toJson<String?>(correctedMatchId),
    };
  }

  TransactionMatche copyWith({
    String? id,
    String? transactionId,
    int? minorUnits,
    String? currency,
    DateTime? createdAt,
    int? status,
    Value<String?> correctedMatchId = const Value.absent(),
  }) => TransactionMatche(
    id: id ?? this.id,
    transactionId: transactionId ?? this.transactionId,
    minorUnits: minorUnits ?? this.minorUnits,
    currency: currency ?? this.currency,
    createdAt: createdAt ?? this.createdAt,
    status: status ?? this.status,
    correctedMatchId: correctedMatchId.present
        ? correctedMatchId.value
        : this.correctedMatchId,
  );
  TransactionMatche copyWithCompanion(TransactionMatchesCompanion data) {
    return TransactionMatche(
      id: data.id.present ? data.id.value : this.id,
      transactionId: data.transactionId.present
          ? data.transactionId.value
          : this.transactionId,
      minorUnits: data.minorUnits.present
          ? data.minorUnits.value
          : this.minorUnits,
      currency: data.currency.present ? data.currency.value : this.currency,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      status: data.status.present ? data.status.value : this.status,
      correctedMatchId: data.correctedMatchId.present
          ? data.correctedMatchId.value
          : this.correctedMatchId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransactionMatche(')
          ..write('id: $id, ')
          ..write('transactionId: $transactionId, ')
          ..write('minorUnits: $minorUnits, ')
          ..write('currency: $currency, ')
          ..write('createdAt: $createdAt, ')
          ..write('status: $status, ')
          ..write('correctedMatchId: $correctedMatchId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    transactionId,
    minorUnits,
    currency,
    createdAt,
    status,
    correctedMatchId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransactionMatche &&
          other.id == this.id &&
          other.transactionId == this.transactionId &&
          other.minorUnits == this.minorUnits &&
          other.currency == this.currency &&
          other.createdAt == this.createdAt &&
          other.status == this.status &&
          other.correctedMatchId == this.correctedMatchId);
}

class TransactionMatchesCompanion extends UpdateCompanion<TransactionMatche> {
  final Value<String> id;
  final Value<String> transactionId;
  final Value<int> minorUnits;
  final Value<String> currency;
  final Value<DateTime> createdAt;
  final Value<int> status;
  final Value<String?> correctedMatchId;
  final Value<int> rowid;
  const TransactionMatchesCompanion({
    this.id = const Value.absent(),
    this.transactionId = const Value.absent(),
    this.minorUnits = const Value.absent(),
    this.currency = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.status = const Value.absent(),
    this.correctedMatchId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransactionMatchesCompanion.insert({
    required String id,
    required String transactionId,
    required int minorUnits,
    required String currency,
    required DateTime createdAt,
    required int status,
    this.correctedMatchId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       transactionId = Value(transactionId),
       minorUnits = Value(minorUnits),
       currency = Value(currency),
       createdAt = Value(createdAt),
       status = Value(status);
  static Insertable<TransactionMatche> custom({
    Expression<String>? id,
    Expression<String>? transactionId,
    Expression<int>? minorUnits,
    Expression<String>? currency,
    Expression<DateTime>? createdAt,
    Expression<int>? status,
    Expression<String>? correctedMatchId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (transactionId != null) 'transaction_id': transactionId,
      if (minorUnits != null) 'minor_units': minorUnits,
      if (currency != null) 'currency': currency,
      if (createdAt != null) 'created_at': createdAt,
      if (status != null) 'status': status,
      if (correctedMatchId != null) 'corrected_match_id': correctedMatchId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransactionMatchesCompanion copyWith({
    Value<String>? id,
    Value<String>? transactionId,
    Value<int>? minorUnits,
    Value<String>? currency,
    Value<DateTime>? createdAt,
    Value<int>? status,
    Value<String?>? correctedMatchId,
    Value<int>? rowid,
  }) {
    return TransactionMatchesCompanion(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      minorUnits: minorUnits ?? this.minorUnits,
      currency: currency ?? this.currency,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      correctedMatchId: correctedMatchId ?? this.correctedMatchId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (transactionId.present) {
      map['transaction_id'] = Variable<String>(transactionId.value);
    }
    if (minorUnits.present) {
      map['minor_units'] = Variable<int>(minorUnits.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (status.present) {
      map['status'] = Variable<int>(status.value);
    }
    if (correctedMatchId.present) {
      map['corrected_match_id'] = Variable<String>(correctedMatchId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionMatchesCompanion(')
          ..write('id: $id, ')
          ..write('transactionId: $transactionId, ')
          ..write('minorUnits: $minorUnits, ')
          ..write('currency: $currency, ')
          ..write('createdAt: $createdAt, ')
          ..write('status: $status, ')
          ..write('correctedMatchId: $correctedMatchId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MatchAllocationsTable extends MatchAllocations
    with TableInfo<$MatchAllocationsTable, MatchAllocation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MatchAllocationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _matchIdMeta = const VerificationMeta(
    'matchId',
  );
  @override
  late final GeneratedColumn<String> matchId = GeneratedColumn<String>(
    'match_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES transaction_matches (id)',
    ),
  );
  static const VerificationMeta _occurrenceIdMeta = const VerificationMeta(
    'occurrenceId',
  );
  @override
  late final GeneratedColumn<String> occurrenceId = GeneratedColumn<String>(
    'occurrence_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES occurrences (id)',
    ),
  );
  static const VerificationMeta _minorUnitsMeta = const VerificationMeta(
    'minorUnits',
  );
  @override
  late final GeneratedColumn<int> minorUnits = GeneratedColumn<int>(
    'minor_units',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    matchId,
    occurrenceId,
    minorUnits,
    currency,
    type,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'match_allocations';
  @override
  VerificationContext validateIntegrity(
    Insertable<MatchAllocation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('match_id')) {
      context.handle(
        _matchIdMeta,
        matchId.isAcceptableOrUnknown(data['match_id']!, _matchIdMeta),
      );
    } else if (isInserting) {
      context.missing(_matchIdMeta);
    }
    if (data.containsKey('occurrence_id')) {
      context.handle(
        _occurrenceIdMeta,
        occurrenceId.isAcceptableOrUnknown(
          data['occurrence_id']!,
          _occurrenceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_occurrenceIdMeta);
    }
    if (data.containsKey('minor_units')) {
      context.handle(
        _minorUnitsMeta,
        minorUnits.isAcceptableOrUnknown(data['minor_units']!, _minorUnitsMeta),
      );
    } else if (isInserting) {
      context.missing(_minorUnitsMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    } else if (isInserting) {
      context.missing(_currencyMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MatchAllocation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MatchAllocation(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      matchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}match_id'],
      )!,
      occurrenceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}occurrence_id'],
      )!,
      minorUnits: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}minor_units'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}type'],
      )!,
    );
  }

  @override
  $MatchAllocationsTable createAlias(String alias) {
    return $MatchAllocationsTable(attachedDatabase, alias);
  }
}

class MatchAllocation extends DataClass implements Insertable<MatchAllocation> {
  final String id;
  final String matchId;
  final String occurrenceId;
  final int minorUnits;
  final String currency;
  final int type;
  const MatchAllocation({
    required this.id,
    required this.matchId,
    required this.occurrenceId,
    required this.minorUnits,
    required this.currency,
    required this.type,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['match_id'] = Variable<String>(matchId);
    map['occurrence_id'] = Variable<String>(occurrenceId);
    map['minor_units'] = Variable<int>(minorUnits);
    map['currency'] = Variable<String>(currency);
    map['type'] = Variable<int>(type);
    return map;
  }

  MatchAllocationsCompanion toCompanion(bool nullToAbsent) {
    return MatchAllocationsCompanion(
      id: Value(id),
      matchId: Value(matchId),
      occurrenceId: Value(occurrenceId),
      minorUnits: Value(minorUnits),
      currency: Value(currency),
      type: Value(type),
    );
  }

  factory MatchAllocation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MatchAllocation(
      id: serializer.fromJson<String>(json['id']),
      matchId: serializer.fromJson<String>(json['matchId']),
      occurrenceId: serializer.fromJson<String>(json['occurrenceId']),
      minorUnits: serializer.fromJson<int>(json['minorUnits']),
      currency: serializer.fromJson<String>(json['currency']),
      type: serializer.fromJson<int>(json['type']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'matchId': serializer.toJson<String>(matchId),
      'occurrenceId': serializer.toJson<String>(occurrenceId),
      'minorUnits': serializer.toJson<int>(minorUnits),
      'currency': serializer.toJson<String>(currency),
      'type': serializer.toJson<int>(type),
    };
  }

  MatchAllocation copyWith({
    String? id,
    String? matchId,
    String? occurrenceId,
    int? minorUnits,
    String? currency,
    int? type,
  }) => MatchAllocation(
    id: id ?? this.id,
    matchId: matchId ?? this.matchId,
    occurrenceId: occurrenceId ?? this.occurrenceId,
    minorUnits: minorUnits ?? this.minorUnits,
    currency: currency ?? this.currency,
    type: type ?? this.type,
  );
  MatchAllocation copyWithCompanion(MatchAllocationsCompanion data) {
    return MatchAllocation(
      id: data.id.present ? data.id.value : this.id,
      matchId: data.matchId.present ? data.matchId.value : this.matchId,
      occurrenceId: data.occurrenceId.present
          ? data.occurrenceId.value
          : this.occurrenceId,
      minorUnits: data.minorUnits.present
          ? data.minorUnits.value
          : this.minorUnits,
      currency: data.currency.present ? data.currency.value : this.currency,
      type: data.type.present ? data.type.value : this.type,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MatchAllocation(')
          ..write('id: $id, ')
          ..write('matchId: $matchId, ')
          ..write('occurrenceId: $occurrenceId, ')
          ..write('minorUnits: $minorUnits, ')
          ..write('currency: $currency, ')
          ..write('type: $type')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, matchId, occurrenceId, minorUnits, currency, type);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MatchAllocation &&
          other.id == this.id &&
          other.matchId == this.matchId &&
          other.occurrenceId == this.occurrenceId &&
          other.minorUnits == this.minorUnits &&
          other.currency == this.currency &&
          other.type == this.type);
}

class MatchAllocationsCompanion extends UpdateCompanion<MatchAllocation> {
  final Value<String> id;
  final Value<String> matchId;
  final Value<String> occurrenceId;
  final Value<int> minorUnits;
  final Value<String> currency;
  final Value<int> type;
  final Value<int> rowid;
  const MatchAllocationsCompanion({
    this.id = const Value.absent(),
    this.matchId = const Value.absent(),
    this.occurrenceId = const Value.absent(),
    this.minorUnits = const Value.absent(),
    this.currency = const Value.absent(),
    this.type = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MatchAllocationsCompanion.insert({
    required String id,
    required String matchId,
    required String occurrenceId,
    required int minorUnits,
    required String currency,
    required int type,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       matchId = Value(matchId),
       occurrenceId = Value(occurrenceId),
       minorUnits = Value(minorUnits),
       currency = Value(currency),
       type = Value(type);
  static Insertable<MatchAllocation> custom({
    Expression<String>? id,
    Expression<String>? matchId,
    Expression<String>? occurrenceId,
    Expression<int>? minorUnits,
    Expression<String>? currency,
    Expression<int>? type,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (matchId != null) 'match_id': matchId,
      if (occurrenceId != null) 'occurrence_id': occurrenceId,
      if (minorUnits != null) 'minor_units': minorUnits,
      if (currency != null) 'currency': currency,
      if (type != null) 'type': type,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MatchAllocationsCompanion copyWith({
    Value<String>? id,
    Value<String>? matchId,
    Value<String>? occurrenceId,
    Value<int>? minorUnits,
    Value<String>? currency,
    Value<int>? type,
    Value<int>? rowid,
  }) {
    return MatchAllocationsCompanion(
      id: id ?? this.id,
      matchId: matchId ?? this.matchId,
      occurrenceId: occurrenceId ?? this.occurrenceId,
      minorUnits: minorUnits ?? this.minorUnits,
      currency: currency ?? this.currency,
      type: type ?? this.type,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (matchId.present) {
      map['match_id'] = Variable<String>(matchId.value);
    }
    if (occurrenceId.present) {
      map['occurrence_id'] = Variable<String>(occurrenceId.value);
    }
    if (minorUnits.present) {
      map['minor_units'] = Variable<int>(minorUnits.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (type.present) {
      map['type'] = Variable<int>(type.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MatchAllocationsCompanion(')
          ..write('id: $id, ')
          ..write('matchId: $matchId, ')
          ..write('occurrenceId: $occurrenceId, ')
          ..write('minorUnits: $minorUnits, ')
          ..write('currency: $currency, ')
          ..write('type: $type, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RelationshipReviewsTable extends RelationshipReviews
    with TableInfo<$RelationshipReviewsTable, RelationshipReview> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RelationshipReviewsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _transactionIdMeta = const VerificationMeta(
    'transactionId',
  );
  @override
  late final GeneratedColumn<String> transactionId = GeneratedColumn<String>(
    'transaction_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES account_entries (id)',
    ),
  );
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  @override
  late final GeneratedColumn<int> revision = GeneratedColumn<int>(
    'revision',
    aliasedName,
    false,
    check: () => ComparableExpr(revision).isBiggerThanValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _decisionMeta = const VerificationMeta(
    'decision',
  );
  @override
  late final GeneratedColumn<int> decision = GeneratedColumn<int>(
    'decision',
    aliasedName,
    false,
    check: () => ComparableExpr(decision).isBetweenValues(0, 1),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _minorUnitsMeta = const VerificationMeta(
    'minorUnits',
  );
  @override
  late final GeneratedColumn<int> minorUnits = GeneratedColumn<int>(
    'minor_units',
    aliasedName,
    false,
    check: () => ComparableExpr(minorUnits).isBiggerThanValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _allocationFingerprintMeta =
      const VerificationMeta('allocationFingerprint');
  @override
  late final GeneratedColumn<String> allocationFingerprint =
      GeneratedColumn<String>(
        'allocation_fingerprint',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _allocationHistoryFingerprintMeta =
      const VerificationMeta('allocationHistoryFingerprint');
  @override
  late final GeneratedColumn<String> allocationHistoryFingerprint =
      GeneratedColumn<String>(
        'allocation_history_fingerprint',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _remainderMinorUnitsMeta =
      const VerificationMeta('remainderMinorUnits');
  @override
  late final GeneratedColumn<int> remainderMinorUnits = GeneratedColumn<int>(
    'remainder_minor_units',
    aliasedName,
    false,
    check: () =>
        ComparableExpr(remainderMinorUnits).isBiggerThanValue(0) &
        ComparableExpr(remainderMinorUnits).isSmallerOrEqual(minorUnits),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordedAtMeta = const VerificationMeta(
    'recordedAt',
  );
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
    'recorded_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    transactionId,
    revision,
    decision,
    minorUnits,
    currency,
    allocationFingerprint,
    allocationHistoryFingerprint,
    remainderMinorUnits,
    recordedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'relationship_reviews';
  @override
  VerificationContext validateIntegrity(
    Insertable<RelationshipReview> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('transaction_id')) {
      context.handle(
        _transactionIdMeta,
        transactionId.isAcceptableOrUnknown(
          data['transaction_id']!,
          _transactionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_transactionIdMeta);
    }
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    } else if (isInserting) {
      context.missing(_revisionMeta);
    }
    if (data.containsKey('decision')) {
      context.handle(
        _decisionMeta,
        decision.isAcceptableOrUnknown(data['decision']!, _decisionMeta),
      );
    } else if (isInserting) {
      context.missing(_decisionMeta);
    }
    if (data.containsKey('minor_units')) {
      context.handle(
        _minorUnitsMeta,
        minorUnits.isAcceptableOrUnknown(data['minor_units']!, _minorUnitsMeta),
      );
    } else if (isInserting) {
      context.missing(_minorUnitsMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    } else if (isInserting) {
      context.missing(_currencyMeta);
    }
    if (data.containsKey('allocation_fingerprint')) {
      context.handle(
        _allocationFingerprintMeta,
        allocationFingerprint.isAcceptableOrUnknown(
          data['allocation_fingerprint']!,
          _allocationFingerprintMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_allocationFingerprintMeta);
    }
    if (data.containsKey('allocation_history_fingerprint')) {
      context.handle(
        _allocationHistoryFingerprintMeta,
        allocationHistoryFingerprint.isAcceptableOrUnknown(
          data['allocation_history_fingerprint']!,
          _allocationHistoryFingerprintMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_allocationHistoryFingerprintMeta);
    }
    if (data.containsKey('remainder_minor_units')) {
      context.handle(
        _remainderMinorUnitsMeta,
        remainderMinorUnits.isAcceptableOrUnknown(
          data['remainder_minor_units']!,
          _remainderMinorUnitsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_remainderMinorUnitsMeta);
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
        _recordedAtMeta,
        recordedAt.isAcceptableOrUnknown(data['recorded_at']!, _recordedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_recordedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RelationshipReview map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RelationshipReview(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      transactionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transaction_id'],
      )!,
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision'],
      )!,
      decision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}decision'],
      )!,
      minorUnits: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}minor_units'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      allocationFingerprint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}allocation_fingerprint'],
      )!,
      allocationHistoryFingerprint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}allocation_history_fingerprint'],
      )!,
      remainderMinorUnits: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}remainder_minor_units'],
      )!,
      recordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}recorded_at'],
      )!,
    );
  }

  @override
  $RelationshipReviewsTable createAlias(String alias) {
    return $RelationshipReviewsTable(attachedDatabase, alias);
  }
}

class RelationshipReview extends DataClass
    implements Insertable<RelationshipReview> {
  final String id;
  final String transactionId;
  final int revision;
  final int decision;
  final int minorUnits;
  final String currency;
  final String allocationFingerprint;
  final String allocationHistoryFingerprint;
  final int remainderMinorUnits;
  final DateTime recordedAt;
  const RelationshipReview({
    required this.id,
    required this.transactionId,
    required this.revision,
    required this.decision,
    required this.minorUnits,
    required this.currency,
    required this.allocationFingerprint,
    required this.allocationHistoryFingerprint,
    required this.remainderMinorUnits,
    required this.recordedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['transaction_id'] = Variable<String>(transactionId);
    map['revision'] = Variable<int>(revision);
    map['decision'] = Variable<int>(decision);
    map['minor_units'] = Variable<int>(minorUnits);
    map['currency'] = Variable<String>(currency);
    map['allocation_fingerprint'] = Variable<String>(allocationFingerprint);
    map['allocation_history_fingerprint'] = Variable<String>(
      allocationHistoryFingerprint,
    );
    map['remainder_minor_units'] = Variable<int>(remainderMinorUnits);
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    return map;
  }

  RelationshipReviewsCompanion toCompanion(bool nullToAbsent) {
    return RelationshipReviewsCompanion(
      id: Value(id),
      transactionId: Value(transactionId),
      revision: Value(revision),
      decision: Value(decision),
      minorUnits: Value(minorUnits),
      currency: Value(currency),
      allocationFingerprint: Value(allocationFingerprint),
      allocationHistoryFingerprint: Value(allocationHistoryFingerprint),
      remainderMinorUnits: Value(remainderMinorUnits),
      recordedAt: Value(recordedAt),
    );
  }

  factory RelationshipReview.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RelationshipReview(
      id: serializer.fromJson<String>(json['id']),
      transactionId: serializer.fromJson<String>(json['transactionId']),
      revision: serializer.fromJson<int>(json['revision']),
      decision: serializer.fromJson<int>(json['decision']),
      minorUnits: serializer.fromJson<int>(json['minorUnits']),
      currency: serializer.fromJson<String>(json['currency']),
      allocationFingerprint: serializer.fromJson<String>(
        json['allocationFingerprint'],
      ),
      allocationHistoryFingerprint: serializer.fromJson<String>(
        json['allocationHistoryFingerprint'],
      ),
      remainderMinorUnits: serializer.fromJson<int>(
        json['remainderMinorUnits'],
      ),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'transactionId': serializer.toJson<String>(transactionId),
      'revision': serializer.toJson<int>(revision),
      'decision': serializer.toJson<int>(decision),
      'minorUnits': serializer.toJson<int>(minorUnits),
      'currency': serializer.toJson<String>(currency),
      'allocationFingerprint': serializer.toJson<String>(allocationFingerprint),
      'allocationHistoryFingerprint': serializer.toJson<String>(
        allocationHistoryFingerprint,
      ),
      'remainderMinorUnits': serializer.toJson<int>(remainderMinorUnits),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
    };
  }

  RelationshipReview copyWith({
    String? id,
    String? transactionId,
    int? revision,
    int? decision,
    int? minorUnits,
    String? currency,
    String? allocationFingerprint,
    String? allocationHistoryFingerprint,
    int? remainderMinorUnits,
    DateTime? recordedAt,
  }) => RelationshipReview(
    id: id ?? this.id,
    transactionId: transactionId ?? this.transactionId,
    revision: revision ?? this.revision,
    decision: decision ?? this.decision,
    minorUnits: minorUnits ?? this.minorUnits,
    currency: currency ?? this.currency,
    allocationFingerprint: allocationFingerprint ?? this.allocationFingerprint,
    allocationHistoryFingerprint:
        allocationHistoryFingerprint ?? this.allocationHistoryFingerprint,
    remainderMinorUnits: remainderMinorUnits ?? this.remainderMinorUnits,
    recordedAt: recordedAt ?? this.recordedAt,
  );
  RelationshipReview copyWithCompanion(RelationshipReviewsCompanion data) {
    return RelationshipReview(
      id: data.id.present ? data.id.value : this.id,
      transactionId: data.transactionId.present
          ? data.transactionId.value
          : this.transactionId,
      revision: data.revision.present ? data.revision.value : this.revision,
      decision: data.decision.present ? data.decision.value : this.decision,
      minorUnits: data.minorUnits.present
          ? data.minorUnits.value
          : this.minorUnits,
      currency: data.currency.present ? data.currency.value : this.currency,
      allocationFingerprint: data.allocationFingerprint.present
          ? data.allocationFingerprint.value
          : this.allocationFingerprint,
      allocationHistoryFingerprint: data.allocationHistoryFingerprint.present
          ? data.allocationHistoryFingerprint.value
          : this.allocationHistoryFingerprint,
      remainderMinorUnits: data.remainderMinorUnits.present
          ? data.remainderMinorUnits.value
          : this.remainderMinorUnits,
      recordedAt: data.recordedAt.present
          ? data.recordedAt.value
          : this.recordedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RelationshipReview(')
          ..write('id: $id, ')
          ..write('transactionId: $transactionId, ')
          ..write('revision: $revision, ')
          ..write('decision: $decision, ')
          ..write('minorUnits: $minorUnits, ')
          ..write('currency: $currency, ')
          ..write('allocationFingerprint: $allocationFingerprint, ')
          ..write(
            'allocationHistoryFingerprint: $allocationHistoryFingerprint, ',
          )
          ..write('remainderMinorUnits: $remainderMinorUnits, ')
          ..write('recordedAt: $recordedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    transactionId,
    revision,
    decision,
    minorUnits,
    currency,
    allocationFingerprint,
    allocationHistoryFingerprint,
    remainderMinorUnits,
    recordedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RelationshipReview &&
          other.id == this.id &&
          other.transactionId == this.transactionId &&
          other.revision == this.revision &&
          other.decision == this.decision &&
          other.minorUnits == this.minorUnits &&
          other.currency == this.currency &&
          other.allocationFingerprint == this.allocationFingerprint &&
          other.allocationHistoryFingerprint ==
              this.allocationHistoryFingerprint &&
          other.remainderMinorUnits == this.remainderMinorUnits &&
          other.recordedAt == this.recordedAt);
}

class RelationshipReviewsCompanion extends UpdateCompanion<RelationshipReview> {
  final Value<String> id;
  final Value<String> transactionId;
  final Value<int> revision;
  final Value<int> decision;
  final Value<int> minorUnits;
  final Value<String> currency;
  final Value<String> allocationFingerprint;
  final Value<String> allocationHistoryFingerprint;
  final Value<int> remainderMinorUnits;
  final Value<DateTime> recordedAt;
  final Value<int> rowid;
  const RelationshipReviewsCompanion({
    this.id = const Value.absent(),
    this.transactionId = const Value.absent(),
    this.revision = const Value.absent(),
    this.decision = const Value.absent(),
    this.minorUnits = const Value.absent(),
    this.currency = const Value.absent(),
    this.allocationFingerprint = const Value.absent(),
    this.allocationHistoryFingerprint = const Value.absent(),
    this.remainderMinorUnits = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RelationshipReviewsCompanion.insert({
    required String id,
    required String transactionId,
    required int revision,
    required int decision,
    required int minorUnits,
    required String currency,
    required String allocationFingerprint,
    required String allocationHistoryFingerprint,
    required int remainderMinorUnits,
    required DateTime recordedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       transactionId = Value(transactionId),
       revision = Value(revision),
       decision = Value(decision),
       minorUnits = Value(minorUnits),
       currency = Value(currency),
       allocationFingerprint = Value(allocationFingerprint),
       allocationHistoryFingerprint = Value(allocationHistoryFingerprint),
       remainderMinorUnits = Value(remainderMinorUnits),
       recordedAt = Value(recordedAt);
  static Insertable<RelationshipReview> custom({
    Expression<String>? id,
    Expression<String>? transactionId,
    Expression<int>? revision,
    Expression<int>? decision,
    Expression<int>? minorUnits,
    Expression<String>? currency,
    Expression<String>? allocationFingerprint,
    Expression<String>? allocationHistoryFingerprint,
    Expression<int>? remainderMinorUnits,
    Expression<DateTime>? recordedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (transactionId != null) 'transaction_id': transactionId,
      if (revision != null) 'revision': revision,
      if (decision != null) 'decision': decision,
      if (minorUnits != null) 'minor_units': minorUnits,
      if (currency != null) 'currency': currency,
      if (allocationFingerprint != null)
        'allocation_fingerprint': allocationFingerprint,
      if (allocationHistoryFingerprint != null)
        'allocation_history_fingerprint': allocationHistoryFingerprint,
      if (remainderMinorUnits != null)
        'remainder_minor_units': remainderMinorUnits,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RelationshipReviewsCompanion copyWith({
    Value<String>? id,
    Value<String>? transactionId,
    Value<int>? revision,
    Value<int>? decision,
    Value<int>? minorUnits,
    Value<String>? currency,
    Value<String>? allocationFingerprint,
    Value<String>? allocationHistoryFingerprint,
    Value<int>? remainderMinorUnits,
    Value<DateTime>? recordedAt,
    Value<int>? rowid,
  }) {
    return RelationshipReviewsCompanion(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      revision: revision ?? this.revision,
      decision: decision ?? this.decision,
      minorUnits: minorUnits ?? this.minorUnits,
      currency: currency ?? this.currency,
      allocationFingerprint:
          allocationFingerprint ?? this.allocationFingerprint,
      allocationHistoryFingerprint:
          allocationHistoryFingerprint ?? this.allocationHistoryFingerprint,
      remainderMinorUnits: remainderMinorUnits ?? this.remainderMinorUnits,
      recordedAt: recordedAt ?? this.recordedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (transactionId.present) {
      map['transaction_id'] = Variable<String>(transactionId.value);
    }
    if (revision.present) {
      map['revision'] = Variable<int>(revision.value);
    }
    if (decision.present) {
      map['decision'] = Variable<int>(decision.value);
    }
    if (minorUnits.present) {
      map['minor_units'] = Variable<int>(minorUnits.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (allocationFingerprint.present) {
      map['allocation_fingerprint'] = Variable<String>(
        allocationFingerprint.value,
      );
    }
    if (allocationHistoryFingerprint.present) {
      map['allocation_history_fingerprint'] = Variable<String>(
        allocationHistoryFingerprint.value,
      );
    }
    if (remainderMinorUnits.present) {
      map['remainder_minor_units'] = Variable<int>(remainderMinorUnits.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RelationshipReviewsCompanion(')
          ..write('id: $id, ')
          ..write('transactionId: $transactionId, ')
          ..write('revision: $revision, ')
          ..write('decision: $decision, ')
          ..write('minorUnits: $minorUnits, ')
          ..write('currency: $currency, ')
          ..write('allocationFingerprint: $allocationFingerprint, ')
          ..write(
            'allocationHistoryFingerprint: $allocationHistoryFingerprint, ',
          )
          ..write('remainderMinorUnits: $remainderMinorUnits, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FinancialExpectationsTable extends FinancialExpectations
    with TableInfo<$FinancialExpectationsTable, FinancialExpectation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FinancialExpectationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _occurrenceIdMeta = const VerificationMeta(
    'occurrenceId',
  );
  @override
  late final GeneratedColumn<String> occurrenceId = GeneratedColumn<String>(
    'occurrence_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES occurrences (id)',
    ),
  );
  static const VerificationMeta _directionMeta = const VerificationMeta(
    'direction',
  );
  @override
  late final GeneratedColumn<int> direction = GeneratedColumn<int>(
    'direction',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _minorUnitsMeta = const VerificationMeta(
    'minorUnits',
  );
  @override
  late final GeneratedColumn<int> minorUnits = GeneratedColumn<int>(
    'minor_units',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES financial_accounts (id)',
    ),
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
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    occurrenceId,
    direction,
    minorUnits,
    currency,
    accountId,
    status,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'financial_expectations';
  @override
  VerificationContext validateIntegrity(
    Insertable<FinancialExpectation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('occurrence_id')) {
      context.handle(
        _occurrenceIdMeta,
        occurrenceId.isAcceptableOrUnknown(
          data['occurrence_id']!,
          _occurrenceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_occurrenceIdMeta);
    }
    if (data.containsKey('direction')) {
      context.handle(
        _directionMeta,
        direction.isAcceptableOrUnknown(data['direction']!, _directionMeta),
      );
    } else if (isInserting) {
      context.missing(_directionMeta);
    }
    if (data.containsKey('minor_units')) {
      context.handle(
        _minorUnitsMeta,
        minorUnits.isAcceptableOrUnknown(data['minor_units']!, _minorUnitsMeta),
      );
    } else if (isInserting) {
      context.missing(_minorUnitsMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {occurrenceId},
  ];
  @override
  FinancialExpectation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FinancialExpectation(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      occurrenceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}occurrence_id'],
      )!,
      direction: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}direction'],
      )!,
      minorUnits: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}minor_units'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      ),
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $FinancialExpectationsTable createAlias(String alias) {
    return $FinancialExpectationsTable(attachedDatabase, alias);
  }
}

class FinancialExpectation extends DataClass
    implements Insertable<FinancialExpectation> {
  final String id;
  final String occurrenceId;
  final int direction;
  final int minorUnits;
  final String? currency;
  final String? accountId;
  final int status;
  final DateTime createdAt;
  final DateTime updatedAt;
  const FinancialExpectation({
    required this.id,
    required this.occurrenceId,
    required this.direction,
    required this.minorUnits,
    this.currency,
    this.accountId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['occurrence_id'] = Variable<String>(occurrenceId);
    map['direction'] = Variable<int>(direction);
    map['minor_units'] = Variable<int>(minorUnits);
    if (!nullToAbsent || currency != null) {
      map['currency'] = Variable<String>(currency);
    }
    if (!nullToAbsent || accountId != null) {
      map['account_id'] = Variable<String>(accountId);
    }
    map['status'] = Variable<int>(status);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  FinancialExpectationsCompanion toCompanion(bool nullToAbsent) {
    return FinancialExpectationsCompanion(
      id: Value(id),
      occurrenceId: Value(occurrenceId),
      direction: Value(direction),
      minorUnits: Value(minorUnits),
      currency: currency == null && nullToAbsent
          ? const Value.absent()
          : Value(currency),
      accountId: accountId == null && nullToAbsent
          ? const Value.absent()
          : Value(accountId),
      status: Value(status),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory FinancialExpectation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FinancialExpectation(
      id: serializer.fromJson<String>(json['id']),
      occurrenceId: serializer.fromJson<String>(json['occurrenceId']),
      direction: serializer.fromJson<int>(json['direction']),
      minorUnits: serializer.fromJson<int>(json['minorUnits']),
      currency: serializer.fromJson<String?>(json['currency']),
      accountId: serializer.fromJson<String?>(json['accountId']),
      status: serializer.fromJson<int>(json['status']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'occurrenceId': serializer.toJson<String>(occurrenceId),
      'direction': serializer.toJson<int>(direction),
      'minorUnits': serializer.toJson<int>(minorUnits),
      'currency': serializer.toJson<String?>(currency),
      'accountId': serializer.toJson<String?>(accountId),
      'status': serializer.toJson<int>(status),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  FinancialExpectation copyWith({
    String? id,
    String? occurrenceId,
    int? direction,
    int? minorUnits,
    Value<String?> currency = const Value.absent(),
    Value<String?> accountId = const Value.absent(),
    int? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => FinancialExpectation(
    id: id ?? this.id,
    occurrenceId: occurrenceId ?? this.occurrenceId,
    direction: direction ?? this.direction,
    minorUnits: minorUnits ?? this.minorUnits,
    currency: currency.present ? currency.value : this.currency,
    accountId: accountId.present ? accountId.value : this.accountId,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  FinancialExpectation copyWithCompanion(FinancialExpectationsCompanion data) {
    return FinancialExpectation(
      id: data.id.present ? data.id.value : this.id,
      occurrenceId: data.occurrenceId.present
          ? data.occurrenceId.value
          : this.occurrenceId,
      direction: data.direction.present ? data.direction.value : this.direction,
      minorUnits: data.minorUnits.present
          ? data.minorUnits.value
          : this.minorUnits,
      currency: data.currency.present ? data.currency.value : this.currency,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FinancialExpectation(')
          ..write('id: $id, ')
          ..write('occurrenceId: $occurrenceId, ')
          ..write('direction: $direction, ')
          ..write('minorUnits: $minorUnits, ')
          ..write('currency: $currency, ')
          ..write('accountId: $accountId, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    occurrenceId,
    direction,
    minorUnits,
    currency,
    accountId,
    status,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FinancialExpectation &&
          other.id == this.id &&
          other.occurrenceId == this.occurrenceId &&
          other.direction == this.direction &&
          other.minorUnits == this.minorUnits &&
          other.currency == this.currency &&
          other.accountId == this.accountId &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class FinancialExpectationsCompanion
    extends UpdateCompanion<FinancialExpectation> {
  final Value<String> id;
  final Value<String> occurrenceId;
  final Value<int> direction;
  final Value<int> minorUnits;
  final Value<String?> currency;
  final Value<String?> accountId;
  final Value<int> status;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const FinancialExpectationsCompanion({
    this.id = const Value.absent(),
    this.occurrenceId = const Value.absent(),
    this.direction = const Value.absent(),
    this.minorUnits = const Value.absent(),
    this.currency = const Value.absent(),
    this.accountId = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FinancialExpectationsCompanion.insert({
    required String id,
    required String occurrenceId,
    required int direction,
    required int minorUnits,
    this.currency = const Value.absent(),
    this.accountId = const Value.absent(),
    required int status,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       occurrenceId = Value(occurrenceId),
       direction = Value(direction),
       minorUnits = Value(minorUnits),
       status = Value(status),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<FinancialExpectation> custom({
    Expression<String>? id,
    Expression<String>? occurrenceId,
    Expression<int>? direction,
    Expression<int>? minorUnits,
    Expression<String>? currency,
    Expression<String>? accountId,
    Expression<int>? status,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (occurrenceId != null) 'occurrence_id': occurrenceId,
      if (direction != null) 'direction': direction,
      if (minorUnits != null) 'minor_units': minorUnits,
      if (currency != null) 'currency': currency,
      if (accountId != null) 'account_id': accountId,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FinancialExpectationsCompanion copyWith({
    Value<String>? id,
    Value<String>? occurrenceId,
    Value<int>? direction,
    Value<int>? minorUnits,
    Value<String?>? currency,
    Value<String?>? accountId,
    Value<int>? status,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return FinancialExpectationsCompanion(
      id: id ?? this.id,
      occurrenceId: occurrenceId ?? this.occurrenceId,
      direction: direction ?? this.direction,
      minorUnits: minorUnits ?? this.minorUnits,
      currency: currency ?? this.currency,
      accountId: accountId ?? this.accountId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (occurrenceId.present) {
      map['occurrence_id'] = Variable<String>(occurrenceId.value);
    }
    if (direction.present) {
      map['direction'] = Variable<int>(direction.value);
    }
    if (minorUnits.present) {
      map['minor_units'] = Variable<int>(minorUnits.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (status.present) {
      map['status'] = Variable<int>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FinancialExpectationsCompanion(')
          ..write('id: $id, ')
          ..write('occurrenceId: $occurrenceId, ')
          ..write('direction: $direction, ')
          ..write('minorUnits: $minorUnits, ')
          ..write('currency: $currency, ')
          ..write('accountId: $accountId, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TagsTable extends Tags with TableInfo<$TagsTable, Tag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _normalizedLabelMeta = const VerificationMeta(
    'normalizedLabel',
  );
  @override
  late final GeneratedColumn<String> normalizedLabel = GeneratedColumn<String>(
    'normalized_label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
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
  @override
  List<GeneratedColumn> get $columns => [id, label, normalizedLabel, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<Tag> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('normalized_label')) {
      context.handle(
        _normalizedLabelMeta,
        normalizedLabel.isAcceptableOrUnknown(
          data['normalized_label']!,
          _normalizedLabelMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_normalizedLabelMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Tag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Tag(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      normalizedLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}normalized_label'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $TagsTable createAlias(String alias) {
    return $TagsTable(attachedDatabase, alias);
  }
}

class Tag extends DataClass implements Insertable<Tag> {
  final String id;
  final String label;
  final String normalizedLabel;
  final DateTime createdAt;
  const Tag({
    required this.id,
    required this.label,
    required this.normalizedLabel,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['label'] = Variable<String>(label);
    map['normalized_label'] = Variable<String>(normalizedLabel);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  TagsCompanion toCompanion(bool nullToAbsent) {
    return TagsCompanion(
      id: Value(id),
      label: Value(label),
      normalizedLabel: Value(normalizedLabel),
      createdAt: Value(createdAt),
    );
  }

  factory Tag.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Tag(
      id: serializer.fromJson<String>(json['id']),
      label: serializer.fromJson<String>(json['label']),
      normalizedLabel: serializer.fromJson<String>(json['normalizedLabel']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'label': serializer.toJson<String>(label),
      'normalizedLabel': serializer.toJson<String>(normalizedLabel),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Tag copyWith({
    String? id,
    String? label,
    String? normalizedLabel,
    DateTime? createdAt,
  }) => Tag(
    id: id ?? this.id,
    label: label ?? this.label,
    normalizedLabel: normalizedLabel ?? this.normalizedLabel,
    createdAt: createdAt ?? this.createdAt,
  );
  Tag copyWithCompanion(TagsCompanion data) {
    return Tag(
      id: data.id.present ? data.id.value : this.id,
      label: data.label.present ? data.label.value : this.label,
      normalizedLabel: data.normalizedLabel.present
          ? data.normalizedLabel.value
          : this.normalizedLabel,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Tag(')
          ..write('id: $id, ')
          ..write('label: $label, ')
          ..write('normalizedLabel: $normalizedLabel, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, label, normalizedLabel, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Tag &&
          other.id == this.id &&
          other.label == this.label &&
          other.normalizedLabel == this.normalizedLabel &&
          other.createdAt == this.createdAt);
}

class TagsCompanion extends UpdateCompanion<Tag> {
  final Value<String> id;
  final Value<String> label;
  final Value<String> normalizedLabel;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const TagsCompanion({
    this.id = const Value.absent(),
    this.label = const Value.absent(),
    this.normalizedLabel = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TagsCompanion.insert({
    required String id,
    required String label,
    required String normalizedLabel,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       label = Value(label),
       normalizedLabel = Value(normalizedLabel),
       createdAt = Value(createdAt);
  static Insertable<Tag> custom({
    Expression<String>? id,
    Expression<String>? label,
    Expression<String>? normalizedLabel,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (label != null) 'label': label,
      if (normalizedLabel != null) 'normalized_label': normalizedLabel,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TagsCompanion copyWith({
    Value<String>? id,
    Value<String>? label,
    Value<String>? normalizedLabel,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return TagsCompanion(
      id: id ?? this.id,
      label: label ?? this.label,
      normalizedLabel: normalizedLabel ?? this.normalizedLabel,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (normalizedLabel.present) {
      map['normalized_label'] = Variable<String>(normalizedLabel.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TagsCompanion(')
          ..write('id: $id, ')
          ..write('label: $label, ')
          ..write('normalizedLabel: $normalizedLabel, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CommitmentTagsTable extends CommitmentTags
    with TableInfo<$CommitmentTagsTable, CommitmentTag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CommitmentTagsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _tagIdMeta = const VerificationMeta('tagId');
  @override
  late final GeneratedColumn<String> tagId = GeneratedColumn<String>(
    'tag_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tags (id)',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [commitmentId, tagId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'commitment_tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<CommitmentTag> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
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
    if (data.containsKey('tag_id')) {
      context.handle(
        _tagIdMeta,
        tagId.isAcceptableOrUnknown(data['tag_id']!, _tagIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tagIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {commitmentId, tagId};
  @override
  CommitmentTag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CommitmentTag(
      commitmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}commitment_id'],
      )!,
      tagId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tag_id'],
      )!,
    );
  }

  @override
  $CommitmentTagsTable createAlias(String alias) {
    return $CommitmentTagsTable(attachedDatabase, alias);
  }
}

class CommitmentTag extends DataClass implements Insertable<CommitmentTag> {
  final String commitmentId;
  final String tagId;
  const CommitmentTag({required this.commitmentId, required this.tagId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['commitment_id'] = Variable<String>(commitmentId);
    map['tag_id'] = Variable<String>(tagId);
    return map;
  }

  CommitmentTagsCompanion toCompanion(bool nullToAbsent) {
    return CommitmentTagsCompanion(
      commitmentId: Value(commitmentId),
      tagId: Value(tagId),
    );
  }

  factory CommitmentTag.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CommitmentTag(
      commitmentId: serializer.fromJson<String>(json['commitmentId']),
      tagId: serializer.fromJson<String>(json['tagId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'commitmentId': serializer.toJson<String>(commitmentId),
      'tagId': serializer.toJson<String>(tagId),
    };
  }

  CommitmentTag copyWith({String? commitmentId, String? tagId}) =>
      CommitmentTag(
        commitmentId: commitmentId ?? this.commitmentId,
        tagId: tagId ?? this.tagId,
      );
  CommitmentTag copyWithCompanion(CommitmentTagsCompanion data) {
    return CommitmentTag(
      commitmentId: data.commitmentId.present
          ? data.commitmentId.value
          : this.commitmentId,
      tagId: data.tagId.present ? data.tagId.value : this.tagId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CommitmentTag(')
          ..write('commitmentId: $commitmentId, ')
          ..write('tagId: $tagId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(commitmentId, tagId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CommitmentTag &&
          other.commitmentId == this.commitmentId &&
          other.tagId == this.tagId);
}

class CommitmentTagsCompanion extends UpdateCompanion<CommitmentTag> {
  final Value<String> commitmentId;
  final Value<String> tagId;
  final Value<int> rowid;
  const CommitmentTagsCompanion({
    this.commitmentId = const Value.absent(),
    this.tagId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CommitmentTagsCompanion.insert({
    required String commitmentId,
    required String tagId,
    this.rowid = const Value.absent(),
  }) : commitmentId = Value(commitmentId),
       tagId = Value(tagId);
  static Insertable<CommitmentTag> custom({
    Expression<String>? commitmentId,
    Expression<String>? tagId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (commitmentId != null) 'commitment_id': commitmentId,
      if (tagId != null) 'tag_id': tagId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CommitmentTagsCompanion copyWith({
    Value<String>? commitmentId,
    Value<String>? tagId,
    Value<int>? rowid,
  }) {
    return CommitmentTagsCompanion(
      commitmentId: commitmentId ?? this.commitmentId,
      tagId: tagId ?? this.tagId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (commitmentId.present) {
      map['commitment_id'] = Variable<String>(commitmentId.value);
    }
    if (tagId.present) {
      map['tag_id'] = Variable<String>(tagId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CommitmentTagsCompanion(')
          ..write('commitmentId: $commitmentId, ')
          ..write('tagId: $tagId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AccountEntryTagsTable extends AccountEntryTags
    with TableInfo<$AccountEntryTagsTable, AccountEntryTag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccountEntryTagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _accountEntryIdMeta = const VerificationMeta(
    'accountEntryId',
  );
  @override
  late final GeneratedColumn<String> accountEntryId = GeneratedColumn<String>(
    'account_entry_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES account_entries (id)',
    ),
  );
  static const VerificationMeta _tagIdMeta = const VerificationMeta('tagId');
  @override
  late final GeneratedColumn<String> tagId = GeneratedColumn<String>(
    'tag_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tags (id)',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [accountEntryId, tagId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'account_entry_tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<AccountEntryTag> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('account_entry_id')) {
      context.handle(
        _accountEntryIdMeta,
        accountEntryId.isAcceptableOrUnknown(
          data['account_entry_id']!,
          _accountEntryIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_accountEntryIdMeta);
    }
    if (data.containsKey('tag_id')) {
      context.handle(
        _tagIdMeta,
        tagId.isAcceptableOrUnknown(data['tag_id']!, _tagIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tagIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {accountEntryId, tagId};
  @override
  AccountEntryTag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AccountEntryTag(
      accountEntryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_entry_id'],
      )!,
      tagId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tag_id'],
      )!,
    );
  }

  @override
  $AccountEntryTagsTable createAlias(String alias) {
    return $AccountEntryTagsTable(attachedDatabase, alias);
  }
}

class AccountEntryTag extends DataClass implements Insertable<AccountEntryTag> {
  final String accountEntryId;
  final String tagId;
  const AccountEntryTag({required this.accountEntryId, required this.tagId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['account_entry_id'] = Variable<String>(accountEntryId);
    map['tag_id'] = Variable<String>(tagId);
    return map;
  }

  AccountEntryTagsCompanion toCompanion(bool nullToAbsent) {
    return AccountEntryTagsCompanion(
      accountEntryId: Value(accountEntryId),
      tagId: Value(tagId),
    );
  }

  factory AccountEntryTag.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AccountEntryTag(
      accountEntryId: serializer.fromJson<String>(json['accountEntryId']),
      tagId: serializer.fromJson<String>(json['tagId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'accountEntryId': serializer.toJson<String>(accountEntryId),
      'tagId': serializer.toJson<String>(tagId),
    };
  }

  AccountEntryTag copyWith({String? accountEntryId, String? tagId}) =>
      AccountEntryTag(
        accountEntryId: accountEntryId ?? this.accountEntryId,
        tagId: tagId ?? this.tagId,
      );
  AccountEntryTag copyWithCompanion(AccountEntryTagsCompanion data) {
    return AccountEntryTag(
      accountEntryId: data.accountEntryId.present
          ? data.accountEntryId.value
          : this.accountEntryId,
      tagId: data.tagId.present ? data.tagId.value : this.tagId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AccountEntryTag(')
          ..write('accountEntryId: $accountEntryId, ')
          ..write('tagId: $tagId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(accountEntryId, tagId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AccountEntryTag &&
          other.accountEntryId == this.accountEntryId &&
          other.tagId == this.tagId);
}

class AccountEntryTagsCompanion extends UpdateCompanion<AccountEntryTag> {
  final Value<String> accountEntryId;
  final Value<String> tagId;
  final Value<int> rowid;
  const AccountEntryTagsCompanion({
    this.accountEntryId = const Value.absent(),
    this.tagId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AccountEntryTagsCompanion.insert({
    required String accountEntryId,
    required String tagId,
    this.rowid = const Value.absent(),
  }) : accountEntryId = Value(accountEntryId),
       tagId = Value(tagId);
  static Insertable<AccountEntryTag> custom({
    Expression<String>? accountEntryId,
    Expression<String>? tagId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (accountEntryId != null) 'account_entry_id': accountEntryId,
      if (tagId != null) 'tag_id': tagId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AccountEntryTagsCompanion copyWith({
    Value<String>? accountEntryId,
    Value<String>? tagId,
    Value<int>? rowid,
  }) {
    return AccountEntryTagsCompanion(
      accountEntryId: accountEntryId ?? this.accountEntryId,
      tagId: tagId ?? this.tagId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (accountEntryId.present) {
      map['account_entry_id'] = Variable<String>(accountEntryId.value);
    }
    if (tagId.present) {
      map['tag_id'] = Variable<String>(tagId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccountEntryTagsCompanion(')
          ..write('accountEntryId: $accountEntryId, ')
          ..write('tagId: $tagId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StagedImportsTable extends StagedImports
    with TableInfo<$StagedImportsTable, StagedImport> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StagedImportsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rawTextMeta = const VerificationMeta(
    'rawText',
  );
  @override
  late final GeneratedColumn<String> rawText = GeneratedColumn<String>(
    'raw_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fingerprintMeta = const VerificationMeta(
    'fingerprint',
  );
  @override
  late final GeneratedColumn<String> fingerprint = GeneratedColumn<String>(
    'fingerprint',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _retentionStatusMeta = const VerificationMeta(
    'retentionStatus',
  );
  @override
  late final GeneratedColumn<int> retentionStatus = GeneratedColumn<int>(
    'retention_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _retentionUntilMeta = const VerificationMeta(
    'retentionUntil',
  );
  @override
  late final GeneratedColumn<DateTime> retentionUntil =
      GeneratedColumn<DateTime>(
        'retention_until',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastDecisionAtMeta = const VerificationMeta(
    'lastDecisionAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastDecisionAt =
      GeneratedColumn<DateTime>(
        'last_decision_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<int> source = GeneratedColumn<int>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceKeyMeta = const VerificationMeta(
    'sourceKey',
  );
  @override
  late final GeneratedColumn<String> sourceKey = GeneratedColumn<String>(
    'source_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _importedAtMeta = const VerificationMeta(
    'importedAt',
  );
  @override
  late final GeneratedColumn<DateTime> importedAt = GeneratedColumn<DateTime>(
    'imported_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _adapterVersionMeta = const VerificationMeta(
    'adapterVersion',
  );
  @override
  late final GeneratedColumn<String> adapterVersion = GeneratedColumn<String>(
    'adapter_version',
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    rawText,
    fingerprint,
    retentionStatus,
    retentionUntil,
    lastDecisionAt,
    source,
    sourceKey,
    importedAt,
    adapterVersion,
    status,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'staged_imports';
  @override
  VerificationContext validateIntegrity(
    Insertable<StagedImport> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('raw_text')) {
      context.handle(
        _rawTextMeta,
        rawText.isAcceptableOrUnknown(data['raw_text']!, _rawTextMeta),
      );
    } else if (isInserting) {
      context.missing(_rawTextMeta);
    }
    if (data.containsKey('fingerprint')) {
      context.handle(
        _fingerprintMeta,
        fingerprint.isAcceptableOrUnknown(
          data['fingerprint']!,
          _fingerprintMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fingerprintMeta);
    }
    if (data.containsKey('retention_status')) {
      context.handle(
        _retentionStatusMeta,
        retentionStatus.isAcceptableOrUnknown(
          data['retention_status']!,
          _retentionStatusMeta,
        ),
      );
    }
    if (data.containsKey('retention_until')) {
      context.handle(
        _retentionUntilMeta,
        retentionUntil.isAcceptableOrUnknown(
          data['retention_until']!,
          _retentionUntilMeta,
        ),
      );
    }
    if (data.containsKey('last_decision_at')) {
      context.handle(
        _lastDecisionAtMeta,
        lastDecisionAt.isAcceptableOrUnknown(
          data['last_decision_at']!,
          _lastDecisionAtMeta,
        ),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('source_key')) {
      context.handle(
        _sourceKeyMeta,
        sourceKey.isAcceptableOrUnknown(data['source_key']!, _sourceKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceKeyMeta);
    }
    if (data.containsKey('imported_at')) {
      context.handle(
        _importedAtMeta,
        importedAt.isAcceptableOrUnknown(data['imported_at']!, _importedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_importedAtMeta);
    }
    if (data.containsKey('adapter_version')) {
      context.handle(
        _adapterVersionMeta,
        adapterVersion.isAcceptableOrUnknown(
          data['adapter_version']!,
          _adapterVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_adapterVersionMeta);
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
  StagedImport map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StagedImport(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      rawText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_text'],
      )!,
      fingerprint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fingerprint'],
      )!,
      retentionStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retention_status'],
      )!,
      retentionUntil: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}retention_until'],
      ),
      lastDecisionAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_decision_at'],
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}source'],
      )!,
      sourceKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_key'],
      )!,
      importedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}imported_at'],
      )!,
      adapterVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}adapter_version'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}status'],
      )!,
    );
  }

  @override
  $StagedImportsTable createAlias(String alias) {
    return $StagedImportsTable(attachedDatabase, alias);
  }
}

class StagedImport extends DataClass implements Insertable<StagedImport> {
  final String id;
  final String rawText;
  final String fingerprint;
  final int retentionStatus;
  final DateTime? retentionUntil;
  final DateTime? lastDecisionAt;
  final int source;
  final String sourceKey;
  final DateTime importedAt;
  final String adapterVersion;
  final int status;
  const StagedImport({
    required this.id,
    required this.rawText,
    required this.fingerprint,
    required this.retentionStatus,
    this.retentionUntil,
    this.lastDecisionAt,
    required this.source,
    required this.sourceKey,
    required this.importedAt,
    required this.adapterVersion,
    required this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['raw_text'] = Variable<String>(rawText);
    map['fingerprint'] = Variable<String>(fingerprint);
    map['retention_status'] = Variable<int>(retentionStatus);
    if (!nullToAbsent || retentionUntil != null) {
      map['retention_until'] = Variable<DateTime>(retentionUntil);
    }
    if (!nullToAbsent || lastDecisionAt != null) {
      map['last_decision_at'] = Variable<DateTime>(lastDecisionAt);
    }
    map['source'] = Variable<int>(source);
    map['source_key'] = Variable<String>(sourceKey);
    map['imported_at'] = Variable<DateTime>(importedAt);
    map['adapter_version'] = Variable<String>(adapterVersion);
    map['status'] = Variable<int>(status);
    return map;
  }

  StagedImportsCompanion toCompanion(bool nullToAbsent) {
    return StagedImportsCompanion(
      id: Value(id),
      rawText: Value(rawText),
      fingerprint: Value(fingerprint),
      retentionStatus: Value(retentionStatus),
      retentionUntil: retentionUntil == null && nullToAbsent
          ? const Value.absent()
          : Value(retentionUntil),
      lastDecisionAt: lastDecisionAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastDecisionAt),
      source: Value(source),
      sourceKey: Value(sourceKey),
      importedAt: Value(importedAt),
      adapterVersion: Value(adapterVersion),
      status: Value(status),
    );
  }

  factory StagedImport.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StagedImport(
      id: serializer.fromJson<String>(json['id']),
      rawText: serializer.fromJson<String>(json['rawText']),
      fingerprint: serializer.fromJson<String>(json['fingerprint']),
      retentionStatus: serializer.fromJson<int>(json['retentionStatus']),
      retentionUntil: serializer.fromJson<DateTime?>(json['retentionUntil']),
      lastDecisionAt: serializer.fromJson<DateTime?>(json['lastDecisionAt']),
      source: serializer.fromJson<int>(json['source']),
      sourceKey: serializer.fromJson<String>(json['sourceKey']),
      importedAt: serializer.fromJson<DateTime>(json['importedAt']),
      adapterVersion: serializer.fromJson<String>(json['adapterVersion']),
      status: serializer.fromJson<int>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'rawText': serializer.toJson<String>(rawText),
      'fingerprint': serializer.toJson<String>(fingerprint),
      'retentionStatus': serializer.toJson<int>(retentionStatus),
      'retentionUntil': serializer.toJson<DateTime?>(retentionUntil),
      'lastDecisionAt': serializer.toJson<DateTime?>(lastDecisionAt),
      'source': serializer.toJson<int>(source),
      'sourceKey': serializer.toJson<String>(sourceKey),
      'importedAt': serializer.toJson<DateTime>(importedAt),
      'adapterVersion': serializer.toJson<String>(adapterVersion),
      'status': serializer.toJson<int>(status),
    };
  }

  StagedImport copyWith({
    String? id,
    String? rawText,
    String? fingerprint,
    int? retentionStatus,
    Value<DateTime?> retentionUntil = const Value.absent(),
    Value<DateTime?> lastDecisionAt = const Value.absent(),
    int? source,
    String? sourceKey,
    DateTime? importedAt,
    String? adapterVersion,
    int? status,
  }) => StagedImport(
    id: id ?? this.id,
    rawText: rawText ?? this.rawText,
    fingerprint: fingerprint ?? this.fingerprint,
    retentionStatus: retentionStatus ?? this.retentionStatus,
    retentionUntil: retentionUntil.present
        ? retentionUntil.value
        : this.retentionUntil,
    lastDecisionAt: lastDecisionAt.present
        ? lastDecisionAt.value
        : this.lastDecisionAt,
    source: source ?? this.source,
    sourceKey: sourceKey ?? this.sourceKey,
    importedAt: importedAt ?? this.importedAt,
    adapterVersion: adapterVersion ?? this.adapterVersion,
    status: status ?? this.status,
  );
  StagedImport copyWithCompanion(StagedImportsCompanion data) {
    return StagedImport(
      id: data.id.present ? data.id.value : this.id,
      rawText: data.rawText.present ? data.rawText.value : this.rawText,
      fingerprint: data.fingerprint.present
          ? data.fingerprint.value
          : this.fingerprint,
      retentionStatus: data.retentionStatus.present
          ? data.retentionStatus.value
          : this.retentionStatus,
      retentionUntil: data.retentionUntil.present
          ? data.retentionUntil.value
          : this.retentionUntil,
      lastDecisionAt: data.lastDecisionAt.present
          ? data.lastDecisionAt.value
          : this.lastDecisionAt,
      source: data.source.present ? data.source.value : this.source,
      sourceKey: data.sourceKey.present ? data.sourceKey.value : this.sourceKey,
      importedAt: data.importedAt.present
          ? data.importedAt.value
          : this.importedAt,
      adapterVersion: data.adapterVersion.present
          ? data.adapterVersion.value
          : this.adapterVersion,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StagedImport(')
          ..write('id: $id, ')
          ..write('rawText: $rawText, ')
          ..write('fingerprint: $fingerprint, ')
          ..write('retentionStatus: $retentionStatus, ')
          ..write('retentionUntil: $retentionUntil, ')
          ..write('lastDecisionAt: $lastDecisionAt, ')
          ..write('source: $source, ')
          ..write('sourceKey: $sourceKey, ')
          ..write('importedAt: $importedAt, ')
          ..write('adapterVersion: $adapterVersion, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    rawText,
    fingerprint,
    retentionStatus,
    retentionUntil,
    lastDecisionAt,
    source,
    sourceKey,
    importedAt,
    adapterVersion,
    status,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StagedImport &&
          other.id == this.id &&
          other.rawText == this.rawText &&
          other.fingerprint == this.fingerprint &&
          other.retentionStatus == this.retentionStatus &&
          other.retentionUntil == this.retentionUntil &&
          other.lastDecisionAt == this.lastDecisionAt &&
          other.source == this.source &&
          other.sourceKey == this.sourceKey &&
          other.importedAt == this.importedAt &&
          other.adapterVersion == this.adapterVersion &&
          other.status == this.status);
}

class StagedImportsCompanion extends UpdateCompanion<StagedImport> {
  final Value<String> id;
  final Value<String> rawText;
  final Value<String> fingerprint;
  final Value<int> retentionStatus;
  final Value<DateTime?> retentionUntil;
  final Value<DateTime?> lastDecisionAt;
  final Value<int> source;
  final Value<String> sourceKey;
  final Value<DateTime> importedAt;
  final Value<String> adapterVersion;
  final Value<int> status;
  final Value<int> rowid;
  const StagedImportsCompanion({
    this.id = const Value.absent(),
    this.rawText = const Value.absent(),
    this.fingerprint = const Value.absent(),
    this.retentionStatus = const Value.absent(),
    this.retentionUntil = const Value.absent(),
    this.lastDecisionAt = const Value.absent(),
    this.source = const Value.absent(),
    this.sourceKey = const Value.absent(),
    this.importedAt = const Value.absent(),
    this.adapterVersion = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StagedImportsCompanion.insert({
    required String id,
    required String rawText,
    required String fingerprint,
    this.retentionStatus = const Value.absent(),
    this.retentionUntil = const Value.absent(),
    this.lastDecisionAt = const Value.absent(),
    required int source,
    required String sourceKey,
    required DateTime importedAt,
    required String adapterVersion,
    required int status,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       rawText = Value(rawText),
       fingerprint = Value(fingerprint),
       source = Value(source),
       sourceKey = Value(sourceKey),
       importedAt = Value(importedAt),
       adapterVersion = Value(adapterVersion),
       status = Value(status);
  static Insertable<StagedImport> custom({
    Expression<String>? id,
    Expression<String>? rawText,
    Expression<String>? fingerprint,
    Expression<int>? retentionStatus,
    Expression<DateTime>? retentionUntil,
    Expression<DateTime>? lastDecisionAt,
    Expression<int>? source,
    Expression<String>? sourceKey,
    Expression<DateTime>? importedAt,
    Expression<String>? adapterVersion,
    Expression<int>? status,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (rawText != null) 'raw_text': rawText,
      if (fingerprint != null) 'fingerprint': fingerprint,
      if (retentionStatus != null) 'retention_status': retentionStatus,
      if (retentionUntil != null) 'retention_until': retentionUntil,
      if (lastDecisionAt != null) 'last_decision_at': lastDecisionAt,
      if (source != null) 'source': source,
      if (sourceKey != null) 'source_key': sourceKey,
      if (importedAt != null) 'imported_at': importedAt,
      if (adapterVersion != null) 'adapter_version': adapterVersion,
      if (status != null) 'status': status,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StagedImportsCompanion copyWith({
    Value<String>? id,
    Value<String>? rawText,
    Value<String>? fingerprint,
    Value<int>? retentionStatus,
    Value<DateTime?>? retentionUntil,
    Value<DateTime?>? lastDecisionAt,
    Value<int>? source,
    Value<String>? sourceKey,
    Value<DateTime>? importedAt,
    Value<String>? adapterVersion,
    Value<int>? status,
    Value<int>? rowid,
  }) {
    return StagedImportsCompanion(
      id: id ?? this.id,
      rawText: rawText ?? this.rawText,
      fingerprint: fingerprint ?? this.fingerprint,
      retentionStatus: retentionStatus ?? this.retentionStatus,
      retentionUntil: retentionUntil ?? this.retentionUntil,
      lastDecisionAt: lastDecisionAt ?? this.lastDecisionAt,
      source: source ?? this.source,
      sourceKey: sourceKey ?? this.sourceKey,
      importedAt: importedAt ?? this.importedAt,
      adapterVersion: adapterVersion ?? this.adapterVersion,
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
    if (rawText.present) {
      map['raw_text'] = Variable<String>(rawText.value);
    }
    if (fingerprint.present) {
      map['fingerprint'] = Variable<String>(fingerprint.value);
    }
    if (retentionStatus.present) {
      map['retention_status'] = Variable<int>(retentionStatus.value);
    }
    if (retentionUntil.present) {
      map['retention_until'] = Variable<DateTime>(retentionUntil.value);
    }
    if (lastDecisionAt.present) {
      map['last_decision_at'] = Variable<DateTime>(lastDecisionAt.value);
    }
    if (source.present) {
      map['source'] = Variable<int>(source.value);
    }
    if (sourceKey.present) {
      map['source_key'] = Variable<String>(sourceKey.value);
    }
    if (importedAt.present) {
      map['imported_at'] = Variable<DateTime>(importedAt.value);
    }
    if (adapterVersion.present) {
      map['adapter_version'] = Variable<String>(adapterVersion.value);
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
    return (StringBuffer('StagedImportsCompanion(')
          ..write('id: $id, ')
          ..write('rawText: $rawText, ')
          ..write('fingerprint: $fingerprint, ')
          ..write('retentionStatus: $retentionStatus, ')
          ..write('retentionUntil: $retentionUntil, ')
          ..write('lastDecisionAt: $lastDecisionAt, ')
          ..write('source: $source, ')
          ..write('sourceKey: $sourceKey, ')
          ..write('importedAt: $importedAt, ')
          ..write('adapterVersion: $adapterVersion, ')
          ..write('status: $status, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InboxSuggestionsTable extends InboxSuggestions
    with TableInfo<$InboxSuggestionsTable, InboxSuggestion> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InboxSuggestionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stagedImportIdMeta = const VerificationMeta(
    'stagedImportId',
  );
  @override
  late final GeneratedColumn<String> stagedImportId = GeneratedColumn<String>(
    'staged_import_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES staged_imports (id)',
    ),
  );
  static const VerificationMeta _draftIdMeta = const VerificationMeta(
    'draftId',
  );
  @override
  late final GeneratedColumn<String> draftId = GeneratedColumn<String>(
    'draft_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _minorUnitsMeta = const VerificationMeta(
    'minorUnits',
  );
  @override
  late final GeneratedColumn<int> minorUnits = GeneratedColumn<int>(
    'minor_units',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
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
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _merchantMeta = const VerificationMeta(
    'merchant',
  );
  @override
  late final GeneratedColumn<String> merchant = GeneratedColumn<String>(
    'merchant',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _referenceMeta = const VerificationMeta(
    'reference',
  );
  @override
  late final GeneratedColumn<String> reference = GeneratedColumn<String>(
    'reference',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
    stagedImportId,
    draftId,
    minorUnits,
    currency,
    occurredAt,
    type,
    merchant,
    reference,
    status,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'inbox_suggestions';
  @override
  VerificationContext validateIntegrity(
    Insertable<InboxSuggestion> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('staged_import_id')) {
      context.handle(
        _stagedImportIdMeta,
        stagedImportId.isAcceptableOrUnknown(
          data['staged_import_id']!,
          _stagedImportIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_stagedImportIdMeta);
    }
    if (data.containsKey('draft_id')) {
      context.handle(
        _draftIdMeta,
        draftId.isAcceptableOrUnknown(data['draft_id']!, _draftIdMeta),
      );
    } else if (isInserting) {
      context.missing(_draftIdMeta);
    }
    if (data.containsKey('minor_units')) {
      context.handle(
        _minorUnitsMeta,
        minorUnits.isAcceptableOrUnknown(data['minor_units']!, _minorUnitsMeta),
      );
    } else if (isInserting) {
      context.missing(_minorUnitsMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    } else if (isInserting) {
      context.missing(_currencyMeta);
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
        _occurredAtMeta,
        occurredAt.isAcceptableOrUnknown(data['occurred_at']!, _occurredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('merchant')) {
      context.handle(
        _merchantMeta,
        merchant.isAcceptableOrUnknown(data['merchant']!, _merchantMeta),
      );
    }
    if (data.containsKey('reference')) {
      context.handle(
        _referenceMeta,
        reference.isAcceptableOrUnknown(data['reference']!, _referenceMeta),
      );
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
  InboxSuggestion map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InboxSuggestion(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      stagedImportId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}staged_import_id'],
      )!,
      draftId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}draft_id'],
      )!,
      minorUnits: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}minor_units'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      occurredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}occurred_at'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      merchant: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}merchant'],
      ),
      reference: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reference'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}status'],
      )!,
    );
  }

  @override
  $InboxSuggestionsTable createAlias(String alias) {
    return $InboxSuggestionsTable(attachedDatabase, alias);
  }
}

class InboxSuggestion extends DataClass implements Insertable<InboxSuggestion> {
  final String id;
  final String stagedImportId;
  final String draftId;
  final int minorUnits;
  final String currency;
  final DateTime occurredAt;
  final String type;
  final String? merchant;
  final String? reference;
  final int status;
  const InboxSuggestion({
    required this.id,
    required this.stagedImportId,
    required this.draftId,
    required this.minorUnits,
    required this.currency,
    required this.occurredAt,
    required this.type,
    this.merchant,
    this.reference,
    required this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['staged_import_id'] = Variable<String>(stagedImportId);
    map['draft_id'] = Variable<String>(draftId);
    map['minor_units'] = Variable<int>(minorUnits);
    map['currency'] = Variable<String>(currency);
    map['occurred_at'] = Variable<DateTime>(occurredAt);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || merchant != null) {
      map['merchant'] = Variable<String>(merchant);
    }
    if (!nullToAbsent || reference != null) {
      map['reference'] = Variable<String>(reference);
    }
    map['status'] = Variable<int>(status);
    return map;
  }

  InboxSuggestionsCompanion toCompanion(bool nullToAbsent) {
    return InboxSuggestionsCompanion(
      id: Value(id),
      stagedImportId: Value(stagedImportId),
      draftId: Value(draftId),
      minorUnits: Value(minorUnits),
      currency: Value(currency),
      occurredAt: Value(occurredAt),
      type: Value(type),
      merchant: merchant == null && nullToAbsent
          ? const Value.absent()
          : Value(merchant),
      reference: reference == null && nullToAbsent
          ? const Value.absent()
          : Value(reference),
      status: Value(status),
    );
  }

  factory InboxSuggestion.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InboxSuggestion(
      id: serializer.fromJson<String>(json['id']),
      stagedImportId: serializer.fromJson<String>(json['stagedImportId']),
      draftId: serializer.fromJson<String>(json['draftId']),
      minorUnits: serializer.fromJson<int>(json['minorUnits']),
      currency: serializer.fromJson<String>(json['currency']),
      occurredAt: serializer.fromJson<DateTime>(json['occurredAt']),
      type: serializer.fromJson<String>(json['type']),
      merchant: serializer.fromJson<String?>(json['merchant']),
      reference: serializer.fromJson<String?>(json['reference']),
      status: serializer.fromJson<int>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'stagedImportId': serializer.toJson<String>(stagedImportId),
      'draftId': serializer.toJson<String>(draftId),
      'minorUnits': serializer.toJson<int>(minorUnits),
      'currency': serializer.toJson<String>(currency),
      'occurredAt': serializer.toJson<DateTime>(occurredAt),
      'type': serializer.toJson<String>(type),
      'merchant': serializer.toJson<String?>(merchant),
      'reference': serializer.toJson<String?>(reference),
      'status': serializer.toJson<int>(status),
    };
  }

  InboxSuggestion copyWith({
    String? id,
    String? stagedImportId,
    String? draftId,
    int? minorUnits,
    String? currency,
    DateTime? occurredAt,
    String? type,
    Value<String?> merchant = const Value.absent(),
    Value<String?> reference = const Value.absent(),
    int? status,
  }) => InboxSuggestion(
    id: id ?? this.id,
    stagedImportId: stagedImportId ?? this.stagedImportId,
    draftId: draftId ?? this.draftId,
    minorUnits: minorUnits ?? this.minorUnits,
    currency: currency ?? this.currency,
    occurredAt: occurredAt ?? this.occurredAt,
    type: type ?? this.type,
    merchant: merchant.present ? merchant.value : this.merchant,
    reference: reference.present ? reference.value : this.reference,
    status: status ?? this.status,
  );
  InboxSuggestion copyWithCompanion(InboxSuggestionsCompanion data) {
    return InboxSuggestion(
      id: data.id.present ? data.id.value : this.id,
      stagedImportId: data.stagedImportId.present
          ? data.stagedImportId.value
          : this.stagedImportId,
      draftId: data.draftId.present ? data.draftId.value : this.draftId,
      minorUnits: data.minorUnits.present
          ? data.minorUnits.value
          : this.minorUnits,
      currency: data.currency.present ? data.currency.value : this.currency,
      occurredAt: data.occurredAt.present
          ? data.occurredAt.value
          : this.occurredAt,
      type: data.type.present ? data.type.value : this.type,
      merchant: data.merchant.present ? data.merchant.value : this.merchant,
      reference: data.reference.present ? data.reference.value : this.reference,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InboxSuggestion(')
          ..write('id: $id, ')
          ..write('stagedImportId: $stagedImportId, ')
          ..write('draftId: $draftId, ')
          ..write('minorUnits: $minorUnits, ')
          ..write('currency: $currency, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('type: $type, ')
          ..write('merchant: $merchant, ')
          ..write('reference: $reference, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    stagedImportId,
    draftId,
    minorUnits,
    currency,
    occurredAt,
    type,
    merchant,
    reference,
    status,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InboxSuggestion &&
          other.id == this.id &&
          other.stagedImportId == this.stagedImportId &&
          other.draftId == this.draftId &&
          other.minorUnits == this.minorUnits &&
          other.currency == this.currency &&
          other.occurredAt == this.occurredAt &&
          other.type == this.type &&
          other.merchant == this.merchant &&
          other.reference == this.reference &&
          other.status == this.status);
}

class InboxSuggestionsCompanion extends UpdateCompanion<InboxSuggestion> {
  final Value<String> id;
  final Value<String> stagedImportId;
  final Value<String> draftId;
  final Value<int> minorUnits;
  final Value<String> currency;
  final Value<DateTime> occurredAt;
  final Value<String> type;
  final Value<String?> merchant;
  final Value<String?> reference;
  final Value<int> status;
  final Value<int> rowid;
  const InboxSuggestionsCompanion({
    this.id = const Value.absent(),
    this.stagedImportId = const Value.absent(),
    this.draftId = const Value.absent(),
    this.minorUnits = const Value.absent(),
    this.currency = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.type = const Value.absent(),
    this.merchant = const Value.absent(),
    this.reference = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InboxSuggestionsCompanion.insert({
    required String id,
    required String stagedImportId,
    required String draftId,
    required int minorUnits,
    required String currency,
    required DateTime occurredAt,
    required String type,
    this.merchant = const Value.absent(),
    this.reference = const Value.absent(),
    required int status,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       stagedImportId = Value(stagedImportId),
       draftId = Value(draftId),
       minorUnits = Value(minorUnits),
       currency = Value(currency),
       occurredAt = Value(occurredAt),
       type = Value(type),
       status = Value(status);
  static Insertable<InboxSuggestion> custom({
    Expression<String>? id,
    Expression<String>? stagedImportId,
    Expression<String>? draftId,
    Expression<int>? minorUnits,
    Expression<String>? currency,
    Expression<DateTime>? occurredAt,
    Expression<String>? type,
    Expression<String>? merchant,
    Expression<String>? reference,
    Expression<int>? status,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (stagedImportId != null) 'staged_import_id': stagedImportId,
      if (draftId != null) 'draft_id': draftId,
      if (minorUnits != null) 'minor_units': minorUnits,
      if (currency != null) 'currency': currency,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (type != null) 'type': type,
      if (merchant != null) 'merchant': merchant,
      if (reference != null) 'reference': reference,
      if (status != null) 'status': status,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InboxSuggestionsCompanion copyWith({
    Value<String>? id,
    Value<String>? stagedImportId,
    Value<String>? draftId,
    Value<int>? minorUnits,
    Value<String>? currency,
    Value<DateTime>? occurredAt,
    Value<String>? type,
    Value<String?>? merchant,
    Value<String?>? reference,
    Value<int>? status,
    Value<int>? rowid,
  }) {
    return InboxSuggestionsCompanion(
      id: id ?? this.id,
      stagedImportId: stagedImportId ?? this.stagedImportId,
      draftId: draftId ?? this.draftId,
      minorUnits: minorUnits ?? this.minorUnits,
      currency: currency ?? this.currency,
      occurredAt: occurredAt ?? this.occurredAt,
      type: type ?? this.type,
      merchant: merchant ?? this.merchant,
      reference: reference ?? this.reference,
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
    if (stagedImportId.present) {
      map['staged_import_id'] = Variable<String>(stagedImportId.value);
    }
    if (draftId.present) {
      map['draft_id'] = Variable<String>(draftId.value);
    }
    if (minorUnits.present) {
      map['minor_units'] = Variable<int>(minorUnits.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<DateTime>(occurredAt.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (merchant.present) {
      map['merchant'] = Variable<String>(merchant.value);
    }
    if (reference.present) {
      map['reference'] = Variable<String>(reference.value);
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
    return (StringBuffer('InboxSuggestionsCompanion(')
          ..write('id: $id, ')
          ..write('stagedImportId: $stagedImportId, ')
          ..write('draftId: $draftId, ')
          ..write('minorUnits: $minorUnits, ')
          ..write('currency: $currency, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('type: $type, ')
          ..write('merchant: $merchant, ')
          ..write('reference: $reference, ')
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
  late final $ReminderRulesTable reminderRules = $ReminderRulesTable(this);
  late final $ReminderInstancesTable reminderInstances =
      $ReminderInstancesTable(this);
  late final $ActualsTable actuals = $ActualsTable(this);
  late final $EvidencesTable evidences = $EvidencesTable(this);
  late final $FinancialAccountsTable financialAccounts =
      $FinancialAccountsTable(this);
  late final $AccountEntriesTable accountEntries = $AccountEntriesTable(this);
  late final $TransactionMatchesTable transactionMatches =
      $TransactionMatchesTable(this);
  late final $MatchAllocationsTable matchAllocations = $MatchAllocationsTable(
    this,
  );
  late final $RelationshipReviewsTable relationshipReviews =
      $RelationshipReviewsTable(this);
  late final $FinancialExpectationsTable financialExpectations =
      $FinancialExpectationsTable(this);
  late final $TagsTable tags = $TagsTable(this);
  late final $CommitmentTagsTable commitmentTags = $CommitmentTagsTable(this);
  late final $AccountEntryTagsTable accountEntryTags = $AccountEntryTagsTable(
    this,
  );
  late final $StagedImportsTable stagedImports = $StagedImportsTable(this);
  late final $InboxSuggestionsTable inboxSuggestions = $InboxSuggestionsTable(
    this,
  );
  late final Index relationshipReviewsTransactionRevision = Index(
    'relationship_reviews_transaction_revision',
    'CREATE UNIQUE INDEX relationship_reviews_transaction_revision ON relationship_reviews (transaction_id, revision)',
  );
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
    reminderRules,
    reminderInstances,
    actuals,
    evidences,
    financialAccounts,
    accountEntries,
    transactionMatches,
    matchAllocations,
    relationshipReviews,
    financialExpectations,
    tags,
    commitmentTags,
    accountEntryTags,
    stagedImports,
    inboxSuggestions,
    relationshipReviewsTransactionRevision,
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
      Value<int> kind,
      Value<int> priority,
      Value<String?> description,
      Value<String> tags,
      Value<String> attachmentIds,
      Value<int> rowid,
    });
typedef $$CommitmentsTableUpdateCompanionBuilder =
    CommitmentsCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<DateTime> createdAt,
      Value<int> status,
      Value<int> kind,
      Value<int> priority,
      Value<String?> description,
      Value<String> tags,
      Value<String> attachmentIds,
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

  static MultiTypedResultKey<$CommitmentTagsTable, List<CommitmentTag>>
  _commitmentTagsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.commitmentTags,
    aliasName: 'commitments__id__commitment_tags__commitment_id',
  );

  $$CommitmentTagsTableProcessedTableManager get commitmentTagsRefs {
    final manager = $$CommitmentTagsTableTableManager(
      $_db,
      $_db.commitmentTags,
    ).filter((f) => f.commitmentId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_commitmentTagsRefsTable($_db));
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

  ColumnFilters<int> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get attachmentIds => $composableBuilder(
    column: $table.attachmentIds,
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

  Expression<bool> commitmentTagsRefs(
    Expression<bool> Function($$CommitmentTagsTableFilterComposer f) f,
  ) {
    final $$CommitmentTagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.commitmentTags,
      getReferencedColumn: (t) => t.commitmentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CommitmentTagsTableFilterComposer(
            $db: $db,
            $table: $db.commitmentTags,
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

  ColumnOrderings<int> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get attachmentIds => $composableBuilder(
    column: $table.attachmentIds,
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

  GeneratedColumn<int> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<String> get attachmentIds => $composableBuilder(
    column: $table.attachmentIds,
    builder: (column) => column,
  );

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

  Expression<T> commitmentTagsRefs<T extends Object>(
    Expression<T> Function($$CommitmentTagsTableAnnotationComposer a) f,
  ) {
    final $$CommitmentTagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.commitmentTags,
      getReferencedColumn: (t) => t.commitmentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CommitmentTagsTableAnnotationComposer(
            $db: $db,
            $table: $db.commitmentTags,
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
          PrefetchHooks Function({
            bool commitmentCyclesRefs,
            bool commitmentTagsRefs,
          })
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
                Value<int> kind = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String> tags = const Value.absent(),
                Value<String> attachmentIds = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CommitmentsCompanion(
                id: id,
                title: title,
                createdAt: createdAt,
                status: status,
                kind: kind,
                priority: priority,
                description: description,
                tags: tags,
                attachmentIds: attachmentIds,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                required DateTime createdAt,
                required int status,
                Value<int> kind = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String> tags = const Value.absent(),
                Value<String> attachmentIds = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CommitmentsCompanion.insert(
                id: id,
                title: title,
                createdAt: createdAt,
                status: status,
                kind: kind,
                priority: priority,
                description: description,
                tags: tags,
                attachmentIds: attachmentIds,
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
          prefetchHooksCallback:
              ({commitmentCyclesRefs = false, commitmentTagsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (commitmentCyclesRefs) db.commitmentCycles,
                    if (commitmentTagsRefs) db.commitmentTags,
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
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.commitmentId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (commitmentTagsRefs)
                        await $_getPrefetchedData<
                          Commitment,
                          $CommitmentsTable,
                          CommitmentTag
                        >(
                          currentTable: table,
                          referencedTable: $$CommitmentsTableReferences
                              ._commitmentTagsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CommitmentsTableReferences(
                                db,
                                table,
                                p0,
                              ).commitmentTagsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
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
      PrefetchHooks Function({
        bool commitmentCyclesRefs,
        bool commitmentTagsRefs,
      })
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

  static MultiTypedResultKey<$ReminderRulesTable, List<ReminderRule>>
  _reminderRulesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.reminderRules,
    aliasName: 'occurrences__id__reminder_rules__occurrence_id',
  );

  $$ReminderRulesTableProcessedTableManager get reminderRulesRefs {
    final manager = $$ReminderRulesTableTableManager(
      $_db,
      $_db.reminderRules,
    ).filter((f) => f.occurrenceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_reminderRulesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ReminderInstancesTable, List<ReminderInstance>>
  _reminderInstancesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.reminderInstances,
        aliasName: 'occurrences__id__reminder_instances__occurrence_id',
      );

  $$ReminderInstancesTableProcessedTableManager get reminderInstancesRefs {
    final manager = $$ReminderInstancesTableTableManager(
      $_db,
      $_db.reminderInstances,
    ).filter((f) => f.occurrenceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _reminderInstancesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ActualsTable, List<Actual>> _actualsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.actuals,
    aliasName: 'occurrences__id__actuals__occurrence_id',
  );

  $$ActualsTableProcessedTableManager get actualsRefs {
    final manager = $$ActualsTableTableManager(
      $_db,
      $_db.actuals,
    ).filter((f) => f.occurrenceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_actualsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$MatchAllocationsTable, List<MatchAllocation>>
  _matchAllocationsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.matchAllocations,
    aliasName: 'occurrences__id__match_allocations__occurrence_id',
  );

  $$MatchAllocationsTableProcessedTableManager get matchAllocationsRefs {
    final manager = $$MatchAllocationsTableTableManager(
      $_db,
      $_db.matchAllocations,
    ).filter((f) => f.occurrenceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _matchAllocationsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $FinancialExpectationsTable,
    List<FinancialExpectation>
  >
  _financialExpectationsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.financialExpectations,
        aliasName: 'occurrences__id__financial_expectations__occurrence_id',
      );

  $$FinancialExpectationsTableProcessedTableManager
  get financialExpectationsRefs {
    final manager = $$FinancialExpectationsTableTableManager(
      $_db,
      $_db.financialExpectations,
    ).filter((f) => f.occurrenceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _financialExpectationsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
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

  Expression<bool> reminderRulesRefs(
    Expression<bool> Function($$ReminderRulesTableFilterComposer f) f,
  ) {
    final $$ReminderRulesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reminderRules,
      getReferencedColumn: (t) => t.occurrenceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReminderRulesTableFilterComposer(
            $db: $db,
            $table: $db.reminderRules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> reminderInstancesRefs(
    Expression<bool> Function($$ReminderInstancesTableFilterComposer f) f,
  ) {
    final $$ReminderInstancesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reminderInstances,
      getReferencedColumn: (t) => t.occurrenceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReminderInstancesTableFilterComposer(
            $db: $db,
            $table: $db.reminderInstances,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> actualsRefs(
    Expression<bool> Function($$ActualsTableFilterComposer f) f,
  ) {
    final $$ActualsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.actuals,
      getReferencedColumn: (t) => t.occurrenceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ActualsTableFilterComposer(
            $db: $db,
            $table: $db.actuals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> matchAllocationsRefs(
    Expression<bool> Function($$MatchAllocationsTableFilterComposer f) f,
  ) {
    final $$MatchAllocationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.matchAllocations,
      getReferencedColumn: (t) => t.occurrenceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MatchAllocationsTableFilterComposer(
            $db: $db,
            $table: $db.matchAllocations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> financialExpectationsRefs(
    Expression<bool> Function($$FinancialExpectationsTableFilterComposer f) f,
  ) {
    final $$FinancialExpectationsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.financialExpectations,
          getReferencedColumn: (t) => t.occurrenceId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$FinancialExpectationsTableFilterComposer(
                $db: $db,
                $table: $db.financialExpectations,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
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

  Expression<T> reminderRulesRefs<T extends Object>(
    Expression<T> Function($$ReminderRulesTableAnnotationComposer a) f,
  ) {
    final $$ReminderRulesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reminderRules,
      getReferencedColumn: (t) => t.occurrenceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReminderRulesTableAnnotationComposer(
            $db: $db,
            $table: $db.reminderRules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> reminderInstancesRefs<T extends Object>(
    Expression<T> Function($$ReminderInstancesTableAnnotationComposer a) f,
  ) {
    final $$ReminderInstancesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.reminderInstances,
          getReferencedColumn: (t) => t.occurrenceId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ReminderInstancesTableAnnotationComposer(
                $db: $db,
                $table: $db.reminderInstances,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> actualsRefs<T extends Object>(
    Expression<T> Function($$ActualsTableAnnotationComposer a) f,
  ) {
    final $$ActualsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.actuals,
      getReferencedColumn: (t) => t.occurrenceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ActualsTableAnnotationComposer(
            $db: $db,
            $table: $db.actuals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> matchAllocationsRefs<T extends Object>(
    Expression<T> Function($$MatchAllocationsTableAnnotationComposer a) f,
  ) {
    final $$MatchAllocationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.matchAllocations,
      getReferencedColumn: (t) => t.occurrenceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MatchAllocationsTableAnnotationComposer(
            $db: $db,
            $table: $db.matchAllocations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> financialExpectationsRefs<T extends Object>(
    Expression<T> Function($$FinancialExpectationsTableAnnotationComposer a) f,
  ) {
    final $$FinancialExpectationsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.financialExpectations,
          getReferencedColumn: (t) => t.occurrenceId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$FinancialExpectationsTableAnnotationComposer(
                $db: $db,
                $table: $db.financialExpectations,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
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
          PrefetchHooks Function({
            bool cycleId,
            bool scheduleDefinitionId,
            bool reminderRulesRefs,
            bool reminderInstancesRefs,
            bool actualsRefs,
            bool matchAllocationsRefs,
            bool financialExpectationsRefs,
          })
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
              ({
                cycleId = false,
                scheduleDefinitionId = false,
                reminderRulesRefs = false,
                reminderInstancesRefs = false,
                actualsRefs = false,
                matchAllocationsRefs = false,
                financialExpectationsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (reminderRulesRefs) db.reminderRules,
                    if (reminderInstancesRefs) db.reminderInstances,
                    if (actualsRefs) db.actuals,
                    if (matchAllocationsRefs) db.matchAllocations,
                    if (financialExpectationsRefs) db.financialExpectations,
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
                    return [
                      if (reminderRulesRefs)
                        await $_getPrefetchedData<
                          Occurrence,
                          $OccurrencesTable,
                          ReminderRule
                        >(
                          currentTable: table,
                          referencedTable: $$OccurrencesTableReferences
                              ._reminderRulesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$OccurrencesTableReferences(
                                db,
                                table,
                                p0,
                              ).reminderRulesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.occurrenceId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (reminderInstancesRefs)
                        await $_getPrefetchedData<
                          Occurrence,
                          $OccurrencesTable,
                          ReminderInstance
                        >(
                          currentTable: table,
                          referencedTable: $$OccurrencesTableReferences
                              ._reminderInstancesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$OccurrencesTableReferences(
                                db,
                                table,
                                p0,
                              ).reminderInstancesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.occurrenceId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (actualsRefs)
                        await $_getPrefetchedData<
                          Occurrence,
                          $OccurrencesTable,
                          Actual
                        >(
                          currentTable: table,
                          referencedTable: $$OccurrencesTableReferences
                              ._actualsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$OccurrencesTableReferences(
                                db,
                                table,
                                p0,
                              ).actualsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.occurrenceId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (matchAllocationsRefs)
                        await $_getPrefetchedData<
                          Occurrence,
                          $OccurrencesTable,
                          MatchAllocation
                        >(
                          currentTable: table,
                          referencedTable: $$OccurrencesTableReferences
                              ._matchAllocationsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$OccurrencesTableReferences(
                                db,
                                table,
                                p0,
                              ).matchAllocationsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.occurrenceId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (financialExpectationsRefs)
                        await $_getPrefetchedData<
                          Occurrence,
                          $OccurrencesTable,
                          FinancialExpectation
                        >(
                          currentTable: table,
                          referencedTable: $$OccurrencesTableReferences
                              ._financialExpectationsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$OccurrencesTableReferences(
                                db,
                                table,
                                p0,
                              ).financialExpectationsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.occurrenceId == item.id,
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
      PrefetchHooks Function({
        bool cycleId,
        bool scheduleDefinitionId,
        bool reminderRulesRefs,
        bool reminderInstancesRefs,
        bool actualsRefs,
        bool matchAllocationsRefs,
        bool financialExpectationsRefs,
      })
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
typedef $$ReminderRulesTableCreateCompanionBuilder =
    ReminderRulesCompanion Function({
      required String id,
      required String occurrenceId,
      required int anchor,
      required int offsetSeconds,
      Value<DateTime?> absoluteAt,
      Value<String?> title,
      Value<String?> body,
      required bool enabled,
      Value<int> rowid,
    });
typedef $$ReminderRulesTableUpdateCompanionBuilder =
    ReminderRulesCompanion Function({
      Value<String> id,
      Value<String> occurrenceId,
      Value<int> anchor,
      Value<int> offsetSeconds,
      Value<DateTime?> absoluteAt,
      Value<String?> title,
      Value<String?> body,
      Value<bool> enabled,
      Value<int> rowid,
    });

final class $$ReminderRulesTableReferences
    extends BaseReferences<_$AppDatabase, $ReminderRulesTable, ReminderRule> {
  $$ReminderRulesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $OccurrencesTable _occurrenceIdTable(_$AppDatabase db) => db
      .occurrences
      .createAlias('reminder_rules__occurrence_id__occurrences__id');

  $$OccurrencesTableProcessedTableManager get occurrenceId {
    final $_column = $_itemColumn<String>('occurrence_id')!;

    final manager = $$OccurrencesTableTableManager(
      $_db,
      $_db.occurrences,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_occurrenceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ReminderInstancesTable, List<ReminderInstance>>
  _reminderInstancesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.reminderInstances,
        aliasName: 'reminder_rules__id__reminder_instances__rule_id',
      );

  $$ReminderInstancesTableProcessedTableManager get reminderInstancesRefs {
    final manager = $$ReminderInstancesTableTableManager(
      $_db,
      $_db.reminderInstances,
    ).filter((f) => f.ruleId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _reminderInstancesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ReminderRulesTableFilterComposer
    extends Composer<_$AppDatabase, $ReminderRulesTable> {
  $$ReminderRulesTableFilterComposer({
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

  ColumnFilters<int> get anchor => $composableBuilder(
    column: $table.anchor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get offsetSeconds => $composableBuilder(
    column: $table.offsetSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get absoluteAt => $composableBuilder(
    column: $table.absoluteAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  $$OccurrencesTableFilterComposer get occurrenceId {
    final $$OccurrencesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.occurrenceId,
      referencedTable: $db.occurrences,
      getReferencedColumn: (t) => t.id,
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
    return composer;
  }

  Expression<bool> reminderInstancesRefs(
    Expression<bool> Function($$ReminderInstancesTableFilterComposer f) f,
  ) {
    final $$ReminderInstancesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reminderInstances,
      getReferencedColumn: (t) => t.ruleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReminderInstancesTableFilterComposer(
            $db: $db,
            $table: $db.reminderInstances,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ReminderRulesTableOrderingComposer
    extends Composer<_$AppDatabase, $ReminderRulesTable> {
  $$ReminderRulesTableOrderingComposer({
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

  ColumnOrderings<int> get anchor => $composableBuilder(
    column: $table.anchor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get offsetSeconds => $composableBuilder(
    column: $table.offsetSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get absoluteAt => $composableBuilder(
    column: $table.absoluteAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  $$OccurrencesTableOrderingComposer get occurrenceId {
    final $$OccurrencesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.occurrenceId,
      referencedTable: $db.occurrences,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OccurrencesTableOrderingComposer(
            $db: $db,
            $table: $db.occurrences,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReminderRulesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReminderRulesTable> {
  $$ReminderRulesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get anchor =>
      $composableBuilder(column: $table.anchor, builder: (column) => column);

  GeneratedColumn<int> get offsetSeconds => $composableBuilder(
    column: $table.offsetSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get absoluteAt => $composableBuilder(
    column: $table.absoluteAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  $$OccurrencesTableAnnotationComposer get occurrenceId {
    final $$OccurrencesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.occurrenceId,
      referencedTable: $db.occurrences,
      getReferencedColumn: (t) => t.id,
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
    return composer;
  }

  Expression<T> reminderInstancesRefs<T extends Object>(
    Expression<T> Function($$ReminderInstancesTableAnnotationComposer a) f,
  ) {
    final $$ReminderInstancesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.reminderInstances,
          getReferencedColumn: (t) => t.ruleId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ReminderInstancesTableAnnotationComposer(
                $db: $db,
                $table: $db.reminderInstances,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$ReminderRulesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReminderRulesTable,
          ReminderRule,
          $$ReminderRulesTableFilterComposer,
          $$ReminderRulesTableOrderingComposer,
          $$ReminderRulesTableAnnotationComposer,
          $$ReminderRulesTableCreateCompanionBuilder,
          $$ReminderRulesTableUpdateCompanionBuilder,
          (ReminderRule, $$ReminderRulesTableReferences),
          ReminderRule,
          PrefetchHooks Function({
            bool occurrenceId,
            bool reminderInstancesRefs,
          })
        > {
  $$ReminderRulesTableTableManager(_$AppDatabase db, $ReminderRulesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReminderRulesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReminderRulesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReminderRulesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> occurrenceId = const Value.absent(),
                Value<int> anchor = const Value.absent(),
                Value<int> offsetSeconds = const Value.absent(),
                Value<DateTime?> absoluteAt = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String?> body = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReminderRulesCompanion(
                id: id,
                occurrenceId: occurrenceId,
                anchor: anchor,
                offsetSeconds: offsetSeconds,
                absoluteAt: absoluteAt,
                title: title,
                body: body,
                enabled: enabled,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String occurrenceId,
                required int anchor,
                required int offsetSeconds,
                Value<DateTime?> absoluteAt = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String?> body = const Value.absent(),
                required bool enabled,
                Value<int> rowid = const Value.absent(),
              }) => ReminderRulesCompanion.insert(
                id: id,
                occurrenceId: occurrenceId,
                anchor: anchor,
                offsetSeconds: offsetSeconds,
                absoluteAt: absoluteAt,
                title: title,
                body: body,
                enabled: enabled,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ReminderRulesTable, ReminderRule>(table),
                  $$ReminderRulesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({occurrenceId = false, reminderInstancesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (reminderInstancesRefs) db.reminderInstances,
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
                        if (occurrenceId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.occurrenceId,
                            referencedTable: $$ReminderRulesTableReferences
                                ._occurrenceIdTable(db),
                            referencedColumn: $$ReminderRulesTableReferences
                                ._occurrenceIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (reminderInstancesRefs)
                        await $_getPrefetchedData<
                          ReminderRule,
                          $ReminderRulesTable,
                          ReminderInstance
                        >(
                          currentTable: table,
                          referencedTable: $$ReminderRulesTableReferences
                              ._reminderInstancesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ReminderRulesTableReferences(
                                db,
                                table,
                                p0,
                              ).reminderInstancesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.ruleId == item.id,
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

typedef $$ReminderRulesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReminderRulesTable,
      ReminderRule,
      $$ReminderRulesTableFilterComposer,
      $$ReminderRulesTableOrderingComposer,
      $$ReminderRulesTableAnnotationComposer,
      $$ReminderRulesTableCreateCompanionBuilder,
      $$ReminderRulesTableUpdateCompanionBuilder,
      (ReminderRule, $$ReminderRulesTableReferences),
      ReminderRule,
      PrefetchHooks Function({bool occurrenceId, bool reminderInstancesRefs})
    >;
typedef $$ReminderInstancesTableCreateCompanionBuilder =
    ReminderInstancesCompanion Function({
      required String id,
      required String ruleId,
      required String occurrenceId,
      required DateTime scheduledAt,
      required int status,
      Value<DateTime?> snoozedUntil,
      Value<String?> platformNotificationId,
      Value<int> rowid,
    });
typedef $$ReminderInstancesTableUpdateCompanionBuilder =
    ReminderInstancesCompanion Function({
      Value<String> id,
      Value<String> ruleId,
      Value<String> occurrenceId,
      Value<DateTime> scheduledAt,
      Value<int> status,
      Value<DateTime?> snoozedUntil,
      Value<String?> platformNotificationId,
      Value<int> rowid,
    });

final class $$ReminderInstancesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ReminderInstancesTable,
          ReminderInstance
        > {
  $$ReminderInstancesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ReminderRulesTable _ruleIdTable(_$AppDatabase db) => db.reminderRules
      .createAlias('reminder_instances__rule_id__reminder_rules__id');

  $$ReminderRulesTableProcessedTableManager get ruleId {
    final $_column = $_itemColumn<String>('rule_id')!;

    final manager = $$ReminderRulesTableTableManager(
      $_db,
      $_db.reminderRules,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_ruleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $OccurrencesTable _occurrenceIdTable(_$AppDatabase db) => db
      .occurrences
      .createAlias('reminder_instances__occurrence_id__occurrences__id');

  $$OccurrencesTableProcessedTableManager get occurrenceId {
    final $_column = $_itemColumn<String>('occurrence_id')!;

    final manager = $$OccurrencesTableTableManager(
      $_db,
      $_db.occurrences,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_occurrenceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ReminderInstancesTableFilterComposer
    extends Composer<_$AppDatabase, $ReminderInstancesTable> {
  $$ReminderInstancesTableFilterComposer({
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

  ColumnFilters<DateTime> get scheduledAt => $composableBuilder(
    column: $table.scheduledAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get snoozedUntil => $composableBuilder(
    column: $table.snoozedUntil,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get platformNotificationId => $composableBuilder(
    column: $table.platformNotificationId,
    builder: (column) => ColumnFilters(column),
  );

  $$ReminderRulesTableFilterComposer get ruleId {
    final $$ReminderRulesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ruleId,
      referencedTable: $db.reminderRules,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReminderRulesTableFilterComposer(
            $db: $db,
            $table: $db.reminderRules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$OccurrencesTableFilterComposer get occurrenceId {
    final $$OccurrencesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.occurrenceId,
      referencedTable: $db.occurrences,
      getReferencedColumn: (t) => t.id,
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
    return composer;
  }
}

class $$ReminderInstancesTableOrderingComposer
    extends Composer<_$AppDatabase, $ReminderInstancesTable> {
  $$ReminderInstancesTableOrderingComposer({
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

  ColumnOrderings<DateTime> get scheduledAt => $composableBuilder(
    column: $table.scheduledAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get snoozedUntil => $composableBuilder(
    column: $table.snoozedUntil,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get platformNotificationId => $composableBuilder(
    column: $table.platformNotificationId,
    builder: (column) => ColumnOrderings(column),
  );

  $$ReminderRulesTableOrderingComposer get ruleId {
    final $$ReminderRulesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ruleId,
      referencedTable: $db.reminderRules,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReminderRulesTableOrderingComposer(
            $db: $db,
            $table: $db.reminderRules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$OccurrencesTableOrderingComposer get occurrenceId {
    final $$OccurrencesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.occurrenceId,
      referencedTable: $db.occurrences,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OccurrencesTableOrderingComposer(
            $db: $db,
            $table: $db.occurrences,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReminderInstancesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReminderInstancesTable> {
  $$ReminderInstancesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get scheduledAt => $composableBuilder(
    column: $table.scheduledAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get snoozedUntil => $composableBuilder(
    column: $table.snoozedUntil,
    builder: (column) => column,
  );

  GeneratedColumn<String> get platformNotificationId => $composableBuilder(
    column: $table.platformNotificationId,
    builder: (column) => column,
  );

  $$ReminderRulesTableAnnotationComposer get ruleId {
    final $$ReminderRulesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ruleId,
      referencedTable: $db.reminderRules,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReminderRulesTableAnnotationComposer(
            $db: $db,
            $table: $db.reminderRules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$OccurrencesTableAnnotationComposer get occurrenceId {
    final $$OccurrencesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.occurrenceId,
      referencedTable: $db.occurrences,
      getReferencedColumn: (t) => t.id,
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
    return composer;
  }
}

class $$ReminderInstancesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReminderInstancesTable,
          ReminderInstance,
          $$ReminderInstancesTableFilterComposer,
          $$ReminderInstancesTableOrderingComposer,
          $$ReminderInstancesTableAnnotationComposer,
          $$ReminderInstancesTableCreateCompanionBuilder,
          $$ReminderInstancesTableUpdateCompanionBuilder,
          (ReminderInstance, $$ReminderInstancesTableReferences),
          ReminderInstance,
          PrefetchHooks Function({bool ruleId, bool occurrenceId})
        > {
  $$ReminderInstancesTableTableManager(
    _$AppDatabase db,
    $ReminderInstancesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReminderInstancesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReminderInstancesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReminderInstancesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> ruleId = const Value.absent(),
                Value<String> occurrenceId = const Value.absent(),
                Value<DateTime> scheduledAt = const Value.absent(),
                Value<int> status = const Value.absent(),
                Value<DateTime?> snoozedUntil = const Value.absent(),
                Value<String?> platformNotificationId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReminderInstancesCompanion(
                id: id,
                ruleId: ruleId,
                occurrenceId: occurrenceId,
                scheduledAt: scheduledAt,
                status: status,
                snoozedUntil: snoozedUntil,
                platformNotificationId: platformNotificationId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String ruleId,
                required String occurrenceId,
                required DateTime scheduledAt,
                required int status,
                Value<DateTime?> snoozedUntil = const Value.absent(),
                Value<String?> platformNotificationId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReminderInstancesCompanion.insert(
                id: id,
                ruleId: ruleId,
                occurrenceId: occurrenceId,
                scheduledAt: scheduledAt,
                status: status,
                snoozedUntil: snoozedUntil,
                platformNotificationId: platformNotificationId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ReminderInstancesTable, ReminderInstance>(table),
                  $$ReminderInstancesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({ruleId = false, occurrenceId = false}) {
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
                    if (ruleId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.ruleId,
                        referencedTable: $$ReminderInstancesTableReferences
                            ._ruleIdTable(db),
                        referencedColumn: $$ReminderInstancesTableReferences
                            ._ruleIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (occurrenceId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.occurrenceId,
                        referencedTable: $$ReminderInstancesTableReferences
                            ._occurrenceIdTable(db),
                        referencedColumn: $$ReminderInstancesTableReferences
                            ._occurrenceIdTable(db)
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

typedef $$ReminderInstancesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReminderInstancesTable,
      ReminderInstance,
      $$ReminderInstancesTableFilterComposer,
      $$ReminderInstancesTableOrderingComposer,
      $$ReminderInstancesTableAnnotationComposer,
      $$ReminderInstancesTableCreateCompanionBuilder,
      $$ReminderInstancesTableUpdateCompanionBuilder,
      (ReminderInstance, $$ReminderInstancesTableReferences),
      ReminderInstance,
      PrefetchHooks Function({bool ruleId, bool occurrenceId})
    >;
typedef $$ActualsTableCreateCompanionBuilder = ActualsCompanion Function({
  required String id,
  required String occurrenceId,
  required int outcome,
  required DateTime recordedAt,
  Value<String?> note,
  Value<int> rowid,
});
typedef $$ActualsTableUpdateCompanionBuilder = ActualsCompanion Function({
  Value<String> id,
  Value<String> occurrenceId,
  Value<int> outcome,
  Value<DateTime> recordedAt,
  Value<String?> note,
  Value<int> rowid,
});

final class $$ActualsTableReferences
    extends BaseReferences<_$AppDatabase, $ActualsTable, Actual> {
  $$ActualsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $OccurrencesTable _occurrenceIdTable(_$AppDatabase db) =>
      db.occurrences.createAlias('actuals__occurrence_id__occurrences__id');

  $$OccurrencesTableProcessedTableManager get occurrenceId {
    final $_column = $_itemColumn<String>('occurrence_id')!;

    final manager = $$OccurrencesTableTableManager(
      $_db,
      $_db.occurrences,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_occurrenceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$EvidencesTable, List<Evidence>>
  _evidencesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.evidences,
    aliasName: 'actuals__id__evidences__actual_id',
  );

  $$EvidencesTableProcessedTableManager get evidencesRefs {
    final manager = $$EvidencesTableTableManager(
      $_db,
      $_db.evidences,
    ).filter((f) => f.actualId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_evidencesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ActualsTableFilterComposer
    extends Composer<_$AppDatabase, $ActualsTable> {
  $$ActualsTableFilterComposer({
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

  ColumnFilters<int> get outcome => $composableBuilder(
    column: $table.outcome,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  $$OccurrencesTableFilterComposer get occurrenceId {
    final $$OccurrencesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.occurrenceId,
      referencedTable: $db.occurrences,
      getReferencedColumn: (t) => t.id,
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
    return composer;
  }

  Expression<bool> evidencesRefs(
    Expression<bool> Function($$EvidencesTableFilterComposer f) f,
  ) {
    final $$EvidencesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.evidences,
      getReferencedColumn: (t) => t.actualId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EvidencesTableFilterComposer(
            $db: $db,
            $table: $db.evidences,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ActualsTableOrderingComposer
    extends Composer<_$AppDatabase, $ActualsTable> {
  $$ActualsTableOrderingComposer({
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

  ColumnOrderings<int> get outcome => $composableBuilder(
    column: $table.outcome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  $$OccurrencesTableOrderingComposer get occurrenceId {
    final $$OccurrencesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.occurrenceId,
      referencedTable: $db.occurrences,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OccurrencesTableOrderingComposer(
            $db: $db,
            $table: $db.occurrences,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ActualsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ActualsTable> {
  $$ActualsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get outcome =>
      $composableBuilder(column: $table.outcome, builder: (column) => column);

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  $$OccurrencesTableAnnotationComposer get occurrenceId {
    final $$OccurrencesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.occurrenceId,
      referencedTable: $db.occurrences,
      getReferencedColumn: (t) => t.id,
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
    return composer;
  }

  Expression<T> evidencesRefs<T extends Object>(
    Expression<T> Function($$EvidencesTableAnnotationComposer a) f,
  ) {
    final $$EvidencesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.evidences,
      getReferencedColumn: (t) => t.actualId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EvidencesTableAnnotationComposer(
            $db: $db,
            $table: $db.evidences,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ActualsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ActualsTable,
          Actual,
          $$ActualsTableFilterComposer,
          $$ActualsTableOrderingComposer,
          $$ActualsTableAnnotationComposer,
          $$ActualsTableCreateCompanionBuilder,
          $$ActualsTableUpdateCompanionBuilder,
          (Actual, $$ActualsTableReferences),
          Actual,
          PrefetchHooks Function({bool occurrenceId, bool evidencesRefs})
        > {
  $$ActualsTableTableManager(_$AppDatabase db, $ActualsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ActualsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ActualsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ActualsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> occurrenceId = const Value.absent(),
                Value<int> outcome = const Value.absent(),
                Value<DateTime> recordedAt = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ActualsCompanion(
                id: id,
                occurrenceId: occurrenceId,
                outcome: outcome,
                recordedAt: recordedAt,
                note: note,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String occurrenceId,
                required int outcome,
                required DateTime recordedAt,
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ActualsCompanion.insert(
                id: id,
                occurrenceId: occurrenceId,
                outcome: outcome,
                recordedAt: recordedAt,
                note: note,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ActualsTable, Actual>(table),
                  $$ActualsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({occurrenceId = false, evidencesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [if (evidencesRefs) db.evidences],
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
                        if (occurrenceId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.occurrenceId,
                            referencedTable: $$ActualsTableReferences
                                ._occurrenceIdTable(db),
                            referencedColumn: $$ActualsTableReferences
                                ._occurrenceIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (evidencesRefs)
                        await $_getPrefetchedData<
                          Actual,
                          $ActualsTable,
                          Evidence
                        >(
                          currentTable: table,
                          referencedTable: $$ActualsTableReferences
                              ._evidencesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ActualsTableReferences(
                                db,
                                table,
                                p0,
                              ).evidencesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.actualId == item.id,
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

typedef $$ActualsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ActualsTable,
      Actual,
      $$ActualsTableFilterComposer,
      $$ActualsTableOrderingComposer,
      $$ActualsTableAnnotationComposer,
      $$ActualsTableCreateCompanionBuilder,
      $$ActualsTableUpdateCompanionBuilder,
      (Actual, $$ActualsTableReferences),
      Actual,
      PrefetchHooks Function({bool occurrenceId, bool evidencesRefs})
    >;
typedef $$EvidencesTableCreateCompanionBuilder = EvidencesCompanion Function({
  required String id,
  required String actualId,
  required int type,
  required String value,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$EvidencesTableUpdateCompanionBuilder = EvidencesCompanion Function({
  Value<String> id,
  Value<String> actualId,
  Value<int> type,
  Value<String> value,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$EvidencesTableReferences
    extends BaseReferences<_$AppDatabase, $EvidencesTable, Evidence> {
  $$EvidencesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ActualsTable _actualIdTable(_$AppDatabase db) =>
      db.actuals.createAlias('evidences__actual_id__actuals__id');

  $$ActualsTableProcessedTableManager get actualId {
    final $_column = $_itemColumn<String>('actual_id')!;

    final manager = $$ActualsTableTableManager(
      $_db,
      $_db.actuals,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_actualIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$EvidencesTableFilterComposer
    extends Composer<_$AppDatabase, $EvidencesTable> {
  $$EvidencesTableFilterComposer({
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

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ActualsTableFilterComposer get actualId {
    final $$ActualsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.actualId,
      referencedTable: $db.actuals,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ActualsTableFilterComposer(
            $db: $db,
            $table: $db.actuals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EvidencesTableOrderingComposer
    extends Composer<_$AppDatabase, $EvidencesTable> {
  $$EvidencesTableOrderingComposer({
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

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ActualsTableOrderingComposer get actualId {
    final $$ActualsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.actualId,
      referencedTable: $db.actuals,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ActualsTableOrderingComposer(
            $db: $db,
            $table: $db.actuals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EvidencesTableAnnotationComposer
    extends Composer<_$AppDatabase, $EvidencesTable> {
  $$EvidencesTableAnnotationComposer({
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

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$ActualsTableAnnotationComposer get actualId {
    final $$ActualsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.actualId,
      referencedTable: $db.actuals,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ActualsTableAnnotationComposer(
            $db: $db,
            $table: $db.actuals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EvidencesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EvidencesTable,
          Evidence,
          $$EvidencesTableFilterComposer,
          $$EvidencesTableOrderingComposer,
          $$EvidencesTableAnnotationComposer,
          $$EvidencesTableCreateCompanionBuilder,
          $$EvidencesTableUpdateCompanionBuilder,
          (Evidence, $$EvidencesTableReferences),
          Evidence,
          PrefetchHooks Function({bool actualId})
        > {
  $$EvidencesTableTableManager(_$AppDatabase db, $EvidencesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EvidencesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EvidencesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EvidencesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> actualId = const Value.absent(),
                Value<int> type = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EvidencesCompanion(
                id: id,
                actualId: actualId,
                type: type,
                value: value,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String actualId,
                required int type,
                required String value,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => EvidencesCompanion.insert(
                id: id,
                actualId: actualId,
                type: type,
                value: value,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$EvidencesTable, Evidence>(table),
                  $$EvidencesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({actualId = false}) {
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
                    if (actualId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.actualId,
                        referencedTable: $$EvidencesTableReferences
                            ._actualIdTable(db),
                        referencedColumn: $$EvidencesTableReferences
                            ._actualIdTable(db)
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

typedef $$EvidencesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EvidencesTable,
      Evidence,
      $$EvidencesTableFilterComposer,
      $$EvidencesTableOrderingComposer,
      $$EvidencesTableAnnotationComposer,
      $$EvidencesTableCreateCompanionBuilder,
      $$EvidencesTableUpdateCompanionBuilder,
      (Evidence, $$EvidencesTableReferences),
      Evidence,
      PrefetchHooks Function({bool actualId})
    >;
typedef $$FinancialAccountsTableCreateCompanionBuilder =
    FinancialAccountsCompanion Function({
      required String id,
      required String name,
      required String currency,
      required int type,
      Value<String?> bankCode,
      required int status,
      Value<int> rowid,
    });
typedef $$FinancialAccountsTableUpdateCompanionBuilder =
    FinancialAccountsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> currency,
      Value<int> type,
      Value<String?> bankCode,
      Value<int> status,
      Value<int> rowid,
    });

final class $$FinancialAccountsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $FinancialAccountsTable,
          FinancialAccount
        > {
  $$FinancialAccountsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$AccountEntriesTable, List<AccountEntry>>
  _accountEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.accountEntries,
    aliasName: 'financial_accounts__id__account_entries__account_id',
  );

  $$AccountEntriesTableProcessedTableManager get accountEntriesRefs {
    final manager = $$AccountEntriesTableTableManager(
      $_db,
      $_db.accountEntries,
    ).filter((f) => f.accountId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_accountEntriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $FinancialExpectationsTable,
    List<FinancialExpectation>
  >
  _financialExpectationsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.financialExpectations,
        aliasName: 'financial_accounts__id__financial_expectations__account_id',
      );

  $$FinancialExpectationsTableProcessedTableManager
  get financialExpectationsRefs {
    final manager = $$FinancialExpectationsTableTableManager(
      $_db,
      $_db.financialExpectations,
    ).filter((f) => f.accountId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _financialExpectationsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$FinancialAccountsTableFilterComposer
    extends Composer<_$AppDatabase, $FinancialAccountsTable> {
  $$FinancialAccountsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bankCode => $composableBuilder(
    column: $table.bankCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> accountEntriesRefs(
    Expression<bool> Function($$AccountEntriesTableFilterComposer f) f,
  ) {
    final $$AccountEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.accountEntries,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountEntriesTableFilterComposer(
            $db: $db,
            $table: $db.accountEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> financialExpectationsRefs(
    Expression<bool> Function($$FinancialExpectationsTableFilterComposer f) f,
  ) {
    final $$FinancialExpectationsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.financialExpectations,
          getReferencedColumn: (t) => t.accountId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$FinancialExpectationsTableFilterComposer(
                $db: $db,
                $table: $db.financialExpectations,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$FinancialAccountsTableOrderingComposer
    extends Composer<_$AppDatabase, $FinancialAccountsTable> {
  $$FinancialAccountsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bankCode => $composableBuilder(
    column: $table.bankCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FinancialAccountsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FinancialAccountsTable> {
  $$FinancialAccountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<int> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get bankCode =>
      $composableBuilder(column: $table.bankCode, builder: (column) => column);

  GeneratedColumn<int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  Expression<T> accountEntriesRefs<T extends Object>(
    Expression<T> Function($$AccountEntriesTableAnnotationComposer a) f,
  ) {
    final $$AccountEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.accountEntries,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.accountEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> financialExpectationsRefs<T extends Object>(
    Expression<T> Function($$FinancialExpectationsTableAnnotationComposer a) f,
  ) {
    final $$FinancialExpectationsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.financialExpectations,
          getReferencedColumn: (t) => t.accountId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$FinancialExpectationsTableAnnotationComposer(
                $db: $db,
                $table: $db.financialExpectations,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$FinancialAccountsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FinancialAccountsTable,
          FinancialAccount,
          $$FinancialAccountsTableFilterComposer,
          $$FinancialAccountsTableOrderingComposer,
          $$FinancialAccountsTableAnnotationComposer,
          $$FinancialAccountsTableCreateCompanionBuilder,
          $$FinancialAccountsTableUpdateCompanionBuilder,
          (FinancialAccount, $$FinancialAccountsTableReferences),
          FinancialAccount,
          PrefetchHooks Function({
            bool accountEntriesRefs,
            bool financialExpectationsRefs,
          })
        > {
  $$FinancialAccountsTableTableManager(
    _$AppDatabase db,
    $FinancialAccountsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FinancialAccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FinancialAccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FinancialAccountsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<int> type = const Value.absent(),
                Value<String?> bankCode = const Value.absent(),
                Value<int> status = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FinancialAccountsCompanion(
                id: id,
                name: name,
                currency: currency,
                type: type,
                bankCode: bankCode,
                status: status,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String currency,
                required int type,
                Value<String?> bankCode = const Value.absent(),
                required int status,
                Value<int> rowid = const Value.absent(),
              }) => FinancialAccountsCompanion.insert(
                id: id,
                name: name,
                currency: currency,
                type: type,
                bankCode: bankCode,
                status: status,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FinancialAccountsTable, FinancialAccount>(table),
                  $$FinancialAccountsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                accountEntriesRefs = false,
                financialExpectationsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (accountEntriesRefs) db.accountEntries,
                    if (financialExpectationsRefs) db.financialExpectations,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (accountEntriesRefs)
                        await $_getPrefetchedData<
                          FinancialAccount,
                          $FinancialAccountsTable,
                          AccountEntry
                        >(
                          currentTable: table,
                          referencedTable: $$FinancialAccountsTableReferences
                              ._accountEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$FinancialAccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).accountEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.accountId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (financialExpectationsRefs)
                        await $_getPrefetchedData<
                          FinancialAccount,
                          $FinancialAccountsTable,
                          FinancialExpectation
                        >(
                          currentTable: table,
                          referencedTable: $$FinancialAccountsTableReferences
                              ._financialExpectationsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$FinancialAccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).financialExpectationsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.accountId == item.id,
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

typedef $$FinancialAccountsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FinancialAccountsTable,
      FinancialAccount,
      $$FinancialAccountsTableFilterComposer,
      $$FinancialAccountsTableOrderingComposer,
      $$FinancialAccountsTableAnnotationComposer,
      $$FinancialAccountsTableCreateCompanionBuilder,
      $$FinancialAccountsTableUpdateCompanionBuilder,
      (FinancialAccount, $$FinancialAccountsTableReferences),
      FinancialAccount,
      PrefetchHooks Function({
        bool accountEntriesRefs,
        bool financialExpectationsRefs,
      })
    >;
typedef $$AccountEntriesTableCreateCompanionBuilder =
    AccountEntriesCompanion Function({
      required String id,
      required String accountId,
      required int type,
      required int minorUnits,
      required String currency,
      required DateTime occurredAt,
      Value<String?> referenceId,
      Value<String?> note,
      Value<String?> category,
      Value<int> source,
      Value<String?> transferGroupId,
      Value<int> rowid,
    });
typedef $$AccountEntriesTableUpdateCompanionBuilder =
    AccountEntriesCompanion Function({
      Value<String> id,
      Value<String> accountId,
      Value<int> type,
      Value<int> minorUnits,
      Value<String> currency,
      Value<DateTime> occurredAt,
      Value<String?> referenceId,
      Value<String?> note,
      Value<String?> category,
      Value<int> source,
      Value<String?> transferGroupId,
      Value<int> rowid,
    });

final class $$AccountEntriesTableReferences
    extends BaseReferences<_$AppDatabase, $AccountEntriesTable, AccountEntry> {
  $$AccountEntriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $FinancialAccountsTable _accountIdTable(_$AppDatabase db) => db
      .financialAccounts
      .createAlias('account_entries__account_id__financial_accounts__id');

  $$FinancialAccountsTableProcessedTableManager get accountId {
    final $_column = $_itemColumn<String>('account_id')!;

    final manager = $$FinancialAccountsTableTableManager(
      $_db,
      $_db.financialAccounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$TransactionMatchesTable, List<TransactionMatche>>
  _transactionMatchesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.transactionMatches,
        aliasName: 'account_entries__id__transaction_matches__transaction_id',
      );

  $$TransactionMatchesTableProcessedTableManager get transactionMatchesRefs {
    final manager = $$TransactionMatchesTableTableManager(
      $_db,
      $_db.transactionMatches,
    ).filter((f) => f.transactionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _transactionMatchesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $RelationshipReviewsTable,
    List<RelationshipReview>
  >
  _relationshipReviewsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.relationshipReviews,
        aliasName: 'account_entries__id__relationship_reviews__transaction_id',
      );

  $$RelationshipReviewsTableProcessedTableManager get relationshipReviewsRefs {
    final manager = $$RelationshipReviewsTableTableManager(
      $_db,
      $_db.relationshipReviews,
    ).filter((f) => f.transactionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _relationshipReviewsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$AccountEntryTagsTable, List<AccountEntryTag>>
  _accountEntryTagsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.accountEntryTags,
    aliasName: 'account_entries__id__account_entry_tags__account_entry_id',
  );

  $$AccountEntryTagsTableProcessedTableManager get accountEntryTagsRefs {
    final manager = $$AccountEntryTagsTableTableManager(
      $_db,
      $_db.accountEntryTags,
    ).filter((f) => f.accountEntryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _accountEntryTagsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AccountEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $AccountEntriesTable> {
  $$AccountEntriesTableFilterComposer({
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

  ColumnFilters<int> get minorUnits => $composableBuilder(
    column: $table.minorUnits,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
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

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get transferGroupId => $composableBuilder(
    column: $table.transferGroupId,
    builder: (column) => ColumnFilters(column),
  );

  $$FinancialAccountsTableFilterComposer get accountId {
    final $$FinancialAccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.financialAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FinancialAccountsTableFilterComposer(
            $db: $db,
            $table: $db.financialAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> transactionMatchesRefs(
    Expression<bool> Function($$TransactionMatchesTableFilterComposer f) f,
  ) {
    final $$TransactionMatchesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactionMatches,
      getReferencedColumn: (t) => t.transactionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionMatchesTableFilterComposer(
            $db: $db,
            $table: $db.transactionMatches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> relationshipReviewsRefs(
    Expression<bool> Function($$RelationshipReviewsTableFilterComposer f) f,
  ) {
    final $$RelationshipReviewsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.relationshipReviews,
      getReferencedColumn: (t) => t.transactionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RelationshipReviewsTableFilterComposer(
            $db: $db,
            $table: $db.relationshipReviews,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> accountEntryTagsRefs(
    Expression<bool> Function($$AccountEntryTagsTableFilterComposer f) f,
  ) {
    final $$AccountEntryTagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.accountEntryTags,
      getReferencedColumn: (t) => t.accountEntryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountEntryTagsTableFilterComposer(
            $db: $db,
            $table: $db.accountEntryTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AccountEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $AccountEntriesTable> {
  $$AccountEntriesTableOrderingComposer({
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

  ColumnOrderings<int> get minorUnits => $composableBuilder(
    column: $table.minorUnits,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
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

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transferGroupId => $composableBuilder(
    column: $table.transferGroupId,
    builder: (column) => ColumnOrderings(column),
  );

  $$FinancialAccountsTableOrderingComposer get accountId {
    final $$FinancialAccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.financialAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FinancialAccountsTableOrderingComposer(
            $db: $db,
            $table: $db.financialAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AccountEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $AccountEntriesTable> {
  $$AccountEntriesTableAnnotationComposer({
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

  GeneratedColumn<int> get minorUnits => $composableBuilder(
    column: $table.minorUnits,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

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

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<int> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get transferGroupId => $composableBuilder(
    column: $table.transferGroupId,
    builder: (column) => column,
  );

  $$FinancialAccountsTableAnnotationComposer get accountId {
    final $$FinancialAccountsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.accountId,
          referencedTable: $db.financialAccounts,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$FinancialAccountsTableAnnotationComposer(
                $db: $db,
                $table: $db.financialAccounts,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  Expression<T> transactionMatchesRefs<T extends Object>(
    Expression<T> Function($$TransactionMatchesTableAnnotationComposer a) f,
  ) {
    final $$TransactionMatchesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.transactionMatches,
          getReferencedColumn: (t) => t.transactionId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TransactionMatchesTableAnnotationComposer(
                $db: $db,
                $table: $db.transactionMatches,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> relationshipReviewsRefs<T extends Object>(
    Expression<T> Function($$RelationshipReviewsTableAnnotationComposer a) f,
  ) {
    final $$RelationshipReviewsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.relationshipReviews,
          getReferencedColumn: (t) => t.transactionId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$RelationshipReviewsTableAnnotationComposer(
                $db: $db,
                $table: $db.relationshipReviews,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> accountEntryTagsRefs<T extends Object>(
    Expression<T> Function($$AccountEntryTagsTableAnnotationComposer a) f,
  ) {
    final $$AccountEntryTagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.accountEntryTags,
      getReferencedColumn: (t) => t.accountEntryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountEntryTagsTableAnnotationComposer(
            $db: $db,
            $table: $db.accountEntryTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AccountEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AccountEntriesTable,
          AccountEntry,
          $$AccountEntriesTableFilterComposer,
          $$AccountEntriesTableOrderingComposer,
          $$AccountEntriesTableAnnotationComposer,
          $$AccountEntriesTableCreateCompanionBuilder,
          $$AccountEntriesTableUpdateCompanionBuilder,
          (AccountEntry, $$AccountEntriesTableReferences),
          AccountEntry,
          PrefetchHooks Function({
            bool accountId,
            bool transactionMatchesRefs,
            bool relationshipReviewsRefs,
            bool accountEntryTagsRefs,
          })
        > {
  $$AccountEntriesTableTableManager(
    _$AppDatabase db,
    $AccountEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AccountEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AccountEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AccountEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                Value<int> type = const Value.absent(),
                Value<int> minorUnits = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<DateTime> occurredAt = const Value.absent(),
                Value<String?> referenceId = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<int> source = const Value.absent(),
                Value<String?> transferGroupId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AccountEntriesCompanion(
                id: id,
                accountId: accountId,
                type: type,
                minorUnits: minorUnits,
                currency: currency,
                occurredAt: occurredAt,
                referenceId: referenceId,
                note: note,
                category: category,
                source: source,
                transferGroupId: transferGroupId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String accountId,
                required int type,
                required int minorUnits,
                required String currency,
                required DateTime occurredAt,
                Value<String?> referenceId = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<int> source = const Value.absent(),
                Value<String?> transferGroupId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AccountEntriesCompanion.insert(
                id: id,
                accountId: accountId,
                type: type,
                minorUnits: minorUnits,
                currency: currency,
                occurredAt: occurredAt,
                referenceId: referenceId,
                note: note,
                category: category,
                source: source,
                transferGroupId: transferGroupId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AccountEntriesTable, AccountEntry>(table),
                  $$AccountEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                accountId = false,
                transactionMatchesRefs = false,
                relationshipReviewsRefs = false,
                accountEntryTagsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (transactionMatchesRefs) db.transactionMatches,
                    if (relationshipReviewsRefs) db.relationshipReviews,
                    if (accountEntryTagsRefs) db.accountEntryTags,
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
                        if (accountId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.accountId,
                            referencedTable: $$AccountEntriesTableReferences
                                ._accountIdTable(db),
                            referencedColumn: $$AccountEntriesTableReferences
                                ._accountIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (transactionMatchesRefs)
                        await $_getPrefetchedData<
                          AccountEntry,
                          $AccountEntriesTable,
                          TransactionMatche
                        >(
                          currentTable: table,
                          referencedTable: $$AccountEntriesTableReferences
                              ._transactionMatchesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AccountEntriesTableReferences(
                                db,
                                table,
                                p0,
                              ).transactionMatchesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.transactionId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (relationshipReviewsRefs)
                        await $_getPrefetchedData<
                          AccountEntry,
                          $AccountEntriesTable,
                          RelationshipReview
                        >(
                          currentTable: table,
                          referencedTable: $$AccountEntriesTableReferences
                              ._relationshipReviewsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AccountEntriesTableReferences(
                                db,
                                table,
                                p0,
                              ).relationshipReviewsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.transactionId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (accountEntryTagsRefs)
                        await $_getPrefetchedData<
                          AccountEntry,
                          $AccountEntriesTable,
                          AccountEntryTag
                        >(
                          currentTable: table,
                          referencedTable: $$AccountEntriesTableReferences
                              ._accountEntryTagsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AccountEntriesTableReferences(
                                db,
                                table,
                                p0,
                              ).accountEntryTagsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.accountEntryId == item.id,
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

typedef $$AccountEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AccountEntriesTable,
      AccountEntry,
      $$AccountEntriesTableFilterComposer,
      $$AccountEntriesTableOrderingComposer,
      $$AccountEntriesTableAnnotationComposer,
      $$AccountEntriesTableCreateCompanionBuilder,
      $$AccountEntriesTableUpdateCompanionBuilder,
      (AccountEntry, $$AccountEntriesTableReferences),
      AccountEntry,
      PrefetchHooks Function({
        bool accountId,
        bool transactionMatchesRefs,
        bool relationshipReviewsRefs,
        bool accountEntryTagsRefs,
      })
    >;
typedef $$TransactionMatchesTableCreateCompanionBuilder =
    TransactionMatchesCompanion Function({
      required String id,
      required String transactionId,
      required int minorUnits,
      required String currency,
      required DateTime createdAt,
      required int status,
      Value<String?> correctedMatchId,
      Value<int> rowid,
    });
typedef $$TransactionMatchesTableUpdateCompanionBuilder =
    TransactionMatchesCompanion Function({
      Value<String> id,
      Value<String> transactionId,
      Value<int> minorUnits,
      Value<String> currency,
      Value<DateTime> createdAt,
      Value<int> status,
      Value<String?> correctedMatchId,
      Value<int> rowid,
    });

final class $$TransactionMatchesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $TransactionMatchesTable,
          TransactionMatche
        > {
  $$TransactionMatchesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $AccountEntriesTable _transactionIdTable(_$AppDatabase db) => db
      .accountEntries
      .createAlias('transaction_matches__transaction_id__account_entries__id');

  $$AccountEntriesTableProcessedTableManager get transactionId {
    final $_column = $_itemColumn<String>('transaction_id')!;

    final manager = $$AccountEntriesTableTableManager(
      $_db,
      $_db.accountEntries,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_transactionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$MatchAllocationsTable, List<MatchAllocation>>
  _matchAllocationsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.matchAllocations,
    aliasName: 'transaction_matches__id__match_allocations__match_id',
  );

  $$MatchAllocationsTableProcessedTableManager get matchAllocationsRefs {
    final manager = $$MatchAllocationsTableTableManager(
      $_db,
      $_db.matchAllocations,
    ).filter((f) => f.matchId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _matchAllocationsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TransactionMatchesTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionMatchesTable> {
  $$TransactionMatchesTableFilterComposer({
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

  ColumnFilters<int> get minorUnits => $composableBuilder(
    column: $table.minorUnits,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
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

  ColumnFilters<String> get correctedMatchId => $composableBuilder(
    column: $table.correctedMatchId,
    builder: (column) => ColumnFilters(column),
  );

  $$AccountEntriesTableFilterComposer get transactionId {
    final $$AccountEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.transactionId,
      referencedTable: $db.accountEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountEntriesTableFilterComposer(
            $db: $db,
            $table: $db.accountEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> matchAllocationsRefs(
    Expression<bool> Function($$MatchAllocationsTableFilterComposer f) f,
  ) {
    final $$MatchAllocationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.matchAllocations,
      getReferencedColumn: (t) => t.matchId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MatchAllocationsTableFilterComposer(
            $db: $db,
            $table: $db.matchAllocations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TransactionMatchesTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionMatchesTable> {
  $$TransactionMatchesTableOrderingComposer({
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

  ColumnOrderings<int> get minorUnits => $composableBuilder(
    column: $table.minorUnits,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
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

  ColumnOrderings<String> get correctedMatchId => $composableBuilder(
    column: $table.correctedMatchId,
    builder: (column) => ColumnOrderings(column),
  );

  $$AccountEntriesTableOrderingComposer get transactionId {
    final $$AccountEntriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.transactionId,
      referencedTable: $db.accountEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountEntriesTableOrderingComposer(
            $db: $db,
            $table: $db.accountEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionMatchesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionMatchesTable> {
  $$TransactionMatchesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get minorUnits => $composableBuilder(
    column: $table.minorUnits,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get correctedMatchId => $composableBuilder(
    column: $table.correctedMatchId,
    builder: (column) => column,
  );

  $$AccountEntriesTableAnnotationComposer get transactionId {
    final $$AccountEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.transactionId,
      referencedTable: $db.accountEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.accountEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> matchAllocationsRefs<T extends Object>(
    Expression<T> Function($$MatchAllocationsTableAnnotationComposer a) f,
  ) {
    final $$MatchAllocationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.matchAllocations,
      getReferencedColumn: (t) => t.matchId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MatchAllocationsTableAnnotationComposer(
            $db: $db,
            $table: $db.matchAllocations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TransactionMatchesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransactionMatchesTable,
          TransactionMatche,
          $$TransactionMatchesTableFilterComposer,
          $$TransactionMatchesTableOrderingComposer,
          $$TransactionMatchesTableAnnotationComposer,
          $$TransactionMatchesTableCreateCompanionBuilder,
          $$TransactionMatchesTableUpdateCompanionBuilder,
          (TransactionMatche, $$TransactionMatchesTableReferences),
          TransactionMatche,
          PrefetchHooks Function({
            bool transactionId,
            bool matchAllocationsRefs,
          })
        > {
  $$TransactionMatchesTableTableManager(
    _$AppDatabase db,
    $TransactionMatchesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionMatchesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionMatchesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionMatchesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> transactionId = const Value.absent(),
                Value<int> minorUnits = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> status = const Value.absent(),
                Value<String?> correctedMatchId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransactionMatchesCompanion(
                id: id,
                transactionId: transactionId,
                minorUnits: minorUnits,
                currency: currency,
                createdAt: createdAt,
                status: status,
                correctedMatchId: correctedMatchId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String transactionId,
                required int minorUnits,
                required String currency,
                required DateTime createdAt,
                required int status,
                Value<String?> correctedMatchId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransactionMatchesCompanion.insert(
                id: id,
                transactionId: transactionId,
                minorUnits: minorUnits,
                currency: currency,
                createdAt: createdAt,
                status: status,
                correctedMatchId: correctedMatchId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TransactionMatchesTable, TransactionMatche>(
                    table,
                  ),
                  $$TransactionMatchesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({transactionId = false, matchAllocationsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (matchAllocationsRefs) db.matchAllocations,
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
                        if (transactionId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.transactionId,
                            referencedTable: $$TransactionMatchesTableReferences
                                ._transactionIdTable(db),
                            referencedColumn:
                                $$TransactionMatchesTableReferences
                                    ._transactionIdTable(db)
                                    .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (matchAllocationsRefs)
                        await $_getPrefetchedData<
                          TransactionMatche,
                          $TransactionMatchesTable,
                          MatchAllocation
                        >(
                          currentTable: table,
                          referencedTable: $$TransactionMatchesTableReferences
                              ._matchAllocationsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TransactionMatchesTableReferences(
                                db,
                                table,
                                p0,
                              ).matchAllocationsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.matchId == item.id,
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

typedef $$TransactionMatchesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransactionMatchesTable,
      TransactionMatche,
      $$TransactionMatchesTableFilterComposer,
      $$TransactionMatchesTableOrderingComposer,
      $$TransactionMatchesTableAnnotationComposer,
      $$TransactionMatchesTableCreateCompanionBuilder,
      $$TransactionMatchesTableUpdateCompanionBuilder,
      (TransactionMatche, $$TransactionMatchesTableReferences),
      TransactionMatche,
      PrefetchHooks Function({bool transactionId, bool matchAllocationsRefs})
    >;
typedef $$MatchAllocationsTableCreateCompanionBuilder =
    MatchAllocationsCompanion Function({
      required String id,
      required String matchId,
      required String occurrenceId,
      required int minorUnits,
      required String currency,
      required int type,
      Value<int> rowid,
    });
typedef $$MatchAllocationsTableUpdateCompanionBuilder =
    MatchAllocationsCompanion Function({
      Value<String> id,
      Value<String> matchId,
      Value<String> occurrenceId,
      Value<int> minorUnits,
      Value<String> currency,
      Value<int> type,
      Value<int> rowid,
    });

final class $$MatchAllocationsTableReferences
    extends
        BaseReferences<_$AppDatabase, $MatchAllocationsTable, MatchAllocation> {
  $$MatchAllocationsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $TransactionMatchesTable _matchIdTable(_$AppDatabase db) => db
      .transactionMatches
      .createAlias('match_allocations__match_id__transaction_matches__id');

  $$TransactionMatchesTableProcessedTableManager get matchId {
    final $_column = $_itemColumn<String>('match_id')!;

    final manager = $$TransactionMatchesTableTableManager(
      $_db,
      $_db.transactionMatches,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_matchIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $OccurrencesTable _occurrenceIdTable(_$AppDatabase db) => db
      .occurrences
      .createAlias('match_allocations__occurrence_id__occurrences__id');

  $$OccurrencesTableProcessedTableManager get occurrenceId {
    final $_column = $_itemColumn<String>('occurrence_id')!;

    final manager = $$OccurrencesTableTableManager(
      $_db,
      $_db.occurrences,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_occurrenceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MatchAllocationsTableFilterComposer
    extends Composer<_$AppDatabase, $MatchAllocationsTable> {
  $$MatchAllocationsTableFilterComposer({
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

  ColumnFilters<int> get minorUnits => $composableBuilder(
    column: $table.minorUnits,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  $$TransactionMatchesTableFilterComposer get matchId {
    final $$TransactionMatchesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.matchId,
      referencedTable: $db.transactionMatches,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionMatchesTableFilterComposer(
            $db: $db,
            $table: $db.transactionMatches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$OccurrencesTableFilterComposer get occurrenceId {
    final $$OccurrencesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.occurrenceId,
      referencedTable: $db.occurrences,
      getReferencedColumn: (t) => t.id,
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
    return composer;
  }
}

class $$MatchAllocationsTableOrderingComposer
    extends Composer<_$AppDatabase, $MatchAllocationsTable> {
  $$MatchAllocationsTableOrderingComposer({
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

  ColumnOrderings<int> get minorUnits => $composableBuilder(
    column: $table.minorUnits,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  $$TransactionMatchesTableOrderingComposer get matchId {
    final $$TransactionMatchesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.matchId,
      referencedTable: $db.transactionMatches,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionMatchesTableOrderingComposer(
            $db: $db,
            $table: $db.transactionMatches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$OccurrencesTableOrderingComposer get occurrenceId {
    final $$OccurrencesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.occurrenceId,
      referencedTable: $db.occurrences,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OccurrencesTableOrderingComposer(
            $db: $db,
            $table: $db.occurrences,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MatchAllocationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MatchAllocationsTable> {
  $$MatchAllocationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get minorUnits => $composableBuilder(
    column: $table.minorUnits,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<int> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  $$TransactionMatchesTableAnnotationComposer get matchId {
    final $$TransactionMatchesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.matchId,
          referencedTable: $db.transactionMatches,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TransactionMatchesTableAnnotationComposer(
                $db: $db,
                $table: $db.transactionMatches,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  $$OccurrencesTableAnnotationComposer get occurrenceId {
    final $$OccurrencesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.occurrenceId,
      referencedTable: $db.occurrences,
      getReferencedColumn: (t) => t.id,
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
    return composer;
  }
}

class $$MatchAllocationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MatchAllocationsTable,
          MatchAllocation,
          $$MatchAllocationsTableFilterComposer,
          $$MatchAllocationsTableOrderingComposer,
          $$MatchAllocationsTableAnnotationComposer,
          $$MatchAllocationsTableCreateCompanionBuilder,
          $$MatchAllocationsTableUpdateCompanionBuilder,
          (MatchAllocation, $$MatchAllocationsTableReferences),
          MatchAllocation,
          PrefetchHooks Function({bool matchId, bool occurrenceId})
        > {
  $$MatchAllocationsTableTableManager(
    _$AppDatabase db,
    $MatchAllocationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MatchAllocationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MatchAllocationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MatchAllocationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> matchId = const Value.absent(),
                Value<String> occurrenceId = const Value.absent(),
                Value<int> minorUnits = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<int> type = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MatchAllocationsCompanion(
                id: id,
                matchId: matchId,
                occurrenceId: occurrenceId,
                minorUnits: minorUnits,
                currency: currency,
                type: type,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String matchId,
                required String occurrenceId,
                required int minorUnits,
                required String currency,
                required int type,
                Value<int> rowid = const Value.absent(),
              }) => MatchAllocationsCompanion.insert(
                id: id,
                matchId: matchId,
                occurrenceId: occurrenceId,
                minorUnits: minorUnits,
                currency: currency,
                type: type,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MatchAllocationsTable, MatchAllocation>(table),
                  $$MatchAllocationsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({matchId = false, occurrenceId = false}) {
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
                    if (matchId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.matchId,
                        referencedTable: $$MatchAllocationsTableReferences
                            ._matchIdTable(db),
                        referencedColumn: $$MatchAllocationsTableReferences
                            ._matchIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (occurrenceId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.occurrenceId,
                        referencedTable: $$MatchAllocationsTableReferences
                            ._occurrenceIdTable(db),
                        referencedColumn: $$MatchAllocationsTableReferences
                            ._occurrenceIdTable(db)
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

typedef $$MatchAllocationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MatchAllocationsTable,
      MatchAllocation,
      $$MatchAllocationsTableFilterComposer,
      $$MatchAllocationsTableOrderingComposer,
      $$MatchAllocationsTableAnnotationComposer,
      $$MatchAllocationsTableCreateCompanionBuilder,
      $$MatchAllocationsTableUpdateCompanionBuilder,
      (MatchAllocation, $$MatchAllocationsTableReferences),
      MatchAllocation,
      PrefetchHooks Function({bool matchId, bool occurrenceId})
    >;
typedef $$RelationshipReviewsTableCreateCompanionBuilder =
    RelationshipReviewsCompanion Function({
      required String id,
      required String transactionId,
      required int revision,
      required int decision,
      required int minorUnits,
      required String currency,
      required String allocationFingerprint,
      required String allocationHistoryFingerprint,
      required int remainderMinorUnits,
      required DateTime recordedAt,
      Value<int> rowid,
    });
typedef $$RelationshipReviewsTableUpdateCompanionBuilder =
    RelationshipReviewsCompanion Function({
      Value<String> id,
      Value<String> transactionId,
      Value<int> revision,
      Value<int> decision,
      Value<int> minorUnits,
      Value<String> currency,
      Value<String> allocationFingerprint,
      Value<String> allocationHistoryFingerprint,
      Value<int> remainderMinorUnits,
      Value<DateTime> recordedAt,
      Value<int> rowid,
    });

final class $$RelationshipReviewsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $RelationshipReviewsTable,
          RelationshipReview
        > {
  $$RelationshipReviewsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $AccountEntriesTable _transactionIdTable(_$AppDatabase db) => db
      .accountEntries
      .createAlias('relationship_reviews__transaction_id__account_entries__id');

  $$AccountEntriesTableProcessedTableManager get transactionId {
    final $_column = $_itemColumn<String>('transaction_id')!;

    final manager = $$AccountEntriesTableTableManager(
      $_db,
      $_db.accountEntries,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_transactionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$RelationshipReviewsTableFilterComposer
    extends Composer<_$AppDatabase, $RelationshipReviewsTable> {
  $$RelationshipReviewsTableFilterComposer({
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

  ColumnFilters<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get decision => $composableBuilder(
    column: $table.decision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get minorUnits => $composableBuilder(
    column: $table.minorUnits,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get allocationFingerprint => $composableBuilder(
    column: $table.allocationFingerprint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get allocationHistoryFingerprint => $composableBuilder(
    column: $table.allocationHistoryFingerprint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get remainderMinorUnits => $composableBuilder(
    column: $table.remainderMinorUnits,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$AccountEntriesTableFilterComposer get transactionId {
    final $$AccountEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.transactionId,
      referencedTable: $db.accountEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountEntriesTableFilterComposer(
            $db: $db,
            $table: $db.accountEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RelationshipReviewsTableOrderingComposer
    extends Composer<_$AppDatabase, $RelationshipReviewsTable> {
  $$RelationshipReviewsTableOrderingComposer({
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

  ColumnOrderings<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get decision => $composableBuilder(
    column: $table.decision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get minorUnits => $composableBuilder(
    column: $table.minorUnits,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get allocationFingerprint => $composableBuilder(
    column: $table.allocationFingerprint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get allocationHistoryFingerprint =>
      $composableBuilder(
        column: $table.allocationHistoryFingerprint,
        builder: (column) => ColumnOrderings(column),
      );

  ColumnOrderings<int> get remainderMinorUnits => $composableBuilder(
    column: $table.remainderMinorUnits,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$AccountEntriesTableOrderingComposer get transactionId {
    final $$AccountEntriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.transactionId,
      referencedTable: $db.accountEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountEntriesTableOrderingComposer(
            $db: $db,
            $table: $db.accountEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RelationshipReviewsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RelationshipReviewsTable> {
  $$RelationshipReviewsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => column);

  GeneratedColumn<int> get decision =>
      $composableBuilder(column: $table.decision, builder: (column) => column);

  GeneratedColumn<int> get minorUnits => $composableBuilder(
    column: $table.minorUnits,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<String> get allocationFingerprint => $composableBuilder(
    column: $table.allocationFingerprint,
    builder: (column) => column,
  );

  GeneratedColumn<String> get allocationHistoryFingerprint =>
      $composableBuilder(
        column: $table.allocationHistoryFingerprint,
        builder: (column) => column,
      );

  GeneratedColumn<int> get remainderMinorUnits => $composableBuilder(
    column: $table.remainderMinorUnits,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => column,
  );

  $$AccountEntriesTableAnnotationComposer get transactionId {
    final $$AccountEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.transactionId,
      referencedTable: $db.accountEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.accountEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RelationshipReviewsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RelationshipReviewsTable,
          RelationshipReview,
          $$RelationshipReviewsTableFilterComposer,
          $$RelationshipReviewsTableOrderingComposer,
          $$RelationshipReviewsTableAnnotationComposer,
          $$RelationshipReviewsTableCreateCompanionBuilder,
          $$RelationshipReviewsTableUpdateCompanionBuilder,
          (RelationshipReview, $$RelationshipReviewsTableReferences),
          RelationshipReview,
          PrefetchHooks Function({bool transactionId})
        > {
  $$RelationshipReviewsTableTableManager(
    _$AppDatabase db,
    $RelationshipReviewsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RelationshipReviewsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RelationshipReviewsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$RelationshipReviewsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> transactionId = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<int> decision = const Value.absent(),
                Value<int> minorUnits = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<String> allocationFingerprint = const Value.absent(),
                Value<String> allocationHistoryFingerprint =
                    const Value.absent(),
                Value<int> remainderMinorUnits = const Value.absent(),
                Value<DateTime> recordedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RelationshipReviewsCompanion(
                id: id,
                transactionId: transactionId,
                revision: revision,
                decision: decision,
                minorUnits: minorUnits,
                currency: currency,
                allocationFingerprint: allocationFingerprint,
                allocationHistoryFingerprint: allocationHistoryFingerprint,
                remainderMinorUnits: remainderMinorUnits,
                recordedAt: recordedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String transactionId,
                required int revision,
                required int decision,
                required int minorUnits,
                required String currency,
                required String allocationFingerprint,
                required String allocationHistoryFingerprint,
                required int remainderMinorUnits,
                required DateTime recordedAt,
                Value<int> rowid = const Value.absent(),
              }) => RelationshipReviewsCompanion.insert(
                id: id,
                transactionId: transactionId,
                revision: revision,
                decision: decision,
                minorUnits: minorUnits,
                currency: currency,
                allocationFingerprint: allocationFingerprint,
                allocationHistoryFingerprint: allocationHistoryFingerprint,
                remainderMinorUnits: remainderMinorUnits,
                recordedAt: recordedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RelationshipReviewsTable, RelationshipReview>(
                    table,
                  ),
                  $$RelationshipReviewsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({transactionId = false}) {
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
                    if (transactionId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.transactionId,
                        referencedTable: $$RelationshipReviewsTableReferences
                            ._transactionIdTable(db),
                        referencedColumn: $$RelationshipReviewsTableReferences
                            ._transactionIdTable(db)
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

typedef $$RelationshipReviewsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RelationshipReviewsTable,
      RelationshipReview,
      $$RelationshipReviewsTableFilterComposer,
      $$RelationshipReviewsTableOrderingComposer,
      $$RelationshipReviewsTableAnnotationComposer,
      $$RelationshipReviewsTableCreateCompanionBuilder,
      $$RelationshipReviewsTableUpdateCompanionBuilder,
      (RelationshipReview, $$RelationshipReviewsTableReferences),
      RelationshipReview,
      PrefetchHooks Function({bool transactionId})
    >;
typedef $$FinancialExpectationsTableCreateCompanionBuilder =
    FinancialExpectationsCompanion Function({
      required String id,
      required String occurrenceId,
      required int direction,
      required int minorUnits,
      Value<String?> currency,
      Value<String?> accountId,
      required int status,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$FinancialExpectationsTableUpdateCompanionBuilder =
    FinancialExpectationsCompanion Function({
      Value<String> id,
      Value<String> occurrenceId,
      Value<int> direction,
      Value<int> minorUnits,
      Value<String?> currency,
      Value<String?> accountId,
      Value<int> status,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$FinancialExpectationsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $FinancialExpectationsTable,
          FinancialExpectation
        > {
  $$FinancialExpectationsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $OccurrencesTable _occurrenceIdTable(_$AppDatabase db) => db
      .occurrences
      .createAlias('financial_expectations__occurrence_id__occurrences__id');

  $$OccurrencesTableProcessedTableManager get occurrenceId {
    final $_column = $_itemColumn<String>('occurrence_id')!;

    final manager = $$OccurrencesTableTableManager(
      $_db,
      $_db.occurrences,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_occurrenceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $FinancialAccountsTable _accountIdTable(_$AppDatabase db) =>
      db.financialAccounts.createAlias(
        'financial_expectations__account_id__financial_accounts__id',
      );

  $$FinancialAccountsTableProcessedTableManager? get accountId {
    final $_column = $_itemColumn<String>('account_id');
    if ($_column == null) return null;
    final manager = $$FinancialAccountsTableTableManager(
      $_db,
      $_db.financialAccounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$FinancialExpectationsTableFilterComposer
    extends Composer<_$AppDatabase, $FinancialExpectationsTable> {
  $$FinancialExpectationsTableFilterComposer({
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

  ColumnFilters<int> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get minorUnits => $composableBuilder(
    column: $table.minorUnits,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$OccurrencesTableFilterComposer get occurrenceId {
    final $$OccurrencesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.occurrenceId,
      referencedTable: $db.occurrences,
      getReferencedColumn: (t) => t.id,
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
    return composer;
  }

  $$FinancialAccountsTableFilterComposer get accountId {
    final $$FinancialAccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.financialAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FinancialAccountsTableFilterComposer(
            $db: $db,
            $table: $db.financialAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FinancialExpectationsTableOrderingComposer
    extends Composer<_$AppDatabase, $FinancialExpectationsTable> {
  $$FinancialExpectationsTableOrderingComposer({
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

  ColumnOrderings<int> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get minorUnits => $composableBuilder(
    column: $table.minorUnits,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$OccurrencesTableOrderingComposer get occurrenceId {
    final $$OccurrencesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.occurrenceId,
      referencedTable: $db.occurrences,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OccurrencesTableOrderingComposer(
            $db: $db,
            $table: $db.occurrences,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FinancialAccountsTableOrderingComposer get accountId {
    final $$FinancialAccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.financialAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FinancialAccountsTableOrderingComposer(
            $db: $db,
            $table: $db.financialAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FinancialExpectationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FinancialExpectationsTable> {
  $$FinancialExpectationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get direction =>
      $composableBuilder(column: $table.direction, builder: (column) => column);

  GeneratedColumn<int> get minorUnits => $composableBuilder(
    column: $table.minorUnits,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$OccurrencesTableAnnotationComposer get occurrenceId {
    final $$OccurrencesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.occurrenceId,
      referencedTable: $db.occurrences,
      getReferencedColumn: (t) => t.id,
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
    return composer;
  }

  $$FinancialAccountsTableAnnotationComposer get accountId {
    final $$FinancialAccountsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.accountId,
          referencedTable: $db.financialAccounts,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$FinancialAccountsTableAnnotationComposer(
                $db: $db,
                $table: $db.financialAccounts,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$FinancialExpectationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FinancialExpectationsTable,
          FinancialExpectation,
          $$FinancialExpectationsTableFilterComposer,
          $$FinancialExpectationsTableOrderingComposer,
          $$FinancialExpectationsTableAnnotationComposer,
          $$FinancialExpectationsTableCreateCompanionBuilder,
          $$FinancialExpectationsTableUpdateCompanionBuilder,
          (FinancialExpectation, $$FinancialExpectationsTableReferences),
          FinancialExpectation,
          PrefetchHooks Function({bool occurrenceId, bool accountId})
        > {
  $$FinancialExpectationsTableTableManager(
    _$AppDatabase db,
    $FinancialExpectationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FinancialExpectationsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$FinancialExpectationsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$FinancialExpectationsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> occurrenceId = const Value.absent(),
                Value<int> direction = const Value.absent(),
                Value<int> minorUnits = const Value.absent(),
                Value<String?> currency = const Value.absent(),
                Value<String?> accountId = const Value.absent(),
                Value<int> status = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FinancialExpectationsCompanion(
                id: id,
                occurrenceId: occurrenceId,
                direction: direction,
                minorUnits: minorUnits,
                currency: currency,
                accountId: accountId,
                status: status,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String occurrenceId,
                required int direction,
                required int minorUnits,
                Value<String?> currency = const Value.absent(),
                Value<String?> accountId = const Value.absent(),
                required int status,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => FinancialExpectationsCompanion.insert(
                id: id,
                occurrenceId: occurrenceId,
                direction: direction,
                minorUnits: minorUnits,
                currency: currency,
                accountId: accountId,
                status: status,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $FinancialExpectationsTable,
                    FinancialExpectation
                  >(table),
                  $$FinancialExpectationsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({occurrenceId = false, accountId = false}) {
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
                    if (occurrenceId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.occurrenceId,
                        referencedTable: $$FinancialExpectationsTableReferences
                            ._occurrenceIdTable(db),
                        referencedColumn: $$FinancialExpectationsTableReferences
                            ._occurrenceIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (accountId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.accountId,
                        referencedTable: $$FinancialExpectationsTableReferences
                            ._accountIdTable(db),
                        referencedColumn: $$FinancialExpectationsTableReferences
                            ._accountIdTable(db)
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

typedef $$FinancialExpectationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FinancialExpectationsTable,
      FinancialExpectation,
      $$FinancialExpectationsTableFilterComposer,
      $$FinancialExpectationsTableOrderingComposer,
      $$FinancialExpectationsTableAnnotationComposer,
      $$FinancialExpectationsTableCreateCompanionBuilder,
      $$FinancialExpectationsTableUpdateCompanionBuilder,
      (FinancialExpectation, $$FinancialExpectationsTableReferences),
      FinancialExpectation,
      PrefetchHooks Function({bool occurrenceId, bool accountId})
    >;
typedef $$TagsTableCreateCompanionBuilder = TagsCompanion Function({
  required String id,
  required String label,
  required String normalizedLabel,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$TagsTableUpdateCompanionBuilder = TagsCompanion Function({
  Value<String> id,
  Value<String> label,
  Value<String> normalizedLabel,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$TagsTableReferences
    extends BaseReferences<_$AppDatabase, $TagsTable, Tag> {
  $$TagsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$CommitmentTagsTable, List<CommitmentTag>>
  _commitmentTagsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.commitmentTags,
    aliasName: 'tags__id__commitment_tags__tag_id',
  );

  $$CommitmentTagsTableProcessedTableManager get commitmentTagsRefs {
    final manager = $$CommitmentTagsTableTableManager(
      $_db,
      $_db.commitmentTags,
    ).filter((f) => f.tagId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_commitmentTagsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$AccountEntryTagsTable, List<AccountEntryTag>>
  _accountEntryTagsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.accountEntryTags,
    aliasName: 'tags__id__account_entry_tags__tag_id',
  );

  $$AccountEntryTagsTableProcessedTableManager get accountEntryTagsRefs {
    final manager = $$AccountEntryTagsTableTableManager(
      $_db,
      $_db.accountEntryTags,
    ).filter((f) => f.tagId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _accountEntryTagsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TagsTableFilterComposer extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableFilterComposer({
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

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get normalizedLabel => $composableBuilder(
    column: $table.normalizedLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> commitmentTagsRefs(
    Expression<bool> Function($$CommitmentTagsTableFilterComposer f) f,
  ) {
    final $$CommitmentTagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.commitmentTags,
      getReferencedColumn: (t) => t.tagId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CommitmentTagsTableFilterComposer(
            $db: $db,
            $table: $db.commitmentTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> accountEntryTagsRefs(
    Expression<bool> Function($$AccountEntryTagsTableFilterComposer f) f,
  ) {
    final $$AccountEntryTagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.accountEntryTags,
      getReferencedColumn: (t) => t.tagId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountEntryTagsTableFilterComposer(
            $db: $db,
            $table: $db.accountEntryTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TagsTableOrderingComposer extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableOrderingComposer({
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

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get normalizedLabel => $composableBuilder(
    column: $table.normalizedLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<String> get normalizedLabel => $composableBuilder(
    column: $table.normalizedLabel,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> commitmentTagsRefs<T extends Object>(
    Expression<T> Function($$CommitmentTagsTableAnnotationComposer a) f,
  ) {
    final $$CommitmentTagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.commitmentTags,
      getReferencedColumn: (t) => t.tagId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CommitmentTagsTableAnnotationComposer(
            $db: $db,
            $table: $db.commitmentTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> accountEntryTagsRefs<T extends Object>(
    Expression<T> Function($$AccountEntryTagsTableAnnotationComposer a) f,
  ) {
    final $$AccountEntryTagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.accountEntryTags,
      getReferencedColumn: (t) => t.tagId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountEntryTagsTableAnnotationComposer(
            $db: $db,
            $table: $db.accountEntryTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TagsTable,
          Tag,
          $$TagsTableFilterComposer,
          $$TagsTableOrderingComposer,
          $$TagsTableAnnotationComposer,
          $$TagsTableCreateCompanionBuilder,
          $$TagsTableUpdateCompanionBuilder,
          (Tag, $$TagsTableReferences),
          Tag,
          PrefetchHooks Function({
            bool commitmentTagsRefs,
            bool accountEntryTagsRefs,
          })
        > {
  $$TagsTableTableManager(_$AppDatabase db, $TagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<String> normalizedLabel = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TagsCompanion(
                id: id,
                label: label,
                normalizedLabel: normalizedLabel,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String label,
                required String normalizedLabel,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => TagsCompanion.insert(
                id: id,
                label: label,
                normalizedLabel: normalizedLabel,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TagsTable, Tag>(table),
                  $$TagsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({commitmentTagsRefs = false, accountEntryTagsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (commitmentTagsRefs) db.commitmentTags,
                    if (accountEntryTagsRefs) db.accountEntryTags,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (commitmentTagsRefs)
                        await $_getPrefetchedData<
                          Tag,
                          $TagsTable,
                          CommitmentTag
                        >(
                          currentTable: table,
                          referencedTable: $$TagsTableReferences
                              ._commitmentTagsRefsTable(db),
                          managerFromTypedResult: (p0) => $$TagsTableReferences(
                            db,
                            table,
                            p0,
                          ).commitmentTagsRefs,
                          referencedItemsForCurrentItem: (
                            item,
                            referencedItems,
                          ) => referencedItems.where((e) => e.tagId == item.id),
                          typedResults: items,
                        ),
                      if (accountEntryTagsRefs)
                        await $_getPrefetchedData<
                          Tag,
                          $TagsTable,
                          AccountEntryTag
                        >(
                          currentTable: table,
                          referencedTable: $$TagsTableReferences
                              ._accountEntryTagsRefsTable(db),
                          managerFromTypedResult: (p0) => $$TagsTableReferences(
                            db,
                            table,
                            p0,
                          ).accountEntryTagsRefs,
                          referencedItemsForCurrentItem: (
                            item,
                            referencedItems,
                          ) => referencedItems.where((e) => e.tagId == item.id),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$TagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TagsTable,
      Tag,
      $$TagsTableFilterComposer,
      $$TagsTableOrderingComposer,
      $$TagsTableAnnotationComposer,
      $$TagsTableCreateCompanionBuilder,
      $$TagsTableUpdateCompanionBuilder,
      (Tag, $$TagsTableReferences),
      Tag,
      PrefetchHooks Function({
        bool commitmentTagsRefs,
        bool accountEntryTagsRefs,
      })
    >;
typedef $$CommitmentTagsTableCreateCompanionBuilder =
    CommitmentTagsCompanion Function({
      required String commitmentId,
      required String tagId,
      Value<int> rowid,
    });
typedef $$CommitmentTagsTableUpdateCompanionBuilder =
    CommitmentTagsCompanion Function({
      Value<String> commitmentId,
      Value<String> tagId,
      Value<int> rowid,
    });

final class $$CommitmentTagsTableReferences
    extends BaseReferences<_$AppDatabase, $CommitmentTagsTable, CommitmentTag> {
  $$CommitmentTagsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CommitmentsTable _commitmentIdTable(_$AppDatabase db) => db
      .commitments
      .createAlias('commitment_tags__commitment_id__commitments__id');

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

  static $TagsTable _tagIdTable(_$AppDatabase db) =>
      db.tags.createAlias('commitment_tags__tag_id__tags__id');

  $$TagsTableProcessedTableManager get tagId {
    final $_column = $_itemColumn<String>('tag_id')!;

    final manager = $$TagsTableTableManager(
      $_db,
      $_db.tags,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_tagIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CommitmentTagsTableFilterComposer
    extends Composer<_$AppDatabase, $CommitmentTagsTable> {
  $$CommitmentTagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
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

  $$TagsTableFilterComposer get tagId {
    final $$TagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableFilterComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CommitmentTagsTableOrderingComposer
    extends Composer<_$AppDatabase, $CommitmentTagsTable> {
  $$CommitmentTagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
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

  $$TagsTableOrderingComposer get tagId {
    final $$TagsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableOrderingComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CommitmentTagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CommitmentTagsTable> {
  $$CommitmentTagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
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

  $$TagsTableAnnotationComposer get tagId {
    final $$TagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableAnnotationComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CommitmentTagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CommitmentTagsTable,
          CommitmentTag,
          $$CommitmentTagsTableFilterComposer,
          $$CommitmentTagsTableOrderingComposer,
          $$CommitmentTagsTableAnnotationComposer,
          $$CommitmentTagsTableCreateCompanionBuilder,
          $$CommitmentTagsTableUpdateCompanionBuilder,
          (CommitmentTag, $$CommitmentTagsTableReferences),
          CommitmentTag,
          PrefetchHooks Function({bool commitmentId, bool tagId})
        > {
  $$CommitmentTagsTableTableManager(
    _$AppDatabase db,
    $CommitmentTagsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CommitmentTagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CommitmentTagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CommitmentTagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> commitmentId = const Value.absent(),
                Value<String> tagId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CommitmentTagsCompanion(
                commitmentId: commitmentId,
                tagId: tagId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String commitmentId,
                required String tagId,
                Value<int> rowid = const Value.absent(),
              }) => CommitmentTagsCompanion.insert(
                commitmentId: commitmentId,
                tagId: tagId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CommitmentTagsTable, CommitmentTag>(table),
                  $$CommitmentTagsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({commitmentId = false, tagId = false}) {
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
                        referencedTable: $$CommitmentTagsTableReferences
                            ._commitmentIdTable(db),
                        referencedColumn: $$CommitmentTagsTableReferences
                            ._commitmentIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (tagId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.tagId,
                        referencedTable: $$CommitmentTagsTableReferences
                            ._tagIdTable(db),
                        referencedColumn: $$CommitmentTagsTableReferences
                            ._tagIdTable(db)
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

typedef $$CommitmentTagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CommitmentTagsTable,
      CommitmentTag,
      $$CommitmentTagsTableFilterComposer,
      $$CommitmentTagsTableOrderingComposer,
      $$CommitmentTagsTableAnnotationComposer,
      $$CommitmentTagsTableCreateCompanionBuilder,
      $$CommitmentTagsTableUpdateCompanionBuilder,
      (CommitmentTag, $$CommitmentTagsTableReferences),
      CommitmentTag,
      PrefetchHooks Function({bool commitmentId, bool tagId})
    >;
typedef $$AccountEntryTagsTableCreateCompanionBuilder =
    AccountEntryTagsCompanion Function({
      required String accountEntryId,
      required String tagId,
      Value<int> rowid,
    });
typedef $$AccountEntryTagsTableUpdateCompanionBuilder =
    AccountEntryTagsCompanion Function({
      Value<String> accountEntryId,
      Value<String> tagId,
      Value<int> rowid,
    });

final class $$AccountEntryTagsTableReferences
    extends
        BaseReferences<_$AppDatabase, $AccountEntryTagsTable, AccountEntryTag> {
  $$AccountEntryTagsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $AccountEntriesTable _accountEntryIdTable(_$AppDatabase db) => db
      .accountEntries
      .createAlias('account_entry_tags__account_entry_id__account_entries__id');

  $$AccountEntriesTableProcessedTableManager get accountEntryId {
    final $_column = $_itemColumn<String>('account_entry_id')!;

    final manager = $$AccountEntriesTableTableManager(
      $_db,
      $_db.accountEntries,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountEntryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $TagsTable _tagIdTable(_$AppDatabase db) =>
      db.tags.createAlias('account_entry_tags__tag_id__tags__id');

  $$TagsTableProcessedTableManager get tagId {
    final $_column = $_itemColumn<String>('tag_id')!;

    final manager = $$TagsTableTableManager(
      $_db,
      $_db.tags,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_tagIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AccountEntryTagsTableFilterComposer
    extends Composer<_$AppDatabase, $AccountEntryTagsTable> {
  $$AccountEntryTagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$AccountEntriesTableFilterComposer get accountEntryId {
    final $$AccountEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountEntryId,
      referencedTable: $db.accountEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountEntriesTableFilterComposer(
            $db: $db,
            $table: $db.accountEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagsTableFilterComposer get tagId {
    final $$TagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableFilterComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AccountEntryTagsTableOrderingComposer
    extends Composer<_$AppDatabase, $AccountEntryTagsTable> {
  $$AccountEntryTagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$AccountEntriesTableOrderingComposer get accountEntryId {
    final $$AccountEntriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountEntryId,
      referencedTable: $db.accountEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountEntriesTableOrderingComposer(
            $db: $db,
            $table: $db.accountEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagsTableOrderingComposer get tagId {
    final $$TagsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableOrderingComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AccountEntryTagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AccountEntryTagsTable> {
  $$AccountEntryTagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$AccountEntriesTableAnnotationComposer get accountEntryId {
    final $$AccountEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountEntryId,
      referencedTable: $db.accountEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.accountEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagsTableAnnotationComposer get tagId {
    final $$TagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableAnnotationComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AccountEntryTagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AccountEntryTagsTable,
          AccountEntryTag,
          $$AccountEntryTagsTableFilterComposer,
          $$AccountEntryTagsTableOrderingComposer,
          $$AccountEntryTagsTableAnnotationComposer,
          $$AccountEntryTagsTableCreateCompanionBuilder,
          $$AccountEntryTagsTableUpdateCompanionBuilder,
          (AccountEntryTag, $$AccountEntryTagsTableReferences),
          AccountEntryTag,
          PrefetchHooks Function({bool accountEntryId, bool tagId})
        > {
  $$AccountEntryTagsTableTableManager(
    _$AppDatabase db,
    $AccountEntryTagsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AccountEntryTagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AccountEntryTagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AccountEntryTagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> accountEntryId = const Value.absent(),
                Value<String> tagId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AccountEntryTagsCompanion(
                accountEntryId: accountEntryId,
                tagId: tagId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String accountEntryId,
                required String tagId,
                Value<int> rowid = const Value.absent(),
              }) => AccountEntryTagsCompanion.insert(
                accountEntryId: accountEntryId,
                tagId: tagId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AccountEntryTagsTable, AccountEntryTag>(table),
                  $$AccountEntryTagsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({accountEntryId = false, tagId = false}) {
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
                    if (accountEntryId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.accountEntryId,
                        referencedTable: $$AccountEntryTagsTableReferences
                            ._accountEntryIdTable(db),
                        referencedColumn: $$AccountEntryTagsTableReferences
                            ._accountEntryIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (tagId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.tagId,
                        referencedTable: $$AccountEntryTagsTableReferences
                            ._tagIdTable(db),
                        referencedColumn: $$AccountEntryTagsTableReferences
                            ._tagIdTable(db)
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

typedef $$AccountEntryTagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AccountEntryTagsTable,
      AccountEntryTag,
      $$AccountEntryTagsTableFilterComposer,
      $$AccountEntryTagsTableOrderingComposer,
      $$AccountEntryTagsTableAnnotationComposer,
      $$AccountEntryTagsTableCreateCompanionBuilder,
      $$AccountEntryTagsTableUpdateCompanionBuilder,
      (AccountEntryTag, $$AccountEntryTagsTableReferences),
      AccountEntryTag,
      PrefetchHooks Function({bool accountEntryId, bool tagId})
    >;
typedef $$StagedImportsTableCreateCompanionBuilder =
    StagedImportsCompanion Function({
      required String id,
      required String rawText,
      required String fingerprint,
      Value<int> retentionStatus,
      Value<DateTime?> retentionUntil,
      Value<DateTime?> lastDecisionAt,
      required int source,
      required String sourceKey,
      required DateTime importedAt,
      required String adapterVersion,
      required int status,
      Value<int> rowid,
    });
typedef $$StagedImportsTableUpdateCompanionBuilder =
    StagedImportsCompanion Function({
      Value<String> id,
      Value<String> rawText,
      Value<String> fingerprint,
      Value<int> retentionStatus,
      Value<DateTime?> retentionUntil,
      Value<DateTime?> lastDecisionAt,
      Value<int> source,
      Value<String> sourceKey,
      Value<DateTime> importedAt,
      Value<String> adapterVersion,
      Value<int> status,
      Value<int> rowid,
    });

final class $$StagedImportsTableReferences
    extends BaseReferences<_$AppDatabase, $StagedImportsTable, StagedImport> {
  $$StagedImportsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$InboxSuggestionsTable, List<InboxSuggestion>>
  _inboxSuggestionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.inboxSuggestions,
    aliasName: 'staged_imports__id__inbox_suggestions__staged_import_id',
  );

  $$InboxSuggestionsTableProcessedTableManager get inboxSuggestionsRefs {
    final manager = $$InboxSuggestionsTableTableManager(
      $_db,
      $_db.inboxSuggestions,
    ).filter((f) => f.stagedImportId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _inboxSuggestionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$StagedImportsTableFilterComposer
    extends Composer<_$AppDatabase, $StagedImportsTable> {
  $$StagedImportsTableFilterComposer({
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

  ColumnFilters<String> get rawText => $composableBuilder(
    column: $table.rawText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fingerprint => $composableBuilder(
    column: $table.fingerprint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retentionStatus => $composableBuilder(
    column: $table.retentionStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get retentionUntil => $composableBuilder(
    column: $table.retentionUntil,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastDecisionAt => $composableBuilder(
    column: $table.lastDecisionAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceKey => $composableBuilder(
    column: $table.sourceKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get adapterVersion => $composableBuilder(
    column: $table.adapterVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> inboxSuggestionsRefs(
    Expression<bool> Function($$InboxSuggestionsTableFilterComposer f) f,
  ) {
    final $$InboxSuggestionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.inboxSuggestions,
      getReferencedColumn: (t) => t.stagedImportId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InboxSuggestionsTableFilterComposer(
            $db: $db,
            $table: $db.inboxSuggestions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$StagedImportsTableOrderingComposer
    extends Composer<_$AppDatabase, $StagedImportsTable> {
  $$StagedImportsTableOrderingComposer({
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

  ColumnOrderings<String> get rawText => $composableBuilder(
    column: $table.rawText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fingerprint => $composableBuilder(
    column: $table.fingerprint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retentionStatus => $composableBuilder(
    column: $table.retentionStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get retentionUntil => $composableBuilder(
    column: $table.retentionUntil,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastDecisionAt => $composableBuilder(
    column: $table.lastDecisionAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceKey => $composableBuilder(
    column: $table.sourceKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get adapterVersion => $composableBuilder(
    column: $table.adapterVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StagedImportsTableAnnotationComposer
    extends Composer<_$AppDatabase, $StagedImportsTable> {
  $$StagedImportsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get rawText =>
      $composableBuilder(column: $table.rawText, builder: (column) => column);

  GeneratedColumn<String> get fingerprint => $composableBuilder(
    column: $table.fingerprint,
    builder: (column) => column,
  );

  GeneratedColumn<int> get retentionStatus => $composableBuilder(
    column: $table.retentionStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get retentionUntil => $composableBuilder(
    column: $table.retentionUntil,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastDecisionAt => $composableBuilder(
    column: $table.lastDecisionAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get sourceKey =>
      $composableBuilder(column: $table.sourceKey, builder: (column) => column);

  GeneratedColumn<DateTime> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get adapterVersion => $composableBuilder(
    column: $table.adapterVersion,
    builder: (column) => column,
  );

  GeneratedColumn<int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  Expression<T> inboxSuggestionsRefs<T extends Object>(
    Expression<T> Function($$InboxSuggestionsTableAnnotationComposer a) f,
  ) {
    final $$InboxSuggestionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.inboxSuggestions,
      getReferencedColumn: (t) => t.stagedImportId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InboxSuggestionsTableAnnotationComposer(
            $db: $db,
            $table: $db.inboxSuggestions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$StagedImportsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StagedImportsTable,
          StagedImport,
          $$StagedImportsTableFilterComposer,
          $$StagedImportsTableOrderingComposer,
          $$StagedImportsTableAnnotationComposer,
          $$StagedImportsTableCreateCompanionBuilder,
          $$StagedImportsTableUpdateCompanionBuilder,
          (StagedImport, $$StagedImportsTableReferences),
          StagedImport,
          PrefetchHooks Function({bool inboxSuggestionsRefs})
        > {
  $$StagedImportsTableTableManager(_$AppDatabase db, $StagedImportsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StagedImportsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StagedImportsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StagedImportsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> rawText = const Value.absent(),
                Value<String> fingerprint = const Value.absent(),
                Value<int> retentionStatus = const Value.absent(),
                Value<DateTime?> retentionUntil = const Value.absent(),
                Value<DateTime?> lastDecisionAt = const Value.absent(),
                Value<int> source = const Value.absent(),
                Value<String> sourceKey = const Value.absent(),
                Value<DateTime> importedAt = const Value.absent(),
                Value<String> adapterVersion = const Value.absent(),
                Value<int> status = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StagedImportsCompanion(
                id: id,
                rawText: rawText,
                fingerprint: fingerprint,
                retentionStatus: retentionStatus,
                retentionUntil: retentionUntil,
                lastDecisionAt: lastDecisionAt,
                source: source,
                sourceKey: sourceKey,
                importedAt: importedAt,
                adapterVersion: adapterVersion,
                status: status,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String rawText,
                required String fingerprint,
                Value<int> retentionStatus = const Value.absent(),
                Value<DateTime?> retentionUntil = const Value.absent(),
                Value<DateTime?> lastDecisionAt = const Value.absent(),
                required int source,
                required String sourceKey,
                required DateTime importedAt,
                required String adapterVersion,
                required int status,
                Value<int> rowid = const Value.absent(),
              }) => StagedImportsCompanion.insert(
                id: id,
                rawText: rawText,
                fingerprint: fingerprint,
                retentionStatus: retentionStatus,
                retentionUntil: retentionUntil,
                lastDecisionAt: lastDecisionAt,
                source: source,
                sourceKey: sourceKey,
                importedAt: importedAt,
                adapterVersion: adapterVersion,
                status: status,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$StagedImportsTable, StagedImport>(table),
                  $$StagedImportsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({inboxSuggestionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (inboxSuggestionsRefs) db.inboxSuggestions,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (inboxSuggestionsRefs)
                    await $_getPrefetchedData<
                      StagedImport,
                      $StagedImportsTable,
                      InboxSuggestion
                    >(
                      currentTable: table,
                      referencedTable: $$StagedImportsTableReferences
                          ._inboxSuggestionsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$StagedImportsTableReferences(
                            db,
                            table,
                            p0,
                          ).inboxSuggestionsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.stagedImportId == item.id,
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

typedef $$StagedImportsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StagedImportsTable,
      StagedImport,
      $$StagedImportsTableFilterComposer,
      $$StagedImportsTableOrderingComposer,
      $$StagedImportsTableAnnotationComposer,
      $$StagedImportsTableCreateCompanionBuilder,
      $$StagedImportsTableUpdateCompanionBuilder,
      (StagedImport, $$StagedImportsTableReferences),
      StagedImport,
      PrefetchHooks Function({bool inboxSuggestionsRefs})
    >;
typedef $$InboxSuggestionsTableCreateCompanionBuilder =
    InboxSuggestionsCompanion Function({
      required String id,
      required String stagedImportId,
      required String draftId,
      required int minorUnits,
      required String currency,
      required DateTime occurredAt,
      required String type,
      Value<String?> merchant,
      Value<String?> reference,
      required int status,
      Value<int> rowid,
    });
typedef $$InboxSuggestionsTableUpdateCompanionBuilder =
    InboxSuggestionsCompanion Function({
      Value<String> id,
      Value<String> stagedImportId,
      Value<String> draftId,
      Value<int> minorUnits,
      Value<String> currency,
      Value<DateTime> occurredAt,
      Value<String> type,
      Value<String?> merchant,
      Value<String?> reference,
      Value<int> status,
      Value<int> rowid,
    });

final class $$InboxSuggestionsTableReferences
    extends
        BaseReferences<_$AppDatabase, $InboxSuggestionsTable, InboxSuggestion> {
  $$InboxSuggestionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $StagedImportsTable _stagedImportIdTable(_$AppDatabase db) => db
      .stagedImports
      .createAlias('inbox_suggestions__staged_import_id__staged_imports__id');

  $$StagedImportsTableProcessedTableManager get stagedImportId {
    final $_column = $_itemColumn<String>('staged_import_id')!;

    final manager = $$StagedImportsTableTableManager(
      $_db,
      $_db.stagedImports,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_stagedImportIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$InboxSuggestionsTableFilterComposer
    extends Composer<_$AppDatabase, $InboxSuggestionsTable> {
  $$InboxSuggestionsTableFilterComposer({
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

  ColumnFilters<String> get draftId => $composableBuilder(
    column: $table.draftId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get minorUnits => $composableBuilder(
    column: $table.minorUnits,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get merchant => $composableBuilder(
    column: $table.merchant,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reference => $composableBuilder(
    column: $table.reference,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  $$StagedImportsTableFilterComposer get stagedImportId {
    final $$StagedImportsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.stagedImportId,
      referencedTable: $db.stagedImports,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StagedImportsTableFilterComposer(
            $db: $db,
            $table: $db.stagedImports,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InboxSuggestionsTableOrderingComposer
    extends Composer<_$AppDatabase, $InboxSuggestionsTable> {
  $$InboxSuggestionsTableOrderingComposer({
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

  ColumnOrderings<String> get draftId => $composableBuilder(
    column: $table.draftId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get minorUnits => $composableBuilder(
    column: $table.minorUnits,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get merchant => $composableBuilder(
    column: $table.merchant,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reference => $composableBuilder(
    column: $table.reference,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  $$StagedImportsTableOrderingComposer get stagedImportId {
    final $$StagedImportsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.stagedImportId,
      referencedTable: $db.stagedImports,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StagedImportsTableOrderingComposer(
            $db: $db,
            $table: $db.stagedImports,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InboxSuggestionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $InboxSuggestionsTable> {
  $$InboxSuggestionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get draftId =>
      $composableBuilder(column: $table.draftId, builder: (column) => column);

  GeneratedColumn<int> get minorUnits => $composableBuilder(
    column: $table.minorUnits,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get merchant =>
      $composableBuilder(column: $table.merchant, builder: (column) => column);

  GeneratedColumn<String> get reference =>
      $composableBuilder(column: $table.reference, builder: (column) => column);

  GeneratedColumn<int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  $$StagedImportsTableAnnotationComposer get stagedImportId {
    final $$StagedImportsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.stagedImportId,
      referencedTable: $db.stagedImports,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StagedImportsTableAnnotationComposer(
            $db: $db,
            $table: $db.stagedImports,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InboxSuggestionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InboxSuggestionsTable,
          InboxSuggestion,
          $$InboxSuggestionsTableFilterComposer,
          $$InboxSuggestionsTableOrderingComposer,
          $$InboxSuggestionsTableAnnotationComposer,
          $$InboxSuggestionsTableCreateCompanionBuilder,
          $$InboxSuggestionsTableUpdateCompanionBuilder,
          (InboxSuggestion, $$InboxSuggestionsTableReferences),
          InboxSuggestion,
          PrefetchHooks Function({bool stagedImportId})
        > {
  $$InboxSuggestionsTableTableManager(
    _$AppDatabase db,
    $InboxSuggestionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InboxSuggestionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InboxSuggestionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InboxSuggestionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> stagedImportId = const Value.absent(),
                Value<String> draftId = const Value.absent(),
                Value<int> minorUnits = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<DateTime> occurredAt = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> merchant = const Value.absent(),
                Value<String?> reference = const Value.absent(),
                Value<int> status = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InboxSuggestionsCompanion(
                id: id,
                stagedImportId: stagedImportId,
                draftId: draftId,
                minorUnits: minorUnits,
                currency: currency,
                occurredAt: occurredAt,
                type: type,
                merchant: merchant,
                reference: reference,
                status: status,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String stagedImportId,
                required String draftId,
                required int minorUnits,
                required String currency,
                required DateTime occurredAt,
                required String type,
                Value<String?> merchant = const Value.absent(),
                Value<String?> reference = const Value.absent(),
                required int status,
                Value<int> rowid = const Value.absent(),
              }) => InboxSuggestionsCompanion.insert(
                id: id,
                stagedImportId: stagedImportId,
                draftId: draftId,
                minorUnits: minorUnits,
                currency: currency,
                occurredAt: occurredAt,
                type: type,
                merchant: merchant,
                reference: reference,
                status: status,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$InboxSuggestionsTable, InboxSuggestion>(table),
                  $$InboxSuggestionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({stagedImportId = false}) {
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
                    if (stagedImportId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.stagedImportId,
                        referencedTable: $$InboxSuggestionsTableReferences
                            ._stagedImportIdTable(db),
                        referencedColumn: $$InboxSuggestionsTableReferences
                            ._stagedImportIdTable(db)
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

typedef $$InboxSuggestionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InboxSuggestionsTable,
      InboxSuggestion,
      $$InboxSuggestionsTableFilterComposer,
      $$InboxSuggestionsTableOrderingComposer,
      $$InboxSuggestionsTableAnnotationComposer,
      $$InboxSuggestionsTableCreateCompanionBuilder,
      $$InboxSuggestionsTableUpdateCompanionBuilder,
      (InboxSuggestion, $$InboxSuggestionsTableReferences),
      InboxSuggestion,
      PrefetchHooks Function({bool stagedImportId})
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
  $$ReminderRulesTableTableManager get reminderRules =>
      $$ReminderRulesTableTableManager(_db, _db.reminderRules);
  $$ReminderInstancesTableTableManager get reminderInstances =>
      $$ReminderInstancesTableTableManager(_db, _db.reminderInstances);
  $$ActualsTableTableManager get actuals =>
      $$ActualsTableTableManager(_db, _db.actuals);
  $$EvidencesTableTableManager get evidences =>
      $$EvidencesTableTableManager(_db, _db.evidences);
  $$FinancialAccountsTableTableManager get financialAccounts =>
      $$FinancialAccountsTableTableManager(_db, _db.financialAccounts);
  $$AccountEntriesTableTableManager get accountEntries =>
      $$AccountEntriesTableTableManager(_db, _db.accountEntries);
  $$TransactionMatchesTableTableManager get transactionMatches =>
      $$TransactionMatchesTableTableManager(_db, _db.transactionMatches);
  $$MatchAllocationsTableTableManager get matchAllocations =>
      $$MatchAllocationsTableTableManager(_db, _db.matchAllocations);
  $$RelationshipReviewsTableTableManager get relationshipReviews =>
      $$RelationshipReviewsTableTableManager(_db, _db.relationshipReviews);
  $$FinancialExpectationsTableTableManager get financialExpectations =>
      $$FinancialExpectationsTableTableManager(_db, _db.financialExpectations);
  $$TagsTableTableManager get tags => $$TagsTableTableManager(_db, _db.tags);
  $$CommitmentTagsTableTableManager get commitmentTags =>
      $$CommitmentTagsTableTableManager(_db, _db.commitmentTags);
  $$AccountEntryTagsTableTableManager get accountEntryTags =>
      $$AccountEntryTagsTableTableManager(_db, _db.accountEntryTags);
  $$StagedImportsTableTableManager get stagedImports =>
      $$StagedImportsTableTableManager(_db, _db.stagedImports);
  $$InboxSuggestionsTableTableManager get inboxSuggestions =>
      $$InboxSuggestionsTableTableManager(_db, _db.inboxSuggestions);
}
