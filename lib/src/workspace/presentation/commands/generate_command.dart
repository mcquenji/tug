import 'package:grumpy_cli/grumpy_cli.dart';
import 'package:tug/src/app/app.dart';
import 'package:tug/src/workspace/workspace.dart';

class GenerateCommand extends TugCommand {
  const GenerateCommand();
  @override
  ArgumentSchema get arguments =>
      ArgumentSchema(arguments: [CommandOptions.force]);
  @override
  Future<void> run(CommandContext c, AppConfig config) async {
    final workspace = WorkspaceService();
    final layout = await workspace.inspect(projectDirectory(c), config);
    await workspace.generate(
      layout,
      replace: c.args.require(CommandOptions.force),
    );
    c.terminal.writeln('Generated deployment files. Review and commit them.');
  }
}
