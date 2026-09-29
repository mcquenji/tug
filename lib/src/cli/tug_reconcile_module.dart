import 'package:grumpy_cli/grumpy_cli.dart';

import '../shared/domain/models/app_config.g.dart';
import '../coolify/domain/datasources/coolify_datasource.dart';
import '../serverpod/domain/datasources/serverpod_config_datasource.dart';
import '../workspace/domain/services/workspace_service.dart';
import '../reconcile/domain/services/reconcile_service.dart';
import '../reconcile/infra/services/default_reconcile_service.dart';
import 'tug_backend_module.dart';

class TugReconcileModule extends Module<CliCommand, AppConfig> {
  @override
  List<Module<CliCommand, AppConfig>> get imports => [TugBackendModule()];
  @override
  List<Route<CliCommand, AppConfig>> get routes => [];
  @override
  void bindServices(Bind<Service, AppConfig> bind) {
    bind<ReconcileService>(
      (_, get) => DefaultReconcileService(
        get<CoolifyDatasource>(),
        get<ServerpodConfigDatasource>(),
        get<WorkspaceService>(),
        get<TerminalService>(),
        get<CancellationToken>(),
      ),
    );
  }

  @override
  String get logTag => 'TugReconcileModule';
}
