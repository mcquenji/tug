import 'dart:io';

import 'package:grumpy_cli/grumpy_cli.dart';
import 'package:tug/src/app/app.dart';
import 'package:tug/src/app/infra/infra.dart';
import 'package:tug/src/coolify/coolify.dart';

/// Resolve the selected profile and configure its explicit credential destination.
CoolifyContext resolveCoolifyContext(CommandContext c, AppConfig config) {
  final selected =
      c.args.get(CommandOptions.context) ??
      config.context ??
      config.currentContext;
  final connection = config.contexts[selected];
  if (connection == null) {
    throw const TugException(
      'Select a configured context using --context, project context, or tug context use.',
    );
  }
  if (connection.token != null && connection.tokenEnv != null) {
    throw const TugException('A context must use token or tokenEnv, not both.');
  }
  final token = connection.tokenEnv == null
      ? connection.token
      : Platform.environment[connection.tokenEnv];
  if (token == null || token.isEmpty) {
    throw const TugException(
      'The selected context has no available API token. Use context add or set its token environment variable.',
    );
  }
  if (c.terminal is SafeTerminalService) {
    (c.terminal as SafeTerminalService).secrets.add(token);
  }
  CoolifyApiService().configure(connection, token);
  return connection;
}

/// Validate a context name before saving it in the global configuration.
String contextName(CommandContext context) =>
    validateContextName(context.args.require(CommandOptions.name));

String validateContextName(String name) {
  if (!RegExp(r'^[a-zA-Z][a-zA-Z0-9_-]*$').hasMatch(name)) {
    throw const TugException('Invalid context name.');
  }
  return name;
}

void reportContextSaved(CommandContext context) => context.terminal.writeln(
  'Saved global configuration: ${context.config.global.path}.',
);
