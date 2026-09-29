import 'dart:io';

import 'package:grumpy_cli/grumpy_cli.dart';
import 'package:tug/src/app/app.dart';
import 'package:tug/src/workspace/workspace.dart';

class InitCommand extends TugCommand {
  const InitCommand();
  @override
  ArgumentSchema get arguments => ArgumentSchema(
    arguments: [
      CommandOptions.web,
      CommandOptions.api,
      CommandOptions.branch,
      CommandOptions.configMode,
      CommandOptions.force,
    ],
  );
  @override
  Future<void> run(CommandContext c, AppConfig config) async {
    final workspace = WorkspaceService();
    final layout = await workspace.inspect(projectDirectory(c), config);
    if (await File(c.config.local.path).exists() &&
        !c.args.require(CommandOptions.force)) {
      throw const TugException(
        'coolify.yaml already exists. Review it before using init --force.',
      );
    }
    final env = EnvironmentConfig(
      branch: c.args.get(CommandOptions.branch) ?? layout.branch,
      domains: DomainConfig(
        web: c.args.get(CommandOptions.web) ?? 'auto',
        api: c.args.get(CommandOptions.api) ?? 'auto',
      ),
      configMode: c.args.get(CommandOptions.configMode),
    );
    await workspace.generate(
      layout,
      replace: c.args.require(CommandOptions.force),
    );
    await c.config.local.update((edit) {
      edit.set(AppConfig.settings.name, layout.name);
      edit.set(
        AppConfig.settings.source,
        SourceConfig(repository: layout.repository),
      );
      edit.set(
        AppConfig.settings.serverpod,
        ServerpodConfig(server: layout.server, flutter: layout.flutter),
      );
      edit.set(AppConfig.settings.environments, {'production': env});
      if (c.args.wasProvided(CommandOptions.context)) {
        edit.set(
          AppConfig.settings.context,
          c.args.require(CommandOptions.context),
        );
      }
    });
    c.terminal.writeln(
      'Created coolify.yaml and .coolify build files. Review and commit the generated deployment files and dependency locks. Runtime YAML and passwords are never staged or committed by Tug.',
    );
  }
}
