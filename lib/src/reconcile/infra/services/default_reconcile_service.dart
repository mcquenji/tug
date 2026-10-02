import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:grumpy_cli/grumpy_cli.dart';
import 'package:path/path.dart' as p;
import 'package:tug/src/app/app.dart';
import 'package:tug/src/coolify/coolify.dart';
import 'package:tug/src/reconcile/domain/domain.dart';
import 'package:tug/src/serverpod/serverpod.dart';
import 'package:tug/src/workspace/workspace.dart';

/// Reconciles typed resources. It has no knowledge of HTTP or Coolify JSON fields.
class DefaultReconcileService extends ReconcileService {
  DefaultReconcileService(
    this.remote,
    this.importer,
    this.workspace,
    this.terminal,
    this.cancellation, {
    Future<void> Function(Duration)? delay,
    this.pollLimit = 180,
  }) : _delay = delay ?? Future<void>.delayed,
       super.internal();
  final CoolifyDatasource remote;
  final ServerpodConfigDatasource importer;
  final WorkspaceService workspace;
  final TerminalService terminal;
  final CancellationToken cancellation;
  final Future<void> Function(Duration) _delay;
  final int pollLimit;
  final _redactions = <String>{};
  static const importKey = 'TUG_IMPORT_V1';
  static const managedKey = 'TUG_MANAGED_V1';

  String _identity(DeploymentSpec s) => sha256
      .convert(utf8.encode(s.layout.repository.toLowerCase()))
      .toString()
      .substring(0, 20);
  String _marker(DeploymentSpec s) =>
      'managed-by=tug,app=${s.config.name},repository=${_identity(s)}';
  bool _hasProjectMarker(RemoteResource project, DeploymentSpec s) =>
      project.description.contains(_marker(s));
  List<String> _tags(DeploymentSpec s, String env) => [
    'managed-by:tug',
    'tug-app:${s.config.name}',
    'tug-environment:$env',
    'tug-repository:${_identity(s)}',
  ];
  bool _owned(RemoteResource r, DeploymentSpec s, String env) =>
      _tags(s, env).every(r.tags.contains);
  String _resourceName(DeploymentSpec s, String env, String kind) =>
      (kind == 'application'
          ? s.config.environments[env]?.resourceName
          : null) ??
      '${s.config.name}-$env-${kind == 'application' ? 'app' : kind}';
  String _mode(String env, EnvironmentConfig config) =>
      config.configMode ?? (env == 'production' ? 'production' : 'staging');
  bool _redis(DeploymentSpec s, String env) =>
      s.config.environments[env]?.redis?.enabled ?? s.config.redis.enabled;

  void _validateName(String? name, String field) {
    if (name == null || !RegExp(r'^[a-z][a-z0-9-]{0,47}$').hasMatch(name)) {
      throw TugException(
        '$field must be a lowercase name with letters, digits or hyphens (up to 48 characters).',
      );
    }
  }

  String _domain(DeploymentSpec s, String env, String type) {
    final template = s.context.domains[env] ?? s.context.domains['default'];
    var domain = (type == 'web' ? template?.web : template?.api) ?? '';
    domain = domain
        .replaceAll('{app}', s.config.name!)
        .replaceAll('{name}', s.config.name!)
        .replaceAll('{environment}', env)
        .replaceAll('{env}', env)
        .toLowerCase();
    if (domain.startsWith('https://')) {
      final uri = Uri.tryParse(domain);
      if (uri == null ||
          uri.userInfo.isNotEmpty ||
          uri.hasPort ||
          uri.hasQuery ||
          uri.hasFragment ||
          !['', '/'].contains(uri.path)) {
        throw TugException(
          'Invalid HTTPS domain for $env.$type. Use a bare hostname without a port or path.',
        );
      }
      domain = uri.host;
    }
    final labels = domain.split('.');
    if (domain.length > 253 ||
        labels.length < 2 ||
        labels.any(
          (l) =>
              l.isEmpty ||
              l.length > 63 ||
              !RegExp(r'^[a-z0-9](?:[a-z0-9-]*[a-z0-9])?$').hasMatch(l),
        )) {
      throw TugException(
        'Set domains.$env.$type in .coolify/local.yaml or configure a context domain template.',
      );
    }
    return domain;
  }

  List<String> _selected(DeploymentSpec s, String? env) {
    if (env != null && !s.config.environments.containsKey(env)) {
      throw TugException('Unknown environment $env.');
    }
    if (s.config.environments.isEmpty) {
      throw const TugException('Declare at least one environment.');
    }
    return env == null ? s.config.environments.keys.toList() : [env];
  }

  Map<String, String> _explicit(DeploymentSpec s, String env) {
    final settings = s.config.environments[env]!;
    String resolve(
      SecretReference source,
      String field, {
      bool allowEmpty = false,
    }) {
      final reference = source.fromEnv;
      if (!RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$').hasMatch(reference)) {
        throw TugException(
          'Invalid environment reference environments.$env.$field.fromEnv.',
        );
      }
      final value = s.processEnvironment[reference];
      if (value == null || (!allowEmpty && value.isEmpty)) {
        throw TugException(
          'Missing environment variable $reference for environments.$env.$field.',
        );
      }
      return value;
    }

    final values = <String, String>{};
    for (final entry in settings.env.entries) {
      values[entry.key] = switch (entry.value) {
        String value => value,
        SecretReference reference => resolve(
          reference,
          'env.${entry.key}',
          allowEmpty: true,
        ),
        _ => throw TugException(
          'Invalid runtime value environments.$env.env.${entry.key}.',
        ),
      };
    }
    for (final entry in settings.secrets.entries) {
      values['SERVERPOD_PASSWORD_${entry.key}'] = resolve(
        entry.value,
        'secrets.${entry.key}',
      );
    }
    for (final key in values.keys) {
      if (!RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$').hasMatch(key)) {
        throw TugException('Invalid variable name in environments.$env.');
      }
      if (ownedVariable(key)) {
        throw TugException(
          'environments.$env: $key is managed by Tug and cannot be overridden.',
        );
      }
    }
    _redactions.addAll(
      values.entries.where((e) => sensitiveName(e.key)).map((e) => e.value),
    );
    return values;
  }

