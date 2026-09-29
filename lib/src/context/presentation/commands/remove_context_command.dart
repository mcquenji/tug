import 'package:grumpy_cli/grumpy_cli.dart';
import 'package:tug/src/app/app.dart';
import 'package:tug/src/context/context.dart';

class RemoveContextCommand extends TugCommand {
  const RemoveContextCommand();
  @override
  ArgumentSchema get arguments =>
      ArgumentSchema(arguments: [CommandOptions.name]);
  @override
  Future<void> run(CommandContext c, AppConfig config) async {
    final selected = contextName(c);
    final global = c.config.global;
    final contexts = {...?global.get(AppConfig.settings.contexts)}
      ..remove(selected);
    await global.update((edit) {
      edit.set(AppConfig.settings.contexts, contexts);
      if (global.get(AppConfig.settings.currentContext) == selected) {
        edit.remove(AppConfig.settings.currentContext);
      }
    });
    reportContextSaved(c);
  }
}
