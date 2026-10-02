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

  /// HTTPS base URL of the Coolify instance, for example https://coolify.example.com.
  final String url;

  /// Coolify API token stored in this private profile. Use either token or tokenEnv.
  final String? token;

  /// Environment variable containing the Coolify API token. Read from the shell or
  /// .env unless --no-env-file is set; shell values take precedence. Use either
  /// tokenEnv or token.
  final String? tokenEnv;

  /// Coolify server UUID. When empty, deployment commands prompt for a server
  /// and save the choice in .coolify/local.yaml.
  final String server;

  /// Coolify destination UUID on the selected server. When empty, deployment
  /// commands prompt for a destination and save it in .coolify/local.yaml.
  final String destination;

  /// Coolify GitHub App identifier used to access the repository. When empty,
  /// deployment commands prompt for an App and save it in .coolify/local.yaml.
  final String githubApp;

  /// Public web/API hostname templates keyed by environment name. The default
  /// entry supplies a fallback; .coolify/local.yaml overrides these per checkout.
  final Map<String, DomainConfig> domains;
  @override
  String toString() => 'CoolifyContext(redacted)';
}
