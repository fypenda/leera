// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint

class $PracticeSessionsTable extends PracticeSessions
    with TableInfo<$PracticeSessionsTable, PracticeSessionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PracticeSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _topicIdMeta = const VerificationMeta(
    'topicId',
  );
  @override
  late final GeneratedColumn<String> topicId = GeneratedColumn<String>(
    'topic_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _formatMeta = const VerificationMeta('format');
  @override
  late final GeneratedColumn<String> format = GeneratedColumn<String>(
    'format',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _presentationMeta = const VerificationMeta(
    'presentation',
  );
  @override
  late final GeneratedColumn<String> presentation = GeneratedColumn<String>(
    'presentation',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rerolledMeta = const VerificationMeta(
    'rerolled',
  );
  @override
  late final GeneratedColumn<bool> rerolled = GeneratedColumn<bool>(
    'rerolled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("rerolled" IN (0, 1))',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> startedAt =
      GeneratedColumn<int>(
        'started_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($PracticeSessionsTable.$converterstartedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> updatedAt =
      GeneratedColumn<int>(
        'updated_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($PracticeSessionsTable.$converterupdatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> completedAt =
      GeneratedColumn<int>(
        'completed_at',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($PracticeSessionsTable.$convertercompletedAtn);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    topicId,
    format,
    status,
    notes,
    presentation,
    rerolled,
    startedAt,
    updatedAt,
    completedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'practice_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<PracticeSessionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('topic_id')) {
      context.handle(
        _topicIdMeta,
        topicId.isAcceptableOrUnknown(data['topic_id']!, _topicIdMeta),
      );
    } else if (isInserting) {
      context.missing(_topicIdMeta);
    }
    if (data.containsKey('format')) {
      context.handle(
        _formatMeta,
        format.isAcceptableOrUnknown(data['format']!, _formatMeta),
      );
    } else if (isInserting) {
      context.missing(_formatMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    } else if (isInserting) {
      context.missing(_notesMeta);
    }
    if (data.containsKey('presentation')) {
      context.handle(
        _presentationMeta,
        presentation.isAcceptableOrUnknown(
          data['presentation']!,
          _presentationMeta,
        ),
      );
    }
    if (data.containsKey('rerolled')) {
      context.handle(
        _rerolledMeta,
        rerolled.isAcceptableOrUnknown(data['rerolled']!, _rerolledMeta),
      );
    } else if (isInserting) {
      context.missing(_rerolledMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PracticeSessionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PracticeSessionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      topicId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}topic_id'],
      )!,
      format: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}format'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      )!,
      presentation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}presentation'],
      ),
      rerolled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}rerolled'],
      )!,
      startedAt: $PracticeSessionsTable.$converterstartedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}started_at'],
        )!,
      ),
      updatedAt: $PracticeSessionsTable.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}updated_at'],
        )!,
      ),
      completedAt: $PracticeSessionsTable.$convertercompletedAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}completed_at'],
        ),
      ),
    );
  }

  @override
  $PracticeSessionsTable createAlias(String alias) {
    return $PracticeSessionsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $converterstartedAt =
      const UtcInstantConverter();
  static TypeConverter<DateTime, int> $converterupdatedAt =
      const UtcInstantConverter();
  static TypeConverter<DateTime, int> $convertercompletedAt =
      const UtcInstantConverter();
  static TypeConverter<DateTime?, int?> $convertercompletedAtn =
      NullAwareTypeConverter.wrap($convertercompletedAt);
}

