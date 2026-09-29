import 'package:grumpy_cli/grumpy_cli.dart';

/// Shared argument handles used by feature command declarations.
abstract final class CommandOptions {
  static final context = CliOption(
    'context',
    type: CliValueType.string(),
    description: 'Coolify context override.',
  );
  static final environment = CliOption(
    'environment',
    type: CliValueType.string(),
    description: 'Select one environment.',
  );
  static final name = CliParameter(
    'name',
    type: CliValueType.string(),
    required: true,
  );
  static final url = CliOption('url', type: CliValueType.string());
  static final tokenEnv = CliOption(
    'token-env',
    type: CliValueType.string(),
    description: 'Name of an environment variable containing the token.',
  );
  static final server = CliOption('server', type: CliValueType.string());
  static final destination = CliOption(
    'destination',
    type: CliValueType.string(),
  );
  static final githubApp = CliOption('github-app', type: CliValueType.string());
  static final web = CliOption('web-domain', type: CliValueType.string());
  static final api = CliOption('api-domain', type: CliValueType.string());
  static final branch = CliOption('branch', type: CliValueType.string());
  static final configMode = CliOption(
    'config-mode',
    type: CliValueType.string(),
  );
  static final force = CliFlag(
    'force',
    negatable: false,
    description: 'Replace existing generated files after review.',
  );
  static final yes = CliFlag(
    'yes',
    negatable: false,
    description: 'Confirm destruction; never bypasses --destroy-data.',
  );
  static final destroyData = CliFlag(
    'destroy-data',
    negatable: false,
    description: 'Allow deletion of persistent databases and volumes.',
  );
  static final wait = CliFlag(
    'wait',
    defaultValue: true,
    description: 'Wait for the deployment to finish.',
  );
}
