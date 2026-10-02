import 'package:grumpy_cli/grumpy_cli.dart';

/// Paths to the Serverpod and Flutter packages within the repository.
class ServerpodConfig extends Model {
  const ServerpodConfig({
    this.server = '',
    this.flutter = '',
    this.migrations = true,
    this.flutterBaseHref = '/app/',
  });

  /// Path to the Serverpod server package, relative to the repository root.
  /// An empty path enables automatic package discovery.
  final String server;

  /// Path to the Flutter web package, relative to the repository root.
  /// An empty path enables automatic package discovery.
  final String flutter;

  /// Apply Serverpod database migrations when the deployed application starts.
  final bool migrations;

  /// URL prefix used by the application's FlutterRoute.
  final String flutterBaseHref;
}
