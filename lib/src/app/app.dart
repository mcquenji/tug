import 'dart:io';

import 'package:grumpy_cli/grumpy_cli.dart';
import 'package:tug/src/configuration/configuration.dart';
import 'package:tug/src/context/context.dart';
import 'package:tug/src/environment/environment.dart';
import 'package:tug/src/reconcile/reconcile.dart';
import 'package:tug/src/workspace/workspace.dart';

import 'domain/domain.dart';
import 'infra/infra.dart';
import 'presentation/presentation.dart';

export 'domain/domain.dart';
export 'presentation/presentation.dart';
export 'utils/utils.dart';

/// The root application module, composing Tug's feature modules.
class App extends CliApp<AppConfig> {
  App({TerminalService? terminal, this.files})
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
      ArgumentSchema(arguments: [CommandOptions.context]);

  @override
  List<Module<CliCommand, AppConfig>> get imports => [Reconcile()];

  @override
  List<Route<CliCommand, AppConfig>> get commands => [
    ...Workspace().commands,
    ...Reconcile().commands,
    CommandGroup(
      name: 'context',
      module: Context(),
      description: 'Manage globally stored Coolify connections.',
    ),
    CommandGroup(
      name: 'environment',
      module: Environment(),
      description: 'Manage isolated deployment environments.',
    ),
    CommandGroup(
      name: 'config',
      module: Configuration(),
      description: 'Refresh native Serverpod runtime configuration.',
    ),
  ];

  @override
  String get logTag => 'App';
}
