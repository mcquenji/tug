import 'package:grumpy_cli/grumpy_cli.dart';

import 'domain_config.dart';

/// Machine-level connection settings. Token values must never be displayed.
class CoolifyContext extends Model {
  const CoolifyContext({
    this.url = '',
    this.token,
    this.tokenEnv,
    this.server = '',
    this.destination = '',
    this.githubApp = '',
    this.domains = const {},
  });
  final String url;
  final String? token;
  final String? tokenEnv;
  final String server;
  final String destination;
  final String githubApp;
  final Map<String, DomainConfig> domains;
  @override
  String toString() => 'CoolifyContext(redacted)';
}
