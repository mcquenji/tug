import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

import '../app.dart';

/// Machine-specific project choices. Build files beside this file remain shared.
class DeploymentSettings {
  DeploymentSettings(this.root, this.values);
  final String root;
  final Map<String, dynamic> values;
  String get path => p.join(root, '.coolify', 'local.yaml');
  String? get context => values['context'] as String?;
  set context(String? value) => values['context'] = value;
  Map<String, CoolifyContext> get contexts =>
      AppConfig.settings.contexts.type.decode(values['contexts'] ?? {});
  Map<String, DomainConfig> get domains => {
    for (final entry in (values['domains'] as Map? ?? {}).entries)
      '${entry.key}': DomainConfig(
        web: entry.value['web'] as String? ?? 'auto',
        api: entry.value['api'] as String? ?? 'auto',
      ),
  };
  void setDomains(String environment, DomainConfig domains) {
    (values['domains'] ??= <String, dynamic>{})[environment] = {
      'web': domains.web,
      'api': domains.api,
    };
  }

  static Future<DeploymentSettings> load(String root) async {
    final file = File(p.join(root, '.coolify', 'local.yaml'));
    try {
      final raw = await file.exists()
          ? loadYaml(await file.readAsString())
          : {};
      final values = Map<String, dynamic>.from(
        jsonDecode(jsonEncode(raw ?? {})) as Map,
      );
      if (values.keys.any(
            (k) => !['context', 'contexts', 'domains'].contains(k),
          ) ||
          values['context'] != null && values['context'] is! String) {
        throw const FormatException();
      }
      final result = DeploymentSettings(root, values);
      result.contexts;
      result.domains;
      return result;
    } catch (_) {
      throw const TugException(
        'Invalid .coolify/local.yaml (contents hidden).',
      );
    }
  }

  Future<void> save() async {
    await ensurePrivateIgnores(root);
    final file = File(path);
    await file.parent.create(recursive: true);
    final yaml = YamlEditor('')..update([], values);
    final temporary = File('$path.tmp');
    await temporary.writeAsString('$yaml\n', flush: true);
    await temporary.rename(path);
  }
}

Future<void> ensurePrivateIgnores(String root) async {
  final file = File(p.join(root, '.gitignore'));
  var text = await file.exists() ? await file.readAsString() : '';
  final entries = text.split('\n').toSet();
  for (final pattern in [
    '/.coolify/local.yaml',
    '/.coolify/local.yaml.tmp',
    '/.coolify/state.json',
    '/.coolify/state.json.tmp',
    '/.env',
    '/.env.*',
  ]) {
    if (!entries.contains(pattern)) {
      if (text.isNotEmpty && !text.endsWith('\n')) text += '\n';
      text += '$pattern\n';
    }
  }
  await file.parent.create(recursive: true);
  await file.writeAsString(text);
}
