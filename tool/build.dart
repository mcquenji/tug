import 'dart:io';

import 'package:yaml/yaml.dart';

/// Official build entry point: embeds the pubspec version in the executable.
Future<void> main(List<String> args) async {
  if (args.isNotEmpty) {
    stderr.writeln('Usage: fvm dart run tool/build.dart');
    exitCode = 64;
    return;
  }
  final root = File.fromUri(Platform.script).parent.parent;
  final pubspec =
      loadYaml(await File('${root.path}/pubspec.yaml').readAsString()) as Map;
  final version = pubspec['version'];
  if (version is! String || version.trim().isEmpty) {
    throw StateError('Missing pubspec version.');
  }
  await Directory('${root.path}/build').create(recursive: true);
  final process = await Process.start(
    'fvm',
    [
      'dart',
      'compile',
      'exe',
      '-DTUG_VERSION=$version',
      'bin/tug.dart',
      '-o',
      Platform.isWindows ? 'build/tug.exe' : 'build/tug',
    ],
    workingDirectory: root.path,
    runInShell: Platform.isWindows,
    mode: ProcessStartMode.inheritStdio,
  );
  exitCode = await process.exitCode;
}
