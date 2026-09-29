import 'dart:io';

import 'package:test/test.dart';
import 'package:tug/src/serverpod/infra/datasources/native_serverpod_config_datasource.dart';
import 'package:tug/src/shared/domain/models/tug_exception.dart';
import 'package:tug/src/shared/utils/security.dart';

void main() {
  late Directory temp;
  late NativeServerpodConfigDatasource source;
  setUp(() async {
    temp = await Directory.systemTemp.createTemp('tug-import-');
    await Directory('${temp.path}/config').create();
    source = NativeServerpodConfigDatasource();
  });
  tearDown(() async => temp.delete(recursive: true));
  Future<void> write(String name, String value) =>
      File('${temp.path}/config/$name.yaml').writeAsString(value);
  test(
    'maps documented settings and case-sensitive passwords; mode wins shared',
    () async {
      await write('staging', '''maxRequestSize: 1048576
allowedOrigins: [https://test.example.com, https://other.example.com]
authCookie:
  refreshName: refresh
  secure: true
sessionLogs:
  retentionPeriod: 30d
futureCall:
  scanInterval: 1000
database:
  searchPaths: [public, tenant]
''');
      await write('passwords', '''shared:
  jwtSecret: shared-secret
  JWTSecret: different-secret
staging:
  jwtSecret: staging-secret
production:
  jwtSecret: production-secret
''');
      final result = await source.read(temp.path, 'staging');
      expect(
        result.values,
        containsPair(
          'SERVERPOD_ALLOWED_ORIGINS',
          'https://test.example.com,https://other.example.com',
        ),
      );
      expect(
        result.values,
        containsPair('SERVERPOD_AUTH_COOKIE_REFRESH_NAME', 'refresh'),
      );
      expect(
        result.values,
        containsPair('SERVERPOD_SESSION_LOG_RETENTION_PERIOD', '30d'),
      );
      expect(
        result.values,
        containsPair('SERVERPOD_FUTURE_CALL_SCAN_INTERVAL', '1000'),
      );
      expect(
        result.values,
        containsPair('SERVERPOD_DATABASE_SEARCH_PATHS', 'public,tenant'),
      );
      expect(
        result.values,
        containsPair('SERVERPOD_PASSWORD_jwtSecret', 'staging-secret'),
      );
      expect(
        result.values,
        containsPair('SERVERPOD_PASSWORD_JWTSecret', 'different-secret'),
      );
      expect(result.toString(), isNot(contains('staging-secret')));
    },
  );
  test('reports unsupported field paths without values', () async {
    await write('production', 'database:\n  filePath: NEVER-PRINT-ME\n');
    await expectLater(
      source.read(temp.path, 'production'),
      throwsA(
        isA<TugException>()
            .having((e) => e.message, 'path', contains('database.filePath'))
            .having(
              (e) => e.message,
              'redaction',
              isNot(contains('NEVER-PRINT-ME')),
            ),
      ),
    );
  });
  test('rejects malformed source values without source excerpts', () async {
    await write('passwords', 'shared: [NEVER-PRINT-ME\n');
    await expectLater(
      source.read(temp.path, 'production'),
      throwsA(
        isA<TugException>().having(
          (e) => e.message,
          'redaction',
          isNot(contains('NEVER-PRINT-ME')),
        ),
      ),
    );
  });
  test(
    'missing local sources are represented without invented values',
    () async {
      final result = await source.read(temp.path, 'production');
      expect(result.available, isFalse);
      expect(result.values, isEmpty);
    },
  );
  test('normalizes every infrastructure password alias', () {
    for (final key in [
      'SERVERPOD_PASSWORD_database',
      'SERVERPOD_PASSWORD_redis',
      'SERVERPOD_PASSWORD_serviceSecret',
      'SERVERPOD_PASSWORD_SERVICESECRET',
    ]) {
      expect(ownedVariable(key), isTrue);
    }
    expect(ownedVariable('SERVERPOD_PASSWORD_jwtSecret'), isFalse);
    expect(ownedVariable('SERVERPOD_DATABASE_MAX_CONNECTION_COUNT'), isFalse);
  });
  test(
    'diagnostics redact known secrets, credentials and terminal escapes',
    () {
      expect(
        redact('secret=abc\npostgres://u:abc@db\nBearer xyz\n\x1b[31mabc', [
          'abc',
        ]),
        isNot(contains('abc')),
      );
      expect(redact('Bearer xyz', []), 'Bearer [REDACTED]');
    },
  );
}
