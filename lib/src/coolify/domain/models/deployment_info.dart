import 'package:grumpy_cli/grumpy_cli.dart';

/// Deployment state and a log tail that callers must redact before displaying.
class DeploymentInfo extends Model {
  const DeploymentInfo(this.uuid, this.status, this.logs);
  final String uuid, status, logs;
  bool get finished => status == 'finished' && !failed;
  bool get failed =>
      ['failed', 'cancelled-by-user', 'cancelled', 'error'].contains(status) ||
      RegExp(
        r'New container is (?:unhealthy|not healthy)|Rolling update failed|healthcheck failed',
        caseSensitive: false,
      ).hasMatch(logs);
}
