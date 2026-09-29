import 'package:grumpy_cli/grumpy_cli.dart';

import '../../../shared/domain/models/app_config.g.dart';
import '../models/project_layout.dart';

abstract class WorkspaceService extends Service {
  WorkspaceService.internal();
  factory WorkspaceService() => Service.get<WorkspaceService>();
  Future<ProjectLayout> inspect(String directory, AppConfig config);
  Future<void> generate(
    ProjectLayout layout, {
    bool replace = false,
    bool check = false,
  });
  Future<void> saveState(String root, Map<String, Object?> state);
  Future<Map<String, dynamic>> readState(String root);
  @override
  String get group => '${super.group}.WorkspaceService';
  @override
  bool get singelton => true;
}
