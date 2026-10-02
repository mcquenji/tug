import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:tug/src/app/app.dart';
import 'package:tug/src/workspace/domain/domain.dart';
import 'package:yaml/yaml.dart';

class NativeWorkspaceService extends WorkspaceService {
  NativeWorkspaceService() : super.internal();
  Future<String> _git(String directory, List<String> args) async {
    final result = await Process.run('git', ['-C', directory, ...args]);
    if (result.exitCode != 0) {
      throw const TugException(
        'Cannot inspect Git repository. Configure origin and use a named branch.',
      );
    }
    return (result.stdout as String).trim();
  }

  Future<Map> _yaml(String file) async {
    try {
      final v = loadYaml(await File(file).readAsString());
      if (v is Map) return v;
    } catch (_) {}
    throw TugException('Cannot parse $file (contents redacted).');
  }

  @override
  Future<ProjectLayout> inspect(String directory, AppConfig config) async {
    final root = await _git(directory, ['rev-parse', '--show-toplevel']);
    if (!p.equals(p.normalize(directory), p.normalize(root))) {
      throw const TugException(
        'Place coolify.yaml at the Git repository root. Split repositories are unsupported.',
      );
    }
    final origin = normalizeRepository(
      await _git(root, ['remote', 'get-url', 'origin']),
    );
    final repository = config.source.repository == 'auto'
        ? origin
        : normalizeRepository(config.source.repository);
    if (repository.toLowerCase() != origin.toLowerCase()) {
      throw const TugException(
        'Manifest repository differs from Git origin. Refusing a repository identity change.',
      );
    }
    final branch = await _git(root, ['branch', '--show-current']);
    if (branch.isEmpty) {
      throw const TugException('Detached Git HEAD; select a named branch.');
    }
    final servers = <String>[], flutters = <String>[];
    Future<void> scan(Directory dir, int depth) async {
      final file = File(p.join(dir.path, 'pubspec.yaml'));
      if (await file.exists()) {
        final yaml = await _yaml(file.path);
        final deps = yaml['dependencies'];
        if (deps is Map && deps.containsKey('serverpod')) {
          servers.add(p.relative(dir.path, from: root));
        }
        if (deps is Map && deps.containsKey('flutter')) {
          flutters.add(p.relative(dir.path, from: root));
        }
      }
      if (depth == 0) return;
      await for (final entity in dir.list(followLinks: false)) {
        if (entity is Directory &&
            !p.basename(entity.path).startsWith('.') &&
            !['build', 'node_modules'].contains(p.basename(entity.path))) {
          await scan(entity, depth - 1);
        }
      }
    }

    await scan(Directory(root), 3);
    String select(String? explicit, List<String> detected, String label) {
      if (explicit != null && explicit.isNotEmpty) {
        if (!detected.contains(explicit)) {
          throw TugException(
            '$label package does not exist inside this repository.',
          );
        }
        return explicit;
      }
      if (detected.length != 1) {
        throw TugException(
          'Expected one $label package in a Serverpod 4 monorepo; found ${detected.length}. Specify serverpod.$label or migrate the layout.',
        );
      }
      return detected.single;
    }

    final server = select(config.serverpod?.server, servers, 'server');
    final flutter = select(config.serverpod?.flutter, flutters, 'flutter');
    for (final path in [server, flutter]) {
      if (!RegExp(r'^[A-Za-z0-9_./-]+$').hasMatch(path) ||
          path.split('/').contains('..')) {
        throw const TugException(
          'Package paths must be relative, without traversal or shell characters.',
        );
      }
      final resolved = await Directory(p.join(root, path))
          .resolveSymbolicLinks();
      if (!p.isWithin(root, resolved) && resolved != root) {
        throw const TugException('Packages must remain inside the repository.');
      }
    }
    final pubspec = await _yaml(p.join(root, server, 'pubspec.yaml'));
    final constraint = '${(pubspec['dependencies'] as Map)['serverpod']}';
    if (!RegExp(r'^[\^~]?4\.').hasMatch(constraint)) {
      throw const TugException(
        'Tug requires Serverpod 4.x. Serverpod 3 and split EduPlanner repositories are unsupported.',
      );
    }
    final rootPubspec = File(p.join(root, 'pubspec.yaml'));
    final workspace =
        await rootPubspec.exists() &&
        (await _yaml(rootPubspec.path))['workspace'] is List;
    for (final package in workspace ? ['.'] : [server, flutter]) {
      final lock = File(p.join(root, package, 'pubspec.lock'));
      if (!await lock.exists()) {
        throw TugException(
          'Missing ${p.relative(lock.path, from: root)}. Resolve and commit dependency locks for reproducible builds.',
        );
      }
    }
    final lock = await _yaml(
      p.join(root, workspace ? '.' : server, 'pubspec.lock'),
    );
    final locked = (lock['packages'] as Map?)?['serverpod'];
    if (locked is! Map || !'${locked['version']}'.startsWith('4.')) {
      throw const TugException('The lockfile must resolve Serverpod 4.x.');
    }
    if (!await File(p.join(root, server, 'lib/src/generated/protocol.yaml'))
        .exists()) {
      throw const TugException(
        'Generate Serverpod protocol resources before deploying.',
      );
    }
    if (!await File(p.join(root, server, 'bin/main.dart')).exists()) {
      throw const TugException('Server package must provide bin/main.dart.');
    }
    return ProjectLayout(
      root: root,
      server: server,
      flutter: flutter,
      repository: repository,
      branch: branch,
      name: '${pubspec['name']}'
          .replaceFirst(RegExp(r'_server$'), '')
          .replaceAll('_', '-'),
      workspace: workspace,
      flutterBaseHref: config.serverpod?.flutterBaseHref ?? '/app/',
    );
  }

