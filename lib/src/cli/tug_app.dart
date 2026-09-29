import 'dart:io';

import 'package:grumpy_cli/grumpy_cli.dart';

import '../shared/domain/models/app_config.g.dart';
import 'infra/services/safe_terminal_service.dart';
import 'presentation/commands/tug_command.dart';
import 'tug_reconcile_module.dart';
import 'tug_group.dart';

class TugApp extends CliApp<AppConfig> {
  TugApp({TerminalService? terminal, this.files})
    : super(AppConfig.defaults(), terminal: terminal ?? SafeTerminalService());
  final ConfigFiles? files;
  @override
  String get executableName => 'tug';
  @override
  String get description =>
      'Deploy Serverpod 4 monorepos to Coolify with private PostgreSQL and runtime configuration.';
  @override
  ConfigFiles get configFiles =>
      files ??
      ConfigFiles(
        applicationId: 'tug',
        global: const ConfigFileOptions(
          filename: 'config.yaml',
          format: ConfigFormat.yaml,
        ),
        local: const ConfigFileOptions(
          filename: 'coolify.yaml',
          format: ConfigFormat.yaml,
        ),
        globalDirectory: Platform.environment['TUG_GLOBAL_DIR'],
        localDirectory: Platform.environment['TUG_LOCAL_DIR'],
      );
  @override
  ArgumentSchema get arguments =>
      ArgumentSchema(arguments: [TugCommand.contextOption]);
  @override
  List<Module<CliCommand, AppConfig>> get imports => [TugReconcileModule()];
  @override
  List<Route<CliCommand, AppConfig>> get commands => [
    for (final name in [
      'init',
      'generate',
      'doctor',
      'plan',
      'apply',
      'status',
      'logs',
      'destroy',
    ])
      Command(
        name: name,
        handler: TugCommand(name),
        description: TugCommand.descriptions[name] ?? '',
      ),
    CommandGroup(
      name: 'context',
      module: TugGroup('context', ['add', 'list', 'use', 'remove']),
      description: 'Manage globally stored Coolify connections.',
    ),
    CommandGroup(
      name: 'environment',
      module: TugGroup('environment', ['add', 'destroy']),
      description: 'Manage isolated deployment environments.',
    ),
    CommandGroup(
      name: 'config',
      module: TugGroup('config', ['sync']),
      description: 'Refresh native Serverpod runtime configuration.',
    ),
  ];
  @override
  String get logTag => 'TugApp';
}
