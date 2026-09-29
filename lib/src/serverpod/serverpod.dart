import 'package:grumpy_cli/grumpy_cli.dart';
import 'package:tug/src/app/app.dart';

import 'domain/domain.dart';
import 'infra/infra.dart';

export 'domain/domain.dart';

/// Native Serverpod runtime-configuration import.
class Serverpod extends Module<CliCommand, AppConfig> {
  @override
  List<Route<CliCommand, AppConfig>> get routes => [];
  @override
  void bindDatasources(Bind<Datasource, AppConfig> bind) {
    super.bindDatasources(bind);
    bind<ServerpodConfigDatasource>(
      (_, _) => NativeServerpodConfigDatasource(),
    );
  }

  @override
  String get logTag => 'Serverpod';
}
