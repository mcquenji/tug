import 'dart:convert';
import 'dart:io';

import 'package:grumpy_cli/grumpy_cli.dart';
import 'package:test/test.dart';
import 'package:tug/src/app/app.dart';
import 'package:yaml/yaml.dart';

import 'support/config_fixture.dart';
import 'support/memory_terminal.dart';

void main() {
  late Directory temp;
  late ConfigService config;

  setUp(() async {
    final directory = await Directory.systemTemp.createTemp('tug-commands-');
    temp = Directory(await directory.resolveSymbolicLinks());
    config = await configFixture(temp);
  });
  tearDown(() async => temp.delete(recursive: true));

  Future<MemoryTerminal> invoke(
    List<String> arguments, {
    int code = 0,
    List<String>? input,
  }) async {
    final terminal = MemoryTerminal(input: input);
    final result = await App(
      terminal: terminal,
      files: config.files,
    ).run(arguments);
    expect(result, code, reason: terminal.errors.toString());
    return terminal;
  }

  Future<void> git(List<String> arguments) async {
    final result = await Process.run('git', arguments);
    expect(result.exitCode, 0, reason: '${result.stderr}');
  }

  test(
    'version needs neither configuration nor a pubspec on the target system',
    () async {
      await File(config.local.path).writeAsString('invalid: [private-secret');
      await File(config.global.path).writeAsString('invalid: [private-secret');
      final terminal = await invoke(['--version']);
      final pubspec =
          loadYaml(await File('pubspec.yaml').readAsString()) as Map;
      expect(terminal.output.toString(), 'tug ${pubspec['version']}\n');
      expect(terminal.errors.toString(), isEmpty);
    },
  );

  Future<void> projectFile(String name, String content) async {
    final file = File('${temp.path}/local/$name');
    await file.parent.create(recursive: true);
    await file.writeAsString(content);
  }

  test(
    'feature command groups expose independent help and arguments',
    () async {
      final context = await invoke(['context', 'add', '--help']);
      expect(context.output.toString(), contains('--token-env'));
      expect(context.output.toString(), isNot(contains('--destroy-data')));
      final environment = await invoke(['environment', 'destroy', '--help']);
      expect(environment.output.toString(), contains('--destroy-data'));
      expect(environment.output.toString(), isNot(contains('--token-env')));
      final sync = await invoke(['config', 'sync', '--help']);
      expect(sync.output.toString(), contains('--environment'));
      expect(sync.output.toString(), contains('--[no-]wait'));
      expect(sync.output.toString(), isNot(contains('--destroy-data')));
    },
  );

  test(
    'context commands retain global writes across separate app lifecycles',
    () async {
      final localBefore = await File(config.local.path).readAsString();
      for (final name in ['home', 'work']) {
        await invoke([
          'context',
          'add',
          name,
          '--url',
          'https://coolify.example.com',
          '--token-env',
          'TUG_TEST_TOKEN',
          '--server',
          'server',
          '--destination',
          'destination',
          '--github-app',
          'github-app',
        ]);
      }
      await invoke(['context', 'use', 'work']);
      final listed = await invoke(['context', 'list']);
      expect(listed.output.toString(), contains('work (current)'));
      await invoke(['context', 'remove', 'work']);
      final global =
          loadYaml(await File(config.global.path).readAsString()) as Map;
      expect((global['contexts'] as Map).keys, ['home']);
      expect(global['currentContext'], isNull);
      expect(await File(config.local.path).readAsString(), localBefore);
    },
  );

  test('context add prompts for every missing value', () async {
    final terminal = await invoke(
      ['context', 'add'],
      input: [
        'home',
        'https://coolify.example.com',
        'COOLIFY_API_TOKEN',
        'server',
        'destination',
        'github-app',
        'web.example.com',
        'api.example.com',
      ],
    );
    final global =
        loadYaml(await File(config.global.path).readAsString()) as Map;
    final context = global['contexts']['home'] as Map;
    expect(global['currentContext'], 'home');
    expect(context['url'], 'https://coolify.example.com');
    expect(context['tokenEnv'], 'COOLIFY_API_TOKEN');
    expect(context['token'], isNull);
    expect(context['server'], 'server');
    expect(context['destination'], 'destination');
    expect(context['githubApp'], 'github-app');
    expect(context['domains']['default'], {
      'web': 'web.example.com',
      'api': 'api.example.com',
    });
    expect(terminal.promptSecrets, List.filled(8, false));
  });

  test(
    'context add skips supplied values and obscures a stored token',
    () async {
      final terminal = await invoke(
        [
          'context',
          'add',
          'home',
          '--url',
          'https://coolify.example.com',
          '--server',
          'server',
          '--destination',
          'destination',
          '--github-app',
          'github-app',
          '--web-domain',
          'web.example.com',
        ],
        input: ['', 'secret-test-token', ''],
      );
      final global =
          loadYaml(await File(config.global.path).readAsString()) as Map;
      final context = global['contexts']['home'] as Map;
      expect(context['token'], 'secret-test-token');
      expect(context['tokenEnv'], isNull);
      expect(context['domains']['default'], {
        'web': 'web.example.com',
        'api': 'auto',
      });
      expect(terminal.promptSecrets, [false, true, false]);
      expect(
        '${terminal.output}${terminal.errors}',
        isNot(contains('secret-test-token')),
      );
    },
  );

  test(
    'context add validates prompted names without writing configuration',
    () async {
      final before = await File(config.global.path).readAsString();
      final terminal = await invoke(
        ['context', 'add'],
        input: ['invalid name'],
        code: 1,
      );
      expect(terminal.errors.toString(), contains('Invalid context name'));
      expect(await File(config.global.path).readAsString(), before);
    },
  );

  test('context add requires missing values in non-interactive mode', () async {
    final before = await File(config.global.path).readAsString();
    final terminal = await invoke(['context', 'add'], code: 64);
    expect(
      terminal.errors.toString(),
      contains('Cannot prompt for "Context name"'),
    );
    expect(await File(config.global.path).readAsString(), before);
  });

  test('workspace and environment modules preserve scoped initialization and generation', () async {
    await File(config.local.path).delete();
    final root = '${temp.path}/local';
    await git(['init', '--initial-branch=main', root]);
    await git([
      '-C',
      root,
      'remote',
      'add',
      'origin',
      'git@github.com:example/demo.git',
    ]);
    await projectFile(
      'pubspec.yaml',
      'name: demo\nworkspace: [server, flutter]\n',
    );
    await projectFile(
      'pubspec.lock',
      'packages:\n  serverpod: {version: 4.0.3}\n',
    );
    await projectFile(
      'server/pubspec.yaml',
      'name: demo_server\ndependencies:\n  serverpod: ^4.0.3\n',
    );
    await projectFile(
      'flutter/pubspec.yaml',
      'name: demo_flutter\ndependencies:\n  flutter: {sdk: flutter}\n',
    );
    await projectFile('server/lib/src/generated/protocol.yaml', '{}');
    await projectFile('server/bin/main.dart', 'void main() {}');
    await projectFile(
      '.coolify/toolchains.json',
      '${const JsonEncoder.withIndent('  ').convert({'flutter': '3.47.5', 'dart': '3.13.4', 'flutterRevision': '6a19cca56475dbfba1478ee68d7bd0c2ef891da1'})}\n',
    );
    final globalBefore = await File(config.global.path).readAsString();
    await invoke([
      'init',
      '--web-domain',
      'web.example.com',
      '--api-domain',
      'api.example.com',
    ]);
    await invoke([
      'environment',
      'add',
      'staging',
      '--branch',
      'develop',
      '--config-mode',
      'development',
    ]);
    final local = loadYaml(await File(config.local.path).readAsString()) as Map;
    expect(local['name'], 'demo');
    final environments = local['environments'] as Map;
    expect(environments.keys, containsAll(['production', 'staging']));
    expect(environments['production']['branch'], 'main');
    expect(environments['staging']['branch'], 'develop');
    expect(environments['staging']['configMode'], 'development');
    final dockerfile = File('$root/.coolify/Dockerfile');
    final generated = await dockerfile.readAsString();
    await invoke(['generate']);
    expect(await dockerfile.readAsString(), generated);
    expect(await File(config.global.path).readAsString(), globalBefore);
  });
}
