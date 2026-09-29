import 'package:grumpy_cli/grumpy_cli.dart';
import 'package:tug/src/app/app.dart';
import 'package:tug/src/reconcile/reconcile.dart';

import 'presentation/presentation.dart';
export 'presentation/presentation.dart';

class Configuration extends CliModule<AppConfig> {
  @override
  List<Module<CliCommand, AppConfig>> get imports => [Reconcile()];
  @override
  List<Route<CliCommand, AppConfig>> get commands => [
    Command(
      name: 'sync',
      handler: const SyncConfigCommand(),
      description: 'Explicitly refresh imported runtime variables in an existing environment.',
    ),
  ];
  @override
  String get logTag => 'Configuration';
}
