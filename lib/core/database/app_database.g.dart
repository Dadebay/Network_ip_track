// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $NetworksTable extends Networks with TableInfo<$NetworksTable, Network> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NetworksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _interfaceNameMeta = const VerificationMeta(
    'interfaceName',
  );
  @override
  late final GeneratedColumn<String> interfaceName = GeneratedColumn<String>(
    'interface_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cidrMeta = const VerificationMeta('cidr');
  @override
  late final GeneratedColumn<String> cidr = GeneratedColumn<String>(
    'cidr',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gatewayIpMeta = const VerificationMeta(
    'gatewayIp',
  );
  @override
  late final GeneratedColumn<String> gatewayIp = GeneratedColumn<String>(
    'gateway_ip',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _firstSeenAtMeta = const VerificationMeta(
    'firstSeenAt',
  );
  @override
  late final GeneratedColumn<DateTime> firstSeenAt = GeneratedColumn<DateTime>(
    'first_seen_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastSeenAtMeta = const VerificationMeta(
    'lastSeenAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSeenAt = GeneratedColumn<DateTime>(
    'last_seen_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    interfaceName,
    displayName,
    cidr,
    gatewayIp,
    firstSeenAt,
    lastSeenAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'networks';
  @override
  VerificationContext validateIntegrity(
    Insertable<Network> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('interface_name')) {
      context.handle(
        _interfaceNameMeta,
        interfaceName.isAcceptableOrUnknown(
          data['interface_name']!,
          _interfaceNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_interfaceNameMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('cidr')) {
      context.handle(
        _cidrMeta,
        cidr.isAcceptableOrUnknown(data['cidr']!, _cidrMeta),
      );
    } else if (isInserting) {
      context.missing(_cidrMeta);
    }
    if (data.containsKey('gateway_ip')) {
      context.handle(
        _gatewayIpMeta,
        gatewayIp.isAcceptableOrUnknown(data['gateway_ip']!, _gatewayIpMeta),
      );
    }
    if (data.containsKey('first_seen_at')) {
      context.handle(
        _firstSeenAtMeta,
        firstSeenAt.isAcceptableOrUnknown(
          data['first_seen_at']!,
          _firstSeenAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_firstSeenAtMeta);
    }
    if (data.containsKey('last_seen_at')) {
      context.handle(
        _lastSeenAtMeta,
        lastSeenAt.isAcceptableOrUnknown(
          data['last_seen_at']!,
          _lastSeenAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastSeenAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Network map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Network(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      interfaceName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}interface_name'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      cidr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cidr'],
      )!,
      gatewayIp: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gateway_ip'],
      ),
      firstSeenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}first_seen_at'],
      )!,
      lastSeenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_seen_at'],
      )!,
    );
  }

  @override
  $NetworksTable createAlias(String alias) {
    return $NetworksTable(attachedDatabase, alias);
  }
}

class Network extends DataClass implements Insertable<Network> {
  final int id;
  final String interfaceName;
  final String displayName;
  final String cidr;
  final String? gatewayIp;
  final DateTime firstSeenAt;
  final DateTime lastSeenAt;
  const Network({
    required this.id,
    required this.interfaceName,
    required this.displayName,
    required this.cidr,
    this.gatewayIp,
    required this.firstSeenAt,
    required this.lastSeenAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['interface_name'] = Variable<String>(interfaceName);
    map['display_name'] = Variable<String>(displayName);
    map['cidr'] = Variable<String>(cidr);
    if (!nullToAbsent || gatewayIp != null) {
      map['gateway_ip'] = Variable<String>(gatewayIp);
    }
    map['first_seen_at'] = Variable<DateTime>(firstSeenAt);
    map['last_seen_at'] = Variable<DateTime>(lastSeenAt);
    return map;
  }

  NetworksCompanion toCompanion(bool nullToAbsent) {
    return NetworksCompanion(
      id: Value(id),
      interfaceName: Value(interfaceName),
      displayName: Value(displayName),
      cidr: Value(cidr),
      gatewayIp: gatewayIp == null && nullToAbsent
          ? const Value.absent()
          : Value(gatewayIp),
      firstSeenAt: Value(firstSeenAt),
      lastSeenAt: Value(lastSeenAt),
    );
  }

  factory Network.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Network(
      id: serializer.fromJson<int>(json['id']),
      interfaceName: serializer.fromJson<String>(json['interfaceName']),
      displayName: serializer.fromJson<String>(json['displayName']),
      cidr: serializer.fromJson<String>(json['cidr']),
      gatewayIp: serializer.fromJson<String?>(json['gatewayIp']),
      firstSeenAt: serializer.fromJson<DateTime>(json['firstSeenAt']),
      lastSeenAt: serializer.fromJson<DateTime>(json['lastSeenAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'interfaceName': serializer.toJson<String>(interfaceName),
      'displayName': serializer.toJson<String>(displayName),
      'cidr': serializer.toJson<String>(cidr),
      'gatewayIp': serializer.toJson<String?>(gatewayIp),
      'firstSeenAt': serializer.toJson<DateTime>(firstSeenAt),
      'lastSeenAt': serializer.toJson<DateTime>(lastSeenAt),
    };
  }

  Network copyWith({
    int? id,
    String? interfaceName,
    String? displayName,
    String? cidr,
    Value<String?> gatewayIp = const Value.absent(),
    DateTime? firstSeenAt,
    DateTime? lastSeenAt,
  }) => Network(
    id: id ?? this.id,
    interfaceName: interfaceName ?? this.interfaceName,
    displayName: displayName ?? this.displayName,
    cidr: cidr ?? this.cidr,
    gatewayIp: gatewayIp.present ? gatewayIp.value : this.gatewayIp,
    firstSeenAt: firstSeenAt ?? this.firstSeenAt,
    lastSeenAt: lastSeenAt ?? this.lastSeenAt,
  );
  Network copyWithCompanion(NetworksCompanion data) {
    return Network(
      id: data.id.present ? data.id.value : this.id,
      interfaceName: data.interfaceName.present
          ? data.interfaceName.value
          : this.interfaceName,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      cidr: data.cidr.present ? data.cidr.value : this.cidr,
      gatewayIp: data.gatewayIp.present ? data.gatewayIp.value : this.gatewayIp,
      firstSeenAt: data.firstSeenAt.present
          ? data.firstSeenAt.value
          : this.firstSeenAt,
      lastSeenAt: data.lastSeenAt.present
          ? data.lastSeenAt.value
          : this.lastSeenAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Network(')
          ..write('id: $id, ')
          ..write('interfaceName: $interfaceName, ')
          ..write('displayName: $displayName, ')
          ..write('cidr: $cidr, ')
          ..write('gatewayIp: $gatewayIp, ')
          ..write('firstSeenAt: $firstSeenAt, ')
          ..write('lastSeenAt: $lastSeenAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    interfaceName,
    displayName,
    cidr,
    gatewayIp,
    firstSeenAt,
    lastSeenAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Network &&
          other.id == this.id &&
          other.interfaceName == this.interfaceName &&
          other.displayName == this.displayName &&
          other.cidr == this.cidr &&
          other.gatewayIp == this.gatewayIp &&
          other.firstSeenAt == this.firstSeenAt &&
          other.lastSeenAt == this.lastSeenAt);
}

class NetworksCompanion extends UpdateCompanion<Network> {
  final Value<int> id;
  final Value<String> interfaceName;
  final Value<String> displayName;
  final Value<String> cidr;
  final Value<String?> gatewayIp;
  final Value<DateTime> firstSeenAt;
  final Value<DateTime> lastSeenAt;
  const NetworksCompanion({
    this.id = const Value.absent(),
    this.interfaceName = const Value.absent(),
    this.displayName = const Value.absent(),
    this.cidr = const Value.absent(),
    this.gatewayIp = const Value.absent(),
    this.firstSeenAt = const Value.absent(),
    this.lastSeenAt = const Value.absent(),
  });
  NetworksCompanion.insert({
    this.id = const Value.absent(),
    required String interfaceName,
    required String displayName,
    required String cidr,
    this.gatewayIp = const Value.absent(),
    required DateTime firstSeenAt,
    required DateTime lastSeenAt,
  }) : interfaceName = Value(interfaceName),
       displayName = Value(displayName),
       cidr = Value(cidr),
       firstSeenAt = Value(firstSeenAt),
       lastSeenAt = Value(lastSeenAt);
  static Insertable<Network> custom({
    Expression<int>? id,
    Expression<String>? interfaceName,
    Expression<String>? displayName,
    Expression<String>? cidr,
    Expression<String>? gatewayIp,
    Expression<DateTime>? firstSeenAt,
    Expression<DateTime>? lastSeenAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (interfaceName != null) 'interface_name': interfaceName,
      if (displayName != null) 'display_name': displayName,
      if (cidr != null) 'cidr': cidr,
      if (gatewayIp != null) 'gateway_ip': gatewayIp,
      if (firstSeenAt != null) 'first_seen_at': firstSeenAt,
      if (lastSeenAt != null) 'last_seen_at': lastSeenAt,
    });
  }

  NetworksCompanion copyWith({
    Value<int>? id,
    Value<String>? interfaceName,
    Value<String>? displayName,
    Value<String>? cidr,
    Value<String?>? gatewayIp,
    Value<DateTime>? firstSeenAt,
    Value<DateTime>? lastSeenAt,
  }) {
    return NetworksCompanion(
      id: id ?? this.id,
      interfaceName: interfaceName ?? this.interfaceName,
      displayName: displayName ?? this.displayName,
      cidr: cidr ?? this.cidr,
      gatewayIp: gatewayIp ?? this.gatewayIp,
      firstSeenAt: firstSeenAt ?? this.firstSeenAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (interfaceName.present) {
      map['interface_name'] = Variable<String>(interfaceName.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (cidr.present) {
      map['cidr'] = Variable<String>(cidr.value);
    }
    if (gatewayIp.present) {
      map['gateway_ip'] = Variable<String>(gatewayIp.value);
    }
    if (firstSeenAt.present) {
      map['first_seen_at'] = Variable<DateTime>(firstSeenAt.value);
    }
    if (lastSeenAt.present) {
      map['last_seen_at'] = Variable<DateTime>(lastSeenAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NetworksCompanion(')
          ..write('id: $id, ')
          ..write('interfaceName: $interfaceName, ')
          ..write('displayName: $displayName, ')
          ..write('cidr: $cidr, ')
          ..write('gatewayIp: $gatewayIp, ')
          ..write('firstSeenAt: $firstSeenAt, ')
          ..write('lastSeenAt: $lastSeenAt')
          ..write(')'))
        .toString();
  }
}

class $DevicesTable extends Devices with TableInfo<$DevicesTable, Device> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DevicesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _networkIdMeta = const VerificationMeta(
    'networkId',
  );
  @override
  late final GeneratedColumn<int> networkId = GeneratedColumn<int>(
    'network_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES networks (id)',
    ),
  );
  static const VerificationMeta _macAddressMeta = const VerificationMeta(
    'macAddress',
  );
  @override
  late final GeneratedColumn<String> macAddress = GeneratedColumn<String>(
    'mac_address',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _currentIpMeta = const VerificationMeta(
    'currentIp',
  );
  @override
  late final GeneratedColumn<String> currentIp = GeneratedColumn<String>(
    'current_ip',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hostnameMeta = const VerificationMeta(
    'hostname',
  );
  @override
  late final GeneratedColumn<String> hostname = GeneratedColumn<String>(
    'hostname',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _vendorMeta = const VerificationMeta('vendor');
  @override
  late final GeneratedColumn<String> vendor = GeneratedColumn<String>(
    'vendor',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _inferredTypeMeta = const VerificationMeta(
    'inferredType',
  );
  @override
  late final GeneratedColumn<String> inferredType = GeneratedColumn<String>(
    'inferred_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _inferredOsMeta = const VerificationMeta(
    'inferredOs',
  );
  @override
  late final GeneratedColumn<String> inferredOs = GeneratedColumn<String>(
    'inferred_os',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _confidenceMeta = const VerificationMeta(
    'confidence',
  );
  @override
  late final GeneratedColumn<String> confidence = GeneratedColumn<String>(
    'confidence',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _osConfidenceMeta = const VerificationMeta(
    'osConfidence',
  );
  @override
  late final GeneratedColumn<String> osConfidence = GeneratedColumn<String>(
    'os_confidence',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _inferenceReasonsJsonMeta =
      const VerificationMeta('inferenceReasonsJson');
  @override
  late final GeneratedColumn<String> inferenceReasonsJson =
      GeneratedColumn<String>(
        'inference_reasons_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      );
  static const VerificationMeta _customNameMeta = const VerificationMeta(
    'customName',
  );
  @override
  late final GeneratedColumn<String> customName = GeneratedColumn<String>(
    'custom_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _customDeviceTypeMeta = const VerificationMeta(
    'customDeviceType',
  );
  @override
  late final GeneratedColumn<String> customDeviceType = GeneratedColumn<String>(
    'custom_type',
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
  static const VerificationMeta _isKnownMeta = const VerificationMeta(
    'isKnown',
  );
  @override
  late final GeneratedColumn<bool> isKnown = GeneratedColumn<bool>(
    'is_known',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_known" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _pingConfirmedMeta = const VerificationMeta(
    'pingConfirmed',
  );
  @override
  late final GeneratedColumn<bool> pingConfirmed = GeneratedColumn<bool>(
    'ping_confirmed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("ping_confirmed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isGatewayMeta = const VerificationMeta(
    'isGateway',
  );
  @override
  late final GeneratedColumn<bool> isGateway = GeneratedColumn<bool>(
    'is_gateway',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_gateway" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isLocalDeviceMeta = const VerificationMeta(
    'isLocalDevice',
  );
  @override
  late final GeneratedColumn<bool> isLocalDevice = GeneratedColumn<bool>(
    'is_local_device',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_local_device" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _firstSeenAtMeta = const VerificationMeta(
    'firstSeenAt',
  );
  @override
  late final GeneratedColumn<DateTime> firstSeenAt = GeneratedColumn<DateTime>(
    'first_seen_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastSeenAtMeta = const VerificationMeta(
    'lastSeenAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSeenAt = GeneratedColumn<DateTime>(
    'last_seen_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    networkId,
    macAddress,
    currentIp,
    hostname,
    vendor,
    inferredType,
    inferredOs,
    confidence,
    osConfidence,
    inferenceReasonsJson,
    customName,
    customDeviceType,
    note,
    isKnown,
    pingConfirmed,
    isGateway,
    isLocalDevice,
    firstSeenAt,
    lastSeenAt,
    status,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'devices';
  @override
  VerificationContext validateIntegrity(
    Insertable<Device> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('network_id')) {
      context.handle(
        _networkIdMeta,
        networkId.isAcceptableOrUnknown(data['network_id']!, _networkIdMeta),
      );
    } else if (isInserting) {
      context.missing(_networkIdMeta);
    }
    if (data.containsKey('mac_address')) {
      context.handle(
        _macAddressMeta,
        macAddress.isAcceptableOrUnknown(data['mac_address']!, _macAddressMeta),
      );
    }
    if (data.containsKey('current_ip')) {
      context.handle(
        _currentIpMeta,
        currentIp.isAcceptableOrUnknown(data['current_ip']!, _currentIpMeta),
      );
    } else if (isInserting) {
      context.missing(_currentIpMeta);
    }
    if (data.containsKey('hostname')) {
      context.handle(
        _hostnameMeta,
        hostname.isAcceptableOrUnknown(data['hostname']!, _hostnameMeta),
      );
    }
    if (data.containsKey('vendor')) {
      context.handle(
        _vendorMeta,
        vendor.isAcceptableOrUnknown(data['vendor']!, _vendorMeta),
      );
    }
    if (data.containsKey('inferred_type')) {
      context.handle(
        _inferredTypeMeta,
        inferredType.isAcceptableOrUnknown(
          data['inferred_type']!,
          _inferredTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_inferredTypeMeta);
    }
    if (data.containsKey('inferred_os')) {
      context.handle(
        _inferredOsMeta,
        inferredOs.isAcceptableOrUnknown(data['inferred_os']!, _inferredOsMeta),
      );
    }
    if (data.containsKey('confidence')) {
      context.handle(
        _confidenceMeta,
        confidence.isAcceptableOrUnknown(data['confidence']!, _confidenceMeta),
      );
    } else if (isInserting) {
      context.missing(_confidenceMeta);
    }
    if (data.containsKey('os_confidence')) {
      context.handle(
        _osConfidenceMeta,
        osConfidence.isAcceptableOrUnknown(
          data['os_confidence']!,
          _osConfidenceMeta,
        ),
      );
    }
    if (data.containsKey('inference_reasons_json')) {
      context.handle(
        _inferenceReasonsJsonMeta,
        inferenceReasonsJson.isAcceptableOrUnknown(
          data['inference_reasons_json']!,
          _inferenceReasonsJsonMeta,
        ),
      );
    }
    if (data.containsKey('custom_name')) {
      context.handle(
        _customNameMeta,
        customName.isAcceptableOrUnknown(data['custom_name']!, _customNameMeta),
      );
    }
    if (data.containsKey('custom_type')) {
      context.handle(
        _customDeviceTypeMeta,
        customDeviceType.isAcceptableOrUnknown(
          data['custom_type']!,
          _customDeviceTypeMeta,
        ),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('is_known')) {
      context.handle(
        _isKnownMeta,
        isKnown.isAcceptableOrUnknown(data['is_known']!, _isKnownMeta),
      );
    }
    if (data.containsKey('ping_confirmed')) {
      context.handle(
        _pingConfirmedMeta,
        pingConfirmed.isAcceptableOrUnknown(
          data['ping_confirmed']!,
          _pingConfirmedMeta,
        ),
      );
    }
    if (data.containsKey('is_gateway')) {
      context.handle(
        _isGatewayMeta,
        isGateway.isAcceptableOrUnknown(data['is_gateway']!, _isGatewayMeta),
      );
    }
    if (data.containsKey('is_local_device')) {
      context.handle(
        _isLocalDeviceMeta,
        isLocalDevice.isAcceptableOrUnknown(
          data['is_local_device']!,
          _isLocalDeviceMeta,
        ),
      );
    }
    if (data.containsKey('first_seen_at')) {
      context.handle(
        _firstSeenAtMeta,
        firstSeenAt.isAcceptableOrUnknown(
          data['first_seen_at']!,
          _firstSeenAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_firstSeenAtMeta);
    }
    if (data.containsKey('last_seen_at')) {
      context.handle(
        _lastSeenAtMeta,
        lastSeenAt.isAcceptableOrUnknown(
          data['last_seen_at']!,
          _lastSeenAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastSeenAtMeta);
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
  Device map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Device(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      networkId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}network_id'],
      )!,
      macAddress: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mac_address'],
      ),
      currentIp: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}current_ip'],
      )!,
      hostname: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hostname'],
      ),
      vendor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vendor'],
      ),
      inferredType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}inferred_type'],
      )!,
      inferredOs: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}inferred_os'],
      ),
      confidence: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}confidence'],
      )!,
      osConfidence: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}os_confidence'],
      ),
      inferenceReasonsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}inference_reasons_json'],
      )!,
      customName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}custom_name'],
      ),
      customDeviceType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}custom_type'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      isKnown: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_known'],
      )!,
      pingConfirmed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}ping_confirmed'],
      )!,
      isGateway: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_gateway'],
      )!,
      isLocalDevice: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_local_device'],
      )!,
      firstSeenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}first_seen_at'],
      )!,
      lastSeenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_seen_at'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
    );
  }

  @override
  $DevicesTable createAlias(String alias) {
    return $DevicesTable(attachedDatabase, alias);
  }
}

