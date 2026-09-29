import 'package:grumpy_cli/grumpy_cli.dart';

/// PostgreSQL engine policy; existing databases are never upgraded automatically.
class DatabaseConfig extends Model {
  const DatabaseConfig({this.type = 'postgres', this.version = 18});
  final String type;
  final int version;
}
