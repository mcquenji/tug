import 'package:grumpy_cli/grumpy_cli.dart';

/// A local process environment variable supplying a runtime value or password.
class SecretReference extends Model {
  const SecretReference({this.fromEnv = ''});

  /// Name of the variable supplying this runtime value. Read from the shell
  /// or .env unless --no-env-file is set; shell values take precedence. The value
  /// is never written to the shared manifest.
  final String fromEnv;
}
