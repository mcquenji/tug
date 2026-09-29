import 'package:grumpy_cli/grumpy_cli.dart';

import 'database_override.dart';
import 'domain_config.dart';
import 'redis_config.dart';
import 'secret_reference.dart';

/// Desired application settings for one isolated deployment environment.
class EnvironmentConfig extends Model {
  const EnvironmentConfig({
    this.branch = 'main',
    this.domains = const DomainConfig(),
    this.configMode,
    this.env = const {},
    this.secrets = const {},
    this.database = const DatabaseOverride(),
    this.redis,
  });
  final String branch;
  final DomainConfig domains;
  final String? configMode;
  final Map<String, String> env;
  final Map<String, SecretReference> secrets;
  final DatabaseOverride database;
  final RedisConfig? redis;
}