  RemoteResource? _one(
    List<RemoteResource> resources,
    bool Function(RemoteResource) predicate,
    String label,
  ) {
    final matches = resources.where(predicate).toList();
    if (matches.length > 1) {
      throw TugException(
        'Ambiguous $label; resolve duplicate remote resources before continuing.',
      );
    }
    return matches.firstOrNull;
  }

  Future<RemoteResource?> _project(DeploymentSpec s) async {
    final projects = await remote.list(CoolifyOperation.projects);
    final project = _one(
      projects,
      (r) => r.name == s.config.name || _hasProjectMarker(r, s),
      'project',
    );
    if (project != null &&
        (!_hasProjectMarker(project, s) || project.name != s.config.name)) {
      final reason = project.name != s.config.name
          ? 'its name differs from the configured app name ${jsonEncode(s.config.name)}'
          : 'its description does not contain the expected Tug app/repository marker';
      throw TugException(
        'Coolify at ${s.context.url} returned project ${jsonEncode(project.name)} '
        '(UUID ${project.uuid}), but $reason. Refusing to adopt it. '
        'Expected marker: ${_marker(s)}. '
        'Check the selected Coolify instance and API token team if you deleted this project; '
        'this result came from the API, not the local state cache.',
      );
    }
    return project;
  }

  Future<RemoteResource?> _environment(
    DeploymentSpec s,
    String project,
    String name,
  ) async {
    final match = _one(
      await remote.list(CoolifyOperation.environments, uuid: project),
      (r) => r.name == name,
      'environment $name',
    );
    // Environments have no metadata field in the API. Their ownership is scoped
    // by the verified parent project; resource ownership is checked individually.
    return match;
  }

  Future<RemoteResource?> _resource(
    DeploymentSpec s,
    EnvironmentSnapshot e,
    String kind,
  ) async {
    final resource = _one(
      e.resources,
      (r) =>
          r.name == _resourceName(s, e.name, kind) ||
          (r.kind == kind && _owned(r, s, e.name)),
      '$kind in ${e.name}',
    );
    if (resource == null) return null;
    final detail = await remote.get(kind, resource.uuid);
    if (resource.kind != kind || !_owned(detail, s, e.name)) {
      throw TugException(
        'Ownership mismatch for $kind in ${e.name}; refusing to adopt it.',
      );
    }
    if (detail.destination != s.context.destination ||
        detail.server != s.context.server) {
      throw TugException(
        '$kind in ${e.name}: topology changes or unverifiable destination/server are unsupported.',
      );
    }
    if (kind == 'application' &&
        normalizeRepository(detail.repository ?? '').toLowerCase() !=
            s.layout.repository.toLowerCase()) {
      throw TugException('Application repository mismatch in ${e.name}.');
    }
    if (kind != 'application' && detail.isPublic) {
      throw TugException(
        '$kind in ${e.name} is public. Make it private in Coolify before continuing.',
      );
    }
    return detail;
  }

  Future<EnvironmentSnapshot> _snapshot(
    DeploymentSpec s,
    String name,
    RemoteResource? project, {
    required bool needSources,
    required bool sync,
  }) async {
    final e = EnvironmentSnapshot(name, {
      'web': _domain(s, name, 'web'),
      'api': _domain(s, name, 'api'),
    }, _explicit(s, name));
    if (project != null) {
      e.environment = await _environment(s, project.uuid, name);
      if (e.environment != null) {
        e.resources = await remote.resources(project.uuid, e.environment!.uuid);
        e.application = await _resource(s, e, 'application');
        e.postgres = await _resource(s, e, 'postgres');
        e.redis = await _resource(s, e, 'redis');
        if (e.application != null) {
          e.variables = await remote.variables(e.application!.uuid);
          if (e.variables.values.any((v) => v.value == null)) {
            throw const TugException(
              'Runtime values are unavailable. Grant read:sensitive permission to reconcile safely.',
            );
          }
          _redactions.addAll(
            e.variables.entries
                .where((v) => sensitiveName(v.key))
                .map((v) => v.value.value!),
          );
        }
      }
    }
    // Resources moved out of this environment must not be recreated under a
    // new UUID, even after local cache loss.
    for (final kind in [
      'application',
      'postgres',
      if (_redis(s, name)) 'redis',
    ]) {
      final exists = switch (kind) {
        'application' => e.application,
        'postgres' => e.postgres,
        _ => e.redis,
      };
      if (exists == null) {
        final all = await remote.list(
          kind == 'application'
              ? CoolifyOperation.applications
              : CoolifyOperation.databases,
        );
        if (all.any((r) => r.name == _resourceName(s, name, kind))) {
          throw TugException(
            '$kind named for $name exists outside the selected environment. Resolve ownership/topology before applying.',
          );
        }
      }
    }
    final mode = _mode(name, s.config.environments[name]!);
    if (needSources && (sync || !_importComplete(e.variables))) {
      e.imported = await importer.read(
        p.join(s.layout.root, s.layout.server),
        mode,
      );
      _redactions.addAll(
        e.imported!.values.entries
            .where((v) => sensitiveName(v.key))
            .map((v) => v.value),
      );
    }
    final metadata = _importMetadata(e.variables);
    if (needSources && metadata != null && metadata['complete'] == false) {
      final missing = (metadata['keys'] as List).cast<String>().where(
        (k) =>
            !e.variables.containsKey(k) &&
            !(e.imported?.values.containsKey(k) ?? false) &&
            !e.explicit.containsKey(k),
      );
      if (missing.isNotEmpty) {
        throw TugException(
          'Incomplete import in $name. Restore the selected source files for: ${missing.join(', ')}.',
        );
      }
    }
    if (e.application != null && e.postgres == null) {
      throw TugException(
        'PostgreSQL is missing for existing application in $name. Automatic database recreation is forbidden.',
      );
    }
    if (e.application != null &&
        _redis(s, name) &&
        e.redis == null &&
        e.variables['SERVERPOD_REDIS_ENABLED']?.value == 'true') {
      throw TugException(
        'Redis is missing for existing application in $name. Automatic recreation is forbidden.',
      );
    }
    if (e.postgres != null) {
      final db = s.config.environments[name]!.database;
      final desiredName = db.name ?? s.config.name!.replaceAll('-', '_');
      final desiredUser = db.user ?? desiredName;
      if (e.postgres!.image != 'postgres:${s.config.database.version}-alpine' ||
          e.postgres!.databaseName != desiredName ||
          e.postgres!.databaseUser != desiredUser) {
        throw TugException(
          'PostgreSQL version, name or user changed in $name. Automatic database upgrades/recreation are forbidden.',
        );
      }
    }
    if (e.redis != null && e.redis!.image != 'redis:7.4-alpine') {
      throw TugException(
        'Redis image changed in $name; automatic upgrades are forbidden.',
      );
    }
    return e;
  }

