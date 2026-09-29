import 'package:grumpy_cli/grumpy_cli.dart';

import '../models/config_import.dart';

abstract class ServerpodConfigDatasource extends Datasource {
  ServerpodConfigDatasource.internal();
  factory ServerpodConfigDatasource() =>
      Datasource.get<ServerpodConfigDatasource>();
  Future<ConfigImport> read(String serverDirectory, String mode);
  @override
  String get group => '${super.group}.ServerpodConfigDatasource';
  @override
  bool get singelton => true;
}
