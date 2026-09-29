import 'dart:convert';

import 'package:grumpy_io/grumpy_io.dart';
import 'package:tug/src/app/app.dart';
import 'package:tug/src/coolify/domain/domain.dart';

/// Parses Coolify v4 JSON while keeping response bodies out of exceptions.
class RestCoolifyDatasource extends CoolifyDatasource {
  RestCoolifyDatasource(this.api) : super.internal();
  final CoolifyApiService api;
  Object? _decode(NetworkResponse response) {
    try {
      if (response.bodyBytes.isEmpty) return null;
      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      throw const TugException('Coolify returned malformed JSON.');
    }
  }

  Map<String, dynamic> _object(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const TugException('Coolify returned an unexpected object.');
    }
    return value;
  }

  List<dynamic> _list(Object? value) {
    if (value is Map && value['data'] is List) value = value['data'];
    if (value is! List) {
      throw const TugException('Coolify returned an unexpected resource list.');
    }
    return value;
  }

  String _required(Map<String, dynamic> value, String key) {
    final field = value[key];
    if (field is! String || field.isEmpty) {
      throw TugException('Coolify response is missing $key.');
    }
    return field;
  }

  String? _string(Object? value) => value == null ? null : '$value';
  bool? _bool(Object? value) => switch (value) {
    true || 1 || '1' => true,
    false || 0 || '0' => false,
    _ => null,
  };
  RemoteResource _resource(Object? value, String kind, {String? environment}) {
    final v = _object(value);
    final destination = v['destination'];
    final settings = v['settings'] is Map ? v['settings'] as Map : const {};
    final tags = v['tags'] as List? ?? const [];
    return RemoteResource(
      uuid: _required(v, 'uuid'),
      name: _string(v['name']) ?? '',
      kind: kind,
      description: _string(v['description']) ?? '',
      status: _string(v['status']) ?? '',
      tags: tags
          .map(
            (t) => t is String
                ? t
                : t is Map
                ? '${t['name']}'
                : '',
          )
          .toList(),
      environment: environment ?? _string(v['environment_uuid']),
      destination:
          _string(v['destination_uuid']) ??
          (destination is Map ? _string(destination['uuid']) : null),
      server:
          _string(v['server_uuid']) ??
          (destination is Map && destination['server'] is Map
              ? _string(destination['server']['uuid'])
              : null),
      repository: _string(v['git_repository']),
      branch: _string(v['git_branch']),
      domains: _string(v['fqdn'] ?? v['domains']),
      image: _string(v['image']),
      databaseName: _string(v['postgres_db']),
      databaseUser: _string(v['postgres_user']),
      isPublic: _bool(v['is_public']) ?? false,
      buildPack: _string(v['build_pack']),
      dockerfile: _string(v['dockerfile_location']),
      ports: _string(v['ports_exposes']),
      baseDirectory: _string(v['base_directory']),
      forceHttps: _bool(
        v['is_force_https_enabled'] ?? settings['is_force_https_enabled'],
      ),
      previewEnabled: _bool(
        v['is_preview_deployments_enabled'] ??
            settings['is_preview_deployments_enabled'],
      ),
    );
  }

  @override
  Future<List<RemoteResource>> list(
    CoolifyOperation operation, {
    String? uuid,
  }) async {
    final kind = switch (operation) {
      CoolifyOperation.projects => 'project',
      CoolifyOperation.environments => 'environment',
      CoolifyOperation.servers => 'server',
      CoolifyOperation.destinations => 'destination',
      CoolifyOperation.githubApps => 'githubApp',
      CoolifyOperation.applications => 'application',
      CoolifyOperation.databases => 'database',
      _ => throw const TugException('Unsupported listing.'),
    };
    return _list(_decode(await api.execute(operation, uuid: uuid)))
        .map((e) => _resource(e, kind))
        .toList();
  }

  @override
  Future<RemoteResource> get(String kind, String uuid) async {
    final op = switch (kind) {
      'application' => CoolifyOperation.application,
      'project' => CoolifyOperation.project,
      'server' => CoolifyOperation.server,
      _ => CoolifyOperation.database,
    };
    final data = _object(_decode(await api.execute(op, uuid: uuid)));
    if (kind == 'application' || kind == 'postgres' || kind == 'redis') {
      data['tags'] = _list(
        _decode(
          await api.execute(
            kind == 'application'
                ? CoolifyOperation.applicationTags
                : CoolifyOperation.databaseTags,
            uuid: uuid,
          ),
        ),
      );
    }
    return _resource(data, kind);
  }

  @override
  Future<List<RemoteResource>> resources(
    String project,
    String environment,
  ) async {
    final data = _object(
      _decode(
        await api.execute(
          CoolifyOperation.environment,
          uuid: environment,
          parent: project,
        ),
      ),
    );
    final result = <RemoteResource>[];
    // Include unsupported resources too: destroy must never cascade over them.
    for (final entry in data.entries) {
      if (entry.value is! List) continue;
      final kind = switch (entry.key) {
        'applications' => 'application',
        'postgresqls' || 'postgresql' => 'postgres',
        'redis' || 'redis_dbs' => 'redis',
        _ => 'unmanaged',
      };
      for (final value in entry.value as List) {
        if (value is Map && value['uuid'] != null) {
          result.add(
            kind == 'unmanaged'
                ? _resource(value, kind, environment: environment)
                : await get(kind, value['uuid'] as String),
          );
        }
      }
    }
    // Coolify's environment endpoint omits some database families (for example
    // KeyDB). Supplement it from the complete database inventory so destruction
    // cannot overlook persistent resources before its first mutation.
    final databases = _list(
      _decode(await api.execute(CoolifyOperation.databases)),
    );
    for (final raw in databases) {
      final value = _object(raw);
      final belongs =
          value['environment_uuid'] == environment ||
          (data['id'] != null && value['environment_id'] == data['id']);
      if (belongs && !result.any((r) => r.uuid == value['uuid'])) {
        result.add(_resource(value, 'unmanaged', environment: environment));
      }
    }
    return result;
  }

  @override
  Future<String> create(
    CoolifyOperation operation,
    Map<String, Object?> values, {
    String? parent,
  }) async {
    final data = _decode(
      await api.execute(operation, uuid: parent, values: values),
    );
    if (data is Map<String, dynamic> && data['uuid'] is String) {
      return data['uuid'] as String;
    }
    throw const TugException(
      'Creation returned no UUID. Run apply again to rediscover the resource.',
      uncertain: true,
    );
  }

  @override
  Future<void> mutate(
    CoolifyOperation operation, {
    String? uuid,
    String? parent,
    Map<String, Object?> values = const {},
  }) async {
    await api.execute(operation, uuid: uuid, parent: parent, values: values);
  }

  @override
  Future<Map<String, RemoteVariable>> variables(String application) async {
    final values = _list(
      _decode(await api.execute(CoolifyOperation.variables, uuid: application)),
    );
    final result = <String, RemoteVariable>{};
    for (final raw in values) {
      final v = _object(raw);
      if (_bool(v['is_preview']) == true) continue;
      final key = _required(v, 'key');
      if (result.containsKey(key)) {
        throw TugException('Duplicate Coolify variable: $key.');
      }
      result[key] = RemoteVariable(
        uuid: _required(v, 'uuid'),
        key: key,
        value: _string(v['value']),
        runtime: _bool(v['is_runtime']) ?? false,
        buildtime: _bool(v['is_buildtime']) ?? false,
        literal: _bool(v['is_literal']) ?? false,
      );
    }
    return result;
  }

  @override
  Future<ConnectionInfo> connection(String database) async {
    final v = _object(
      _decode(await api.execute(CoolifyOperation.database, uuid: database)),
    );
    final raw = v['internal_db_url'];
    if (raw is! String || raw.isEmpty) {
      throw const TugException(
        'Database internal URL is unavailable. Grant read:sensitive permission.',
      );
    }
    try {
      final uri = Uri.parse(raw);
      if (!['postgres', 'postgresql', 'redis', 'rediss'].contains(uri.scheme) ||
          uri.host.isEmpty) {
        throw const FormatException();
      }
      final split = uri.userInfo.indexOf(':');
      if (split < 0) throw const FormatException();
      final user = Uri.decodeComponent(uri.userInfo.substring(0, split));
      final password = Uri.decodeComponent(uri.userInfo.substring(split + 1));
      if (password.isEmpty) throw const FormatException();
      return ConnectionInfo(
        host: uri.host,
        port: uri.hasPort
            ? uri.port
            : uri.scheme.startsWith('redis')
            ? 6379
            : 5432,
        user: user,
        password: password,
        database: uri.pathSegments.isEmpty ? '' : uri.pathSegments.first,
      );
    } catch (_) {
      throw const TugException(
        'Coolify returned an invalid internal database URL (redacted).',
      );
    }
  }

  DeploymentInfo _deployment(Object? raw) {
    final v = _object(raw);
    var logs = v['logs'];
    if (logs is String) {
      try {
        logs = jsonDecode(logs);
      } catch (_) {}
    }
    if (logs is List) {
      logs = logs
          .map((e) => e is Map ? '${e['output'] ?? ''}' : '$e')
          .join('\n');
    }
    return DeploymentInfo(
      '${v['deployment_uuid'] ?? v['uuid'] ?? ''}',
      _required(v, 'status'),
      _string(logs) ?? '',
    );
  }

  @override
  Future<DeploymentInfo> deployment(String uuid) async => _deployment(
    _decode(await api.execute(CoolifyOperation.deployment, uuid: uuid)),
  );
  @override
  Future<DeploymentInfo?> latestDeployment(String application) async {
    final raw = _decode(
      await api.execute(CoolifyOperation.deployments, uuid: application),
    );
    final items = _list(
      raw is Map && raw['deployments'] is List ? raw['deployments'] : raw,
    );
    return items.isEmpty ? null : _deployment(items.first);
  }

  @override
  Future<String> deploy(String application) async {
    final v = _object(
      _decode(await api.execute(CoolifyOperation.deploy, uuid: application)),
    );
    final items = _list(v['deployments']);
    if (items.isEmpty) {
      throw const TugException(
        'Coolify did not return a deployment identifier.',
        uncertain: true,
      );
    }
    return _required(_object(items.first), 'deployment_uuid');
  }

  @override
  Future<String> logs(String application) async {
    final raw = _decode(
      await api.execute(CoolifyOperation.logs, uuid: application),
    );
    if (raw is String) return raw;
    return _string(_object(raw)['logs']) ?? '';
  }

  @override
  Future<bool> hasStorage(String application) async {
    final raw = _decode(
      await api.execute(CoolifyOperation.storages, uuid: application),
    );
    if (raw is List) return raw.isNotEmpty;
    final object = _object(raw);
    return _list(object['persistent_storages']).isNotEmpty ||
        _list(object['file_storages']).isNotEmpty;
  }

  @override
  String get logTag => 'RestCoolifyDatasource';
  @override
  Future<void> destroy() async {}
}
