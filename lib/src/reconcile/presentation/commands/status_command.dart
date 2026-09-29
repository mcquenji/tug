import 'package:grumpy_cli/grumpy_cli.dart';
import 'package:tug/src/app/app.dart';
import 'package:tug/src/reconcile/reconcile.dart';

class StatusCommand extends DeploymentCommand {
  const StatusCommand();
  @override
  ArgumentSchema get arguments =>
      ArgumentSchema(arguments: [CommandOptions.environment]);
  @override
  Future<void> reconcile(CommandContext c, DeploymentSpec spec) async {
    await ReconcileService().status(
      spec,
      environment: c.args.get(CommandOptions.environment),
    );
  }
}
