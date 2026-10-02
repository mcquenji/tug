import 'package:grumpy_cli/grumpy_cli.dart';

/// Optional private Redis resource.
class RedisConfig extends Model {
  const RedisConfig({this.enabled = false});

  /// Create and manage a private Redis instance for each enabled environment.
  final bool enabled;
}
