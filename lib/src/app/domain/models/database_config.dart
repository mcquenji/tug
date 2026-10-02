import 'package:grumpy_cli/grumpy_cli.dart';

/// PostgreSQL engine policy; existing databases are never upgraded automatically.
class DatabaseConfig extends Model {
  const DatabaseConfig({this.type = 'postgres', this.version = 18});

  /// Database engine. Currently only postgres is supported.
  final String type;

  /// PostgreSQL major version for new databases: 16, 17 or 18. Tug never
  /// automatically upgrades an existing database.
  final int version;
}
