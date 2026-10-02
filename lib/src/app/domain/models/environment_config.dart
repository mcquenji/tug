import 'package:grumpy_cli/grumpy_cli.dart';

import 'database_override.dart';
import 'redis_config.dart';
import 'secret_reference.dart';

/// Desired application settings for one isolated deployment environment.
class EnvironmentConfig extends Model {
  const EnvironmentConfig({
    this.branch = 'main',
    this.configMode,
    this.env = const {},
    this.secrets = const {},
    this.database = const DatabaseOverride(),
    this.redis,
  });

  /// Git branch Coolify deploys for this environment.
  final String branch;

  /// Serverpod configuration mode. Defaults to production for the production
  /// environment and staging otherwise; the runtime mode remains production.
  final String? configMode;

  /// Literal non-secret runtime environment variables. Tug-managed connection,
  /// port and credential settings cannot be overridden here. Use secrets for passwords.
  final Map<String, String> env;

  /// Serverpod password names mapped to local environment-variable references.
  /// Each value is sent as `SERVERPOD_PASSWORD_<name>`; keep secret values out of this file.
  final Map<String, SecretReference> secrets;

  /// Initial database name and user overrides for this environment.
  final DatabaseOverride database;

  /// Override the project Redis setting for this environment. When omitted,
  /// the project-level redis configuration applies.
  final RedisConfig? redis;
}
