import 'package:grumpy_cli/grumpy_cli.dart';
import 'package:tug/src/app/app.dart';
import 'package:tug/src/workspace/workspace.dart';

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
