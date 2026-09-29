import 'package:grumpy_cli/grumpy_cli.dart';

import '../../../coolify/domain/models/remote_resource.dart';
import '../../../coolify/domain/models/remote_variable.dart';
import '../../../serverpod/domain/models/config_import.dart';

class EnvironmentSnapshot extends Model {
  EnvironmentSnapshot(this.name, this.domains, this.explicit);
  final String name;
  final Map<String, String> domains, explicit;
  RemoteResource? environment, application, postgres, redis;
  List<RemoteResource> resources = [];
  Map<String, RemoteVariable> variables = {};
  ConfigImport? imported;
}
