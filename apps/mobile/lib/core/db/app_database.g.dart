// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $RebuildSetsTable extends RebuildSets
    with TableInfo<$RebuildSetsTable, RebuildSetRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RebuildSetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _setItemIdMeta = const VerificationMeta(
    'setItemId',
  );
  @override
  late final GeneratedColumn<int> setItemId = GeneratedColumn<int>(
    'set_item_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _themeMeta = const VerificationMeta('theme');
  @override
  late final GeneratedColumn<String> theme = GeneratedColumn<String>(
    'theme',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
    'year',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imageUrlMeta = const VerificationMeta(
    'imageUrl',
  );
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
    'image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalPartsMeta = const VerificationMeta(
    'totalParts',
  );
  @override
  late final GeneratedColumn<int> totalParts = GeneratedColumn<int>(
    'total_parts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _verifiedAtMeta = const VerificationMeta(
    'verifiedAt',
  );
  @override
  late final GeneratedColumn<DateTime> verifiedAt = GeneratedColumn<DateTime>(
    'verified_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _dirtyMeta = const VerificationMeta('dirty');
  @override
  late final GeneratedColumn<bool> dirty = GeneratedColumn<bool>(
    'dirty',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("dirty" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    setItemId,
    name,
    theme,
    year,
    imageUrl,
    totalParts,
    verifiedAt,
    createdAt,
    updatedAt,
    dirty,
    deleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rebuild_sets';
  @override
  VerificationContext validateIntegrity(
    Insertable<RebuildSetRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('set_item_id')) {
      context.handle(
        _setItemIdMeta,
        setItemId.isAcceptableOrUnknown(data['set_item_id']!, _setItemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_setItemIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('theme')) {
      context.handle(
        _themeMeta,
        theme.isAcceptableOrUnknown(data['theme']!, _themeMeta),
      );
    }
    if (data.containsKey('year')) {
      context.handle(
        _yearMeta,
        year.isAcceptableOrUnknown(data['year']!, _yearMeta),
      );
    }
    if (data.containsKey('image_url')) {
      context.handle(
        _imageUrlMeta,
        imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta),
      );
    }
    if (data.containsKey('total_parts')) {
      context.handle(
        _totalPartsMeta,
        totalParts.isAcceptableOrUnknown(data['total_parts']!, _totalPartsMeta),
      );
    }
    if (data.containsKey('verified_at')) {
      context.handle(
        _verifiedAtMeta,
        verifiedAt.isAcceptableOrUnknown(data['verified_at']!, _verifiedAtMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('dirty')) {
      context.handle(
        _dirtyMeta,
        dirty.isAcceptableOrUnknown(data['dirty']!, _dirtyMeta),
      );
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RebuildSetRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RebuildSetRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      setItemId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}set_item_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      theme: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}theme'],
      ),
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}year'],
      ),
      imageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_url'],
      ),
      totalParts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_parts'],
      )!,
      verifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}verified_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      dirty: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}dirty'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
    );
  }

  @override
  $RebuildSetsTable createAlias(String alias) {
    return $RebuildSetsTable(attachedDatabase, alias);
  }
}

