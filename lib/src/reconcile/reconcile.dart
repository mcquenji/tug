import 'package:grumpy_cli/grumpy_cli.dart';
import 'package:tug/src/app/app.dart';
import 'package:tug/src/coolify/coolify.dart';
import 'package:tug/src/serverpod/serverpod.dart';
import 'package:tug/src/workspace/workspace.dart';

import 'domain/domain.dart';
import 'infra/infra.dart';
import 'presentation/presentation.dart';

export 'domain/domain.dart';
export 'presentation/presentation.dart';
export 'utils/utils.dart';

/// Deployment reconciliation, diagnostics and guarded destruction.
class Reconcile extends CliModule<AppConfig> {
  @override
  List<Module<CliCommand, AppConfig>> get imports => [
    Coolify(),
    Serverpod(),
    Workspace(),
  ];
  @override
  void bindServices(Bind<Service, AppConfig> bind) {
    super.bindServices(bind);
    bind<ReconcileService>(
      (_, resolve) => DefaultReconcileService(
        resolve<CoolifyDatasource>(),
        resolve<ServerpodConfigDatasource>(),
        resolve<WorkspaceService>(),
        resolve<TerminalService>(),
        resolve<CancellationToken>(),
      ),
    );
  }

  @override
  List<Route<CliCommand, AppConfig>> get commands => [
    Command(
      name: 'doctor',
      handler: const DoctorCommand(),
      description:
          'Validate local layout, runtime import and remote prerequisites.',
    ),
    Command(
      name: 'plan',
      handler: const PlanCommand(),
      description: 'Read-only comparison with Coolify.',
    ),
    Command(
      name: 'apply',
      handler: const ApplyCommand(),
      description: 'Reconcile resources and deploy changes.',
    ),
    Command(
      name: 'status',
      handler: const StatusCommand(),
      description: 'Show verified resource and deployment status.',
    ),
    Command(
      name: 'logs',
      handler: const LogsCommand(),
      description: 'Show sanitized application logs.',
    ),
    Command(
      name: 'destroy',
      handler: const DestroyCommand(),
      description: 'Destroy managed resources with persistent-data guards.',
    ),
  ];
  @override
  String get logTag => 'Reconcile';
}
