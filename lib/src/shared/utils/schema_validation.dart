import 'dart:convert';

import 'package:json_schema/json_schema.dart';

import '../generated/schemas.g.dart';
import '../domain/models/tug_exception.dart';

/// Resolves only embedded schema data; offline validation never fetches a URL.
void validateOffline(Object? document, {required String scope}) {
  if (!['global', 'local'].contains(scope)) {
    throw ArgumentError('Unknown configuration scope.');
  }
  final canonical = jsonDecode(configSchemaJson) as Map;
  final schema = JsonSchema.create((canonical[r'$defs'] as Map)[scope]);
  final result = schema.validate(document);
  if (!result.isValid) {
    // Validator messages can contain instance values. Report only property paths.
    final paths = result.errors.map((e) => e.instancePath).toSet().join(', ');
    throw TugException(
      'Invalid $scope configuration at $paths (values redacted).',
    );
  }
}
