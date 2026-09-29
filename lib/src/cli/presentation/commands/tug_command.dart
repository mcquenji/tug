import 'dart:io';

import 'package:yaml/yaml.dart';

import '../../../shared/utils/schema_validation.dart';

import 'package:grumpy_cli/grumpy_cli.dart';
import 'package:path/path.dart' as p;

import '../../../shared/domain/models/app_config.g.dart';
import '../../../shared/domain/models/coolify_context.dart';
import '../../../shared/domain/models/domain_config.dart';
import '../../../shared/domain/models/environment_config.dart';
import '../../../shared/domain/models/serverpod_config.dart';
import '../../../shared/domain/models/source_config.dart';
import '../../../shared/domain/models/tug_exception.dart';
import '../../../shared/utils/security.dart';
import '../../../coolify/domain/services/coolify_api_service.dart';
import '../../../workspace/domain/services/workspace_service.dart';
import '../../../reconcile/domain/models/deployment_spec.dart';
import '../../../reconcile/domain/services/reconcile_service.dart';
import '../../infra/services/safe_terminal_service.dart';

class TugCommand extends CliCommand {
  const TugCommand(this.action);
  final String action;
  static final contextOption = CliOption(
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
  static const descriptions = {
    'init': 'Detect a Serverpod 4 monorepo and create local deployment files.',
    'generate': 'Generate a pinned Dockerfile and secret exclusions.',
    'doctor': 'Validate local layout, runtime import and remote prerequisites.',
    'plan': 'Read-only comparison with Coolify.',
    'apply': 'Reconcile resources and deploy changes.',
    'status': 'Show verified resource and deployment status.',
    'logs': 'Show sanitized application logs.',
    'destroy': 'Destroy managed resources with persistent-data guards.',
    'context add': 'Save a Coolify context globally (credentials never accepted as arguments).',
    'context list': 'List contexts without token values.',
    'context use': 'Select the global default context.',
    'context remove': 'Remove a global context.',
    'environment add': 'Add a named local environment.',
    'environment destroy':
        'Destroy one managed environment, including orphaned environments.',
    'config sync': 'Explicitly refresh imported runtime variables in an existing environment.',
  };
  @override
  ArgumentSchema get arguments => ArgumentSchema(
    arguments: [
      if ([
        'context add',
        'context use',
        'context remove',
        'environment add',
        'environment destroy',
      ].contains(action))
        name,
      if (action == 'context add') ...[
        url,
        tokenEnv,
        server,
        destination,
        githubApp,
        web,
        api,
        force,
      ],
      if (['init', 'environment add'].contains(action)) ...[
        web,
        api,
        branch,
        configMode,
      ],
      if (['init', 'generate'].contains(action)) force,
      if ([
        'doctor',
        'plan',
        'apply',
        'status',
        'logs',
        'config sync',
      ].contains(action))
        environment,
      if (['apply', 'config sync'].contains(action)) wait,
      if (['destroy', 'environment destroy'].contains(action)) ...[
        destroyData,
        yes,
      ],
    ],
  );

  void _localWarnings(CommandContext c) {
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
        in (scope.get(AppConfig.settings.contexts) ??
                <String, CoolifyContext>{})
            .entries) {
      final url = Uri.tryParse(entry.value.url);
      if (url != null &&
          (url.userInfo.isNotEmpty || url.hasQuery || url.hasFragment)) {
        warn('contexts.${entry.key}.url');
      }
      if (entry.value.token?.isNotEmpty ?? false) {
        warn('contexts.${entry.key}.token');
      }
      if (c.terminal is SafeTerminalService && entry.value.token != null) {
        (c.terminal as SafeTerminalService).secrets.add(entry.value.token!);
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

  CoolifyContext _context(CommandContext c, AppConfig config) {
    final selected =
        c.args.get(contextOption) ?? config.context ?? config.currentContext;
    final connection = config.contexts[selected];
    if (connection == null) {
      throw const TugException(
        'Select a configured context using --context, project context, or tug context use.',
      );
    }
    if (connection.token != null && connection.tokenEnv != null) {
      throw const TugException(
        'A context must use token or tokenEnv, not both.',
      );
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

  @override
  Future<CommandResult> execute(CommandContext c) async {
    for (final entry in {
      'global': c.config.global,
      'local': c.config.local,
    }.entries) {
      final file = File(entry.value.path);
      if (await file.exists()) {
        validateOffline(loadYaml(await file.readAsString()), scope: entry.key);
      }
    }
    _localWarnings(c);
    final config = AppConfig();
    if (action.startsWith('context ')) {
      await _contextCommand(c, config);
      return CommandResult.success;
    }
    final directory = p.dirname(c.config.local.path);
    final workspace = WorkspaceService();
    final layout = await workspace.inspect(directory, config);
    if (action == 'init') {
      if (await File(c.config.local.path).exists() && !c.args.require(force)) {
        throw const TugException(
          'coolify.yaml already exists. Review it before using init --force.',
        );
      }
      final env = EnvironmentConfig(
        branch: c.args.get(branch) ?? layout.branch,
        domains: DomainConfig(
          web: c.args.get(web) ?? 'auto',
          api: c.args.get(api) ?? 'auto',
        ),
        configMode: c.args.get(configMode),
      );
      await workspace.generate(layout, replace: c.args.require(force));
      await c.config.local.update((edit) {
        edit.set(AppConfig.settings.name, layout.name);
        edit.set(
          AppConfig.settings.source,
          SourceConfig(repository: layout.repository),
        );
        edit.set(
          AppConfig.settings.serverpod,
          ServerpodConfig(server: layout.server, flutter: layout.flutter),
        );
        edit.set(AppConfig.settings.environments, {'production': env});
        if (c.args.wasProvided(contextOption)) {
          edit.set(AppConfig.settings.context, c.args.require(contextOption));
        }
      });
      c.terminal.writeln(
        'Created coolify.yaml and .coolify build files. Review and commit the generated deployment files and dependency locks. Runtime YAML and passwords are never staged or committed by Tug.',
      );
      return CommandResult.success;
    }
    if (action == 'generate') {
      await workspace.generate(layout, replace: c.args.require(force));
      c.terminal.writeln('Generated deployment files. Review and commit them.');
      return CommandResult.success;
    }
    if (action == 'environment add') {
      final selected = c.args.require(name);
      if (!RegExp(r'^[a-z][a-z0-9-]{0,47}$').hasMatch(selected)) {
        throw const TugException(
          'Use a lowercase environment name with letters, digits or hyphens.',
        );
      }
      if (config.environments.containsKey(selected)) {
        throw const TugException('Environment already exists.');
      }
      await c.config.local.set(AppConfig.settings.environments, {
        ...config.environments,
        selected: EnvironmentConfig(
          branch: c.args.get(branch) ?? layout.branch,
          configMode: c.args.get(configMode),
          domains: DomainConfig(
            web: c.args.get(web) ?? 'auto',
            api: c.args.get(api) ?? 'auto',
          ),
        ),
      });
      c.terminal.writeln('Added $selected to coolify.yaml.');
      return CommandResult.success;
    }
    final connection = _context(c, config);
    final spec = DeploymentSpec(
      config,
      connection,
      layout,
      Platform.environment,
    );
    final engine = ReconcileService();
    final selected = ['destroy', 'environment destroy'].contains(action)
        ? null
        : c.args.get(environment);
    switch (action) {
      case 'doctor':
      case 'plan':
        await engine.apply(spec, environment: selected, plan: true);
        if (action == 'doctor') {
          c.terminal.writeln(
            'Checks passed. DNS and public HTTPS are verified after deployment; Tug never changes DNS.',
          );
        }
      case 'apply':
        await engine.apply(
          spec,
          environment: selected,
          wait: c.args.require(wait),
        );
      case 'config sync':
        if (selected == null) {
          throw const TugException('config sync requires --environment.');
        }
        await engine.apply(
          spec,
          environment: selected,
          sync: true,
          wait: c.args.require(wait),
        );
      case 'status':
      case 'logs':
        await engine.status(
          spec,
          environment: selected,
          logs: action == 'logs',
        );
      case 'destroy':
      case 'environment destroy':
        await engine.destroyDeployment(
          spec,
          environment: action == 'destroy' ? null : c.args.require(name),
          destroyData: c.args.require(destroyData),
          confirm: () async =>
              c.args.require(yes) ||
              await c.prompts.confirm(
                'Destroy the listed resources?',
                defaultValue: false,
              ),
        );
      default:
        throw const TugException('Unsupported command.');
    }
    return CommandResult.success;
  }

  Future<void> _contextCommand(CommandContext c, AppConfig config) async {
    final global = c.config.global;
    final contexts = {...?global.get(AppConfig.settings.contexts)};
    if (action == 'context list') {
      for (final entry in config.contexts.entries) {
        c.terminal.writeln(
          '${entry.key}${entry.key == config.currentContext ? ' (current)' : ''}: ${Uri.tryParse(entry.value.url)?.hasAuthority == true ? Uri.parse(entry.value.url).replace(userInfo: '', path: '', query: '', fragment: '').toString() : '(invalid URL)'}',
        );
      }
      return;
    }
    final selected = c.args.require(name);
    if (!RegExp(r'^[a-zA-Z][a-zA-Z0-9_-]*$').hasMatch(selected)) {
      throw const TugException('Invalid context name.');
    }
    if (action == 'context use') {
      if (!contexts.containsKey(selected)) {
        throw const TugException('No such global context.');
      }
      await global.set(AppConfig.settings.currentContext, selected);
    } else if (action == 'context remove') {
      contexts.remove(selected);
      await global.update((edit) {
        edit.set(AppConfig.settings.contexts, contexts);
        if (global.get(AppConfig.settings.currentContext) == selected) {
          edit.remove(AppConfig.settings.currentContext);
        }
      });
    } else {
      if (contexts.containsKey(selected) && !c.args.require(force)) {
        throw const TugException('Context exists; use --force to replace it.');
      }
      Future<String> setting(CliOption<String> option, String label) async =>
          c.args.get(option) ?? await c.prompts.text(label);
      final address = await setting(
        url,
        'Coolify HTTPS URL (credential destination)',
      );
      final ref = c.args.get(tokenEnv);
      if (ref != null && !RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$').hasMatch(ref)) {
        throw const TugException('Invalid token environment variable name.');
      }
      final secret = ref == null
          ? await c.prompts.password('API token (saved in global config)')
          : null;
      final connection = CoolifyContext(
        url: address,
        token: secret,
        tokenEnv: ref,
        server: await setting(server, 'Server UUID'),
        destination: await setting(destination, 'Destination UUID'),
        githubApp: await setting(githubApp, 'GitHub App UUID'),
        domains: {
          if (c.args.wasProvided(web) || c.args.wasProvided(api))
            'default': DomainConfig(
              web: c.args.get(web) ?? 'auto',
              api: c.args.get(api) ?? 'auto',
            ),
        },
      );
      // Validate the destination without issuing any network request.
      CoolifyApiService().configure(connection, secret ?? 'validation-only');
      contexts[selected] = connection;
      await global.update((edit) {
        edit.set(AppConfig.settings.contexts, contexts);
        if (global.get(AppConfig.settings.currentContext) == null) {
          edit.set(AppConfig.settings.currentContext, selected);
        }
      });
    }
    c.terminal.writeln('Saved global configuration: ${global.path}.');
  }
}
