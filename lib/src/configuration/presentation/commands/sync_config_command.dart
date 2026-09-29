import 'package:grumpy_cli/grumpy_cli.dart';
import 'package:tug/src/app/app.dart';
import 'package:tug/src/reconcile/reconcile.dart';

class SyncConfigCommand extends DeploymentCommand {
  const SyncConfigCommand();
  @override
  ArgumentSchema get arguments => ArgumentSchema(
    arguments: [CommandOptions.environment, CommandOptions.wait],
  );
  @override
  Future<void> reconcile(CommandContext c, DeploymentSpec spec) async {
    final selected = c.args.get(CommandOptions.environment);
    if (selected == null) {
      throw const TugException('config sync requires --environment.');
    }
    await ReconcileService().apply(
      spec,
      environment: selected,
      sync: true,
      wait: c.args.require(CommandOptions.wait),
    );
  }
}
