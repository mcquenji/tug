# Tug

Tug provisions Serverpod 4 monorepos on Coolify: one application and private PostgreSQL per named environment, with optional Redis. Coolify builds the committed source and stores the runtime configuration.

## Build and run

Keep `grumpy`, `grumpy_annotations`, `grumpy_cli`, `grumpy_io`, `grumpy_gen`, and `grumpy_lints` beside this repository. Tug uses the local package overrides in `pubspec.yaml`.

```sh
fvm dart pub get
fvm dart run tool/generate.dart
fvm dart run bin/tug.dart --help
mkdir -p build
fvm dart compile exe bin/tug.dart -o build/tug
```

Add `build/tug` to your PATH. A project must contain a Serverpod 4 server, Flutter app, committed dependency locks, generated protocol resources and migrations in one GitHub repository. Split Serverpod 3 repositories are unsupported.

## Connect to Coolify

```sh
tug context add home \
  --url https://coolify.example.com \
  --token-env COOLIFY_API_TOKEN \
  --server SERVER_UUID \
  --destination DESTINATION_UUID \
  --github-app GITHUB_APP_UUID
tug context use home
```

Set the token in your shell using your normal secret manager. Do not put its value in an argument. Omit `--token-env` to enter a token through an obscured prompt and save it globally. API access requires `read`, `read:sensitive`, `write` and `deploy` permissions.

Grumpy's default global configuration location is used (`~/Library/Application Support/tug/config.yaml` on macOS, XDG on Linux). Project configuration is `coolify.yaml`. Resolution is local → global → defaults; maps and lists replace lower-precedence values. Context selection is `--context`, then project `context`, then resolved `currentContext`. Local credentials are allowed with a warning that names the setting but never its value.

## Initialize and deploy

Run in the monorepo root:

```sh
tug init --context home \
  --web-domain app.example.com \
  --api-domain api.example.com
# Review and commit coolify.yaml, .coolify build files, locks and generated app code.
tug doctor
tug plan
tug apply
tug status
```

`init` and `generate` preserve existing files. Use `generate --force` only after reviewing a requested replacement. The toolchain file pins the Flutter version and Git revision plus the Dart version. The default Flutter URL prefix is `/app/`; set `serverpod.flutterBaseHref: /` for a FlutterRoute mounted at the root.

Tug never stages or commits files. Native runtime YAML, passwords, `.env` files and common credential files are excluded from the generated Docker build context. The runtime image contains compiled code, native assets, Flutter assets, migrations and protocol resources. Existing safe tracked Serverpod defaults may remain in Git; they are excluded from Tug's image.

## Runtime configuration import

During the first apply for each environment, Tug reads local `<server>/config/<configMode>.yaml` and `config/passwords.yaml`. Mode-specific passwords override `shared`. Production imports `production` by default; other environments import `staging`. An explicit `configMode` selects another source while the deployed run mode remains production.

Supported Serverpod settings become their documented environment variables. Password `jwtSecret` becomes the case-sensitive `SERVERPOD_PASSWORD_jwtSecret`. Unsupported paths or values are rejected before provisioning. Serverpod 4.0 cannot parse explicit null log-retention values from environment strings; choose an explicit supported value. Null future-call concurrency maps to its documented unlimited value.

Tug-owned database/Redis connections, credentials, service secret, ports and domains take precedence. Explicit manifest settings and references take precedence over imported application values:

```yaml
environments:
  production:
    branch: main
    configMode: production
    domains:
      web: app.example.com
      api: api.example.com
    env:
      SERVERPOD_MAX_REQUEST_SIZE: '1048576'
    secrets:
      jwtSecret:
        fromEnv: PRODUCTION_JWT_SECRET
```

Imported secrets are literal, runtime-only Coolify variables. They are never build arguments or local state. Later applies preserve the saved values even if the original files disappear. Editing a local file does not automatically rotate a deployed value. To refresh source values deliberately:

```sh
tug config sync --environment production
```

Synchronization upserts present keys, preserves absent keys, and respects Tug-owned and explicit settings. Remote metadata records imported key names and completion, separately from manifest ownership. Applications must allow Serverpod to read environment configuration; a custom explicit `ServerpodConfig` object can bypass that behavior.

## Named environments and destruction

```sh
tug environment add staging --branch develop \
  --web-domain staging.example.com --api-domain api-staging.example.com
tug apply --environment staging
tug logs --environment staging
tug environment destroy staging --destroy-data
# Destroy all managed environments and the empty parent project:
tug destroy --destroy-data --yes
```

Every environment has separate database credentials. Enable Redis globally with `redis.enabled: true` or override it per environment. Orphans are reported and preserved. Ownership/repository checks run before mutation; ambiguous matches, topology moves and automatic database upgrades or recreation are refused. Manual settings and variables outside Tug's ownership remain intact.

Destruction preflights all selected resources. Persistent data requires `--destroy-data`; confirmation and `--yes` cannot bypass it. Removing `.coolify/state.json` is safe: it stores only verified IDs and is never trusted as authorization to mutate a resource.

## Schemas and verification

Grumpy-generated scoped schemas and documentation live under `schemas/v1/` and [docs/configuration.md](docs/configuration.md). Canonical copies are embedded for offline validation. Hosted editor URLs become anonymously accessible when the repository is public.

```sh
fvm dart run tool/generate.dart --check
fvm dart analyze --fatal-infos
fvm dart test
```

See [the design](docs/plan.md) and [verification record](docs/verification.md) for behavior and release checks.

## Code organization

Tug follows EduPlanner's feature-module structure. `lib/src/app/app.dart` defines the root `App` and composes the features. Each feature has a matching entry point (`coolify/coolify.dart`, `workspace/workspace.dart`, and so on) that owns its dependency bindings and command routes, and exports its domain, presentation and utilities through barrel files.

Domain contracts and models live in `domain/`; concrete services and datasources live in `infra/`. Each CLI command has its own file under its feature's `presentation/commands/`. Import other features through their module entry points. Configuration models belong to `app/domain/models/`, while generated offline schemas live in `lib/gen/`.
