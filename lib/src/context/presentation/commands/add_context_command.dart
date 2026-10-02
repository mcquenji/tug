import 'package:grumpy_cli/grumpy_cli.dart';
import 'package:tug/src/app/app.dart';
import 'package:tug/src/context/context.dart';
import 'package:tug/src/coolify/coolify.dart';

class AddContextCommand extends TugCommand {
  const AddContextCommand();

  static final _name = CliParameter('name', type: CliValueType.string());

  @override
  ArgumentSchema get arguments => ArgumentSchema(
    arguments: [
      _name,
      CommandOptions.url,
      CommandOptions.tokenEnv,
      CommandOptions.server,
      CommandOptions.destination,
      CommandOptions.githubApp,
      CommandOptions.web,
      CommandOptions.api,
      CommandOptions.force,
    ],
  );
  @override
  Future<void> run(CommandContext c, AppConfig config) async {
    final selected = validateContextName(
      c.args.get(_name) ?? await c.prompts.text('Context name'),
    );
    final global = c.config.global;
    final contexts = {...?global.get(AppConfig.settings.contexts)};
    if (contexts.containsKey(selected) &&
        !c.args.require(CommandOptions.force)) {
      throw const TugException('Context exists; use --force to replace it.');
    }
    Future<String> setting(
      CliOption<String> option,
      String label, {
      String? defaultValue,
    }) async =>
        c.args.get(option) ??
        await c.prompts.text(
          label,
          defaultValue: defaultValue,
          allowDefaultNonInteractive: defaultValue != null,
        );
    final address = await setting(
      CommandOptions.url,
      'Coolify HTTPS URL (credential destination)',
    );
    final tokenEnv = await setting(
      CommandOptions.tokenEnv,
      'Token environment variable (leave blank to save an API token)',
      defaultValue: '',
    );
    final ref = tokenEnv.isEmpty ? null : tokenEnv;
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
      server: await setting(
        CommandOptions.server,
        'Default server UUID (leave blank to select per checkout)',
        defaultValue: '',
      ),
      destination: await setting(
        CommandOptions.destination,
        'Default destination UUID (leave blank to select per checkout)',
        defaultValue: '',
      ),
      githubApp: await setting(CommandOptions.githubApp, 'GitHub App UUID'),
      domains: {
        'default': DomainConfig(
          web: await setting(
            CommandOptions.web,
            'Web domain',
            defaultValue: 'auto',
          ),
          api: await setting(
            CommandOptions.api,
            'API domain',
            defaultValue: 'auto',
          ),
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

    reportContextSaved(c);
  }
}
