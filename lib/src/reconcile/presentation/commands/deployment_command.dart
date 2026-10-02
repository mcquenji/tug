import 'package:grumpy_cli/grumpy_cli.dart';
import 'package:tug/src/app/app.dart';
import 'package:tug/src/context/context.dart';
import 'package:tug/src/reconcile/domain/domain.dart';
import 'package:tug/src/workspace/workspace.dart';

/// Resolves a verified workspace and context before invoking reconciliation.
abstract class DeploymentCommand extends TugCommand {
  const DeploymentCommand();
  bool get needsInfrastructure => true;
  bool get needsDomains => true;

  @override
  Future<void> run(CommandContext context, AppConfig config) async {
    final layout = await context.terminal.task(
      'Inspect workspace',
      () => WorkspaceService().inspect(projectDirectory(context), config),
    );
    final connection = await resolveCoolifyContext(
      context,
      config,
      requireInfrastructure: needsInfrastructure,
      requireDomains: needsDomains,
    );
    await reconcile(
      context,
      DeploymentSpec(
        config,
        connection,
        layout,
        await commandEnvironment(context),
      ),
    );
  }

  Future<void> reconcile(CommandContext context, DeploymentSpec spec);
}