class PracticeSessionRow extends DataClass
    implements Insertable<PracticeSessionRow> {
  final String id;
  final String topicId;
  final String format;
  final String status;
  final String notes;
  final String? presentation;
  final bool rerolled;
  final DateTime startedAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  const PracticeSessionRow({
    required this.id,
    required this.topicId,
    required this.format,
    required this.status,
    required this.notes,
    this.presentation,
    required this.rerolled,
    required this.startedAt,
    required this.updatedAt,
    this.completedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['topic_id'] = Variable<String>(topicId);
    map['format'] = Variable<String>(format);
    map['status'] = Variable<String>(status);
    map['notes'] = Variable<String>(notes);
    if (!nullToAbsent || presentation != null) {
      map['presentation'] = Variable<String>(presentation);
    }
    map['rerolled'] = Variable<bool>(rerolled);
    {
      map['started_at'] = Variable<int>(
        $PracticeSessionsTable.$converterstartedAt.toSql(startedAt),
      );
    }
    {
      map['updated_at'] = Variable<int>(
        $PracticeSessionsTable.$converterupdatedAt.toSql(updatedAt),
      );
    }
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<int>(
        $PracticeSessionsTable.$convertercompletedAtn.toSql(completedAt),
      );
    }
    return map;
  }

  PracticeSessionsCompanion toCompanion(bool nullToAbsent) {
    return PracticeSessionsCompanion(
      id: Value(id),
      topicId: Value(topicId),
      format: Value(format),
      status: Value(status),
      notes: Value(notes),
      presentation: presentation == null && nullToAbsent
          ? const Value.absent()
          : Value(presentation),
      rerolled: Value(rerolled),
      startedAt: Value(startedAt),
      updatedAt: Value(updatedAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
    );
  }

  factory PracticeSessionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PracticeSessionRow(
      id: serializer.fromJson<String>(json['id']),
      topicId: serializer.fromJson<String>(json['topicId']),
      format: serializer.fromJson<String>(json['format']),
      status: serializer.fromJson<String>(json['status']),
      notes: serializer.fromJson<String>(json['notes']),
      presentation: serializer.fromJson<String?>(json['presentation']),
      rerolled: serializer.fromJson<bool>(json['rerolled']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'topicId': serializer.toJson<String>(topicId),
      'format': serializer.toJson<String>(format),
      'status': serializer.toJson<String>(status),
      'notes': serializer.toJson<String>(notes),
      'presentation': serializer.toJson<String?>(presentation),
      'rerolled': serializer.toJson<bool>(rerolled),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
    };
  }

  PracticeSessionRow copyWith({
    String? id,
    String? topicId,
    String? format,
    String? status,
    String? notes,
    Value<String?> presentation = const Value.absent(),
    bool? rerolled,
    DateTime? startedAt,
    DateTime? updatedAt,
    Value<DateTime?> completedAt = const Value.absent(),
  }) => PracticeSessionRow(
    id: id ?? this.id,
    topicId: topicId ?? this.topicId,
    format: format ?? this.format,
    status: status ?? this.status,
    notes: notes ?? this.notes,
    presentation: presentation.present ? presentation.value : this.presentation,
    rerolled: rerolled ?? this.rerolled,
    startedAt: startedAt ?? this.startedAt,
    updatedAt: updatedAt ?? this.updatedAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
  );
  PracticeSessionRow copyWithCompanion(PracticeSessionsCompanion data) {
    return PracticeSessionRow(
      id: data.id.present ? data.id.value : this.id,
      topicId: data.topicId.present ? data.topicId.value : this.topicId,
      format: data.format.present ? data.format.value : this.format,
      status: data.status.present ? data.status.value : this.status,
      notes: data.notes.present ? data.notes.value : this.notes,
      presentation: data.presentation.present
          ? data.presentation.value
          : this.presentation,
      rerolled: data.rerolled.present ? data.rerolled.value : this.rerolled,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PracticeSessionRow(')
          ..write('id: $id, ')
          ..write('topicId: $topicId, ')
          ..write('format: $format, ')
          ..write('status: $status, ')
          ..write('notes: $notes, ')
          ..write('presentation: $presentation, ')
          ..write('rerolled: $rerolled, ')
          ..write('startedAt: $startedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    topicId,
    format,
    status,
    notes,
    presentation,
    rerolled,
    startedAt,
    updatedAt,
    completedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PracticeSessionRow &&
          other.id == this.id &&
          other.topicId == this.topicId &&
          other.format == this.format &&
          other.status == this.status &&
          other.notes == this.notes &&
          other.presentation == this.presentation &&
          other.rerolled == this.rerolled &&
          other.startedAt == this.startedAt &&
          other.updatedAt == this.updatedAt &&
          other.completedAt == this.completedAt);
}

class PracticeSessionsCompanion extends UpdateCompanion<PracticeSessionRow> {
  final Value<String> id;
  final Value<String> topicId;
  final Value<String> format;
  final Value<String> status;
  final Value<String> notes;
  final Value<String?> presentation;
  final Value<bool> rerolled;
  final Value<DateTime> startedAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> completedAt;
  final Value<int> rowid;
  const PracticeSessionsCompanion({
    this.id = const Value.absent(),
    this.topicId = const Value.absent(),
    this.format = const Value.absent(),
    this.status = const Value.absent(),
    this.notes = const Value.absent(),
    this.presentation = const Value.absent(),
    this.rerolled = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PracticeSessionsCompanion.insert({
    required String id,
    required String topicId,
    required String format,
    required String status,
    required String notes,
    this.presentation = const Value.absent(),
    required bool rerolled,
    required DateTime startedAt,
    required DateTime updatedAt,
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       topicId = Value(topicId),
       format = Value(format),
       status = Value(status),
       notes = Value(notes),
       rerolled = Value(rerolled),
       startedAt = Value(startedAt),
       updatedAt = Value(updatedAt);
  static Insertable<PracticeSessionRow> custom({
    Expression<String>? id,
    Expression<String>? topicId,
    Expression<String>? format,
    Expression<String>? status,
    Expression<String>? notes,
    Expression<String>? presentation,
    Expression<bool>? rerolled,
    Expression<int>? startedAt,
    Expression<int>? updatedAt,
    Expression<int>? completedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (topicId != null) 'topic_id': topicId,
      if (format != null) 'format': format,
      if (status != null) 'status': status,
      if (notes != null) 'notes': notes,
      if (presentation != null) 'presentation': presentation,
      if (rerolled != null) 'rerolled': rerolled,
      if (startedAt != null) 'started_at': startedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PracticeSessionsCompanion copyWith({
    Value<String>? id,
    Value<String>? topicId,
    Value<String>? format,
    Value<String>? status,
    Value<String>? notes,
    Value<String?>? presentation,
    Value<bool>? rerolled,
    Value<DateTime>? startedAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? completedAt,
    Value<int>? rowid,
  }) {
    return PracticeSessionsCompanion(
      id: id ?? this.id,
      topicId: topicId ?? this.topicId,
      format: format ?? this.format,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      presentation: presentation ?? this.presentation,
      rerolled: rerolled ?? this.rerolled,
      startedAt: startedAt ?? this.startedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (topicId.present) {
      map['topic_id'] = Variable<String>(topicId.value);
    }
    if (format.present) {
      map['format'] = Variable<String>(format.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (presentation.present) {
      map['presentation'] = Variable<String>(presentation.value);
    }
    if (rerolled.present) {
      map['rerolled'] = Variable<bool>(rerolled.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<int>(
        $PracticeSessionsTable.$converterstartedAt.toSql(startedAt.value),
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(
        $PracticeSessionsTable.$converterupdatedAt.toSql(updatedAt.value),
      );
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<int>(
        $PracticeSessionsTable.$convertercompletedAtn.toSql(completedAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PracticeSessionsCompanion(')
          ..write('id: $id, ')
          ..write('topicId: $topicId, ')
          ..write('format: $format, ')
          ..write('status: $status, ')
          ..write('notes: $notes, ')
          ..write('presentation: $presentation, ')
          ..write('rerolled: $rerolled, ')
          ..write('startedAt: $startedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SessionFeedbacksTable extends SessionFeedbacks
    with TableInfo<$SessionFeedbacksTable, SessionFeedbackRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionFeedbacksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES practice_sessions (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> receivedAt =
      GeneratedColumn<int>(
        'received_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($SessionFeedbacksTable.$converterreceivedAt);
  @override
  List<GeneratedColumn> get $columns => [sessionId, payload, receivedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'session_feedbacks';
  @override
  VerificationContext validateIntegrity(
    Insertable<SessionFeedbackRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sessionId};
  @override
  SessionFeedbackRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SessionFeedbackRow(
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      receivedAt: $SessionFeedbacksTable.$converterreceivedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}received_at'],
        )!,
      ),
    );
  }

  @override
  $SessionFeedbacksTable createAlias(String alias) {
    return $SessionFeedbacksTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $converterreceivedAt =
      const UtcInstantConverter();
}

class SessionFeedbackRow extends DataClass
    implements Insertable<SessionFeedbackRow> {
  final String sessionId;
  final String payload;
  final DateTime receivedAt;
  const SessionFeedbackRow({
    required this.sessionId,
    required this.payload,
    required this.receivedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['session_id'] = Variable<String>(sessionId);
    map['payload'] = Variable<String>(payload);
    {
      map['received_at'] = Variable<int>(
        $SessionFeedbacksTable.$converterreceivedAt.toSql(receivedAt),
      );
    }
    return map;
  }

  SessionFeedbacksCompanion toCompanion(bool nullToAbsent) {
    return SessionFeedbacksCompanion(
      sessionId: Value(sessionId),
      payload: Value(payload),
      receivedAt: Value(receivedAt),
    );
  }

  factory SessionFeedbackRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SessionFeedbackRow(
      sessionId: serializer.fromJson<String>(json['sessionId']),
      payload: serializer.fromJson<String>(json['payload']),
      receivedAt: serializer.fromJson<DateTime>(json['receivedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sessionId': serializer.toJson<String>(sessionId),
      'payload': serializer.toJson<String>(payload),
      'receivedAt': serializer.toJson<DateTime>(receivedAt),
    };
  }

  SessionFeedbackRow copyWith({
    String? sessionId,
    String? payload,
    DateTime? receivedAt,
  }) => SessionFeedbackRow(
    sessionId: sessionId ?? this.sessionId,
    payload: payload ?? this.payload,
    receivedAt: receivedAt ?? this.receivedAt,
  );
  SessionFeedbackRow copyWithCompanion(SessionFeedbacksCompanion data) {
    return SessionFeedbackRow(
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      payload: data.payload.present ? data.payload.value : this.payload,
      receivedAt: data.receivedAt.present
          ? data.receivedAt.value
          : this.receivedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SessionFeedbackRow(')
          ..write('sessionId: $sessionId, ')
          ..write('payload: $payload, ')
          ..write('receivedAt: $receivedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(sessionId, payload, receivedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SessionFeedbackRow &&
          other.sessionId == this.sessionId &&
          other.payload == this.payload &&
          other.receivedAt == this.receivedAt);
}

class SessionFeedbacksCompanion extends UpdateCompanion<SessionFeedbackRow> {
  final Value<String> sessionId;
  final Value<String> payload;
  final Value<DateTime> receivedAt;
  final Value<int> rowid;
  const SessionFeedbacksCompanion({
    this.sessionId = const Value.absent(),
    this.payload = const Value.absent(),
    this.receivedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SessionFeedbacksCompanion.insert({
    required String sessionId,
    required String payload,
    required DateTime receivedAt,
    this.rowid = const Value.absent(),
  }) : sessionId = Value(sessionId),
       payload = Value(payload),
       receivedAt = Value(receivedAt);
  static Insertable<SessionFeedbackRow> custom({
    Expression<String>? sessionId,
    Expression<String>? payload,
    Expression<int>? receivedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sessionId != null) 'session_id': sessionId,
      if (payload != null) 'payload': payload,
      if (receivedAt != null) 'received_at': receivedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SessionFeedbacksCompanion copyWith({
    Value<String>? sessionId,
    Value<String>? payload,
    Value<DateTime>? receivedAt,
    Value<int>? rowid,
  }) {
    return SessionFeedbacksCompanion(
      sessionId: sessionId ?? this.sessionId,
      payload: payload ?? this.payload,
      receivedAt: receivedAt ?? this.receivedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (receivedAt.present) {
      map['received_at'] = Variable<int>(
        $SessionFeedbacksTable.$converterreceivedAt.toSql(receivedAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionFeedbacksCompanion(')
          ..write('sessionId: $sessionId, ')
          ..write('payload: $payload, ')
          ..write('receivedAt: $receivedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}


class $SessionRecordingsTable extends SessionRecordings
    with TableInfo<$SessionRecordingsTable, SessionRecordingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionRecordingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES practice_sessions (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _fileNameMeta = const VerificationMeta(
    'fileName',
  );
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
    'file_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> recordedAt =
      GeneratedColumn<int>(
        'recorded_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($SessionRecordingsTable.$converterrecordedAt);
  static const VerificationMeta _transcriptMeta = const VerificationMeta(
    'transcript',
  );
  @override
  late final GeneratedColumn<String> transcript = GeneratedColumn<String>(
    'transcript',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    sessionId,
    fileName,
    durationMs,
    recordedAt,
    transcript,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'session_recordings';
  @override
  VerificationContext validateIntegrity(
    Insertable<SessionRecordingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('file_name')) {
      context.handle(
        _fileNameMeta,
        fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fileNameMeta);
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    } else if (isInserting) {
      context.missing(_durationMsMeta);
    }
    if (data.containsKey('transcript')) {
      context.handle(
        _transcriptMeta,
        transcript.isAcceptableOrUnknown(data['transcript']!, _transcriptMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sessionId};
  @override
  SessionRecordingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SessionRecordingRow(
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      fileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_name'],
      )!,
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      )!,
      recordedAt: $SessionRecordingsTable.$converterrecordedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}recorded_at'],
        )!,
      ),
      transcript: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transcript'],
      ),
    );
  }

  @override
  $SessionRecordingsTable createAlias(String alias) {
    return $SessionRecordingsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $converterrecordedAt =
      const UtcInstantConverter();
}

class SessionRecordingRow extends DataClass
    implements Insertable<SessionRecordingRow> {
  final String sessionId;
  final String fileName;
  final int durationMs;
  final DateTime recordedAt;
  final String? transcript;
  const SessionRecordingRow({
    required this.sessionId,
    required this.fileName,
    required this.durationMs,
    required this.recordedAt,
    this.transcript,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['session_id'] = Variable<String>(sessionId);
    map['file_name'] = Variable<String>(fileName);
    map['duration_ms'] = Variable<int>(durationMs);
    {
      map['recorded_at'] = Variable<int>(
        $SessionRecordingsTable.$converterrecordedAt.toSql(recordedAt),
      );
    }
    if (!nullToAbsent || transcript != null) {
      map['transcript'] = Variable<String>(transcript);
    }
    return map;
  }

  SessionRecordingsCompanion toCompanion(bool nullToAbsent) {
    return SessionRecordingsCompanion(
      sessionId: Value(sessionId),
      fileName: Value(fileName),
      durationMs: Value(durationMs),
      recordedAt: Value(recordedAt),
      transcript: transcript == null && nullToAbsent
          ? const Value.absent()
          : Value(transcript),
    );
  }

  factory SessionRecordingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SessionRecordingRow(
      sessionId: serializer.fromJson<String>(json['sessionId']),
      fileName: serializer.fromJson<String>(json['fileName']),
      durationMs: serializer.fromJson<int>(json['durationMs']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
      transcript: serializer.fromJson<String?>(json['transcript']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sessionId': serializer.toJson<String>(sessionId),
      'fileName': serializer.toJson<String>(fileName),
      'durationMs': serializer.toJson<int>(durationMs),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
      'transcript': serializer.toJson<String?>(transcript),
    };
  }

  SessionRecordingRow copyWith({
    String? sessionId,
    String? fileName,
    int? durationMs,
    DateTime? recordedAt,
    Value<String?> transcript = const Value.absent(),
  }) => SessionRecordingRow(
    sessionId: sessionId ?? this.sessionId,
    fileName: fileName ?? this.fileName,
    durationMs: durationMs ?? this.durationMs,
    recordedAt: recordedAt ?? this.recordedAt,
    transcript: transcript.present ? transcript.value : this.transcript,
  );
  SessionRecordingRow copyWithCompanion(SessionRecordingsCompanion data) {
    return SessionRecordingRow(
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      recordedAt: data.recordedAt.present
          ? data.recordedAt.value
          : this.recordedAt,
      transcript: data.transcript.present
          ? data.transcript.value
          : this.transcript,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SessionRecordingRow(')
          ..write('sessionId: $sessionId, ')
          ..write('fileName: $fileName, ')
          ..write('durationMs: $durationMs, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('transcript: $transcript')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(sessionId, fileName, durationMs, recordedAt, transcript);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SessionRecordingRow &&
          other.sessionId == this.sessionId &&
          other.fileName == this.fileName &&
          other.durationMs == this.durationMs &&
          other.recordedAt == this.recordedAt &&
          other.transcript == this.transcript);
}

class SessionRecordingsCompanion extends UpdateCompanion<SessionRecordingRow> {
  final Value<String> sessionId;
  final Value<String> fileName;
  final Value<int> durationMs;
  final Value<DateTime> recordedAt;
  final Value<String?> transcript;
  final Value<int> rowid;
  const SessionRecordingsCompanion({
    this.sessionId = const Value.absent(),
    this.fileName = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.transcript = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SessionRecordingsCompanion.insert({
    required String sessionId,
    required String fileName,
    required int durationMs,
    required DateTime recordedAt,
    this.transcript = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : sessionId = Value(sessionId),
       fileName = Value(fileName),
       durationMs = Value(durationMs),
       recordedAt = Value(recordedAt);
  static Insertable<SessionRecordingRow> custom({
    Expression<String>? sessionId,
    Expression<String>? fileName,
    Expression<int>? durationMs,
    Expression<int>? recordedAt,
    Expression<String>? transcript,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sessionId != null) 'session_id': sessionId,
      if (fileName != null) 'file_name': fileName,
      if (durationMs != null) 'duration_ms': durationMs,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (transcript != null) 'transcript': transcript,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SessionRecordingsCompanion copyWith({
    Value<String>? sessionId,
    Value<String>? fileName,
    Value<int>? durationMs,
    Value<DateTime>? recordedAt,
    Value<String?>? transcript,
    Value<int>? rowid,
  }) {
    return SessionRecordingsCompanion(
      sessionId: sessionId ?? this.sessionId,
      fileName: fileName ?? this.fileName,
      durationMs: durationMs ?? this.durationMs,
      recordedAt: recordedAt ?? this.recordedAt,
      transcript: transcript ?? this.transcript,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<int>(
        $SessionRecordingsTable.$converterrecordedAt.toSql(recordedAt.value),
      );
    }
    if (transcript.present) {
      map['transcript'] = Variable<String>(transcript.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionRecordingsCompanion(')
          ..write('sessionId: $sessionId, ')
          ..write('fileName: $fileName, ')
          ..write('durationMs: $durationMs, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('transcript: $transcript, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}


abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $PracticeSessionsTable practiceSessions = $PracticeSessionsTable(
    this,
  );
  late final $SessionFeedbacksTable sessionFeedbacks = $SessionFeedbacksTable(
    this,
  );
  late final $SessionRecordingsTable sessionRecordings =
      $SessionRecordingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    practiceSessions,
    sessionFeedbacks,
    sessionRecordings,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'practice_sessions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('session_feedbacks', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'practice_sessions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('session_recordings', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$PracticeSessionsTableCreateCompanionBuilder =
    PracticeSessionsCompanion Function({
      required String id,
      required String topicId,
      required String format,
      required String status,
      required String notes,
      Value<String?> presentation,
      required bool rerolled,
      required DateTime startedAt,
      required DateTime updatedAt,
      Value<DateTime?> completedAt,
      Value<int> rowid,
    });
typedef $$PracticeSessionsTableUpdateCompanionBuilder =
    PracticeSessionsCompanion Function({
      Value<String> id,
      Value<String> topicId,
      Value<String> format,
      Value<String> status,
      Value<String> notes,
      Value<String?> presentation,
      Value<bool> rerolled,
      Value<DateTime> startedAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> completedAt,
      Value<int> rowid,
    });

final class $$PracticeSessionsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $PracticeSessionsTable,
          PracticeSessionRow
        > {
  $$PracticeSessionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$SessionFeedbacksTable, List<SessionFeedbackRow>>
  _sessionFeedbacksRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.sessionFeedbacks,
    aliasName: 'practice_sessions__id__session_feedbacks__session_id',
  );

  $$SessionFeedbacksTableProcessedTableManager get sessionFeedbacksRefs {
    final manager = $$SessionFeedbacksTableTableManager(
      $_db,
      $_db.sessionFeedbacks,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _sessionFeedbacksRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SessionRecordingsTable, List<SessionRecordingRow>>
  _sessionRecordingsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.sessionRecordings,
        aliasName: 'practice_sessions__id__session_recordings__session_id',
      );

  $$SessionRecordingsTableProcessedTableManager get sessionRecordingsRefs {
    final manager = $$SessionRecordingsTableTableManager(
      $_db,
      $_db.sessionRecordings,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _sessionRecordingsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PracticeSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $PracticeSessionsTable> {
  $$PracticeSessionsTableFilterComposer({
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

  ColumnFilters<String> get topicId => $composableBuilder(
    column: $table.topicId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get format => $composableBuilder(
    column: $table.format,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get presentation => $composableBuilder(
    column: $table.presentation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get rerolled => $composableBuilder(
    column: $table.rerolled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get startedAt =>
      $composableBuilder(
        column: $table.startedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get updatedAt =>
      $composableBuilder(
        column: $table.updatedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, int> get completedAt =>
      $composableBuilder(
        column: $table.completedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  Expression<bool> sessionFeedbacksRefs(
    Expression<bool> Function($$SessionFeedbacksTableFilterComposer f) f,
  ) {
    final $$SessionFeedbacksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sessionFeedbacks,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionFeedbacksTableFilterComposer(
            $db: $db,
            $table: $db.sessionFeedbacks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> sessionRecordingsRefs(
    Expression<bool> Function($$SessionRecordingsTableFilterComposer f) f,
  ) {
    final $$SessionRecordingsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sessionRecordings,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionRecordingsTableFilterComposer(
            $db: $db,
            $table: $db.sessionRecordings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PracticeSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $PracticeSessionsTable> {
  $$PracticeSessionsTableOrderingComposer({
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

  ColumnOrderings<String> get topicId => $composableBuilder(
    column: $table.topicId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get format => $composableBuilder(
    column: $table.format,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get presentation => $composableBuilder(
    column: $table.presentation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get rerolled => $composableBuilder(
    column: $table.rerolled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PracticeSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PracticeSessionsTable> {
  $$PracticeSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get topicId =>
      $composableBuilder(column: $table.topicId, builder: (column) => column);

  GeneratedColumn<String> get format =>
      $composableBuilder(column: $table.format, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get presentation => $composableBuilder(
    column: $table.presentation,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get rerolled =>
      $composableBuilder(column: $table.rerolled, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime?, int> get completedAt =>
      $composableBuilder(
        column: $table.completedAt,
        builder: (column) => column,
      );

  Expression<T> sessionFeedbacksRefs<T extends Object>(
    Expression<T> Function($$SessionFeedbacksTableAnnotationComposer a) f,
  ) {
    final $$SessionFeedbacksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sessionFeedbacks,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionFeedbacksTableAnnotationComposer(
            $db: $db,
            $table: $db.sessionFeedbacks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> sessionRecordingsRefs<T extends Object>(
    Expression<T> Function($$SessionRecordingsTableAnnotationComposer a) f,
  ) {
    final $$SessionRecordingsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.sessionRecordings,
          getReferencedColumn: (t) => t.sessionId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$SessionRecordingsTableAnnotationComposer(
                $db: $db,
                $table: $db.sessionRecordings,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$PracticeSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PracticeSessionsTable,
          PracticeSessionRow,
          $$PracticeSessionsTableFilterComposer,
          $$PracticeSessionsTableOrderingComposer,
          $$PracticeSessionsTableAnnotationComposer,
          $$PracticeSessionsTableCreateCompanionBuilder,
          $$PracticeSessionsTableUpdateCompanionBuilder,
          (PracticeSessionRow, $$PracticeSessionsTableReferences),
          PracticeSessionRow,
          PrefetchHooks Function({
            bool sessionFeedbacksRefs,
            bool sessionRecordingsRefs,
          })
        > {
  $$PracticeSessionsTableTableManager(
    _$AppDatabase db,
    $PracticeSessionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PracticeSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PracticeSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PracticeSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> topicId = const Value.absent(),
                Value<String> format = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<String?> presentation = const Value.absent(),
                Value<bool> rerolled = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PracticeSessionsCompanion(
                id: id,
                topicId: topicId,
                format: format,
                status: status,
                notes: notes,
                presentation: presentation,
                rerolled: rerolled,
                startedAt: startedAt,
                updatedAt: updatedAt,
                completedAt: completedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String topicId,
                required String format,
                required String status,
                required String notes,
                Value<String?> presentation = const Value.absent(),
                required bool rerolled,
                required DateTime startedAt,
                required DateTime updatedAt,
                Value<DateTime?> completedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PracticeSessionsCompanion.insert(
                id: id,
                topicId: topicId,
                format: format,
                status: status,
                notes: notes,
                presentation: presentation,
                rerolled: rerolled,
                startedAt: startedAt,
                updatedAt: updatedAt,
                completedAt: completedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PracticeSessionsTable, PracticeSessionRow>(
                    table,
                  ),
                  $$PracticeSessionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({sessionFeedbacksRefs = false, sessionRecordingsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (sessionFeedbacksRefs) db.sessionFeedbacks,
                    if (sessionRecordingsRefs) db.sessionRecordings,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (sessionFeedbacksRefs)
                        await $_getPrefetchedData<
                          PracticeSessionRow,
                          $PracticeSessionsTable,
                          SessionFeedbackRow
                        >(
                          currentTable: table,
                          referencedTable: $$PracticeSessionsTableReferences
                              ._sessionFeedbacksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PracticeSessionsTableReferences(
                                db,
                                table,
                                p0,
                              ).sessionFeedbacksRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sessionId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (sessionRecordingsRefs)
                        await $_getPrefetchedData<
                          PracticeSessionRow,
                          $PracticeSessionsTable,
                          SessionRecordingRow
                        >(
                          currentTable: table,
                          referencedTable: $$PracticeSessionsTableReferences
                              ._sessionRecordingsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PracticeSessionsTableReferences(
                                db,
                                table,
                                p0,
                              ).sessionRecordingsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sessionId == item.id,
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

typedef $$PracticeSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PracticeSessionsTable,
      PracticeSessionRow,
      $$PracticeSessionsTableFilterComposer,
      $$PracticeSessionsTableOrderingComposer,
      $$PracticeSessionsTableAnnotationComposer,
      $$PracticeSessionsTableCreateCompanionBuilder,
      $$PracticeSessionsTableUpdateCompanionBuilder,
      (PracticeSessionRow, $$PracticeSessionsTableReferences),
      PracticeSessionRow,
      PrefetchHooks Function({
        bool sessionFeedbacksRefs,
        bool sessionRecordingsRefs,
      })
    >;
typedef $$SessionFeedbacksTableCreateCompanionBuilder =
    SessionFeedbacksCompanion Function({
      required String sessionId,
      required String payload,
      required DateTime receivedAt,
      Value<int> rowid,
    });
typedef $$SessionFeedbacksTableUpdateCompanionBuilder =
    SessionFeedbacksCompanion Function({
      Value<String> sessionId,
      Value<String> payload,
      Value<DateTime> receivedAt,
      Value<int> rowid,
    });

final class $$SessionFeedbacksTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $SessionFeedbacksTable,
          SessionFeedbackRow
        > {
  $$SessionFeedbacksTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PracticeSessionsTable _sessionIdTable(_$AppDatabase db) => db
      .practiceSessions
      .createAlias('session_feedbacks__session_id__practice_sessions__id');

  $$PracticeSessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<String>('session_id')!;

    final manager = $$PracticeSessionsTableTableManager(
      $_db,
      $_db.practiceSessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SessionFeedbacksTableFilterComposer
    extends Composer<_$AppDatabase, $SessionFeedbacksTable> {
  $$SessionFeedbacksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get receivedAt =>
      $composableBuilder(
        column: $table.receivedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  $$PracticeSessionsTableFilterComposer get sessionId {
    final $$PracticeSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.practiceSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PracticeSessionsTableFilterComposer(
            $db: $db,
            $table: $db.practiceSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SessionFeedbacksTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionFeedbacksTable> {
  $$SessionFeedbacksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$PracticeSessionsTableOrderingComposer get sessionId {
    final $$PracticeSessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.practiceSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PracticeSessionsTableOrderingComposer(
            $db: $db,
            $table: $db.practiceSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SessionFeedbacksTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionFeedbacksTable> {
  $$SessionFeedbacksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get receivedAt =>
      $composableBuilder(
        column: $table.receivedAt,
        builder: (column) => column,
      );

  $$PracticeSessionsTableAnnotationComposer get sessionId {
    final $$PracticeSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.practiceSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PracticeSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.practiceSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SessionFeedbacksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SessionFeedbacksTable,
          SessionFeedbackRow,
          $$SessionFeedbacksTableFilterComposer,
          $$SessionFeedbacksTableOrderingComposer,
          $$SessionFeedbacksTableAnnotationComposer,
          $$SessionFeedbacksTableCreateCompanionBuilder,
          $$SessionFeedbacksTableUpdateCompanionBuilder,
          (SessionFeedbackRow, $$SessionFeedbacksTableReferences),
          SessionFeedbackRow,
          PrefetchHooks Function({bool sessionId})
        > {
  $$SessionFeedbacksTableTableManager(
    _$AppDatabase db,
    $SessionFeedbacksTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionFeedbacksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionFeedbacksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionFeedbacksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> sessionId = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<DateTime> receivedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionFeedbacksCompanion(
                sessionId: sessionId,
                payload: payload,
                receivedAt: receivedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String sessionId,
                required String payload,
                required DateTime receivedAt,
                Value<int> rowid = const Value.absent(),
              }) => SessionFeedbacksCompanion.insert(
                sessionId: sessionId,
                payload: payload,
                receivedAt: receivedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SessionFeedbacksTable, SessionFeedbackRow>(
                    table,
                  ),
                  $$SessionFeedbacksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sessionId = false}) {
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
                    if (sessionId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.sessionId,
                        referencedTable: $$SessionFeedbacksTableReferences
                            ._sessionIdTable(db),
                        referencedColumn: $$SessionFeedbacksTableReferences
                            ._sessionIdTable(db)
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

typedef $$SessionFeedbacksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SessionFeedbacksTable,
      SessionFeedbackRow,
      $$SessionFeedbacksTableFilterComposer,
      $$SessionFeedbacksTableOrderingComposer,
      $$SessionFeedbacksTableAnnotationComposer,
      $$SessionFeedbacksTableCreateCompanionBuilder,
      $$SessionFeedbacksTableUpdateCompanionBuilder,
      (SessionFeedbackRow, $$SessionFeedbacksTableReferences),
      SessionFeedbackRow,
      PrefetchHooks Function({bool sessionId})
    >;
typedef $$SessionRecordingsTableCreateCompanionBuilder =
    SessionRecordingsCompanion Function({
      required String sessionId,
      required String fileName,
      required int durationMs,
      required DateTime recordedAt,
      Value<String?> transcript,
      Value<int> rowid,
    });
typedef $$SessionRecordingsTableUpdateCompanionBuilder =
    SessionRecordingsCompanion Function({
      Value<String> sessionId,
      Value<String> fileName,
      Value<int> durationMs,
      Value<DateTime> recordedAt,
      Value<String?> transcript,
      Value<int> rowid,
    });

final class $$SessionRecordingsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $SessionRecordingsTable,
          SessionRecordingRow
        > {
  $$SessionRecordingsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PracticeSessionsTable _sessionIdTable(_$AppDatabase db) => db
      .practiceSessions
      .createAlias('session_recordings__session_id__practice_sessions__id');

  $$PracticeSessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<String>('session_id')!;

    final manager = $$PracticeSessionsTableTableManager(
      $_db,
      $_db.practiceSessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SessionRecordingsTableFilterComposer
    extends Composer<_$AppDatabase, $SessionRecordingsTable> {
  $$SessionRecordingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get recordedAt =>
      $composableBuilder(
        column: $table.recordedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get transcript => $composableBuilder(
    column: $table.transcript,
    builder: (column) => ColumnFilters(column),
  );

  $$PracticeSessionsTableFilterComposer get sessionId {
    final $$PracticeSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.practiceSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PracticeSessionsTableFilterComposer(
            $db: $db,
            $table: $db.practiceSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SessionRecordingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionRecordingsTable> {
  $$SessionRecordingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transcript => $composableBuilder(
    column: $table.transcript,
    builder: (column) => ColumnOrderings(column),
  );

  $$PracticeSessionsTableOrderingComposer get sessionId {
    final $$PracticeSessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.practiceSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PracticeSessionsTableOrderingComposer(
            $db: $db,
            $table: $db.practiceSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SessionRecordingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionRecordingsTable> {
  $$SessionRecordingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DateTime, int> get recordedAt =>
      $composableBuilder(
        column: $table.recordedAt,
        builder: (column) => column,
      );

  GeneratedColumn<String> get transcript => $composableBuilder(
    column: $table.transcript,
    builder: (column) => column,
  );

  $$PracticeSessionsTableAnnotationComposer get sessionId {
    final $$PracticeSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.practiceSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PracticeSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.practiceSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SessionRecordingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SessionRecordingsTable,
          SessionRecordingRow,
          $$SessionRecordingsTableFilterComposer,
          $$SessionRecordingsTableOrderingComposer,
          $$SessionRecordingsTableAnnotationComposer,
          $$SessionRecordingsTableCreateCompanionBuilder,
          $$SessionRecordingsTableUpdateCompanionBuilder,
          (SessionRecordingRow, $$SessionRecordingsTableReferences),
          SessionRecordingRow,
          PrefetchHooks Function({bool sessionId})
        > {
  $$SessionRecordingsTableTableManager(
    _$AppDatabase db,
    $SessionRecordingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionRecordingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionRecordingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionRecordingsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> sessionId = const Value.absent(),
                Value<String> fileName = const Value.absent(),
                Value<int> durationMs = const Value.absent(),
                Value<DateTime> recordedAt = const Value.absent(),
                Value<String?> transcript = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionRecordingsCompanion(
                sessionId: sessionId,
                fileName: fileName,
                durationMs: durationMs,
                recordedAt: recordedAt,
                transcript: transcript,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String sessionId,
                required String fileName,
                required int durationMs,
                required DateTime recordedAt,
                Value<String?> transcript = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionRecordingsCompanion.insert(
                sessionId: sessionId,
                fileName: fileName,
                durationMs: durationMs,
                recordedAt: recordedAt,
                transcript: transcript,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SessionRecordingsTable, SessionRecordingRow>(
                    table,
                  ),
                  $$SessionRecordingsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sessionId = false}) {
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
                    if (sessionId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.sessionId,
                        referencedTable: $$SessionRecordingsTableReferences
                            ._sessionIdTable(db),
                        referencedColumn: $$SessionRecordingsTableReferences
                            ._sessionIdTable(db)
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

typedef $$SessionRecordingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SessionRecordingsTable,
      SessionRecordingRow,
      $$SessionRecordingsTableFilterComposer,
      $$SessionRecordingsTableOrderingComposer,
      $$SessionRecordingsTableAnnotationComposer,
      $$SessionRecordingsTableCreateCompanionBuilder,
      $$SessionRecordingsTableUpdateCompanionBuilder,
      (SessionRecordingRow, $$SessionRecordingsTableReferences),
      SessionRecordingRow,
      PrefetchHooks Function({bool sessionId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$PracticeSessionsTableTableManager get practiceSessions =>
      $$PracticeSessionsTableTableManager(_db, _db.practiceSessions);
  $$SessionFeedbacksTableTableManager get sessionFeedbacks =>
      $$SessionFeedbacksTableTableManager(_db, _db.sessionFeedbacks);
  $$SessionRecordingsTableTableManager get sessionRecordings =>
      $$SessionRecordingsTableTableManager(_db, _db.sessionRecordings);
}
