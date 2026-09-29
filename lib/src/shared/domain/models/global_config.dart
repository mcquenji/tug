import 'package:grumpy_cli/grumpy_cli.dart';

import 'coolify_context.dart';

/// Defaults saved globally by Tug; local overrides follow Grumpy semantics.
@config
class GlobalConfig extends Model {
  const GlobalConfig({this.currentContext, this.contexts = const {}});

  /// Default connection profile when no project or command selects one.
  final String? currentContext;

  /// Named Coolify connections. Tokens are sensitive, including local overrides.
  final Map<String, CoolifyContext> contexts;
}
