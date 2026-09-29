import 'package:grumpy_cli/grumpy_cli.dart';

/// Per-environment initial database identity.
class DatabaseOverride extends Model {
  const DatabaseOverride({this.name, this.user});
  final String? name;
  final String? user;
}
