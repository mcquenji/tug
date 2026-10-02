import 'package:grumpy_cli/grumpy_cli.dart';

import 'database_config.dart';
import 'environment_config.dart';
import 'redis_config.dart';
import 'serverpod_config.dart';
import 'source_config.dart';

/// Project settings saved to coolify.yaml using Grumpy's default config service.
@localConfig
class LocalConfig extends Model {
  const LocalConfig({
    this.version = 1,
    this.name,
    this.source = const SourceConfig(),
    this.serverpod,
    this.database = const DatabaseConfig(),
    this.redis = const RedisConfig(),
    this.environments = const {},
  });

  /// Manifest format version.
  @ConfigField(choices: [1])
  final int version;

  /// Stable project name used to identify managed resources.
  final String? name;

  /// Git repository shared by all deployment environments.
  final SourceConfig source;

  /// Serverpod and Flutter package paths and build options. Omit to discover
  /// the packages automatically and use the default build options.
  final ServerpodConfig? serverpod;

  /// PostgreSQL engine and major version for newly created databases.
  final DatabaseConfig database;

  /// Default Redis setting for all environments; individual environments can override it.
  final RedisConfig redis;

  /// Named, isolated deployments with their own branches, databases and runtime settings.
  final Map<String, EnvironmentConfig> environments;
}
