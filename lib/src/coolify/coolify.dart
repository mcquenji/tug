import 'package:grumpy_cli/grumpy_cli.dart';
import 'package:grumpy_io/grumpy_io.dart';
import 'package:tug/src/app/app.dart';

import 'domain/domain.dart';
import 'infra/infra.dart';

export 'domain/domain.dart';

/// Coolify API transport and typed response parsing.
class Coolify extends Module<CliCommand, AppConfig> {
  @override
  List<Module<CliCommand, AppConfig>> get imports => [
    CoolifyNetworkingModule(),
  ];
  @override
  List<Route<CliCommand, AppConfig>> get routes => [];
  @override
  void bindServices(Bind<Service, AppConfig> bind) {
    super.bindServices(bind);
    bind<CoolifyApiService>(
      (_, resolve) => RestCoolifyApiService(
        resolve<NetworkService>(),
        resolve<CancellationToken>(),
        terminal: resolve<TerminalService>(),
      ),
    );
  }

  @override
  void bindDatasources(Bind<Datasource, AppConfig> bind) {
    super.bindDatasources(bind);
    bind<CoolifyDatasource>(
      (_, resolve) => RestCoolifyDatasource(resolve<CoolifyApiService>()),
    );
  }

  @override
  String get logTag => 'Coolify';
}
