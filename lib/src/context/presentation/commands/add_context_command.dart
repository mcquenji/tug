import 'package:grumpy_cli/grumpy_cli.dart';
import 'package:tug/src/app/app.dart';
import 'package:tug/src/context/context.dart';
import 'package:tug/src/coolify/coolify.dart';

class AddContextCommand extends TugCommand {
  const AddContextCommand();
  @override
  ArgumentSchema get arguments => ArgumentSchema(
    arguments: [
      CommandOptions.name,
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
    final selected = contextName(c);
    final global = c.config.global;
    final contexts = {...?global.get(AppConfig.settings.contexts)};
    if (contexts.containsKey(selected) &&
        !c.args.require(CommandOptions.force)) {
      throw const TugException('Context exists; use --force to replace it.');
    }
    Future<String> setting(CliOption<String> option, String label) async =>
        c.args.get(option) ?? await c.prompts.text(label);
    final address = await setting(
      CommandOptions.url,
      'Coolify HTTPS URL (credential destination)',
    );
    final ref = c.args.get(CommandOptions.tokenEnv);
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
      server: await setting(CommandOptions.server, 'Server UUID'),
      destination: await setting(
        CommandOptions.destination,
        'Destination UUID',
      ),
      githubApp: await setting(CommandOptions.githubApp, 'GitHub App UUID'),
      domains: {
        if (c.args.wasProvided(CommandOptions.web) ||
            c.args.wasProvided(CommandOptions.api))
          'default': DomainConfig(
            web: c.args.get(CommandOptions.web) ?? 'auto',
            api: c.args.get(CommandOptions.api) ?? 'auto',
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
