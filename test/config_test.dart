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
