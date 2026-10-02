import 'package:grumpy_cli/grumpy_cli.dart';

/// Git source shared by all environments.
class SourceConfig extends Model {
  const SourceConfig({this.repository = 'auto'});

  /// GitHub repository URL shared by all environments. auto reads the origin
  /// Git remote; an explicit URL must identify the same repository as origin.
  final String repository;
}
