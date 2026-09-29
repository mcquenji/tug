# Verification record

Validated on 2026-09-29 with Flutter 3.47.5, Dart 3.13.4 and a fresh Serverpod 4.0.3 fixture.

## Completed

- Static analysis with fatal infos, all 29 automated tests, generated-artifact freshness and native executable compilation passed.
- Grumpy's standard configuration precedence, whole-map replacement, scoped persistence and schema references.
- Local sensitive-field warnings, including inactive contexts, without values in output.
- Offline validation against the embedded canonical scoped schemas.
- Native Serverpod field mapping, password section precedence, case-sensitive custom passwords, reserved aliases and unsupported-field redaction.
- A stateful HTTP fixture covering production/staging isolation, PostgreSQL, Redis, runtime-only literal variables, explicit manifest precedence, synchronization, interrupted imports, uncertain creation/deployment responses, interrupted deployment acknowledgement, nonblocking applies, manual fields/variables, unchanged applies, missing local files, cache loss, environment failures, ownership ambiguity, topology moves and destruction guards, including database types omitted by the environment API.
- A clean Git checkout built with the generated Dockerfile, official Dart image and pinned Flutter Git revision. The checkout contained no native Serverpod configuration or password files.
- The resulting image ran against disposable local PostgreSQL 18 and Redis 7.4 using runtime environment variables only. Database migrations, a Redis write/read, imported-password availability, Flutter HTML/JavaScript, the runtime API URL and a greeting API request passed.
- An exported image audit found no native runtime configuration directory, password YAML or Tug manifest.
- The local smoke-test containers, named/anonymous volumes, network and tagged image were removed.
- Both EduPlanner repositories were inspected only for unsupported-layout diagnostics; their existing files and edits were preserved.
- Both requested test domains resolved in DNS. DNS was not modified.

## Release gate still pending

Live Coolify provisioning and HTTPS validation have not run. The prior automatic approval review rejected sending `COOLIFY_API_TOKEN` to a discovered URL without explicit destination authorization. A disposable context now explicitly names the destination and stores only the token's environment-variable name; the user's authorization question is pending. No live Coolify resources have been created.

The remaining live check uses the Projects server, `test.mcquenji.dev` and `api-test.mcquenji.dev`, with MCP discovery/monitoring and Tug REST provisioning. It must verify internal database connectivity, HTTPS, migrations, Redis, Flutter/API connectivity, import persistence, idempotency and cache recovery, then remove all test resources and volumes.

The temporary GitHub fixture branch became the repository's default branch because the repository was initially empty. It must be replaced as the default before GitHub will permit its deletion. All fixture runtime configuration and passwords remained uncommitted.

## Repeatable local checks

```sh
fvm dart pub get
fvm dart run tool/generate.dart --check
fvm dart analyze --fatal-infos
fvm dart test
mkdir -p build
fvm dart compile exe bin/tug.dart -o build/tug
```

The Grumpy generator currently emits an upstream analyzer/SDK-version advisory while completing successfully. Generated-artifact freshness and `dart analyze --fatal-infos` remain separate checks.
