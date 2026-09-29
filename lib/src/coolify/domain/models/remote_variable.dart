import 'package:grumpy_cli/grumpy_cli.dart';

/// Runtime variable with private value and normalized Coolify flags.
class RemoteVariable extends Model {
  const RemoteVariable({
    required this.uuid,
    required this.key,
    required this.value,
    this.runtime = true,
    this.buildtime = false,
    this.literal = true,
  });
  final String uuid, key;
  final String? value;
  final bool runtime, buildtime, literal;
  @override
  String toString() => 'RemoteVariable($key, redacted)';
}
