# Tug

Tug provisions Serverpod 4 monorepos on Coolify: one application and private PostgreSQL per named environment, with optional Redis. Coolify builds the committed source and stores the runtime configuration.

## Install with Homebrew

```sh
brew install mcquenji/tap/tug
```

macOS and Linux releases install through the tap. Windows x64 binaries are available from [GitHub Releases](https://github.com/mcquenji/tug/releases). See [release and installation instructions](docs/releases.md) for supported systems, upgrades, and publishing version tags.

## Build and run

Tug resolves the Grumpy packages from their `mcquenji` GitHub repositories. The committed `pubspec.lock` pins their resolved revisions; sibling checkouts and local dependency overrides are not required.

```sh
fvm dart pub get
fvm dart run tool/generate.dart
fvm dart run bin/tug.dart --help
fvm dart run tool/build.dart
build/tug --version
```

`tool/build.dart` reads the version from Tug's `pubspec.yaml` and embeds it in the executable. `tug --version` works without configuration, a checkout, or a pubspec on the target machine. Add `build/tug` to your PATH. A project must contain a Serverpod 4 server, Flutter app, committed dependency locks, generated protocol resources and migrations in one GitHub repository. Split Serverpod 3 repositories are unsupported.

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

Run `tug context add` to be prompted for all missing values, including the context name. Supplied arguments skip their prompts. Server and destination defaults can be left blank to select them per checkout. Domain prompts default to `auto`; unattended invocations also use that default. Replacing an existing context still requires `--force`.

Put the referenced token in the project-root `.env` file or your shell environment. Do not put its value in an argument. Omit `--token-env` to be prompted for the environment variable name, or leave that prompt blank to enter a token through an obscured prompt and save it globally. API access requires `read`, `read:sensitive`, `write` and `deploy` permissions.

Global contexts use Grumpy's default configuration location (`~/Library/Application Support/tug/config.yaml` on macOS, XDG on Linux). The committed `coolify.yaml` contains portable app settings: layout, source, environments, branches, database requirements and variable/secret references. Connection profiles, selected context and public domains do not belong in that manifest.

Each checkout stores its context selection, domain names and any connection overrides in **`.coolify/local.yaml`**, which Tug gitignores along with its state cache and `.env` files. On first interactive use of a checkout, Tug lists the instance's servers and asks where to deploy, even when the global context has a default server. It then lists destinations belonging to that server and saves both choices privately. Later commands reuse and display the saved target. Use `tug plan --select-server` to choose again; changing a selection does not move existing resources. Missing GitHub App settings are also prompted for. An explicit `--context` takes precedence over the saved selection. On first use, interactive commands offer global contexts; unattended commands can use the global current context and explicitly configured server/destination defaults, but fail clearly if required settings are missing. `--select-server` requires interactive selection. No compatibility/migration layer is provided for the old manifest format.

Example private settings (never commit this file):

```yaml
context: home
domains:
  production:
    web: app.example.com
    api: api.example.com
```

Tug reads `.env` automatically for token references and `secrets.*.fromEnv`. Shell values take precedence, including explicitly empty values. Use `--no-env-file` to ignore the file. Quoted values, multiline values, `export` and comments are supported; dollar signs stay literal and no shell commands or variable expansions run. `.env` entries are not automatically uploaded to Coolify.

Terminal tasks use spinners with success/failure markers, colored diagnostics and clean output when redirected. `--verbose` adds API-operation and deployment-status details without request bodies or credentials. Use `--no-color` or `NO_COLOR` to disable colors.

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

`init` writes portable defaults (`source.repository: auto` discovers the clone's Git origin), and saves `--context`, `--web-domain`, and `--api-domain` privately. `init` and `generate` preserve existing build files. Use `generate --force` only after reviewing a requested replacement. The toolchain file pins the Flutter version and Git revision plus the Dart version. The default Flutter URL prefix is `/app/`; set `serverpod.flutterBaseHref: /` for a FlutterRoute mounted at the root.

`tug generate` produces `.coolify/Dockerfile`, `.coolify/Dockerfile.dockerignore`, and `.coolify/toolchains.json`, plus ignore rules. Commit these build files; **do not gitignore the whole `.coolify` directory**. Regenerate when the project layout, Flutter base path, pinned toolchain, Docker exclusion rules, or Tug's build template changes. Normal app-code edits and environment-variable changes do **not** require generation. Push code changes to the configured branch; use `tug apply` for manifest settings and explicit secret references, or `tug config sync` to reimport native Serverpod configuration.

Tug never stages or commits files. Native runtime YAML, passwords, `.env` files and common credential files are excluded from the generated Docker build context. The runtime image contains compiled code, native assets, Flutter assets, migrations and protocol resources. Existing safe tracked Serverpod defaults may remain in Git; they are excluded from Tug's image.

Tug enables and reconciles Coolify's HTTP health check at `http://127.0.0.1:8080/readyz` (GET, expected status 200), using a 10-second interval, 5-second timeout, 3 retries and a 60-second startup grace period. The generated runtime includes a static BusyBox shell and wget so Coolify can execute the check inside the container. Existing projects must review and run `tug generate --force`, then commit the updated Dockerfile before applying this version.

## Runtime configuration import

During the first apply for each environment, Tug reads local `<server>/config/<configMode>.yaml` and `config/passwords.yaml`. Mode-specific passwords override `shared`. Production imports `production` by default; other environments import `staging`. An explicit `configMode` selects another source while the deployed run mode remains production.

Supported Serverpod settings become their documented environment variables. Password `jwtSecret` becomes the case-sensitive `SERVERPOD_PASSWORD_jwtSecret`. Unsupported paths or values are rejected before provisioning. Serverpod 4.0 cannot parse explicit null log-retention values from environment strings; choose an explicit supported value. Null future-call concurrency maps to its documented unlimited value.

Tug-owned database/Redis connections, credentials, service secret, ports and private deployment domains take precedence. Explicit manifest settings and references take precedence over imported application values:

```yaml
environments:
  production:
    branch: main
    configMode: production
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

## Deployment health and addresses

By default `apply` waits for both the deployment and a healthy application. Failed/cancelled deployments, unhealthy or exited containers, rollback logs, and unconfirmed health at the polling deadline cause a nonzero exit. `--no-wait` reports submission only; it does not claim deployment success.

The generated runtime includes `wget` and `/bin/sh` for Coolify's health check. Coolify's Dockerfile warning is advisory about the image's required tools, not proof that a tool is missing. Consult the actual health-check output for the failure. Commit and push regenerated Dockerfiles before redeploying: Coolify builds the Git branch, not uncommitted local files.

Public URLs are HTTPS on port 443. The container serves plain HTTP on ports 8080 (API) and 8082 (web), on all container interfaces. Serverpod's `Webserver listening` log currently combines the public hostname with its internal scheme/port; use Tug's explicitly labeled public URLs instead. Do not change the internal port to 443 or bind to localhost, since Coolify's proxy must reach the container.

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
