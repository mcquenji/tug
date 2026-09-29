import 'dart:convert';
import 'dart:io';

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
  ];
  final before = {
    for (final name in generated)
      name: File(name).existsSync() ? File(name).readAsStringSync() : null,
  };
  Future<void> run(List<String> arguments) async {
    final process = await Process.start('fvm', [
      'dart',
      ...arguments,
    ], mode: ProcessStartMode.inheritStdio);
    final result = await process.exitCode;
    if (result != 0) {
      exitCode = result;
      throw StateError('Generation failed.');
    }
  }

  await run(['run', 'build_runner', 'build']);
  final schema = File('schemas/v1/config.schema.json').readAsStringSync();
  final canonical = jsonDecode(schema) as Map<String, dynamic>;
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
