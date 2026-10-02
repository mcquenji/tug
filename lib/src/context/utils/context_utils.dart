import 'package:grumpy_cli/grumpy_cli.dart';
import 'package:tug/src/app/app.dart';
import 'package:tug/src/app/infra/infra.dart';
import 'package:tug/src/coolify/coolify.dart';

/// Resolve the selected profile and configure its explicit credential destination.
Future<CoolifyContext> resolveCoolifyContext(
  CommandContext c,
  AppConfig config, {
  CoolifyApiService? api,
  CoolifyDatasource? remote,
  bool requireInfrastructure = true,
  bool requireDomains = true,
}) async {
  final settings = await DeploymentSettings.load(projectDirectory(c));
  final contexts = {...config.contexts, ...settings.contexts};
  var selected = c.args.get(CommandOptions.context) ?? settings.context;
  if (contexts.isEmpty) {
    selected ??= validateContextName(
      await c.prompts.text(
        'Name for this local Coolify context',
        defaultValue: 'local',
      ),
    );
    final url = await c.prompts.text(
      'Coolify HTTPS URL (saved in .coolify/local.yaml)',
    );
    final connection = CoolifyContext(url: url);
    contexts[selected] = connection;
    settings.values['contexts'] = AppConfig.settings.contexts.type.encode(
      contexts,
    );
  }
  selected ??= await c.prompts.select<String>(
    'Coolify context for this checkout',
    choices: [for (final name in contexts.keys) PromptChoice(name, name)],
    defaultValue: contexts.containsKey(config.currentContext)
        ? config.currentContext
        : null,
    allowDefaultNonInteractive: config.currentContext != null,
  );
  var connection = contexts[selected];
  if (connection == null) {
    throw const TugException(
      'Selected context does not exist. Choose a global context with --context or edit .coolify/local.yaml.',
    );
  }
  final reselectServer = c.args.require(CommandOptions.selectServer);
  final savedServer = settings.contexts[selected]?.server ?? '';
  final chooseServer = reselectServer || savedServer.isEmpty;
  if (connection.token != null && connection.tokenEnv != null) {
    throw const TugException('A context must use token or tokenEnv, not both.');
  }
  var token = connection.tokenEnv == null
      ? connection.token
      : (await commandEnvironment(c))[connection.tokenEnv];
  if (token == null || token.isEmpty) {
    token = await c.prompts.password(
      'API token for $selected (saved in .coolify/local.yaml)',
    );
    connection = CoolifyContext(
      url: connection.url,
      token: token,
      server: connection.server,
      destination: connection.destination,
      githubApp: connection.githubApp,
      domains: connection.domains,
    );
    settings.values['contexts'] = AppConfig.settings.contexts.type.encode({
      ...settings.contexts,
      selected: connection,
    });
  }
  if (c.terminal is SafeTerminalService) {
    (c.terminal as SafeTerminalService).secrets.add(token);
  }
  (api ?? CoolifyApiService()).configure(connection, token);
  Future<String> resource(
    String value,
    String label,
    CoolifyOperation operation, {
    String? parent,
    bool choose = false,
  }) async {
    if (!requireInfrastructure || value.isNotEmpty && !choose) return value;
    final options = await c.terminal.task(
      'Load available $label',
      () => (remote ?? CoolifyDatasource()).list(operation, uuid: parent),
    );
    if (options.isEmpty) {
      throw TugException(
        'No $label available in the selected Coolify context.',
      );
    }
    return c.prompts.select<String>(
      'Select $label',
      choices: [
        for (final r in options) PromptChoice('${r.name} (${r.uuid})', r.uuid),
      ],
      defaultValue: options.any((r) => r.uuid == value) ? value : null,
      allowDefaultNonInteractive: !reselectServer,
    );
  }

  final server = await resource(
    connection.server,
    'server',
    CoolifyOperation.servers,
    choose: chooseServer,
  );
  final destination = await resource(
    server == connection.server ? connection.destination : '',
    'destination',
    CoolifyOperation.destinations,
    parent: server,
    choose: chooseServer,
  );
  final githubApp = await resource(
    connection.githubApp,
    'GitHub App',
    CoolifyOperation.githubApps,
  );
  if (requireInfrastructure && chooseServer ||
      server != connection.server ||
      destination != connection.destination ||
      githubApp != connection.githubApp) {
    settings.values['contexts'] = AppConfig.settings.contexts.type.encode({
      ...settings.contexts,
      selected: CoolifyContext(
        url: connection.url,
        token: connection.token,
        tokenEnv: connection.tokenEnv,
        server: server,
        destination: destination,
        githubApp: githubApp,
        domains: connection.domains,
      ),
    });
  }
  final domains = {
    ...connection.domains,
    if (settings.context == null || settings.context == selected)
      ...settings.domains,
  };
  if (settings.context != null && settings.context != selected) {
    settings.values.remove('domains');
  }
  settings.context = selected;
  for (final name in requireDomains ? config.environments.keys : <String>[]) {
    final current = domains[name] ?? domains['default'] ?? const DomainConfig();
    Future<String> domain(String value, String kind) async {
      if (value.isNotEmpty && value != 'auto') return value;
      return c.prompts.text(
        '$name $kind public hostname',
        description:
            'For example $kind.example.com; saved only in .coolify/local.yaml.',
      );
    }

    final resolved = DomainConfig(
      web: await domain(current.web, 'web'),
      api: await domain(current.api, 'api'),
    );
    domains[name] = resolved;
    settings.setDomains(name, resolved);
  }
  await settings.save();
  if (requireInfrastructure) {
    c.terminal.writeln(
      'Deployment target: $selected (${connection.url}) · server $server · destination $destination',
    );
  }
  c.terminal.detail('Context $selected · ${connection.url}');
  return CoolifyContext(
    url: connection.url,
    token: connection.token,
    tokenEnv: connection.tokenEnv,
    server: server,
    destination: destination,
    githubApp: githubApp,
    domains: domains,
  );
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
