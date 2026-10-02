import 'dart:convert';

import 'package:grumpy_cli/grumpy_cli.dart';

import 'secret_reference.dart';

/// Runtime variables accept literal strings or explicit local references.
const environmentVariablesSchema = <String, Object?>{
  'type': 'object',
  'additionalProperties': {
    'oneOf': [
      {'type': 'string'},
      {
        'type': 'object',
        'additionalProperties': false,
        'required': ['fromEnv'],
        'properties': {
          'fromEnv': {'type': 'string', 'pattern': r'^[A-Za-z_][A-Za-z0-9_]*$'},
        },
      },
    ],
  },
};

/// Preserves existing string literals and decodes references without resolving
/// their values, so config writes never persist values from the environment.
CliValueType<Map<String, Object>> environmentVariablesType() {
  Object decode(Object? value) {
    if (value is String) return value;
    if (value is Map && value.length == 1 && value['fromEnv'] is String) {
      final name = value['fromEnv'] as String;
      if (RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$').hasMatch(name)) {
        return SecretReference(fromEnv: name);
      }
    }
    throw const FormatException(
      'Expected a string or an object containing a valid fromEnv variable name.',
    );
  }

  return CliValueType.map(
    CliValueType<Object>(
      parse: (text) => decode(jsonDecode(text)),
      decode: decode,
      encode: (value) {
        final encoded = value is SecretReference
            ? {'fromEnv': value.fromEnv}
            : value;
        decode(encoded);
        return encoded;
      },
      schema:
          environmentVariablesSchema['additionalProperties']!
              as Map<String, Object?>,
    ),
  );
}
