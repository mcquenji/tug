import 'package:grumpy_cli/grumpy_cli.dart';
import 'package:tug/src/app/app.dart';
import 'package:tug/src/reconcile/reconcile.dart';

class DestroyEnvironmentCommand extends DeploymentCommand {
  const DestroyEnvironmentCommand();
  @override
  bool get needsInfrastructure => false;
  @override
  bool get needsDomains => false;
  @override
  ArgumentSchema get arguments => ArgumentSchema(
    arguments: [
      CommandOptions.name,
      CommandOptions.destroyData,
      CommandOptions.yes,
    ],
  );
  @override
  Future<void> reconcile(CommandContext c, DeploymentSpec spec) async {
    await c.terminal.task(
      'Destroy managed environment',
      () => ReconcileService().destroyDeployment(
        spec,
        environment: c.args.require(CommandOptions.name),
        destroyData: c.args.require(CommandOptions.destroyData),
        confirm: () => confirmDestruction(c),
      ),
    );
  }
}