  Map<String, dynamic>? _importMetadata(Map<String, RemoteVariable> vars) {
    final raw = vars[importKey]?.value;
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic> &&
          decoded['keys'] is List &&
          (decoded['keys'] as List).every((v) => v is String) &&
          decoded['complete'] is bool) {
        return decoded;
      }
    } catch (_) {}
    throw const TugException(
      'Remote import metadata is invalid. Restore TUG_IMPORT_V1 before reconciling.',
    );
  }

  bool _importComplete(Map<String, RemoteVariable> vars) =>
      _importMetadata(vars)?['complete'] == true;
  Set<String> _managed(Map<String, RemoteVariable> vars) {
    final raw = vars[managedKey]?.value;
    if (raw == null) return {};
    try {
      final keys = jsonDecode(raw) as List;
      if (keys.every((k) => k is String && !ownedVariable(k))) {
        return keys.cast<String>().toSet();
      }
    } catch (_) {}
    throw const TugException(
      'Remote variable ownership metadata is invalid. Restore TUG_MANAGED_V1.',
    );
  }

  Future<void> _infrastructure(DeploymentSpec s) async {
    for (final entry in {
      'server': s.context.server,
      'destination': s.context.destination,
      'githubApp': s.context.githubApp,
    }.entries) {
      if (entry.value.isEmpty) {
        throw TugException('Configure context ${entry.key}.');
      }
      final op = switch (entry.key) {
        'server' => CoolifyOperation.servers,
        'destination' => CoolifyOperation.destinations,
        _ => CoolifyOperation.githubApps,
      };
      final resources = await remote.list(
        op,
        uuid: entry.key == 'destination' ? s.context.server : null,
      );
      if (!resources.any((r) => r.uuid == entry.value)) {
        throw TugException(
          'Context ${entry.key} is unavailable or does not belong to the selected server/team.',
        );
      }
    }
  }

  Future<void> _cache(
    DeploymentSpec s,
    RemoteResource project,
    EnvironmentSnapshot? e,
  ) async {
    final old = await workspace.readState(s.layout.root);
    final key = '${s.context.url}|${s.layout.repository}|${s.config.name}';
    final environments = old['identity'] == key && old['environments'] is Map
        ? Map<String, Object?>.from(old['environments'] as Map)
        : <String, Object?>{};
    if (e != null) {
      environments[e.name] = {
        'environment': e.environment?.uuid,
        'application': e.application?.uuid,
        'postgres': e.postgres?.uuid,
        'redis': e.redis?.uuid,
      };
    }
    // No cache UUID is trusted for discovery or mutation. Only verified remote IDs are persisted.
    await workspace.saveState(s.layout.root, {
      'identity': key,
      'project': project.uuid,
      'environments': environments,
    });
  }

  Future<RemoteResource> _created(
    DeploymentSpec s,
    RemoteResource project,
    EnvironmentSnapshot e,
    String kind,
    String uuid,
  ) async {
    e.resources = await remote.resources(project.uuid, e.environment!.uuid);
    final verified = await _resource(s, e, kind);
    if (verified == null || verified.uuid != uuid) {
      throw TugException(
        'Created $kind could not be verified in ${e.name}; no further changes were made to it.',
      );
    }
    return verified;
  }

  Future<String> _create(
    CoolifyOperation op,
    Map<String, Object?> values,
    Future<String?> Function() rediscover, {
    String? parent,
  }) async {
    cancellation.throwIfCancelled();
    try {
      return await remote.create(op, values, parent: parent);
    } on TugException catch (e) {
      if (!e.uncertain) rethrow;
      // Never repeat a possibly accepted POST. Rediscover by verified identity.
      for (var attempt = 0; attempt < 3; attempt++) {
        await cancellation.race(_delay(const Duration(seconds: 2)));
        final found = await rediscover();
        if (found != null) return found;
      }
      throw const TugException(
        'Creation outcome is uncertain. No duplicate was created; rerun apply to rediscover safely.',
      );
    }
  }

  @override
  Future<void> apply(
    DeploymentSpec s, {
    String? environment,
    bool plan = false,
    bool sync = false,
    bool wait = true,
  }) async {
    _validateName(s.config.name, 'name');
    if (s.config.database.type != 'postgres' ||
        ![16, 17, 18].contains(s.config.database.version)) {
      throw const TugException('Use PostgreSQL version 16, 17 or 18.');
    }
    final selected = _selected(s, environment);
    final domainSet = <String>{};
    final applicationNames = <String>{};
    for (final name in s.config.environments.keys) {
      _validateName(name, 'environment');
      for (final type in ['web', 'api']) {
        if (!domainSet.add(_domain(s, name, type))) {
          throw const TugException(
            'Web/API domains must be unique across environments.',
          );
        }
      }
      final settings = s.config.environments[name]!;
      final resourceName = _resourceName(s, name, 'application');
      if (resourceName.trim().isEmpty ||
          resourceName != resourceName.trim() ||
          RegExp(r'[\x00-\x1f\x7f]').hasMatch(resourceName)) {
        throw TugException(
          'environments.$name.resourceName must be nonempty with no surrounding whitespace or control characters.',
        );
      }
      if (!applicationNames.add(resourceName) ||
          resourceName == _resourceName(s, name, 'postgres') ||
          resourceName == _resourceName(s, name, 'redis')) {
        throw TugException(
          'environments.$name.resourceName conflicts with another resource name.',
        );
      }
      if (!RegExp(r'^(?!-)(?!.*\.\.)[A-Za-z0-9_./-]+$')
              .hasMatch(settings.branch) ||
          settings.branch.endsWith('/') ||
          settings.branch.endsWith('.')) {
        throw TugException('Invalid branch for $name.');
      }
      if (!RegExp(r'^[a-z][a-z0-9_-]*$').hasMatch(_mode(name, settings))) {
        throw TugException('Invalid configMode for $name.');
      }
      final db = s.config.environments[name]!.database;
      for (final value in [db.name, db.user].nonNulls) {
        if (!RegExp(r'^[a-z_][a-z0-9_]{0,62}$').hasMatch(value)) {
          throw TugException('Invalid database name/user in $name.');
        }
      }
    }
    await terminal.task(
      'Validate deployment build files',
      () => workspace.generate(s.layout, check: true),
    );
    await terminal.task(
      'Check Coolify infrastructure',
      () => _infrastructure(s),
    );
    var project = await terminal.task('Discover project', () => _project(s));
    final snapshots = <EnvironmentSnapshot>[];
    for (final name in selected) {
      snapshots.add(
        await _snapshot(s, name, project, needSources: true, sync: sync),
      );
    }
    if (sync && snapshots.any((e) => e.application == null)) {
      throw const TugException(
        'config sync requires an existing Tug application. Run apply first.',
      );
    }
    // Check all visible application domains before any write; Coolify also rejects forced claims.
    for (final app in await remote.list(CoolifyOperation.applications)) {
      if (snapshots.any(
        (e) =>
            app.name == _resourceName(s, e.name, 'application') &&
            app.uuid != e.application?.uuid,
      )) {
        throw const TugException(
          'A requested application resource name is already in use. Choose a different resourceName.',
        );
      }
      final ourIds = snapshots.map((e) => e.application?.uuid).toSet();
      if (ourIds.contains(app.uuid)) continue;
      for (final domain in (app.domains ?? '').split(',')) {
        if (snapshots.any(
          (e) => e.domains.values.contains(Uri.tryParse(domain.trim())?.host),
        )) {
          throw const TugException(
            'A requested domain is already assigned to another application. Tug will not force its ownership.',
          );
        }
      }
    }
    if (project != null) {
      for (final env in await remote.list(
        CoolifyOperation.environments,
        uuid: project.uuid,
      )) {
        if (!s.config.environments.containsKey(env.name)) {
          terminal.warning(
            'Orphaned environment ${env.name}; no automatic deletion.',
          );
        }
      }
    }
    var changed = false;
    if (project == null) {
      terminal.writeln('Create project ${s.config.name}.');
      changed = true;
      if (!plan) {
        final uuid = await _create(CoolifyOperation.createProject, {
          'name': s.config.name,
          'description': _marker(s),
        }, () async => (await _project(s))?.uuid);
        project = await remote.get('project', uuid);
        if (!_hasProjectMarker(project, s)) {
          throw const TugException(
            'Created project ownership was not persisted.',
          );
        }
        await _cache(s, project, null);
      }
    }
    final failures = <String>[];
    for (final e in snapshots) {
      try {
        changed =
            await terminal.task(
              '${e.name}: reconcile resources',
              () => _applyEnvironment(
                s,
                project,
                e,
                plan: plan,
                sync: sync,
                wait: wait,
              ),
            ) ||
            changed;
      } on TugException catch (error) {
        terminal.failure('${e.name}: ${error.message}');
        failures.add(e.name);
      }
    }
    if (failures.isNotEmpty) {
      throw TugException(
        'Failed environments: ${failures.join(', ')}. Successful progress is preserved; rerun apply after fixing the issue.',
      );
    }
    if (!changed) terminal.success('No changes.');
  }

  Future<bool> _applyEnvironment(
    DeploymentSpec s,
    RemoteResource? project,
    EnvironmentSnapshot e, {
    required bool plan,
    required bool sync,
    required bool wait,
  }) async {
    var changed = false;
    var markedPending = false;
    Future<void> markPending() async {
      if (plan || markedPending) return;
      final last = await remote.latestDeployment(e.application!.uuid);
      await remote.mutate(
        CoolifyOperation.upsertVariables,
        uuid: e.application!.uuid,
        values: {
          'TUG_DEPLOYMENT_BASELINE': last?.uuid ?? '',
          'TUG_DEPLOYMENT_PENDING': 'true',
        },
      );
      markedPending = true;
    }

    Future<void> clearPending() => remote.mutate(
      CoolifyOperation.upsertVariables,
      uuid: e.application!.uuid,
      values: {'TUG_DEPLOYMENT_PENDING': 'false'},
    );

    final env = s.config.environments[e.name]!;
    if (e.environment == null && project != null) {
      e.environment = await _environment(s, project.uuid, e.name);
    }
    if (e.environment == null) {
      terminal.writeln('${e.name}: create environment.');
      changed = true;
      if (!plan) {
        await _create(
          CoolifyOperation.createEnvironment,
          {'name': e.name, 'description': _marker(s)},
          () async => (await _environment(s, project.uuid, e.name))?.uuid,
          parent: project!.uuid,
        );
        e.environment = await _environment(s, project.uuid, e.name);
        await _cache(s, project, e);
      }
    }
    Future<RemoteResource?> database(
      String kind,
      RemoteResource? resource,
    ) async {
      if (resource == null) {
        terminal.writeln('${e.name}: create private $kind.');
        changed = true;
        if (plan) return null;
        final password = newSecret();
        _redactions.add(password);
        final name = env.database.name ?? s.config.name!.replaceAll('-', '_');
        final uuid = await _create(
          CoolifyOperation.createDatabase,
          {
            'kind': kind,
            'name': _resourceName(s, e.name, kind),
            'project': project!.uuid,
            'environment': e.environment!.uuid,
            'server': s.context.server,
            'destination': s.context.destination,
            'tags': _tags(s, e.name),
            'image': kind == 'redis'
                ? 'redis:7.4-alpine'
                : 'postgres:${s.config.database.version}-alpine',
            'user': env.database.user ?? name,
            'database': name,
            'password': password,
          },
          () async {
            e.resources = await remote.resources(
              project.uuid,
              e.environment!.uuid,
            );
            return (await _resource(s, e, kind))?.uuid;
          },
        );
        resource = await _created(s, project, e, kind, uuid);
        if (kind == 'postgres') {
          e.postgres = resource;
        } else {
          e.redis = resource;
        }
        await _cache(s, project, e);
      }
      if (!resource.running) {
        terminal.writeln('${e.name}: start $kind.');
        changed = true;
        if (!plan) {
          await remote.mutate(
            CoolifyOperation.startDatabase,
            uuid: resource.uuid,
          );
          var running = false;
          for (var i = 0; i < 60; i++) {
            if ((await remote.get(kind, resource.uuid)).running) {
              running = true;
              break;
            }
            await cancellation.race(_delay(const Duration(seconds: 2)));
          }
          if (!running) {
            throw TugException(
              '$kind did not become ready within two minutes.',
            );
          }
        }
      }
      return resource;
    }

    e.postgres = await database('postgres', e.postgres);
    if (_redis(s, e.name)) {
      e.redis = await database('redis', e.redis);
    } else if (e.redis != null) {
      terminal.warning('${e.name}: orphaned Redis; no automatic deletion.');
    }
    final fields = <String, Object?>{
      'name': _resourceName(s, e.name, 'application'),
      'repository': s.layout.repository,
      'branch': env.branch,
      'domains':
          'https://${e.domains['web']}:8082,https://${e.domains['api']}:8080',
    };
    if (e.application == null) {
      terminal.writeln(
        '${e.name}: create application ${jsonEncode(fields['name'])}.',
      );
      changed = true;
      if (!plan) {
        final uuid = await _create(
          CoolifyOperation.createApplication,
          {
            ...fields,
            'project': project!.uuid,
            'environment': e.environment!.uuid,
            'server': s.context.server,
            'destination': s.context.destination,
            'githubApp': s.context.githubApp,
            'tags': _tags(s, e.name),
          },
          () async {
            e.resources = await remote.resources(
              project.uuid,
              e.environment!.uuid,
            );
            return (await _resource(s, e, 'application'))?.uuid;
          },
        );
        e.application = await _created(s, project, e, 'application', uuid);
        await _cache(s, project, e);
        e.variables = await remote.variables(uuid);
      }
    } else {
      final app = e.application!;
      if (app.name != fields['name']) {
        terminal.writeln(
          '${e.name}: rename application ${jsonEncode(app.name)} to ${jsonEncode(fields['name'])}.',
        );
      }
      bool sameDomains(String? a, String? b) =>
          (a ?? '')
              .split(',')
              .map((v) => v.trim())
              .toSet()
              .containsAll((b ?? '').split(',')) &&
          (a ?? '').split(',').length == (b ?? '').split(',').length;
      if (app.repository != Uri.parse(s.layout.repository).path.substring(1) ||
          app.branch != env.branch ||
          app.name != fields['name'] ||
          !sameDomains(app.domains, fields['domains'] as String) ||
          app.dockerfile != '/.coolify/Dockerfile' ||
          app.buildPack != 'dockerfile' ||
          app.baseDirectory != '/' ||
          app.ports != '8080,8082' ||
          app.forceHttps != true ||
          app.previewEnabled != false ||
          app.healthCheckEnabled != true ||
          app.healthCheckType != 'http' ||
          app.healthCheckPath != '/readyz' ||
          app.healthCheckPort != '8080' ||
          app.healthCheckHost != '127.0.0.1' ||
          app.healthCheckMethod != 'GET' ||
          app.healthCheckScheme != 'http' ||
          app.healthCheckReturnCode != 200 ||
          (app.healthCheckResponseText ?? '').isNotEmpty ||
          app.healthCheckInterval != 10 ||
          app.healthCheckTimeout != 5 ||
          app.healthCheckRetries != 3 ||
          app.healthCheckStartPeriod != 60) {
        terminal.writeln('${e.name}: update managed application fields.');
        changed = true;
        if (!plan) {
          await markPending();
          await remote.mutate(
            CoolifyOperation.updateApplication,
            uuid: app.uuid,
            values: fields,
          );
        }
      }
    }
    if (plan &&
        (e.application == null ||
            e.postgres == null ||
            _redis(s, e.name) && e.redis == null)) {
      final names = {
        ...?e.imported?.values.keys.where((k) => !ownedVariable(k)),
        ...e.explicit.keys,
      }.toList()..sort();
      terminal.writeln(
        '${e.name}: configure runtime infrastructure and application variables${names.isEmpty ? '' : ': ${names.join(', ')}'}; deploy.',
      );
      return true;
    }
    final pg = await remote.connection(e.postgres!.uuid);
    final redis = _redis(s, e.name)
        ? await remote.connection(e.redis!.uuid)
        : null;
    _redactions.add(pg.password);
    if (redis != null) _redactions.add(redis.password);
    final owned = _runtime(s, e, pg, redis, plan);
    final before = e.variables;
    final importedKeys = <String>{
      ...?(_importMetadata(before)?['keys'] as List?)?.cast<String>(),
    };
    final desired = <String, String>{...owned, ...e.explicit};
    final imported = e.imported;
    if (imported != null) {
      for (final entry in imported.values.entries) {
        if (ownedVariable(entry.key) || e.explicit.containsKey(entry.key)) {
          continue;
        }
        if (sync || !before.containsKey(entry.key)) {
          desired[entry.key] = entry.value;
        }
        // Existing manually set values are preserved and are not claimed on initial import.
        if (sync ||
            !before.containsKey(entry.key) ||
            importedKeys.contains(entry.key)) {
          importedKeys.add(entry.key);
        }
      }
    }
    final previousManaged = _managed(before);
    final deletes = {
      if (before.containsKey('SERVERPOD_DATABASE_DATA_PATH'))
        'SERVERPOD_DATABASE_DATA_PATH',
      ...previousManaged
          .difference(e.explicit.keys.toSet())
          .where((k) => !importedKeys.contains(k)),
      ...before.keys.where(
        (k) => k != canonicalVariable(k) && ownedVariable(k),
      ),
    };
    // Imported values are never deleted, even when files or source keys disappear.
    desired[managedKey] = jsonEncode(e.explicit.keys.toList()..sort());
    bool differs(String key, String value) {
      final old = before[key];
      return old == null ||
          old.value != value ||
          !old.runtime ||
          old.buildtime ||
          !old.literal;
    }

    final writes = Map<String, String>.fromEntries(
      desired.entries.where((e) => differs(e.key, e.value)),
    );
    // Record pending key ownership before the bulk request, which can partially
    // succeed. Retrying then preserves both values and ownership after any interruption.
    if (imported != null && !plan) {
      final pending = jsonEncode({
        'complete': false,
        'mode': _mode(e.name, env),
        'keys': importedKeys.toList()..sort(),
      });
      final complete = jsonEncode({
        'complete': true,
        'mode': _mode(e.name, env),
        'keys': importedKeys.toList()..sort(),
      });
      if (writes.isNotEmpty || differs(importKey, complete)) {
        await remote.mutate(
          CoolifyOperation.upsertVariables,
          uuid: e.application!.uuid,
          values: {importKey: pending},
        );
      }
    }
    if (!plan &&
        (changed || writes.isNotEmpty || deletes.any(before.containsKey))) {
      await markPending();
    }
    if (writes.isNotEmpty || deletes.any(before.containsKey)) {
      changed = true;
      terminal.writeln(
        '${e.name}: update runtime variables: ${writes.keys.join(', ')}${deletes.isEmpty ? '' : '; remove: ${deletes.join(', ')}'}.',
      );
      if (!plan) {
        if (writes.isNotEmpty) {
          await remote.mutate(
            CoolifyOperation.upsertVariables,
            uuid: e.application!.uuid,
            values: writes,
          );
        }
        for (final key in deletes) {
          final variable = before[key];
          if (variable != null) {
            await remote.mutate(
              CoolifyOperation.deleteVariable,
              uuid: variable.uuid,
              parent: e.application!.uuid,
            );
          }
        }
      }
    }
    if (imported != null) {
      final metadata = jsonEncode({
        'complete': true,
        'mode': _mode(e.name, env),
        'keys': importedKeys.toList()..sort(),
      });
      if (writes.isNotEmpty || differs(importKey, metadata)) {
        changed = true;
        terminal.writeln(
          '${e.name}: record completed configuration import (${importedKeys.length} keys).',
        );
        if (!plan) {
          final saved = await remote.variables(e.application!.uuid);
          if (writes.entries.any(
            (v) =>
                saved[v.key]?.value != v.value ||
                saved[v.key]?.buildtime != false ||
                saved[v.key]?.literal != true ||
                saved[v.key]?.runtime != true,
          )) {
            throw const TugException(
              'Configuration import was not fully saved. Completion was not recorded; rerun apply.',
            );
          }
          await remote.mutate(
            CoolifyOperation.upsertVariables,
            uuid: e.application!.uuid,
            values: {importKey: metadata},
          );
        }
      }
    }
    final last = await remote.latestDeployment(e.application!.uuid);
    final pending = e.variables['TUG_DEPLOYMENT_PENDING']?.value == 'true';
    // A deployment may have been accepted just before the client was interrupted.
    // Compare its ID with the pre-request baseline instead of queuing it again.
    final accepted =
        pending &&
        before.containsKey('TUG_DEPLOYMENT_BASELINE') &&
        last != null &&
        last.uuid != before['TUG_DEPLOYMENT_BASELINE']!.value &&
        !last.failed;
    if (!changed && accepted) {
      if (!plan) {
        await clearPending();
        if (wait) await _waitDeployment(e.name, last.uuid, e.application!.uuid);
      }
    } else if (!changed &&
        !pending &&
        last != null &&
        !last.finished &&
        !last.failed) {
      if (wait && !plan) {
        await _waitDeployment(e.name, last.uuid, e.application!.uuid);
      }
    } else if (changed ||
        pending ||
        last == null ||
        last.failed ||
        !e.application!.running) {
      terminal.writeln('${e.name}: deploy.');
      if (!plan) {
        if (last != null && !last.finished && !last.failed) {
          if (wait) {
            await _waitDeployment(e.name, last.uuid, e.application!.uuid);
          }
          throw const TugException(
            'An earlier deployment was already running. Rerun apply after it finishes to deploy pending changes.',
          );
        }
        await markPending();
        String id;
        try {
          id = await remote.deploy(e.application!.uuid);
        } on TugException catch (error) {
          if (!error.uncertain) rethrow;
          final accepted = await remote.latestDeployment(e.application!.uuid);
          if (accepted == null || accepted.uuid == last?.uuid) {
            throw const TugException(
              'Deployment request outcome is uncertain. Use status before retrying; no duplicate deployment was queued.',
            );
          }
          id = accepted.uuid;
        }
        await clearPending();
        if (wait) await _waitDeployment(e.name, id, e.application!.uuid);
      }
      changed = true;
    }
    if (!plan && wait && !changed && last?.finished == true && !accepted) {
      await _waitDeployment(e.name, last!.uuid, e.application!.uuid);
    }
    if (!plan) {
      if (!wait) {
        terminal.warning(
          '${e.name}: deployment submitted; health has not been verified (--no-wait).',
        );
      }
      terminal.writeln(
        '${e.name} public URLs:\n  Web  https://${e.domains['web']}\n  API  https://${e.domains['api']}',
      );
      terminal.detail(
        'Container HTTP listeners: API :8080, web :8082. Coolify terminates public HTTPS on :443.',
      );
    }
    if (!plan && project != null) await _cache(s, project, e);
    return changed;
  }

  Map<String, String> _runtime(
    DeploymentSpec s,
    EnvironmentSnapshot e,
    ConnectionInfo pg,
    ConnectionInfo? redis,
    bool plan,
  ) {
    final serviceSecret =
        e.variables['SERVERPOD_SERVICE_SECRET']?.value ??
        e.variables['SERVERPOD_PASSWORD_serviceSecret']?.value ??
        (plan ? '<generated>' : newSecret());
    _redactions.add(serviceSecret);
    return {
      'SERVERPOD_RUN_MODE': 'production',
      'SERVERPOD_SERVER_ID': e.name,
      'SERVERPOD_SERVER_ROLE': 'monolith',
      'SERVERPOD_APPLY_MIGRATIONS': '${s.config.serverpod?.migrations ?? true}',
      'SERVERPOD_APPLY_REPAIR_MIGRATION': 'false',
      for (final type in ['API', 'WEB']) ...{
        'SERVERPOD_${type}_SERVER_PORT': type == 'API' ? '8080' : '8082',
        'SERVERPOD_${type}_SERVER_PUBLIC_HOST': e.domains[type.toLowerCase()]!,
        'SERVERPOD_${type}_SERVER_PUBLIC_PORT': '443',
        'SERVERPOD_${type}_SERVER_PUBLIC_SCHEME': 'https',
      },
      'SERVERPOD_INSIGHTS_SERVER_PORT': '8081',
      'SERVERPOD_INSIGHTS_SERVER_PUBLIC_HOST': 'localhost',
      'SERVERPOD_INSIGHTS_SERVER_PUBLIC_PORT': '8081',
      'SERVERPOD_INSIGHTS_SERVER_PUBLIC_SCHEME': 'http',
      'SERVERPOD_INSIGHTS_SERVER_ENABLE_DATABASE_ACCESS': 'false',
      'SERVERPOD_DATABASE_HOST': pg.host,
      'SERVERPOD_DATABASE_PORT': '${pg.port}',
      'SERVERPOD_DATABASE_NAME': pg.database,
      'SERVERPOD_DATABASE_USER': pg.user,
      'SERVERPOD_DATABASE_PASSWORD': pg.password,
      'SERVERPOD_DATABASE_REQUIRE_SSL': 'false',
      'SERVERPOD_DATABASE_IS_UNIX_SOCKET': 'false',
      'SERVERPOD_SERVICE_SECRET': serviceSecret,
      'SERVERPOD_REDIS_ENABLED': '${redis != null}',
      if (redis != null) ...{
        'SERVERPOD_REDIS_HOST': redis.host,
        'SERVERPOD_REDIS_PORT': '${redis.port}',
        'SERVERPOD_REDIS_USER': redis.user,
        'SERVERPOD_REDIS_PASSWORD': redis.password,
        'SERVERPOD_REDIS_REQUIRE_SSL': 'false',
      },
    };
  }

  Future<void> _waitDeployment(
    String env,
    String id,
    String application,
  ) => terminal.task('$env: deploy and verify application health', () async {
    for (var i = 0; i < pollLimit; i++) {
      final deployment = await remote.deployment(id);
      if (deployment.failed) {
        final logs = redact(deployment.logs, _redactions);
        terminal.errorln(
          logs.split('\n').reversed.take(40).toList().reversed.join('\n'),
        );
        throw TugException(
          'Deployment $id failed. Check build logs, health checks, migrations and database connectivity.',
        );
      }
      if (deployment.finished) {
        final app = await remote.get('application', application);
        final status = app.status.toLowerCase();
        if (status.contains('unhealthy') ||
            status.startsWith('exited') ||
            status.startsWith('stopped') ||
            status.startsWith('dead')) {
          throw TugException(
            'Deployment $id finished, but the application is ${app.status}. '
            'Deployment is not successful. Check Coolify health-check logs and ensure the committed Dockerfile includes wget.',
          );
        }
        if (app.running &&
            (status.contains(':healthy') || status.contains('(healthy)'))) {
          terminal.success(
            '$env: deployment finished; application is healthy.',
          );
          return;
        }
        terminal.detail(
          '$env: deployment finished; waiting for health confirmation (${app.status}).',
        );
      } else {
        terminal.detail('$env: deployment ${deployment.status}.');
      }
      await cancellation.race(_delay(const Duration(seconds: 5)));
    }
    throw TugException(
      'Deployment $id has not confirmed a healthy application within the polling limit. '
      'Use tug status and Coolify health-check logs; no success has been reported.',
    );
  });

  @override
  Future<void> status(
    DeploymentSpec s, {
    String? environment,
    bool logs = false,
  }) async {
    final project = await _project(s);
    if (project == null) {
      terminal.writeln('Project has not been provisioned.');
      return;
    }
    for (final name in _selected(s, environment)) {
      final e = await _snapshot(
        s,
        name,
        project,
        needSources: false,
        sync: false,
      );
      terminal.writeln(
        '$name: application ${e.application?.status ?? 'absent'}, PostgreSQL ${e.postgres?.status ?? 'absent'}, Redis ${e.redis?.status ?? 'absent'}.',
      );
      if (e.application != null) {
        final deployment = await remote.latestDeployment(e.application!.uuid);
        if (deployment != null) {
          terminal.writeln(
            '$name: deployment ${deployment.uuid} ${deployment.status}.',
          );
        }
        if (logs) {
          terminal.writeln(
            redact(await remote.logs(e.application!.uuid), _redactions),
          );
        }
      }
    }
  }

  @override
  Future<void> destroyDeployment(
    DeploymentSpec s, {
    String? environment,
    bool destroyData = false,
    required Future<bool> Function() confirm,
  }) async {
    _validateName(s.config.name, 'name');
    final project = await _project(s);
    if (project == null) {
      terminal.writeln('No changes.');
      return;
    }
    final environments = await remote.list(
      CoolifyOperation.environments,
      uuid: project.uuid,
    );
    final selected = environments
        .where((e) => environment == null || e.name == environment)
        .toList();
    if (environment != null && selected.isEmpty) {
      terminal.writeln('No changes.');
      return;
    }
    final resources = <String, List<RemoteResource>>{};
    // Complete every ownership and persistent-data check before the first mutation or confirmation.
    for (final e in selected) {
      resources[e.uuid] = await remote.resources(project.uuid, e.uuid);
      for (final r in resources[e.uuid]!) {
        if (!['application', 'postgres', 'redis'].contains(r.kind)) {
          throw TugException(
            'Unmanaged resource in ${e.name}; refusing cascading deletion.',
          );
        }
        final detail = await remote.get(r.kind, r.uuid);
        if (!_owned(detail, s, e.name)) {
          throw TugException(
            'Unmanaged resource in ${e.name}; refusing cascading deletion.',
          );
        }
        if (r.kind == 'application' &&
            normalizeRepository(detail.repository ?? '').toLowerCase() !=
                s.layout.repository.toLowerCase()) {
          throw const TugException(
            'Application repository ownership mismatch.',
          );
        }
        final persistent =
            r.kind != 'application' || await remote.hasStorage(r.uuid);
        if (persistent && !destroyData) {
          throw const TugException(
            'Persistent data exists. --destroy-data is required; --yes or confirmation cannot bypass this guard.',
          );
        }
      }
    }
    terminal.writeln(
      'Destroy ${selected.map((e) => e.name).join(', ')}${destroyData ? ' including persistent volumes' : ''}.',
    );
    if (!await confirm()) throw const TugException('Destruction cancelled.');
    for (final e in selected) {
      final ordered = resources[e.uuid]!
        ..sort(
          (a, b) => (a.kind == 'application' ? 0 : 1).compareTo(
            b.kind == 'application' ? 0 : 1,
          ),
        );
      for (final r in ordered) {
        cancellation.throwIfCancelled();
        await remote.mutate(
          r.kind == 'application'
              ? CoolifyOperation.deleteApplication
              : CoolifyOperation.deleteDatabase,
          uuid: r.uuid,
          values: {'destroyData': destroyData},
        );
      }
      if ((await remote.resources(project.uuid, e.uuid)).isEmpty) {
        await remote.mutate(
          CoolifyOperation.deleteEnvironment,
          uuid: e.uuid,
          parent: project.uuid,
        );
      } else {
        throw TugException(
          'Environment ${e.name} is still deleting or has new resources. Rerun destroy; its parent was preserved.',
        );
      }
    }
    if (environment == null &&
        (await remote.list(
          CoolifyOperation.environments,
          uuid: project.uuid,
        )).isEmpty) {
      await remote.mutate(CoolifyOperation.deleteProject, uuid: project.uuid);
    }
    await workspace.saveState(s.layout.root, {});
    terminal.writeln('Destruction completed.');
  }

  @override
  String get logTag => 'DefaultReconcileService';
  @override
  Future<void> destroy() async {
    _redactions.clear();
  }
}
