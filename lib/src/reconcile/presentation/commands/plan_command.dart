import 'package:grumpy_cli/grumpy_cli.dart';
import 'package:tug/src/app/app.dart';
import 'package:tug/src/reconcile/reconcile.dart';

class PlanCommand extends DeploymentCommand {
  const PlanCommand();
  @override
  ArgumentSchema get arguments =>
      ArgumentSchema(arguments: [CommandOptions.environment]);
  @override
  Future<void> reconcile(CommandContext c, DeploymentSpec spec) async {
    await ReconcileService().apply(
      spec,
      environment: c.args.get(CommandOptions.environment),
      plan: true,
    );
  }
}
