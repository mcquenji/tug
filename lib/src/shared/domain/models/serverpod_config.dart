import 'package:grumpy_cli/grumpy_cli.dart';

/// Paths to the Serverpod and Flutter packages within the repository.
class ServerpodConfig extends Model {
  const ServerpodConfig({
    this.server = '',
    this.flutter = '',
    this.migrations = true,
    this.flutterBaseHref = '/app/',
  });
  final String server;
  final String flutter;
  final bool migrations;

  /// URL prefix used by the application's FlutterRoute.
  final String flutterBaseHref;
}
