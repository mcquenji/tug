import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import '../../../shared/domain/models/tug_exception.dart';
import '../../domain/datasources/serverpod_config_datasource.dart';
import '../../domain/models/config_import.dart';

/// Native Serverpod files are import sources, independent of Tug's config store.
class NativeServerpodConfigDatasource extends ServerpodConfigDatasource {
  NativeServerpodConfigDatasource() : super.internal();

  static const mappings = <String, String>{
    'serverId': 'SERVER_ID',
    'role': 'SERVER_ROLE',
    'logging': 'LOGGING_MODE',
    'applyMigrations': 'APPLY_MIGRATIONS',
    'applyRepairMigration': 'APPLY_REPAIR_MIGRATION',
    'apiServer.port': 'API_SERVER_PORT',
    'apiServer.publicHost': 'API_SERVER_PUBLIC_HOST',
    'apiServer.publicPort': 'API_SERVER_PUBLIC_PORT',
    'apiServer.publicScheme': 'API_SERVER_PUBLIC_SCHEME',
    'webServer.port': 'WEB_SERVER_PORT',
    'webServer.publicHost': 'WEB_SERVER_PUBLIC_HOST',
    'webServer.publicPort': 'WEB_SERVER_PUBLIC_PORT',
    'webServer.publicScheme': 'WEB_SERVER_PUBLIC_SCHEME',
    'insightsServer.port': 'INSIGHTS_SERVER_PORT',
    'insightsServer.publicHost': 'INSIGHTS_SERVER_PUBLIC_HOST',
    'insightsServer.publicPort': 'INSIGHTS_SERVER_PUBLIC_PORT',
    'insightsServer.publicScheme': 'INSIGHTS_SERVER_PUBLIC_SCHEME',
    'insightsServer.enableDatabaseAccess':
        'INSIGHTS_SERVER_ENABLE_DATABASE_ACCESS',
    'database.host': 'DATABASE_HOST',
    'database.port': 'DATABASE_PORT',
    'database.name': 'DATABASE_NAME',
    'database.user': 'DATABASE_USER',
    'database.searchPaths': 'DATABASE_SEARCH_PATHS',
    'database.requireSsl': 'DATABASE_REQUIRE_SSL',
    'database.isUnixSocket': 'DATABASE_IS_UNIX_SOCKET',
    'database.maxConnectionCount': 'DATABASE_MAX_CONNECTION_COUNT',
    'database.dataPath': 'DATABASE_DATA_PATH',
    'redis.host': 'REDIS_HOST',
    'redis.port': 'REDIS_PORT',
    'redis.user': 'REDIS_USER',
    'redis.enabled': 'REDIS_ENABLED',
    'redis.requireSsl': 'REDIS_REQUIRE_SSL',
    'maxRequestSize': 'MAX_REQUEST_SIZE',
    'validateHeaders': 'VALIDATE_HEADERS',
    'allowedOrigins': 'ALLOWED_ORIGINS',
    'authCookie.name': 'AUTH_COOKIE_NAME',
    'authCookie.refreshName': 'AUTH_COOKIE_REFRESH_NAME',
    'authCookie.domain': 'AUTH_COOKIE_DOMAIN',
    'authCookie.path': 'AUTH_COOKIE_PATH',
    'authCookie.secure': 'AUTH_COOKIE_SECURE',
    'authCookie.sameSite': 'AUTH_COOKIE_SAME_SITE',
    'sessionLogs.persistentEnabled': 'SESSION_PERSISTENT_LOG_ENABLED',
    'sessionLogs.consoleEnabled': 'SESSION_CONSOLE_LOG_ENABLED',
    'sessionLogs.consoleLogFormat': 'SESSION_CONSOLE_LOG_FORMAT',
    'sessionLogs.cleanupInterval': 'SESSION_LOG_CLEANUP_INTERVAL',
    'sessionLogs.retentionPeriod': 'SESSION_LOG_RETENTION_PERIOD',
    'sessionLogs.retentionCount': 'SESSION_LOG_RETENTION_COUNT',
    'futureCallExecutionEnabled': 'FUTURE_CALL_EXECUTION_ENABLED',
    'futureCall.executionEnabled': 'FUTURE_CALL_EXECUTION_ENABLED',
    'futureCall.enabled': 'FUTURE_CALL_ENABLED',
    'futureCall.concurrencyLimit': 'FUTURE_CALL_CONCURRENCY_LIMIT',
    'futureCall.scanInterval': 'FUTURE_CALL_SCAN_INTERVAL',
    'futureCall.checkBrokenCalls': 'FUTURE_CALL_CHECK_BROKEN_CALLS',
    'futureCall.deleteBrokenCalls': 'FUTURE_CALL_DELETE_BROKEN_CALLS',
    'websocketPingInterval': 'WEBSOCKET_PING_INTERVAL',
  };
  static const nullable = {
    'sessionLogs.cleanupInterval',
    'sessionLogs.retentionPeriod',
    'sessionLogs.retentionCount',
    'futureCall.concurrencyLimit',
    'futureCall.checkBrokenCalls',
  };
  static const lists = {'database.searchPaths', 'allowedOrigins'};
  static const booleans = {
    'applyMigrations',
    'applyRepairMigration',
    'insightsServer.enableDatabaseAccess',
    'database.requireSsl',
    'database.isUnixSocket',
    'redis.enabled',
    'redis.requireSsl',
    'validateHeaders',
    'authCookie.secure',
    'sessionLogs.persistentEnabled',
    'sessionLogs.consoleEnabled',
    'futureCallExecutionEnabled',
    'futureCall.executionEnabled',
    'futureCall.enabled',
    'futureCall.checkBrokenCalls',
    'futureCall.deleteBrokenCalls',
  };
  static const integers = {
    'apiServer.port',
    'apiServer.publicPort',
    'webServer.port',
    'webServer.publicPort',
    'insightsServer.port',
    'insightsServer.publicPort',
    'database.port',
    'database.maxConnectionCount',
    'redis.port',
    'maxRequestSize',
    'sessionLogs.retentionCount',
    'futureCall.concurrencyLimit',
    'futureCall.scanInterval',
    'websocketPingInterval',
  };

