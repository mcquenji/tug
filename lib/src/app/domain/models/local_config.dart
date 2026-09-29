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
    this.context,
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

  /// Optional reference to a globally configured context.
  final String? context;
  final SourceConfig source;
  final ServerpodConfig? serverpod;
  final DatabaseConfig database;
  final RedisConfig redis;
  final Map<String, EnvironmentConfig> environments;
}
