import 'package:grumpy_cli/grumpy_cli.dart';

/// Git source shared by all environments.
class SourceConfig extends Model {
  const SourceConfig({this.repository = 'auto'});
  final String repository;
}
