import 'package:grumpy_cli/grumpy_cli.dart';
import 'package:tug/src/app/app.dart';

class ListContextsCommand extends TugCommand {
  const ListContextsCommand();
  @override
  ArgumentSchema get arguments => ArgumentSchema(arguments: []);
  @override
  Future<void> run(CommandContext c, AppConfig config) async {
    for (final entry in config.contexts.entries) {
      final uri = Uri.tryParse(entry.value.url);
      final address = uri?.hasAuthority == true
          ? Uri(
              scheme: uri!.scheme,
              host: uri.host,
              port: uri.hasPort ? uri.port : null,
            ).toString()
          : '(invalid URL)';
      c.terminal.writeln(
        '${entry.key}${entry.key == config.currentContext ? ' (current)' : ''}: $address',
      );
    }
  }
}