  @override
  Future<void> generate(
    ProjectLayout layout, {
    bool replace = false,
    bool check = false,
  }) async {
    final toolchain = File(p.join(layout.root, '.coolify/toolchains.json'));
    Map versions;
    if (await toolchain.exists()) {
      try {
        versions = jsonDecode(await toolchain.readAsString()) as Map;
      } catch (_) {
        throw const TugException('Invalid .coolify/toolchains.json.');
      }
    } else {
      if (check) {
        throw const TugException(
          'Run tug generate and commit the generated deployment files.',
        );
      }
      final result = await Process.run('fvm', [
        'flutter',
        '--version',
        '--machine',
      ], workingDirectory: layout.root);
      if (result.exitCode != 0) {
        throw const TugException(
          'Cannot resolve Flutter toolchain using fvm flutter.',
        );
      }
      final info = jsonDecode(result.stdout as String) as Map;
      versions = {
        'flutter': info['frameworkVersion'],
        'flutterRevision': info['frameworkRevision'],
        'dart': '${info['dartSdkVersion']}'.split(' ').first,
      };
    }
    if (versions['flutterRevision'] == null && !check) {
      final result = await Process.run('fvm', [
        'flutter',
        '--version',
        '--machine',
      ], workingDirectory: layout.root);
      if (result.exitCode != 0) {
        throw const TugException('Cannot resolve Flutter revision using FVM.');
      }
      final info = jsonDecode(result.stdout as String) as Map;
      if (info['frameworkVersion'] != versions['flutter']) {
        throw const TugException(
          'Select the pinned Flutter version in FVM before regenerating toolchains.',
        );
      }
      versions['flutterRevision'] = info['frameworkRevision'];
    }
    if (!RegExp(r'^[a-f0-9]{40}$').hasMatch('${versions['flutterRevision']}')) {
      throw const TugException(
        'Run tug generate to pin flutterRevision in .coolify/toolchains.json.',
      );
    }
    for (final key in ['flutter', 'dart']) {
      if (!RegExp(r'^\d+\.\d+\.\d+$').hasMatch('${versions[key]}')) {
        throw TugException(
          'Pin a stable $key version in .coolify/toolchains.json.',
        );
      }
    }
    if (!RegExp(r'^/(?:[A-Za-z0-9_-]+/)*$').hasMatch(layout.flutterBaseHref)) {
      throw const TugException(
        'serverpod.flutterBaseHref must be a URL path beginning and ending with /.',
      );
    }
    final files = generatedFiles(
      layout,
      '${versions['flutter']}',
      '${versions['dart']}',
      '${versions['flutterRevision']}',
    );
    files['.coolify/toolchains.json'] =
        '${const JsonEncoder.withIndent('  ').convert(versions)}\n';
    final rootIgnore = File(p.join(layout.root, '.dockerignore'));
    final existingIgnore = await rootIgnore.exists()
        ? await rootIgnore.readAsString()
        : '';
    // Dockerfile-specific ignore takes precedence over root .dockerignore.
    files['.coolify/Dockerfile.dockerignore'] =
        '$existingIgnore\n${dockerExclusions(layout.server)}';
    for (final entry in files.entries) {
      final file = File(p.join(layout.root, entry.key));
      if (await file.exists()) {
        if (await file.readAsString() == entry.value) continue;
        if (!replace || check) {
          throw TugException(
            '${entry.key} differs. Review it, then use tug generate --force to replace it.',
          );
        }
      } else if (check) {
        throw TugException('Missing ${entry.key}; run tug generate.');
      }
    }
    if (check) return;
    for (final entry in files.entries) {
      final file = File(p.join(layout.root, entry.key));
      await file.parent.create(recursive: true);
      await file.writeAsString(entry.value);
    }
    await ensurePrivateIgnores(layout.root);
  }

