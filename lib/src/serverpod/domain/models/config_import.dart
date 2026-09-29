import 'package:grumpy_cli/grumpy_cli.dart';

/// Values live only in memory until uploaded to Coolify.
class ConfigImport extends Model {
  const ConfigImport(this.values, this.sources);
  final Map<String, String> values;
  final List<String> sources;
  bool get available => sources.isNotEmpty;
  @override
  String toString() => 'ConfigImport(${values.keys.join(', ')})';
}
