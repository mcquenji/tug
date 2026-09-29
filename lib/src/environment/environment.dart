import 'package:grumpy_cli/grumpy_cli.dart';
import 'package:tug/src/app/app.dart';
import 'package:tug/src/reconcile/reconcile.dart';

import 'presentation/presentation.dart';
export 'presentation/presentation.dart';

class Environment extends CliModule<AppConfig> {
  @override
  List<Module<CliCommand, AppConfig>> get imports => [Reconcile()];
  @override
  List<Route<CliCommand, AppConfig>> get commands => [
    Command(
      name: 'add',
      handler: const AddEnvironmentCommand(),
      description: 'Add a named local environment.',
    ),
    Command(
      name: 'destroy',
      handler: const DestroyEnvironmentCommand(),
      description:
          'Destroy one managed environment, including orphaned environments.',
    ),
  ];
  @override
  String get logTag => 'Environment';
}