class RebuildSetRow extends DataClass implements Insertable<RebuildSetRow> {
  final String id;
  final int setItemId;
  final String name;
  final String? theme;
  final int? year;
  final String? imageUrl;
  final int totalParts;
  final DateTime? verifiedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool dirty;
  final bool deleted;
  const RebuildSetRow({
    required this.id,
    required this.setItemId,
    required this.name,
    this.theme,
    this.year,
    this.imageUrl,
    required this.totalParts,
    this.verifiedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.dirty,
    required this.deleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['set_item_id'] = Variable<int>(setItemId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || theme != null) {
      map['theme'] = Variable<String>(theme);
    }
    if (!nullToAbsent || year != null) {
      map['year'] = Variable<int>(year);
    }
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    map['total_parts'] = Variable<int>(totalParts);
    if (!nullToAbsent || verifiedAt != null) {
      map['verified_at'] = Variable<DateTime>(verifiedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['dirty'] = Variable<bool>(dirty);
    map['deleted'] = Variable<bool>(deleted);
    return map;
  }

  RebuildSetsCompanion toCompanion(bool nullToAbsent) {
    return RebuildSetsCompanion(
      id: Value(id),
      setItemId: Value(setItemId),
      name: Value(name),
      theme: theme == null && nullToAbsent
          ? const Value.absent()
          : Value(theme),
      year: year == null && nullToAbsent ? const Value.absent() : Value(year),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
      totalParts: Value(totalParts),
      verifiedAt: verifiedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(verifiedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      dirty: Value(dirty),
      deleted: Value(deleted),
    );
  }

  factory RebuildSetRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RebuildSetRow(
      id: serializer.fromJson<String>(json['id']),
      setItemId: serializer.fromJson<int>(json['setItemId']),
      name: serializer.fromJson<String>(json['name']),
      theme: serializer.fromJson<String?>(json['theme']),
      year: serializer.fromJson<int?>(json['year']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
      totalParts: serializer.fromJson<int>(json['totalParts']),
      verifiedAt: serializer.fromJson<DateTime?>(json['verifiedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      dirty: serializer.fromJson<bool>(json['dirty']),
      deleted: serializer.fromJson<bool>(json['deleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'setItemId': serializer.toJson<int>(setItemId),
      'name': serializer.toJson<String>(name),
      'theme': serializer.toJson<String?>(theme),
      'year': serializer.toJson<int?>(year),
      'imageUrl': serializer.toJson<String?>(imageUrl),
      'totalParts': serializer.toJson<int>(totalParts),
      'verifiedAt': serializer.toJson<DateTime?>(verifiedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'dirty': serializer.toJson<bool>(dirty),
      'deleted': serializer.toJson<bool>(deleted),
    };
  }

  RebuildSetRow copyWith({
    String? id,
    int? setItemId,
    String? name,
    Value<String?> theme = const Value.absent(),
    Value<int?> year = const Value.absent(),
    Value<String?> imageUrl = const Value.absent(),
    int? totalParts,
    Value<DateTime?> verifiedAt = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? dirty,
    bool? deleted,
  }) => RebuildSetRow(
    id: id ?? this.id,
    setItemId: setItemId ?? this.setItemId,
    name: name ?? this.name,
    theme: theme.present ? theme.value : this.theme,
    year: year.present ? year.value : this.year,
    imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
    totalParts: totalParts ?? this.totalParts,
    verifiedAt: verifiedAt.present ? verifiedAt.value : this.verifiedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    dirty: dirty ?? this.dirty,
    deleted: deleted ?? this.deleted,
  );
  RebuildSetRow copyWithCompanion(RebuildSetsCompanion data) {
    return RebuildSetRow(
      id: data.id.present ? data.id.value : this.id,
      setItemId: data.setItemId.present ? data.setItemId.value : this.setItemId,
      name: data.name.present ? data.name.value : this.name,
      theme: data.theme.present ? data.theme.value : this.theme,
      year: data.year.present ? data.year.value : this.year,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      totalParts: data.totalParts.present
          ? data.totalParts.value
          : this.totalParts,
      verifiedAt: data.verifiedAt.present
          ? data.verifiedAt.value
          : this.verifiedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      dirty: data.dirty.present ? data.dirty.value : this.dirty,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RebuildSetRow(')
          ..write('id: $id, ')
          ..write('setItemId: $setItemId, ')
          ..write('name: $name, ')
          ..write('theme: $theme, ')
          ..write('year: $year, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('totalParts: $totalParts, ')
          ..write('verifiedAt: $verifiedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('dirty: $dirty, ')
          ..write('deleted: $deleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    setItemId,
    name,
    theme,
    year,
    imageUrl,
    totalParts,
    verifiedAt,
    createdAt,
    updatedAt,
    dirty,
    deleted,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RebuildSetRow &&
          other.id == this.id &&
          other.setItemId == this.setItemId &&
          other.name == this.name &&
          other.theme == this.theme &&
          other.year == this.year &&
          other.imageUrl == this.imageUrl &&
          other.totalParts == this.totalParts &&
          other.verifiedAt == this.verifiedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.dirty == this.dirty &&
          other.deleted == this.deleted);
}

class RebuildSetsCompanion extends UpdateCompanion<RebuildSetRow> {
  final Value<String> id;
  final Value<int> setItemId;
  final Value<String> name;
  final Value<String?> theme;
  final Value<int?> year;
  final Value<String?> imageUrl;
  final Value<int> totalParts;
  final Value<DateTime?> verifiedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<bool> dirty;
  final Value<bool> deleted;
  final Value<int> rowid;
  const RebuildSetsCompanion({
    this.id = const Value.absent(),
    this.setItemId = const Value.absent(),
    this.name = const Value.absent(),
    this.theme = const Value.absent(),
    this.year = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.totalParts = const Value.absent(),
    this.verifiedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.dirty = const Value.absent(),
    this.deleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RebuildSetsCompanion.insert({
    required String id,
    required int setItemId,
    this.name = const Value.absent(),
    this.theme = const Value.absent(),
    this.year = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.totalParts = const Value.absent(),
    this.verifiedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.dirty = const Value.absent(),
    this.deleted = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       setItemId = Value(setItemId);
  static Insertable<RebuildSetRow> custom({
    Expression<String>? id,
    Expression<int>? setItemId,
    Expression<String>? name,
    Expression<String>? theme,
    Expression<int>? year,
    Expression<String>? imageUrl,
    Expression<int>? totalParts,
    Expression<DateTime>? verifiedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? dirty,
    Expression<bool>? deleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (setItemId != null) 'set_item_id': setItemId,
      if (name != null) 'name': name,
      if (theme != null) 'theme': theme,
      if (year != null) 'year': year,
      if (imageUrl != null) 'image_url': imageUrl,
      if (totalParts != null) 'total_parts': totalParts,
      if (verifiedAt != null) 'verified_at': verifiedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (dirty != null) 'dirty': dirty,
      if (deleted != null) 'deleted': deleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RebuildSetsCompanion copyWith({
    Value<String>? id,
    Value<int>? setItemId,
    Value<String>? name,
    Value<String?>? theme,
    Value<int?>? year,
    Value<String?>? imageUrl,
    Value<int>? totalParts,
    Value<DateTime?>? verifiedAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<bool>? dirty,
    Value<bool>? deleted,
    Value<int>? rowid,
  }) {
    return RebuildSetsCompanion(
      id: id ?? this.id,
      setItemId: setItemId ?? this.setItemId,
      name: name ?? this.name,
      theme: theme ?? this.theme,
      year: year ?? this.year,
      imageUrl: imageUrl ?? this.imageUrl,
      totalParts: totalParts ?? this.totalParts,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      dirty: dirty ?? this.dirty,
      deleted: deleted ?? this.deleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (setItemId.present) {
      map['set_item_id'] = Variable<int>(setItemId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (theme.present) {
      map['theme'] = Variable<String>(theme.value);
    }
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (totalParts.present) {
      map['total_parts'] = Variable<int>(totalParts.value);
    }
    if (verifiedAt.present) {
      map['verified_at'] = Variable<DateTime>(verifiedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (dirty.present) {
      map['dirty'] = Variable<bool>(dirty.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RebuildSetsCompanion(')
          ..write('id: $id, ')
          ..write('setItemId: $setItemId, ')
          ..write('name: $name, ')
          ..write('theme: $theme, ')
          ..write('year: $year, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('totalParts: $totalParts, ')
          ..write('verifiedAt: $verifiedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('dirty: $dirty, ')
          ..write('deleted: $deleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RebuildPartsTable extends RebuildParts
    with TableInfo<$RebuildPartsTable, RebuildPartRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RebuildPartsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _rebuildSetIdMeta = const VerificationMeta(
    'rebuildSetId',
  );
  @override
  late final GeneratedColumn<String> rebuildSetId = GeneratedColumn<String>(
    'rebuild_set_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _partItemIdMeta = const VerificationMeta(
    'partItemId',
  );
  @override
  late final GeneratedColumn<int> partItemId = GeneratedColumn<int>(
    'part_item_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorIdMeta = const VerificationMeta(
    'colorId',
  );
  @override
  late final GeneratedColumn<int> colorId = GeneratedColumn<int>(
    'color_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _neededQtyMeta = const VerificationMeta(
    'neededQty',
  );
  @override
  late final GeneratedColumn<int> neededQty = GeneratedColumn<int>(
    'needed_qty',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _haveQtyMeta = const VerificationMeta(
    'haveQty',
  );
  @override
  late final GeneratedColumn<int> haveQty = GeneratedColumn<int>(
    'have_qty',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _partNameMeta = const VerificationMeta(
    'partName',
  );
  @override
  late final GeneratedColumn<String> partName = GeneratedColumn<String>(
    'part_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _partNumMeta = const VerificationMeta(
    'partNum',
  );
  @override
  late final GeneratedColumn<String> partNum = GeneratedColumn<String>(
    'part_num',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _partCatIdMeta = const VerificationMeta(
    'partCatId',
  );
  @override
  late final GeneratedColumn<int> partCatId = GeneratedColumn<int>(
    'part_cat_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryNameMeta = const VerificationMeta(
    'categoryName',
  );
  @override
  late final GeneratedColumn<String> categoryName = GeneratedColumn<String>(
    'category_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorNameMeta = const VerificationMeta(
    'colorName',
  );
  @override
  late final GeneratedColumn<String> colorName = GeneratedColumn<String>(
    'color_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorRgbMeta = const VerificationMeta(
    'colorRgb',
  );
  @override
  late final GeneratedColumn<String> colorRgb = GeneratedColumn<String>(
    'color_rgb',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imageUrlMeta = const VerificationMeta(
    'imageUrl',
  );
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
    'image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _blPartIdMeta = const VerificationMeta(
    'blPartId',
  );
  @override
  late final GeneratedColumn<String> blPartId = GeneratedColumn<String>(
    'bl_part_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _blColorIdMeta = const VerificationMeta(
    'blColorId',
  );
  @override
  late final GeneratedColumn<int> blColorId = GeneratedColumn<int>(
    'bl_color_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _dirtyMeta = const VerificationMeta('dirty');
  @override
  late final GeneratedColumn<bool> dirty = GeneratedColumn<bool>(
    'dirty',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("dirty" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    rebuildSetId,
    partItemId,
    colorId,
    neededQty,
    haveQty,
    partName,
    partNum,
    partCatId,
    categoryName,
    colorName,
    colorRgb,
    imageUrl,
    blPartId,
    blColorId,
    updatedAt,
    dirty,
    deleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rebuild_parts';
  @override
  VerificationContext validateIntegrity(
    Insertable<RebuildPartRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('rebuild_set_id')) {
      context.handle(
        _rebuildSetIdMeta,
        rebuildSetId.isAcceptableOrUnknown(
          data['rebuild_set_id']!,
          _rebuildSetIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_rebuildSetIdMeta);
    }
    if (data.containsKey('part_item_id')) {
      context.handle(
        _partItemIdMeta,
        partItemId.isAcceptableOrUnknown(
          data['part_item_id']!,
          _partItemIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_partItemIdMeta);
    }
    if (data.containsKey('color_id')) {
      context.handle(
        _colorIdMeta,
        colorId.isAcceptableOrUnknown(data['color_id']!, _colorIdMeta),
      );
    } else if (isInserting) {
      context.missing(_colorIdMeta);
    }
    if (data.containsKey('needed_qty')) {
      context.handle(
        _neededQtyMeta,
        neededQty.isAcceptableOrUnknown(data['needed_qty']!, _neededQtyMeta),
      );
    }
    if (data.containsKey('have_qty')) {
      context.handle(
        _haveQtyMeta,
        haveQty.isAcceptableOrUnknown(data['have_qty']!, _haveQtyMeta),
      );
    }
    if (data.containsKey('part_name')) {
      context.handle(
        _partNameMeta,
        partName.isAcceptableOrUnknown(data['part_name']!, _partNameMeta),
      );
    }
    if (data.containsKey('part_num')) {
      context.handle(
        _partNumMeta,
        partNum.isAcceptableOrUnknown(data['part_num']!, _partNumMeta),
      );
    }
    if (data.containsKey('part_cat_id')) {
      context.handle(
        _partCatIdMeta,
        partCatId.isAcceptableOrUnknown(data['part_cat_id']!, _partCatIdMeta),
      );
    }
    if (data.containsKey('category_name')) {
      context.handle(
        _categoryNameMeta,
        categoryName.isAcceptableOrUnknown(
          data['category_name']!,
          _categoryNameMeta,
        ),
      );
    }
    if (data.containsKey('color_name')) {
      context.handle(
        _colorNameMeta,
        colorName.isAcceptableOrUnknown(data['color_name']!, _colorNameMeta),
      );
    }
    if (data.containsKey('color_rgb')) {
      context.handle(
        _colorRgbMeta,
        colorRgb.isAcceptableOrUnknown(data['color_rgb']!, _colorRgbMeta),
      );
    }
    if (data.containsKey('image_url')) {
      context.handle(
        _imageUrlMeta,
        imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta),
      );
    }
    if (data.containsKey('bl_part_id')) {
      context.handle(
        _blPartIdMeta,
        blPartId.isAcceptableOrUnknown(data['bl_part_id']!, _blPartIdMeta),
      );
    }
    if (data.containsKey('bl_color_id')) {
      context.handle(
        _blColorIdMeta,
        blColorId.isAcceptableOrUnknown(data['bl_color_id']!, _blColorIdMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('dirty')) {
      context.handle(
        _dirtyMeta,
        dirty.isAcceptableOrUnknown(data['dirty']!, _dirtyMeta),
      );
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {rebuildSetId, partItemId, colorId};
  @override
  RebuildPartRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RebuildPartRow(
      rebuildSetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rebuild_set_id'],
      )!,
      partItemId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}part_item_id'],
      )!,
      colorId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color_id'],
      )!,
      neededQty: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}needed_qty'],
      )!,
      haveQty: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}have_qty'],
      )!,
      partName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}part_name'],
      )!,
      partNum: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}part_num'],
      ),
      partCatId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}part_cat_id'],
      ),
      categoryName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_name'],
      ),
      colorName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color_name'],
      ),
      colorRgb: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color_rgb'],
      ),
      imageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_url'],
      ),
      blPartId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bl_part_id'],
      ),
      blColorId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bl_color_id'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      dirty: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}dirty'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
    );
  }

  @override
  $RebuildPartsTable createAlias(String alias) {
    return $RebuildPartsTable(attachedDatabase, alias);
  }
}

class RebuildPartRow extends DataClass implements Insertable<RebuildPartRow> {
  final String rebuildSetId;
  final int partItemId;
  final int colorId;
  final int neededQty;
  final int haveQty;
  final String partName;
  final String? partNum;
  final int? partCatId;
  final String? categoryName;
  final String? colorName;
  final String? colorRgb;
  final String? imageUrl;
  final String? blPartId;
  final int? blColorId;
  final DateTime updatedAt;
  final bool dirty;
  final bool deleted;
  const RebuildPartRow({
    required this.rebuildSetId,
    required this.partItemId,
    required this.colorId,
    required this.neededQty,
    required this.haveQty,
    required this.partName,
    this.partNum,
    this.partCatId,
    this.categoryName,
    this.colorName,
    this.colorRgb,
    this.imageUrl,
    this.blPartId,
    this.blColorId,
    required this.updatedAt,
    required this.dirty,
    required this.deleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['rebuild_set_id'] = Variable<String>(rebuildSetId);
    map['part_item_id'] = Variable<int>(partItemId);
    map['color_id'] = Variable<int>(colorId);
    map['needed_qty'] = Variable<int>(neededQty);
    map['have_qty'] = Variable<int>(haveQty);
    map['part_name'] = Variable<String>(partName);
    if (!nullToAbsent || partNum != null) {
      map['part_num'] = Variable<String>(partNum);
    }
    if (!nullToAbsent || partCatId != null) {
      map['part_cat_id'] = Variable<int>(partCatId);
    }
    if (!nullToAbsent || categoryName != null) {
      map['category_name'] = Variable<String>(categoryName);
    }
    if (!nullToAbsent || colorName != null) {
      map['color_name'] = Variable<String>(colorName);
    }
    if (!nullToAbsent || colorRgb != null) {
      map['color_rgb'] = Variable<String>(colorRgb);
    }
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    if (!nullToAbsent || blPartId != null) {
      map['bl_part_id'] = Variable<String>(blPartId);
    }
    if (!nullToAbsent || blColorId != null) {
      map['bl_color_id'] = Variable<int>(blColorId);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['dirty'] = Variable<bool>(dirty);
    map['deleted'] = Variable<bool>(deleted);
    return map;
  }

  RebuildPartsCompanion toCompanion(bool nullToAbsent) {
    return RebuildPartsCompanion(
      rebuildSetId: Value(rebuildSetId),
      partItemId: Value(partItemId),
      colorId: Value(colorId),
      neededQty: Value(neededQty),
      haveQty: Value(haveQty),
      partName: Value(partName),
      partNum: partNum == null && nullToAbsent
          ? const Value.absent()
          : Value(partNum),
      partCatId: partCatId == null && nullToAbsent
          ? const Value.absent()
          : Value(partCatId),
      categoryName: categoryName == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryName),
      colorName: colorName == null && nullToAbsent
          ? const Value.absent()
          : Value(colorName),
      colorRgb: colorRgb == null && nullToAbsent
          ? const Value.absent()
          : Value(colorRgb),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
      blPartId: blPartId == null && nullToAbsent
          ? const Value.absent()
          : Value(blPartId),
      blColorId: blColorId == null && nullToAbsent
          ? const Value.absent()
          : Value(blColorId),
      updatedAt: Value(updatedAt),
      dirty: Value(dirty),
      deleted: Value(deleted),
    );
  }

  factory RebuildPartRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RebuildPartRow(
      rebuildSetId: serializer.fromJson<String>(json['rebuildSetId']),
      partItemId: serializer.fromJson<int>(json['partItemId']),
      colorId: serializer.fromJson<int>(json['colorId']),
      neededQty: serializer.fromJson<int>(json['neededQty']),
      haveQty: serializer.fromJson<int>(json['haveQty']),
      partName: serializer.fromJson<String>(json['partName']),
      partNum: serializer.fromJson<String?>(json['partNum']),
      partCatId: serializer.fromJson<int?>(json['partCatId']),
      categoryName: serializer.fromJson<String?>(json['categoryName']),
      colorName: serializer.fromJson<String?>(json['colorName']),
      colorRgb: serializer.fromJson<String?>(json['colorRgb']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
      blPartId: serializer.fromJson<String?>(json['blPartId']),
      blColorId: serializer.fromJson<int?>(json['blColorId']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      dirty: serializer.fromJson<bool>(json['dirty']),
      deleted: serializer.fromJson<bool>(json['deleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'rebuildSetId': serializer.toJson<String>(rebuildSetId),
      'partItemId': serializer.toJson<int>(partItemId),
      'colorId': serializer.toJson<int>(colorId),
      'neededQty': serializer.toJson<int>(neededQty),
      'haveQty': serializer.toJson<int>(haveQty),
      'partName': serializer.toJson<String>(partName),
      'partNum': serializer.toJson<String?>(partNum),
      'partCatId': serializer.toJson<int?>(partCatId),
      'categoryName': serializer.toJson<String?>(categoryName),
      'colorName': serializer.toJson<String?>(colorName),
      'colorRgb': serializer.toJson<String?>(colorRgb),
      'imageUrl': serializer.toJson<String?>(imageUrl),
      'blPartId': serializer.toJson<String?>(blPartId),
      'blColorId': serializer.toJson<int?>(blColorId),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'dirty': serializer.toJson<bool>(dirty),
      'deleted': serializer.toJson<bool>(deleted),
    };
  }

  RebuildPartRow copyWith({
    String? rebuildSetId,
    int? partItemId,
    int? colorId,
    int? neededQty,
    int? haveQty,
    String? partName,
    Value<String?> partNum = const Value.absent(),
    Value<int?> partCatId = const Value.absent(),
    Value<String?> categoryName = const Value.absent(),
    Value<String?> colorName = const Value.absent(),
    Value<String?> colorRgb = const Value.absent(),
    Value<String?> imageUrl = const Value.absent(),
    Value<String?> blPartId = const Value.absent(),
    Value<int?> blColorId = const Value.absent(),
    DateTime? updatedAt,
    bool? dirty,
    bool? deleted,
  }) => RebuildPartRow(
    rebuildSetId: rebuildSetId ?? this.rebuildSetId,
    partItemId: partItemId ?? this.partItemId,
    colorId: colorId ?? this.colorId,
    neededQty: neededQty ?? this.neededQty,
    haveQty: haveQty ?? this.haveQty,
    partName: partName ?? this.partName,
    partNum: partNum.present ? partNum.value : this.partNum,
    partCatId: partCatId.present ? partCatId.value : this.partCatId,
    categoryName: categoryName.present ? categoryName.value : this.categoryName,
    colorName: colorName.present ? colorName.value : this.colorName,
    colorRgb: colorRgb.present ? colorRgb.value : this.colorRgb,
    imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
    blPartId: blPartId.present ? blPartId.value : this.blPartId,
    blColorId: blColorId.present ? blColorId.value : this.blColorId,
    updatedAt: updatedAt ?? this.updatedAt,
    dirty: dirty ?? this.dirty,
    deleted: deleted ?? this.deleted,
  );
  RebuildPartRow copyWithCompanion(RebuildPartsCompanion data) {
    return RebuildPartRow(
      rebuildSetId: data.rebuildSetId.present
          ? data.rebuildSetId.value
          : this.rebuildSetId,
      partItemId: data.partItemId.present
          ? data.partItemId.value
          : this.partItemId,
      colorId: data.colorId.present ? data.colorId.value : this.colorId,
      neededQty: data.neededQty.present ? data.neededQty.value : this.neededQty,
      haveQty: data.haveQty.present ? data.haveQty.value : this.haveQty,
      partName: data.partName.present ? data.partName.value : this.partName,
      partNum: data.partNum.present ? data.partNum.value : this.partNum,
      partCatId: data.partCatId.present ? data.partCatId.value : this.partCatId,
      categoryName: data.categoryName.present
          ? data.categoryName.value
          : this.categoryName,
      colorName: data.colorName.present ? data.colorName.value : this.colorName,
      colorRgb: data.colorRgb.present ? data.colorRgb.value : this.colorRgb,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      blPartId: data.blPartId.present ? data.blPartId.value : this.blPartId,
      blColorId: data.blColorId.present ? data.blColorId.value : this.blColorId,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      dirty: data.dirty.present ? data.dirty.value : this.dirty,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RebuildPartRow(')
          ..write('rebuildSetId: $rebuildSetId, ')
          ..write('partItemId: $partItemId, ')
          ..write('colorId: $colorId, ')
          ..write('neededQty: $neededQty, ')
          ..write('haveQty: $haveQty, ')
          ..write('partName: $partName, ')
          ..write('partNum: $partNum, ')
          ..write('partCatId: $partCatId, ')
          ..write('categoryName: $categoryName, ')
          ..write('colorName: $colorName, ')
          ..write('colorRgb: $colorRgb, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('blPartId: $blPartId, ')
          ..write('blColorId: $blColorId, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('dirty: $dirty, ')
          ..write('deleted: $deleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    rebuildSetId,
    partItemId,
    colorId,
    neededQty,
    haveQty,
    partName,
    partNum,
    partCatId,
    categoryName,
    colorName,
    colorRgb,
    imageUrl,
    blPartId,
    blColorId,
    updatedAt,
    dirty,
    deleted,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RebuildPartRow &&
          other.rebuildSetId == this.rebuildSetId &&
          other.partItemId == this.partItemId &&
          other.colorId == this.colorId &&
          other.neededQty == this.neededQty &&
          other.haveQty == this.haveQty &&
          other.partName == this.partName &&
          other.partNum == this.partNum &&
          other.partCatId == this.partCatId &&
          other.categoryName == this.categoryName &&
          other.colorName == this.colorName &&
          other.colorRgb == this.colorRgb &&
          other.imageUrl == this.imageUrl &&
          other.blPartId == this.blPartId &&
          other.blColorId == this.blColorId &&
          other.updatedAt == this.updatedAt &&
          other.dirty == this.dirty &&
          other.deleted == this.deleted);
}

class RebuildPartsCompanion extends UpdateCompanion<RebuildPartRow> {
  final Value<String> rebuildSetId;
  final Value<int> partItemId;
  final Value<int> colorId;
  final Value<int> neededQty;
  final Value<int> haveQty;
  final Value<String> partName;
  final Value<String?> partNum;
  final Value<int?> partCatId;
  final Value<String?> categoryName;
  final Value<String?> colorName;
  final Value<String?> colorRgb;
  final Value<String?> imageUrl;
  final Value<String?> blPartId;
  final Value<int?> blColorId;
  final Value<DateTime> updatedAt;
  final Value<bool> dirty;
  final Value<bool> deleted;
  final Value<int> rowid;
  const RebuildPartsCompanion({
    this.rebuildSetId = const Value.absent(),
    this.partItemId = const Value.absent(),
    this.colorId = const Value.absent(),
    this.neededQty = const Value.absent(),
    this.haveQty = const Value.absent(),
    this.partName = const Value.absent(),
    this.partNum = const Value.absent(),
    this.partCatId = const Value.absent(),
    this.categoryName = const Value.absent(),
    this.colorName = const Value.absent(),
    this.colorRgb = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.blPartId = const Value.absent(),
    this.blColorId = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.dirty = const Value.absent(),
    this.deleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RebuildPartsCompanion.insert({
    required String rebuildSetId,
    required int partItemId,
    required int colorId,
    this.neededQty = const Value.absent(),
    this.haveQty = const Value.absent(),
    this.partName = const Value.absent(),
    this.partNum = const Value.absent(),
    this.partCatId = const Value.absent(),
    this.categoryName = const Value.absent(),
    this.colorName = const Value.absent(),
    this.colorRgb = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.blPartId = const Value.absent(),
    this.blColorId = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.dirty = const Value.absent(),
    this.deleted = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : rebuildSetId = Value(rebuildSetId),
       partItemId = Value(partItemId),
       colorId = Value(colorId);
  static Insertable<RebuildPartRow> custom({
    Expression<String>? rebuildSetId,
    Expression<int>? partItemId,
    Expression<int>? colorId,
    Expression<int>? neededQty,
    Expression<int>? haveQty,
    Expression<String>? partName,
    Expression<String>? partNum,
    Expression<int>? partCatId,
    Expression<String>? categoryName,
    Expression<String>? colorName,
    Expression<String>? colorRgb,
    Expression<String>? imageUrl,
    Expression<String>? blPartId,
    Expression<int>? blColorId,
    Expression<DateTime>? updatedAt,
    Expression<bool>? dirty,
    Expression<bool>? deleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (rebuildSetId != null) 'rebuild_set_id': rebuildSetId,
      if (partItemId != null) 'part_item_id': partItemId,
      if (colorId != null) 'color_id': colorId,
      if (neededQty != null) 'needed_qty': neededQty,
      if (haveQty != null) 'have_qty': haveQty,
      if (partName != null) 'part_name': partName,
      if (partNum != null) 'part_num': partNum,
      if (partCatId != null) 'part_cat_id': partCatId,
      if (categoryName != null) 'category_name': categoryName,
      if (colorName != null) 'color_name': colorName,
      if (colorRgb != null) 'color_rgb': colorRgb,
      if (imageUrl != null) 'image_url': imageUrl,
      if (blPartId != null) 'bl_part_id': blPartId,
      if (blColorId != null) 'bl_color_id': blColorId,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (dirty != null) 'dirty': dirty,
      if (deleted != null) 'deleted': deleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RebuildPartsCompanion copyWith({
    Value<String>? rebuildSetId,
    Value<int>? partItemId,
    Value<int>? colorId,
    Value<int>? neededQty,
    Value<int>? haveQty,
    Value<String>? partName,
    Value<String?>? partNum,
    Value<int?>? partCatId,
    Value<String?>? categoryName,
    Value<String?>? colorName,
    Value<String?>? colorRgb,
    Value<String?>? imageUrl,
    Value<String?>? blPartId,
    Value<int?>? blColorId,
    Value<DateTime>? updatedAt,
    Value<bool>? dirty,
    Value<bool>? deleted,
    Value<int>? rowid,
  }) {
    return RebuildPartsCompanion(
      rebuildSetId: rebuildSetId ?? this.rebuildSetId,
      partItemId: partItemId ?? this.partItemId,
      colorId: colorId ?? this.colorId,
      neededQty: neededQty ?? this.neededQty,
      haveQty: haveQty ?? this.haveQty,
      partName: partName ?? this.partName,
      partNum: partNum ?? this.partNum,
      partCatId: partCatId ?? this.partCatId,
      categoryName: categoryName ?? this.categoryName,
      colorName: colorName ?? this.colorName,
      colorRgb: colorRgb ?? this.colorRgb,
      imageUrl: imageUrl ?? this.imageUrl,
      blPartId: blPartId ?? this.blPartId,
      blColorId: blColorId ?? this.blColorId,
      updatedAt: updatedAt ?? this.updatedAt,
      dirty: dirty ?? this.dirty,
      deleted: deleted ?? this.deleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (rebuildSetId.present) {
      map['rebuild_set_id'] = Variable<String>(rebuildSetId.value);
    }
    if (partItemId.present) {
      map['part_item_id'] = Variable<int>(partItemId.value);
    }
    if (colorId.present) {
      map['color_id'] = Variable<int>(colorId.value);
    }
    if (neededQty.present) {
      map['needed_qty'] = Variable<int>(neededQty.value);
    }
    if (haveQty.present) {
      map['have_qty'] = Variable<int>(haveQty.value);
    }
    if (partName.present) {
      map['part_name'] = Variable<String>(partName.value);
    }
    if (partNum.present) {
      map['part_num'] = Variable<String>(partNum.value);
    }
    if (partCatId.present) {
      map['part_cat_id'] = Variable<int>(partCatId.value);
    }
    if (categoryName.present) {
      map['category_name'] = Variable<String>(categoryName.value);
    }
    if (colorName.present) {
      map['color_name'] = Variable<String>(colorName.value);
    }
    if (colorRgb.present) {
      map['color_rgb'] = Variable<String>(colorRgb.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (blPartId.present) {
      map['bl_part_id'] = Variable<String>(blPartId.value);
    }
    if (blColorId.present) {
      map['bl_color_id'] = Variable<int>(blColorId.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (dirty.present) {
      map['dirty'] = Variable<bool>(dirty.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RebuildPartsCompanion(')
          ..write('rebuildSetId: $rebuildSetId, ')
          ..write('partItemId: $partItemId, ')
          ..write('colorId: $colorId, ')
          ..write('neededQty: $neededQty, ')
          ..write('haveQty: $haveQty, ')
          ..write('partName: $partName, ')
          ..write('partNum: $partNum, ')
          ..write('partCatId: $partCatId, ')
          ..write('categoryName: $categoryName, ')
          ..write('colorName: $colorName, ')
          ..write('colorRgb: $colorRgb, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('blPartId: $blPartId, ')
          ..write('blColorId: $blColorId, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('dirty: $dirty, ')
          ..write('deleted: $deleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RebuildMinifigsTable extends RebuildMinifigs
    with TableInfo<$RebuildMinifigsTable, RebuildMinifigRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RebuildMinifigsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _rebuildSetIdMeta = const VerificationMeta(
    'rebuildSetId',
  );
  @override
  late final GeneratedColumn<String> rebuildSetId = GeneratedColumn<String>(
    'rebuild_set_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _minifigItemIdMeta = const VerificationMeta(
    'minifigItemId',
  );
  @override
  late final GeneratedColumn<int> minifigItemId = GeneratedColumn<int>(
    'minifig_item_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _neededQtyMeta = const VerificationMeta(
    'neededQty',
  );
  @override
  late final GeneratedColumn<int> neededQty = GeneratedColumn<int>(
    'needed_qty',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _haveQtyMeta = const VerificationMeta(
    'haveQty',
  );
  @override
  late final GeneratedColumn<int> haveQty = GeneratedColumn<int>(
    'have_qty',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _imageUrlMeta = const VerificationMeta(
    'imageUrl',
  );
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
    'image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _dirtyMeta = const VerificationMeta('dirty');
  @override
  late final GeneratedColumn<bool> dirty = GeneratedColumn<bool>(
    'dirty',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("dirty" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    rebuildSetId,
    minifigItemId,
    neededQty,
    haveQty,
    name,
    imageUrl,
    updatedAt,
    dirty,
    deleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rebuild_minifigs';
  @override
  VerificationContext validateIntegrity(
    Insertable<RebuildMinifigRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('rebuild_set_id')) {
      context.handle(
        _rebuildSetIdMeta,
        rebuildSetId.isAcceptableOrUnknown(
          data['rebuild_set_id']!,
          _rebuildSetIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_rebuildSetIdMeta);
    }
    if (data.containsKey('minifig_item_id')) {
      context.handle(
        _minifigItemIdMeta,
        minifigItemId.isAcceptableOrUnknown(
          data['minifig_item_id']!,
          _minifigItemIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_minifigItemIdMeta);
    }
    if (data.containsKey('needed_qty')) {
      context.handle(
        _neededQtyMeta,
        neededQty.isAcceptableOrUnknown(data['needed_qty']!, _neededQtyMeta),
      );
    }
    if (data.containsKey('have_qty')) {
      context.handle(
        _haveQtyMeta,
        haveQty.isAcceptableOrUnknown(data['have_qty']!, _haveQtyMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('image_url')) {
      context.handle(
        _imageUrlMeta,
        imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('dirty')) {
      context.handle(
        _dirtyMeta,
        dirty.isAcceptableOrUnknown(data['dirty']!, _dirtyMeta),
      );
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {rebuildSetId, minifigItemId};
  @override
  RebuildMinifigRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RebuildMinifigRow(
      rebuildSetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rebuild_set_id'],
      )!,
      minifigItemId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}minifig_item_id'],
      )!,
      neededQty: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}needed_qty'],
      )!,
      haveQty: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}have_qty'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      imageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_url'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      dirty: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}dirty'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
    );
  }

  @override
  $RebuildMinifigsTable createAlias(String alias) {
    return $RebuildMinifigsTable(attachedDatabase, alias);
  }
}

class RebuildMinifigRow extends DataClass
    implements Insertable<RebuildMinifigRow> {
  final String rebuildSetId;
  final int minifigItemId;
  final int neededQty;
  final int haveQty;
  final String name;
  final String? imageUrl;
  final DateTime updatedAt;
  final bool dirty;
  final bool deleted;
  const RebuildMinifigRow({
    required this.rebuildSetId,
    required this.minifigItemId,
    required this.neededQty,
    required this.haveQty,
    required this.name,
    this.imageUrl,
    required this.updatedAt,
    required this.dirty,
    required this.deleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['rebuild_set_id'] = Variable<String>(rebuildSetId);
    map['minifig_item_id'] = Variable<int>(minifigItemId);
    map['needed_qty'] = Variable<int>(neededQty);
    map['have_qty'] = Variable<int>(haveQty);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['dirty'] = Variable<bool>(dirty);
    map['deleted'] = Variable<bool>(deleted);
    return map;
  }

  RebuildMinifigsCompanion toCompanion(bool nullToAbsent) {
    return RebuildMinifigsCompanion(
      rebuildSetId: Value(rebuildSetId),
      minifigItemId: Value(minifigItemId),
      neededQty: Value(neededQty),
      haveQty: Value(haveQty),
      name: Value(name),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
      updatedAt: Value(updatedAt),
      dirty: Value(dirty),
      deleted: Value(deleted),
    );
  }

  factory RebuildMinifigRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RebuildMinifigRow(
      rebuildSetId: serializer.fromJson<String>(json['rebuildSetId']),
      minifigItemId: serializer.fromJson<int>(json['minifigItemId']),
      neededQty: serializer.fromJson<int>(json['neededQty']),
      haveQty: serializer.fromJson<int>(json['haveQty']),
      name: serializer.fromJson<String>(json['name']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      dirty: serializer.fromJson<bool>(json['dirty']),
      deleted: serializer.fromJson<bool>(json['deleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'rebuildSetId': serializer.toJson<String>(rebuildSetId),
      'minifigItemId': serializer.toJson<int>(minifigItemId),
      'neededQty': serializer.toJson<int>(neededQty),
      'haveQty': serializer.toJson<int>(haveQty),
      'name': serializer.toJson<String>(name),
      'imageUrl': serializer.toJson<String?>(imageUrl),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'dirty': serializer.toJson<bool>(dirty),
      'deleted': serializer.toJson<bool>(deleted),
    };
  }

  RebuildMinifigRow copyWith({
    String? rebuildSetId,
    int? minifigItemId,
    int? neededQty,
    int? haveQty,
    String? name,
    Value<String?> imageUrl = const Value.absent(),
    DateTime? updatedAt,
    bool? dirty,
    bool? deleted,
  }) => RebuildMinifigRow(
    rebuildSetId: rebuildSetId ?? this.rebuildSetId,
    minifigItemId: minifigItemId ?? this.minifigItemId,
    neededQty: neededQty ?? this.neededQty,
    haveQty: haveQty ?? this.haveQty,
    name: name ?? this.name,
    imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
    updatedAt: updatedAt ?? this.updatedAt,
    dirty: dirty ?? this.dirty,
    deleted: deleted ?? this.deleted,
  );
  RebuildMinifigRow copyWithCompanion(RebuildMinifigsCompanion data) {
    return RebuildMinifigRow(
      rebuildSetId: data.rebuildSetId.present
          ? data.rebuildSetId.value
          : this.rebuildSetId,
      minifigItemId: data.minifigItemId.present
          ? data.minifigItemId.value
          : this.minifigItemId,
      neededQty: data.neededQty.present ? data.neededQty.value : this.neededQty,
      haveQty: data.haveQty.present ? data.haveQty.value : this.haveQty,
      name: data.name.present ? data.name.value : this.name,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      dirty: data.dirty.present ? data.dirty.value : this.dirty,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RebuildMinifigRow(')
          ..write('rebuildSetId: $rebuildSetId, ')
          ..write('minifigItemId: $minifigItemId, ')
          ..write('neededQty: $neededQty, ')
          ..write('haveQty: $haveQty, ')
          ..write('name: $name, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('dirty: $dirty, ')
          ..write('deleted: $deleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    rebuildSetId,
    minifigItemId,
    neededQty,
    haveQty,
    name,
    imageUrl,
    updatedAt,
    dirty,
    deleted,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RebuildMinifigRow &&
          other.rebuildSetId == this.rebuildSetId &&
          other.minifigItemId == this.minifigItemId &&
          other.neededQty == this.neededQty &&
          other.haveQty == this.haveQty &&
          other.name == this.name &&
          other.imageUrl == this.imageUrl &&
          other.updatedAt == this.updatedAt &&
          other.dirty == this.dirty &&
          other.deleted == this.deleted);
}

class RebuildMinifigsCompanion extends UpdateCompanion<RebuildMinifigRow> {
  final Value<String> rebuildSetId;
  final Value<int> minifigItemId;
  final Value<int> neededQty;
  final Value<int> haveQty;
  final Value<String> name;
  final Value<String?> imageUrl;
  final Value<DateTime> updatedAt;
  final Value<bool> dirty;
  final Value<bool> deleted;
  final Value<int> rowid;
  const RebuildMinifigsCompanion({
    this.rebuildSetId = const Value.absent(),
    this.minifigItemId = const Value.absent(),
    this.neededQty = const Value.absent(),
    this.haveQty = const Value.absent(),
    this.name = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.dirty = const Value.absent(),
    this.deleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RebuildMinifigsCompanion.insert({
    required String rebuildSetId,
    required int minifigItemId,
    this.neededQty = const Value.absent(),
    this.haveQty = const Value.absent(),
    this.name = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.dirty = const Value.absent(),
    this.deleted = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : rebuildSetId = Value(rebuildSetId),
       minifigItemId = Value(minifigItemId);
  static Insertable<RebuildMinifigRow> custom({
    Expression<String>? rebuildSetId,
    Expression<int>? minifigItemId,
    Expression<int>? neededQty,
    Expression<int>? haveQty,
    Expression<String>? name,
    Expression<String>? imageUrl,
    Expression<DateTime>? updatedAt,
    Expression<bool>? dirty,
    Expression<bool>? deleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (rebuildSetId != null) 'rebuild_set_id': rebuildSetId,
      if (minifigItemId != null) 'minifig_item_id': minifigItemId,
      if (neededQty != null) 'needed_qty': neededQty,
      if (haveQty != null) 'have_qty': haveQty,
      if (name != null) 'name': name,
      if (imageUrl != null) 'image_url': imageUrl,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (dirty != null) 'dirty': dirty,
      if (deleted != null) 'deleted': deleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RebuildMinifigsCompanion copyWith({
    Value<String>? rebuildSetId,
    Value<int>? minifigItemId,
    Value<int>? neededQty,
    Value<int>? haveQty,
    Value<String>? name,
    Value<String?>? imageUrl,
    Value<DateTime>? updatedAt,
    Value<bool>? dirty,
    Value<bool>? deleted,
    Value<int>? rowid,
  }) {
    return RebuildMinifigsCompanion(
      rebuildSetId: rebuildSetId ?? this.rebuildSetId,
      minifigItemId: minifigItemId ?? this.minifigItemId,
      neededQty: neededQty ?? this.neededQty,
      haveQty: haveQty ?? this.haveQty,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      updatedAt: updatedAt ?? this.updatedAt,
      dirty: dirty ?? this.dirty,
      deleted: deleted ?? this.deleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (rebuildSetId.present) {
      map['rebuild_set_id'] = Variable<String>(rebuildSetId.value);
    }
    if (minifigItemId.present) {
      map['minifig_item_id'] = Variable<int>(minifigItemId.value);
    }
    if (neededQty.present) {
      map['needed_qty'] = Variable<int>(neededQty.value);
    }
    if (haveQty.present) {
      map['have_qty'] = Variable<int>(haveQty.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (dirty.present) {
      map['dirty'] = Variable<bool>(dirty.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RebuildMinifigsCompanion(')
          ..write('rebuildSetId: $rebuildSetId, ')
          ..write('minifigItemId: $minifigItemId, ')
          ..write('neededQty: $neededQty, ')
          ..write('haveQty: $haveQty, ')
          ..write('name: $name, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('dirty: $dirty, ')
          ..write('deleted: $deleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VerificationsTable extends Verifications
    with TableInfo<$VerificationsTable, VerificationRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VerificationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rebuildSetIdMeta = const VerificationMeta(
    'rebuildSetId',
  );
  @override
  late final GeneratedColumn<String> rebuildSetId = GeneratedColumn<String>(
    'rebuild_set_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _setItemIdMeta = const VerificationMeta(
    'setItemId',
  );
  @override
  late final GeneratedColumn<int> setItemId = GeneratedColumn<int>(
    'set_item_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completionPctMeta = const VerificationMeta(
    'completionPct',
  );
  @override
  late final GeneratedColumn<double> completionPct = GeneratedColumn<double>(
    'completion_pct',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _partsNeededMeta = const VerificationMeta(
    'partsNeeded',
  );
  @override
  late final GeneratedColumn<int> partsNeeded = GeneratedColumn<int>(
    'parts_needed',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _partsFoundMeta = const VerificationMeta(
    'partsFound',
  );
  @override
  late final GeneratedColumn<int> partsFound = GeneratedColumn<int>(
    'parts_found',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _minifigsNeededMeta = const VerificationMeta(
    'minifigsNeeded',
  );
  @override
  late final GeneratedColumn<int> minifigsNeeded = GeneratedColumn<int>(
    'minifigs_needed',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _minifigsFoundMeta = const VerificationMeta(
    'minifigsFound',
  );
  @override
  late final GeneratedColumn<int> minifigsFound = GeneratedColumn<int>(
    'minifigs_found',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _flagsMeta = const VerificationMeta('flags');
  @override
  late final GeneratedColumn<String> flags = GeneratedColumn<String>(
    'flags',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _verifiedAtMeta = const VerificationMeta(
    'verifiedAt',
  );
  @override
  late final GeneratedColumn<DateTime> verifiedAt = GeneratedColumn<DateTime>(
    'verified_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _dirtyMeta = const VerificationMeta('dirty');
  @override
  late final GeneratedColumn<bool> dirty = GeneratedColumn<bool>(
    'dirty',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("dirty" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    rebuildSetId,
    setItemId,
    completionPct,
    partsNeeded,
    partsFound,
    minifigsNeeded,
    minifigsFound,
    flags,
    notes,
    verifiedAt,
    updatedAt,
    dirty,
    deleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'verifications';
  @override
  VerificationContext validateIntegrity(
    Insertable<VerificationRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('rebuild_set_id')) {
      context.handle(
        _rebuildSetIdMeta,
        rebuildSetId.isAcceptableOrUnknown(
          data['rebuild_set_id']!,
          _rebuildSetIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_rebuildSetIdMeta);
    }
    if (data.containsKey('set_item_id')) {
      context.handle(
        _setItemIdMeta,
        setItemId.isAcceptableOrUnknown(data['set_item_id']!, _setItemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_setItemIdMeta);
    }
    if (data.containsKey('completion_pct')) {
      context.handle(
        _completionPctMeta,
        completionPct.isAcceptableOrUnknown(
          data['completion_pct']!,
          _completionPctMeta,
        ),
      );
    }
    if (data.containsKey('parts_needed')) {
      context.handle(
        _partsNeededMeta,
        partsNeeded.isAcceptableOrUnknown(
          data['parts_needed']!,
          _partsNeededMeta,
        ),
      );
    }
    if (data.containsKey('parts_found')) {
      context.handle(
        _partsFoundMeta,
        partsFound.isAcceptableOrUnknown(data['parts_found']!, _partsFoundMeta),
      );
    }
    if (data.containsKey('minifigs_needed')) {
      context.handle(
        _minifigsNeededMeta,
        minifigsNeeded.isAcceptableOrUnknown(
          data['minifigs_needed']!,
          _minifigsNeededMeta,
        ),
      );
    }
    if (data.containsKey('minifigs_found')) {
      context.handle(
        _minifigsFoundMeta,
        minifigsFound.isAcceptableOrUnknown(
          data['minifigs_found']!,
          _minifigsFoundMeta,
        ),
      );
    }
    if (data.containsKey('flags')) {
      context.handle(
        _flagsMeta,
        flags.isAcceptableOrUnknown(data['flags']!, _flagsMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('verified_at')) {
      context.handle(
        _verifiedAtMeta,
        verifiedAt.isAcceptableOrUnknown(data['verified_at']!, _verifiedAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('dirty')) {
      context.handle(
        _dirtyMeta,
        dirty.isAcceptableOrUnknown(data['dirty']!, _dirtyMeta),
      );
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VerificationRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VerificationRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      rebuildSetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rebuild_set_id'],
      )!,
      setItemId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}set_item_id'],
      )!,
      completionPct: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}completion_pct'],
      )!,
      partsNeeded: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}parts_needed'],
      ),
      partsFound: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}parts_found'],
      ),
      minifigsNeeded: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}minifigs_needed'],
      ),
      minifigsFound: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}minifigs_found'],
      ),
      flags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}flags'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      verifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}verified_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      dirty: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}dirty'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
    );
  }

  @override
  $VerificationsTable createAlias(String alias) {
    return $VerificationsTable(attachedDatabase, alias);
  }
}

class VerificationRow extends DataClass implements Insertable<VerificationRow> {
  final String id;
  final String rebuildSetId;
  final int setItemId;
  final double completionPct;
  final int? partsNeeded;
  final int? partsFound;
  final int? minifigsNeeded;
  final int? minifigsFound;
  final String flags;
  final String? notes;
  final DateTime verifiedAt;
  final DateTime updatedAt;
  final bool dirty;
  final bool deleted;
  const VerificationRow({
    required this.id,
    required this.rebuildSetId,
    required this.setItemId,
    required this.completionPct,
    this.partsNeeded,
    this.partsFound,
    this.minifigsNeeded,
    this.minifigsFound,
    required this.flags,
    this.notes,
    required this.verifiedAt,
    required this.updatedAt,
    required this.dirty,
    required this.deleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['rebuild_set_id'] = Variable<String>(rebuildSetId);
    map['set_item_id'] = Variable<int>(setItemId);
    map['completion_pct'] = Variable<double>(completionPct);
    if (!nullToAbsent || partsNeeded != null) {
      map['parts_needed'] = Variable<int>(partsNeeded);
    }
    if (!nullToAbsent || partsFound != null) {
      map['parts_found'] = Variable<int>(partsFound);
    }
    if (!nullToAbsent || minifigsNeeded != null) {
      map['minifigs_needed'] = Variable<int>(minifigsNeeded);
    }
    if (!nullToAbsent || minifigsFound != null) {
      map['minifigs_found'] = Variable<int>(minifigsFound);
    }
    map['flags'] = Variable<String>(flags);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['verified_at'] = Variable<DateTime>(verifiedAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['dirty'] = Variable<bool>(dirty);
    map['deleted'] = Variable<bool>(deleted);
    return map;
  }

  VerificationsCompanion toCompanion(bool nullToAbsent) {
    return VerificationsCompanion(
      id: Value(id),
      rebuildSetId: Value(rebuildSetId),
      setItemId: Value(setItemId),
      completionPct: Value(completionPct),
      partsNeeded: partsNeeded == null && nullToAbsent
          ? const Value.absent()
          : Value(partsNeeded),
      partsFound: partsFound == null && nullToAbsent
          ? const Value.absent()
          : Value(partsFound),
      minifigsNeeded: minifigsNeeded == null && nullToAbsent
          ? const Value.absent()
          : Value(minifigsNeeded),
      minifigsFound: minifigsFound == null && nullToAbsent
          ? const Value.absent()
          : Value(minifigsFound),
      flags: Value(flags),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      verifiedAt: Value(verifiedAt),
      updatedAt: Value(updatedAt),
      dirty: Value(dirty),
      deleted: Value(deleted),
    );
  }

  factory VerificationRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VerificationRow(
      id: serializer.fromJson<String>(json['id']),
      rebuildSetId: serializer.fromJson<String>(json['rebuildSetId']),
      setItemId: serializer.fromJson<int>(json['setItemId']),
      completionPct: serializer.fromJson<double>(json['completionPct']),
      partsNeeded: serializer.fromJson<int?>(json['partsNeeded']),
      partsFound: serializer.fromJson<int?>(json['partsFound']),
      minifigsNeeded: serializer.fromJson<int?>(json['minifigsNeeded']),
      minifigsFound: serializer.fromJson<int?>(json['minifigsFound']),
      flags: serializer.fromJson<String>(json['flags']),
      notes: serializer.fromJson<String?>(json['notes']),
      verifiedAt: serializer.fromJson<DateTime>(json['verifiedAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      dirty: serializer.fromJson<bool>(json['dirty']),
      deleted: serializer.fromJson<bool>(json['deleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'rebuildSetId': serializer.toJson<String>(rebuildSetId),
      'setItemId': serializer.toJson<int>(setItemId),
      'completionPct': serializer.toJson<double>(completionPct),
      'partsNeeded': serializer.toJson<int?>(partsNeeded),
      'partsFound': serializer.toJson<int?>(partsFound),
      'minifigsNeeded': serializer.toJson<int?>(minifigsNeeded),
      'minifigsFound': serializer.toJson<int?>(minifigsFound),
      'flags': serializer.toJson<String>(flags),
      'notes': serializer.toJson<String?>(notes),
      'verifiedAt': serializer.toJson<DateTime>(verifiedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'dirty': serializer.toJson<bool>(dirty),
      'deleted': serializer.toJson<bool>(deleted),
    };
  }

  VerificationRow copyWith({
    String? id,
    String? rebuildSetId,
    int? setItemId,
    double? completionPct,
    Value<int?> partsNeeded = const Value.absent(),
    Value<int?> partsFound = const Value.absent(),
    Value<int?> minifigsNeeded = const Value.absent(),
    Value<int?> minifigsFound = const Value.absent(),
    String? flags,
    Value<String?> notes = const Value.absent(),
    DateTime? verifiedAt,
    DateTime? updatedAt,
    bool? dirty,
    bool? deleted,
  }) => VerificationRow(
    id: id ?? this.id,
    rebuildSetId: rebuildSetId ?? this.rebuildSetId,
    setItemId: setItemId ?? this.setItemId,
    completionPct: completionPct ?? this.completionPct,
    partsNeeded: partsNeeded.present ? partsNeeded.value : this.partsNeeded,
    partsFound: partsFound.present ? partsFound.value : this.partsFound,
    minifigsNeeded: minifigsNeeded.present
        ? minifigsNeeded.value
        : this.minifigsNeeded,
    minifigsFound: minifigsFound.present
        ? minifigsFound.value
        : this.minifigsFound,
    flags: flags ?? this.flags,
    notes: notes.present ? notes.value : this.notes,
    verifiedAt: verifiedAt ?? this.verifiedAt,
    updatedAt: updatedAt ?? this.updatedAt,
    dirty: dirty ?? this.dirty,
    deleted: deleted ?? this.deleted,
  );
  VerificationRow copyWithCompanion(VerificationsCompanion data) {
    return VerificationRow(
      id: data.id.present ? data.id.value : this.id,
      rebuildSetId: data.rebuildSetId.present
          ? data.rebuildSetId.value
          : this.rebuildSetId,
      setItemId: data.setItemId.present ? data.setItemId.value : this.setItemId,
      completionPct: data.completionPct.present
          ? data.completionPct.value
          : this.completionPct,
      partsNeeded: data.partsNeeded.present
          ? data.partsNeeded.value
          : this.partsNeeded,
      partsFound: data.partsFound.present
          ? data.partsFound.value
          : this.partsFound,
      minifigsNeeded: data.minifigsNeeded.present
          ? data.minifigsNeeded.value
          : this.minifigsNeeded,
      minifigsFound: data.minifigsFound.present
          ? data.minifigsFound.value
          : this.minifigsFound,
      flags: data.flags.present ? data.flags.value : this.flags,
      notes: data.notes.present ? data.notes.value : this.notes,
      verifiedAt: data.verifiedAt.present
          ? data.verifiedAt.value
          : this.verifiedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      dirty: data.dirty.present ? data.dirty.value : this.dirty,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VerificationRow(')
          ..write('id: $id, ')
          ..write('rebuildSetId: $rebuildSetId, ')
          ..write('setItemId: $setItemId, ')
          ..write('completionPct: $completionPct, ')
          ..write('partsNeeded: $partsNeeded, ')
          ..write('partsFound: $partsFound, ')
          ..write('minifigsNeeded: $minifigsNeeded, ')
          ..write('minifigsFound: $minifigsFound, ')
          ..write('flags: $flags, ')
          ..write('notes: $notes, ')
          ..write('verifiedAt: $verifiedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('dirty: $dirty, ')
          ..write('deleted: $deleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    rebuildSetId,
    setItemId,
    completionPct,
    partsNeeded,
    partsFound,
    minifigsNeeded,
    minifigsFound,
    flags,
    notes,
    verifiedAt,
    updatedAt,
    dirty,
    deleted,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VerificationRow &&
          other.id == this.id &&
          other.rebuildSetId == this.rebuildSetId &&
          other.setItemId == this.setItemId &&
          other.completionPct == this.completionPct &&
          other.partsNeeded == this.partsNeeded &&
          other.partsFound == this.partsFound &&
          other.minifigsNeeded == this.minifigsNeeded &&
          other.minifigsFound == this.minifigsFound &&
          other.flags == this.flags &&
          other.notes == this.notes &&
          other.verifiedAt == this.verifiedAt &&
          other.updatedAt == this.updatedAt &&
          other.dirty == this.dirty &&
          other.deleted == this.deleted);
}

class VerificationsCompanion extends UpdateCompanion<VerificationRow> {
  final Value<String> id;
  final Value<String> rebuildSetId;
  final Value<int> setItemId;
  final Value<double> completionPct;
  final Value<int?> partsNeeded;
  final Value<int?> partsFound;
  final Value<int?> minifigsNeeded;
  final Value<int?> minifigsFound;
  final Value<String> flags;
  final Value<String?> notes;
  final Value<DateTime> verifiedAt;
  final Value<DateTime> updatedAt;
  final Value<bool> dirty;
  final Value<bool> deleted;
  final Value<int> rowid;
  const VerificationsCompanion({
    this.id = const Value.absent(),
    this.rebuildSetId = const Value.absent(),
    this.setItemId = const Value.absent(),
    this.completionPct = const Value.absent(),
    this.partsNeeded = const Value.absent(),
    this.partsFound = const Value.absent(),
    this.minifigsNeeded = const Value.absent(),
    this.minifigsFound = const Value.absent(),
    this.flags = const Value.absent(),
    this.notes = const Value.absent(),
    this.verifiedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.dirty = const Value.absent(),
    this.deleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VerificationsCompanion.insert({
    required String id,
    required String rebuildSetId,
    required int setItemId,
    this.completionPct = const Value.absent(),
    this.partsNeeded = const Value.absent(),
    this.partsFound = const Value.absent(),
    this.minifigsNeeded = const Value.absent(),
    this.minifigsFound = const Value.absent(),
    this.flags = const Value.absent(),
    this.notes = const Value.absent(),
    this.verifiedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.dirty = const Value.absent(),
    this.deleted = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       rebuildSetId = Value(rebuildSetId),
       setItemId = Value(setItemId);
  static Insertable<VerificationRow> custom({
    Expression<String>? id,
    Expression<String>? rebuildSetId,
    Expression<int>? setItemId,
    Expression<double>? completionPct,
    Expression<int>? partsNeeded,
    Expression<int>? partsFound,
    Expression<int>? minifigsNeeded,
    Expression<int>? minifigsFound,
    Expression<String>? flags,
    Expression<String>? notes,
    Expression<DateTime>? verifiedAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? dirty,
    Expression<bool>? deleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (rebuildSetId != null) 'rebuild_set_id': rebuildSetId,
      if (setItemId != null) 'set_item_id': setItemId,
      if (completionPct != null) 'completion_pct': completionPct,
      if (partsNeeded != null) 'parts_needed': partsNeeded,
      if (partsFound != null) 'parts_found': partsFound,
      if (minifigsNeeded != null) 'minifigs_needed': minifigsNeeded,
      if (minifigsFound != null) 'minifigs_found': minifigsFound,
      if (flags != null) 'flags': flags,
      if (notes != null) 'notes': notes,
      if (verifiedAt != null) 'verified_at': verifiedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (dirty != null) 'dirty': dirty,
      if (deleted != null) 'deleted': deleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VerificationsCompanion copyWith({
    Value<String>? id,
    Value<String>? rebuildSetId,
    Value<int>? setItemId,
    Value<double>? completionPct,
    Value<int?>? partsNeeded,
    Value<int?>? partsFound,
    Value<int?>? minifigsNeeded,
    Value<int?>? minifigsFound,
    Value<String>? flags,
    Value<String?>? notes,
    Value<DateTime>? verifiedAt,
    Value<DateTime>? updatedAt,
    Value<bool>? dirty,
    Value<bool>? deleted,
    Value<int>? rowid,
  }) {
    return VerificationsCompanion(
      id: id ?? this.id,
      rebuildSetId: rebuildSetId ?? this.rebuildSetId,
      setItemId: setItemId ?? this.setItemId,
      completionPct: completionPct ?? this.completionPct,
      partsNeeded: partsNeeded ?? this.partsNeeded,
      partsFound: partsFound ?? this.partsFound,
      minifigsNeeded: minifigsNeeded ?? this.minifigsNeeded,
      minifigsFound: minifigsFound ?? this.minifigsFound,
      flags: flags ?? this.flags,
      notes: notes ?? this.notes,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      dirty: dirty ?? this.dirty,
      deleted: deleted ?? this.deleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (rebuildSetId.present) {
      map['rebuild_set_id'] = Variable<String>(rebuildSetId.value);
    }
    if (setItemId.present) {
      map['set_item_id'] = Variable<int>(setItemId.value);
    }
    if (completionPct.present) {
      map['completion_pct'] = Variable<double>(completionPct.value);
    }
    if (partsNeeded.present) {
      map['parts_needed'] = Variable<int>(partsNeeded.value);
    }
    if (partsFound.present) {
      map['parts_found'] = Variable<int>(partsFound.value);
    }
    if (minifigsNeeded.present) {
      map['minifigs_needed'] = Variable<int>(minifigsNeeded.value);
    }
    if (minifigsFound.present) {
      map['minifigs_found'] = Variable<int>(minifigsFound.value);
    }
    if (flags.present) {
      map['flags'] = Variable<String>(flags.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (verifiedAt.present) {
      map['verified_at'] = Variable<DateTime>(verifiedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (dirty.present) {
      map['dirty'] = Variable<bool>(dirty.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VerificationsCompanion(')
          ..write('id: $id, ')
          ..write('rebuildSetId: $rebuildSetId, ')
          ..write('setItemId: $setItemId, ')
          ..write('completionPct: $completionPct, ')
          ..write('partsNeeded: $partsNeeded, ')
          ..write('partsFound: $partsFound, ')
          ..write('minifigsNeeded: $minifigsNeeded, ')
          ..write('minifigsFound: $minifigsFound, ')
          ..write('flags: $flags, ')
          ..write('notes: $notes, ')
          ..write('verifiedAt: $verifiedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('dirty: $dirty, ')
          ..write('deleted: $deleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RebuildExtraPartsTable extends RebuildExtraParts
    with TableInfo<$RebuildExtraPartsTable, RebuildExtraPartRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RebuildExtraPartsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _rebuildSetIdMeta = const VerificationMeta(
    'rebuildSetId',
  );
  @override
  late final GeneratedColumn<String> rebuildSetId = GeneratedColumn<String>(
    'rebuild_set_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _partItemIdMeta = const VerificationMeta(
    'partItemId',
  );
  @override
  late final GeneratedColumn<int> partItemId = GeneratedColumn<int>(
    'part_item_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorIdMeta = const VerificationMeta(
    'colorId',
  );
  @override
  late final GeneratedColumn<int> colorId = GeneratedColumn<int>(
    'color_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _neededQtyMeta = const VerificationMeta(
    'neededQty',
  );
  @override
  late final GeneratedColumn<int> neededQty = GeneratedColumn<int>(
    'needed_qty',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _haveQtyMeta = const VerificationMeta(
    'haveQty',
  );
  @override
  late final GeneratedColumn<int> haveQty = GeneratedColumn<int>(
    'have_qty',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _partNameMeta = const VerificationMeta(
    'partName',
  );
  @override
  late final GeneratedColumn<String> partName = GeneratedColumn<String>(
    'part_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _partNumMeta = const VerificationMeta(
    'partNum',
  );
  @override
  late final GeneratedColumn<String> partNum = GeneratedColumn<String>(
    'part_num',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _partCatIdMeta = const VerificationMeta(
    'partCatId',
  );
  @override
  late final GeneratedColumn<int> partCatId = GeneratedColumn<int>(
    'part_cat_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryNameMeta = const VerificationMeta(
    'categoryName',
  );
  @override
  late final GeneratedColumn<String> categoryName = GeneratedColumn<String>(
    'category_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorNameMeta = const VerificationMeta(
    'colorName',
  );
  @override
  late final GeneratedColumn<String> colorName = GeneratedColumn<String>(
    'color_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorRgbMeta = const VerificationMeta(
    'colorRgb',
  );
  @override
  late final GeneratedColumn<String> colorRgb = GeneratedColumn<String>(
    'color_rgb',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imageUrlMeta = const VerificationMeta(
    'imageUrl',
  );
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
    'image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    rebuildSetId,
    partItemId,
    colorId,
    neededQty,
    haveQty,
    partName,
    partNum,
    partCatId,
    categoryName,
    colorName,
    colorRgb,
    imageUrl,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rebuild_extra_parts';
  @override
  VerificationContext validateIntegrity(
    Insertable<RebuildExtraPartRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('rebuild_set_id')) {
      context.handle(
        _rebuildSetIdMeta,
        rebuildSetId.isAcceptableOrUnknown(
          data['rebuild_set_id']!,
          _rebuildSetIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_rebuildSetIdMeta);
    }
    if (data.containsKey('part_item_id')) {
      context.handle(
        _partItemIdMeta,
        partItemId.isAcceptableOrUnknown(
          data['part_item_id']!,
          _partItemIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_partItemIdMeta);
    }
    if (data.containsKey('color_id')) {
      context.handle(
        _colorIdMeta,
        colorId.isAcceptableOrUnknown(data['color_id']!, _colorIdMeta),
      );
    } else if (isInserting) {
      context.missing(_colorIdMeta);
    }
    if (data.containsKey('needed_qty')) {
      context.handle(
        _neededQtyMeta,
        neededQty.isAcceptableOrUnknown(data['needed_qty']!, _neededQtyMeta),
      );
    }
    if (data.containsKey('have_qty')) {
      context.handle(
        _haveQtyMeta,
        haveQty.isAcceptableOrUnknown(data['have_qty']!, _haveQtyMeta),
      );
    }
    if (data.containsKey('part_name')) {
      context.handle(
        _partNameMeta,
        partName.isAcceptableOrUnknown(data['part_name']!, _partNameMeta),
      );
    }
    if (data.containsKey('part_num')) {
      context.handle(
        _partNumMeta,
        partNum.isAcceptableOrUnknown(data['part_num']!, _partNumMeta),
      );
    }
    if (data.containsKey('part_cat_id')) {
      context.handle(
        _partCatIdMeta,
        partCatId.isAcceptableOrUnknown(data['part_cat_id']!, _partCatIdMeta),
      );
    }
    if (data.containsKey('category_name')) {
      context.handle(
        _categoryNameMeta,
        categoryName.isAcceptableOrUnknown(
          data['category_name']!,
          _categoryNameMeta,
        ),
      );
    }
    if (data.containsKey('color_name')) {
      context.handle(
        _colorNameMeta,
        colorName.isAcceptableOrUnknown(data['color_name']!, _colorNameMeta),
      );
    }
    if (data.containsKey('color_rgb')) {
      context.handle(
        _colorRgbMeta,
        colorRgb.isAcceptableOrUnknown(data['color_rgb']!, _colorRgbMeta),
      );
    }
    if (data.containsKey('image_url')) {
      context.handle(
        _imageUrlMeta,
        imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {rebuildSetId, partItemId, colorId};
  @override
  RebuildExtraPartRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RebuildExtraPartRow(
      rebuildSetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rebuild_set_id'],
      )!,
      partItemId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}part_item_id'],
      )!,
      colorId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color_id'],
      )!,
      neededQty: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}needed_qty'],
      )!,
      haveQty: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}have_qty'],
      )!,
      partName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}part_name'],
      )!,
      partNum: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}part_num'],
      ),
      partCatId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}part_cat_id'],
      ),
      categoryName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_name'],
      ),
      colorName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color_name'],
      ),
      colorRgb: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color_rgb'],
      ),
      imageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_url'],
      ),
    );
  }

  @override
  $RebuildExtraPartsTable createAlias(String alias) {
    return $RebuildExtraPartsTable(attachedDatabase, alias);
  }
}

class RebuildExtraPartRow extends DataClass
    implements Insertable<RebuildExtraPartRow> {
  final String rebuildSetId;
  final int partItemId;
  final int colorId;
  final int neededQty;
  final int haveQty;
  final String partName;
  final String? partNum;
  final int? partCatId;
  final String? categoryName;
  final String? colorName;
  final String? colorRgb;
  final String? imageUrl;
  const RebuildExtraPartRow({
    required this.rebuildSetId,
    required this.partItemId,
    required this.colorId,
    required this.neededQty,
    required this.haveQty,
    required this.partName,
    this.partNum,
    this.partCatId,
    this.categoryName,
    this.colorName,
    this.colorRgb,
    this.imageUrl,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['rebuild_set_id'] = Variable<String>(rebuildSetId);
    map['part_item_id'] = Variable<int>(partItemId);
    map['color_id'] = Variable<int>(colorId);
    map['needed_qty'] = Variable<int>(neededQty);
    map['have_qty'] = Variable<int>(haveQty);
    map['part_name'] = Variable<String>(partName);
    if (!nullToAbsent || partNum != null) {
      map['part_num'] = Variable<String>(partNum);
    }
    if (!nullToAbsent || partCatId != null) {
      map['part_cat_id'] = Variable<int>(partCatId);
    }
    if (!nullToAbsent || categoryName != null) {
      map['category_name'] = Variable<String>(categoryName);
    }
    if (!nullToAbsent || colorName != null) {
      map['color_name'] = Variable<String>(colorName);
    }
    if (!nullToAbsent || colorRgb != null) {
      map['color_rgb'] = Variable<String>(colorRgb);
    }
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    return map;
  }

  RebuildExtraPartsCompanion toCompanion(bool nullToAbsent) {
    return RebuildExtraPartsCompanion(
      rebuildSetId: Value(rebuildSetId),
      partItemId: Value(partItemId),
      colorId: Value(colorId),
      neededQty: Value(neededQty),
      haveQty: Value(haveQty),
      partName: Value(partName),
      partNum: partNum == null && nullToAbsent
          ? const Value.absent()
          : Value(partNum),
      partCatId: partCatId == null && nullToAbsent
          ? const Value.absent()
          : Value(partCatId),
      categoryName: categoryName == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryName),
      colorName: colorName == null && nullToAbsent
          ? const Value.absent()
          : Value(colorName),
      colorRgb: colorRgb == null && nullToAbsent
          ? const Value.absent()
          : Value(colorRgb),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
    );
  }

  factory RebuildExtraPartRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RebuildExtraPartRow(
      rebuildSetId: serializer.fromJson<String>(json['rebuildSetId']),
      partItemId: serializer.fromJson<int>(json['partItemId']),
      colorId: serializer.fromJson<int>(json['colorId']),
      neededQty: serializer.fromJson<int>(json['neededQty']),
      haveQty: serializer.fromJson<int>(json['haveQty']),
      partName: serializer.fromJson<String>(json['partName']),
      partNum: serializer.fromJson<String?>(json['partNum']),
      partCatId: serializer.fromJson<int?>(json['partCatId']),
      categoryName: serializer.fromJson<String?>(json['categoryName']),
      colorName: serializer.fromJson<String?>(json['colorName']),
      colorRgb: serializer.fromJson<String?>(json['colorRgb']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'rebuildSetId': serializer.toJson<String>(rebuildSetId),
      'partItemId': serializer.toJson<int>(partItemId),
      'colorId': serializer.toJson<int>(colorId),
      'neededQty': serializer.toJson<int>(neededQty),
      'haveQty': serializer.toJson<int>(haveQty),
      'partName': serializer.toJson<String>(partName),
      'partNum': serializer.toJson<String?>(partNum),
      'partCatId': serializer.toJson<int?>(partCatId),
      'categoryName': serializer.toJson<String?>(categoryName),
      'colorName': serializer.toJson<String?>(colorName),
      'colorRgb': serializer.toJson<String?>(colorRgb),
      'imageUrl': serializer.toJson<String?>(imageUrl),
    };
  }

  RebuildExtraPartRow copyWith({
    String? rebuildSetId,
    int? partItemId,
    int? colorId,
    int? neededQty,
    int? haveQty,
    String? partName,
    Value<String?> partNum = const Value.absent(),
    Value<int?> partCatId = const Value.absent(),
    Value<String?> categoryName = const Value.absent(),
    Value<String?> colorName = const Value.absent(),
    Value<String?> colorRgb = const Value.absent(),
    Value<String?> imageUrl = const Value.absent(),
  }) => RebuildExtraPartRow(
    rebuildSetId: rebuildSetId ?? this.rebuildSetId,
    partItemId: partItemId ?? this.partItemId,
    colorId: colorId ?? this.colorId,
    neededQty: neededQty ?? this.neededQty,
    haveQty: haveQty ?? this.haveQty,
    partName: partName ?? this.partName,
    partNum: partNum.present ? partNum.value : this.partNum,
    partCatId: partCatId.present ? partCatId.value : this.partCatId,
    categoryName: categoryName.present ? categoryName.value : this.categoryName,
    colorName: colorName.present ? colorName.value : this.colorName,
    colorRgb: colorRgb.present ? colorRgb.value : this.colorRgb,
    imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
  );
  RebuildExtraPartRow copyWithCompanion(RebuildExtraPartsCompanion data) {
    return RebuildExtraPartRow(
      rebuildSetId: data.rebuildSetId.present
          ? data.rebuildSetId.value
          : this.rebuildSetId,
      partItemId: data.partItemId.present
          ? data.partItemId.value
          : this.partItemId,
      colorId: data.colorId.present ? data.colorId.value : this.colorId,
      neededQty: data.neededQty.present ? data.neededQty.value : this.neededQty,
      haveQty: data.haveQty.present ? data.haveQty.value : this.haveQty,
      partName: data.partName.present ? data.partName.value : this.partName,
      partNum: data.partNum.present ? data.partNum.value : this.partNum,
      partCatId: data.partCatId.present ? data.partCatId.value : this.partCatId,
      categoryName: data.categoryName.present
          ? data.categoryName.value
          : this.categoryName,
      colorName: data.colorName.present ? data.colorName.value : this.colorName,
      colorRgb: data.colorRgb.present ? data.colorRgb.value : this.colorRgb,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RebuildExtraPartRow(')
          ..write('rebuildSetId: $rebuildSetId, ')
          ..write('partItemId: $partItemId, ')
          ..write('colorId: $colorId, ')
          ..write('neededQty: $neededQty, ')
          ..write('haveQty: $haveQty, ')
          ..write('partName: $partName, ')
          ..write('partNum: $partNum, ')
          ..write('partCatId: $partCatId, ')
          ..write('categoryName: $categoryName, ')
          ..write('colorName: $colorName, ')
          ..write('colorRgb: $colorRgb, ')
          ..write('imageUrl: $imageUrl')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    rebuildSetId,
    partItemId,
    colorId,
    neededQty,
    haveQty,
    partName,
    partNum,
    partCatId,
    categoryName,
    colorName,
    colorRgb,
    imageUrl,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RebuildExtraPartRow &&
          other.rebuildSetId == this.rebuildSetId &&
          other.partItemId == this.partItemId &&
          other.colorId == this.colorId &&
          other.neededQty == this.neededQty &&
          other.haveQty == this.haveQty &&
          other.partName == this.partName &&
          other.partNum == this.partNum &&
          other.partCatId == this.partCatId &&
          other.categoryName == this.categoryName &&
          other.colorName == this.colorName &&
          other.colorRgb == this.colorRgb &&
          other.imageUrl == this.imageUrl);
}

class RebuildExtraPartsCompanion extends UpdateCompanion<RebuildExtraPartRow> {
  final Value<String> rebuildSetId;
  final Value<int> partItemId;
  final Value<int> colorId;
  final Value<int> neededQty;
  final Value<int> haveQty;
  final Value<String> partName;
  final Value<String?> partNum;
  final Value<int?> partCatId;
  final Value<String?> categoryName;
  final Value<String?> colorName;
  final Value<String?> colorRgb;
  final Value<String?> imageUrl;
  final Value<int> rowid;
  const RebuildExtraPartsCompanion({
    this.rebuildSetId = const Value.absent(),
    this.partItemId = const Value.absent(),
    this.colorId = const Value.absent(),
    this.neededQty = const Value.absent(),
    this.haveQty = const Value.absent(),
    this.partName = const Value.absent(),
    this.partNum = const Value.absent(),
    this.partCatId = const Value.absent(),
    this.categoryName = const Value.absent(),
    this.colorName = const Value.absent(),
    this.colorRgb = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RebuildExtraPartsCompanion.insert({
    required String rebuildSetId,
    required int partItemId,
    required int colorId,
    this.neededQty = const Value.absent(),
    this.haveQty = const Value.absent(),
    this.partName = const Value.absent(),
    this.partNum = const Value.absent(),
    this.partCatId = const Value.absent(),
    this.categoryName = const Value.absent(),
    this.colorName = const Value.absent(),
    this.colorRgb = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : rebuildSetId = Value(rebuildSetId),
       partItemId = Value(partItemId),
       colorId = Value(colorId);
  static Insertable<RebuildExtraPartRow> custom({
    Expression<String>? rebuildSetId,
    Expression<int>? partItemId,
    Expression<int>? colorId,
    Expression<int>? neededQty,
    Expression<int>? haveQty,
    Expression<String>? partName,
    Expression<String>? partNum,
    Expression<int>? partCatId,
    Expression<String>? categoryName,
    Expression<String>? colorName,
    Expression<String>? colorRgb,
    Expression<String>? imageUrl,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (rebuildSetId != null) 'rebuild_set_id': rebuildSetId,
      if (partItemId != null) 'part_item_id': partItemId,
      if (colorId != null) 'color_id': colorId,
      if (neededQty != null) 'needed_qty': neededQty,
      if (haveQty != null) 'have_qty': haveQty,
      if (partName != null) 'part_name': partName,
      if (partNum != null) 'part_num': partNum,
      if (partCatId != null) 'part_cat_id': partCatId,
      if (categoryName != null) 'category_name': categoryName,
      if (colorName != null) 'color_name': colorName,
      if (colorRgb != null) 'color_rgb': colorRgb,
      if (imageUrl != null) 'image_url': imageUrl,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RebuildExtraPartsCompanion copyWith({
    Value<String>? rebuildSetId,
    Value<int>? partItemId,
    Value<int>? colorId,
    Value<int>? neededQty,
    Value<int>? haveQty,
    Value<String>? partName,
    Value<String?>? partNum,
    Value<int?>? partCatId,
    Value<String?>? categoryName,
    Value<String?>? colorName,
    Value<String?>? colorRgb,
    Value<String?>? imageUrl,
    Value<int>? rowid,
  }) {
    return RebuildExtraPartsCompanion(
      rebuildSetId: rebuildSetId ?? this.rebuildSetId,
      partItemId: partItemId ?? this.partItemId,
      colorId: colorId ?? this.colorId,
      neededQty: neededQty ?? this.neededQty,
      haveQty: haveQty ?? this.haveQty,
      partName: partName ?? this.partName,
      partNum: partNum ?? this.partNum,
      partCatId: partCatId ?? this.partCatId,
      categoryName: categoryName ?? this.categoryName,
      colorName: colorName ?? this.colorName,
      colorRgb: colorRgb ?? this.colorRgb,
      imageUrl: imageUrl ?? this.imageUrl,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (rebuildSetId.present) {
      map['rebuild_set_id'] = Variable<String>(rebuildSetId.value);
    }
    if (partItemId.present) {
      map['part_item_id'] = Variable<int>(partItemId.value);
    }
    if (colorId.present) {
      map['color_id'] = Variable<int>(colorId.value);
    }
    if (neededQty.present) {
      map['needed_qty'] = Variable<int>(neededQty.value);
    }
    if (haveQty.present) {
      map['have_qty'] = Variable<int>(haveQty.value);
    }
    if (partName.present) {
      map['part_name'] = Variable<String>(partName.value);
    }
    if (partNum.present) {
      map['part_num'] = Variable<String>(partNum.value);
    }
    if (partCatId.present) {
      map['part_cat_id'] = Variable<int>(partCatId.value);
    }
    if (categoryName.present) {
      map['category_name'] = Variable<String>(categoryName.value);
    }
    if (colorName.present) {
      map['color_name'] = Variable<String>(colorName.value);
    }
    if (colorRgb.present) {
      map['color_rgb'] = Variable<String>(colorRgb.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RebuildExtraPartsCompanion(')
          ..write('rebuildSetId: $rebuildSetId, ')
          ..write('partItemId: $partItemId, ')
          ..write('colorId: $colorId, ')
          ..write('neededQty: $neededQty, ')
          ..write('haveQty: $haveQty, ')
          ..write('partName: $partName, ')
          ..write('partNum: $partNum, ')
          ..write('partCatId: $partCatId, ')
          ..write('categoryName: $categoryName, ')
          ..write('colorName: $colorName, ')
          ..write('colorRgb: $colorRgb, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $RebuildSetsTable rebuildSets = $RebuildSetsTable(this);
  late final $RebuildPartsTable rebuildParts = $RebuildPartsTable(this);
  late final $RebuildMinifigsTable rebuildMinifigs = $RebuildMinifigsTable(
    this,
  );
  late final $VerificationsTable verifications = $VerificationsTable(this);
  late final $RebuildExtraPartsTable rebuildExtraParts =
      $RebuildExtraPartsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    rebuildSets,
    rebuildParts,
    rebuildMinifigs,
    verifications,
    rebuildExtraParts,
  ];
}

typedef $$RebuildSetsTableCreateCompanionBuilder =
    RebuildSetsCompanion Function({
      required String id,
      required int setItemId,
      Value<String> name,
      Value<String?> theme,
      Value<int?> year,
      Value<String?> imageUrl,
      Value<int> totalParts,
      Value<DateTime?> verifiedAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<bool> dirty,
      Value<bool> deleted,
      Value<int> rowid,
    });
typedef $$RebuildSetsTableUpdateCompanionBuilder =
    RebuildSetsCompanion Function({
      Value<String> id,
      Value<int> setItemId,
      Value<String> name,
      Value<String?> theme,
      Value<int?> year,
      Value<String?> imageUrl,
      Value<int> totalParts,
      Value<DateTime?> verifiedAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<bool> dirty,
      Value<bool> deleted,
      Value<int> rowid,
    });

class $$RebuildSetsTableFilterComposer
    extends Composer<_$AppDatabase, $RebuildSetsTable> {
  $$RebuildSetsTableFilterComposer({
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

  ColumnFilters<int> get setItemId => $composableBuilder(
    column: $table.setItemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get theme => $composableBuilder(
    column: $table.theme,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalParts => $composableBuilder(
    column: $table.totalParts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get verifiedAt => $composableBuilder(
    column: $table.verifiedAt,
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

  ColumnFilters<bool> get dirty => $composableBuilder(
    column: $table.dirty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RebuildSetsTableOrderingComposer
    extends Composer<_$AppDatabase, $RebuildSetsTable> {
  $$RebuildSetsTableOrderingComposer({
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

  ColumnOrderings<int> get setItemId => $composableBuilder(
    column: $table.setItemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get theme => $composableBuilder(
    column: $table.theme,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalParts => $composableBuilder(
    column: $table.totalParts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get verifiedAt => $composableBuilder(
    column: $table.verifiedAt,
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

  ColumnOrderings<bool> get dirty => $composableBuilder(
    column: $table.dirty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RebuildSetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RebuildSetsTable> {
  $$RebuildSetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get setItemId =>
      $composableBuilder(column: $table.setItemId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get theme =>
      $composableBuilder(column: $table.theme, builder: (column) => column);

  GeneratedColumn<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  GeneratedColumn<int> get totalParts => $composableBuilder(
    column: $table.totalParts,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get verifiedAt => $composableBuilder(
    column: $table.verifiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get dirty =>
      $composableBuilder(column: $table.dirty, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);
}

class $$RebuildSetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RebuildSetsTable,
          RebuildSetRow,
          $$RebuildSetsTableFilterComposer,
          $$RebuildSetsTableOrderingComposer,
          $$RebuildSetsTableAnnotationComposer,
          $$RebuildSetsTableCreateCompanionBuilder,
          $$RebuildSetsTableUpdateCompanionBuilder,
          (
            RebuildSetRow,
            BaseReferences<_$AppDatabase, $RebuildSetsTable, RebuildSetRow>,
          ),
          RebuildSetRow,
          PrefetchHooks Function()
        > {
  $$RebuildSetsTableTableManager(_$AppDatabase db, $RebuildSetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RebuildSetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RebuildSetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RebuildSetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> setItemId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> theme = const Value.absent(),
                Value<int?> year = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<int> totalParts = const Value.absent(),
                Value<DateTime?> verifiedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> dirty = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RebuildSetsCompanion(
                id: id,
                setItemId: setItemId,
                name: name,
                theme: theme,
                year: year,
                imageUrl: imageUrl,
                totalParts: totalParts,
                verifiedAt: verifiedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                dirty: dirty,
                deleted: deleted,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int setItemId,
                Value<String> name = const Value.absent(),
                Value<String?> theme = const Value.absent(),
                Value<int?> year = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<int> totalParts = const Value.absent(),
                Value<DateTime?> verifiedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> dirty = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RebuildSetsCompanion.insert(
                id: id,
                setItemId: setItemId,
                name: name,
                theme: theme,
                year: year,
                imageUrl: imageUrl,
                totalParts: totalParts,
                verifiedAt: verifiedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                dirty: dirty,
                deleted: deleted,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RebuildSetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RebuildSetsTable,
      RebuildSetRow,
      $$RebuildSetsTableFilterComposer,
      $$RebuildSetsTableOrderingComposer,
      $$RebuildSetsTableAnnotationComposer,
      $$RebuildSetsTableCreateCompanionBuilder,
      $$RebuildSetsTableUpdateCompanionBuilder,
      (
        RebuildSetRow,
        BaseReferences<_$AppDatabase, $RebuildSetsTable, RebuildSetRow>,
      ),
      RebuildSetRow,
      PrefetchHooks Function()
    >;
typedef $$RebuildPartsTableCreateCompanionBuilder =
    RebuildPartsCompanion Function({
      required String rebuildSetId,
      required int partItemId,
      required int colorId,
      Value<int> neededQty,
      Value<int> haveQty,
      Value<String> partName,
      Value<String?> partNum,
      Value<int?> partCatId,
      Value<String?> categoryName,
      Value<String?> colorName,
      Value<String?> colorRgb,
      Value<String?> imageUrl,
      Value<String?> blPartId,
      Value<int?> blColorId,
      Value<DateTime> updatedAt,
      Value<bool> dirty,
      Value<bool> deleted,
      Value<int> rowid,
    });
typedef $$RebuildPartsTableUpdateCompanionBuilder =
    RebuildPartsCompanion Function({
      Value<String> rebuildSetId,
      Value<int> partItemId,
      Value<int> colorId,
      Value<int> neededQty,
      Value<int> haveQty,
      Value<String> partName,
      Value<String?> partNum,
      Value<int?> partCatId,
      Value<String?> categoryName,
      Value<String?> colorName,
      Value<String?> colorRgb,
      Value<String?> imageUrl,
      Value<String?> blPartId,
      Value<int?> blColorId,
      Value<DateTime> updatedAt,
      Value<bool> dirty,
      Value<bool> deleted,
      Value<int> rowid,
    });

class $$RebuildPartsTableFilterComposer
    extends Composer<_$AppDatabase, $RebuildPartsTable> {
  $$RebuildPartsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get rebuildSetId => $composableBuilder(
    column: $table.rebuildSetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get partItemId => $composableBuilder(
    column: $table.partItemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get colorId => $composableBuilder(
    column: $table.colorId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get neededQty => $composableBuilder(
    column: $table.neededQty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get haveQty => $composableBuilder(
    column: $table.haveQty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get partName => $composableBuilder(
    column: $table.partName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get partNum => $composableBuilder(
    column: $table.partNum,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get partCatId => $composableBuilder(
    column: $table.partCatId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryName => $composableBuilder(
    column: $table.categoryName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get colorName => $composableBuilder(
    column: $table.colorName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get colorRgb => $composableBuilder(
    column: $table.colorRgb,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get blPartId => $composableBuilder(
    column: $table.blPartId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get blColorId => $composableBuilder(
    column: $table.blColorId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get dirty => $composableBuilder(
    column: $table.dirty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RebuildPartsTableOrderingComposer
    extends Composer<_$AppDatabase, $RebuildPartsTable> {
  $$RebuildPartsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get rebuildSetId => $composableBuilder(
    column: $table.rebuildSetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get partItemId => $composableBuilder(
    column: $table.partItemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get colorId => $composableBuilder(
    column: $table.colorId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get neededQty => $composableBuilder(
    column: $table.neededQty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get haveQty => $composableBuilder(
    column: $table.haveQty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get partName => $composableBuilder(
    column: $table.partName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get partNum => $composableBuilder(
    column: $table.partNum,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get partCatId => $composableBuilder(
    column: $table.partCatId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryName => $composableBuilder(
    column: $table.categoryName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get colorName => $composableBuilder(
    column: $table.colorName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get colorRgb => $composableBuilder(
    column: $table.colorRgb,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get blPartId => $composableBuilder(
    column: $table.blPartId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get blColorId => $composableBuilder(
    column: $table.blColorId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get dirty => $composableBuilder(
    column: $table.dirty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RebuildPartsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RebuildPartsTable> {
  $$RebuildPartsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get rebuildSetId => $composableBuilder(
    column: $table.rebuildSetId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get partItemId => $composableBuilder(
    column: $table.partItemId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get colorId =>
      $composableBuilder(column: $table.colorId, builder: (column) => column);

  GeneratedColumn<int> get neededQty =>
      $composableBuilder(column: $table.neededQty, builder: (column) => column);

  GeneratedColumn<int> get haveQty =>
      $composableBuilder(column: $table.haveQty, builder: (column) => column);

  GeneratedColumn<String> get partName =>
      $composableBuilder(column: $table.partName, builder: (column) => column);

  GeneratedColumn<String> get partNum =>
      $composableBuilder(column: $table.partNum, builder: (column) => column);

  GeneratedColumn<int> get partCatId =>
      $composableBuilder(column: $table.partCatId, builder: (column) => column);

  GeneratedColumn<String> get categoryName => $composableBuilder(
    column: $table.categoryName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get colorName =>
      $composableBuilder(column: $table.colorName, builder: (column) => column);

  GeneratedColumn<String> get colorRgb =>
      $composableBuilder(column: $table.colorRgb, builder: (column) => column);

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  GeneratedColumn<String> get blPartId =>
      $composableBuilder(column: $table.blPartId, builder: (column) => column);

  GeneratedColumn<int> get blColorId =>
      $composableBuilder(column: $table.blColorId, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get dirty =>
      $composableBuilder(column: $table.dirty, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);
}

class $$RebuildPartsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RebuildPartsTable,
          RebuildPartRow,
          $$RebuildPartsTableFilterComposer,
          $$RebuildPartsTableOrderingComposer,
          $$RebuildPartsTableAnnotationComposer,
          $$RebuildPartsTableCreateCompanionBuilder,
          $$RebuildPartsTableUpdateCompanionBuilder,
          (
            RebuildPartRow,
            BaseReferences<_$AppDatabase, $RebuildPartsTable, RebuildPartRow>,
          ),
          RebuildPartRow,
          PrefetchHooks Function()
        > {
  $$RebuildPartsTableTableManager(_$AppDatabase db, $RebuildPartsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RebuildPartsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RebuildPartsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RebuildPartsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> rebuildSetId = const Value.absent(),
                Value<int> partItemId = const Value.absent(),
                Value<int> colorId = const Value.absent(),
                Value<int> neededQty = const Value.absent(),
                Value<int> haveQty = const Value.absent(),
                Value<String> partName = const Value.absent(),
                Value<String?> partNum = const Value.absent(),
                Value<int?> partCatId = const Value.absent(),
                Value<String?> categoryName = const Value.absent(),
                Value<String?> colorName = const Value.absent(),
                Value<String?> colorRgb = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<String?> blPartId = const Value.absent(),
                Value<int?> blColorId = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> dirty = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RebuildPartsCompanion(
                rebuildSetId: rebuildSetId,
                partItemId: partItemId,
                colorId: colorId,
                neededQty: neededQty,
                haveQty: haveQty,
                partName: partName,
                partNum: partNum,
                partCatId: partCatId,
                categoryName: categoryName,
                colorName: colorName,
                colorRgb: colorRgb,
                imageUrl: imageUrl,
                blPartId: blPartId,
                blColorId: blColorId,
                updatedAt: updatedAt,
                dirty: dirty,
                deleted: deleted,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String rebuildSetId,
                required int partItemId,
                required int colorId,
                Value<int> neededQty = const Value.absent(),
                Value<int> haveQty = const Value.absent(),
                Value<String> partName = const Value.absent(),
                Value<String?> partNum = const Value.absent(),
                Value<int?> partCatId = const Value.absent(),
                Value<String?> categoryName = const Value.absent(),
                Value<String?> colorName = const Value.absent(),
                Value<String?> colorRgb = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<String?> blPartId = const Value.absent(),
                Value<int?> blColorId = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> dirty = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RebuildPartsCompanion.insert(
                rebuildSetId: rebuildSetId,
                partItemId: partItemId,
                colorId: colorId,
                neededQty: neededQty,
                haveQty: haveQty,
                partName: partName,
                partNum: partNum,
                partCatId: partCatId,
                categoryName: categoryName,
                colorName: colorName,
                colorRgb: colorRgb,
                imageUrl: imageUrl,
                blPartId: blPartId,
                blColorId: blColorId,
                updatedAt: updatedAt,
                dirty: dirty,
                deleted: deleted,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RebuildPartsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RebuildPartsTable,
      RebuildPartRow,
      $$RebuildPartsTableFilterComposer,
      $$RebuildPartsTableOrderingComposer,
      $$RebuildPartsTableAnnotationComposer,
      $$RebuildPartsTableCreateCompanionBuilder,
      $$RebuildPartsTableUpdateCompanionBuilder,
      (
        RebuildPartRow,
        BaseReferences<_$AppDatabase, $RebuildPartsTable, RebuildPartRow>,
      ),
      RebuildPartRow,
      PrefetchHooks Function()
    >;
typedef $$RebuildMinifigsTableCreateCompanionBuilder =
    RebuildMinifigsCompanion Function({
      required String rebuildSetId,
      required int minifigItemId,
      Value<int> neededQty,
      Value<int> haveQty,
      Value<String> name,
      Value<String?> imageUrl,
      Value<DateTime> updatedAt,
      Value<bool> dirty,
      Value<bool> deleted,
      Value<int> rowid,
    });
typedef $$RebuildMinifigsTableUpdateCompanionBuilder =
    RebuildMinifigsCompanion Function({
      Value<String> rebuildSetId,
      Value<int> minifigItemId,
      Value<int> neededQty,
      Value<int> haveQty,
      Value<String> name,
      Value<String?> imageUrl,
      Value<DateTime> updatedAt,
      Value<bool> dirty,
      Value<bool> deleted,
      Value<int> rowid,
    });

class $$RebuildMinifigsTableFilterComposer
    extends Composer<_$AppDatabase, $RebuildMinifigsTable> {
  $$RebuildMinifigsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get rebuildSetId => $composableBuilder(
    column: $table.rebuildSetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get minifigItemId => $composableBuilder(
    column: $table.minifigItemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get neededQty => $composableBuilder(
    column: $table.neededQty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get haveQty => $composableBuilder(
    column: $table.haveQty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get dirty => $composableBuilder(
    column: $table.dirty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RebuildMinifigsTableOrderingComposer
    extends Composer<_$AppDatabase, $RebuildMinifigsTable> {
  $$RebuildMinifigsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get rebuildSetId => $composableBuilder(
    column: $table.rebuildSetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get minifigItemId => $composableBuilder(
    column: $table.minifigItemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get neededQty => $composableBuilder(
    column: $table.neededQty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get haveQty => $composableBuilder(
    column: $table.haveQty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get dirty => $composableBuilder(
    column: $table.dirty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RebuildMinifigsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RebuildMinifigsTable> {
  $$RebuildMinifigsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get rebuildSetId => $composableBuilder(
    column: $table.rebuildSetId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get minifigItemId => $composableBuilder(
    column: $table.minifigItemId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get neededQty =>
      $composableBuilder(column: $table.neededQty, builder: (column) => column);

  GeneratedColumn<int> get haveQty =>
      $composableBuilder(column: $table.haveQty, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get dirty =>
      $composableBuilder(column: $table.dirty, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);
}

class $$RebuildMinifigsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RebuildMinifigsTable,
          RebuildMinifigRow,
          $$RebuildMinifigsTableFilterComposer,
          $$RebuildMinifigsTableOrderingComposer,
          $$RebuildMinifigsTableAnnotationComposer,
          $$RebuildMinifigsTableCreateCompanionBuilder,
          $$RebuildMinifigsTableUpdateCompanionBuilder,
          (
            RebuildMinifigRow,
            BaseReferences<
              _$AppDatabase,
              $RebuildMinifigsTable,
              RebuildMinifigRow
            >,
          ),
          RebuildMinifigRow,
          PrefetchHooks Function()
        > {
  $$RebuildMinifigsTableTableManager(
    _$AppDatabase db,
    $RebuildMinifigsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RebuildMinifigsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RebuildMinifigsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RebuildMinifigsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> rebuildSetId = const Value.absent(),
                Value<int> minifigItemId = const Value.absent(),
                Value<int> neededQty = const Value.absent(),
                Value<int> haveQty = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> dirty = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RebuildMinifigsCompanion(
                rebuildSetId: rebuildSetId,
                minifigItemId: minifigItemId,
                neededQty: neededQty,
                haveQty: haveQty,
                name: name,
                imageUrl: imageUrl,
                updatedAt: updatedAt,
                dirty: dirty,
                deleted: deleted,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String rebuildSetId,
                required int minifigItemId,
                Value<int> neededQty = const Value.absent(),
                Value<int> haveQty = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> dirty = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RebuildMinifigsCompanion.insert(
                rebuildSetId: rebuildSetId,
                minifigItemId: minifigItemId,
                neededQty: neededQty,
                haveQty: haveQty,
                name: name,
                imageUrl: imageUrl,
                updatedAt: updatedAt,
                dirty: dirty,
                deleted: deleted,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RebuildMinifigsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RebuildMinifigsTable,
      RebuildMinifigRow,
      $$RebuildMinifigsTableFilterComposer,
      $$RebuildMinifigsTableOrderingComposer,
      $$RebuildMinifigsTableAnnotationComposer,
      $$RebuildMinifigsTableCreateCompanionBuilder,
      $$RebuildMinifigsTableUpdateCompanionBuilder,
      (
        RebuildMinifigRow,
        BaseReferences<_$AppDatabase, $RebuildMinifigsTable, RebuildMinifigRow>,
      ),
      RebuildMinifigRow,
      PrefetchHooks Function()
    >;
typedef $$VerificationsTableCreateCompanionBuilder =
    VerificationsCompanion Function({
      required String id,
      required String rebuildSetId,
      required int setItemId,
      Value<double> completionPct,
      Value<int?> partsNeeded,
      Value<int?> partsFound,
      Value<int?> minifigsNeeded,
      Value<int?> minifigsFound,
      Value<String> flags,
      Value<String?> notes,
      Value<DateTime> verifiedAt,
      Value<DateTime> updatedAt,
      Value<bool> dirty,
      Value<bool> deleted,
      Value<int> rowid,
    });
typedef $$VerificationsTableUpdateCompanionBuilder =
    VerificationsCompanion Function({
      Value<String> id,
      Value<String> rebuildSetId,
      Value<int> setItemId,
      Value<double> completionPct,
      Value<int?> partsNeeded,
      Value<int?> partsFound,
      Value<int?> minifigsNeeded,
      Value<int?> minifigsFound,
      Value<String> flags,
      Value<String?> notes,
      Value<DateTime> verifiedAt,
      Value<DateTime> updatedAt,
      Value<bool> dirty,
      Value<bool> deleted,
      Value<int> rowid,
    });

class $$VerificationsTableFilterComposer
    extends Composer<_$AppDatabase, $VerificationsTable> {
  $$VerificationsTableFilterComposer({
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

  ColumnFilters<String> get rebuildSetId => $composableBuilder(
    column: $table.rebuildSetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get setItemId => $composableBuilder(
    column: $table.setItemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get completionPct => $composableBuilder(
    column: $table.completionPct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get partsNeeded => $composableBuilder(
    column: $table.partsNeeded,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get partsFound => $composableBuilder(
    column: $table.partsFound,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get minifigsNeeded => $composableBuilder(
    column: $table.minifigsNeeded,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get minifigsFound => $composableBuilder(
    column: $table.minifigsFound,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get flags => $composableBuilder(
    column: $table.flags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get verifiedAt => $composableBuilder(
    column: $table.verifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get dirty => $composableBuilder(
    column: $table.dirty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );
}

class $$VerificationsTableOrderingComposer
    extends Composer<_$AppDatabase, $VerificationsTable> {
  $$VerificationsTableOrderingComposer({
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

  ColumnOrderings<String> get rebuildSetId => $composableBuilder(
    column: $table.rebuildSetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get setItemId => $composableBuilder(
    column: $table.setItemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get completionPct => $composableBuilder(
    column: $table.completionPct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get partsNeeded => $composableBuilder(
    column: $table.partsNeeded,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get partsFound => $composableBuilder(
    column: $table.partsFound,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get minifigsNeeded => $composableBuilder(
    column: $table.minifigsNeeded,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get minifigsFound => $composableBuilder(
    column: $table.minifigsFound,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get flags => $composableBuilder(
    column: $table.flags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get verifiedAt => $composableBuilder(
    column: $table.verifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get dirty => $composableBuilder(
    column: $table.dirty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VerificationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $VerificationsTable> {
  $$VerificationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get rebuildSetId => $composableBuilder(
    column: $table.rebuildSetId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get setItemId =>
      $composableBuilder(column: $table.setItemId, builder: (column) => column);

  GeneratedColumn<double> get completionPct => $composableBuilder(
    column: $table.completionPct,
    builder: (column) => column,
  );

  GeneratedColumn<int> get partsNeeded => $composableBuilder(
    column: $table.partsNeeded,
    builder: (column) => column,
  );

  GeneratedColumn<int> get partsFound => $composableBuilder(
    column: $table.partsFound,
    builder: (column) => column,
  );

  GeneratedColumn<int> get minifigsNeeded => $composableBuilder(
    column: $table.minifigsNeeded,
    builder: (column) => column,
  );

  GeneratedColumn<int> get minifigsFound => $composableBuilder(
    column: $table.minifigsFound,
    builder: (column) => column,
  );

  GeneratedColumn<String> get flags =>
      $composableBuilder(column: $table.flags, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get verifiedAt => $composableBuilder(
    column: $table.verifiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get dirty =>
      $composableBuilder(column: $table.dirty, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);
}

class $$VerificationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VerificationsTable,
          VerificationRow,
          $$VerificationsTableFilterComposer,
          $$VerificationsTableOrderingComposer,
          $$VerificationsTableAnnotationComposer,
          $$VerificationsTableCreateCompanionBuilder,
          $$VerificationsTableUpdateCompanionBuilder,
          (
            VerificationRow,
            BaseReferences<_$AppDatabase, $VerificationsTable, VerificationRow>,
          ),
          VerificationRow,
          PrefetchHooks Function()
        > {
  $$VerificationsTableTableManager(_$AppDatabase db, $VerificationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VerificationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VerificationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VerificationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> rebuildSetId = const Value.absent(),
                Value<int> setItemId = const Value.absent(),
                Value<double> completionPct = const Value.absent(),
                Value<int?> partsNeeded = const Value.absent(),
                Value<int?> partsFound = const Value.absent(),
                Value<int?> minifigsNeeded = const Value.absent(),
                Value<int?> minifigsFound = const Value.absent(),
                Value<String> flags = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> verifiedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> dirty = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VerificationsCompanion(
                id: id,
                rebuildSetId: rebuildSetId,
                setItemId: setItemId,
                completionPct: completionPct,
                partsNeeded: partsNeeded,
                partsFound: partsFound,
                minifigsNeeded: minifigsNeeded,
                minifigsFound: minifigsFound,
                flags: flags,
                notes: notes,
                verifiedAt: verifiedAt,
                updatedAt: updatedAt,
                dirty: dirty,
                deleted: deleted,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String rebuildSetId,
                required int setItemId,
                Value<double> completionPct = const Value.absent(),
                Value<int?> partsNeeded = const Value.absent(),
                Value<int?> partsFound = const Value.absent(),
                Value<int?> minifigsNeeded = const Value.absent(),
                Value<int?> minifigsFound = const Value.absent(),
                Value<String> flags = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> verifiedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> dirty = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VerificationsCompanion.insert(
                id: id,
                rebuildSetId: rebuildSetId,
                setItemId: setItemId,
                completionPct: completionPct,
                partsNeeded: partsNeeded,
                partsFound: partsFound,
                minifigsNeeded: minifigsNeeded,
                minifigsFound: minifigsFound,
                flags: flags,
                notes: notes,
                verifiedAt: verifiedAt,
                updatedAt: updatedAt,
                dirty: dirty,
                deleted: deleted,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$VerificationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VerificationsTable,
      VerificationRow,
      $$VerificationsTableFilterComposer,
      $$VerificationsTableOrderingComposer,
      $$VerificationsTableAnnotationComposer,
      $$VerificationsTableCreateCompanionBuilder,
      $$VerificationsTableUpdateCompanionBuilder,
      (
        VerificationRow,
        BaseReferences<_$AppDatabase, $VerificationsTable, VerificationRow>,
      ),
      VerificationRow,
      PrefetchHooks Function()
    >;
typedef $$RebuildExtraPartsTableCreateCompanionBuilder =
    RebuildExtraPartsCompanion Function({
      required String rebuildSetId,
      required int partItemId,
      required int colorId,
      Value<int> neededQty,
      Value<int> haveQty,
      Value<String> partName,
      Value<String?> partNum,
      Value<int?> partCatId,
      Value<String?> categoryName,
      Value<String?> colorName,
      Value<String?> colorRgb,
      Value<String?> imageUrl,
      Value<int> rowid,
    });
typedef $$RebuildExtraPartsTableUpdateCompanionBuilder =
    RebuildExtraPartsCompanion Function({
      Value<String> rebuildSetId,
      Value<int> partItemId,
      Value<int> colorId,
      Value<int> neededQty,
      Value<int> haveQty,
      Value<String> partName,
      Value<String?> partNum,
      Value<int?> partCatId,
      Value<String?> categoryName,
      Value<String?> colorName,
      Value<String?> colorRgb,
      Value<String?> imageUrl,
      Value<int> rowid,
    });

class $$RebuildExtraPartsTableFilterComposer
    extends Composer<_$AppDatabase, $RebuildExtraPartsTable> {
  $$RebuildExtraPartsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get rebuildSetId => $composableBuilder(
    column: $table.rebuildSetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get partItemId => $composableBuilder(
    column: $table.partItemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get colorId => $composableBuilder(
    column: $table.colorId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get neededQty => $composableBuilder(
    column: $table.neededQty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get haveQty => $composableBuilder(
    column: $table.haveQty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get partName => $composableBuilder(
    column: $table.partName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get partNum => $composableBuilder(
    column: $table.partNum,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get partCatId => $composableBuilder(
    column: $table.partCatId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryName => $composableBuilder(
    column: $table.categoryName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get colorName => $composableBuilder(
    column: $table.colorName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get colorRgb => $composableBuilder(
    column: $table.colorRgb,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RebuildExtraPartsTableOrderingComposer
    extends Composer<_$AppDatabase, $RebuildExtraPartsTable> {
  $$RebuildExtraPartsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get rebuildSetId => $composableBuilder(
    column: $table.rebuildSetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get partItemId => $composableBuilder(
    column: $table.partItemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get colorId => $composableBuilder(
    column: $table.colorId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get neededQty => $composableBuilder(
    column: $table.neededQty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get haveQty => $composableBuilder(
    column: $table.haveQty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get partName => $composableBuilder(
    column: $table.partName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get partNum => $composableBuilder(
    column: $table.partNum,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get partCatId => $composableBuilder(
    column: $table.partCatId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryName => $composableBuilder(
    column: $table.categoryName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get colorName => $composableBuilder(
    column: $table.colorName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get colorRgb => $composableBuilder(
    column: $table.colorRgb,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RebuildExtraPartsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RebuildExtraPartsTable> {
  $$RebuildExtraPartsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get rebuildSetId => $composableBuilder(
    column: $table.rebuildSetId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get partItemId => $composableBuilder(
    column: $table.partItemId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get colorId =>
      $composableBuilder(column: $table.colorId, builder: (column) => column);

  GeneratedColumn<int> get neededQty =>
      $composableBuilder(column: $table.neededQty, builder: (column) => column);

  GeneratedColumn<int> get haveQty =>
      $composableBuilder(column: $table.haveQty, builder: (column) => column);

  GeneratedColumn<String> get partName =>
      $composableBuilder(column: $table.partName, builder: (column) => column);

  GeneratedColumn<String> get partNum =>
      $composableBuilder(column: $table.partNum, builder: (column) => column);

  GeneratedColumn<int> get partCatId =>
      $composableBuilder(column: $table.partCatId, builder: (column) => column);

  GeneratedColumn<String> get categoryName => $composableBuilder(
    column: $table.categoryName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get colorName =>
      $composableBuilder(column: $table.colorName, builder: (column) => column);

  GeneratedColumn<String> get colorRgb =>
      $composableBuilder(column: $table.colorRgb, builder: (column) => column);

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);
}

class $$RebuildExtraPartsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RebuildExtraPartsTable,
          RebuildExtraPartRow,
          $$RebuildExtraPartsTableFilterComposer,
          $$RebuildExtraPartsTableOrderingComposer,
          $$RebuildExtraPartsTableAnnotationComposer,
          $$RebuildExtraPartsTableCreateCompanionBuilder,
          $$RebuildExtraPartsTableUpdateCompanionBuilder,
          (
            RebuildExtraPartRow,
            BaseReferences<
              _$AppDatabase,
              $RebuildExtraPartsTable,
              RebuildExtraPartRow
            >,
          ),
          RebuildExtraPartRow,
          PrefetchHooks Function()
        > {
  $$RebuildExtraPartsTableTableManager(
    _$AppDatabase db,
    $RebuildExtraPartsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RebuildExtraPartsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RebuildExtraPartsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RebuildExtraPartsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> rebuildSetId = const Value.absent(),
                Value<int> partItemId = const Value.absent(),
                Value<int> colorId = const Value.absent(),
                Value<int> neededQty = const Value.absent(),
                Value<int> haveQty = const Value.absent(),
                Value<String> partName = const Value.absent(),
                Value<String?> partNum = const Value.absent(),
                Value<int?> partCatId = const Value.absent(),
                Value<String?> categoryName = const Value.absent(),
                Value<String?> colorName = const Value.absent(),
                Value<String?> colorRgb = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RebuildExtraPartsCompanion(
                rebuildSetId: rebuildSetId,
                partItemId: partItemId,
                colorId: colorId,
                neededQty: neededQty,
                haveQty: haveQty,
                partName: partName,
                partNum: partNum,
                partCatId: partCatId,
                categoryName: categoryName,
                colorName: colorName,
                colorRgb: colorRgb,
                imageUrl: imageUrl,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String rebuildSetId,
                required int partItemId,
                required int colorId,
                Value<int> neededQty = const Value.absent(),
                Value<int> haveQty = const Value.absent(),
                Value<String> partName = const Value.absent(),
                Value<String?> partNum = const Value.absent(),
                Value<int?> partCatId = const Value.absent(),
                Value<String?> categoryName = const Value.absent(),
                Value<String?> colorName = const Value.absent(),
                Value<String?> colorRgb = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RebuildExtraPartsCompanion.insert(
                rebuildSetId: rebuildSetId,
                partItemId: partItemId,
                colorId: colorId,
                neededQty: neededQty,
                haveQty: haveQty,
                partName: partName,
                partNum: partNum,
                partCatId: partCatId,
                categoryName: categoryName,
                colorName: colorName,
                colorRgb: colorRgb,
                imageUrl: imageUrl,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RebuildExtraPartsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RebuildExtraPartsTable,
      RebuildExtraPartRow,
      $$RebuildExtraPartsTableFilterComposer,
      $$RebuildExtraPartsTableOrderingComposer,
      $$RebuildExtraPartsTableAnnotationComposer,
      $$RebuildExtraPartsTableCreateCompanionBuilder,
      $$RebuildExtraPartsTableUpdateCompanionBuilder,
      (
        RebuildExtraPartRow,
        BaseReferences<
          _$AppDatabase,
          $RebuildExtraPartsTable,
          RebuildExtraPartRow
        >,
      ),
      RebuildExtraPartRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$RebuildSetsTableTableManager get rebuildSets =>
      $$RebuildSetsTableTableManager(_db, _db.rebuildSets);
  $$RebuildPartsTableTableManager get rebuildParts =>
      $$RebuildPartsTableTableManager(_db, _db.rebuildParts);
  $$RebuildMinifigsTableTableManager get rebuildMinifigs =>
      $$RebuildMinifigsTableTableManager(_db, _db.rebuildMinifigs);
  $$VerificationsTableTableManager get verifications =>
      $$VerificationsTableTableManager(_db, _db.verifications);
  $$RebuildExtraPartsTableTableManager get rebuildExtraParts =>
      $$RebuildExtraPartsTableTableManager(_db, _db.rebuildExtraParts);
}
