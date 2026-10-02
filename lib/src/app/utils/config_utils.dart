import 'dart:io';

import 'package:grumpy_cli/grumpy_cli.dart';
import 'package:path/path.dart' as p;
import 'package:tug/src/app/domain/domain.dart';
import 'package:tug/src/app/infra/infra.dart';
import 'package:yaml/yaml.dart';

import 'schema_utils.dart';
import 'security_utils.dart';

/// Project directory selected by Grumpy's default local configuration scope.
String projectDirectory(CommandContext context) =>
    p.dirname(context.config.local.path);

/// Validate both scopes against embedded schemas before a command can mutate.
Future<void> validateConfiguration(CommandContext context) async {
  for (final entry in {
    'global': context.config.global,
    'local': context.config.local,
  }.entries) {
    final file = File(entry.value.path);
    if (await file.exists()) {
      validateOffline(loadYaml(await file.readAsString()), scope: entry.key);
    }
  }
}

/// Warn once per inline secret in the shared manifest.
void warnLocalSensitiveValues(CommandContext c) {
  final scope = c.config.local;
  final seen = <String>{};
  void warn(String field) {
    if (seen.add(field)) {
      c.terminal.errorln(
        'Warning: ${scope.path}: $field stores a sensitive value locally. Prefer a global token or an environment-variable reference.',
      );
    }
  }

  for (final entry
      in (scope.get(AppConfig.settings.environments) ??
              <String, EnvironmentConfig>{})
          .entries) {
    for (final variable in entry.value.env.entries) {
      if (sensitiveName(variable.key)) {
        warn('environments.${entry.key}.env.${variable.key}');
        if (c.terminal is SafeTerminalService) {
          (c.terminal as SafeTerminalService).secrets.add(variable.value);
        }
      }
    }
  }
}
