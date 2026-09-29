import 'dart:io';

import 'package:grumpy_cli/grumpy_cli.dart';
import 'package:tug/src/app/app.dart';
import 'package:tug/src/context/context.dart';
import 'package:tug/src/reconcile/domain/domain.dart';
import 'package:tug/src/workspace/workspace.dart';

/// Resolves a verified workspace and context before invoking reconciliation.
abstract class DeploymentCommand extends TugCommand {
  const DeploymentCommand();

  @override
  Future<void> run(CommandContext context, AppConfig config) async {
    final layout = await WorkspaceService().inspect(
      projectDirectory(context),
      config,
    );
    final connection = resolveCoolifyContext(context, config);
    await reconcile(
      context,
      DeploymentSpec(config, connection, layout, Platform.environment),
    );
  }

  Future<void> reconcile(CommandContext context, DeploymentSpec spec);
}
