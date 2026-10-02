import 'package:grumpy_cli/grumpy_cli.dart';
import 'package:tug/src/app/app.dart';
import 'package:tug/src/workspace/workspace.dart';

class AddEnvironmentCommand extends TugCommand {
  const AddEnvironmentCommand();
  @override
  ArgumentSchema get arguments => ArgumentSchema(
    arguments: [
      CommandOptions.name,
      CommandOptions.web,
      CommandOptions.api,
      CommandOptions.branch,
      CommandOptions.configMode,
    ],
  );
  @override
  Future<void> run(CommandContext c, AppConfig config) async {
    final layout = await WorkspaceService().inspect(
      projectDirectory(c),
      config,
    );
    final selected = c.args.require(CommandOptions.name);
    if (!RegExp(r'^[a-z][a-z0-9-]{0,47}$').hasMatch(selected)) {
      throw const TugException(
        'Use a lowercase environment name with letters, digits or hyphens.',
      );
    }
    if (config.environments.containsKey(selected)) {
      throw const TugException('Environment already exists.');
    }
    await c.config.local.set(AppConfig.settings.environments, {
      ...config.environments,
      selected: EnvironmentConfig(
        branch: c.args.get(CommandOptions.branch) ?? layout.branch,
        configMode: c.args.get(CommandOptions.configMode),
      ),
    });
    final settings = await DeploymentSettings.load(layout.root);
    settings.setDomains(
      selected,
      DomainConfig(
        web: c.args.get(CommandOptions.web) ?? 'auto',
        api: c.args.get(CommandOptions.api) ?? 'auto',
      ),
    );
    await settings.save();
    c.terminal.writeln('Added $selected to coolify.yaml.');
  }
}
