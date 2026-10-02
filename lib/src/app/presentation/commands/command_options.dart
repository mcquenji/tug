import 'package:grumpy_cli/grumpy_cli.dart';

/// Shared argument handles used by feature command declarations.
abstract final class CommandOptions {
  static final version = CliFlag(
    'version',
    negatable: false,
    description: 'Print the version embedded at build time.',
  );
  static final envFile = CliFlag(
    'env-file',
    defaultValue: true,
    description:
        'Load .env from the project root; shell values take precedence.',
  );
  static final color = CliFlag(
    'color',
    defaultValue: true,
    description: 'Use terminal colors when supported.',
  );
  static final verbose = CliFlag(
    'verbose',
    negatable: false,
    description: 'Show detailed progress diagnostics.',
  );
  static final context = CliOption(
    'context',
    type: CliValueType.string(),
    description: 'Coolify context override.',
  );
  static final selectServer = CliFlag(
    'select-server',
    negatable: false,
    description: 'Choose the server and destination for this checkout again.',
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
