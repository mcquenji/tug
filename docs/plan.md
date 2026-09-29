# Tug — Coolify Bootstrap CLI

**Status:** Implementation design v1 — runtime configuration stored in Coolify
**Purpose:** Personal deployment bootstrapper for Flutter + Serverpod applications running on Coolify
**Manifest:** `coolify.yaml`
**Manifest schema:** `schemas/v1/coolify.schema.json` hosted in the Tug repository
**Target:** Serverpod 4.x, Flutter Web/PWA, self-hosted Coolify v4

## 1. Goal

Provision a newly created Serverpod/Flutter application on an existing Coolify installation with essentially:

```bash
tug init
tug apply
```

Afterwards, existing CI/CD handles future deployments.

`tug` is **not** another deployment platform. Coolify remains responsible for builds, containers, networking, databases, TLS, logs and deployments. `tug` turns a small declarative `coolify.yaml` into the initial Coolify resources and keeps those resources reconciled across multiple environments.

The intended end state is:

```text
git clone / serverpod create
        │
        ▼
    tug init
        │
        ├── coolify.yaml
        └── .coolify/Dockerfile
        │
        ▼
    tug apply
        │
        ├── Coolify Project
        ├── production Environment
        ├── optional staging Environments
        ├── PostgreSQL per environment
        ├── Serverpod Application per environment
        ├── domains
        ├── environment variables
        └── initial deployments
```

## 2. Architecture decision

A normal application should consist of one Coolify Project with one or more environments:

```text
Coolify Project: notes
├── production
│   ├── Application
│   │   ├── Serverpod API        :8080
│   │   └── Flutter Web / PWA    :8082
│   │
│   └── PostgreSQL               :5432
│
└── staging
    ├── Application
    │   ├── Serverpod API        :8080
    │   └── Flutter Web / PWA    :8082
    │
    └── PostgreSQL               :5432

optional per environment:
    └── Redis                    :6379
```

Each Coolify environment is an isolated deployment target. Applications and databases belonging to the same environment share that environment’s destination/network configuration.

There should **not** be a separate Flutter container by default.

