import 'package:grumpy_cli/grumpy_cli.dart';
import 'package:tug/src/app/app.dart';

import 'domain/domain.dart';
import 'infra/infra.dart';
import 'presentation/presentation.dart';

export 'domain/domain.dart';
export 'presentation/presentation.dart';

/// Project discovery and reproducible build generation.
class Workspace extends CliModule<AppConfig> {
  @override
  void bindServices(Bind<Service, AppConfig> bind) {
    super.bindServices(bind);
    bind<WorkspaceService>((_, _) => NativeWorkspaceService());
  }

  @override
  List<Route<CliCommand, AppConfig>> get commands => [
    Command(
      name: 'init',
      handler: const InitCommand(),
      description:
          'Detect a Serverpod 4 monorepo and create local deployment files.',
    ),
    Command(
      name: 'generate',
      handler: const GenerateCommand(),
      description: 'Generate a pinned Dockerfile and secret exclusions.',
    ),
  ];
  @override
  String get logTag => 'Workspace';
}
