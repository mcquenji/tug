import 'dart:convert';
import 'dart:io' show HttpDate;

import 'package:grumpy_cli/grumpy_cli.dart';
import 'package:grumpy_io/grumpy_io.dart';
import 'package:tug/src/app/app.dart';
import 'package:tug/src/coolify/domain/domain.dart';

/// Coolify v4 REST mapping with bounded reads and no blind mutation retries.
class RestCoolifyApiService extends CoolifyApiService {
  RestCoolifyApiService(
    this.network,
    this.cancellation, {
    Future<void> Function(Duration)? delay,
    this.terminal,
  }) : _delay = delay ?? Future<void>.delayed,
       super.internal();
  final NetworkService network;
  final CancellationToken cancellation;
  final TerminalService? terminal;
  final Future<void> Function(Duration) _delay;
  Uri? _base;
  String? _token;

  @override
  void configure(CoolifyContext context, String token) {
    final uri = Uri.tryParse(context.url);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw const TugException(
        'Coolify URL must be an HTTPS URL without credentials, query, or fragment.',
      );
    }
    final path = uri.path.replaceFirst(RegExp(r'/+$'), '');
    _base = uri.replace(
      path: path.endsWith('/api/v1') ? '$path/' : '$path/api/v1/',
    );
    _token = token;
  }

  @override
  Future<NetworkResponse> execute(
    CoolifyOperation operation, {
    String? uuid,
    String? parent,
    Map<String, Object?> values = const {},
  }) async {
    if (_base == null || _token == null) {
      throw const TugException('Select a Coolify context first.');
    }
    final id = Uri.encodeComponent(uuid ?? '');
    final owner = Uri.encodeComponent(parent ?? '');
    final (method, path) = switch (operation) {
      CoolifyOperation.applicationTags => (
        HttpMethod.get,
        'applications/$id/tags',
      ),
      CoolifyOperation.databaseTags => (HttpMethod.get, 'databases/$id/tags'),
      CoolifyOperation.projects => (HttpMethod.get, 'projects'),
      CoolifyOperation.project => (HttpMethod.get, 'projects/$id'),
      CoolifyOperation.createProject => (HttpMethod.post, 'projects'),
      CoolifyOperation.deleteProject => (HttpMethod.delete, 'projects/$id'),
      CoolifyOperation.environments => (
        HttpMethod.get,
        'projects/$id/environments',
      ),
      CoolifyOperation.environment => (HttpMethod.get, 'projects/$owner/$id'),
      CoolifyOperation.createEnvironment => (
        HttpMethod.post,
        'projects/$id/environments',
      ),
      CoolifyOperation.deleteEnvironment => (
        HttpMethod.delete,
        'projects/$owner/environments/$id',
      ),
      CoolifyOperation.servers => (HttpMethod.get, 'servers'),
      CoolifyOperation.server => (HttpMethod.get, 'servers/$id'),
      CoolifyOperation.destinations => (
        HttpMethod.get,
        'servers/$id/destinations',
      ),
      CoolifyOperation.githubApps => (HttpMethod.get, 'github-apps'),
      CoolifyOperation.applications => (HttpMethod.get, 'applications'),
      CoolifyOperation.application => (HttpMethod.get, 'applications/$id'),
      CoolifyOperation.createApplication => (
        HttpMethod.post,
        'applications/private-github-app',
      ),
      CoolifyOperation.updateApplication => (
        HttpMethod.patch,
        'applications/$id',
      ),
      CoolifyOperation.deleteApplication => (
        HttpMethod.delete,
        'applications/$id',
      ),
      CoolifyOperation.variables => (HttpMethod.get, 'applications/$id/envs'),
      CoolifyOperation.upsertVariables => (
        HttpMethod.patch,
        'applications/$id/envs/bulk',
      ),
      CoolifyOperation.deleteVariable => (
        HttpMethod.delete,
        'applications/$owner/envs/$id',
      ),
      CoolifyOperation.storages => (
        HttpMethod.get,
        'applications/$id/storages',
      ),
      CoolifyOperation.databases => (HttpMethod.get, 'databases'),
      CoolifyOperation.database => (HttpMethod.get, 'databases/$id'),
      CoolifyOperation.createDatabase => (
        HttpMethod.post,
        'databases/${values['kind'] == 'redis' ? 'redis' : 'postgresql'}',
      ),
      CoolifyOperation.startDatabase => (
        HttpMethod.post,
        'databases/$id/start',
      ),
      CoolifyOperation.deleteDatabase => (HttpMethod.delete, 'databases/$id'),
      CoolifyOperation.deploy => (HttpMethod.post, 'deploy'),
      CoolifyOperation.deployment => (HttpMethod.get, 'deployments/$id'),
      CoolifyOperation.deployments => (
        HttpMethod.get,
        'deployments/applications/$id',
      ),
      CoolifyOperation.logs => (HttpMethod.get, 'applications/$id/logs'),
    };
    final payload = _payload(operation, values, uuid);
    terminal?.detail('Coolify ${method.name.toUpperCase()} $path');
    final request = NetworkRequest(
      method: method,
      uri: _base!.resolve(path),
      headers: {
        'Authorization': 'Bearer $_token',
        'Accept': 'application/json',
      },
      query:
          operation == CoolifyOperation.deleteDatabase ||
              operation == CoolifyOperation.deleteApplication
          ? {'delete_volumes': values['destroyData'] == true ? 'true' : 'false'}
          : const {},
      contentType: payload == null ? null : 'application/json',
      bodyBytes: payload == null
          ? null
          : Bytes.fromList(utf8.encode(jsonEncode(payload))),
      sendTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    );
    for (var attempt = 0; ; attempt++) {
      cancellation.throwIfCancelled();
      final result = await cancellation.race(network.send(request));
      if (result case IoErr<NetworkResponse>()) {
        throw TugException(
          'Coolify ${operation.name} failed: network unavailable or timed out.',
          uncertain: method != HttpMethod.get,
        );
      }
      final response = (result as IoOk<NetworkResponse>).value;
      if (method == HttpMethod.get &&
          attempt < 3 &&
          (response.statusCode == 429 || response.statusCode >= 500)) {
        final header = response.headers.entries
            .where((e) => e.key.toLowerCase() == 'retry-after')
            .firstOrNull
            ?.value
            .firstOrNull;
        var seconds = int.tryParse(header ?? '') ?? (1 << attempt);
        if (header != null && int.tryParse(header) == null) {
          try {
            seconds =
                HttpDate.parse(header)
                    .difference(DateTime.now().toUtc())
                    .inSeconds +
                1;
          } catch (_) {}
        }
        if (seconds > 120) {
          throw const TugException(
            'Coolify requested a long Retry-After delay. Retry this command later.',
          );
        }
        await cancellation.race(
          _delay(Duration(seconds: seconds < 0 ? 0 : seconds)),
        );
        continue;
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final advice = switch (response.statusCode) {
          401 => 'Check the configured API token.',
          403 => 'Check API access and token permissions (read, read:sensitive, write, deploy).',
          409 => 'Resolve the resource/domain conflict; Tug never forces domain ownership.',
          429 => 'Rate limited; retry later after rediscovery.',
          _ => 'Check the request settings and Coolify version.',
        };
        throw TugException(
          'Coolify ${operation.name}: HTTP ${response.statusCode}. $advice',
          status: response.statusCode,
          uncertain: method != HttpMethod.get && response.statusCode >= 500,
        );
      }
      return response;
    }
  }

  Object? _payload(CoolifyOperation op, Map<String, Object?> v, String? uuid) {
    if (op == CoolifyOperation.createProject ||
        op == CoolifyOperation.createEnvironment) {
      return {
        'name': v['name'],
        if (op == CoolifyOperation.createProject)
          'description': v['description'],
      };
    }
    if (op == CoolifyOperation.createApplication ||
        op == CoolifyOperation.updateApplication) {
      return {
        'name': v['name'],
        // GitHub App deployments append this value to /repos/ on GitHub.
        'git_repository': Uri.parse(
          normalizeRepository(v['repository'] as String),
        ).path.substring(1),
        'git_branch': v['branch'],
        'build_pack': 'dockerfile',
        'dockerfile_location': '/.coolify/Dockerfile',
        'base_directory': '/',
        'ports_exposes': '8080,8082',
        'domains': v['domains'],
        'is_force_https_enabled': true,
        'force_domain_override': false,
        'is_preview_deployments_enabled': false,
        if (op == CoolifyOperation.createApplication) ...{
          'project_uuid': v['project'],
          'environment_uuid': v['environment'],
          'server_uuid': v['server'],
          'destination_uuid': v['destination'],
          'github_app_uuid': v['githubApp'],
          'tags': v['tags'],
          'instant_deploy': false,
          'autogenerate_domain': false,
          'is_auto_deploy_enabled': true,
        },
      };
    }
    if (op == CoolifyOperation.createDatabase) {
      final redis = v['kind'] == 'redis';
      return {
        'name': v['name'],
        'project_uuid': v['project'],
        'environment_uuid': v['environment'],
        'server_uuid': v['server'],
        'destination_uuid': v['destination'],
        'image': v['image'],
        'is_public': false,
        'instant_deploy': false,
        'tags': v['tags'],
        if (redis) 'redis_password': v['password'],
        if (!redis) ...{
          'postgres_user': v['user'],
          'postgres_db': v['database'],
          'postgres_password': v['password'],
        },
      };
    }
    if (op == CoolifyOperation.upsertVariables) {
      return {
        'data': [
          for (final entry in v.entries)
            {
              'key': entry.key,
              'value': entry.value,
              'is_runtime': true,
              'is_buildtime': false,
              'is_preview': false,
              'is_literal': true,
              'is_multiline': entry.value.toString().contains('\n'),
            },
        ],
      };
    }
    if (op == CoolifyOperation.deploy) return {'uuid': uuid, 'force': false};
    return null;
  }

  @override
  String get logTag => 'RestCoolifyApiService';
  @override
  Future<void> destroy() async {
    _token = null;
  }
}
