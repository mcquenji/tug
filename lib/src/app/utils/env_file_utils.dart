import 'dart:io';

import 'package:grumpy_cli/grumpy_cli.dart';
import 'package:path/path.dart' as p;

import '../app.dart';
import '../infra/infra.dart';

final _environments = Expando<Map<String, String>>();

/// Load local references without changing the process environment or uploading it.
Future<Map<String, String>> commandEnvironment(CommandContext c) async {
  final cached = _environments[c];
  if (cached != null) return cached;
  final values = await loadEnvironment(
    projectDirectory(c),
    enabled: c.args.get(CommandOptions.envFile) ?? true,
  );
  if (c.terminal case SafeTerminalService terminal) {
    terminal.secrets.addAll(
      values.entries.where((e) => sensitiveName(e.key)).map((e) => e.value),
    );
  }
  return _environments[c] = values;
}

Future<Map<String, String>> loadEnvironment(
  String root, {
  bool enabled = true,
  Map<String, String>? processEnvironment,
}) async {
  final file = File(p.join(root, '.env'));
  return {
    if (enabled && await file.exists())
      ...parseEnvFile(await file.readAsString()),
    ...processEnvironment ?? Platform.environment,
  };
}

/// Supports export, comments, empty values and quoted/multiline values.
/// Dollar signs stay literal: dotenv files are data, never shell scripts.
Map<String, String> parseEnvFile(String content) {
  final values = <String, String>{};
  final lines = content.replaceFirst('\uFEFF', '').split(RegExp(r'\r?\n'));
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i].trim();
    if (line.isEmpty || line.startsWith('#')) continue;
    final start = i + 1;
    Never invalid() => throw TugException(
      'Invalid .env entry at line $start (contents hidden).',
    );
    final match = RegExp(r'^(?:export\s+)?([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)$')
        .firstMatch(line);
    if (match == null) invalid();
    var value = match.group(2)!;
    if (value.startsWith('"') || value.startsWith("'")) {
      final quote = value[0];
      final buffer = StringBuffer();
      var cursor = 1;
      while (true) {
        if (cursor == value.length) {
          if (++i >= lines.length) invalid();
          buffer.writeln();
          value = lines[i];
          cursor = 0;
          continue;
        }
        final char = value[cursor++];
        if (char == quote) {
          final rest = value.substring(cursor).trim();
          if (rest.isNotEmpty && !rest.startsWith('#')) invalid();
          break;
        }
        if (quote == '"' && char == r'\' && cursor < value.length) {
          final escaped = value[cursor++];
          buffer.write(switch (escaped) {
            'n' => '\n',
            'r' => '\r',
            't' => '\t',
            '"' => '"',
            r'\' => r'\',
            _ => '\\$escaped',
          });
        } else {
          buffer.write(char);
        }
      }
      value = buffer.toString();
    } else {
      value = value.replaceFirst(RegExp(r'\s+#.*$'), '').trimRight();
      if (value.startsWith('#')) value = '';
    }
    values[match.group(1)!] = value;
  }
  return values;
}
