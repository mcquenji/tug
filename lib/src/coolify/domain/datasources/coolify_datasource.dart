import 'package:grumpy_cli/grumpy_cli.dart';

import '../models/connection_info.dart';
import '../models/coolify_operation.dart';
import '../models/deployment_info.dart';
import '../models/remote_resource.dart';
import '../models/remote_variable.dart';

/// Typed access to Coolify resources; all response parsing lives here.
abstract class CoolifyDatasource extends Datasource {
  CoolifyDatasource.internal();
  factory CoolifyDatasource() => Datasource.get<CoolifyDatasource>();
  Future<List<RemoteResource>> list(CoolifyOperation operation, {String? uuid});
  Future<RemoteResource> get(String kind, String uuid);
  Future<List<RemoteResource>> resources(String project, String environment);
  Future<String> create(
    CoolifyOperation operation,
    Map<String, Object?> values, {
    String? parent,
  });
  Future<void> mutate(
    CoolifyOperation operation, {
    String? uuid,
    String? parent,
    Map<String, Object?> values = const {},
  });
  Future<Map<String, RemoteVariable>> variables(String application);
  Future<ConnectionInfo> connection(String database);
  Future<DeploymentInfo> deployment(String uuid);
  Future<DeploymentInfo?> latestDeployment(String application);
  Future<String> deploy(String application);
  Future<String> logs(String application);
  Future<bool> hasStorage(String application);
  @override
  String get group => '${super.group}.CoolifyDatasource';
  @override
  bool get singelton => true;
}
