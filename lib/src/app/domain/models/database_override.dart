import 'package:grumpy_cli/grumpy_cli.dart';

/// Per-environment initial database identity.
class DatabaseOverride extends Model {
  const DatabaseOverride({this.name, this.user});

  /// Initial PostgreSQL database name. Defaults to the project name with hyphens
  /// replaced by underscores; does not rename an existing database.
  final String? name;

  /// Initial PostgreSQL username. Defaults to the database name; does not rename
  /// an existing database user.
  final String? user;
}
