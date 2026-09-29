import 'package:grumpy_cli/grumpy_cli.dart';
import 'package:tug/src/coolify/coolify.dart';
import 'package:tug/src/serverpod/serverpod.dart';

class EnvironmentSnapshot extends Model {
  EnvironmentSnapshot(this.name, this.domains, this.explicit);
  final String name;
  final Map<String, String> domains, explicit;
  RemoteResource? environment, application, postgres, redis;
  List<RemoteResource> resources = [];
  Map<String, RemoteVariable> variables = {};
  ConfigImport? imported;
}
