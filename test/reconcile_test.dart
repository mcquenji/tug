import 'dart:convert';
import 'dart:io';

import 'package:grumpy_cli/grumpy_cli.dart';
import 'package:test/test.dart';
import 'package:tug/src/app/app.dart';
import 'package:tug/src/coolify/infra/infra.dart';
import 'package:tug/src/reconcile/infra/infra.dart';
import 'package:tug/src/reconcile/reconcile.dart';
import 'package:tug/src/serverpod/infra/infra.dart';
import 'package:tug/src/workspace/infra/infra.dart';
import 'package:tug/src/workspace/workspace.dart';

import 'support/config_fixture.dart';
import 'support/fake_coolify_network.dart';
import 'support/memory_terminal.dart';

void main() {
  late Directory temp;
  late ConfigService configService;
  late DeploymentSpec spec;
  late FakeCoolifyNetwork fake;
  late DefaultReconcileService engine;
  late NativeWorkspaceService workspace;
  late MemoryTerminal terminal;
  Future<void> noDelay(Duration _) async {}
  Future<void> sources(String value, {String mode = 'production'}) async {
    final dir = Directory('${spec.layout.root}/server/config');
    await dir.create(recursive: true);
    await File('${dir.path}/$mode.yaml')
        .writeAsString('maxRequestSize: 12345\n');
    await File('${dir.path}/passwords.yaml').writeAsString(
      'shared:\n  jwtSecret: $value\n  database: ignored-database-password\n  serviceSecret: ignored-service-secret\n',
    );
  }

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('tug-reconcile-');
    configService = await configFixture(
      temp,
      local: '''name: demo
serverpod: {server: server, flutter: flutter}
redis: {enabled: true}
environments:
  production:
    branch: main
  staging:
    branch: main
''',
    );
    final config = AppConfig.defaults().resolveConfig(configService);
    const context = CoolifyContext(
      url: 'https://coolify.example.com',
      server: 'server',
      destination: 'destination',
      githubApp: 'github',
      domains: {
        'production': DomainConfig(
          web: 'test.example.com',
          api: 'api-test.example.com',
        ),
        'staging': DomainConfig(
          web: 'staging.example.com',
          api: 'api-staging.example.com',
        ),
      },
    );
    final layout = ProjectLayout(
      root: '${temp.path}/local',
      server: 'server',
      flutter: 'flutter',
      repository: 'https://github.com/example/demo',
      branch: 'main',
      name: 'demo',
      workspace: true,
    );
    spec = DeploymentSpec(config, context, layout, {});
    final versions = File('${layout.root}/.coolify/toolchains.json');
    await versions.parent.create();
    await versions.writeAsString(
      '{"flutter":"3.47.5","dart":"3.13.4","flutterRevision":"6a19cca56475dbfba1478ee68d7bd0c2ef891da1"}',
    );
    workspace = NativeWorkspaceService();
    await workspace.generate(layout, replace: true);
    fake = FakeCoolifyNetwork();
    final cancel = CancellationToken();
    final api = RestCoolifyApiService(fake, cancel, delay: noDelay)
      ..configure(context, 'secret-api-token');
    terminal = MemoryTerminal();
    engine = DefaultReconcileService(
      RestCoolifyDatasource(api),
      NativeServerpodConfigDatasource(),
      workspace,
      terminal,
      cancel,
      delay: noDelay,
      pollLimit: 3,
    );
    await sources('imported-jwt');
  });
  tearDown(() async => temp.delete(recursive: true));
  Map<String, dynamic> app(String env) =>
      fake.resources.values.singleWhere((r) => r['name'] == 'demo-$env-app');
  Map<String, Map<String, dynamic>> vars(String env) =>
      fake.variables[app(env)['uuid']]!;

  Future<void> resourceNames({String? production, String? staging}) async {
    await configService.local.set(AppConfig.settings.environments, {
      'production': EnvironmentConfig(resourceName: production),
      'staging': EnvironmentConfig(resourceName: staging),
    });
    spec = DeploymentSpec(
      AppConfig.defaults().resolveConfig(configService),
      spec.context,
      spec.layout,
      spec.processEnvironment,
    );
  }

  test(
    'custom application names preserve case and environment isolation',
    () async {
      await resourceNames(production: 'StopIt', staging: 'StopIt Staging');
      await engine.apply(spec);
      expect(
        fake.resources.values.map((r) => r['name']),
        unorderedEquals([
          'StopIt',
          'demo-production-postgres',
          'demo-production-redis',
          'StopIt Staging',
          'demo-staging-postgres',
          'demo-staging-redis',
        ]),
      );
      final writes = fake.mutations.length;
      await engine.apply(spec);
      expect(fake.mutations.length, writes);
    },
  );

  test(
    'name override renames in place after cache loss and can be removed',
    () async {
      await engine.apply(spec);
      final application = app('production');
      final uuid = application['uuid'];
      final resourceIds = fake.resources.keys.toSet();
      final databasePassword = vars(
        'production',
      )['SERVERPOD_DATABASE_PASSWORD']!['value'];
      final tags = List.of(application['tags'] as List);
      await File('${spec.layout.root}/.coolify/state.json').delete();
      await resourceNames(production: 'StopIt');
      final writes = fake.mutations.length;
      await engine.apply(spec, environment: 'production', plan: true);
      expect(fake.mutations.length, writes);
      expect(application['name'], 'demo-production-app');
      expect(
        terminal.output.toString(),
        contains('rename application "demo-production-app" to "StopIt"'),
      );
      await engine.apply(spec, environment: 'production');
      expect(application['name'], 'StopIt');
      expect(fake.resources.keys.toSet(), resourceIds);
      expect(application['tags'], tags);
      expect(
        fake.variables[uuid]!['SERVERPOD_DATABASE_PASSWORD']!['value'],
        databasePassword,
      );
      expect(app('staging')['name'], 'demo-staging-app');
      final afterRename = fake.mutations.length;
      await engine.apply(spec);
      expect(fake.mutations.length, afterRename);
      await resourceNames();
      await engine.apply(spec, environment: 'production');
      expect(app('production')['uuid'], uuid);
      expect(fake.resources.keys.toSet(), resourceIds);
    },
  );

  for (final name in [
    '',
    '   ',
    ' StopIt',
    'StopIt ',
    'Stop\nIt',
    'demo-staging-app',
    'demo-production-postgres',
    'demo-production-redis',
  ]) {
    test(
      'invalid or conflicting resource name ${jsonEncode(name)} fails before writes',
      () async {
        await resourceNames(production: name);
        await expectLater(engine.apply(spec), throwsA(isA<TugException>()));
        expect(fake.mutations, isEmpty);
      },
    );
  }

  for (final existing in [false, true]) {
    test(
      'custom name collision outside environment blocks ${existing ? 'rename' : 'creation'}',
      () async {
        if (existing) await engine.apply(spec, environment: 'production');
        fake.resources['foreign'] = {
          'uuid': 'foreign',
          'kind': 'application',
          'name': 'StopIt',
          'environment_uuid': 'foreign-environment',
          'tags': <String>[],
        };
        await resourceNames(production: 'StopIt');
        final writes = fake.mutations.length;
        await expectLater(
          engine.apply(spec, environment: 'production'),
          throwsA(isA<TugException>()),
        );
        expect(fake.mutations.length, writes);
      },
    );
  }

  test(
    'custom name does not adopt an unowned application in the environment',
    () async {
      await engine.apply(spec, environment: 'production');
      final application = app('production');
      application['name'] = 'StopIt';
      application['tags'] = <String>[];
      await resourceNames(production: 'StopIt');
      final writes = fake.mutations.length;
      await expectLater(
        engine.apply(spec, environment: 'production'),
        throwsA(isA<TugException>()),
      );
      expect(fake.mutations.length, writes);
    },
  );

  test('uncertain custom application creation is rediscovered', () async {
    await resourceNames(production: 'StopIt');
    fake.loseCreationPath = 'applications/private-github-app';
    await engine.apply(spec, environment: 'production');
    expect(
      fake.resources.values
          .where((r) => r['kind'] == 'application')
          .single['name'],
      'StopIt',
    );
    final writes = fake.mutations.length;
    await engine.apply(spec, environment: 'production');
    expect(fake.mutations.length, writes);
  });

  for (final state in ['running:unhealthy', 'exited', 'running:unknown']) {
    test(
      'finished deployment with $state application is not success',
      () async {
        fake.deployedApplicationStatus = state;
        await expectLater(
          engine.apply(spec, environment: 'production'),
          throwsA(isA<TugException>()),
        );
        expect(
          terminal.output.toString(),
          isNot(contains('application is healthy')),
        );
        expect(terminal.errors.toString(), contains('Deployment'));
      },
    );
  }

  test('rollback failure logs override finished status and an old healthy container', () async {
    fake.deploymentLogs =
        'New container is unhealthy. Rolling back. secret=never-print-me';
    await expectLater(
      engine.apply(spec, environment: 'production'),
      throwsA(isA<TugException>()),
    );
    expect(
      terminal.output.toString(),
      isNot(contains('application is healthy')),
    );
    expect(terminal.errors.toString(), isNot(contains('never-print-me')));
  });

  test(
    'generic Docker healthcheck warning is not itself a deployment failure',
    () async {
      fake.deploymentLogs =
          'WARNING: Dockerfile deployment healthcheck needs curl or wget.';
      await engine.apply(spec, environment: 'production');
      expect(terminal.output.toString(), contains('application is healthy'));
      expect(
        terminal.output.toString(),
        contains('Web  https://test.example.com'),
      );
      expect(vars('production')['SERVERPOD_WEB_SERVER_PORT']!['value'], '8082');
      expect(
        vars('production')['SERVERPOD_WEB_SERVER_PUBLIC_PORT']!['value'],
        '443',
      );
      expect(
        vars('production')['SERVERPOD_WEB_SERVER_PUBLIC_SCHEME']!['value'],
        'https',
      );
    },
  );

  test('no-wait reports submission without claiming verified health', () async {
    fake.deployedApplicationStatus = 'running:unhealthy';
    await engine.apply(spec, environment: 'production', wait: false);
    expect(
      terminal.errors.toString(),
      contains('health has not been verified'),
    );
    expect(
      terminal.output.toString(),
      isNot(contains('application is healthy')),
    );
  });

  Future<void> explicit({
    Map<String, Object> env = const {},
    Map<String, SecretReference> secrets = const {},
    Map<String, String> process = const {},
  }) async {
    await configService.local.set(AppConfig.settings.environments, {
      ...spec.config.environments,
      'production': EnvironmentConfig(env: env, secrets: secrets),
    });
    spec = DeploymentSpec(
      AppConfig.defaults().resolveConfig(configService),
      spec.context,
      spec.layout,
      process,
    );
  }

  test(
    'project ownership marker uses Coolify-compatible punctuation',
    () async {
      await engine.apply(spec, environment: 'production');
      final description = fake.projects.values.single['description'] as String;
      expect(description, startsWith('managed-by=tug,app=demo,repository='));
      expect(description, isNot(contains(':')));
      expect(description, isNot(contains(';')));
      // A subsequent run must rediscover and verify the existing project.
      await engine.apply(spec, environment: 'production');
      expect(fake.projects, hasLength(1));
    },
  );

  test('foreign repository markers are refused', () async {
    await engine.apply(spec, environment: 'production');
    final project = fake.projects.values.single;
    final writes = fake.mutations.length;
    project['description'] = 'managed-by=tug,app=demo,repository=foreign';
    await expectLater(
      engine.apply(spec, environment: 'production'),
      throwsA(isA<TugException>()),
    );
    expect(fake.mutations.length, writes);
  });

  test(
    'deleted remote resources are recreated despite stale local state',
    () async {
      await engine.apply(spec, environment: 'production');
      final previous = await workspace.readState(spec.layout.root);
      fake.projects.clear();
      fake.environments.clear();
      fake.resources.clear();
      fake.variables.clear();
      fake.deployments.clear();
      final writes = fake.mutations.length;
      await engine.apply(spec, environment: 'production', plan: true);
      expect(fake.mutations.length, writes);
      expect(terminal.output.toString(), contains('Create project demo.'));
      await engine.apply(spec, environment: 'production');
      final current = await workspace.readState(spec.layout.root);
      expect(current['project'], isNot(previous['project']));
      expect(fake.projects, hasLength(1));
      expect(fake.resources, hasLength(3));
      final recreatedWrites = fake.mutations.length;
      await engine.apply(spec, environment: 'production');
      expect(fake.mutations.length, recreatedWrites);
    },
  );

  test(
    'project conflict identifies the API project and expected marker',
    () async {
      fake.projects['foreign-project'] = {
        'uuid': 'foreign-project',
        'name': 'demo',
        'description': 'Do not print this private description',
      };
      await expectLater(
        engine.apply(spec, environment: 'production'),
        throwsA(
          predicate((e) {
            final message = e.toString();
            return e is TugException &&
                message.contains('https://coolify.example.com') &&
                message.contains('foreign-project') &&
                message.contains(
                  'Expected marker: managed-by=tug,app=demo,repository=',
                ) &&
                message.contains('API, not the local state cache') &&
                !message.contains('private description');
          }),
        ),
      );
      expect(fake.mutations, isEmpty);
    },
  );

  test(
    'apply configures and repairs the Serverpod readiness health check',
    () async {
      const desired = {
        'health_check_enabled': true,
        'health_check_type': 'http',
        'health_check_path': '/readyz',
        'health_check_port': '8080',
        'health_check_host': '127.0.0.1',
        'health_check_method': 'GET',
        'health_check_scheme': 'http',
        'health_check_return_code': 200,
        'health_check_response_text': '',
        'health_check_interval': 10,
        'health_check_timeout': 5,
        'health_check_retries': 3,
        'health_check_start_period': 60,
      };
      await engine.apply(spec, environment: 'production');
      final application = app('production');
      for (final entry in desired.entries) {
        expect(application[entry.key], entry.value, reason: entry.key);
      }
      final deployments = fake.deployments.length;
      application.addAll({
        'health_check_enabled': false,
        'health_check_type': 'cmd',
        'health_check_path': '/wrong',
        'health_check_port': '8082',
        'health_check_host': 'example.com',
        'health_check_method': 'POST',
        'health_check_scheme': 'https',
        'health_check_return_code': 201,
        'health_check_response_text': 'wrong',
        'health_check_interval': 1,
        'health_check_timeout': 1,
        'health_check_retries': 1,
        'health_check_start_period': 0,
      });
      final writes = fake.mutations.length;
      await engine.apply(spec, environment: 'production', plan: true);
      expect(fake.mutations.length, writes);
      expect(application['health_check_enabled'], false);
      await engine.apply(spec, environment: 'production');
      for (final entry in desired.entries) {
        expect(application[entry.key], entry.value, reason: entry.key);
      }
      expect(fake.deployments.length, deployments + 1);
      // Coolify versions may serialize numeric settings as strings and empty text as null.
      application['health_check_response_text'] = null;
      application['health_check_enabled'] = 1;
      application['health_check_port'] = 8080;
      for (final key in [
        'health_check_return_code',
        'health_check_interval',
        'health_check_timeout',
        'health_check_retries',
        'health_check_start_period',
      ]) {
        application[key] = '${application[key]}';
      }
      final repairedWrites = fake.mutations.length;
      await engine.apply(spec, environment: 'production');
      expect(fake.mutations.length, repairedWrites);
    },
  );

  test(
    'explicit null baseline is empty while redacted values stay blocked',
    () async {
      await engine.apply(spec, environment: 'production');
      final baseline = vars('production')['TUG_DEPLOYMENT_BASELINE']!;
      baseline['value'] = null;
      await engine.status(spec, environment: 'production');
      baseline.remove('value');
      await expectLater(
        engine.status(spec, environment: 'production'),
        throwsA(isA<TugException>()),
      );
    },
  );

  test(
    'GitHub App repositories use slugs and repair legacy URL values',
    () async {
      await engine.apply(spec, environment: 'production');
      final application = app('production');
      expect(application['git_repository'], 'example/demo');
      application['git_repository'] = 'https://github.com/example/demo';
      await engine.apply(spec, environment: 'production');
      expect(application['git_repository'], 'example/demo');
      final writes = fake.mutations.length;
      await engine.apply(spec, environment: 'production');
      expect(fake.mutations.length, writes);
      application['git_repository'] = 'someone-else/demo';
      await expectLater(
        engine.apply(spec, environment: 'production'),
        throwsA(isA<TugException>()),
      );
      expect(fake.mutations.length, writes);
    },
  );

  test(
    'manifest values and references override imported application values',
    () async {
      await explicit(
        env: {'SERVERPOD_MAX_REQUEST_SIZE': '999999'},
        secrets: {'jwtSecret': const SecretReference(fromEnv: 'JWT_SECRET')},
        process: {'JWT_SECRET': 'explicit-secret'},
      );
      await engine.apply(spec, environment: 'production');
      expect(
        vars('production')['SERVERPOD_MAX_REQUEST_SIZE']!['value'],
        '999999',
      );
      expect(
        vars('production')['SERVERPOD_PASSWORD_jwtSecret']!['value'],
        'explicit-secret',
      );
      await sources('local-rotation');
      await engine.apply(spec, environment: 'production', sync: true);
      expect(
        vars('production')['SERVERPOD_PASSWORD_jwtSecret']!['value'],
        'explicit-secret',
      );
    },
  );
  test(
    'missing explicit references and reserved aliases fail before mutation',
    () async {
      await explicit(
        secrets: {'jwtSecret': const SecretReference(fromEnv: 'MISSING')},
      );
      await expectLater(engine.apply(spec), throwsA(isA<TugException>()));
      expect(fake.mutations, isEmpty);
      await explicit(env: {'SERVERPOD_PASSWORD_database': 'cannot-override'});
      await expectLater(engine.apply(spec), throwsA(isA<TugException>()));
      expect(fake.mutations, isEmpty);
    },
  );
  test('runtime references resolve dotenv and shell values without persisting them', () async {
    await File('${spec.layout.root}/.env').writeAsString(
      'LOCAL_ISSUER=https://dotenv.example.com\nOPTIONAL=dotenv-value\nUNREFERENCED=private-extra\n',
    );
    final process = await loadEnvironment(
      spec.layout.root,
      processEnvironment: {
        'LOCAL_ISSUER': 'https://shell.example.com',
        'OPTIONAL': '',
      },
    );
    await explicit(
      env: {
        'OIDC_ISSUER': const SecretReference(fromEnv: 'LOCAL_ISSUER'),
        'OPTIONAL_SETTING': const SecretReference(fromEnv: 'OPTIONAL'),
        'SERVERPOD_MAX_REQUEST_SIZE': const SecretReference(
          fromEnv: 'REQUEST_SIZE',
        ),
        'APP_THEME': 'blue',
        'DOLLARS': r'${UNCHANGED}',
      },
      process: {...process, 'REQUEST_SIZE': '54321'},
    );
    final manifestBefore = await File(configService.local.path).readAsString();
    await engine.apply(spec, environment: 'production');
    final values = vars('production');
    expect(values['OIDC_ISSUER']!['value'], 'https://shell.example.com');
    expect(values['OPTIONAL_SETTING']!['value'], '');
    expect(values['SERVERPOD_MAX_REQUEST_SIZE']!['value'], '54321');
    expect(values['APP_THEME']!['value'], 'blue');
    expect(values['DOLLARS']!['value'], r'${UNCHANGED}');
    expect(values.containsKey('SERVERPOD_PASSWORD_OIDC_ISSUER'), isFalse);
    expect(values.containsKey('UNREFERENCED'), isFalse);
    expect(manifestBefore, contains('fromEnv'));
    expect(manifestBefore, isNot(contains('https://shell.example.com')));
    expect(await File(configService.local.path).readAsString(), manifestBefore);
  });

  test(
    'missing runtime references and reserved runtime keys fail before writes',
    () async {
      await explicit(
        env: {'OIDC_ISSUER': const SecretReference(fromEnv: 'MISSING')},
      );
      await expectLater(engine.apply(spec), throwsA(isA<TugException>()));
      expect(fake.mutations, isEmpty);
      await explicit(
        env: {
          'SERVERPOD_PASSWORD_database': const SecretReference(
            fromEnv: 'DB_VALUE',
          ),
        },
        process: {'DB_VALUE': 'must-not-override'},
      );
      await expectLater(engine.apply(spec), throwsA(isA<TugException>()));
      expect(fake.mutations, isEmpty);
    },
  );

  test('empty secret references remain invalid', () async {
    await explicit(
      secrets: {'jwtSecret': const SecretReference(fromEnv: 'JWT_SECRET')},
      process: {'JWT_SECRET': ''},
    );
    await expectLater(engine.apply(spec), throwsA(isA<TugException>()));
    expect(fake.mutations, isEmpty);
  });

  test('completion failure preserves imported ownership on retry', () async {
    fake.failCompletedImport = true;
    await expectLater(
      engine.apply(spec, environment: 'production'),
      throwsA(isA<TugException>()),
    );
    expect(
      vars('production')['SERVERPOD_PASSWORD_jwtSecret']!['value'],
      'imported-jwt',
    );
    await engine.apply(spec, environment: 'production');
    final metadata = jsonDecode(
      vars('production')['TUG_IMPORT_V1']!['value'] as String,
    ) as Map;
    expect(metadata['complete'], isTrue);
    expect(metadata['keys'], contains('SERVERPOD_PASSWORD_jwtSecret'));
  });
  test('only previously manifest-managed variables are removed', () async {
    await explicit(env: {'APP_THEME': 'blue'});
    await engine.apply(spec, environment: 'production');
    vars('production')['MANUAL'] = {
      'uuid': 'manual',
      'key': 'MANUAL',
      'value': 'untouched',
      'is_runtime': true,
      'is_buildtime': false,
      'is_literal': true,
    };
    await explicit();
    await engine.apply(spec, environment: 'production');
    expect(vars('production').containsKey('APP_THEME'), isFalse);
    expect(vars('production').containsKey('MANUAL'), isTrue);
    expect(
      vars('production').containsKey('SERVERPOD_PASSWORD_jwtSecret'),
      isTrue,
    );
  });
  test('ambiguity and topology moves refuse before writes', () async {
    await engine.apply(spec, environment: 'production');
    final original = app('production');
    fake.resources['duplicate'] = {...original, 'uuid': 'duplicate'};
    final count = fake.mutations.length;
    await expectLater(
      engine.apply(spec, environment: 'production'),
      throwsA(isA<TugException>()),
    );
    expect(fake.mutations.length, count);
    fake.resources.remove('duplicate');
    original['destination_uuid'] = 'other-destination';
    await expectLater(
      engine.apply(spec, environment: 'production'),
      throwsA(isA<TugException>()),
    );
    expect(fake.mutations.length, count);
  });
  test('missing database is never automatically recreated', () async {
    await engine.apply(spec, environment: 'production');
    fake.resources.removeWhere((k, v) => v['kind'] == 'postgres');
    final count = fake.mutations.length;
    await expectLater(
      engine.apply(spec, environment: 'production'),
      throwsA(isA<TugException>()),
    );
    expect(fake.mutations.length, count);
  });

  test('no-wait apply does not queue an unchanged deployment again', () async {
    fake.deploymentStatus = 'in_progress';
    await engine.apply(spec, environment: 'production', wait: false);
    final writes = fake.mutations.length;
    await engine.apply(spec, environment: 'production', wait: false);
    expect(fake.mutations.length, writes);
    fake.deployments.values.single['status'] = 'finished';
    await engine.apply(spec, environment: 'production');
    expect(fake.mutations.length, writes);
    expect(fake.deployments, hasLength(1));
  });

  test(
    'accepted deployment survives interruption before acknowledgement',
    () async {
      fake.failDeploymentAcknowledgement = true;
      await expectLater(
        engine.apply(spec, environment: 'production'),
        throwsA(isA<TugException>()),
      );
      expect(fake.deployments, hasLength(1));
      await engine.apply(spec, environment: 'production');
      expect(fake.deployments, hasLength(1));
      expect(vars('production')['TUG_DEPLOYMENT_PENDING']!['value'], 'false');
    },
  );

  test(
    'lost deployment response is rediscovered without a duplicate',
    () async {
      fake.loseDeploymentResponse = true;
      await engine.apply(spec, environment: 'production');
      await engine.apply(spec, environment: 'production');
      expect(fake.deployments, hasLength(1));
    },
  );

  test(
    'changes during a deployment remain pending for the next apply',
    () async {
      fake.deploymentStatus = 'in_progress';
      await engine.apply(spec, environment: 'production', wait: false);
      await explicit(env: {'APP_THEME': 'green'});
      await expectLater(
        engine.apply(spec, environment: 'production', wait: false),
        throwsA(isA<TugException>()),
      );
      expect(fake.deployments, hasLength(1));
      fake.deployments.values.single['status'] = 'finished';
      fake.deploymentStatus = 'finished';
      await engine.apply(spec, environment: 'production');
      expect(fake.deployments, hasLength(2));
      await engine.apply(spec, environment: 'production');
      expect(fake.deployments, hasLength(2));
    },
  );

  test(
    'environment isolation, Redis, runtime-only imports and unchanged apply',
    () async {
      await engine.apply(spec);
      expect(fake.projects, hasLength(1));
      expect(fake.environments, hasLength(2));
      expect(fake.resources, hasLength(6));
      expect(fake.deployments, hasLength(2));
      final production = vars('production');
      final staging = vars('staging');
      expect(
        production['SERVERPOD_PASSWORD_jwtSecret']!['value'],
        'imported-jwt',
      );
      expect(
        production['SERVERPOD_DATABASE_PASSWORD']!['value'],
        isNot(staging['SERVERPOD_DATABASE_PASSWORD']!['value']),
      );
      expect(production.containsKey('SERVERPOD_PASSWORD_database'), isFalse);
      expect(
        production['SERVERPOD_SERVICE_SECRET']!['value'],
        isNot('ignored-service-secret'),
      );
      expect(
        production.values.every(
          (v) =>
              v['is_runtime'] == true &&
              v['is_buildtime'] == false &&
              v['is_literal'] == true,
        ),
        isTrue,
      );
      expect(staging['SERVERPOD_RUN_MODE']!['value'], 'production');
      final writes = fake.mutations.length;
      await engine.apply(spec);
      expect(fake.mutations.length, writes);
      expect(terminal.output.toString(), contains('No changes.'));
      final state = await File('${spec.layout.root}/.coolify/state.json')
          .readAsString();
      for (final value in [
        'imported-jwt',
        'ignored-database-password',
        production['SERVERPOD_DATABASE_PASSWORD']!['value'] as String,
      ]) {
        expect(state, isNot(contains(value)));
      }
    },
  );
  test('missing sources and cache loss preserve imported secrets and manual settings', () async {
    await engine.apply(spec, environment: 'production');
    final application = app('production');
    application['custom_labels'] = 'manual-label';
    vars('production')['MANUAL'] = {
      'uuid': 'manual',
      'key': 'MANUAL',
      'value': 'manual-value',
      'is_runtime': true,
      'is_buildtime': false,
      'is_literal': true,
    };
    await Directory('${spec.layout.root}/server/config')
        .delete(recursive: true);
    await File('${spec.layout.root}/.coolify/state.json').delete();
    final writes = fake.mutations.length;
    await engine.apply(spec, environment: 'production');
    expect(fake.mutations.length, writes);
    expect(
      vars('production')['SERVERPOD_PASSWORD_jwtSecret']!['value'],
      'imported-jwt',
    );
    expect(vars('production')['MANUAL']!['value'], 'manual-value');
    expect(application['custom_labels'], 'manual-label');
  });
  test(
    'explicit sync refreshes present imported keys and preserves absent keys',
    () async {
      await engine.apply(spec, environment: 'production');
      await sources('updated-jwt');
      await engine.apply(spec, environment: 'production');
      expect(
        vars('production')['SERVERPOD_PASSWORD_jwtSecret']!['value'],
        'imported-jwt',
      );
      await engine.apply(spec, environment: 'production', sync: true);
      expect(
        vars('production')['SERVERPOD_PASSWORD_jwtSecret']!['value'],
        'updated-jwt',
      );
      await File('${spec.layout.root}/server/config/passwords.yaml')
          .writeAsString('shared: {}');
      await engine.apply(spec, environment: 'production', sync: true);
      expect(
        vars('production')['SERVERPOD_PASSWORD_jwtSecret']!['value'],
        'updated-jwt',
      );
    },
  );
  test(
    'interrupted bulk import resumes without completing prematurely',
    () async {
      fake.failVariableKey = 'SERVERPOD_PASSWORD_jwtSecret';
      await expectLater(
        engine.apply(spec, environment: 'production'),
        throwsA(isA<TugException>()),
      );
      final marker = vars('production')['TUG_IMPORT_V1']?['value'];
      expect(
        marker == null ||
            (jsonDecode(marker as String) as Map)['complete'] == false,
        isTrue,
      );
      await engine.apply(spec, environment: 'production');
      expect(
        vars('production')['SERVERPOD_PASSWORD_jwtSecret']!['value'],
        'imported-jwt',
      );
      expect(
        (jsonDecode(vars('production')['TUG_IMPORT_V1']!['value'] as String)
            as Map)['complete'],
        true,
      );
    },
  );
  test(
    'uncertain creation rediscovery never repeats an accepted POST',
    () async {
      fake.loseCreationPath = 'databases/postgresql';
      await engine.apply(spec, environment: 'production');
      expect(
        fake.resources.values.where((r) => r['kind'] == 'postgres'),
        hasLength(1),
      );
    },
  );
  test('one environment failure preserves progress in the other', () async {
    fake.failEnvironment = 'staging';
    await expectLater(engine.apply(spec), throwsA(isA<TugException>()));
    expect(app('production')['status'], 'running:healthy');
    fake.failEnvironment = null;
    await engine.apply(spec);
    expect(fake.resources, hasLength(6));
    expect(fake.deployments, hasLength(2));
  });
  test('destroy-data is mandatory before confirmation and deletion', () async {
    await engine.apply(spec);
    final count = fake.mutations.length;
    var confirmed = false;
    await expectLater(
      engine.destroyDeployment(
        spec,
        confirm: () async {
          confirmed = true;
          return true;
        },
      ),
      throwsA(isA<TugException>()),
    );
    expect(confirmed, isFalse);
    expect(fake.mutations.length, count);
    await engine.destroyDeployment(
      spec,
      destroyData: true,
      confirm: () async => true,
    );
    expect(fake.projects, isEmpty);
    expect(fake.resources, isEmpty);
    expect(fake.environments, isEmpty);
    expect(
      fake.mutations
          .where(
            (r) =>
                r.method.name == 'delete' &&
                (r.uri.path.contains('/databases/') ||
                    r.uri.path.contains('/applications/')),
          )
          .every((r) => r.query['delete_volumes'] == 'true'),
      isTrue,
    );
  });
  test(
    'unmanaged resources and changed database image block destruction/apply',
    () async {
      await engine.apply(spec, environment: 'production');
      final db = fake.resources.values.singleWhere(
        (r) => r['kind'] == 'postgres',
      );
      db['image'] = 'postgres:17-alpine';
      final count = fake.mutations.length;
      await expectLater(
        engine.apply(spec, environment: 'production'),
        throwsA(isA<TugException>()),
      );
      expect(fake.mutations.length, count);
      app('production')['tags'] = ['someone-else'];
      await expectLater(
        engine.destroyDeployment(
          spec,
          destroyData: true,
          confirm: () async => true,
        ),
        throwsA(isA<TugException>()),
      );
      expect(fake.mutations.length, count);
    },
  );
  test(
    'database types omitted by the environment API block destruction',
    () async {
      await engine.apply(spec, environment: 'production');
      fake.resources['unmanaged-keydb'] = {
        'uuid': 'unmanaged-keydb',
        'kind': 'keydb',
        'name': 'manual-keydb',
        'environment_uuid': app('production')['environment_uuid'],
      };
      final writes = fake.mutations.length;
      await expectLater(
        engine.destroyDeployment(
          spec,
          destroyData: true,
          confirm: () async => true,
        ),
        throwsA(isA<TugException>()),
      );
      expect(fake.mutations.length, writes);
    },
  );
  test(
    'plan validates imports and never mutates; rate limits are retried',
    () async {
      fake.readsToRateLimit = 2;
      await engine.apply(spec, plan: true);
      expect(fake.mutations, isEmpty);
      await File('${spec.layout.root}/server/config/production.yaml')
          .writeAsString('unknown: secret-value');
      await expectLater(engine.apply(spec), throwsA(isA<TugException>()));
      expect(fake.mutations, isEmpty);
    },
  );
}
