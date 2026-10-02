import 'package:grumpy_cli/grumpy_cli.dart';

import 'coolify_context.dart';

/// Connection profiles saved globally by Tug.
@config
class GlobalConfig extends Model {
  const GlobalConfig({this.currentContext, this.contexts = const {}});

  /// Default connection profile when no project or command selects one.
  final String? currentContext;

  /// Named global Coolify connections; keep credentials out of the shared manifest.
  final Map<String, CoolifyContext> contexts;
}