Serverpod 4 can directly serve the compiled Flutter web application from `web/app`. Its `FlutterRoute` handles static files, SPA fallback and cache behavior, and new full-stack projects already contain support for this setup. ([Serverpod](https://docs.serverpod.dev/concepts/web-server/flutter-web?utm_source=chatgpt.com))

Serverpod’s Flutter client can also obtain the production API address at runtime from the Serverpod-served `config.json`. That means the Flutter bundle does not need to be rebuilt simply because the API hostname changed. ([Serverpod](https://docs.serverpod.dev/next/concepts/endpoints-and-apis?utm_source=chatgpt.com))

Coolify can route multiple hostnames to different ports in the **same container**. For example:

```text
https://notes.example.com:8082
https://api.notes.example.com:8080
```

The `:8082` and `:8080` portions are Coolify’s internal target-port syntax; users still visit normal HTTPS port 443. ([Coolify](https://coolify.io/docs/applications/configuration/general?utm_source=chatgpt.com))

Therefore:

```text
notes.example.com
        │
        ▼
 Coolify Proxy ───────► container:8082

api.notes.example.com
        │
        ▼
 Coolify Proxy ───────► same container:8080
```

Port `8081` / Serverpod Insights must remain private.

## 3. Coolify environments

Coolify environments are deployment scopes inside a project. The project is the shared logical grouping, while each environment contains its own applications, databases, domains, variables and deployments.

`tug` uses this model as follows:

```text
coolify.yaml
      │
      ├── project-level identity
      │
      └── environments
          ├── production
          ├── staging
          └── preview-like named environments
```

The default environment is `production`.

A staging environment is not a second Coolify project. It is another environment inside the same project with its own resources and configuration.

For example:

```text
Coolify Project: notes
├── production
│   ├── notes-production-app
│   └── notes-production-postgres
│
└── staging
    ├── notes-staging-app
    └── notes-staging-postgres
```

By default, staging must use a separate PostgreSQL resource. Sharing production data with staging is unsafe and is not supported by the default configuration.

Each environment may use a different:

```text
Git branch
domain
database
database credentials
environment variables
secret values
deployment policy
```

The same Git repository and Coolify GitHub App can be used for all environments.

### 3.1 Environment lifecycle

`tug` treats environments as declarative resources.

If an environment is present in `coolify.yaml`, `tug apply` ensures that it exists and contains the required resources.

If an environment is removed from `coolify.yaml`, `tug plan` reports it as an orphaned managed environment, but `tug apply` must not delete it automatically. Removal requires an explicit command:

```bash
tug environment destroy staging
```

Database deletion additionally requires:

```bash
tug environment destroy staging --destroy-data
```

This prevents accidentally deleting a staging environment that still contains useful data.

### 3.2 Environment naming

Environment names must be stable, lowercase and suitable for Coolify resource names.

Recommended names:

```text
production
staging
qa
demo
```

The environment name is used in generated resource names:

```text
notes-production-app
notes-production-postgres

notes-staging-app
notes-staging-postgres
```

The environment name must not be inferred from the current Git branch after the manifest has been created. It must be explicitly declared or generated once and then committed.

### 3.3 Environment-specific domains

Each environment should normally have distinct domains:

```text
production:
  web: https://notes.example.com
  api: https://api.notes.example.com

staging:
  web: https://staging.notes.example.com
  api: https://api.staging.notes.example.com
```

Using the same domain in two environments must fail before any mutation is attempted.

### 3.4 Environment-specific branches

Each environment may track a different branch:

```text
production:
  branch: main

staging:
  branch: develop
```

A staging environment can also track a release branch:

```yaml
# yaml-language-server: $schema=https://raw.githubusercontent.com/mcquenji/tug/main/schemas/v1/coolify.schema.json
environments:
  staging:
    branch: staging
```

The branch is configured on the Coolify application for that environment. Future pushes to that branch can continue to use Coolify’s normal webhook or CI/CD deployment flow.

### 3.5 Environment-specific databases

Every environment gets its own database by default:

```text
production → notes-production-postgres
staging    → notes-staging-postgres
```

This ensures:

```text
staging migrations cannot alter production
staging test data cannot pollute production
staging resets cannot destroy production data
```

A future version may support explicitly importing a production backup into staging, but that is outside the bootstrapper’s initial scope.

## 4. Configuration scopes and contexts

Tug uses `grumpy_cli`'s default configuration service, datasource, codec, platform paths and persistence. `ConfigFiles` selects global `config.yaml` and project-local `coolify.yaml`. No Tug configuration adapter replaces Grumpy's behavior.

Resolution is **local → global → defaults**. Maps and lists replace lower-precedence values in full. Global `contexts` and `currentContext` are also valid local overrides. Context selection is **`--context` → project `context` → resolved `currentContext`**.

Context commands save globally. Project and environment commands save locally. On macOS the global file is under `~/Library/Application Support/tug/`; on Linux it uses the normal XDG configuration directory. `TUG_GLOBAL_DIR` and `TUG_LOCAL_DIR` provide explicit standard `ConfigFiles` directory overrides for isolated tests.

```yaml
# yaml-language-server: $schema=https://raw.githubusercontent.com/mcquenji/tug/main/schemas/v1/config.schema.json#/$defs/global
currentContext: home
contexts:
  home:
    url: https://coolify.example.com
    tokenEnv: COOLIFY_API_TOKEN
    server: server-uuid
    destination: destination-uuid
    githubApp: github-app-uuid
    domains:
      production:
        web: '{app}.example.com'
        api: 'api.{app}.example.com'
      default:
        web: '{environment}.{app}.example.com'
        api: 'api.{environment}.{app}.example.com'
```

A context may instead store `token` directly. `context add` prompts without echo for direct tokens; it accepts only token *references* as command-line arguments. The URL is the explicitly configured credential destination, must use HTTPS, and cannot contain embedded credentials. Redirects are not followed. API access needs read, read:sensitive, write and deploy permissions.

Sensitive local overrides are allowed. Tug warns on stderr once per setting per invocation, naming the file and field without showing values. Inactive contexts are checked too. Token environment references and ordinary settings do not warn. This warning does not change precedence or prevent the command.

The GitHub App installation remains a one-time operation in Coolify. Tug uses its UUID for private repository builds and webhooks.

## 5. Repository layout

Expected Serverpod layout:

```text
notes/
├── notes_client/
├── notes_flutter/
├── notes_server/
│
├── coolify.yaml
│
├── .coolify/
│   ├── Dockerfile
│   └── state.json
│
└── .gitignore
```

`coolify.yaml` and the Dockerfile are committed. No schema file is copied into the application repository.

`.coolify/state.json` is gitignored.

The state file contains only resource identifiers and cache information, never credentials.

Schemas live in the Tug repository. Each Tug-managed YAML file links to its corresponding hosted schema so editors, language servers, CI validation and other tools can validate it without installing `tug`. Unrelated YAML files, including Serverpod configuration, remain untouched.

## 6. Generated and offline schemas

`grumpy_gen` generates the shared config models, `schemas/v1/config.schema.json`, and `docs/configuration.md` from the annotated global and local models. The canonical schema has `$defs/global` and `$defs/local`; the local scope includes global settings, matching Grumpy precedence.

Grumpy writes scoped editor references:

```text
config.schema.json#/$defs/global  → global config.yaml
config.schema.json#/$defs/local   → project coolify.yaml
```

`coolify.schema.json` retains the manifest-facing URL as a wrapper around the local definition. `global.schema.json` and `local.schema.json` provide standalone scoped URLs. All artifacts live in Tug, not in application repositories.

`tool/generate.dart` embeds a canonical copy in the executable. Commands validate offline without fetching schemas or trusting a schema comment to choose executable validation rules. The private GitHub URLs become anonymously accessible when the owner makes Tug public; offline validation is available immediately.

### 6.1 Schema ownership

Run `fvm dart run tool/generate.dart` after changing configuration models. `fvm dart run tool/generate.dart --check` detects stale generated models, schemas, docs and the embedded copy. Versioned `v1` URLs retain version-1 semantics. Grumpy preserves existing YAML comments; semantic validation separately checks domains, ownership, topology, source versions and secret references.

### 6.2 Minimal schema example

YAML snippets elsewhere in this plan may show only part of a document. Their schema directives identify the intended full document; fragments are not standalone valid manifests.

The hosted manifest schema should validate a manifest similar to:

```yaml
# yaml-language-server: $schema=https://raw.githubusercontent.com/mcquenji/tug/main/schemas/v1/coolify.schema.json
version: 1

name: notes

source:
  repository: auto

serverpod:
  server: notes_server
  flutter: notes_flutter
  migrations: true

database:
  type: postgres
  version: 18

environments:
  production:
    branch: main
    domains:
      web: auto
      api: auto

  staging:
    branch: develop
    domains:
      web: https://staging.notes.example.com
      api: https://api.staging.notes.example.com
```

The schema rejects unknown properties and invalid value types. Semantic validation additionally rejects invalid environment names, domains, database engines and unsupported PostgreSQL versions before provisioning.

The schema should allow future manifest versions to be introduced explicitly rather than silently changing the meaning of existing fields.

## 7. `coolify.yaml`

Minimal production-only example:

```yaml
# yaml-language-server: $schema=https://raw.githubusercontent.com/mcquenji/tug/main/schemas/v1/coolify.schema.json
version: 1

name: notes

source:
  repository: auto

serverpod:
  server: notes_server
  flutter: notes_flutter
  migrations: true

database:
  type: postgres
  version: 18

environments:
  production:
    branch: main
    domains:
      web: auto
      api: auto
```

Production and staging example:

```yaml
# yaml-language-server: $schema=https://raw.githubusercontent.com/mcquenji/tug/main/schemas/v1/coolify.schema.json
version: 1

name: notes

source:
  repository: git@github.com:BenjaminMcEachnie/notes.git

serverpod:
  server: notes_server
  flutter: notes_flutter
  migrations: true

database:
  type: postgres
  version: 18

environments:
  production:
    branch: main

    domains:
      web: https://notes.mceachnie.at
      api: https://api.notes.mceachnie.at

  staging:
    branch: develop

    domains:
      web: https://staging.notes.mceachnie.at
      api: https://api.staging.notes.mceachnie.at

    env:
      FEATURE_X: "true"

    secrets:
      stripeSecretKey:
        fromEnv: STAGING_STRIPE_SECRET_KEY
```

With optional Redis:

```yaml
# yaml-language-server: $schema=https://raw.githubusercontent.com/mcquenji/tug/main/schemas/v1/coolify.schema.json
version: 1

name: notes

source:
  repository: auto

serverpod:
  server: notes_server
  flutter: notes_flutter
  migrations: true

database:
  type: postgres
  version: 18

redis:
  enabled: true

environments:
  production:
    branch: main

    domains:
      web: auto
      api: auto

  staging:
    branch: develop

    domains:
      web: auto
      api: auto
```

`repository: auto` means read the current Git remote.

`domains.*: auto` uses the domain template for the environment from the active context.

Prefer secret references in the manifest. Sensitive local overrides are allowed and produce a warning on stderr; do not commit those values.

`coolify.yaml` is **our schema**, not a native Coolify configuration format.

### 7.1 Top-level versus environment-level configuration

Top-level fields describe shared application intent:

```text
name
source.repository
serverpod.server
serverpod.flutter
database.type
database.version
redis.enabled
```

Environment-level fields describe deployment-specific values:

```text
branch
domains
env
secrets
configMode
database.name
database.user
redis settings
```

A top-level value is inherited by every environment unless an environment-specific override is supported for that field.

For example:

```yaml
# yaml-language-server: $schema=https://raw.githubusercontent.com/mcquenji/tug/main/schemas/v1/coolify.schema.json
database:
  type: postgres
  version: 18

environments:
  production:
    database:
      name: notes_production

  staging:
    database:
      name: notes_staging
```

The database engine and major version are shared by default. Database names and users may differ per environment.

## 8. Importing Serverpod runtime configuration

Serverpod 4 reads environment variables directly. Tug does not generate runtime YAML or copy native configuration into an image. It never stages or commits `config/<mode>.yaml` or `config/passwords.yaml`.

For initial provisioning, Tug reads `<server>/config/<configMode>.yaml` and `config/passwords.yaml` locally. Shared passwords are merged with the selected mode, with mode-specific values winning. Production defaults to `configMode: production`; every other environment defaults to `staging`. An explicit `configMode` selects a different import source, while every deployment still runs with `SERVERPOD_RUN_MODE=production`.

The native Serverpod datasource maps supported documented fields to their environment variables. Custom passwords retain case: `jwtSecret` becomes `SERVERPOD_PASSWORD_jwtSecret`. Unsupported fields are reported by path, with values redacted. Values which Serverpod 4.0 cannot represent through environment parsing (such as explicit null log retention values) are rejected rather than uploaded as invalid strings. Null future-call concurrency maps to the supported unlimited sentinel.

Precedence during provisioning is:

1. Tug-owned infrastructure and runtime values: database/Redis credentials and connections, service secret, ports, public domains, private Insights and deployment run options.
2. Explicit manifest `env` settings and `secrets.<name>.fromEnv` references.
3. Imported application configuration, initially filling only missing remote keys.
4. Other manually configured Coolify variables, which Tug preserves.

Reserved password aliases for `database`, `redis` and `serviceSecret` are recognized and removed or ignored so they cannot override Tug's dedicated infrastructure variables indirectly. Secrets are uploaded as literal runtime-only values (`is_runtime=true`, `is_buildtime=false`, `is_literal=true`). Only variable names appear in plans and import progress output.

`TUG_IMPORT_V1` records imported key names, source mode and completion in Coolify. A pending marker precedes the bulk upload so interrupted imports can resume without losing key ownership. Completion follows successful verification. No secret values are stored in markers or the local cache. `TUG_MANAGED_V1` tracks explicit manifest variable ownership separately; `TUG_DEPLOYMENT_PENDING` preserves deployment intent across interruptions. `TUG_DEPLOYMENT_BASELINE` identifies the preceding deployment, allowing an accepted request to be rediscovered without queuing a duplicate, including with `--no-wait`.

Normal `apply` preserves completed imports. Missing local files on another machine do not remove imported values or block an unchanged reconciliation. Updating a local source does not silently rotate a deployed secret.

```sh
tug config sync --environment production
```

Explicit synchronization refreshes keys present in the selected sources, preserves absent keys, and respects infrastructure and explicit-manifest precedence. Missing required explicit `fromEnv` references are reported before provisioning.

See the [Serverpod configuration reference](https://docs.serverpod.dev/concepts/lookups/configuration-reference) for supported runtime variables.

## 9. Database

`tug` creates a **native Coolify PostgreSQL resource per environment**, not a Postgres container hidden inside the application.

Advantages:

- separate lifecycle from application deployments
- persistent Coolify-managed storage
- internal connection URL
- health checks
- Coolify database logs
- scheduled PostgreSQL backups
- no publicly exposed `5432`
- staging and production data remain isolated

Coolify explicitly recommends applications on the same destination use the database’s internal URL. Standalone PostgreSQL resources remain private by default. ([Coolify](https://coolify.io/docs/databases/?utm_source=chatgpt.com))

Each environment’s application and database must use the same Coolify `destination_uuid`. A destination corresponds to a Docker network and allows resources on it to communicate through internal container names. ([Coolify](https://coolify.io/docs/core/networking/destinations/overview?utm_source=chatgpt.com))

The default resource layout is:

```text
production:
  notes-production-postgres
  notes-production-app

staging:
  notes-staging-postgres
  notes-staging-app
```

### Important implementation detail

Do **not** construct the database hostname manually.

After database creation, retrieve its actual Coolify connection data and extract:

```text
host
port
database
username
password
```

from the resource.

If the API does not expose every component cleanly, the Coolify adapter should handle parsing the internal PostgreSQL URL centrally. No application-level code should make assumptions about Coolify container naming.

### 9.1 Database configuration inheritance

The top-level database configuration applies to every environment:

```yaml
# yaml-language-server: $schema=https://raw.githubusercontent.com/mcquenji/tug/main/schemas/v1/coolify.schema.json
database:
  type: postgres
  version: 18
```

An environment may override the database name and user:

```yaml
# yaml-language-server: $schema=https://raw.githubusercontent.com/mcquenji/tug/main/schemas/v1/coolify.schema.json
environments:
  production:
    database:
      name: notes_production
      user: notes_production

  staging:
    database:
      name: notes_staging
      user: notes_staging
```

Changing the PostgreSQL major version is never automatic, regardless of whether the change is top-level or environment-specific.

## 10. Redis

Redis is optional and is created per environment:

```yaml
# yaml-language-server: $schema=https://raw.githubusercontent.com/mcquenji/tug/main/schemas/v1/coolify.schema.json
redis:
  enabled: true
```

If enabled, `tug` creates a native Coolify Redis resource in each enabled environment and configures:

```text
SERVERPOD_REDIS_ENABLED=true
SERVERPOD_REDIS_HOST=...
SERVERPOD_REDIS_PORT=6379
SERVERPOD_REDIS_USER=...
SERVERPOD_REDIS_PASSWORD=...
```

Redis remains private. Coolify provides an internal URL for Redis resources in the same manner as PostgreSQL. ([Coolify](https://coolify.io/docs/databases/redis?utm_source=chatgpt.com))

For personal apps, Redis should default to disabled.

An environment may disable Redis explicitly:

```yaml
# yaml-language-server: $schema=https://raw.githubusercontent.com/mcquenji/tug/main/schemas/v1/coolify.schema.json
redis:
  enabled: true

environments:
  staging:
    redis:
      enabled: false
```

Disabling Redis must not delete the existing Redis resource automatically. `tug plan` reports it as an orphaned managed resource, and deletion requires an explicit destructive command.

## 11. Reproducible Git builds

`init` and `generate` create `.coolify/Dockerfile`, `.coolify/Dockerfile.dockerignore`, and `.coolify/toolchains.json`. The toolchain file pins Flutter's version and Git revision plus the matching Dart version. The builder uses the official Dart image and verifies its checkout of the official Flutter repository. It resolves committed dependency locks with `--enforce-lockfile`.

The builder compiles Flutter web, copies it into the server's `web/app`, and uses `dart build cli` for the server executable and native assets. The final image contains the Dart runtime libraries, compiled bundle, web resources, migrations, and generated protocol YAML. It contains no native runtime configuration directory.

`serverpod.flutterBaseHref` defaults to `/app/`, matching Serverpod 4's standard FlutterRoute. Applications serving Flutter at another route must set the matching prefix (for example `/`). Environment domains remain runtime settings and do not require rebuilding Flutter.

The Dockerfile-specific ignore file preserves root ignore rules and appends exclusions for native configuration YAML, passwords, `.env` files, credential files, private keys, local caches and the Tug manifest. These exclusions apply to local Docker builds too. Keep required generated Dart code, protocol resources and migrations committed; generation does not run inside the image.

Existing files are preserved unless replacement is explicitly requested with `generate --force` or `init --force`. `apply` checks generated artifacts before provisioning. The same Dockerfile serves every environment. Coolify builds from Git with its saved runtime variables, without local source secrets.

## 12. Commands

### `tug context add`

One-time setup.

```bash
tug context add home
```

Collect/configure:

```text
Coolify URL
API token environment variable
server
default destination
GitHub App
domain templates per environment
```

Validate and save the explicitly selected credential destination without a network request. `doctor` verifies API access after configuration.

### `tug init`

Run inside a Serverpod repository.

```bash
tug init
```

Automatically detect:

```text
project name
*_server
*_flutter
Git remote
current branch
```

Generate:

```text
coolify.yaml
.coolify/Dockerfile
```

The generated manifest should contain a production environment using the current branch.

No remote resources are touched.

The generated manifest includes the hosted-schema directive. `tug init` never creates, copies, overwrites or deletes a project-local schema file.

### `tug doctor`

Validate everything without making changes.

Checks:

```text
coolify.yaml syntax
coolify.yaml against the bundled manifest schema
hosted-schema directives and format-version compatibility
machine configuration against the bundled configuration schema
Serverpod project layout
Flutter project
Dockerfile
Git remote
Coolify API authentication
server exists
destination exists
GitHub App exists
required local secret env vars exist for every environment
domains are syntactically valid
domains are unique across environments
environment names are valid
branches are valid
```

DNS resolution can be checked, but DNS modification is outside the MVP.

### `tug plan`

Calculate desired versus actual state across all environments.

Example:

```text
Project notes                         unchanged

Environment production                create
  PostgreSQL notes-production-postgres create
  Application notes-production-app     create
  Web domain                           notes.mceachnie.at
  API domain                           api.notes.mceachnie.at

Environment staging                   create
  PostgreSQL notes-staging-postgres    create
  Application notes-staging-app        create
  Web domain                           staging.notes.mceachnie.at
  API domain                           api.staging.notes.mceachnie.at

Redis                                  disabled

6 changes
```

No mutations.

### `tug apply`

```bash
tug apply
```

Reconcile Coolify with `coolify.yaml`.

By default, `tug apply` applies every environment declared in the manifest.

A single environment can be selected:

```bash
tug apply --environment staging
```

This is useful during initial staging setup or when debugging a single environment.

Running it twice with no changes must result in:

```text
No changes.
```

### `tug environment add`

Add a new environment to the manifest, using options for branch, domains and import mode:

```bash
tug environment add staging
```

This updates `coolify.yaml` and does not contact Coolify.

### `tug environment destroy`

Remove a managed environment from Coolify:

```bash
tug environment destroy staging
```

This must refuse to delete databases or persistent volumes without:

```bash
tug environment destroy staging --destroy-data
```

The declaration remains in `coolify.yaml`. Remove it explicitly after destroying an environment if future applies should not recreate it.

### `tug status`

Show all environments:

```text
Environment     Application     Database      Deployment    Web
production      running         running       finished      https://notes...
staging         running         running       finished      https://staging.notes...
```

A single environment can be selected:

```bash
tug status --environment staging
```

### `tug logs`

Convenience wrapper around Coolify deployment/application logs.

```bash
tug logs --environment staging
```

### `tug destroy`

Remove all resources managed by `tug`.

Database destruction requires:

```bash
tug destroy --destroy-data
```

`tug destroy` without that flag must refuse to delete PostgreSQL resources in every environment.

## 13. `tug apply` reconciliation algorithm

Execution order:

```text
1. Parse coolify.yaml
2. Validate coolify.yaml against the bundled schema for its manifest version
3. Validate local project
4. Authenticate with Coolify
5. Resolve server/destination/GitHub App
6. Discover existing project and environments
7. Build desired-state plan
8. Create Coolify project if missing
9. Create each declared environment if missing
10. For each environment:
    a. Resolve branch and domains
    b. Create/start PostgreSQL if missing
    c. Create/start Redis if enabled
    d. Read internal database/Redis connection details
    e. Create/update application
    f. Configure domains
    g. Configure environment variables
    h. Trigger initial deployment
    i. Poll deployment
    j. Verify API
    k. Verify web application
11. Report orphaned environments/resources
12. Write local state cache
```

Production and staging should be processed independently. A failed staging deployment must not roll back or modify production.

Coolify exposes APIs for private GitHub applications, including repository, branch, Dockerfile build pack, destination, exposed ports, domains and tags. ([Coolify](https://coolify.io/docs/api/endpoints/applications/create-private-github-app-application?utm_source=chatgpt.com))

It also exposes native PostgreSQL creation through its API. ([Coolify](https://next.coolify.io/docs/api/endpoints/databases/create-database-postgresql?utm_source=chatgpt.com))

## 14. Resource naming and ownership

Default names:

```text
project: notes

environment: production
application: notes-production-app
database: notes-production-postgres
redis: notes-production-redis

environment: staging
application: notes-staging-app
database: notes-staging-postgres
redis: notes-staging-redis
```

Resources should additionally carry identifying tags where supported:

```text
managed-by:tug
tug-app:notes
tug-environment:production
```

UUIDs returned by Coolify are cached locally:

```json
{
  "project": "...",
  "environments": {
    "production": {
      "environment": "...",
      "application": "...",
      "database": "...",
      "redis": "..."
    },
    "staging": {
      "environment": "...",
      "application": "...",
      "database": "...",
      "redis": "..."
    }
  }
}
```

This is only a cache.

If `state.json` disappears, `tug` must rediscover resources using names, tags, environment identity and repository identity.

If discovery finds multiple possible matches, `tug` fails rather than guessing.

## 15. Managed-fields rule

`tug` must **not** behave like Terraform and assume ownership of every Coolify field.

It owns only fields represented by `coolify.yaml` or required by the Serverpod deployment model.

For example, if the user manually changes:

```text
CPU limits
memory limits
Coolify UI descriptions
backup schedule
log drains
```

and those fields are not represented in the manifest, `tug apply` leaves them alone.

This makes it safe to mix the tool with occasional manual Coolify configuration.

Moving an application or database to another environment or destination is refused. Migrate explicitly outside Tug, then review the manifest and ownership before reconciling.

## 16. Domains

Internally `tug` translates:

```yaml
# yaml-language-server: $schema=https://raw.githubusercontent.com/mcquenji/tug/main/schemas/v1/coolify.schema.json
environments:
  production:
    domains:
      web: https://notes.example.com
      api: https://api.notes.example.com

  staging:
    domains:
      web: https://staging.notes.example.com
      api: https://api.staging.notes.example.com
```

into Coolify domain configurations:

```text
production:
  https://notes.example.com:8082,
  https://api.notes.example.com:8080

staging:
  https://staging.notes.example.com:8082,
  https://api.staging.notes.example.com:8080
```

Coolify then terminates HTTPS and forwards each hostname to the appropriate internal port. ([Coolify](https://coolify.io/docs/core/networking/domains?utm_source=chatgpt.com))

DNS itself is not managed.

The ideal personal setup is a wildcard record such as:

```text
*.apps.example.com → server
```

which makes new projects require zero DNS work. Coolify itself supports wildcard domains for repeatedly creating application domains. ([Coolify](https://coolify.io/docs/core/networking/domains?utm_source=chatgpt.com))

Domain templates may use environment placeholders:

```yaml
# Domain-template fragment inside a configured context.
contexts:
  home:
    domains:
      production:
        web: '{name}.apps.example.com'
        api: 'api.{name}.apps.example.com'
      default:
        web: '{environment}.{name}.apps.example.com'
        api: 'api.{environment}.{name}.apps.example.com'
```

Use a production-specific template to omit the environment prefix. Otherwise `{environment}` is replaced with the declared environment name.

`tug` must reject duplicate domains across all environments before creating or updating any application.

## 17. Migrations

Default:

```yaml
# yaml-language-server: $schema=https://raw.githubusercontent.com/mcquenji/tug/main/schemas/v1/coolify.schema.json
serverpod:
  migrations: true
```

results in:

```text
SERVERPOD_APPLY_MIGRATIONS=true
```

Serverpod 4 officially supports migration execution at server startup. ([Serverpod](https://docs.serverpod.dev/concepts/lookups/configuration-reference?utm_source=chatgpt.com))

For a single-instance personal application this is the desired behavior.

Each environment runs migrations against its own database.

Multi-instance migration coordination is outside the MVP.

## 18. Secrets

Rules:

1. Prefer global credentials and local secret references. Warn when users deliberately store sensitive overrides in `coolify.yaml`.
2. Never store them in hosted or bundled schemas.
3. Never store them in `.coolify/state.json`.
4. Never print them during normal output.
5. Never pass them through command-line arguments where they may appear in shell history.
6. Import native password files once per environment, or resolve explicit secret references from environment variables.
7. Generate internal secrets with a cryptographically secure random generator.
8. Store runtime secrets in Coolify environment variables.
9. Redact sensitive API bodies from debug logging.
10. Require separate local secret variables when production and staging should not share credentials.

The Coolify API token itself should be treated as a password. Coolify’s API permission system explicitly separates sensitive-value access from ordinary reads. ([Coolify](https://coolify.io/docs/api/permissions?utm_source=chatgpt.com))

## 19. Failure handling

`tug apply` must be safe to interrupt.

If:

```text
project created                         ✓
production environment created          ✓
production database created              ✓
production application created          ✓
production deployment finished          ✓
staging environment created             ✓
staging database created                 ✓
staging application created              ✓
staging deployment failed                ✗
```

`tug` must leave the successfully-created resources intact.

The next:

```bash
tug apply
```

continues from that state rather than creating duplicates.

A failed staging deployment must not modify production resources.

Deployment failure should automatically show the useful tail of the deployment log.

Domain collisions must fail visibly. Coolify itself returns conflicts for domains already attached to another resource; `tug` must never automatically enable force-domain-override. ([Coolify](https://coolify.io/docs/api/endpoints/applications/create-private-deploy-key-application?utm_source=chatgpt.com))

API `429` responses should respect Coolify’s `Retry-After` header. Unsafe create requests must not simply be blindly retried; rediscover state first to avoid duplicate resources. ([Coolify](https://coolify.io/docs/api/rate-limits?utm_source=chatgpt.com))

## 20. Destructive changes

These must never happen automatically:

```text
deleting environments
deleting databases
deleting persistent volumes
changing PostgreSQL major versions
recreating a database because configuration changed
moving resources between destinations
forcing conflicting domains
sharing a production database with staging
```

Changing the PostgreSQL major version should produce:

```text
ERROR: PostgreSQL major-version changes require manual migration.
```

Coolify explicitly warns that changing a production database image/major version is not itself a database migration and should only be done with a backup and an engine-specific migration plan. ([Coolify](https://coolify.io/docs/databases/configuration/general?utm_source=chatgpt.com))

Removing an environment from `coolify.yaml` must produce a plan warning:

```text
Environment staging exists remotely but is no longer declared locally.
No resources will be deleted automatically.
```

## 21. Service and datasource boundaries

`CoolifyApiService` maps typed operations and domain arguments to Coolify endpoints and request payloads, using `grumpy_io`'s network service for transport. `CoolifyDatasource` parses JSON into typed resources, connections, variables and deployments. Reconciliation only consumes these models; it does not parse API payloads. Native Serverpod configuration has its own datasource, independent of Grumpy configuration persistence.

Reads have bounded retries, including Retry-After handling. Mutations are never blindly retried. Uncertain creation responses trigger bounded ownership-based rediscovery. Deployment polling is bounded and resumable. Diagnostics suppress response bodies and redact known credentials before displaying logs.

Projects carry repository identity in a description marker. Applications and databases carry managed-by, app, environment and repository tags. Coolify's environment creation API only accepts a name, so environment ownership is checked through the verified parent project and each contained resource. Tags are fetched through the dedicated tag endpoints. Cached UUIDs never authorize mutation: every command rediscovers and verifies remote identity.

PostgreSQL and Redis connection data comes from each resource's sensitive `internal_db_url`, including percent-decoded credentials. Hostnames are never invented from resource UUIDs. Public database exposure, topology changes, repository mismatches, ambiguous matches and automatic database upgrades/recreation are refused.

Removing a manifest environment reports an orphan but never deletes it. Destruction checks all selected resources before its first mutation. Persistent data requires `--destroy-data`; `--yes` cannot bypass the requirement. Unmanaged resources are preserved, and parents are deleted only after they are empty.

## 22. Implementation language

Use Dart.

Reasons:

```text
same ecosystem as Serverpod
single native executable
cross-platform
easy YAML parsing
easy process/Git inspection
easy reuse of Serverpod conventions
```

Use the Grumpy Git dependencies consistently: `grumpy_cli` for commands, modules, dependency injection and default configuration; `grumpy_io` for transport; `grumpy_gen` for configuration artifacts; and `grumpy_lints` for architecture checks. Packages resolve from their `mcquenji` GitHub repositories, including transitive Grumpy core and annotations. The lockfile records their resolved revisions, and the analyzer plugin also uses Git. No sibling checkouts or local dependency overrides are required.

Implementation layout:

```text
lib/
├── gen/                # embedded canonical schemas
└── src/
    ├── app/            # root App, configuration models and common command preflight
    ├── configuration/  # explicit runtime-configuration synchronization
    ├── context/        # global Coolify context commands and selection
    ├── coolify/        # API service, response datasource and typed remote models
    ├── environment/    # named environment commands
    ├── reconcile/      # deployment commands, ownership and reconciliation
    ├── serverpod/      # native runtime-configuration import datasource
    └── workspace/      # initialization, generation, layout validation and ID cache
```

Follow EduPlanner's feature-module structure. Each feature has a root `<feature>.dart` module that declares its dependencies, binds its own services/datasources, and exposes its routes. Domain, infrastructure, presentation and utility directories expose barrel files, including type-specific barrels such as `models/models.dart` and `commands/commands.dart`. Cross-feature imports use the feature entry points; infrastructure remains an explicit internal import.

Commands live in their owning feature's `presentation/commands`, one command per class and file. `TugCommand` supplies shared configuration preflight and `DeploymentCommand` resolves a deployment specification. The root `App` composes modules instead of dispatching action strings. `bin/tug.dart` starts it. Grumpy generates `app/domain/models/app_config.g.dart`; its default configuration services and scope resolution remain unchanged.

## 23. MVP scope

The first version supports exactly:

```text
Serverpod 4
Flutter Web / PWA
one Serverpod instance per environment
PostgreSQL per environment
optional Redis per environment
private GitHub repositories through existing Coolify GitHub App
one Coolify server
one Coolify project
production environment
additional named staging environments
HTTPS domains
Dockerfile builds
initial deployments
idempotent reconciliation
Tug-hosted JSON Schemas linked from every Tug-managed YAML file
bundled schemas for offline CLI validation
```

Explicitly **not included**:

```text
CI/CD configuration
Cloudflare/DNS modification
automatic preview environments per pull request
multiple Serverpod replicas
Kubernetes
generic Docker projects
rollback orchestration
secret rotation
automatic PostgreSQL upgrades
database restore
multiple Flutter apps
Serverpod Insights exposure
automatic production-to-staging database cloning
```

Named staging environments are included. Fully automatic preview environments are not.

## 24. Acceptance criteria

The MVP is done when this works on a fresh Serverpod project:

```bash
serverpod create notes
cd notes

tug init
tug apply
```

without opening the Coolify dashboard for project-specific setup.

Afterward:

```text
✓ project exists
✓ no schema file was copied into the application repository
✓ every Tug-managed YAML file links to its corresponding Tug-hosted schema
✓ bundled schemas work offline; hosted URLs become public when Tug is published
✓ coolify.yaml validates against the bundled manifest schema offline
✓ production environment exists
✓ PostgreSQL is running
✓ PostgreSQL is private
✓ Serverpod is running
✓ migrations were applied
✓ Flutter PWA loads
✓ API is reachable
✓ Flutter receives correct API URL
✓ HTTPS works
✓ no imported runtime secrets or native password files were staged or committed by Tug
```

Adding staging should work with:

```bash
tug environment add staging
tug apply
```

or by editing `coolify.yaml`:

```yaml
# yaml-language-server: $schema=https://raw.githubusercontent.com/mcquenji/tug/main/schemas/v1/coolify.schema.json
environments:
  production:
    branch: main
    domains:
      web: https://notes.example.com
      api: https://api.notes.example.com

  staging:
    branch: develop
    domains:
      web: https://staging.notes.example.com
      api: https://api.staging.notes.example.com
```

After applying:

```text
✓ staging environment exists
✓ staging has its own application
✓ staging has its own PostgreSQL resource
✓ staging uses the develop branch
✓ staging has distinct domains
✓ staging secrets are separate from production
✓ staging migrations target only the staging database
```

Running:

```bash
tug apply
```

again must produce:

```text
No changes.
```

Removing `.coolify/state.json` and running `tug apply` must rediscover the deployment rather than duplicate it.

A failed deployment must return a non-zero exit code and useful logs.

`tug destroy` must not be able to delete PostgreSQL data without an explicit destructive flag.

Removing `staging` from `coolify.yaml` must not delete the remote staging environment automatically.

## 25. Recommended development order

**Phase 1 — Read only**

Implement:

```text
context
manifest parsing
canonical schemas and publication in the Tug repository
hosted-schema directives in generated YAML
bundled schema validation
Coolify API client
environment discovery
doctor
resource discovery
plan
```

No mutations.

**Phase 2 — Production provisioning**

Implement:

```text
project creation
production environment creation
PostgreSQL
application
environment variables
domains
initial deployment
```

At this point the tool is already useful.

**Phase 3 — Staging environments**

Implement:

```text
named environment parsing
environment-specific branches
environment-specific domains
database per environment
environment-specific secrets
environment-specific status and logs
```

**Phase 4 — Reliability**

Add:

```text
state recovery
idempotency tests
deployment polling
error/log reporting
rate-limit handling
domain conflict detection
safe destroy
orphaned environment reporting
```

**Phase 5 — Nice-to-haves**

Only after actually using it:

```text
Redis
backup configuration
schema migration tooling
shell completion
automatic preview environments
generic Docker workloads
```

## 26. Release validation

Local checks cover Grumpy precedence and scoped writes, sensitive-value warnings, canonical offline schemas, native import mappings and merging, reserved aliases, reconciliation against a stateful HTTP fake, Redis, idempotency, lost caches, partial failures, manual settings and destruction guards.

Required release commands use FVM:

```sh
fvm dart run tool/generate.dart --check
fvm dart analyze --fatal-infos
fvm dart test
fvm dart compile exe bin/tug.dart -o build/tug
```

Validate a clean checkout's Docker build and environment-only runtime with PostgreSQL, migrations, Redis, Flutter assets and an API call. Inspect the image to ensure no runtime YAML or passwords were included.

Live validation uses a fresh disposable Serverpod 4 fixture on a temporary Tug branch. It targets the Projects server at `test.mcquenji.dev` and `api-test.mcquenji.dev`, after explicitly configuring the API credential destination. Use Coolify MCP for discovery and monitoring and Tug's REST adapter for provisioning. Verify internal database connections, HTTPS, runtime import persistence, repeated apply and cache recovery; then remove all test resources, volumes, branches and scratch files. Check DNS/ingress without modifying DNS.

The existing EduPlanner repositories are unsupported Serverpod 3/split-layout diagnostics only. Their files and existing edits must remain unchanged. See `docs/verification.md` for the completed checks and any remaining release conditions.

---

# Final design

The core model is:

```text
coolify.yaml (links to Tug-hosted schema)
          │
          ▼
         tug
          │
          ▼
   Coolify REST API
          │
          ├── Coolify Project
          │      │
          │      ├── production Environment
          │      │      ├── Application
          │      │      │      ├── :8080 Serverpod API
          │      │      │      └── :8082 Flutter PWA
          │      │      └── PostgreSQL
          │      │
          │      └── staging Environment
          │             ├── Application
          │             │      ├── :8080 Serverpod API
          │             │      └── :8082 Flutter PWA
          │             └── PostgreSQL
          │
          └── optional Redis per environment
```

Coolify owns infrastructure.

Serverpod owns the application.

`coolify.yaml` owns the desired deployment model.

Tug-hosted schemas document the YAML formats and provide editor validation through schema links. Bundled copies provide offline CLI validation without project-local schema files.

`tug` owns only the boring glue between them.