class Device extends DataClass implements Insertable<Device> {
  final int id;
  final int networkId;
  final String? macAddress;
  final String currentIp;
  final String? hostname;
  final String? vendor;
  final String inferredType;
  final String? inferredOs;
  final String confidence;

  /// Confidence of [inferredOs] alone (schema v3) — the OS can be backed by
  /// weaker evidence than the device type.
  final String? osConfidence;

  /// Human-readable reasons behind the current inference (schema v3).
  final String inferenceReasonsJson;
  final String? customName;
  final String? customDeviceType;
  final String? note;

  /// "Bu cihazı tanıyorum" (schema v3).
  final bool isKnown;

  /// True once an ICMP echo reply has ever been seen from this IP (schema
  /// v4). Sticky — never reset to false — because it's a strong, hard-to-
  /// spoof liveness signal: on networks where a middlebox answers every TCP
  /// connect attempt (see `signals_json`/port-probe false positives), this
  /// is what actually distinguishes a real host from noise.
  final bool pingConfirmed;
  final bool isGateway;
  final bool isLocalDevice;
  final DateTime firstSeenAt;
  final DateTime lastSeenAt;
  final String status;
  const Device({
    required this.id,
    required this.networkId,
    this.macAddress,
    required this.currentIp,
    this.hostname,
    this.vendor,
    required this.inferredType,
    this.inferredOs,
    required this.confidence,
    this.osConfidence,
    required this.inferenceReasonsJson,
    this.customName,
    this.customDeviceType,
    this.note,
    required this.isKnown,
    required this.pingConfirmed,
    required this.isGateway,
    required this.isLocalDevice,
    required this.firstSeenAt,
    required this.lastSeenAt,
    required this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['network_id'] = Variable<int>(networkId);
    if (!nullToAbsent || macAddress != null) {
      map['mac_address'] = Variable<String>(macAddress);
    }
    map['current_ip'] = Variable<String>(currentIp);
    if (!nullToAbsent || hostname != null) {
      map['hostname'] = Variable<String>(hostname);
    }
    if (!nullToAbsent || vendor != null) {
      map['vendor'] = Variable<String>(vendor);
    }
    map['inferred_type'] = Variable<String>(inferredType);
    if (!nullToAbsent || inferredOs != null) {
      map['inferred_os'] = Variable<String>(inferredOs);
    }
    map['confidence'] = Variable<String>(confidence);
    if (!nullToAbsent || osConfidence != null) {
      map['os_confidence'] = Variable<String>(osConfidence);
    }
    map['inference_reasons_json'] = Variable<String>(inferenceReasonsJson);
    if (!nullToAbsent || customName != null) {
      map['custom_name'] = Variable<String>(customName);
    }
    if (!nullToAbsent || customDeviceType != null) {
      map['custom_type'] = Variable<String>(customDeviceType);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['is_known'] = Variable<bool>(isKnown);
    map['ping_confirmed'] = Variable<bool>(pingConfirmed);
    map['is_gateway'] = Variable<bool>(isGateway);
    map['is_local_device'] = Variable<bool>(isLocalDevice);
    map['first_seen_at'] = Variable<DateTime>(firstSeenAt);
    map['last_seen_at'] = Variable<DateTime>(lastSeenAt);
    map['status'] = Variable<String>(status);
    return map;
  }

  DevicesCompanion toCompanion(bool nullToAbsent) {
    return DevicesCompanion(
      id: Value(id),
      networkId: Value(networkId),
      macAddress: macAddress == null && nullToAbsent
          ? const Value.absent()
          : Value(macAddress),
      currentIp: Value(currentIp),
      hostname: hostname == null && nullToAbsent
          ? const Value.absent()
          : Value(hostname),
      vendor: vendor == null && nullToAbsent
          ? const Value.absent()
          : Value(vendor),
      inferredType: Value(inferredType),
      inferredOs: inferredOs == null && nullToAbsent
          ? const Value.absent()
          : Value(inferredOs),
      confidence: Value(confidence),
      osConfidence: osConfidence == null && nullToAbsent
          ? const Value.absent()
          : Value(osConfidence),
      inferenceReasonsJson: Value(inferenceReasonsJson),
      customName: customName == null && nullToAbsent
          ? const Value.absent()
          : Value(customName),
      customDeviceType: customDeviceType == null && nullToAbsent
          ? const Value.absent()
          : Value(customDeviceType),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      isKnown: Value(isKnown),
      pingConfirmed: Value(pingConfirmed),
      isGateway: Value(isGateway),
      isLocalDevice: Value(isLocalDevice),
      firstSeenAt: Value(firstSeenAt),
      lastSeenAt: Value(lastSeenAt),
      status: Value(status),
    );
  }

  factory Device.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Device(
      id: serializer.fromJson<int>(json['id']),
      networkId: serializer.fromJson<int>(json['networkId']),
      macAddress: serializer.fromJson<String?>(json['macAddress']),
      currentIp: serializer.fromJson<String>(json['currentIp']),
      hostname: serializer.fromJson<String?>(json['hostname']),
      vendor: serializer.fromJson<String?>(json['vendor']),
      inferredType: serializer.fromJson<String>(json['inferredType']),
      inferredOs: serializer.fromJson<String?>(json['inferredOs']),
      confidence: serializer.fromJson<String>(json['confidence']),
      osConfidence: serializer.fromJson<String?>(json['osConfidence']),
      inferenceReasonsJson: serializer.fromJson<String>(
        json['inferenceReasonsJson'],
      ),
      customName: serializer.fromJson<String?>(json['customName']),
      customDeviceType: serializer.fromJson<String?>(json['customDeviceType']),
      note: serializer.fromJson<String?>(json['note']),
      isKnown: serializer.fromJson<bool>(json['isKnown']),
      pingConfirmed: serializer.fromJson<bool>(json['pingConfirmed']),
      isGateway: serializer.fromJson<bool>(json['isGateway']),
      isLocalDevice: serializer.fromJson<bool>(json['isLocalDevice']),
      firstSeenAt: serializer.fromJson<DateTime>(json['firstSeenAt']),
      lastSeenAt: serializer.fromJson<DateTime>(json['lastSeenAt']),
      status: serializer.fromJson<String>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'networkId': serializer.toJson<int>(networkId),
      'macAddress': serializer.toJson<String?>(macAddress),
      'currentIp': serializer.toJson<String>(currentIp),
      'hostname': serializer.toJson<String?>(hostname),
      'vendor': serializer.toJson<String?>(vendor),
      'inferredType': serializer.toJson<String>(inferredType),
      'inferredOs': serializer.toJson<String?>(inferredOs),
      'confidence': serializer.toJson<String>(confidence),
      'osConfidence': serializer.toJson<String?>(osConfidence),
      'inferenceReasonsJson': serializer.toJson<String>(inferenceReasonsJson),
      'customName': serializer.toJson<String?>(customName),
      'customDeviceType': serializer.toJson<String?>(customDeviceType),
      'note': serializer.toJson<String?>(note),
      'isKnown': serializer.toJson<bool>(isKnown),
      'pingConfirmed': serializer.toJson<bool>(pingConfirmed),
      'isGateway': serializer.toJson<bool>(isGateway),
      'isLocalDevice': serializer.toJson<bool>(isLocalDevice),
      'firstSeenAt': serializer.toJson<DateTime>(firstSeenAt),
      'lastSeenAt': serializer.toJson<DateTime>(lastSeenAt),
      'status': serializer.toJson<String>(status),
    };
  }

  Device copyWith({
    int? id,
    int? networkId,
    Value<String?> macAddress = const Value.absent(),
    String? currentIp,
    Value<String?> hostname = const Value.absent(),
    Value<String?> vendor = const Value.absent(),
    String? inferredType,
    Value<String?> inferredOs = const Value.absent(),
    String? confidence,
    Value<String?> osConfidence = const Value.absent(),
    String? inferenceReasonsJson,
    Value<String?> customName = const Value.absent(),
    Value<String?> customDeviceType = const Value.absent(),
    Value<String?> note = const Value.absent(),
    bool? isKnown,
    bool? pingConfirmed,
    bool? isGateway,
    bool? isLocalDevice,
    DateTime? firstSeenAt,
    DateTime? lastSeenAt,
    String? status,
  }) => Device(
    id: id ?? this.id,
    networkId: networkId ?? this.networkId,
    macAddress: macAddress.present ? macAddress.value : this.macAddress,
    currentIp: currentIp ?? this.currentIp,
    hostname: hostname.present ? hostname.value : this.hostname,
    vendor: vendor.present ? vendor.value : this.vendor,
    inferredType: inferredType ?? this.inferredType,
    inferredOs: inferredOs.present ? inferredOs.value : this.inferredOs,
    confidence: confidence ?? this.confidence,
    osConfidence: osConfidence.present ? osConfidence.value : this.osConfidence,
    inferenceReasonsJson: inferenceReasonsJson ?? this.inferenceReasonsJson,
    customName: customName.present ? customName.value : this.customName,
    customDeviceType: customDeviceType.present
        ? customDeviceType.value
        : this.customDeviceType,
    note: note.present ? note.value : this.note,
    isKnown: isKnown ?? this.isKnown,
    pingConfirmed: pingConfirmed ?? this.pingConfirmed,
    isGateway: isGateway ?? this.isGateway,
    isLocalDevice: isLocalDevice ?? this.isLocalDevice,
    firstSeenAt: firstSeenAt ?? this.firstSeenAt,
    lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    status: status ?? this.status,
  );
  Device copyWithCompanion(DevicesCompanion data) {
    return Device(
      id: data.id.present ? data.id.value : this.id,
      networkId: data.networkId.present ? data.networkId.value : this.networkId,
      macAddress: data.macAddress.present
          ? data.macAddress.value
          : this.macAddress,
      currentIp: data.currentIp.present ? data.currentIp.value : this.currentIp,
      hostname: data.hostname.present ? data.hostname.value : this.hostname,
      vendor: data.vendor.present ? data.vendor.value : this.vendor,
      inferredType: data.inferredType.present
          ? data.inferredType.value
          : this.inferredType,
      inferredOs: data.inferredOs.present
          ? data.inferredOs.value
          : this.inferredOs,
      confidence: data.confidence.present
          ? data.confidence.value
          : this.confidence,
      osConfidence: data.osConfidence.present
          ? data.osConfidence.value
          : this.osConfidence,
      inferenceReasonsJson: data.inferenceReasonsJson.present
          ? data.inferenceReasonsJson.value
          : this.inferenceReasonsJson,
      customName: data.customName.present
          ? data.customName.value
          : this.customName,
      customDeviceType: data.customDeviceType.present
          ? data.customDeviceType.value
          : this.customDeviceType,
      note: data.note.present ? data.note.value : this.note,
      isKnown: data.isKnown.present ? data.isKnown.value : this.isKnown,
      pingConfirmed: data.pingConfirmed.present
          ? data.pingConfirmed.value
          : this.pingConfirmed,
      isGateway: data.isGateway.present ? data.isGateway.value : this.isGateway,
      isLocalDevice: data.isLocalDevice.present
          ? data.isLocalDevice.value
          : this.isLocalDevice,
      firstSeenAt: data.firstSeenAt.present
          ? data.firstSeenAt.value
          : this.firstSeenAt,
      lastSeenAt: data.lastSeenAt.present
          ? data.lastSeenAt.value
          : this.lastSeenAt,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Device(')
          ..write('id: $id, ')
          ..write('networkId: $networkId, ')
          ..write('macAddress: $macAddress, ')
          ..write('currentIp: $currentIp, ')
          ..write('hostname: $hostname, ')
          ..write('vendor: $vendor, ')
          ..write('inferredType: $inferredType, ')
          ..write('inferredOs: $inferredOs, ')
          ..write('confidence: $confidence, ')
          ..write('osConfidence: $osConfidence, ')
          ..write('inferenceReasonsJson: $inferenceReasonsJson, ')
          ..write('customName: $customName, ')
          ..write('customDeviceType: $customDeviceType, ')
          ..write('note: $note, ')
          ..write('isKnown: $isKnown, ')
          ..write('pingConfirmed: $pingConfirmed, ')
          ..write('isGateway: $isGateway, ')
          ..write('isLocalDevice: $isLocalDevice, ')
          ..write('firstSeenAt: $firstSeenAt, ')
          ..write('lastSeenAt: $lastSeenAt, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    networkId,
    macAddress,
    currentIp,
    hostname,
    vendor,
    inferredType,
    inferredOs,
    confidence,
    osConfidence,
    inferenceReasonsJson,
    customName,
    customDeviceType,
    note,
    isKnown,
    pingConfirmed,
    isGateway,
    isLocalDevice,
    firstSeenAt,
    lastSeenAt,
    status,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Device &&
          other.id == this.id &&
          other.networkId == this.networkId &&
          other.macAddress == this.macAddress &&
          other.currentIp == this.currentIp &&
          other.hostname == this.hostname &&
          other.vendor == this.vendor &&
          other.inferredType == this.inferredType &&
          other.inferredOs == this.inferredOs &&
          other.confidence == this.confidence &&
          other.osConfidence == this.osConfidence &&
          other.inferenceReasonsJson == this.inferenceReasonsJson &&
          other.customName == this.customName &&
          other.customDeviceType == this.customDeviceType &&
          other.note == this.note &&
          other.isKnown == this.isKnown &&
          other.pingConfirmed == this.pingConfirmed &&
          other.isGateway == this.isGateway &&
          other.isLocalDevice == this.isLocalDevice &&
          other.firstSeenAt == this.firstSeenAt &&
          other.lastSeenAt == this.lastSeenAt &&
          other.status == this.status);
}

class DevicesCompanion extends UpdateCompanion<Device> {
  final Value<int> id;
  final Value<int> networkId;
  final Value<String?> macAddress;
  final Value<String> currentIp;
  final Value<String?> hostname;
  final Value<String?> vendor;
  final Value<String> inferredType;
  final Value<String?> inferredOs;
  final Value<String> confidence;
  final Value<String?> osConfidence;
  final Value<String> inferenceReasonsJson;
  final Value<String?> customName;
  final Value<String?> customDeviceType;
  final Value<String?> note;
  final Value<bool> isKnown;
  final Value<bool> pingConfirmed;
  final Value<bool> isGateway;
  final Value<bool> isLocalDevice;
  final Value<DateTime> firstSeenAt;
  final Value<DateTime> lastSeenAt;
  final Value<String> status;
  const DevicesCompanion({
    this.id = const Value.absent(),
    this.networkId = const Value.absent(),
    this.macAddress = const Value.absent(),
    this.currentIp = const Value.absent(),
    this.hostname = const Value.absent(),
    this.vendor = const Value.absent(),
    this.inferredType = const Value.absent(),
    this.inferredOs = const Value.absent(),
    this.confidence = const Value.absent(),
    this.osConfidence = const Value.absent(),
    this.inferenceReasonsJson = const Value.absent(),
    this.customName = const Value.absent(),
    this.customDeviceType = const Value.absent(),
    this.note = const Value.absent(),
    this.isKnown = const Value.absent(),
    this.pingConfirmed = const Value.absent(),
    this.isGateway = const Value.absent(),
    this.isLocalDevice = const Value.absent(),
    this.firstSeenAt = const Value.absent(),
    this.lastSeenAt = const Value.absent(),
    this.status = const Value.absent(),
  });
  DevicesCompanion.insert({
    this.id = const Value.absent(),
    required int networkId,
    this.macAddress = const Value.absent(),
    required String currentIp,
    this.hostname = const Value.absent(),
    this.vendor = const Value.absent(),
    required String inferredType,
    this.inferredOs = const Value.absent(),
    required String confidence,
    this.osConfidence = const Value.absent(),
    this.inferenceReasonsJson = const Value.absent(),
    this.customName = const Value.absent(),
    this.customDeviceType = const Value.absent(),
    this.note = const Value.absent(),
    this.isKnown = const Value.absent(),
    this.pingConfirmed = const Value.absent(),
    this.isGateway = const Value.absent(),
    this.isLocalDevice = const Value.absent(),
    required DateTime firstSeenAt,
    required DateTime lastSeenAt,
    required String status,
  }) : networkId = Value(networkId),
       currentIp = Value(currentIp),
       inferredType = Value(inferredType),
       confidence = Value(confidence),
       firstSeenAt = Value(firstSeenAt),
       lastSeenAt = Value(lastSeenAt),
       status = Value(status);
  static Insertable<Device> custom({
    Expression<int>? id,
    Expression<int>? networkId,
    Expression<String>? macAddress,
    Expression<String>? currentIp,
    Expression<String>? hostname,
    Expression<String>? vendor,
    Expression<String>? inferredType,
    Expression<String>? inferredOs,
    Expression<String>? confidence,
    Expression<String>? osConfidence,
    Expression<String>? inferenceReasonsJson,
    Expression<String>? customName,
    Expression<String>? customDeviceType,
    Expression<String>? note,
    Expression<bool>? isKnown,
    Expression<bool>? pingConfirmed,
    Expression<bool>? isGateway,
    Expression<bool>? isLocalDevice,
    Expression<DateTime>? firstSeenAt,
    Expression<DateTime>? lastSeenAt,
    Expression<String>? status,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (networkId != null) 'network_id': networkId,
      if (macAddress != null) 'mac_address': macAddress,
      if (currentIp != null) 'current_ip': currentIp,
      if (hostname != null) 'hostname': hostname,
      if (vendor != null) 'vendor': vendor,
      if (inferredType != null) 'inferred_type': inferredType,
      if (inferredOs != null) 'inferred_os': inferredOs,
      if (confidence != null) 'confidence': confidence,
      if (osConfidence != null) 'os_confidence': osConfidence,
      if (inferenceReasonsJson != null)
        'inference_reasons_json': inferenceReasonsJson,
      if (customName != null) 'custom_name': customName,
      if (customDeviceType != null) 'custom_type': customDeviceType,
      if (note != null) 'note': note,
      if (isKnown != null) 'is_known': isKnown,
      if (pingConfirmed != null) 'ping_confirmed': pingConfirmed,
      if (isGateway != null) 'is_gateway': isGateway,
      if (isLocalDevice != null) 'is_local_device': isLocalDevice,
      if (firstSeenAt != null) 'first_seen_at': firstSeenAt,
      if (lastSeenAt != null) 'last_seen_at': lastSeenAt,
      if (status != null) 'status': status,
    });
  }

  DevicesCompanion copyWith({
    Value<int>? id,
    Value<int>? networkId,
    Value<String?>? macAddress,
    Value<String>? currentIp,
    Value<String?>? hostname,
    Value<String?>? vendor,
    Value<String>? inferredType,
    Value<String?>? inferredOs,
    Value<String>? confidence,
    Value<String?>? osConfidence,
    Value<String>? inferenceReasonsJson,
    Value<String?>? customName,
    Value<String?>? customDeviceType,
    Value<String?>? note,
    Value<bool>? isKnown,
    Value<bool>? pingConfirmed,
    Value<bool>? isGateway,
    Value<bool>? isLocalDevice,
    Value<DateTime>? firstSeenAt,
    Value<DateTime>? lastSeenAt,
    Value<String>? status,
  }) {
    return DevicesCompanion(
      id: id ?? this.id,
      networkId: networkId ?? this.networkId,
      macAddress: macAddress ?? this.macAddress,
      currentIp: currentIp ?? this.currentIp,
      hostname: hostname ?? this.hostname,
      vendor: vendor ?? this.vendor,
      inferredType: inferredType ?? this.inferredType,
      inferredOs: inferredOs ?? this.inferredOs,
      confidence: confidence ?? this.confidence,
      osConfidence: osConfidence ?? this.osConfidence,
      inferenceReasonsJson: inferenceReasonsJson ?? this.inferenceReasonsJson,
      customName: customName ?? this.customName,
      customDeviceType: customDeviceType ?? this.customDeviceType,
      note: note ?? this.note,
      isKnown: isKnown ?? this.isKnown,
      pingConfirmed: pingConfirmed ?? this.pingConfirmed,
      isGateway: isGateway ?? this.isGateway,
      isLocalDevice: isLocalDevice ?? this.isLocalDevice,
      firstSeenAt: firstSeenAt ?? this.firstSeenAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      status: status ?? this.status,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (networkId.present) {
      map['network_id'] = Variable<int>(networkId.value);
    }
    if (macAddress.present) {
      map['mac_address'] = Variable<String>(macAddress.value);
    }
    if (currentIp.present) {
      map['current_ip'] = Variable<String>(currentIp.value);
    }
    if (hostname.present) {
      map['hostname'] = Variable<String>(hostname.value);
    }
    if (vendor.present) {
      map['vendor'] = Variable<String>(vendor.value);
    }
    if (inferredType.present) {
      map['inferred_type'] = Variable<String>(inferredType.value);
    }
    if (inferredOs.present) {
      map['inferred_os'] = Variable<String>(inferredOs.value);
    }
    if (confidence.present) {
      map['confidence'] = Variable<String>(confidence.value);
    }
    if (osConfidence.present) {
      map['os_confidence'] = Variable<String>(osConfidence.value);
    }
    if (inferenceReasonsJson.present) {
      map['inference_reasons_json'] = Variable<String>(
        inferenceReasonsJson.value,
      );
    }
    if (customName.present) {
      map['custom_name'] = Variable<String>(customName.value);
    }
    if (customDeviceType.present) {
      map['custom_type'] = Variable<String>(customDeviceType.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (isKnown.present) {
      map['is_known'] = Variable<bool>(isKnown.value);
    }
    if (pingConfirmed.present) {
      map['ping_confirmed'] = Variable<bool>(pingConfirmed.value);
    }
    if (isGateway.present) {
      map['is_gateway'] = Variable<bool>(isGateway.value);
    }
    if (isLocalDevice.present) {
      map['is_local_device'] = Variable<bool>(isLocalDevice.value);
    }
    if (firstSeenAt.present) {
      map['first_seen_at'] = Variable<DateTime>(firstSeenAt.value);
    }
    if (lastSeenAt.present) {
      map['last_seen_at'] = Variable<DateTime>(lastSeenAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DevicesCompanion(')
          ..write('id: $id, ')
          ..write('networkId: $networkId, ')
          ..write('macAddress: $macAddress, ')
          ..write('currentIp: $currentIp, ')
          ..write('hostname: $hostname, ')
          ..write('vendor: $vendor, ')
          ..write('inferredType: $inferredType, ')
          ..write('inferredOs: $inferredOs, ')
          ..write('confidence: $confidence, ')
          ..write('osConfidence: $osConfidence, ')
          ..write('inferenceReasonsJson: $inferenceReasonsJson, ')
          ..write('customName: $customName, ')
          ..write('customDeviceType: $customDeviceType, ')
          ..write('note: $note, ')
          ..write('isKnown: $isKnown, ')
          ..write('pingConfirmed: $pingConfirmed, ')
          ..write('isGateway: $isGateway, ')
          ..write('isLocalDevice: $isLocalDevice, ')
          ..write('firstSeenAt: $firstSeenAt, ')
          ..write('lastSeenAt: $lastSeenAt, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }
}

class $DeviceObservationsTable extends DeviceObservations
    with TableInfo<$DeviceObservationsTable, DeviceObservation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DeviceObservationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<int> deviceId = GeneratedColumn<int>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES devices (id)',
    ),
  );
  static const VerificationMeta _observedAtMeta = const VerificationMeta(
    'observedAt',
  );
  @override
  late final GeneratedColumn<DateTime> observedAt = GeneratedColumn<DateTime>(
    'observed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ipAddressMeta = const VerificationMeta(
    'ipAddress',
  );
  @override
  late final GeneratedColumn<String> ipAddress = GeneratedColumn<String>(
    'ip_address',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hostnameMeta = const VerificationMeta(
    'hostname',
  );
  @override
  late final GeneratedColumn<String> hostname = GeneratedColumn<String>(
    'hostname',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _servicesJsonMeta = const VerificationMeta(
    'servicesJson',
  );
  @override
  late final GeneratedColumn<String> servicesJson = GeneratedColumn<String>(
    'services_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _signalsJsonMeta = const VerificationMeta(
    'signalsJson',
  );
  @override
  late final GeneratedColumn<String> signalsJson = GeneratedColumn<String>(
    'signals_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    deviceId,
    observedAt,
    ipAddress,
    hostname,
    servicesJson,
    signalsJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'device_observations';
  @override
  VerificationContext validateIntegrity(
    Insertable<DeviceObservation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('observed_at')) {
      context.handle(
        _observedAtMeta,
        observedAt.isAcceptableOrUnknown(data['observed_at']!, _observedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_observedAtMeta);
    }
    if (data.containsKey('ip_address')) {
      context.handle(
        _ipAddressMeta,
        ipAddress.isAcceptableOrUnknown(data['ip_address']!, _ipAddressMeta),
      );
    } else if (isInserting) {
      context.missing(_ipAddressMeta);
    }
    if (data.containsKey('hostname')) {
      context.handle(
        _hostnameMeta,
        hostname.isAcceptableOrUnknown(data['hostname']!, _hostnameMeta),
      );
    }
    if (data.containsKey('services_json')) {
      context.handle(
        _servicesJsonMeta,
        servicesJson.isAcceptableOrUnknown(
          data['services_json']!,
          _servicesJsonMeta,
        ),
      );
    }
    if (data.containsKey('signals_json')) {
      context.handle(
        _signalsJsonMeta,
        signalsJson.isAcceptableOrUnknown(
          data['signals_json']!,
          _signalsJsonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DeviceObservation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DeviceObservation(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}device_id'],
      )!,
      observedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}observed_at'],
      )!,
      ipAddress: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ip_address'],
      )!,
      hostname: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hostname'],
      ),
      servicesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}services_json'],
      )!,
      signalsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}signals_json'],
      )!,
    );
  }

  @override
  $DeviceObservationsTable createAlias(String alias) {
    return $DeviceObservationsTable(attachedDatabase, alias);
  }
}

class DeviceObservation extends DataClass
    implements Insertable<DeviceObservation> {
  final int id;
  final int deviceId;
  final DateTime observedAt;
  final String ipAddress;
  final String? hostname;
  final String servicesJson;
  final String signalsJson;
  const DeviceObservation({
    required this.id,
    required this.deviceId,
    required this.observedAt,
    required this.ipAddress,
    this.hostname,
    required this.servicesJson,
    required this.signalsJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['device_id'] = Variable<int>(deviceId);
    map['observed_at'] = Variable<DateTime>(observedAt);
    map['ip_address'] = Variable<String>(ipAddress);
    if (!nullToAbsent || hostname != null) {
      map['hostname'] = Variable<String>(hostname);
    }
    map['services_json'] = Variable<String>(servicesJson);
    map['signals_json'] = Variable<String>(signalsJson);
    return map;
  }

  DeviceObservationsCompanion toCompanion(bool nullToAbsent) {
    return DeviceObservationsCompanion(
      id: Value(id),
      deviceId: Value(deviceId),
      observedAt: Value(observedAt),
      ipAddress: Value(ipAddress),
      hostname: hostname == null && nullToAbsent
          ? const Value.absent()
          : Value(hostname),
      servicesJson: Value(servicesJson),
      signalsJson: Value(signalsJson),
    );
  }

  factory DeviceObservation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DeviceObservation(
      id: serializer.fromJson<int>(json['id']),
      deviceId: serializer.fromJson<int>(json['deviceId']),
      observedAt: serializer.fromJson<DateTime>(json['observedAt']),
      ipAddress: serializer.fromJson<String>(json['ipAddress']),
      hostname: serializer.fromJson<String?>(json['hostname']),
      servicesJson: serializer.fromJson<String>(json['servicesJson']),
      signalsJson: serializer.fromJson<String>(json['signalsJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'deviceId': serializer.toJson<int>(deviceId),
      'observedAt': serializer.toJson<DateTime>(observedAt),
      'ipAddress': serializer.toJson<String>(ipAddress),
      'hostname': serializer.toJson<String?>(hostname),
      'servicesJson': serializer.toJson<String>(servicesJson),
      'signalsJson': serializer.toJson<String>(signalsJson),
    };
  }

  DeviceObservation copyWith({
    int? id,
    int? deviceId,
    DateTime? observedAt,
    String? ipAddress,
    Value<String?> hostname = const Value.absent(),
    String? servicesJson,
    String? signalsJson,
  }) => DeviceObservation(
    id: id ?? this.id,
    deviceId: deviceId ?? this.deviceId,
    observedAt: observedAt ?? this.observedAt,
    ipAddress: ipAddress ?? this.ipAddress,
    hostname: hostname.present ? hostname.value : this.hostname,
    servicesJson: servicesJson ?? this.servicesJson,
    signalsJson: signalsJson ?? this.signalsJson,
  );
  DeviceObservation copyWithCompanion(DeviceObservationsCompanion data) {
    return DeviceObservation(
      id: data.id.present ? data.id.value : this.id,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      observedAt: data.observedAt.present
          ? data.observedAt.value
          : this.observedAt,
      ipAddress: data.ipAddress.present ? data.ipAddress.value : this.ipAddress,
      hostname: data.hostname.present ? data.hostname.value : this.hostname,
      servicesJson: data.servicesJson.present
          ? data.servicesJson.value
          : this.servicesJson,
      signalsJson: data.signalsJson.present
          ? data.signalsJson.value
          : this.signalsJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DeviceObservation(')
          ..write('id: $id, ')
          ..write('deviceId: $deviceId, ')
          ..write('observedAt: $observedAt, ')
          ..write('ipAddress: $ipAddress, ')
          ..write('hostname: $hostname, ')
          ..write('servicesJson: $servicesJson, ')
          ..write('signalsJson: $signalsJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    deviceId,
    observedAt,
    ipAddress,
    hostname,
    servicesJson,
    signalsJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeviceObservation &&
          other.id == this.id &&
          other.deviceId == this.deviceId &&
          other.observedAt == this.observedAt &&
          other.ipAddress == this.ipAddress &&
          other.hostname == this.hostname &&
          other.servicesJson == this.servicesJson &&
          other.signalsJson == this.signalsJson);
}

class DeviceObservationsCompanion extends UpdateCompanion<DeviceObservation> {
  final Value<int> id;
  final Value<int> deviceId;
  final Value<DateTime> observedAt;
  final Value<String> ipAddress;
  final Value<String?> hostname;
  final Value<String> servicesJson;
  final Value<String> signalsJson;
  const DeviceObservationsCompanion({
    this.id = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.observedAt = const Value.absent(),
    this.ipAddress = const Value.absent(),
    this.hostname = const Value.absent(),
    this.servicesJson = const Value.absent(),
    this.signalsJson = const Value.absent(),
  });
  DeviceObservationsCompanion.insert({
    this.id = const Value.absent(),
    required int deviceId,
    required DateTime observedAt,
    required String ipAddress,
    this.hostname = const Value.absent(),
    this.servicesJson = const Value.absent(),
    this.signalsJson = const Value.absent(),
  }) : deviceId = Value(deviceId),
       observedAt = Value(observedAt),
       ipAddress = Value(ipAddress);
  static Insertable<DeviceObservation> custom({
    Expression<int>? id,
    Expression<int>? deviceId,
    Expression<DateTime>? observedAt,
    Expression<String>? ipAddress,
    Expression<String>? hostname,
    Expression<String>? servicesJson,
    Expression<String>? signalsJson,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (deviceId != null) 'device_id': deviceId,
      if (observedAt != null) 'observed_at': observedAt,
      if (ipAddress != null) 'ip_address': ipAddress,
      if (hostname != null) 'hostname': hostname,
      if (servicesJson != null) 'services_json': servicesJson,
      if (signalsJson != null) 'signals_json': signalsJson,
    });
  }

  DeviceObservationsCompanion copyWith({
    Value<int>? id,
    Value<int>? deviceId,
    Value<DateTime>? observedAt,
    Value<String>? ipAddress,
    Value<String?>? hostname,
    Value<String>? servicesJson,
    Value<String>? signalsJson,
  }) {
    return DeviceObservationsCompanion(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      observedAt: observedAt ?? this.observedAt,
      ipAddress: ipAddress ?? this.ipAddress,
      hostname: hostname ?? this.hostname,
      servicesJson: servicesJson ?? this.servicesJson,
      signalsJson: signalsJson ?? this.signalsJson,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<int>(deviceId.value);
    }
    if (observedAt.present) {
      map['observed_at'] = Variable<DateTime>(observedAt.value);
    }
    if (ipAddress.present) {
      map['ip_address'] = Variable<String>(ipAddress.value);
    }
    if (hostname.present) {
      map['hostname'] = Variable<String>(hostname.value);
    }
    if (servicesJson.present) {
      map['services_json'] = Variable<String>(servicesJson.value);
    }
    if (signalsJson.present) {
      map['signals_json'] = Variable<String>(signalsJson.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DeviceObservationsCompanion(')
          ..write('id: $id, ')
          ..write('deviceId: $deviceId, ')
          ..write('observedAt: $observedAt, ')
          ..write('ipAddress: $ipAddress, ')
          ..write('hostname: $hostname, ')
          ..write('servicesJson: $servicesJson, ')
          ..write('signalsJson: $signalsJson')
          ..write(')'))
        .toString();
  }
}

class $TrafficSamplesTable extends TrafficSamples
    with TableInfo<$TrafficSamplesTable, TrafficSample> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TrafficSamplesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<int> deviceId = GeneratedColumn<int>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES devices (id)',
    ),
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _periodStartMeta = const VerificationMeta(
    'periodStart',
  );
  @override
  late final GeneratedColumn<DateTime> periodStart = GeneratedColumn<DateTime>(
    'period_start',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _periodEndMeta = const VerificationMeta(
    'periodEnd',
  );
  @override
  late final GeneratedColumn<DateTime> periodEnd = GeneratedColumn<DateTime>(
    'period_end',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _downloadBytesMeta = const VerificationMeta(
    'downloadBytes',
  );
  @override
  late final GeneratedColumn<int> downloadBytes = GeneratedColumn<int>(
    'download_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _uploadBytesMeta = const VerificationMeta(
    'uploadBytes',
  );
  @override
  late final GeneratedColumn<int> uploadBytes = GeneratedColumn<int>(
    'upload_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reliabilityMeta = const VerificationMeta(
    'reliability',
  );
  @override
  late final GeneratedColumn<String> reliability = GeneratedColumn<String>(
    'reliability',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _macAddressMeta = const VerificationMeta(
    'macAddress',
  );
  @override
  late final GeneratedColumn<String> macAddress = GeneratedColumn<String>(
    'mac_address',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ipAddressMeta = const VerificationMeta(
    'ipAddress',
  );
  @override
  late final GeneratedColumn<String> ipAddress = GeneratedColumn<String>(
    'ip_address',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    deviceId,
    source,
    periodStart,
    periodEnd,
    downloadBytes,
    uploadBytes,
    reliability,
    macAddress,
    ipAddress,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'traffic_samples';
  @override
  VerificationContext validateIntegrity(
    Insertable<TrafficSample> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('period_start')) {
      context.handle(
        _periodStartMeta,
        periodStart.isAcceptableOrUnknown(
          data['period_start']!,
          _periodStartMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_periodStartMeta);
    }
    if (data.containsKey('period_end')) {
      context.handle(
        _periodEndMeta,
        periodEnd.isAcceptableOrUnknown(data['period_end']!, _periodEndMeta),
      );
    } else if (isInserting) {
      context.missing(_periodEndMeta);
    }
    if (data.containsKey('download_bytes')) {
      context.handle(
        _downloadBytesMeta,
        downloadBytes.isAcceptableOrUnknown(
          data['download_bytes']!,
          _downloadBytesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_downloadBytesMeta);
    }
    if (data.containsKey('upload_bytes')) {
      context.handle(
        _uploadBytesMeta,
        uploadBytes.isAcceptableOrUnknown(
          data['upload_bytes']!,
          _uploadBytesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_uploadBytesMeta);
    }
    if (data.containsKey('reliability')) {
      context.handle(
        _reliabilityMeta,
        reliability.isAcceptableOrUnknown(
          data['reliability']!,
          _reliabilityMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_reliabilityMeta);
    }
    if (data.containsKey('mac_address')) {
      context.handle(
        _macAddressMeta,
        macAddress.isAcceptableOrUnknown(data['mac_address']!, _macAddressMeta),
      );
    }
    if (data.containsKey('ip_address')) {
      context.handle(
        _ipAddressMeta,
        ipAddress.isAcceptableOrUnknown(data['ip_address']!, _ipAddressMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TrafficSample map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TrafficSample(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}device_id'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      periodStart: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}period_start'],
      )!,
      periodEnd: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}period_end'],
      )!,
      downloadBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}download_bytes'],
      )!,
      uploadBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}upload_bytes'],
      )!,
      reliability: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reliability'],
      )!,
      macAddress: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mac_address'],
      ),
      ipAddress: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ip_address'],
      ),
    );
  }

  @override
  $TrafficSamplesTable createAlias(String alias) {
    return $TrafficSamplesTable(attachedDatabase, alias);
  }
}

class TrafficSample extends DataClass implements Insertable<TrafficSample> {
  final int id;
  final int deviceId;
  final String source;
  final DateTime periodStart;
  final DateTime periodEnd;
  final int downloadBytes;
  final int uploadBytes;
  final String reliability;

  /// The MAC/IP binding the provider reported at sample time (schema v2).
  final String? macAddress;
  final String? ipAddress;
  const TrafficSample({
    required this.id,
    required this.deviceId,
    required this.source,
    required this.periodStart,
    required this.periodEnd,
    required this.downloadBytes,
    required this.uploadBytes,
    required this.reliability,
    this.macAddress,
    this.ipAddress,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['device_id'] = Variable<int>(deviceId);
    map['source'] = Variable<String>(source);
    map['period_start'] = Variable<DateTime>(periodStart);
    map['period_end'] = Variable<DateTime>(periodEnd);
    map['download_bytes'] = Variable<int>(downloadBytes);
    map['upload_bytes'] = Variable<int>(uploadBytes);
    map['reliability'] = Variable<String>(reliability);
    if (!nullToAbsent || macAddress != null) {
      map['mac_address'] = Variable<String>(macAddress);
    }
    if (!nullToAbsent || ipAddress != null) {
      map['ip_address'] = Variable<String>(ipAddress);
    }
    return map;
  }

  TrafficSamplesCompanion toCompanion(bool nullToAbsent) {
    return TrafficSamplesCompanion(
      id: Value(id),
      deviceId: Value(deviceId),
      source: Value(source),
      periodStart: Value(periodStart),
      periodEnd: Value(periodEnd),
      downloadBytes: Value(downloadBytes),
      uploadBytes: Value(uploadBytes),
      reliability: Value(reliability),
      macAddress: macAddress == null && nullToAbsent
          ? const Value.absent()
          : Value(macAddress),
      ipAddress: ipAddress == null && nullToAbsent
          ? const Value.absent()
          : Value(ipAddress),
    );
  }

  factory TrafficSample.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TrafficSample(
      id: serializer.fromJson<int>(json['id']),
      deviceId: serializer.fromJson<int>(json['deviceId']),
      source: serializer.fromJson<String>(json['source']),
      periodStart: serializer.fromJson<DateTime>(json['periodStart']),
      periodEnd: serializer.fromJson<DateTime>(json['periodEnd']),
      downloadBytes: serializer.fromJson<int>(json['downloadBytes']),
      uploadBytes: serializer.fromJson<int>(json['uploadBytes']),
      reliability: serializer.fromJson<String>(json['reliability']),
      macAddress: serializer.fromJson<String?>(json['macAddress']),
      ipAddress: serializer.fromJson<String?>(json['ipAddress']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'deviceId': serializer.toJson<int>(deviceId),
      'source': serializer.toJson<String>(source),
      'periodStart': serializer.toJson<DateTime>(periodStart),
      'periodEnd': serializer.toJson<DateTime>(periodEnd),
      'downloadBytes': serializer.toJson<int>(downloadBytes),
      'uploadBytes': serializer.toJson<int>(uploadBytes),
      'reliability': serializer.toJson<String>(reliability),
      'macAddress': serializer.toJson<String?>(macAddress),
      'ipAddress': serializer.toJson<String?>(ipAddress),
    };
  }

  TrafficSample copyWith({
    int? id,
    int? deviceId,
    String? source,
    DateTime? periodStart,
    DateTime? periodEnd,
    int? downloadBytes,
    int? uploadBytes,
    String? reliability,
    Value<String?> macAddress = const Value.absent(),
    Value<String?> ipAddress = const Value.absent(),
  }) => TrafficSample(
    id: id ?? this.id,
    deviceId: deviceId ?? this.deviceId,
    source: source ?? this.source,
    periodStart: periodStart ?? this.periodStart,
    periodEnd: periodEnd ?? this.periodEnd,
    downloadBytes: downloadBytes ?? this.downloadBytes,
    uploadBytes: uploadBytes ?? this.uploadBytes,
    reliability: reliability ?? this.reliability,
    macAddress: macAddress.present ? macAddress.value : this.macAddress,
    ipAddress: ipAddress.present ? ipAddress.value : this.ipAddress,
  );
  TrafficSample copyWithCompanion(TrafficSamplesCompanion data) {
    return TrafficSample(
      id: data.id.present ? data.id.value : this.id,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      source: data.source.present ? data.source.value : this.source,
      periodStart: data.periodStart.present
          ? data.periodStart.value
          : this.periodStart,
      periodEnd: data.periodEnd.present ? data.periodEnd.value : this.periodEnd,
      downloadBytes: data.downloadBytes.present
          ? data.downloadBytes.value
          : this.downloadBytes,
      uploadBytes: data.uploadBytes.present
          ? data.uploadBytes.value
          : this.uploadBytes,
      reliability: data.reliability.present
          ? data.reliability.value
          : this.reliability,
      macAddress: data.macAddress.present
          ? data.macAddress.value
          : this.macAddress,
      ipAddress: data.ipAddress.present ? data.ipAddress.value : this.ipAddress,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TrafficSample(')
          ..write('id: $id, ')
          ..write('deviceId: $deviceId, ')
          ..write('source: $source, ')
          ..write('periodStart: $periodStart, ')
          ..write('periodEnd: $periodEnd, ')
          ..write('downloadBytes: $downloadBytes, ')
          ..write('uploadBytes: $uploadBytes, ')
          ..write('reliability: $reliability, ')
          ..write('macAddress: $macAddress, ')
          ..write('ipAddress: $ipAddress')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    deviceId,
    source,
    periodStart,
    periodEnd,
    downloadBytes,
    uploadBytes,
    reliability,
    macAddress,
    ipAddress,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrafficSample &&
          other.id == this.id &&
          other.deviceId == this.deviceId &&
          other.source == this.source &&
          other.periodStart == this.periodStart &&
          other.periodEnd == this.periodEnd &&
          other.downloadBytes == this.downloadBytes &&
          other.uploadBytes == this.uploadBytes &&
          other.reliability == this.reliability &&
          other.macAddress == this.macAddress &&
          other.ipAddress == this.ipAddress);
}

class TrafficSamplesCompanion extends UpdateCompanion<TrafficSample> {
  final Value<int> id;
  final Value<int> deviceId;
  final Value<String> source;
  final Value<DateTime> periodStart;
  final Value<DateTime> periodEnd;
  final Value<int> downloadBytes;
  final Value<int> uploadBytes;
  final Value<String> reliability;
  final Value<String?> macAddress;
  final Value<String?> ipAddress;
  const TrafficSamplesCompanion({
    this.id = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.source = const Value.absent(),
    this.periodStart = const Value.absent(),
    this.periodEnd = const Value.absent(),
    this.downloadBytes = const Value.absent(),
    this.uploadBytes = const Value.absent(),
    this.reliability = const Value.absent(),
    this.macAddress = const Value.absent(),
    this.ipAddress = const Value.absent(),
  });
  TrafficSamplesCompanion.insert({
    this.id = const Value.absent(),
    required int deviceId,
    required String source,
    required DateTime periodStart,
    required DateTime periodEnd,
    required int downloadBytes,
    required int uploadBytes,
    required String reliability,
    this.macAddress = const Value.absent(),
    this.ipAddress = const Value.absent(),
  }) : deviceId = Value(deviceId),
       source = Value(source),
       periodStart = Value(periodStart),
       periodEnd = Value(periodEnd),
       downloadBytes = Value(downloadBytes),
       uploadBytes = Value(uploadBytes),
       reliability = Value(reliability);
  static Insertable<TrafficSample> custom({
    Expression<int>? id,
    Expression<int>? deviceId,
    Expression<String>? source,
    Expression<DateTime>? periodStart,
    Expression<DateTime>? periodEnd,
    Expression<int>? downloadBytes,
    Expression<int>? uploadBytes,
    Expression<String>? reliability,
    Expression<String>? macAddress,
    Expression<String>? ipAddress,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (deviceId != null) 'device_id': deviceId,
      if (source != null) 'source': source,
      if (periodStart != null) 'period_start': periodStart,
      if (periodEnd != null) 'period_end': periodEnd,
      if (downloadBytes != null) 'download_bytes': downloadBytes,
      if (uploadBytes != null) 'upload_bytes': uploadBytes,
      if (reliability != null) 'reliability': reliability,
      if (macAddress != null) 'mac_address': macAddress,
      if (ipAddress != null) 'ip_address': ipAddress,
    });
  }

  TrafficSamplesCompanion copyWith({
    Value<int>? id,
    Value<int>? deviceId,
    Value<String>? source,
    Value<DateTime>? periodStart,
    Value<DateTime>? periodEnd,
    Value<int>? downloadBytes,
    Value<int>? uploadBytes,
    Value<String>? reliability,
    Value<String?>? macAddress,
    Value<String?>? ipAddress,
  }) {
    return TrafficSamplesCompanion(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      source: source ?? this.source,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      downloadBytes: downloadBytes ?? this.downloadBytes,
      uploadBytes: uploadBytes ?? this.uploadBytes,
      reliability: reliability ?? this.reliability,
      macAddress: macAddress ?? this.macAddress,
      ipAddress: ipAddress ?? this.ipAddress,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<int>(deviceId.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (periodStart.present) {
      map['period_start'] = Variable<DateTime>(periodStart.value);
    }
    if (periodEnd.present) {
      map['period_end'] = Variable<DateTime>(periodEnd.value);
    }
    if (downloadBytes.present) {
      map['download_bytes'] = Variable<int>(downloadBytes.value);
    }
    if (uploadBytes.present) {
      map['upload_bytes'] = Variable<int>(uploadBytes.value);
    }
    if (reliability.present) {
      map['reliability'] = Variable<String>(reliability.value);
    }
    if (macAddress.present) {
      map['mac_address'] = Variable<String>(macAddress.value);
    }
    if (ipAddress.present) {
      map['ip_address'] = Variable<String>(ipAddress.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TrafficSamplesCompanion(')
          ..write('id: $id, ')
          ..write('deviceId: $deviceId, ')
          ..write('source: $source, ')
          ..write('periodStart: $periodStart, ')
          ..write('periodEnd: $periodEnd, ')
          ..write('downloadBytes: $downloadBytes, ')
          ..write('uploadBytes: $uploadBytes, ')
          ..write('reliability: $reliability, ')
          ..write('macAddress: $macAddress, ')
          ..write('ipAddress: $ipAddress')
          ..write(')'))
        .toString();
  }
}

class $ScanSessionsTable extends ScanSessions
    with TableInfo<$ScanSessionsTable, ScanSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ScanSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _networkIdMeta = const VerificationMeta(
    'networkId',
  );
  @override
  late final GeneratedColumn<int> networkId = GeneratedColumn<int>(
    'network_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES networks (id)',
    ),
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _finishedAtMeta = const VerificationMeta(
    'finishedAt',
  );
  @override
  late final GeneratedColumn<DateTime> finishedAt = GeneratedColumn<DateTime>(
    'finished_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _targetCidrsJsonMeta = const VerificationMeta(
    'targetCidrsJson',
  );
  @override
  late final GeneratedColumn<String> targetCidrsJson = GeneratedColumn<String>(
    'target_cidrs_json',
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
  static const VerificationMeta _hostsScannedMeta = const VerificationMeta(
    'hostsScanned',
  );
  @override
  late final GeneratedColumn<int> hostsScanned = GeneratedColumn<int>(
    'hosts_scanned',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _devicesFoundMeta = const VerificationMeta(
    'devicesFound',
  );
  @override
  late final GeneratedColumn<int> devicesFound = GeneratedColumn<int>(
    'devices_found',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _checkpointJsonMeta = const VerificationMeta(
    'checkpointJson',
  );
  @override
  late final GeneratedColumn<String> checkpointJson = GeneratedColumn<String>(
    'checkpoint_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _errorMessageMeta = const VerificationMeta(
    'errorMessage',
  );
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
    'error_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    networkId,
    startedAt,
    finishedAt,
    targetCidrsJson,
    status,
    hostsScanned,
    devicesFound,
    checkpointJson,
    errorMessage,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'scan_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<ScanSession> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('network_id')) {
      context.handle(
        _networkIdMeta,
        networkId.isAcceptableOrUnknown(data['network_id']!, _networkIdMeta),
      );
    } else if (isInserting) {
      context.missing(_networkIdMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('finished_at')) {
      context.handle(
        _finishedAtMeta,
        finishedAt.isAcceptableOrUnknown(data['finished_at']!, _finishedAtMeta),
      );
    }
    if (data.containsKey('target_cidrs_json')) {
      context.handle(
        _targetCidrsJsonMeta,
        targetCidrsJson.isAcceptableOrUnknown(
          data['target_cidrs_json']!,
          _targetCidrsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_targetCidrsJsonMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('hosts_scanned')) {
      context.handle(
        _hostsScannedMeta,
        hostsScanned.isAcceptableOrUnknown(
          data['hosts_scanned']!,
          _hostsScannedMeta,
        ),
      );
    }
    if (data.containsKey('devices_found')) {
      context.handle(
        _devicesFoundMeta,
        devicesFound.isAcceptableOrUnknown(
          data['devices_found']!,
          _devicesFoundMeta,
        ),
      );
    }
    if (data.containsKey('checkpoint_json')) {
      context.handle(
        _checkpointJsonMeta,
        checkpointJson.isAcceptableOrUnknown(
          data['checkpoint_json']!,
          _checkpointJsonMeta,
        ),
      );
    }
    if (data.containsKey('error_message')) {
      context.handle(
        _errorMessageMeta,
        errorMessage.isAcceptableOrUnknown(
          data['error_message']!,
          _errorMessageMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ScanSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ScanSession(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      networkId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}network_id'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      finishedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}finished_at'],
      ),
      targetCidrsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_cidrs_json'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      hostsScanned: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hosts_scanned'],
      )!,
      devicesFound: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}devices_found'],
      )!,
      checkpointJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}checkpoint_json'],
      ),
      errorMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_message'],
      ),
    );
  }

  @override
  $ScanSessionsTable createAlias(String alias) {
    return $ScanSessionsTable(attachedDatabase, alias);
  }
}

class ScanSession extends DataClass implements Insertable<ScanSession> {
  final int id;
  final int networkId;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final String targetCidrsJson;
  final String status;
  final int hostsScanned;
  final int devicesFound;
  final String? checkpointJson;
  final String? errorMessage;
  const ScanSession({
    required this.id,
    required this.networkId,
    required this.startedAt,
    this.finishedAt,
    required this.targetCidrsJson,
    required this.status,
    required this.hostsScanned,
    required this.devicesFound,
    this.checkpointJson,
    this.errorMessage,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['network_id'] = Variable<int>(networkId);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || finishedAt != null) {
      map['finished_at'] = Variable<DateTime>(finishedAt);
    }
    map['target_cidrs_json'] = Variable<String>(targetCidrsJson);
    map['status'] = Variable<String>(status);
    map['hosts_scanned'] = Variable<int>(hostsScanned);
    map['devices_found'] = Variable<int>(devicesFound);
    if (!nullToAbsent || checkpointJson != null) {
      map['checkpoint_json'] = Variable<String>(checkpointJson);
    }
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    return map;
  }

  ScanSessionsCompanion toCompanion(bool nullToAbsent) {
    return ScanSessionsCompanion(
      id: Value(id),
      networkId: Value(networkId),
      startedAt: Value(startedAt),
      finishedAt: finishedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(finishedAt),
      targetCidrsJson: Value(targetCidrsJson),
      status: Value(status),
      hostsScanned: Value(hostsScanned),
      devicesFound: Value(devicesFound),
      checkpointJson: checkpointJson == null && nullToAbsent
          ? const Value.absent()
          : Value(checkpointJson),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
    );
  }

  factory ScanSession.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ScanSession(
      id: serializer.fromJson<int>(json['id']),
      networkId: serializer.fromJson<int>(json['networkId']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      finishedAt: serializer.fromJson<DateTime?>(json['finishedAt']),
      targetCidrsJson: serializer.fromJson<String>(json['targetCidrsJson']),
      status: serializer.fromJson<String>(json['status']),
      hostsScanned: serializer.fromJson<int>(json['hostsScanned']),
      devicesFound: serializer.fromJson<int>(json['devicesFound']),
      checkpointJson: serializer.fromJson<String?>(json['checkpointJson']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'networkId': serializer.toJson<int>(networkId),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'finishedAt': serializer.toJson<DateTime?>(finishedAt),
      'targetCidrsJson': serializer.toJson<String>(targetCidrsJson),
      'status': serializer.toJson<String>(status),
      'hostsScanned': serializer.toJson<int>(hostsScanned),
      'devicesFound': serializer.toJson<int>(devicesFound),
      'checkpointJson': serializer.toJson<String?>(checkpointJson),
      'errorMessage': serializer.toJson<String?>(errorMessage),
    };
  }

  ScanSession copyWith({
    int? id,
    int? networkId,
    DateTime? startedAt,
    Value<DateTime?> finishedAt = const Value.absent(),
    String? targetCidrsJson,
    String? status,
    int? hostsScanned,
    int? devicesFound,
    Value<String?> checkpointJson = const Value.absent(),
    Value<String?> errorMessage = const Value.absent(),
  }) => ScanSession(
    id: id ?? this.id,
    networkId: networkId ?? this.networkId,
    startedAt: startedAt ?? this.startedAt,
    finishedAt: finishedAt.present ? finishedAt.value : this.finishedAt,
    targetCidrsJson: targetCidrsJson ?? this.targetCidrsJson,
    status: status ?? this.status,
    hostsScanned: hostsScanned ?? this.hostsScanned,
    devicesFound: devicesFound ?? this.devicesFound,
    checkpointJson: checkpointJson.present
        ? checkpointJson.value
        : this.checkpointJson,
    errorMessage: errorMessage.present ? errorMessage.value : this.errorMessage,
  );
  ScanSession copyWithCompanion(ScanSessionsCompanion data) {
    return ScanSession(
      id: data.id.present ? data.id.value : this.id,
      networkId: data.networkId.present ? data.networkId.value : this.networkId,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      finishedAt: data.finishedAt.present
          ? data.finishedAt.value
          : this.finishedAt,
      targetCidrsJson: data.targetCidrsJson.present
          ? data.targetCidrsJson.value
          : this.targetCidrsJson,
      status: data.status.present ? data.status.value : this.status,
      hostsScanned: data.hostsScanned.present
          ? data.hostsScanned.value
          : this.hostsScanned,
      devicesFound: data.devicesFound.present
          ? data.devicesFound.value
          : this.devicesFound,
      checkpointJson: data.checkpointJson.present
          ? data.checkpointJson.value
          : this.checkpointJson,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ScanSession(')
          ..write('id: $id, ')
          ..write('networkId: $networkId, ')
          ..write('startedAt: $startedAt, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('targetCidrsJson: $targetCidrsJson, ')
          ..write('status: $status, ')
          ..write('hostsScanned: $hostsScanned, ')
          ..write('devicesFound: $devicesFound, ')
          ..write('checkpointJson: $checkpointJson, ')
          ..write('errorMessage: $errorMessage')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    networkId,
    startedAt,
    finishedAt,
    targetCidrsJson,
    status,
    hostsScanned,
    devicesFound,
    checkpointJson,
    errorMessage,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScanSession &&
          other.id == this.id &&
          other.networkId == this.networkId &&
          other.startedAt == this.startedAt &&
          other.finishedAt == this.finishedAt &&
          other.targetCidrsJson == this.targetCidrsJson &&
          other.status == this.status &&
          other.hostsScanned == this.hostsScanned &&
          other.devicesFound == this.devicesFound &&
          other.checkpointJson == this.checkpointJson &&
          other.errorMessage == this.errorMessage);
}

class ScanSessionsCompanion extends UpdateCompanion<ScanSession> {
  final Value<int> id;
  final Value<int> networkId;
  final Value<DateTime> startedAt;
  final Value<DateTime?> finishedAt;
  final Value<String> targetCidrsJson;
  final Value<String> status;
  final Value<int> hostsScanned;
  final Value<int> devicesFound;
  final Value<String?> checkpointJson;
  final Value<String?> errorMessage;
  const ScanSessionsCompanion({
    this.id = const Value.absent(),
    this.networkId = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.finishedAt = const Value.absent(),
    this.targetCidrsJson = const Value.absent(),
    this.status = const Value.absent(),
    this.hostsScanned = const Value.absent(),
    this.devicesFound = const Value.absent(),
    this.checkpointJson = const Value.absent(),
    this.errorMessage = const Value.absent(),
  });
  ScanSessionsCompanion.insert({
    this.id = const Value.absent(),
    required int networkId,
    required DateTime startedAt,
    this.finishedAt = const Value.absent(),
    required String targetCidrsJson,
    required String status,
    this.hostsScanned = const Value.absent(),
    this.devicesFound = const Value.absent(),
    this.checkpointJson = const Value.absent(),
    this.errorMessage = const Value.absent(),
  }) : networkId = Value(networkId),
       startedAt = Value(startedAt),
       targetCidrsJson = Value(targetCidrsJson),
       status = Value(status);
  static Insertable<ScanSession> custom({
    Expression<int>? id,
    Expression<int>? networkId,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? finishedAt,
    Expression<String>? targetCidrsJson,
    Expression<String>? status,
    Expression<int>? hostsScanned,
    Expression<int>? devicesFound,
    Expression<String>? checkpointJson,
    Expression<String>? errorMessage,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (networkId != null) 'network_id': networkId,
      if (startedAt != null) 'started_at': startedAt,
      if (finishedAt != null) 'finished_at': finishedAt,
      if (targetCidrsJson != null) 'target_cidrs_json': targetCidrsJson,
      if (status != null) 'status': status,
      if (hostsScanned != null) 'hosts_scanned': hostsScanned,
      if (devicesFound != null) 'devices_found': devicesFound,
      if (checkpointJson != null) 'checkpoint_json': checkpointJson,
      if (errorMessage != null) 'error_message': errorMessage,
    });
  }

  ScanSessionsCompanion copyWith({
    Value<int>? id,
    Value<int>? networkId,
    Value<DateTime>? startedAt,
    Value<DateTime?>? finishedAt,
    Value<String>? targetCidrsJson,
    Value<String>? status,
    Value<int>? hostsScanned,
    Value<int>? devicesFound,
    Value<String?>? checkpointJson,
    Value<String?>? errorMessage,
  }) {
    return ScanSessionsCompanion(
      id: id ?? this.id,
      networkId: networkId ?? this.networkId,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      targetCidrsJson: targetCidrsJson ?? this.targetCidrsJson,
      status: status ?? this.status,
      hostsScanned: hostsScanned ?? this.hostsScanned,
      devicesFound: devicesFound ?? this.devicesFound,
      checkpointJson: checkpointJson ?? this.checkpointJson,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (networkId.present) {
      map['network_id'] = Variable<int>(networkId.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (finishedAt.present) {
      map['finished_at'] = Variable<DateTime>(finishedAt.value);
    }
    if (targetCidrsJson.present) {
      map['target_cidrs_json'] = Variable<String>(targetCidrsJson.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (hostsScanned.present) {
      map['hosts_scanned'] = Variable<int>(hostsScanned.value);
    }
    if (devicesFound.present) {
      map['devices_found'] = Variable<int>(devicesFound.value);
    }
    if (checkpointJson.present) {
      map['checkpoint_json'] = Variable<String>(checkpointJson.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScanSessionsCompanion(')
          ..write('id: $id, ')
          ..write('networkId: $networkId, ')
          ..write('startedAt: $startedAt, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('targetCidrsJson: $targetCidrsJson, ')
          ..write('status: $status, ')
          ..write('hostsScanned: $hostsScanned, ')
          ..write('devicesFound: $devicesFound, ')
          ..write('checkpointJson: $checkpointJson, ')
          ..write('errorMessage: $errorMessage')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $NetworksTable networks = $NetworksTable(this);
  late final $DevicesTable devices = $DevicesTable(this);
  late final $DeviceObservationsTable deviceObservations =
      $DeviceObservationsTable(this);
  late final $TrafficSamplesTable trafficSamples = $TrafficSamplesTable(this);
  late final $ScanSessionsTable scanSessions = $ScanSessionsTable(this);
  late final Index trafficSamplesDevicePeriod = Index(
    'traffic_samples_device_period',
    'CREATE INDEX traffic_samples_device_period ON traffic_samples (device_id, period_start)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    networks,
    devices,
    deviceObservations,
    trafficSamples,
    scanSessions,
    trafficSamplesDevicePeriod,
  ];
}

typedef $$NetworksTableCreateCompanionBuilder =
    NetworksCompanion Function({
      Value<int> id,
      required String interfaceName,
      required String displayName,
      required String cidr,
      Value<String?> gatewayIp,
      required DateTime firstSeenAt,
      required DateTime lastSeenAt,
    });
typedef $$NetworksTableUpdateCompanionBuilder =
    NetworksCompanion Function({
      Value<int> id,
      Value<String> interfaceName,
      Value<String> displayName,
      Value<String> cidr,
      Value<String?> gatewayIp,
      Value<DateTime> firstSeenAt,
      Value<DateTime> lastSeenAt,
    });

final class $$NetworksTableReferences
    extends BaseReferences<_$AppDatabase, $NetworksTable, Network> {
  $$NetworksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$DevicesTable, List<Device>> _devicesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.devices,
    aliasName: $_aliasNameGenerator(db.networks.id, db.devices.networkId),
  );

  $$DevicesTableProcessedTableManager get devicesRefs {
    final manager = $$DevicesTableTableManager(
      $_db,
      $_db.devices,
    ).filter((f) => f.networkId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_devicesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ScanSessionsTable, List<ScanSession>>
  _scanSessionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.scanSessions,
    aliasName: $_aliasNameGenerator(db.networks.id, db.scanSessions.networkId),
  );

  $$ScanSessionsTableProcessedTableManager get scanSessionsRefs {
    final manager = $$ScanSessionsTableTableManager(
      $_db,
      $_db.scanSessions,
    ).filter((f) => f.networkId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_scanSessionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$NetworksTableFilterComposer
    extends Composer<_$AppDatabase, $NetworksTable> {
  $$NetworksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get interfaceName => $composableBuilder(
    column: $table.interfaceName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cidr => $composableBuilder(
    column: $table.cidr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gatewayIp => $composableBuilder(
    column: $table.gatewayIp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get firstSeenAt => $composableBuilder(
    column: $table.firstSeenAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> devicesRefs(
    Expression<bool> Function($$DevicesTableFilterComposer f) f,
  ) {
    final $$DevicesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.devices,
      getReferencedColumn: (t) => t.networkId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DevicesTableFilterComposer(
            $db: $db,
            $table: $db.devices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> scanSessionsRefs(
    Expression<bool> Function($$ScanSessionsTableFilterComposer f) f,
  ) {
    final $$ScanSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.scanSessions,
      getReferencedColumn: (t) => t.networkId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScanSessionsTableFilterComposer(
            $db: $db,
            $table: $db.scanSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$NetworksTableOrderingComposer
    extends Composer<_$AppDatabase, $NetworksTable> {
  $$NetworksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get interfaceName => $composableBuilder(
    column: $table.interfaceName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cidr => $composableBuilder(
    column: $table.cidr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gatewayIp => $composableBuilder(
    column: $table.gatewayIp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get firstSeenAt => $composableBuilder(
    column: $table.firstSeenAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NetworksTableAnnotationComposer
    extends Composer<_$AppDatabase, $NetworksTable> {
  $$NetworksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get interfaceName => $composableBuilder(
    column: $table.interfaceName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cidr =>
      $composableBuilder(column: $table.cidr, builder: (column) => column);

  GeneratedColumn<String> get gatewayIp =>
      $composableBuilder(column: $table.gatewayIp, builder: (column) => column);

  GeneratedColumn<DateTime> get firstSeenAt => $composableBuilder(
    column: $table.firstSeenAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => column,
  );

  Expression<T> devicesRefs<T extends Object>(
    Expression<T> Function($$DevicesTableAnnotationComposer a) f,
  ) {
    final $$DevicesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.devices,
      getReferencedColumn: (t) => t.networkId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DevicesTableAnnotationComposer(
            $db: $db,
            $table: $db.devices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> scanSessionsRefs<T extends Object>(
    Expression<T> Function($$ScanSessionsTableAnnotationComposer a) f,
  ) {
    final $$ScanSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.scanSessions,
      getReferencedColumn: (t) => t.networkId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScanSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.scanSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$NetworksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NetworksTable,
          Network,
          $$NetworksTableFilterComposer,
          $$NetworksTableOrderingComposer,
          $$NetworksTableAnnotationComposer,
          $$NetworksTableCreateCompanionBuilder,
          $$NetworksTableUpdateCompanionBuilder,
          (Network, $$NetworksTableReferences),
          Network,
          PrefetchHooks Function({bool devicesRefs, bool scanSessionsRefs})
        > {
  $$NetworksTableTableManager(_$AppDatabase db, $NetworksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NetworksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NetworksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NetworksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> interfaceName = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String> cidr = const Value.absent(),
                Value<String?> gatewayIp = const Value.absent(),
                Value<DateTime> firstSeenAt = const Value.absent(),
                Value<DateTime> lastSeenAt = const Value.absent(),
              }) => NetworksCompanion(
                id: id,
                interfaceName: interfaceName,
                displayName: displayName,
                cidr: cidr,
                gatewayIp: gatewayIp,
                firstSeenAt: firstSeenAt,
                lastSeenAt: lastSeenAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String interfaceName,
                required String displayName,
                required String cidr,
                Value<String?> gatewayIp = const Value.absent(),
                required DateTime firstSeenAt,
                required DateTime lastSeenAt,
              }) => NetworksCompanion.insert(
                id: id,
                interfaceName: interfaceName,
                displayName: displayName,
                cidr: cidr,
                gatewayIp: gatewayIp,
                firstSeenAt: firstSeenAt,
                lastSeenAt: lastSeenAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$NetworksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({devicesRefs = false, scanSessionsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (devicesRefs) db.devices,
                    if (scanSessionsRefs) db.scanSessions,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (devicesRefs)
                        await $_getPrefetchedData<
                          Network,
                          $NetworksTable,
                          Device
                        >(
                          currentTable: table,
                          referencedTable: $$NetworksTableReferences
                              ._devicesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$NetworksTableReferences(
                                db,
                                table,
                                p0,
                              ).devicesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.networkId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (scanSessionsRefs)
                        await $_getPrefetchedData<
                          Network,
                          $NetworksTable,
                          ScanSession
                        >(
                          currentTable: table,
                          referencedTable: $$NetworksTableReferences
                              ._scanSessionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$NetworksTableReferences(
                                db,
                                table,
                                p0,
                              ).scanSessionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.networkId == item.id,
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

typedef $$NetworksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NetworksTable,
      Network,
      $$NetworksTableFilterComposer,
      $$NetworksTableOrderingComposer,
      $$NetworksTableAnnotationComposer,
      $$NetworksTableCreateCompanionBuilder,
      $$NetworksTableUpdateCompanionBuilder,
      (Network, $$NetworksTableReferences),
      Network,
      PrefetchHooks Function({bool devicesRefs, bool scanSessionsRefs})
    >;
typedef $$DevicesTableCreateCompanionBuilder =
    DevicesCompanion Function({
      Value<int> id,
      required int networkId,
      Value<String?> macAddress,
      required String currentIp,
      Value<String?> hostname,
      Value<String?> vendor,
      required String inferredType,
      Value<String?> inferredOs,
      required String confidence,
      Value<String?> osConfidence,
      Value<String> inferenceReasonsJson,
      Value<String?> customName,
      Value<String?> customDeviceType,
      Value<String?> note,
      Value<bool> isKnown,
      Value<bool> pingConfirmed,
      Value<bool> isGateway,
      Value<bool> isLocalDevice,
      required DateTime firstSeenAt,
      required DateTime lastSeenAt,
      required String status,
    });
typedef $$DevicesTableUpdateCompanionBuilder =
    DevicesCompanion Function({
      Value<int> id,
      Value<int> networkId,
      Value<String?> macAddress,
      Value<String> currentIp,
      Value<String?> hostname,
      Value<String?> vendor,
      Value<String> inferredType,
      Value<String?> inferredOs,
      Value<String> confidence,
      Value<String?> osConfidence,
      Value<String> inferenceReasonsJson,
      Value<String?> customName,
      Value<String?> customDeviceType,
      Value<String?> note,
      Value<bool> isKnown,
      Value<bool> pingConfirmed,
      Value<bool> isGateway,
      Value<bool> isLocalDevice,
      Value<DateTime> firstSeenAt,
      Value<DateTime> lastSeenAt,
      Value<String> status,
    });

final class $$DevicesTableReferences
    extends BaseReferences<_$AppDatabase, $DevicesTable, Device> {
  $$DevicesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $NetworksTable _networkIdTable(_$AppDatabase db) => db.networks
      .createAlias($_aliasNameGenerator(db.devices.networkId, db.networks.id));

  $$NetworksTableProcessedTableManager get networkId {
    final $_column = $_itemColumn<int>('network_id')!;

    final manager = $$NetworksTableTableManager(
      $_db,
      $_db.networks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_networkIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$DeviceObservationsTable, List<DeviceObservation>>
  _deviceObservationsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.deviceObservations,
        aliasName: $_aliasNameGenerator(
          db.devices.id,
          db.deviceObservations.deviceId,
        ),
      );

  $$DeviceObservationsTableProcessedTableManager get deviceObservationsRefs {
    final manager = $$DeviceObservationsTableTableManager(
      $_db,
      $_db.deviceObservations,
    ).filter((f) => f.deviceId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _deviceObservationsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TrafficSamplesTable, List<TrafficSample>>
  _trafficSamplesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.trafficSamples,
    aliasName: $_aliasNameGenerator(db.devices.id, db.trafficSamples.deviceId),
  );

  $$TrafficSamplesTableProcessedTableManager get trafficSamplesRefs {
    final manager = $$TrafficSamplesTableTableManager(
      $_db,
      $_db.trafficSamples,
    ).filter((f) => f.deviceId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_trafficSamplesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$DevicesTableFilterComposer
    extends Composer<_$AppDatabase, $DevicesTable> {
  $$DevicesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get macAddress => $composableBuilder(
    column: $table.macAddress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currentIp => $composableBuilder(
    column: $table.currentIp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hostname => $composableBuilder(
    column: $table.hostname,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get vendor => $composableBuilder(
    column: $table.vendor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get inferredType => $composableBuilder(
    column: $table.inferredType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get inferredOs => $composableBuilder(
    column: $table.inferredOs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get osConfidence => $composableBuilder(
    column: $table.osConfidence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get inferenceReasonsJson => $composableBuilder(
    column: $table.inferenceReasonsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customName => $composableBuilder(
    column: $table.customName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customDeviceType => $composableBuilder(
    column: $table.customDeviceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isKnown => $composableBuilder(
    column: $table.isKnown,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pingConfirmed => $composableBuilder(
    column: $table.pingConfirmed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isGateway => $composableBuilder(
    column: $table.isGateway,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isLocalDevice => $composableBuilder(
    column: $table.isLocalDevice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get firstSeenAt => $composableBuilder(
    column: $table.firstSeenAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  $$NetworksTableFilterComposer get networkId {
    final $$NetworksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.networkId,
      referencedTable: $db.networks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NetworksTableFilterComposer(
            $db: $db,
            $table: $db.networks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> deviceObservationsRefs(
    Expression<bool> Function($$DeviceObservationsTableFilterComposer f) f,
  ) {
    final $$DeviceObservationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.deviceObservations,
      getReferencedColumn: (t) => t.deviceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DeviceObservationsTableFilterComposer(
            $db: $db,
            $table: $db.deviceObservations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> trafficSamplesRefs(
    Expression<bool> Function($$TrafficSamplesTableFilterComposer f) f,
  ) {
    final $$TrafficSamplesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.trafficSamples,
      getReferencedColumn: (t) => t.deviceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TrafficSamplesTableFilterComposer(
            $db: $db,
            $table: $db.trafficSamples,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DevicesTableOrderingComposer
    extends Composer<_$AppDatabase, $DevicesTable> {
  $$DevicesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get macAddress => $composableBuilder(
    column: $table.macAddress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currentIp => $composableBuilder(
    column: $table.currentIp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hostname => $composableBuilder(
    column: $table.hostname,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get vendor => $composableBuilder(
    column: $table.vendor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get inferredType => $composableBuilder(
    column: $table.inferredType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get inferredOs => $composableBuilder(
    column: $table.inferredOs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get osConfidence => $composableBuilder(
    column: $table.osConfidence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get inferenceReasonsJson => $composableBuilder(
    column: $table.inferenceReasonsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customName => $composableBuilder(
    column: $table.customName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customDeviceType => $composableBuilder(
    column: $table.customDeviceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isKnown => $composableBuilder(
    column: $table.isKnown,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pingConfirmed => $composableBuilder(
    column: $table.pingConfirmed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isGateway => $composableBuilder(
    column: $table.isGateway,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isLocalDevice => $composableBuilder(
    column: $table.isLocalDevice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get firstSeenAt => $composableBuilder(
    column: $table.firstSeenAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  $$NetworksTableOrderingComposer get networkId {
    final $$NetworksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.networkId,
      referencedTable: $db.networks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NetworksTableOrderingComposer(
            $db: $db,
            $table: $db.networks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DevicesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DevicesTable> {
  $$DevicesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get macAddress => $composableBuilder(
    column: $table.macAddress,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currentIp =>
      $composableBuilder(column: $table.currentIp, builder: (column) => column);

  GeneratedColumn<String> get hostname =>
      $composableBuilder(column: $table.hostname, builder: (column) => column);

  GeneratedColumn<String> get vendor =>
      $composableBuilder(column: $table.vendor, builder: (column) => column);

  GeneratedColumn<String> get inferredType => $composableBuilder(
    column: $table.inferredType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get inferredOs => $composableBuilder(
    column: $table.inferredOs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => column,
  );

  GeneratedColumn<String> get osConfidence => $composableBuilder(
    column: $table.osConfidence,
    builder: (column) => column,
  );

  GeneratedColumn<String> get inferenceReasonsJson => $composableBuilder(
    column: $table.inferenceReasonsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customName => $composableBuilder(
    column: $table.customName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customDeviceType => $composableBuilder(
    column: $table.customDeviceType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<bool> get isKnown =>
      $composableBuilder(column: $table.isKnown, builder: (column) => column);

  GeneratedColumn<bool> get pingConfirmed => $composableBuilder(
    column: $table.pingConfirmed,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isGateway =>
      $composableBuilder(column: $table.isGateway, builder: (column) => column);

  GeneratedColumn<bool> get isLocalDevice => $composableBuilder(
    column: $table.isLocalDevice,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get firstSeenAt => $composableBuilder(
    column: $table.firstSeenAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  $$NetworksTableAnnotationComposer get networkId {
    final $$NetworksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.networkId,
      referencedTable: $db.networks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NetworksTableAnnotationComposer(
            $db: $db,
            $table: $db.networks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> deviceObservationsRefs<T extends Object>(
    Expression<T> Function($$DeviceObservationsTableAnnotationComposer a) f,
  ) {
    final $$DeviceObservationsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.deviceObservations,
          getReferencedColumn: (t) => t.deviceId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$DeviceObservationsTableAnnotationComposer(
                $db: $db,
                $table: $db.deviceObservations,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> trafficSamplesRefs<T extends Object>(
    Expression<T> Function($$TrafficSamplesTableAnnotationComposer a) f,
  ) {
    final $$TrafficSamplesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.trafficSamples,
      getReferencedColumn: (t) => t.deviceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TrafficSamplesTableAnnotationComposer(
            $db: $db,
            $table: $db.trafficSamples,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DevicesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DevicesTable,
          Device,
          $$DevicesTableFilterComposer,
          $$DevicesTableOrderingComposer,
          $$DevicesTableAnnotationComposer,
          $$DevicesTableCreateCompanionBuilder,
          $$DevicesTableUpdateCompanionBuilder,
          (Device, $$DevicesTableReferences),
          Device,
          PrefetchHooks Function({
            bool networkId,
            bool deviceObservationsRefs,
            bool trafficSamplesRefs,
          })
        > {
  $$DevicesTableTableManager(_$AppDatabase db, $DevicesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DevicesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DevicesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DevicesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> networkId = const Value.absent(),
                Value<String?> macAddress = const Value.absent(),
                Value<String> currentIp = const Value.absent(),
                Value<String?> hostname = const Value.absent(),
                Value<String?> vendor = const Value.absent(),
                Value<String> inferredType = const Value.absent(),
                Value<String?> inferredOs = const Value.absent(),
                Value<String> confidence = const Value.absent(),
                Value<String?> osConfidence = const Value.absent(),
                Value<String> inferenceReasonsJson = const Value.absent(),
                Value<String?> customName = const Value.absent(),
                Value<String?> customDeviceType = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<bool> isKnown = const Value.absent(),
                Value<bool> pingConfirmed = const Value.absent(),
                Value<bool> isGateway = const Value.absent(),
                Value<bool> isLocalDevice = const Value.absent(),
                Value<DateTime> firstSeenAt = const Value.absent(),
                Value<DateTime> lastSeenAt = const Value.absent(),
                Value<String> status = const Value.absent(),
              }) => DevicesCompanion(
                id: id,
                networkId: networkId,
                macAddress: macAddress,
                currentIp: currentIp,
                hostname: hostname,
                vendor: vendor,
                inferredType: inferredType,
                inferredOs: inferredOs,
                confidence: confidence,
                osConfidence: osConfidence,
                inferenceReasonsJson: inferenceReasonsJson,
                customName: customName,
                customDeviceType: customDeviceType,
                note: note,
                isKnown: isKnown,
                pingConfirmed: pingConfirmed,
                isGateway: isGateway,
                isLocalDevice: isLocalDevice,
                firstSeenAt: firstSeenAt,
                lastSeenAt: lastSeenAt,
                status: status,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int networkId,
                Value<String?> macAddress = const Value.absent(),
                required String currentIp,
                Value<String?> hostname = const Value.absent(),
                Value<String?> vendor = const Value.absent(),
                required String inferredType,
                Value<String?> inferredOs = const Value.absent(),
                required String confidence,
                Value<String?> osConfidence = const Value.absent(),
                Value<String> inferenceReasonsJson = const Value.absent(),
                Value<String?> customName = const Value.absent(),
                Value<String?> customDeviceType = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<bool> isKnown = const Value.absent(),
                Value<bool> pingConfirmed = const Value.absent(),
                Value<bool> isGateway = const Value.absent(),
                Value<bool> isLocalDevice = const Value.absent(),
                required DateTime firstSeenAt,
                required DateTime lastSeenAt,
                required String status,
              }) => DevicesCompanion.insert(
                id: id,
                networkId: networkId,
                macAddress: macAddress,
                currentIp: currentIp,
                hostname: hostname,
                vendor: vendor,
                inferredType: inferredType,
                inferredOs: inferredOs,
                confidence: confidence,
                osConfidence: osConfidence,
                inferenceReasonsJson: inferenceReasonsJson,
                customName: customName,
                customDeviceType: customDeviceType,
                note: note,
                isKnown: isKnown,
                pingConfirmed: pingConfirmed,
                isGateway: isGateway,
                isLocalDevice: isLocalDevice,
                firstSeenAt: firstSeenAt,
                lastSeenAt: lastSeenAt,
                status: status,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$DevicesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                networkId = false,
                deviceObservationsRefs = false,
                trafficSamplesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (deviceObservationsRefs) db.deviceObservations,
                    if (trafficSamplesRefs) db.trafficSamples,
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
                        if (networkId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.networkId,
                                    referencedTable: $$DevicesTableReferences
                                        ._networkIdTable(db),
                                    referencedColumn: $$DevicesTableReferences
                                        ._networkIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (deviceObservationsRefs)
                        await $_getPrefetchedData<
                          Device,
                          $DevicesTable,
                          DeviceObservation
                        >(
                          currentTable: table,
                          referencedTable: $$DevicesTableReferences
                              ._deviceObservationsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DevicesTableReferences(
                                db,
                                table,
                                p0,
                              ).deviceObservationsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.deviceId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (trafficSamplesRefs)
                        await $_getPrefetchedData<
                          Device,
                          $DevicesTable,
                          TrafficSample
                        >(
                          currentTable: table,
                          referencedTable: $$DevicesTableReferences
                              ._trafficSamplesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DevicesTableReferences(
                                db,
                                table,
                                p0,
                              ).trafficSamplesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.deviceId == item.id,
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

typedef $$DevicesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DevicesTable,
      Device,
      $$DevicesTableFilterComposer,
      $$DevicesTableOrderingComposer,
      $$DevicesTableAnnotationComposer,
      $$DevicesTableCreateCompanionBuilder,
      $$DevicesTableUpdateCompanionBuilder,
      (Device, $$DevicesTableReferences),
      Device,
      PrefetchHooks Function({
        bool networkId,
        bool deviceObservationsRefs,
        bool trafficSamplesRefs,
      })
    >;
typedef $$DeviceObservationsTableCreateCompanionBuilder =
    DeviceObservationsCompanion Function({
      Value<int> id,
      required int deviceId,
      required DateTime observedAt,
      required String ipAddress,
      Value<String?> hostname,
      Value<String> servicesJson,
      Value<String> signalsJson,
    });
typedef $$DeviceObservationsTableUpdateCompanionBuilder =
    DeviceObservationsCompanion Function({
      Value<int> id,
      Value<int> deviceId,
      Value<DateTime> observedAt,
      Value<String> ipAddress,
      Value<String?> hostname,
      Value<String> servicesJson,
      Value<String> signalsJson,
    });

final class $$DeviceObservationsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $DeviceObservationsTable,
          DeviceObservation
        > {
  $$DeviceObservationsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $DevicesTable _deviceIdTable(_$AppDatabase db) =>
      db.devices.createAlias(
        $_aliasNameGenerator(db.deviceObservations.deviceId, db.devices.id),
      );

  $$DevicesTableProcessedTableManager get deviceId {
    final $_column = $_itemColumn<int>('device_id')!;

    final manager = $$DevicesTableTableManager(
      $_db,
      $_db.devices,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_deviceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$DeviceObservationsTableFilterComposer
    extends Composer<_$AppDatabase, $DeviceObservationsTable> {
  $$DeviceObservationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get observedAt => $composableBuilder(
    column: $table.observedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ipAddress => $composableBuilder(
    column: $table.ipAddress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hostname => $composableBuilder(
    column: $table.hostname,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get servicesJson => $composableBuilder(
    column: $table.servicesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get signalsJson => $composableBuilder(
    column: $table.signalsJson,
    builder: (column) => ColumnFilters(column),
  );

  $$DevicesTableFilterComposer get deviceId {
    final $$DevicesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deviceId,
      referencedTable: $db.devices,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DevicesTableFilterComposer(
            $db: $db,
            $table: $db.devices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DeviceObservationsTableOrderingComposer
    extends Composer<_$AppDatabase, $DeviceObservationsTable> {
  $$DeviceObservationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get observedAt => $composableBuilder(
    column: $table.observedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ipAddress => $composableBuilder(
    column: $table.ipAddress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hostname => $composableBuilder(
    column: $table.hostname,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get servicesJson => $composableBuilder(
    column: $table.servicesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get signalsJson => $composableBuilder(
    column: $table.signalsJson,
    builder: (column) => ColumnOrderings(column),
  );

  $$DevicesTableOrderingComposer get deviceId {
    final $$DevicesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deviceId,
      referencedTable: $db.devices,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DevicesTableOrderingComposer(
            $db: $db,
            $table: $db.devices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DeviceObservationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DeviceObservationsTable> {
  $$DeviceObservationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get observedAt => $composableBuilder(
    column: $table.observedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ipAddress =>
      $composableBuilder(column: $table.ipAddress, builder: (column) => column);

  GeneratedColumn<String> get hostname =>
      $composableBuilder(column: $table.hostname, builder: (column) => column);

  GeneratedColumn<String> get servicesJson => $composableBuilder(
    column: $table.servicesJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get signalsJson => $composableBuilder(
    column: $table.signalsJson,
    builder: (column) => column,
  );

  $$DevicesTableAnnotationComposer get deviceId {
    final $$DevicesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deviceId,
      referencedTable: $db.devices,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DevicesTableAnnotationComposer(
            $db: $db,
            $table: $db.devices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DeviceObservationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DeviceObservationsTable,
          DeviceObservation,
          $$DeviceObservationsTableFilterComposer,
          $$DeviceObservationsTableOrderingComposer,
          $$DeviceObservationsTableAnnotationComposer,
          $$DeviceObservationsTableCreateCompanionBuilder,
          $$DeviceObservationsTableUpdateCompanionBuilder,
          (DeviceObservation, $$DeviceObservationsTableReferences),
          DeviceObservation,
          PrefetchHooks Function({bool deviceId})
        > {
  $$DeviceObservationsTableTableManager(
    _$AppDatabase db,
    $DeviceObservationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DeviceObservationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DeviceObservationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DeviceObservationsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> deviceId = const Value.absent(),
                Value<DateTime> observedAt = const Value.absent(),
                Value<String> ipAddress = const Value.absent(),
                Value<String?> hostname = const Value.absent(),
                Value<String> servicesJson = const Value.absent(),
                Value<String> signalsJson = const Value.absent(),
              }) => DeviceObservationsCompanion(
                id: id,
                deviceId: deviceId,
                observedAt: observedAt,
                ipAddress: ipAddress,
                hostname: hostname,
                servicesJson: servicesJson,
                signalsJson: signalsJson,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int deviceId,
                required DateTime observedAt,
                required String ipAddress,
                Value<String?> hostname = const Value.absent(),
                Value<String> servicesJson = const Value.absent(),
                Value<String> signalsJson = const Value.absent(),
              }) => DeviceObservationsCompanion.insert(
                id: id,
                deviceId: deviceId,
                observedAt: observedAt,
                ipAddress: ipAddress,
                hostname: hostname,
                servicesJson: servicesJson,
                signalsJson: signalsJson,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$DeviceObservationsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({deviceId = false}) {
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
                    if (deviceId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.deviceId,
                                referencedTable:
                                    $$DeviceObservationsTableReferences
                                        ._deviceIdTable(db),
                                referencedColumn:
                                    $$DeviceObservationsTableReferences
                                        ._deviceIdTable(db)
                                        .id,
                              )
                              as T;
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

typedef $$DeviceObservationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DeviceObservationsTable,
      DeviceObservation,
      $$DeviceObservationsTableFilterComposer,
      $$DeviceObservationsTableOrderingComposer,
      $$DeviceObservationsTableAnnotationComposer,
      $$DeviceObservationsTableCreateCompanionBuilder,
      $$DeviceObservationsTableUpdateCompanionBuilder,
      (DeviceObservation, $$DeviceObservationsTableReferences),
      DeviceObservation,
      PrefetchHooks Function({bool deviceId})
    >;
typedef $$TrafficSamplesTableCreateCompanionBuilder =
    TrafficSamplesCompanion Function({
      Value<int> id,
      required int deviceId,
      required String source,
      required DateTime periodStart,
      required DateTime periodEnd,
      required int downloadBytes,
      required int uploadBytes,
      required String reliability,
      Value<String?> macAddress,
      Value<String?> ipAddress,
    });
typedef $$TrafficSamplesTableUpdateCompanionBuilder =
    TrafficSamplesCompanion Function({
      Value<int> id,
      Value<int> deviceId,
      Value<String> source,
      Value<DateTime> periodStart,
      Value<DateTime> periodEnd,
      Value<int> downloadBytes,
      Value<int> uploadBytes,
      Value<String> reliability,
      Value<String?> macAddress,
      Value<String?> ipAddress,
    });

final class $$TrafficSamplesTableReferences
    extends BaseReferences<_$AppDatabase, $TrafficSamplesTable, TrafficSample> {
  $$TrafficSamplesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $DevicesTable _deviceIdTable(_$AppDatabase db) =>
      db.devices.createAlias(
        $_aliasNameGenerator(db.trafficSamples.deviceId, db.devices.id),
      );

  $$DevicesTableProcessedTableManager get deviceId {
    final $_column = $_itemColumn<int>('device_id')!;

    final manager = $$DevicesTableTableManager(
      $_db,
      $_db.devices,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_deviceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TrafficSamplesTableFilterComposer
    extends Composer<_$AppDatabase, $TrafficSamplesTable> {
  $$TrafficSamplesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get periodStart => $composableBuilder(
    column: $table.periodStart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get periodEnd => $composableBuilder(
    column: $table.periodEnd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get downloadBytes => $composableBuilder(
    column: $table.downloadBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get uploadBytes => $composableBuilder(
    column: $table.uploadBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reliability => $composableBuilder(
    column: $table.reliability,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get macAddress => $composableBuilder(
    column: $table.macAddress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ipAddress => $composableBuilder(
    column: $table.ipAddress,
    builder: (column) => ColumnFilters(column),
  );

  $$DevicesTableFilterComposer get deviceId {
    final $$DevicesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deviceId,
      referencedTable: $db.devices,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DevicesTableFilterComposer(
            $db: $db,
            $table: $db.devices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TrafficSamplesTableOrderingComposer
    extends Composer<_$AppDatabase, $TrafficSamplesTable> {
  $$TrafficSamplesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get periodStart => $composableBuilder(
    column: $table.periodStart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get periodEnd => $composableBuilder(
    column: $table.periodEnd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get downloadBytes => $composableBuilder(
    column: $table.downloadBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get uploadBytes => $composableBuilder(
    column: $table.uploadBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reliability => $composableBuilder(
    column: $table.reliability,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get macAddress => $composableBuilder(
    column: $table.macAddress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ipAddress => $composableBuilder(
    column: $table.ipAddress,
    builder: (column) => ColumnOrderings(column),
  );

  $$DevicesTableOrderingComposer get deviceId {
    final $$DevicesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deviceId,
      referencedTable: $db.devices,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DevicesTableOrderingComposer(
            $db: $db,
            $table: $db.devices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TrafficSamplesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TrafficSamplesTable> {
  $$TrafficSamplesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<DateTime> get periodStart => $composableBuilder(
    column: $table.periodStart,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get periodEnd =>
      $composableBuilder(column: $table.periodEnd, builder: (column) => column);

  GeneratedColumn<int> get downloadBytes => $composableBuilder(
    column: $table.downloadBytes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get uploadBytes => $composableBuilder(
    column: $table.uploadBytes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reliability => $composableBuilder(
    column: $table.reliability,
    builder: (column) => column,
  );

  GeneratedColumn<String> get macAddress => $composableBuilder(
    column: $table.macAddress,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ipAddress =>
      $composableBuilder(column: $table.ipAddress, builder: (column) => column);

  $$DevicesTableAnnotationComposer get deviceId {
    final $$DevicesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deviceId,
      referencedTable: $db.devices,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DevicesTableAnnotationComposer(
            $db: $db,
            $table: $db.devices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TrafficSamplesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TrafficSamplesTable,
          TrafficSample,
          $$TrafficSamplesTableFilterComposer,
          $$TrafficSamplesTableOrderingComposer,
          $$TrafficSamplesTableAnnotationComposer,
          $$TrafficSamplesTableCreateCompanionBuilder,
          $$TrafficSamplesTableUpdateCompanionBuilder,
          (TrafficSample, $$TrafficSamplesTableReferences),
          TrafficSample,
          PrefetchHooks Function({bool deviceId})
        > {
  $$TrafficSamplesTableTableManager(
    _$AppDatabase db,
    $TrafficSamplesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TrafficSamplesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TrafficSamplesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TrafficSamplesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> deviceId = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<DateTime> periodStart = const Value.absent(),
                Value<DateTime> periodEnd = const Value.absent(),
                Value<int> downloadBytes = const Value.absent(),
                Value<int> uploadBytes = const Value.absent(),
                Value<String> reliability = const Value.absent(),
                Value<String?> macAddress = const Value.absent(),
                Value<String?> ipAddress = const Value.absent(),
              }) => TrafficSamplesCompanion(
                id: id,
                deviceId: deviceId,
                source: source,
                periodStart: periodStart,
                periodEnd: periodEnd,
                downloadBytes: downloadBytes,
                uploadBytes: uploadBytes,
                reliability: reliability,
                macAddress: macAddress,
                ipAddress: ipAddress,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int deviceId,
                required String source,
                required DateTime periodStart,
                required DateTime periodEnd,
                required int downloadBytes,
                required int uploadBytes,
                required String reliability,
                Value<String?> macAddress = const Value.absent(),
                Value<String?> ipAddress = const Value.absent(),
              }) => TrafficSamplesCompanion.insert(
                id: id,
                deviceId: deviceId,
                source: source,
                periodStart: periodStart,
                periodEnd: periodEnd,
                downloadBytes: downloadBytes,
                uploadBytes: uploadBytes,
                reliability: reliability,
                macAddress: macAddress,
                ipAddress: ipAddress,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TrafficSamplesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({deviceId = false}) {
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
                    if (deviceId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.deviceId,
                                referencedTable: $$TrafficSamplesTableReferences
                                    ._deviceIdTable(db),
                                referencedColumn:
                                    $$TrafficSamplesTableReferences
                                        ._deviceIdTable(db)
                                        .id,
                              )
                              as T;
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

typedef $$TrafficSamplesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TrafficSamplesTable,
      TrafficSample,
      $$TrafficSamplesTableFilterComposer,
      $$TrafficSamplesTableOrderingComposer,
      $$TrafficSamplesTableAnnotationComposer,
      $$TrafficSamplesTableCreateCompanionBuilder,
      $$TrafficSamplesTableUpdateCompanionBuilder,
      (TrafficSample, $$TrafficSamplesTableReferences),
      TrafficSample,
      PrefetchHooks Function({bool deviceId})
    >;
typedef $$ScanSessionsTableCreateCompanionBuilder =
    ScanSessionsCompanion Function({
      Value<int> id,
      required int networkId,
      required DateTime startedAt,
      Value<DateTime?> finishedAt,
      required String targetCidrsJson,
      required String status,
      Value<int> hostsScanned,
      Value<int> devicesFound,
      Value<String?> checkpointJson,
      Value<String?> errorMessage,
    });
typedef $$ScanSessionsTableUpdateCompanionBuilder =
    ScanSessionsCompanion Function({
      Value<int> id,
      Value<int> networkId,
      Value<DateTime> startedAt,
      Value<DateTime?> finishedAt,
      Value<String> targetCidrsJson,
      Value<String> status,
      Value<int> hostsScanned,
      Value<int> devicesFound,
      Value<String?> checkpointJson,
      Value<String?> errorMessage,
    });

final class $$ScanSessionsTableReferences
    extends BaseReferences<_$AppDatabase, $ScanSessionsTable, ScanSession> {
  $$ScanSessionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $NetworksTable _networkIdTable(_$AppDatabase db) =>
      db.networks.createAlias(
        $_aliasNameGenerator(db.scanSessions.networkId, db.networks.id),
      );

  $$NetworksTableProcessedTableManager get networkId {
    final $_column = $_itemColumn<int>('network_id')!;

    final manager = $$NetworksTableTableManager(
      $_db,
      $_db.networks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_networkIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ScanSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $ScanSessionsTable> {
  $$ScanSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetCidrsJson => $composableBuilder(
    column: $table.targetCidrsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hostsScanned => $composableBuilder(
    column: $table.hostsScanned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get devicesFound => $composableBuilder(
    column: $table.devicesFound,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get checkpointJson => $composableBuilder(
    column: $table.checkpointJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnFilters(column),
  );

  $$NetworksTableFilterComposer get networkId {
    final $$NetworksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.networkId,
      referencedTable: $db.networks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NetworksTableFilterComposer(
            $db: $db,
            $table: $db.networks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ScanSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $ScanSessionsTable> {
  $$ScanSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetCidrsJson => $composableBuilder(
    column: $table.targetCidrsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hostsScanned => $composableBuilder(
    column: $table.hostsScanned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get devicesFound => $composableBuilder(
    column: $table.devicesFound,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get checkpointJson => $composableBuilder(
    column: $table.checkpointJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnOrderings(column),
  );

  $$NetworksTableOrderingComposer get networkId {
    final $$NetworksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.networkId,
      referencedTable: $db.networks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NetworksTableOrderingComposer(
            $db: $db,
            $table: $db.networks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ScanSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ScanSessionsTable> {
  $$ScanSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get targetCidrsJson => $composableBuilder(
    column: $table.targetCidrsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get hostsScanned => $composableBuilder(
    column: $table.hostsScanned,
    builder: (column) => column,
  );

  GeneratedColumn<int> get devicesFound => $composableBuilder(
    column: $table.devicesFound,
    builder: (column) => column,
  );

  GeneratedColumn<String> get checkpointJson => $composableBuilder(
    column: $table.checkpointJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => column,
  );

  $$NetworksTableAnnotationComposer get networkId {
    final $$NetworksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.networkId,
      referencedTable: $db.networks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NetworksTableAnnotationComposer(
            $db: $db,
            $table: $db.networks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ScanSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ScanSessionsTable,
          ScanSession,
          $$ScanSessionsTableFilterComposer,
          $$ScanSessionsTableOrderingComposer,
          $$ScanSessionsTableAnnotationComposer,
          $$ScanSessionsTableCreateCompanionBuilder,
          $$ScanSessionsTableUpdateCompanionBuilder,
          (ScanSession, $$ScanSessionsTableReferences),
          ScanSession,
          PrefetchHooks Function({bool networkId})
        > {
  $$ScanSessionsTableTableManager(_$AppDatabase db, $ScanSessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ScanSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ScanSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ScanSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> networkId = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> finishedAt = const Value.absent(),
                Value<String> targetCidrsJson = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> hostsScanned = const Value.absent(),
                Value<int> devicesFound = const Value.absent(),
                Value<String?> checkpointJson = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
              }) => ScanSessionsCompanion(
                id: id,
                networkId: networkId,
                startedAt: startedAt,
                finishedAt: finishedAt,
                targetCidrsJson: targetCidrsJson,
                status: status,
                hostsScanned: hostsScanned,
                devicesFound: devicesFound,
                checkpointJson: checkpointJson,
                errorMessage: errorMessage,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int networkId,
                required DateTime startedAt,
                Value<DateTime?> finishedAt = const Value.absent(),
                required String targetCidrsJson,
                required String status,
                Value<int> hostsScanned = const Value.absent(),
                Value<int> devicesFound = const Value.absent(),
                Value<String?> checkpointJson = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
              }) => ScanSessionsCompanion.insert(
                id: id,
                networkId: networkId,
                startedAt: startedAt,
                finishedAt: finishedAt,
                targetCidrsJson: targetCidrsJson,
                status: status,
                hostsScanned: hostsScanned,
                devicesFound: devicesFound,
                checkpointJson: checkpointJson,
                errorMessage: errorMessage,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ScanSessionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({networkId = false}) {
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
                    if (networkId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.networkId,
                                referencedTable: $$ScanSessionsTableReferences
                                    ._networkIdTable(db),
                                referencedColumn: $$ScanSessionsTableReferences
                                    ._networkIdTable(db)
                                    .id,
                              )
                              as T;
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

typedef $$ScanSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ScanSessionsTable,
      ScanSession,
      $$ScanSessionsTableFilterComposer,
      $$ScanSessionsTableOrderingComposer,
      $$ScanSessionsTableAnnotationComposer,
      $$ScanSessionsTableCreateCompanionBuilder,
      $$ScanSessionsTableUpdateCompanionBuilder,
      (ScanSession, $$ScanSessionsTableReferences),
      ScanSession,
      PrefetchHooks Function({bool networkId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$NetworksTableTableManager get networks =>
      $$NetworksTableTableManager(_db, _db.networks);
  $$DevicesTableTableManager get devices =>
      $$DevicesTableTableManager(_db, _db.devices);
  $$DeviceObservationsTableTableManager get deviceObservations =>
      $$DeviceObservationsTableTableManager(_db, _db.deviceObservations);
  $$TrafficSamplesTableTableManager get trafficSamples =>
      $$TrafficSamplesTableTableManager(_db, _db.trafficSamples);
  $$ScanSessionsTableTableManager get scanSessions =>
      $$ScanSessionsTableTableManager(_db, _db.scanSessions);
}
