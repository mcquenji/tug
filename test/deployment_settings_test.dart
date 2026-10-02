import 'dart:io';

import 'package:grumpy_cli/grumpy_cli.dart';
import 'package:test/test.dart';
import 'package:tug/src/app/app.dart';
import 'package:tug/src/context/context.dart';
import 'package:tug/src/coolify/infra/infra.dart';

import 'support/config_fixture.dart';
import 'support/fake_coolify_network.dart';
import 'support/memory_terminal.dart';

class ConnectCommand extends TugCommand {
  const ConnectCommand(this.connect);
  final Future<void> Function(CommandContext, AppConfig) connect;
  @override
  Future<void> run(CommandContext c, AppConfig config) => connect(c, config);
}

class ConnectApp extends App {
  @override
  String get logTag => 'ConnectApp';
  ConnectApp({
    required super.files,
    required super.terminal,
    required this.connect,
  });
  final Future<void> Function(CommandContext, AppConfig) connect;
  @override
  List<Route<CliCommand, AppConfig>> get commands => [
    Command(name: 'connect', handler: ConnectCommand(connect)),
  ];
}

void main() {
  test(
    'first use can configure a private connection without global contexts',
    () async {
      final root = await Directory.systemTemp.createTemp('tug-private-');
      addTearDown(() => root.delete(recursive: true));
      final config = await configFixture(root);
      final fake = FakeCoolifyNetwork();
      final api = RestCoolifyApiService(fake, CancellationToken());
      final terminal = MemoryTerminal(
        input: [
          'local',
          'https://coolify.example.com',
          'private-token',
          '1',
          '1',
          '1',
        ],
      );
      final code = await ConnectApp(
        files: config.files,
        terminal: terminal,
        connect: (c, cfg) async {
          await resolveCoolifyContext(
            c,
            cfg,
            api: api,
            remote: RestCoolifyDatasource(api),
          );
        },
      ).run(['connect']);
      expect(code, 0, reason: terminal.errors.toString());
      final settings = await DeploymentSettings.load('${root.path}/local');
      expect(settings.context, 'local');
      expect(settings.contexts['local']!.token, 'private-token');
      expect(terminal.promptSecrets, contains(true));
      expect(
        '${terminal.output}${terminal.errors}',
        isNot(contains('private-token')),
      );
    },
  );
  test(
    'missing context, resources and domains are selected and saved privately',
    () async {
      final root = await Directory.systemTemp.createTemp('tug-private-');
      addTearDown(() => root.delete(recursive: true));
      final config = await configFixture(
        root,
        global: '''contexts:
  home: {url: https://coolify.example.com, tokenEnv: TUG_FIXTURE_TOKEN}
''',
        local: 'name: demo\nenvironments: {production: {}}\n',
      );
      final shared = await File(config.local.path).readAsString();
      final global = await File(config.global.path).readAsString();
      final localRoot = '${root.path}/local';
      await File('$localRoot/.env')
          .writeAsString('TUG_FIXTURE_TOKEN=from-env-file\n');
      final fake = FakeCoolifyNetwork();
      final api = RestCoolifyApiService(fake, CancellationToken());
      CoolifyContext? resolved;
      Future<void> connect(CommandContext c, AppConfig cfg) async {
        resolved = await resolveCoolifyContext(
          c,
          cfg,
          api: api,
          remote: RestCoolifyDatasource(api),
        );
      }

      final terminal = MemoryTerminal(
        input: ['1', '1', '1', '1', 'web.example.com', 'api.example.com'],
      );
      final code = await ConnectApp(
        files: config.files,
        terminal: terminal,
        connect: connect,
      ).run(['connect']);
      expect(code, 0, reason: terminal.errors.toString());
      expect(resolved!.server, 'server');
      expect(resolved!.domains['production']!.web, 'web.example.com');
      expect(
        fake.requests.every(
          (r) => r.headers['Authorization'] == 'Bearer from-env-file',
        ),
        true,
      );
      expect(await File(config.local.path).readAsString(), shared);
      expect(await File(config.global.path).readAsString(), global);
      final saved = await DeploymentSettings.load(localRoot);
      expect(saved.context, 'home');
      expect(saved.contexts['home']!.githubApp, 'github');
      expect(
        await File('$localRoot/.gitignore').readAsString(),
        contains('/.env'),
      );
      final again = MemoryTerminal();
      expect(
        await ConnectApp(
          files: config.files,
          terminal: again,
          connect: connect,
        ).run(['connect']),
        0,
        reason: again.errors.toString(),
      );
      expect(again.promptSecrets, isEmpty);
      expect(
        '${terminal.output}${terminal.errors}',
        isNot(contains('from-env-file')),
      );
    },
  );

  test(
    'missing unattended settings fail without persisting partial configuration',
    () async {
      final root = await Directory.systemTemp.createTemp('tug-private-');
      addTearDown(() => root.delete(recursive: true));
      final config = await configFixture(
        root,
        global: 'contexts: {home: {url: https://coolify.example.com}}',
      );
      final terminal = MemoryTerminal();
      final code = await ConnectApp(
        files: config.files,
        terminal: terminal,
        connect: (c, cfg) async {
          await resolveCoolifyContext(c, cfg);
        },
      ).run(['connect', '--non-interactive']);
      expect(code, 64);
      expect(
        await File('${root.path}/local/.coolify/local.yaml').exists(),
        false,
      );
    },
  );
}
