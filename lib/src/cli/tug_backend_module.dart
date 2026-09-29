import 'package:grumpy_cli/grumpy_cli.dart';
import 'package:grumpy_io/grumpy_io.dart';

import '../shared/domain/models/app_config.g.dart';
import '../coolify/domain/services/coolify_api_service.dart';
import '../coolify/domain/datasources/coolify_datasource.dart';
import '../coolify/infra/services/rest_coolify_api_service.dart';
import '../coolify/infra/datasources/rest_coolify_datasource.dart';
import '../serverpod/domain/datasources/serverpod_config_datasource.dart';
import '../serverpod/infra/datasources/native_serverpod_config_datasource.dart';
import '../workspace/domain/services/workspace_service.dart';
import '../workspace/infra/services/native_workspace_service.dart';
import 'tug_networking_module.dart';

class TugBackendModule extends Module<CliCommand, AppConfig> {
  @override
  List<Module<CliCommand, AppConfig>> get imports => [TugNetworkingModule()];
  @override
  List<Route<CliCommand, AppConfig>> get routes => [];
  @override
  void bindServices(Bind<Service, AppConfig> bind) {
    bind<CoolifyApiService>(
      (_, get) => RestCoolifyApiService(
        get<NetworkService>(),
        get<CancellationToken>(),
      ),
    );
    bind<WorkspaceService>((_, _) => NativeWorkspaceService());
  }

  @override
  void bindDatasources(Bind<Datasource, AppConfig> bind) {
    bind<CoolifyDatasource>(
      (_, get) => RestCoolifyDatasource(get<CoolifyApiService>()),
    );
    bind<ServerpodConfigDatasource>(
      (_, _) => NativeServerpodConfigDatasource(),
    );
  }

  @override
  String get logTag => 'TugBackendModule';
}
