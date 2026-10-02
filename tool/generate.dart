import 'dart:convert';
import 'dart:io';

import 'package:yaml/yaml.dart';

/// Regenerate canonical schemas, documentation and the compiled offline copy.
Future<void> main(List<String> args) async {
  final check = args.contains('--check');
  const generated = [
    'lib/src/app/domain/models/app_config.g.dart',
    'schemas/v1/config.schema.json',
    'schemas/v1/coolify.schema.json',
    'schemas/v1/global.schema.json',
    'schemas/v1/local.schema.json',
    'lib/gen/schemas.g.dart',
    'docs/configuration.md',
    'lib/gen/version.g.dart',
  ];
  final before = {
    for (final name in generated)
      name: File(name).existsSync() ? File(name).readAsStringSync() : null,
  };
  Future<void> run(List<String> arguments) async {
    final process = await Process.start(
      'fvm',
      ['dart', ...arguments],
      mode: ProcessStartMode.inheritStdio,
      runInShell: Platform.isWindows,
    );
    final result = await process.exitCode;
    if (result != 0) {
      exitCode = result;
      throw StateError('Generation failed.');
    }
  }

  await run(['run', 'build_runner', 'build']);
  final pubspec = loadYaml(await File('pubspec.yaml').readAsString()) as Map;
  File('lib/gen/version.g.dart').writeAsStringSync(
    '// GENERATED CODE - DO NOT MODIFY BY HAND.\nconst String pubspecVersion = ${jsonEncode(pubspec['version']).replaceAll(r'$', r'\$')};\n',
  );
  final schema = File('schemas/v1/config.schema.json').readAsStringSync();
  final canonical = jsonDecode(schema) as Map<String, dynamic>;
  // Global connection profiles must never be suggested or accepted in the shared manifest.
  final local = (canonical[r'$defs'] as Map)['local'] as Map;
  for (final key in ['contexts', 'currentContext']) {
    (local['properties'] as Map).remove(key);
  }
  final docs = File('docs/configuration.md');
  final sections = docs.readAsStringSync().split('## Local');
  if (sections.length == 2) {
    final shared = sections[1]
        .split('\n')
        .where(
          (line) =>
              !line.startsWith('| `contexts`') &&
              !line.startsWith('| `currentContext`'),
        )
        .join('\n');
    docs.writeAsStringSync(
      '${sections[0].replaceFirst('Local values override global values. Declared defaults apply last.', 'Global connections are separate from the shared manifest. Per-checkout context selection, domains and connection overrides live in gitignored `.coolify/local.yaml`; see README.md.')}## Local$shared',
    );
  }
  File('schemas/v1/config.schema.json').writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(canonical)}\n',
  );
  for (final scope in ['coolify', 'global', 'local']) {
    final wrapper = {
      r'$schema': 'https://json-schema.org/draft/2020-12/schema',
      r'$id':
          'https://raw.githubusercontent.com/mcquenji/tug/main/schemas/v1/$scope.schema.json',
      r'$ref':
          'config.schema.json#/${r'$defs'}/${scope == 'global' ? 'global' : 'local'}',
    };
    File('schemas/v1/$scope.schema.json').writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(wrapper)}\n',
    );
  }
  final embedded = File('lib/gen/schemas.g.dart');
  embedded.parent.createSync(recursive: true);
  embedded.writeAsStringSync(
    '// GENERATED CODE - DO NOT MODIFY BY HAND.\nconst String configSchemaJson = ${jsonEncode(jsonEncode(canonical)).replaceAll(r'$', r'\$')};\n',
  );
  await run([
    'format',
    'lib/src/app/domain/models/app_config.g.dart',
    embedded.path,
    'lib/gen/version.g.dart',
  ]);
  if (check) {
    final stale = generated
        .where((name) => before[name] != File(name).readAsStringSync())
        .toList();
    if (stale.isNotEmpty) {
      stderr.writeln(
        'Stale generated artifacts: ${stale.join(', ')}. Run fvm dart run tool/generate.dart and commit the results.',
      );
      exitCode = 1;
    }
  }
}
