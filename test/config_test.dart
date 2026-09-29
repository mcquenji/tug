import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:tug/src/cli/tug_app.dart';
import 'package:tug/src/shared/domain/models/app_config.g.dart';
import 'package:tug/src/shared/domain/models/coolify_context.dart';
import 'package:tug/src/shared/utils/schema_validation.dart';
import 'package:tug/src/shared/generated/schemas.g.dart';

import 'support/config_fixture.dart';
import 'support/memory_terminal.dart';

void main() {
  late Directory temp;
  setUp(
    () async => temp = await Directory.systemTemp.createTemp('tug-config-'),
  );
  tearDown(() async => temp.delete(recursive: true));
  test(
    'default Grumpy precedence replaces maps and scoped writes remain scoped',
    () async {
      final config = await configFixture(
        temp,
        global: '''currentContext: global
contexts:
  global: {url: https://global.example.com, tokenEnv: TOKEN}
  inherited: {url: https://other.example.com}
''',
        local: '''currentContext: local
contexts:
  local: {url: https://local.example.com}
environments: {}
''',
      );
      final resolved = AppConfig.defaults().resolveConfig(config);
      expect(resolved.currentContext, 'local');
      expect(resolved.contexts.keys, ['local']);
      expect(resolved.database.version, 18);
      final localBefore = await File(config.local.path).readAsString();
      await config.global.set(AppConfig.settings.contexts, {
        'new': const CoolifyContext(
          url: 'https://new.example.com',
          tokenEnv: 'TOKEN',
        ),
      });
      expect(await File(config.local.path).readAsString(), localBefore);
      expect(config.get(AppConfig.settings.contexts)!.keys, ['local']);
      await config.local.remove(AppConfig.settings.contexts);
      expect(config.get(AppConfig.settings.contexts)!.keys, ['new']);
      expect(
        await File(config.global.path).readAsString(),
        contains('config.schema.json#/\$defs/global'),
      );
      expect(
        await File(config.local.path).readAsString(),
        contains('config.schema.json#/\$defs/local'),
      );
    },
  );
  test(
    'warns for inactive local credentials once without printing values',
    () async {
      final config = await configFixture(
        temp,
        local: '''currentContext: active
contexts:
  active: {url: https://active.example.com, tokenEnv: TOKEN}
  inactive: {url: https://inactive.example.com, token: never-print-me}
environments:
  production:
    env: {API_TOKEN: also-secret, ORDINARY: ordinary}
    secrets:
      jwtSecret: {fromEnv: JWT_SECRET}
''',
      );
      final terminal = MemoryTerminal();
      final code = await TugApp(
        terminal: terminal,
        files: config.files,
      ).run(['context', 'list']);
      expect(code, 0, reason: terminal.errors.toString());
      expect(terminal.errors.toString(), contains('contexts.inactive.token'));
      expect(
        'contexts.inactive.token'.allMatches(terminal.errors.toString()).length,
        1,
      );
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
    },
  );
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
      returnsNormally,
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
