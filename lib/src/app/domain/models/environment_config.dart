import 'package:grumpy_cli/grumpy_cli.dart';

import 'database_override.dart';
import 'environment_variables.dart';
import 'redis_config.dart';
import 'secret_reference.dart';

/// Desired application settings for one isolated deployment environment.
class EnvironmentConfig extends Model {
  const EnvironmentConfig({
    this.branch = 'main',
    this.resourceName,
    this.configMode,
    this.env = const {},
    this.secrets = const {},
    this.database = const DatabaseOverride(),
    this.redis,
  });

  /// Git branch Coolify deploys for this environment.
  final String branch;

  /// Coolify application resource name, preserving capitalization. Defaults to
  /// `<project>-<environment>-app`. Changes rename the existing managed application;
  /// project identity and PostgreSQL/Redis resource names are unchanged.
  final String? resourceName;

  /// Serverpod configuration mode. Defaults to production for the production
  /// environment and staging otherwise; the runtime mode remains production.
  final String? configMode;

  /// Runtime environment variables: literal strings or {fromEnv: VARIABLE}
  /// references read from the shell or .env. Tug-managed connection, port and
  /// credential settings cannot be overridden. Use secrets for Serverpod passwords.
  @ConfigField(
    valueType: environmentVariablesType,
    schema: environmentVariablesSchema,
  )
  final Map<String, Object> env;

  /// Serverpod password names mapped to local environment-variable references.
  /// Each value is sent as `SERVERPOD_PASSWORD_<name>`; keep secret values out of this file.
  final Map<String, SecretReference> secrets;

  /// Initial database name and user overrides for this environment.
  final DatabaseOverride database;

  /// Override the project Redis setting for this environment. When omitted,
  /// the project-level redis configuration applies.
  final RedisConfig? redis;
}
