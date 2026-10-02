import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:tug/gen/schemas.g.dart';
import 'package:tug/src/app/app.dart';

import 'support/config_fixture.dart';
import 'support/memory_terminal.dart';

void main() {
  late Directory temp;
  setUp(
    () async => temp = await Directory.systemTemp.createTemp('tug-config-'),
  );
  tearDown(() async => temp.delete(recursive: true));
  test(
    'global connections and shared application settings remain separate',
    () async {
      final config = await configFixture(
        temp,
        global: '''currentContext: global
contexts:
  global: {url: https://global.example.com, tokenEnv: TOKEN}
  inherited: {url: https://other.example.com}
''',
        local: 'environments: {}\n',
      );
      final resolved = AppConfig.defaults().resolveConfig(config);
      expect(resolved.currentContext, 'global');
      expect(resolved.contexts.keys, ['global', 'inherited']);
      expect(resolved.database.version, 18);
      final localBefore = await File(config.local.path).readAsString();
      await config.global.set(AppConfig.settings.contexts, {
        'new': const CoolifyContext(
          url: 'https://new.example.com',
          tokenEnv: 'TOKEN',
        ),
      });
      expect(await File(config.local.path).readAsString(), localBefore);
      expect(config.get(AppConfig.settings.contexts)!.keys, ['new']);
      expect(
        await File(config.global.path).readAsString(),
        contains('config.schema.json#/\$defs/global'),
      );
    },
  );
  test('warns about inline manifest secrets without printing values', () async {
    final config = await configFixture(
      temp,
      local: '''environments:
  production:
    env: {API_TOKEN: also-secret, ORDINARY: ordinary}
    secrets:
      jwtSecret: {fromEnv: JWT_SECRET}
''',
    );
    final terminal = MemoryTerminal();
    final code = await App(
      terminal: terminal,
      files: config.files,
    ).run(['context', 'list']);
    expect(code, 0, reason: terminal.errors.toString());
    expect(
      terminal.errors.toString(),
      contains('environments.production.env.API_TOKEN'),
    );
    for (final value in [
      'never-print-me',
      'also-secret',
      'tokenEnv',
      'fromEnv',
      'ORDINARY',
    ]) {
      expect(terminal.errors.toString(), isNot(contains(value)));
    }
    expect(terminal.output.toString(), isNot(contains('never-print-me')));
  });
  test(
    'runtime references decode, round-trip and do not warn as inline secrets',
    () async {
      final config = await configFixture(
        temp,
        local: '''environments:
  production:
    env:
      OIDC_ISSUER: {fromEnv: LOCAL_ISSUER}
      API_TOKEN: {fromEnv: LOCAL_TOKEN}
      APP_THEME: blue
''',
      );
      final resolved = AppConfig.defaults().resolveConfig(config);
      final env = resolved.environments['production']!.env;
      expect((env['OIDC_ISSUER'] as SecretReference).fromEnv, 'LOCAL_ISSUER');
      expect(env['APP_THEME'], 'blue');
      final encoded = AppConfig.settings.environments.type.encode(
        resolved.environments,
      ) as Map;
      expect(encoded['production']['env']['OIDC_ISSUER'], {
        'fromEnv': 'LOCAL_ISSUER',
      });
      validateOffline({'environments': encoded}, scope: 'local');
      final terminal = MemoryTerminal();
      final code = await App(
        terminal: terminal,
        files: config.files,
      ).run(['context', 'list']);
      expect(code, 0);
      expect(
        terminal.errors.toString(),
        isNot(contains('stores a sensitive value')),
      );
    },
  );

  test(
    'application resource names decode and round-trip per environment',
    () async {
      final config = await configFixture(
        temp,
        local: '''name: stop-it
environments:
  production:
    resourceName: StopIt
  staging:
    resourceName: StopIt Staging
  preview: {}
''',
      );
      final environments = AppConfig.defaults()
          .resolveConfig(config)
          .environments;
      expect(environments['production']!.resourceName, 'StopIt');
      expect(environments['staging']!.resourceName, 'StopIt Staging');
      expect(environments['preview']!.resourceName, isNull);
      final encoded =
          AppConfig.settings.environments.type.encode(environments) as Map;
      expect(encoded['production']['resourceName'], 'StopIt');
      expect(encoded['staging']['resourceName'], 'StopIt Staging');
      validateOffline({'environments': encoded}, scope: 'local');
      expect(
        () => validateOffline({
          'environments': {
            'production': {'resourceName': 123},
          },
        }, scope: 'local'),
        throwsException,
      );
    },
  );

  test('schema and config decoder reject malformed runtime references', () {
    for (final invalid in [
      123,
      true,
      null,
      [],
      {},
      {'fromEnv': ''},
      {'fromEnv': 'INVALID-NAME'},
      {'fromEnv': 123},
      {'fromEnv': 'VALUE', 'extra': 'hidden-value'},
    ]) {
      final environments = {
        'production': {
          'env': {'SETTING': invalid},
        },
      };
      expect(
        () => validateOffline({'environments': environments}, scope: 'local'),
        throwsException,
      );
      expect(
        () => AppConfig.settings.environments.type.decode(environments),
        throwsException,
      );
    }
  });

  test('offline schema matches canonical and correctly scopes fields', () {
    expect(
      jsonDecode(configSchemaJson),
      jsonDecode(File('schemas/v1/config.schema.json').readAsStringSync()),
    );
    expect(
      () => validateOffline({
        'contexts': {
          'home': {'tokenEnv': 'TOKEN'},
        },
      }, scope: 'global'),
      returnsNormally,
    );
    expect(
      () => validateOffline({'name': 'demo'}, scope: 'global'),
      throwsException,
    );
    expect(
      () => validateOffline({'name': 'demo', 'contexts': {}}, scope: 'local'),
      throwsException,
    );
    expect(
      () => validateOffline({
        'environments': {
          'production': {'configMode': 'staging'},
        },
      }, scope: 'local'),
      returnsNormally,
    );
    expect(
      () => validateOffline({'secrets': 'never-print'}, scope: 'local'),
      throwsA(predicate((e) => !e.toString().contains('never-print'))),
    );
  });
}
