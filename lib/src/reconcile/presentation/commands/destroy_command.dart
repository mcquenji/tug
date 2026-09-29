import 'package:grumpy_cli/grumpy_cli.dart';
import 'package:tug/src/app/app.dart';
import 'package:tug/src/reconcile/reconcile.dart';

class DestroyCommand extends DeploymentCommand {
  const DestroyCommand();
  @override
  ArgumentSchema get arguments => ArgumentSchema(
    arguments: [CommandOptions.destroyData, CommandOptions.yes],
  );
  @override
  Future<void> reconcile(CommandContext c, DeploymentSpec spec) async {
    await ReconcileService().destroyDeployment(
      spec,
      destroyData: c.args.require(CommandOptions.destroyData),
      confirm: () => confirmDestruction(c),
    );
  }
}
