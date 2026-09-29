import 'package:grumpy_cli/grumpy_cli.dart';

import '../models/deployment_spec.dart';

abstract class ReconcileService extends Service {
  ReconcileService.internal();
  factory ReconcileService() => Service.get<ReconcileService>();
  Future<void> apply(
    DeploymentSpec spec, {
    String? environment,
    bool plan = false,
    bool sync = false,
    bool wait = true,
  });
  Future<void> status(
    DeploymentSpec spec, {
    String? environment,
    bool logs = false,
  });
  Future<void> destroyDeployment(
    DeploymentSpec spec, {
    String? environment,
    bool destroyData = false,
    required Future<bool> Function() confirm,
  });
  @override
  String get group => '${super.group}.ReconcileService';
  @override
  bool get singelton => true;
}
