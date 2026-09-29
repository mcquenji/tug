import 'dart:io';

import 'package:grumpy_cli/grumpy_cli.dart';
import 'package:grumpy_io/grumpy_io.dart';
import 'package:tug/src/app/app.dart';

Future<ConfigService> configFixture(
  Directory root, {
  String global = '{}',
  String local = '{}',
}) async {
  final files = ConfigFiles(
    applicationId: 'tug',
    globalDirectory: '${root.path}/global',
    localDirectory: '${root.path}/local',
    global: const ConfigFileOptions(
      filename: 'config.yaml',
      format: ConfigFormat.yaml,
    ),
    local: const ConfigFileOptions(
      filename: 'coolify.yaml',
      format: ConfigFormat.yaml,
    ),
  );
  final globalFile = File('${root.path}/global/config.yaml');
  final localFile = File('${root.path}/local/coolify.yaml');
  await globalFile.parent.create(recursive: true);
  await localFile.parent.create(recursive: true);
  await globalFile.writeAsString(global);
  await localFile.writeAsString(local);
  final datasource = FileConfigDatasource(
    fileSystemService: DefaultFileSystemService(),
  );
  final service = DefaultConfigService(
    schema: AppConfig.defaults().configSchema,
    files: files,
    datasource: datasource,
    locations: PlatformConfigLocationService(datasource),
    codec: JsonYamlConfigCodecService(),
  );
  await service.load();
  return service;
}
