import 'dart:convert';
import 'dart:math';

String newSecret() =>
    base64Url.encode(List.generate(36, (_) => Random.secure().nextInt(256)));

String canonicalVariable(String key) => switch (key.toLowerCase()) {
  'serverpod_password_database' => 'SERVERPOD_DATABASE_PASSWORD',
  'serverpod_password_redis' => 'SERVERPOD_REDIS_PASSWORD',
  'serverpod_password_servicesecret' => 'SERVERPOD_SERVICE_SECRET',
  _ => key,
};

bool ownedVariable(String key) {
  key = canonicalVariable(key);
  return key.startsWith('TUG_') ||
      const {
        'SERVERPOD_RUN_MODE',
        'SERVERPOD_SERVER_ID',
        'SERVERPOD_SERVER_ROLE',
        'SERVERPOD_APPLY_MIGRATIONS',
        'SERVERPOD_APPLY_REPAIR_MIGRATION',
        'SERVERPOD_API_SERVER_PORT',
        'SERVERPOD_API_SERVER_PUBLIC_HOST',
        'SERVERPOD_API_SERVER_PUBLIC_PORT',
        'SERVERPOD_API_SERVER_PUBLIC_SCHEME',
        'SERVERPOD_WEB_SERVER_PORT',
        'SERVERPOD_WEB_SERVER_PUBLIC_HOST',
        'SERVERPOD_WEB_SERVER_PUBLIC_PORT',
        'SERVERPOD_WEB_SERVER_PUBLIC_SCHEME',
        'SERVERPOD_INSIGHTS_SERVER_PORT',
        'SERVERPOD_INSIGHTS_SERVER_PUBLIC_HOST',
        'SERVERPOD_INSIGHTS_SERVER_PUBLIC_PORT',
        'SERVERPOD_INSIGHTS_SERVER_PUBLIC_SCHEME',
        'SERVERPOD_INSIGHTS_SERVER_ENABLE_DATABASE_ACCESS',
        'SERVERPOD_DATABASE_HOST',
        'SERVERPOD_DATABASE_PORT',
        'SERVERPOD_DATABASE_NAME',
        'SERVERPOD_DATABASE_USER',
        'SERVERPOD_DATABASE_PASSWORD',
        'SERVERPOD_DATABASE_REQUIRE_SSL',
        'SERVERPOD_DATABASE_IS_UNIX_SOCKET',
        'SERVERPOD_DATABASE_DATA_PATH',
        'SERVERPOD_REDIS_ENABLED',
        'SERVERPOD_REDIS_HOST',
        'SERVERPOD_REDIS_PORT',
        'SERVERPOD_REDIS_USER',
        'SERVERPOD_REDIS_PASSWORD',
        'SERVERPOD_REDIS_REQUIRE_SSL',
        'SERVERPOD_SERVICE_SECRET',
      }.contains(key);
}

bool sensitiveName(String key) => RegExp(
  r'password|token|secret|credential|private.?key|api.?key',
  caseSensitive: false,
).hasMatch(key);

/// Redacts known runtime values and common credential syntax from diagnostics.
String redact(String input, Iterable<String> values) {
  var result = input.replaceAll(RegExp(r'\x1B\[[0-?]*[ -/]*[@-~]'), '');
  final ordered = values.where((v) => v.isNotEmpty).toSet().toList()
    ..sort((a, b) => b.length.compareTo(a.length));
  for (final value in ordered) {
    for (final representation in {
      value,
      Uri.encodeComponent(value),
      jsonEncode(value).substring(1, jsonEncode(value).length - 1),
      base64.encode(utf8.encode(value)),
    }) {
      result = result.replaceAll(representation, '[REDACTED]');
    }
  }
  result = result.replaceAll(
    RegExp(r'(?<=://)[^/\s:@]+:[^@\s]+@'),
    '[REDACTED]@',
  );
  result = result.replaceAll(
    RegExp(r'Bearer\s+[^\s"\x27]+', caseSensitive: false),
    'Bearer [REDACTED]',
  );
  result = result.replaceAllMapped(
    RegExp(
      r'((?:PASSWORD|TOKEN|SECRET|CREDENTIAL|API_KEY)[a-zA-Z0-9_]*\s*[:=]\s*)[^\r\n]+',
      caseSensitive: false,
    ),
    (m) => '${m[1]}[REDACTED]',
  );
  return result;
}
