import 'package:grumpy_cli/grumpy_cli.dart';

import '../../../shared/domain/models/app_config.g.dart';
import '../../../shared/domain/models/coolify_context.dart';
import '../../../workspace/domain/models/project_layout.dart';

class DeploymentSpec extends Model {
  const DeploymentSpec(
    this.config,
    this.context,
    this.layout,
    this.processEnvironment,
  );
  final AppConfig config;
  final CoolifyContext context;
  final ProjectLayout layout;
  final Map<String, String> processEnvironment;
}
