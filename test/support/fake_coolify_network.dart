import 'dart:convert';

import 'package:grumpy_io/grumpy_io.dart';

/// Stateful HTTP fixture, deliberately storing wire-format data independently
/// of Tug's typed models. Fault injection simulates accepted-but-lost responses.
class FakeCoolifyNetwork extends NetworkService {
  FakeCoolifyNetwork() : super.internal();
  final projects = <String, Map<String, dynamic>>{};
  final environments = <String, Map<String, dynamic>>{};
  final resources = <String, Map<String, dynamic>>{};
  final variables = <String, Map<String, Map<String, dynamic>>>{};
  final deployments = <String, Map<String, dynamic>>{};
  final requests = <NetworkRequest>[];
  String? loseCreationPath;
  String? failVariableKey;
  bool failCompletedImport = false;
  bool failDeploymentAcknowledgement = false;
  bool loseDeploymentResponse = false;
  String deploymentStatus = 'finished';
  String? failEnvironment;
  int readsToRateLimit = 0;
  int counter = 0;
  String id(String prefix) => '$prefix${++counter}';
  Iterable<NetworkRequest> get mutations =>
      requests.where((r) => r.method != HttpMethod.get);
  @override
  Future<IoResult<NetworkResponse>> send(
    NetworkRequest request, {
    TransferProgressCallback? onUploadProgress,
    TransferProgressCallback? onDownloadProgress,
    NetworkCancelToken? cancelToken,
  }) async {
    requests.add(request);
    final path = request.uri.path.replaceFirst('/api/v1/', '');
    final parts = path.split('/');
    final payload = request.bodyBytes == null
        ? <String, dynamic>{}
        : jsonDecode(utf8.decode(request.bodyBytes!)) as Map<String, dynamic>;
    final method = request.method;
    IoResult<NetworkResponse> response(Object? body, [int status = 200]) =>
        IoOk(
          NetworkResponse(
            statusCode: status,
            statusMessage: null,
            headers: status == 429
                ? {
                    'Retry-After': ['1'],
                  }
                : {},
            bodyBytes: Bytes.fromList(utf8.encode(jsonEncode(body))),
            request: request,
          ),
        );
    if (readsToRateLimit > 0 && method == HttpMethod.get) {
      readsToRateLimit--;
      return response({'message': 'slow down'}, 429);
    }
    if (method == HttpMethod.get) {
      if (path == 'servers') {
        return response([
          {'uuid': 'server', 'name': 'Projects'},
        ]);
      }
      if (path == 'servers/server/destinations') {
        return response([
          {'uuid': 'destination', 'name': 'coolify'},
        ]);
      }
      if (path == 'github-apps') {
        return response([
          {'uuid': 'github', 'name': 'GitHub'},
        ]);
      }
      if (path == 'databases') {
        return response(
          resources.values.where((r) => r['kind'] != 'application').toList(),
        );
      }
      if (path == 'projects') return response(projects.values.toList());
      if (parts.first == 'projects') {
        if (parts.length == 2) return response(projects[parts[1]]);
        if (parts.last == 'environments') {
          return response(
            environments.values.where((e) => e['project'] == parts[1]).toList(),
          );
        }
        final env = environments[parts.last];
        if (env == null) return response({}, 404);
        return response({
          ...env,
          for (final kind in ['application', 'postgres', 'redis'])
            {
              'application': 'applications',
              'postgres': 'postgresqls',
              'redis': 'redis',
            }[kind]!: resources.values
                .where(
                  (r) =>
                      r['kind'] == kind && r['environment_uuid'] == parts.last,
                )
                .toList(),
        });
      }
      if (path == 'applications') {
        return response(
          resources.values.where((r) => r['kind'] == 'application').toList(),
        );
      }
      if (parts.first == 'applications' || parts.first == 'databases') {
        final resource = resources[parts[1]];
        if (resource == null) return response({}, 404);
        if (parts.length == 2) return response({...resource}..remove('tags'));
        if (parts.last == 'tags') {
          return response(
            (resource['tags'] as List).map((t) => {'name': t}).toList(),
          );
        }
        if (parts.last == 'envs') {
          return response(variables[parts[1]]!.values.toList());
        }
        if (parts.last == 'storages') {
          return response({
            'persistent_storages': resource['storages'] ?? [],
            'file_storages': [],
          });
        }
        if (parts.last == 'logs') {
          return response({'logs': resource['logs'] ?? 'ready'});
        }
      }
      if (parts.first == 'deployments') {
        if (parts[1] == 'applications') {
          return response({
            'deployments': deployments.values
                .where((d) => d['app'] == parts.last)
                .toList()
                .reversed
                .toList(),
          });
        }
        return response(deployments[parts[1]]);
      }
    }
    if (method == HttpMethod.post) {
      Map<String, dynamic>? created;
      if (path == 'projects') {
        final uuid = id('project');
        created = {'uuid': uuid, ...payload};
        projects[uuid] = created;
        final eid = id('env');
        environments[eid] = {
          'uuid': eid,
          'name': 'production',
          'project': uuid,
        };
      } else if (parts.first == 'projects' && parts.last == 'environments') {
        if (payload.keys.any((k) => k != 'name')) return response({}, 422);
        final uuid = id('env');
        created = {'uuid': uuid, ...payload, 'project': parts[1]};
        environments[uuid] = created;
      } else if (path == 'databases/postgresql' ||
          path == 'databases/redis' ||
          path == 'applications/private-github-app') {
        if (environments[payload['environment_uuid']]?['name'] ==
            failEnvironment) {
          return response({}, 422);
        }
        final uuid = id('resource');
        final kind = path.contains('postgresql')
            ? 'postgres'
            : path.contains('redis')
            ? 'redis'
            : 'application';
        created = {
          'uuid': uuid,
          ...payload,
          'kind': kind,
          'status': 'exited',
          'destination': {
            'uuid': 'destination',
            'server': {'uuid': 'server'},
          },
          'settings': {
            'is_force_https_enabled': true,
            'is_preview_deployments_enabled': false,
          },
          'fqdn': payload['domains'],
          if (kind == 'postgres')
            'internal_db_url':
                'postgresql://${payload['postgres_user']}:${Uri.encodeComponent(payload['postgres_password'] as String)}@$uuid:5432/${payload['postgres_db']}',
          if (kind == 'redis')
            'internal_db_url':
                'redis://default:${Uri.encodeComponent(payload['redis_password'] as String)}@$uuid:6379/0',
        };
        resources[uuid] = created;
        if (kind == 'application') variables[uuid] = {};
      } else if (parts.first == 'databases' && parts.last == 'start') {
        resources[parts[1]]!['status'] = 'running';
        return response({'message': 'started'});
      } else if (path == 'deploy') {
        final uuid = id('deploy');
        deployments[uuid] = {
          'deployment_uuid': uuid,
          'app': payload['uuid'],
          'status': deploymentStatus,
          'logs': 'ready',
        };
        resources[payload['uuid']]!['status'] = 'running';
        if (loseDeploymentResponse) {
          loseDeploymentResponse = false;
          return response({'message': 'accepted response lost'}, 503);
        }
        return response({
          'deployments': [
            {'deployment_uuid': uuid},
          ],
        });
      }
      if (created != null) {
        if (loseCreationPath == path) {
          loseCreationPath = null;
          return response({'message': 'lost response'}, 503);
        }
        return response({'uuid': created['uuid']}, 201);
      }
    }
    if (method == HttpMethod.patch && parts.first == 'applications') {
      if (parts.last == 'bulk') {
        for (final item in payload['data'] as List) {
          final key = item['key'] as String;
          if (failDeploymentAcknowledgement &&
              key == 'TUG_DEPLOYMENT_PENDING' &&
              item['value'] == 'false') {
            failDeploymentAcknowledgement = false;
            return response({'message': 'interrupted acknowledgement'}, 500);
          }
          if (failCompletedImport &&
              key == 'TUG_IMPORT_V1' &&
              (jsonDecode(item['value'] as String) as Map)['complete'] ==
                  true) {
            failCompletedImport = false;
            return response({'message': 'interrupted completion'}, 500);
          }
          if (key == failVariableKey) {
            failVariableKey = null;
            return response({'message': 'partial write'}, 500);
          }
          variables[parts[1]]![key] = {
            'uuid': variables[parts[1]]![key]?['uuid'] ?? id('var'),
            ...Map<String, dynamic>.from(item as Map),
          };
        }
        return response([]);
      }
      resources[parts[1]]!.addAll({...payload, 'fqdn': payload['domains']});
      return response({'uuid': parts[1]});
    }
    if (method == HttpMethod.delete) {
      if (parts.first == 'applications' && parts.length == 4) {
        variables[parts[1]]!.removeWhere((k, v) => v['uuid'] == parts.last);
        return response({});
      }
      if (parts.first == 'applications' || parts.first == 'databases') {
        resources.remove(parts[1]);
        variables.remove(parts[1]);
        return response({});
      }
      if (parts.first == 'projects' && parts.length == 4) {
        environments.remove(parts.last);
        return response({});
      }
      if (parts.first == 'projects') {
        projects.remove(parts[1]);
        return response({});
      }
    }
    throw StateError('Unexpected fake request: ${method.name} $path');
  }

  @override
  String get logTag => 'FakeCoolifyNetwork';
  @override
  Future<void> destroy() async {}
}
