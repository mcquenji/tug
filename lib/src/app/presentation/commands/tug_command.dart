import 'package:grumpy_cli/grumpy_cli.dart';
import 'package:tug/src/app/app.dart';
import 'package:tug/src/app/infra/infra.dart';

/// Common configuration preflight for each independently declared command.
abstract class TugCommand extends CliCommand {
  const TugCommand();

  @override
  Future<CommandResult> execute(CommandContext context) async {
    if (context.terminal case SafeTerminalService terminal) {
      terminal.colorEnabled = context.args.require(CommandOptions.color);
      terminal.verboseEnabled = context.args.require(CommandOptions.verbose);
    }
    if (context.args.require(CommandOptions.version)) {
      context.terminal.writeln('tug ${App.buildVersion}');
      return CommandResult.success;
    }
    await validateConfiguration(context);
    warnLocalSensitiveValues(context);
    await run(context, AppConfig());
    return CommandResult.success;
  }

  Future<void> run(CommandContext context, AppConfig config);
}
