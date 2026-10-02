import 'package:grumpy_cli/grumpy_cli.dart';

/// Public origins, or templates containing {name} and {environment}.
class DomainConfig extends Model {
  const DomainConfig({this.web = 'auto', this.api = 'auto'});

  /// Public web hostname or HTTPS origin without a port or path. Supports {app},
  /// {name}, {environment} and {env} placeholders. auto prompts for a hostname
  /// and saves it in .coolify/local.yaml.
  final String web;

  /// Public API hostname or HTTPS origin without a port or path. Supports {app},
  /// {name}, {environment} and {env} placeholders. auto prompts for a hostname
  /// and saves it in .coolify/local.yaml.
  final String api;
}
