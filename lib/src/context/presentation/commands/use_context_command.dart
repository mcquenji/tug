import 'package:grumpy_cli/grumpy_cli.dart';
import 'package:tug/src/app/app.dart';
import 'package:tug/src/context/context.dart';

class UseContextCommand extends TugCommand {
  const UseContextCommand();
  @override
  ArgumentSchema get arguments =>
      ArgumentSchema(arguments: [CommandOptions.name]);
  @override
  Future<void> run(CommandContext c, AppConfig config) async {
    final selected = contextName(c);
    final contexts = c.config.global.get(AppConfig.settings.contexts) ?? {};
    if (!contexts.containsKey(selected)) {
      throw const TugException('No such global context.');
    }
    await c.config.global.set(AppConfig.settings.currentContext, selected);
    reportContextSaved(c);
  }
}
