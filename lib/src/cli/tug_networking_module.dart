import 'package:dio/dio.dart';
import 'package:grumpy_cli/grumpy_cli.dart';
import 'package:grumpy_io/grumpy_io.dart';

import '../shared/domain/models/app_config.g.dart';

class TugNetworkingModule extends NetworkingModule<CliCommand, AppConfig> {
  @override
  InjectableFactory<Dio, AppConfig> get dioBuilder =>
      (_, _) => Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 20),
          followRedirects: false,
          validateStatus: (_) => true,
        ),
      );
  @override
  String get logTag => 'TugNetworkingModule';
}
