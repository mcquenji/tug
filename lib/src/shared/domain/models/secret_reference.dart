import 'package:grumpy_cli/grumpy_cli.dart';

/// A local process environment variable supplying an application password.
class SecretReference extends Model {
  const SecretReference({this.fromEnv = ''});
  final String fromEnv;
}
