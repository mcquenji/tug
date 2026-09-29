import 'package:grumpy_cli/grumpy_cli.dart';

/// Connection parsed from Coolify's internal URL, never inferred from names.
class ConnectionInfo extends Model {
  const ConnectionInfo({
    required this.host,
    required this.port,
    required this.user,
    required this.password,
    required this.database,
  });
  final String host, user, password, database;
  final int port;
  @override
  String toString() => 'ConnectionInfo(redacted)';
}