  static String dockerExclusions(String server) =>
      '''# Tug runtime secrets never enter the build context.
**/.git
**/.dart_tool
**/.fvm
**/build
**/.env
**/.env.*
**/config/*.yaml
**/config/*.yml
**/passwords.*
**/credentials*
**/*.pem
**/*.key
**/*.p12
**/*.pfx
**/*.jks
**/*.keystore
**/.netrc
**/.npmrc
**/.pypirc
**/.ssh
**/.aws
**/id_rsa*
**/id_ed25519*
**/*service-account*.json
**/*service_account*.json
**/secrets.*
coolify.yaml
.coolify/local.yaml*
.coolify/state.json*
''';

  static Map<String, String> generatedFiles(
    ProjectLayout l,
    String flutter,
    String dart,
    String flutterRevision,
  ) => {
    '.coolify/Dockerfile':
        '''# Generated by Tug. Runtime configuration comes exclusively from Coolify.
FROM dart:$dart AS build
RUN apt-get update && apt-get install -y --no-install-recommends git curl unzip xz-utils libglu1-mesa && rm -rf /var/lib/apt/lists/*
RUN git clone --depth 1 --branch $flutter https://github.com/flutter/flutter.git /opt/flutter && test "\$(git -C /opt/flutter rev-parse HEAD)" = "$flutterRevision"
ENV PATH="/opt/flutter/bin:\${PATH}"
RUN flutter config --no-analytics && flutter precache --web
WORKDIR /app
COPY . .
${l.workspace ? 'RUN flutter pub get --enforce-lockfile' : 'RUN cd ${l.flutter} && flutter pub get --enforce-lockfile\nRUN cd ${l.server} && dart pub get --enforce-lockfile'}
RUN cd ${l.flutter} && flutter build web --release --no-pub --base-href ${l.flutterBaseHref}
RUN mkdir -p ${l.server}/web/app ${l.server}/migrations && cp -a ${l.flutter}/build/web/. ${l.server}/web/app/
RUN cd ${l.server} && dart build cli --target bin/main.dart --output build

FROM scratch
COPY --from=build /runtime/ /
WORKDIR /app
COPY --from=build /app/${l.server}/build/bundle/ /app/
COPY --from=build /app/${l.server}/web/ /app/web/
COPY --from=build /app/${l.server}/migrations/ /app/migrations/
COPY --from=build /app/${l.server}/lib/src/generated/protocol.yaml /app/lib/src/generated/protocol.yaml
EXPOSE 8080 8082
ENTRYPOINT ["/app/bin/main"]
''',
  };

  @override
  Future<Map<String, dynamic>> readState(String root) async {
    final file = File(p.join(root, '.coolify/state.json'));
    if (!await file.exists()) return {};
    try {
      return jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    } catch (_) {
      throw const TugException(
        'Invalid .coolify/state.json. Remove this cache to rediscover resources safely.',
      );
    }
  }

  @override
  Future<void> saveState(String root, Map<String, Object?> state) async {
    final file = File(p.join(root, '.coolify/state.json'));
    await file.parent.create(recursive: true);
    final temp = File('${file.path}.tmp');
    await temp.writeAsString(
      '${const JsonEncoder.withIndent('  ').convert(state)}\n',
      flush: true,
    );
    await temp.rename(file.path);
  }

  @override
  String get logTag => 'NativeWorkspaceService';
  @override
  Future<void> destroy() async {}
}
