import 'package:grumpy_cli/grumpy_cli.dart';

/// Optional private Redis resource.
class RedisConfig extends Model {
  const RedisConfig({this.enabled = false});
  final bool enabled;
}
