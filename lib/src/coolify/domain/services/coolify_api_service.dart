import 'package:grumpy_cli/grumpy_cli.dart';
import 'package:grumpy_io/grumpy_io.dart';

import '../../../shared/domain/models/coolify_context.dart';
import '../models/coolify_operation.dart';

/// Maps domain operations to Coolify HTTP requests. It does not parse resources.
abstract class CoolifyApiService extends Service {
  CoolifyApiService.internal();
  factory CoolifyApiService() => Service.get<CoolifyApiService>();
  void configure(CoolifyContext context, String token);
  Future<NetworkResponse> execute(
    CoolifyOperation operation, {
    String? uuid,
    String? parent,
    Map<String, Object?> values = const {},
  });
  @override
  String get group => '${super.group}.CoolifyApiService';
  @override
  bool get singelton => true;
}
