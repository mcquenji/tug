import 'package:grumpy_cli/grumpy_cli.dart';
import 'package:tug/src/app/app.dart';
import 'package:tug/src/coolify/coolify.dart';

import 'presentation/presentation.dart';
export 'presentation/presentation.dart';
export 'utils/utils.dart';

class Context extends CliModule<AppConfig> {
  @override
  List<Module<CliCommand, AppConfig>> get imports => [Coolify()];
  @override
  List<Route<CliCommand, AppConfig>> get commands => [
    Command(
      name: 'add',
      handler: const AddContextCommand(),
      description: 'Save a Coolify context globally (credentials never accepted as arguments).',
    ),
    Command(
      name: 'list',
      handler: const ListContextsCommand(),
      description: 'List contexts without token values.',
    ),
    Command(
      name: 'use',
      handler: const UseContextCommand(),
      description: 'Select the global default context.',
    ),
    Command(
      name: 'remove',
      handler: const RemoveContextCommand(),
      description: 'Remove a global context.',
    ),
  ];
  @override
  String get logTag => 'Context';
}
