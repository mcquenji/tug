import 'package:dio/dio.dart';
import 'package:grumpy_cli/grumpy_cli.dart';
import 'package:grumpy_io/grumpy_io.dart';
import 'package:tug/src/app/app.dart';

class CoolifyNetworkingModule extends NetworkingModule<CliCommand, AppConfig> {
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
  String get logTag => 'CoolifyNetworkingModule';
}