  Future<Map?> _read(File file) async {
    if (!await file.exists()) return null;
    try {
      final parsed = loadYaml(await file.readAsString());
      if (parsed == null) return {};
      if (parsed is Map) return parsed;
    } catch (_) {
      throw TugException(
        'Cannot parse ${file.path}; source contents are redacted.',
      );
    }
    throw TugException('Expected a mapping in ${file.path}.');
  }

  @override
  Future<ConfigImport> read(String serverDirectory, String mode) async {
    if (!RegExp(r'^[a-z][a-z0-9_-]*$').hasMatch(mode)) {
      throw const TugException('Invalid configMode; use a simple mode name.');
    }
    final values = <String, String>{};
    final sources = <String>[];
    final unsupported = <String>[];
    final configFile = File(p.join(serverDirectory, 'config', '$mode.yaml'));
    final config = await _read(configFile);
    if (config != null) {
      sources.add(configFile.path);
      void visit(Map object, String prefix) {
        for (final entry in object.entries) {
          final field = prefix.isEmpty
              ? '${entry.key}'
              : '$prefix.${entry.key}';
          final name = mappings[field];
          final value = entry.value;
          if (name == null) {
            if (value is Map &&
                mappings.keys.any((k) => k.startsWith('$field.'))) {
              visit(value, field);
            } else {
              unsupported.add(field);
            }
            continue;
          }
          if (value == null && nullable.contains(field)) {
            if (field == 'futureCall.concurrencyLimit') {
              values['SERVERPOD_$name'] = '-1';
              continue;
            }
            throw TugException(
              'Unsupported null at ${configFile.path}:$field. Serverpod 4.0 environment parsing cannot represent this value; configure a supported explicit value.',
            );
          }
          final valid = value == null
              ? nullable.contains(field)
              : lists.contains(field)
              ? value is List &&
                    value.every((v) => v is String && !v.contains(','))
              : booleans.contains(field)
              ? value is bool
              : integers.contains(field)
              ? value is int
              : value is String;
          if (!valid) {
            throw TugException(
              'Invalid Serverpod setting ${configFile.path}:$field (value redacted).',
            );
          }
          values['SERVERPOD_$name'] = value is List
              ? value.join(',')
              : '$value';
        }
      }

      visit(config, '');
    }
    if (unsupported.isNotEmpty) {
      throw TugException(
        'Unsupported Serverpod settings in ${configFile.path}: ${unsupported.join(', ')}. Move application-specific configuration to explicit environment variables.',
      );
    }
    final passwordsFile = File(
      p.join(serverDirectory, 'config', 'passwords.yaml'),
    );
    final passwords = await _read(passwordsFile);
    if (passwords != null) {
      sources.add(passwordsFile.path);
      for (final section in ['shared', mode]) {
        final entries = passwords[section];
        if (entries == null) continue;
        if (entries is! Map) {
          throw TugException(
            'Expected a mapping at ${passwordsFile.path}:$section.',
          );
        }
        for (final entry in entries.entries) {
          final key = entry.key;
          if (key is! String ||
              !RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$').hasMatch(key)) {
            throw TugException(
              'Invalid password key in ${passwordsFile.path}:$section (redacted).',
            );
          }
          if (entry.value is! String) {
            throw TugException(
              'Expected a string at ${passwordsFile.path}:$section.$key (redacted).',
            );
          }
          values['SERVERPOD_PASSWORD_$key'] = entry.value as String;
        }
      }
    }
    return ConfigImport(Map.unmodifiable(values), List.unmodifiable(sources));
  }

  @override
  String get logTag => 'NativeServerpodConfigDatasource';
  @override
  Future<void> destroy() async {}
}
