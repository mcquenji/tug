import 'package:grumpy_cli/grumpy_cli.dart';

import '../shared/domain/models/app_config.g.dart';
import 'presentation/commands/tug_command.dart';

class TugGroup extends CliModule<AppConfig> {
  TugGroup(this.prefix, this.actions);
  final String prefix;
  final List<String> actions;
  @override
  List<Route<CliCommand, AppConfig>> get commands => [
    for (final action in actions)
      Command(
        name: action,
        handler: TugCommand('$prefix $action'),
        description: TugCommand.descriptions['$prefix $action'] ?? '',
      ),
  ];
  @override
  String get logTag => 'TugGroup';
}
