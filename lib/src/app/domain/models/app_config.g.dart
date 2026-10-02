// GENERATED CODE - DO NOT MODIFY BY HAND.

import 'package:grumpy_cli/grumpy_cli.dart';
import "package:tug/src/app/domain/models/domain_config.dart" as _c0;
import "package:tug/src/app/domain/models/coolify_context.dart" as _c1;
import "package:tug/src/app/domain/models/database_config.dart" as _c2;
import "package:tug/src/app/domain/models/database_override.dart" as _c3;
import "package:tug/src/app/domain/models/environment_variables.dart" as _c4;
import "package:tug/src/app/domain/models/redis_config.dart" as _c5;
import "package:tug/src/app/domain/models/secret_reference.dart" as _c6;
import "package:tug/src/app/domain/models/environment_config.dart" as _c7;
import "package:tug/src/app/domain/models/serverpod_config.dart" as _c8;
import "package:tug/src/app/domain/models/source_config.dart" as _c9;
import "package:tug/src/app/domain/models/global_config.dart" as _c10;
import "package:tug/src/app/domain/models/local_config.dart" as _c11;

/// Immutable configuration resolved for the current application invocation.
final class AppConfig extends CliConfig<AppConfig>
    implements _c10.GlobalConfig, _c11.LocalConfig {
  AppConfig._({
    required this.contexts,
    required this.currentContext,
    required this.database,
    required this.environments,
    required this.name,
    required this.redis,
    required this.serverpod,
    required this.source,
    required this.version,
  });

  /// Resolves the configuration registered by your root module.
  factory AppConfig() => RootModule.getConfig<AppConfig>();

  /// Creates a snapshot using the defaults declared by your config models.
  factory AppConfig.defaults() => AppConfig._(
    contexts: settings.contexts.defaultValue as Map<String, _c1.CoolifyContext>,
    currentContext: settings.currentContext.defaultValue as String?,
    database: settings.database.defaultValue as _c2.DatabaseConfig,
    environments:
        settings.environments.defaultValue
            as Map<String, _c7.EnvironmentConfig>,
    name: settings.name.defaultValue as String?,
    redis: settings.redis.defaultValue as _c5.RedisConfig,
    serverpod: settings.serverpod.defaultValue as _c8.ServerpodConfig?,
    source: settings.source.defaultValue as _c9.SourceConfig,
    version: settings.version.defaultValue as int,
  );

  /// Typed handles for explicit scope writes, provenance and shared value types.
  static final settings = AppConfigSettings();

  /// Named global Coolify connections; keep credentials out of the shared manifest.
  @override
  final Map<String, _c1.CoolifyContext> contexts;

  /// Default connection profile when no project or command selects one.
  @override
  final String? currentContext;

  /// PostgreSQL engine and major version for newly created databases.
  @override
  final _c2.DatabaseConfig database;

  /// Named, isolated deployments with their own branches, databases and runtime settings.
  @override
  final Map<String, _c7.EnvironmentConfig> environments;

  /// Stable project name used to identify managed resources.
  @override
  final String? name;

  /// Default Redis setting for all environments; individual environments can override it.
  @override
  final _c5.RedisConfig redis;

  /// Serverpod and Flutter package paths and build options. Omit to discover
  /// the packages automatically and use the default build options.
  @override
  final _c8.ServerpodConfig? serverpod;

  /// Git repository shared by all deployment environments.
  @override
  final _c9.SourceConfig source;

  /// Manifest format version.
  @override
  final int version;
  @override
  ConfigSchema get configSchema => _schema;
  static final _schema = ConfigSchema(
    global: [settings.contexts, settings.currentContext],
    local: [
      settings.database,
      settings.environments,
      settings.name,
      settings.redis,
      settings.serverpod,
      settings.source,
      settings.version,
    ],
    schemaUri: Uri.parse(
      "https://raw.githubusercontent.com/mcquenji/tug/main/schemas/v1/config.schema.json",
    ),
  );

  @override
  AppConfig resolveConfig(ConfigService service) => AppConfig._(
    contexts: service.get(settings.contexts) as Map<String, _c1.CoolifyContext>,
    currentContext: service.get(settings.currentContext) as String?,
    database: service.get(settings.database) as _c2.DatabaseConfig,
    environments: service.get(
      settings.environments,
    ) as Map<String, _c7.EnvironmentConfig>,
    name: service.get(settings.name) as String?,
    redis: service.get(settings.redis) as _c5.RedisConfig,
    serverpod: service.get(settings.serverpod) as _c8.ServerpodConfig?,
    source: service.get(settings.source) as _c9.SourceConfig,
    version: service.get(settings.version) as int,
  );
}

/// Generated typed setting declarations; use AppConfig.settings.
final class AppConfigSettings extends Model {
  /// Creates the generated settings collection.
  AppConfigSettings();

  /// Named global Coolify connections; keep credentials out of the shared manifest.
  final contexts = ConfigSetting<Map<String, _c1.CoolifyContext>>(
    "contexts",
    type: CliValueType.map(
      CliValueType.object<_c1.CoolifyContext>(
        properties: {
          "destination": CliValueType.string(),
          "domains": CliValueType.map(
            CliValueType.object<_c0.DomainConfig>(
              properties: {
                "api": CliValueType.string(),
                "web": CliValueType.string(),
              },
              fromJson: (json) => _c0.DomainConfig(
                api: CliValueType.string().decode(
                  json.containsKey("api") ? json["api"] : "auto",
                ),
                web: CliValueType.string().decode(
                  json.containsKey("web") ? json["web"] : "auto",
                ),
              ),
              toJson: (value) => {
                "api": CliValueType.string().encode(value.api),
                "web": CliValueType.string().encode(value.web),
              },
            ).constrained({
              "properties": {
                "api": {
                  "type": "string",
                  "description": "Public API hostname or HTTPS origin without a port or path. Supports {app},\n{name}, {environment} and {env} placeholders. auto prompts for a hostname\nand saves it in .coolify/local.yaml.",
                  "default": "auto",
                },
                "web": {
                  "type": "string",
                  "description": "Public web hostname or HTTPS origin without a port or path. Supports {app},\n{name}, {environment} and {env} placeholders. auto prompts for a hostname\nand saves it in .coolify/local.yaml.",
                  "default": "auto",
                },
              },
            }),
          ),
          "githubApp": CliValueType.string(),
          "server": CliValueType.string(),
          "token": CliValueType.string().nullable(),
          "tokenEnv": CliValueType.string().nullable(),
          "url": CliValueType.string(),
        },
        fromJson: (json) => _c1.CoolifyContext(
          destination: CliValueType.string().decode(
            json.containsKey("destination") ? json["destination"] : "",
          ),
          domains: CliValueType.map(
            CliValueType.object<_c0.DomainConfig>(
              properties: {
                "api": CliValueType.string(),
                "web": CliValueType.string(),
              },
              fromJson: (json) => _c0.DomainConfig(
                api: CliValueType.string().decode(
                  json.containsKey("api") ? json["api"] : "auto",
                ),
                web: CliValueType.string().decode(
                  json.containsKey("web") ? json["web"] : "auto",
                ),
              ),
              toJson: (value) => {
                "api": CliValueType.string().encode(value.api),
                "web": CliValueType.string().encode(value.web),
              },
            ).constrained({
              "properties": {
                "api": {
                  "type": "string",
                  "description": "Public API hostname or HTTPS origin without a port or path. Supports {app},\n{name}, {environment} and {env} placeholders. auto prompts for a hostname\nand saves it in .coolify/local.yaml.",
                  "default": "auto",
                },
                "web": {
                  "type": "string",
                  "description": "Public web hostname or HTTPS origin without a port or path. Supports {app},\n{name}, {environment} and {env} placeholders. auto prompts for a hostname\nand saves it in .coolify/local.yaml.",
                  "default": "auto",
                },
              },
            }),
          ).decode(json.containsKey("domains") ? json["domains"] : {}),
          githubApp: CliValueType.string().decode(
            json.containsKey("githubApp") ? json["githubApp"] : "",
          ),
          server: CliValueType.string().decode(
            json.containsKey("server") ? json["server"] : "",
          ),
          token: CliValueType.string().nullable().decode(
            json.containsKey("token") ? json["token"] : null,
          ),
          tokenEnv: CliValueType.string().nullable().decode(
            json.containsKey("tokenEnv") ? json["tokenEnv"] : null,
          ),
          url: CliValueType.string().decode(
            json.containsKey("url") ? json["url"] : "",
          ),
        ),
        toJson: (value) => {
          "destination": CliValueType.string().encode(value.destination),
          "domains": CliValueType.map(
            CliValueType.object<_c0.DomainConfig>(
              properties: {
                "api": CliValueType.string(),
                "web": CliValueType.string(),
              },
              fromJson: (json) => _c0.DomainConfig(
                api: CliValueType.string().decode(
                  json.containsKey("api") ? json["api"] : "auto",
                ),
                web: CliValueType.string().decode(
                  json.containsKey("web") ? json["web"] : "auto",
                ),
              ),
              toJson: (value) => {
                "api": CliValueType.string().encode(value.api),
                "web": CliValueType.string().encode(value.web),
              },
            ).constrained({
              "properties": {
                "api": {
                  "type": "string",
                  "description": "Public API hostname or HTTPS origin without a port or path. Supports {app},\n{name}, {environment} and {env} placeholders. auto prompts for a hostname\nand saves it in .coolify/local.yaml.",
                  "default": "auto",
                },
                "web": {
                  "type": "string",
                  "description": "Public web hostname or HTTPS origin without a port or path. Supports {app},\n{name}, {environment} and {env} placeholders. auto prompts for a hostname\nand saves it in .coolify/local.yaml.",
                  "default": "auto",
                },
              },
            }),
          ).encode(value.domains),
          "githubApp": CliValueType.string().encode(value.githubApp),
          "server": CliValueType.string().encode(value.server),
          "token": CliValueType.string().nullable().encode(value.token),
          "tokenEnv": CliValueType.string().nullable().encode(value.tokenEnv),
          "url": CliValueType.string().encode(value.url),
        },
      ).constrained({
        "properties": {
          "destination": {
            "type": "string",
            "description": "Default Coolify destination UUID. Selecting a server also selects one of\nits destinations; a different server does not inherit this destination.\nThe checkout's choice is saved in .coolify/local.yaml.",
            "default": "",
          },
          "domains": {
            "type": "object",
            "additionalProperties": {
              "type": "object",
              "properties": {
                "api": {
                  "type": "string",
                  "description": "Public API hostname or HTTPS origin without a port or path. Supports {app},\n{name}, {environment} and {env} placeholders. auto prompts for a hostname\nand saves it in .coolify/local.yaml.",
                  "default": "auto",
                },
                "web": {
                  "type": "string",
                  "description": "Public web hostname or HTTPS origin without a port or path. Supports {app},\n{name}, {environment} and {env} placeholders. auto prompts for a hostname\nand saves it in .coolify/local.yaml.",
                  "default": "auto",
                },
              },
              "additionalProperties": false,
            },
            "description": "Public web/API hostname templates keyed by environment name. The default\nentry supplies a fallback; .coolify/local.yaml overrides these per checkout.",
            "default": {},
          },
          "githubApp": {
            "type": "string",
            "description": "Coolify GitHub App identifier used to access the repository. When empty,\ndeployment commands prompt for an App and save it in .coolify/local.yaml.",
            "default": "",
          },
          "server": {
            "type": "string",
            "description": "Default Coolify server UUID. Interactive deployment commands confirm the\nserver on first use of each checkout and save it in .coolify/local.yaml.\nUse --select-server to choose again. Unattended commands may use this default.",
            "default": "",
          },
          "token": {
            "anyOf": [
              {"type": "string"},
              {"type": "null"},
            ],
            "description": "Coolify API token stored in this private profile. Use either token or tokenEnv.",
            "default": null,
          },
          "tokenEnv": {
            "anyOf": [
              {"type": "string"},
              {"type": "null"},
            ],
            "description": "Environment variable containing the Coolify API token. Read from the shell or\n.env unless --no-env-file is set; shell values take precedence. Use either\ntokenEnv or token.",
            "default": null,
          },
          "url": {
            "type": "string",
            "description": "HTTPS base URL of the Coolify instance, for example https://coolify.example.com.",
            "default": "",
          },
        },
      }),
    ),
    description: "Named global Coolify connections; keep credentials out of the shared manifest.",
    defaultValue: CliValueType.map(
      CliValueType.object<_c1.CoolifyContext>(
        properties: {
          "destination": CliValueType.string(),
          "domains": CliValueType.map(
            CliValueType.object<_c0.DomainConfig>(
              properties: {
                "api": CliValueType.string(),
                "web": CliValueType.string(),
              },
              fromJson: (json) => _c0.DomainConfig(
                api: CliValueType.string().decode(
                  json.containsKey("api") ? json["api"] : "auto",
                ),
                web: CliValueType.string().decode(
                  json.containsKey("web") ? json["web"] : "auto",
                ),
              ),
              toJson: (value) => {
                "api": CliValueType.string().encode(value.api),
                "web": CliValueType.string().encode(value.web),
              },
            ).constrained({
              "properties": {
                "api": {
                  "type": "string",
                  "description": "Public API hostname or HTTPS origin without a port or path. Supports {app},\n{name}, {environment} and {env} placeholders. auto prompts for a hostname\nand saves it in .coolify/local.yaml.",
                  "default": "auto",
                },
                "web": {
                  "type": "string",
                  "description": "Public web hostname or HTTPS origin without a port or path. Supports {app},\n{name}, {environment} and {env} placeholders. auto prompts for a hostname\nand saves it in .coolify/local.yaml.",
                  "default": "auto",
                },
              },
            }),
          ),
          "githubApp": CliValueType.string(),
          "server": CliValueType.string(),
          "token": CliValueType.string().nullable(),
          "tokenEnv": CliValueType.string().nullable(),
          "url": CliValueType.string(),
        },
        fromJson: (json) => _c1.CoolifyContext(
          destination: CliValueType.string().decode(
            json.containsKey("destination") ? json["destination"] : "",
          ),
          domains: CliValueType.map(
            CliValueType.object<_c0.DomainConfig>(
              properties: {
                "api": CliValueType.string(),
                "web": CliValueType.string(),
              },
              fromJson: (json) => _c0.DomainConfig(
                api: CliValueType.string().decode(
                  json.containsKey("api") ? json["api"] : "auto",
                ),
                web: CliValueType.string().decode(
                  json.containsKey("web") ? json["web"] : "auto",
                ),
              ),
              toJson: (value) => {
                "api": CliValueType.string().encode(value.api),
                "web": CliValueType.string().encode(value.web),
              },
            ).constrained({
              "properties": {
                "api": {
                  "type": "string",
                  "description": "Public API hostname or HTTPS origin without a port or path. Supports {app},\n{name}, {environment} and {env} placeholders. auto prompts for a hostname\nand saves it in .coolify/local.yaml.",
                  "default": "auto",
                },
                "web": {
                  "type": "string",
                  "description": "Public web hostname or HTTPS origin without a port or path. Supports {app},\n{name}, {environment} and {env} placeholders. auto prompts for a hostname\nand saves it in .coolify/local.yaml.",
                  "default": "auto",
                },
              },
            }),
          ).decode(json.containsKey("domains") ? json["domains"] : {}),
          githubApp: CliValueType.string().decode(
            json.containsKey("githubApp") ? json["githubApp"] : "",
          ),
          server: CliValueType.string().decode(
            json.containsKey("server") ? json["server"] : "",
          ),
          token: CliValueType.string().nullable().decode(
            json.containsKey("token") ? json["token"] : null,
          ),
          tokenEnv: CliValueType.string().nullable().decode(
            json.containsKey("tokenEnv") ? json["tokenEnv"] : null,
          ),
          url: CliValueType.string().decode(
            json.containsKey("url") ? json["url"] : "",
          ),
        ),
        toJson: (value) => {
          "destination": CliValueType.string().encode(value.destination),
          "domains": CliValueType.map(
            CliValueType.object<_c0.DomainConfig>(
              properties: {
                "api": CliValueType.string(),
                "web": CliValueType.string(),
              },
              fromJson: (json) => _c0.DomainConfig(
                api: CliValueType.string().decode(
                  json.containsKey("api") ? json["api"] : "auto",
                ),
                web: CliValueType.string().decode(
                  json.containsKey("web") ? json["web"] : "auto",
                ),
              ),
              toJson: (value) => {
                "api": CliValueType.string().encode(value.api),
                "web": CliValueType.string().encode(value.web),
              },
            ).constrained({
              "properties": {
                "api": {
                  "type": "string",
                  "description": "Public API hostname or HTTPS origin without a port or path. Supports {app},\n{name}, {environment} and {env} placeholders. auto prompts for a hostname\nand saves it in .coolify/local.yaml.",
                  "default": "auto",
                },
                "web": {
                  "type": "string",
                  "description": "Public web hostname or HTTPS origin without a port or path. Supports {app},\n{name}, {environment} and {env} placeholders. auto prompts for a hostname\nand saves it in .coolify/local.yaml.",
                  "default": "auto",
                },
              },
            }),
          ).encode(value.domains),
          "githubApp": CliValueType.string().encode(value.githubApp),
          "server": CliValueType.string().encode(value.server),
          "token": CliValueType.string().nullable().encode(value.token),
          "tokenEnv": CliValueType.string().nullable().encode(value.tokenEnv),
          "url": CliValueType.string().encode(value.url),
        },
      ).constrained({
        "properties": {
          "destination": {
            "type": "string",
            "description": "Default Coolify destination UUID. Selecting a server also selects one of\nits destinations; a different server does not inherit this destination.\nThe checkout's choice is saved in .coolify/local.yaml.",
            "default": "",
          },
          "domains": {
            "type": "object",
            "additionalProperties": {
              "type": "object",
              "properties": {
                "api": {
                  "type": "string",
                  "description": "Public API hostname or HTTPS origin without a port or path. Supports {app},\n{name}, {environment} and {env} placeholders. auto prompts for a hostname\nand saves it in .coolify/local.yaml.",
                  "default": "auto",
                },
                "web": {
                  "type": "string",
                  "description": "Public web hostname or HTTPS origin without a port or path. Supports {app},\n{name}, {environment} and {env} placeholders. auto prompts for a hostname\nand saves it in .coolify/local.yaml.",
                  "default": "auto",
                },
              },
              "additionalProperties": false,
            },
            "description": "Public web/API hostname templates keyed by environment name. The default\nentry supplies a fallback; .coolify/local.yaml overrides these per checkout.",
            "default": {},
          },
          "githubApp": {
            "type": "string",
            "description": "Coolify GitHub App identifier used to access the repository. When empty,\ndeployment commands prompt for an App and save it in .coolify/local.yaml.",
            "default": "",
          },
          "server": {
            "type": "string",
            "description": "Default Coolify server UUID. Interactive deployment commands confirm the\nserver on first use of each checkout and save it in .coolify/local.yaml.\nUse --select-server to choose again. Unattended commands may use this default.",
            "default": "",
          },
          "token": {
            "anyOf": [
              {"type": "string"},
              {"type": "null"},
            ],
            "description": "Coolify API token stored in this private profile. Use either token or tokenEnv.",
            "default": null,
          },
          "tokenEnv": {
            "anyOf": [
              {"type": "string"},
              {"type": "null"},
            ],
            "description": "Environment variable containing the Coolify API token. Read from the shell or\n.env unless --no-env-file is set; shell values take precedence. Use either\ntokenEnv or token.",
            "default": null,
          },
          "url": {
            "type": "string",
            "description": "HTTPS base URL of the Coolify instance, for example https://coolify.example.com.",
            "default": "",
          },
        },
      }),
    ).decode({}),
    examples: [],
    hasDefault: true,
    deprecated: false,
  );

  /// Default connection profile when no project or command selects one.
  final currentContext = ConfigSetting<String?>(
    "currentContext",
    type: CliValueType.string().nullable(),
    description:
        "Default connection profile when no project or command selects one.",
    defaultValue: CliValueType.string().nullable().decode(null),
    examples: [],
    hasDefault: true,
    deprecated: false,
  );

  /// PostgreSQL engine and major version for newly created databases.
  final database = ConfigSetting<_c2.DatabaseConfig>(
    "database",
    type:
        CliValueType.object<_c2.DatabaseConfig>(
          properties: {
            "type": CliValueType.string(),
            "version": CliValueType.integer(),
          },
          fromJson: (json) => _c2.DatabaseConfig(
            type: CliValueType.string().decode(
              json.containsKey("type") ? json["type"] : "postgres",
            ),
            version: CliValueType.integer().decode(
              json.containsKey("version") ? json["version"] : 18,
            ),
          ),
          toJson: (value) => {
            "type": CliValueType.string().encode(value.type),
            "version": CliValueType.integer().encode(value.version),
          },
        ).constrained({
          "properties": {
            "type": {
              "type": "string",
              "description":
                  "Database engine. Currently only postgres is supported.",
              "default": "postgres",
            },
            "version": {
              "type": "integer",
              "description": "PostgreSQL major version for new databases: 16, 17 or 18. Tug never\nautomatically upgrades an existing database.",
              "default": 18,
            },
          },
        }),
    description:
        "PostgreSQL engine and major version for newly created databases.",
    defaultValue:
        CliValueType.object<_c2.DatabaseConfig>(
              properties: {
                "type": CliValueType.string(),
                "version": CliValueType.integer(),
              },
              fromJson: (json) => _c2.DatabaseConfig(
                type: CliValueType.string().decode(
                  json.containsKey("type") ? json["type"] : "postgres",
                ),
                version: CliValueType.integer().decode(
                  json.containsKey("version") ? json["version"] : 18,
                ),
              ),
              toJson: (value) => {
                "type": CliValueType.string().encode(value.type),
                "version": CliValueType.integer().encode(value.version),
              },
            )
            .constrained({
              "properties": {
                "type": {
                  "type": "string",
                  "description":
                      "Database engine. Currently only postgres is supported.",
                  "default": "postgres",
                },
                "version": {
                  "type": "integer",
                  "description": "PostgreSQL major version for new databases: 16, 17 or 18. Tug never\nautomatically upgrades an existing database.",
                  "default": 18,
                },
              },
            })
            .decode({"type": "postgres", "version": 18}),
    examples: [],
    hasDefault: true,
    deprecated: false,
  );

  /// Named, isolated deployments with their own branches, databases and runtime settings.
  final environments = ConfigSetting<Map<String, _c7.EnvironmentConfig>>(
    "environments",
    type: CliValueType.map(
      CliValueType.object<_c7.EnvironmentConfig>(
        properties: {
          "branch": CliValueType.string(),
          "configMode": CliValueType.string().nullable(),
          "database":
              CliValueType.object<_c3.DatabaseOverride>(
                properties: {
                  "name": CliValueType.string().nullable(),
                  "user": CliValueType.string().nullable(),
                },
                fromJson: (json) => _c3.DatabaseOverride(
                  name: CliValueType.string().nullable().decode(
                    json.containsKey("name") ? json["name"] : null,
                  ),
                  user: CliValueType.string().nullable().decode(
                    json.containsKey("user") ? json["user"] : null,
                  ),
                ),
                toJson: (value) => {
                  "name": CliValueType.string().nullable().encode(value.name),
                  "user": CliValueType.string().nullable().encode(value.user),
                },
              ).constrained({
                "properties": {
                  "name": {
                    "anyOf": [
                      {"type": "string"},
                      {"type": "null"},
                    ],
                    "description": "Initial PostgreSQL database name. Defaults to the project name with hyphens\nreplaced by underscores; does not rename an existing database.",
                    "default": null,
                  },
                  "user": {
                    "anyOf": [
                      {"type": "string"},
                      {"type": "null"},
                    ],
                    "description": "Initial PostgreSQL username. Defaults to the database name; does not rename\nan existing database user.",
                    "default": null,
                  },
                },
              }),
          "env": _c4.environmentVariablesType(),
          "redis":
              CliValueType.object<_c5.RedisConfig>(
                properties: {"enabled": CliValueType.boolean()},
                fromJson: (json) => _c5.RedisConfig(
                  enabled: CliValueType.boolean().decode(
                    json.containsKey("enabled") ? json["enabled"] : false,
                  ),
                ),
                toJson: (value) => {
                  "enabled": CliValueType.boolean().encode(value.enabled),
                },
              ).constrained({
                "properties": {
                  "enabled": {
                    "type": "boolean",
                    "description": "Create and manage a private Redis instance for each enabled environment.",
                    "default": false,
                  },
                },
              }).nullable(),
          "resourceName": CliValueType.string().nullable(),
          "secrets": CliValueType.map(
            CliValueType.object<_c6.SecretReference>(
              properties: {"fromEnv": CliValueType.string()},
              fromJson: (json) => _c6.SecretReference(
                fromEnv: CliValueType.string().decode(
                  json.containsKey("fromEnv") ? json["fromEnv"] : "",
                ),
              ),
              toJson: (value) => {
                "fromEnv": CliValueType.string().encode(value.fromEnv),
              },
            ).constrained({
              "properties": {
                "fromEnv": {
                  "type": "string",
                  "description": "Name of the variable supplying this runtime value. Read from the shell\nor .env unless --no-env-file is set; shell values take precedence. The value\nis never written to the shared manifest.",
                  "default": "",
                },
              },
            }),
          ),
        },
        fromJson: (json) => _c7.EnvironmentConfig(
          branch: CliValueType.string().decode(
            json.containsKey("branch") ? json["branch"] : "main",
          ),
          configMode: CliValueType.string().nullable().decode(
            json.containsKey("configMode") ? json["configMode"] : null,
          ),
          database:
              CliValueType.object<_c3.DatabaseOverride>(
                    properties: {
                      "name": CliValueType.string().nullable(),
                      "user": CliValueType.string().nullable(),
                    },
                    fromJson: (json) => _c3.DatabaseOverride(
                      name: CliValueType.string().nullable().decode(
                        json.containsKey("name") ? json["name"] : null,
                      ),
                      user: CliValueType.string().nullable().decode(
                        json.containsKey("user") ? json["user"] : null,
                      ),
                    ),
                    toJson: (value) => {
                      "name": CliValueType.string().nullable().encode(
                        value.name,
                      ),
                      "user": CliValueType.string().nullable().encode(
                        value.user,
                      ),
                    },
                  )
                  .constrained({
                    "properties": {
                      "name": {
                        "anyOf": [
                          {"type": "string"},
                          {"type": "null"},
                        ],
                        "description": "Initial PostgreSQL database name. Defaults to the project name with hyphens\nreplaced by underscores; does not rename an existing database.",
                        "default": null,
                      },
                      "user": {
                        "anyOf": [
                          {"type": "string"},
                          {"type": "null"},
                        ],
                        "description": "Initial PostgreSQL username. Defaults to the database name; does not rename\nan existing database user.",
                        "default": null,
                      },
                    },
                  })
                  .decode(
                    json.containsKey("database")
                        ? json["database"]
                        : {"name": null, "user": null},
                  ),
          env: _c4.environmentVariablesType().decode(
            json.containsKey("env") ? json["env"] : {},
          ),
          redis:
              CliValueType.object<_c5.RedisConfig>(
                    properties: {"enabled": CliValueType.boolean()},
                    fromJson: (json) => _c5.RedisConfig(
                      enabled: CliValueType.boolean().decode(
                        json.containsKey("enabled") ? json["enabled"] : false,
                      ),
                    ),
                    toJson: (value) => {
                      "enabled": CliValueType.boolean().encode(value.enabled),
                    },
                  )
                  .constrained({
                    "properties": {
                      "enabled": {
                        "type": "boolean",
                        "description": "Create and manage a private Redis instance for each enabled environment.",
                        "default": false,
                      },
                    },
                  })
                  .nullable()
                  .decode(json.containsKey("redis") ? json["redis"] : null),
          resourceName: CliValueType.string().nullable().decode(
            json.containsKey("resourceName") ? json["resourceName"] : null,
          ),
          secrets: CliValueType.map(
            CliValueType.object<_c6.SecretReference>(
              properties: {"fromEnv": CliValueType.string()},
              fromJson: (json) => _c6.SecretReference(
                fromEnv: CliValueType.string().decode(
                  json.containsKey("fromEnv") ? json["fromEnv"] : "",
                ),
              ),
              toJson: (value) => {
                "fromEnv": CliValueType.string().encode(value.fromEnv),
              },
            ).constrained({
              "properties": {
                "fromEnv": {
                  "type": "string",
                  "description": "Name of the variable supplying this runtime value. Read from the shell\nor .env unless --no-env-file is set; shell values take precedence. The value\nis never written to the shared manifest.",
                  "default": "",
                },
              },
            }),
          ).decode(json.containsKey("secrets") ? json["secrets"] : {}),
        ),
        toJson: (value) => {
          "branch": CliValueType.string().encode(value.branch),
          "configMode": CliValueType.string().nullable().encode(
            value.configMode,
          ),
          "database":
              CliValueType.object<_c3.DatabaseOverride>(
                    properties: {
                      "name": CliValueType.string().nullable(),
                      "user": CliValueType.string().nullable(),
                    },
                    fromJson: (json) => _c3.DatabaseOverride(
                      name: CliValueType.string().nullable().decode(
                        json.containsKey("name") ? json["name"] : null,
                      ),
                      user: CliValueType.string().nullable().decode(
                        json.containsKey("user") ? json["user"] : null,
                      ),
                    ),
                    toJson: (value) => {
                      "name": CliValueType.string().nullable().encode(
                        value.name,
                      ),
                      "user": CliValueType.string().nullable().encode(
                        value.user,
                      ),
                    },
                  )
                  .constrained({
                    "properties": {
                      "name": {
                        "anyOf": [
                          {"type": "string"},
                          {"type": "null"},
                        ],
                        "description": "Initial PostgreSQL database name. Defaults to the project name with hyphens\nreplaced by underscores; does not rename an existing database.",
                        "default": null,
                      },
                      "user": {
                        "anyOf": [
                          {"type": "string"},
                          {"type": "null"},
                        ],
                        "description": "Initial PostgreSQL username. Defaults to the database name; does not rename\nan existing database user.",
                        "default": null,
                      },
                    },
                  })
                  .encode(value.database),
          "env": _c4.environmentVariablesType().encode(value.env),
          "redis":
              CliValueType.object<_c5.RedisConfig>(
                    properties: {"enabled": CliValueType.boolean()},
                    fromJson: (json) => _c5.RedisConfig(
                      enabled: CliValueType.boolean().decode(
                        json.containsKey("enabled") ? json["enabled"] : false,
                      ),
                    ),
                    toJson: (value) => {
                      "enabled": CliValueType.boolean().encode(value.enabled),
                    },
                  )
                  .constrained({
                    "properties": {
                      "enabled": {
                        "type": "boolean",
                        "description": "Create and manage a private Redis instance for each enabled environment.",
                        "default": false,
                      },
                    },
                  })
                  .nullable()
                  .encode(value.redis),
          "resourceName": CliValueType.string().nullable().encode(
            value.resourceName,
          ),
          "secrets": CliValueType.map(
            CliValueType.object<_c6.SecretReference>(
              properties: {"fromEnv": CliValueType.string()},
              fromJson: (json) => _c6.SecretReference(
                fromEnv: CliValueType.string().decode(
                  json.containsKey("fromEnv") ? json["fromEnv"] : "",
                ),
              ),
              toJson: (value) => {
                "fromEnv": CliValueType.string().encode(value.fromEnv),
              },
            ).constrained({
              "properties": {
                "fromEnv": {
                  "type": "string",
                  "description": "Name of the variable supplying this runtime value. Read from the shell\nor .env unless --no-env-file is set; shell values take precedence. The value\nis never written to the shared manifest.",
                  "default": "",
                },
              },
            }),
          ).encode(value.secrets),
        },
      ).constrained({
        "properties": {
          "branch": {
            "type": "string",
            "description": "Git branch Coolify deploys for this environment.",
            "default": "main",
          },
          "configMode": {
            "anyOf": [
              {"type": "string"},
              {"type": "null"},
            ],
            "description": "Serverpod configuration mode. Defaults to production for the production\nenvironment and staging otherwise; the runtime mode remains production.",
            "default": null,
          },
          "database": {
            "type": "object",
            "properties": {
              "name": {
                "anyOf": [
                  {"type": "string"},
                  {"type": "null"},
                ],
                "description": "Initial PostgreSQL database name. Defaults to the project name with hyphens\nreplaced by underscores; does not rename an existing database.",
                "default": null,
              },
              "user": {
                "anyOf": [
                  {"type": "string"},
                  {"type": "null"},
                ],
                "description": "Initial PostgreSQL username. Defaults to the database name; does not rename\nan existing database user.",
                "default": null,
              },
            },
            "additionalProperties": false,
            "description": "Initial database name and user overrides for this environment.",
            "default": {"name": null, "user": null},
          },
          "env": {
            "type": "object",
            "additionalProperties": {
              "oneOf": [
                {"type": "string"},
                {
                  "type": "object",
                  "additionalProperties": false,
                  "required": ["fromEnv"],
                  "properties": {
                    "fromEnv": {
                      "type": "string",
                      "pattern": "^[A-Za-z_][A-Za-z0-9_]*\$",
                    },
                  },
                },
              ],
            },
            "description": "Runtime environment variables: literal strings or {fromEnv: VARIABLE}\nreferences read from the shell or .env. Tug-managed connection, port and\ncredential settings cannot be overridden. Use secrets for Serverpod passwords.",
            "default": {},
          },
          "redis": {
            "anyOf": [
              {
                "type": "object",
                "properties": {
                  "enabled": {
                    "type": "boolean",
                    "description": "Create and manage a private Redis instance for each enabled environment.",
                    "default": false,
                  },
                },
                "additionalProperties": false,
              },
              {"type": "null"},
            ],
            "description": "Override the project Redis setting for this environment. When omitted,\nthe project-level redis configuration applies.",
            "default": null,
          },
          "resourceName": {
            "anyOf": [
              {"type": "string"},
              {"type": "null"},
            ],
            "description": "Coolify application resource name, preserving capitalization. Defaults to\n`<project>-<environment>-app`. Changes rename the existing managed application;\nproject identity and PostgreSQL/Redis resource names are unchanged.",
            "default": null,
          },
          "secrets": {
            "type": "object",
            "additionalProperties": {
              "type": "object",
              "properties": {
                "fromEnv": {
                  "type": "string",
                  "description": "Name of the variable supplying this runtime value. Read from the shell\nor .env unless --no-env-file is set; shell values take precedence. The value\nis never written to the shared manifest.",
                  "default": "",
                },
              },
              "additionalProperties": false,
            },
            "description": "Serverpod password names mapped to local environment-variable references.\nEach value is sent as `SERVERPOD_PASSWORD_<name>`; keep secret values out of this file.",
            "default": {},
          },
        },
      }),
    ),
    description: "Named, isolated deployments with their own branches, databases and runtime settings.",
    defaultValue: CliValueType.map(
      CliValueType.object<_c7.EnvironmentConfig>(
        properties: {
          "branch": CliValueType.string(),
          "configMode": CliValueType.string().nullable(),
          "database":
              CliValueType.object<_c3.DatabaseOverride>(
                properties: {
                  "name": CliValueType.string().nullable(),
                  "user": CliValueType.string().nullable(),
                },
                fromJson: (json) => _c3.DatabaseOverride(
                  name: CliValueType.string().nullable().decode(
                    json.containsKey("name") ? json["name"] : null,
                  ),
                  user: CliValueType.string().nullable().decode(
                    json.containsKey("user") ? json["user"] : null,
                  ),
                ),
                toJson: (value) => {
                  "name": CliValueType.string().nullable().encode(value.name),
                  "user": CliValueType.string().nullable().encode(value.user),
                },
              ).constrained({
                "properties": {
                  "name": {
                    "anyOf": [
                      {"type": "string"},
                      {"type": "null"},
                    ],
                    "description": "Initial PostgreSQL database name. Defaults to the project name with hyphens\nreplaced by underscores; does not rename an existing database.",
                    "default": null,
                  },
                  "user": {
                    "anyOf": [
                      {"type": "string"},
                      {"type": "null"},
                    ],
                    "description": "Initial PostgreSQL username. Defaults to the database name; does not rename\nan existing database user.",
                    "default": null,
                  },
                },
              }),
          "env": _c4.environmentVariablesType(),
          "redis":
              CliValueType.object<_c5.RedisConfig>(
                properties: {"enabled": CliValueType.boolean()},
                fromJson: (json) => _c5.RedisConfig(
                  enabled: CliValueType.boolean().decode(
                    json.containsKey("enabled") ? json["enabled"] : false,
                  ),
                ),
                toJson: (value) => {
                  "enabled": CliValueType.boolean().encode(value.enabled),
                },
              ).constrained({
                "properties": {
                  "enabled": {
                    "type": "boolean",
                    "description": "Create and manage a private Redis instance for each enabled environment.",
                    "default": false,
                  },
                },
              }).nullable(),
          "resourceName": CliValueType.string().nullable(),
          "secrets": CliValueType.map(
            CliValueType.object<_c6.SecretReference>(
              properties: {"fromEnv": CliValueType.string()},
              fromJson: (json) => _c6.SecretReference(
                fromEnv: CliValueType.string().decode(
                  json.containsKey("fromEnv") ? json["fromEnv"] : "",
                ),
              ),
              toJson: (value) => {
                "fromEnv": CliValueType.string().encode(value.fromEnv),
              },
            ).constrained({
              "properties": {
                "fromEnv": {
                  "type": "string",
                  "description": "Name of the variable supplying this runtime value. Read from the shell\nor .env unless --no-env-file is set; shell values take precedence. The value\nis never written to the shared manifest.",
                  "default": "",
                },
              },
            }),
          ),
        },
        fromJson: (json) => _c7.EnvironmentConfig(
          branch: CliValueType.string().decode(
            json.containsKey("branch") ? json["branch"] : "main",
          ),
          configMode: CliValueType.string().nullable().decode(
            json.containsKey("configMode") ? json["configMode"] : null,
          ),
          database:
              CliValueType.object<_c3.DatabaseOverride>(
                    properties: {
                      "name": CliValueType.string().nullable(),
                      "user": CliValueType.string().nullable(),
                    },
                    fromJson: (json) => _c3.DatabaseOverride(
                      name: CliValueType.string().nullable().decode(
                        json.containsKey("name") ? json["name"] : null,
                      ),
                      user: CliValueType.string().nullable().decode(
                        json.containsKey("user") ? json["user"] : null,
                      ),
                    ),
                    toJson: (value) => {
                      "name": CliValueType.string().nullable().encode(
                        value.name,
                      ),
                      "user": CliValueType.string().nullable().encode(
                        value.user,
                      ),
                    },
                  )
                  .constrained({
                    "properties": {
                      "name": {
                        "anyOf": [
                          {"type": "string"},
                          {"type": "null"},
                        ],
                        "description": "Initial PostgreSQL database name. Defaults to the project name with hyphens\nreplaced by underscores; does not rename an existing database.",
                        "default": null,
                      },
                      "user": {
                        "anyOf": [
                          {"type": "string"},
                          {"type": "null"},
                        ],
                        "description": "Initial PostgreSQL username. Defaults to the database name; does not rename\nan existing database user.",
                        "default": null,
                      },
                    },
                  })
                  .decode(
                    json.containsKey("database")
                        ? json["database"]
                        : {"name": null, "user": null},
                  ),
          env: _c4.environmentVariablesType().decode(
            json.containsKey("env") ? json["env"] : {},
          ),
          redis:
              CliValueType.object<_c5.RedisConfig>(
                    properties: {"enabled": CliValueType.boolean()},
                    fromJson: (json) => _c5.RedisConfig(
                      enabled: CliValueType.boolean().decode(
                        json.containsKey("enabled") ? json["enabled"] : false,
                      ),
                    ),
                    toJson: (value) => {
                      "enabled": CliValueType.boolean().encode(value.enabled),
                    },
                  )
                  .constrained({
                    "properties": {
                      "enabled": {
                        "type": "boolean",
                        "description": "Create and manage a private Redis instance for each enabled environment.",
                        "default": false,
                      },
                    },
                  })
                  .nullable()
                  .decode(json.containsKey("redis") ? json["redis"] : null),
          resourceName: CliValueType.string().nullable().decode(
            json.containsKey("resourceName") ? json["resourceName"] : null,
          ),
          secrets: CliValueType.map(
            CliValueType.object<_c6.SecretReference>(
              properties: {"fromEnv": CliValueType.string()},
              fromJson: (json) => _c6.SecretReference(
                fromEnv: CliValueType.string().decode(
                  json.containsKey("fromEnv") ? json["fromEnv"] : "",
                ),
              ),
              toJson: (value) => {
                "fromEnv": CliValueType.string().encode(value.fromEnv),
              },
            ).constrained({
              "properties": {
                "fromEnv": {
                  "type": "string",
                  "description": "Name of the variable supplying this runtime value. Read from the shell\nor .env unless --no-env-file is set; shell values take precedence. The value\nis never written to the shared manifest.",
                  "default": "",
                },
              },
            }),
          ).decode(json.containsKey("secrets") ? json["secrets"] : {}),
        ),
        toJson: (value) => {
          "branch": CliValueType.string().encode(value.branch),
          "configMode": CliValueType.string().nullable().encode(
            value.configMode,
          ),
          "database":
              CliValueType.object<_c3.DatabaseOverride>(
                    properties: {
                      "name": CliValueType.string().nullable(),
                      "user": CliValueType.string().nullable(),
                    },
                    fromJson: (json) => _c3.DatabaseOverride(
                      name: CliValueType.string().nullable().decode(
                        json.containsKey("name") ? json["name"] : null,
                      ),
                      user: CliValueType.string().nullable().decode(
                        json.containsKey("user") ? json["user"] : null,
                      ),
                    ),
                    toJson: (value) => {
                      "name": CliValueType.string().nullable().encode(
                        value.name,
                      ),
                      "user": CliValueType.string().nullable().encode(
                        value.user,
                      ),
                    },
                  )
                  .constrained({
                    "properties": {
                      "name": {
                        "anyOf": [
                          {"type": "string"},
                          {"type": "null"},
                        ],
                        "description": "Initial PostgreSQL database name. Defaults to the project name with hyphens\nreplaced by underscores; does not rename an existing database.",
                        "default": null,
                      },
                      "user": {
                        "anyOf": [
                          {"type": "string"},
                          {"type": "null"},
                        ],
                        "description": "Initial PostgreSQL username. Defaults to the database name; does not rename\nan existing database user.",
                        "default": null,
                      },
                    },
                  })
                  .encode(value.database),
          "env": _c4.environmentVariablesType().encode(value.env),
          "redis":
              CliValueType.object<_c5.RedisConfig>(
                    properties: {"enabled": CliValueType.boolean()},
                    fromJson: (json) => _c5.RedisConfig(
                      enabled: CliValueType.boolean().decode(
                        json.containsKey("enabled") ? json["enabled"] : false,
                      ),
                    ),
                    toJson: (value) => {
                      "enabled": CliValueType.boolean().encode(value.enabled),
                    },
                  )
                  .constrained({
                    "properties": {
                      "enabled": {
                        "type": "boolean",
                        "description": "Create and manage a private Redis instance for each enabled environment.",
                        "default": false,
                      },
                    },
                  })
                  .nullable()
                  .encode(value.redis),
          "resourceName": CliValueType.string().nullable().encode(
            value.resourceName,
          ),
          "secrets": CliValueType.map(
            CliValueType.object<_c6.SecretReference>(
              properties: {"fromEnv": CliValueType.string()},
              fromJson: (json) => _c6.SecretReference(
                fromEnv: CliValueType.string().decode(
                  json.containsKey("fromEnv") ? json["fromEnv"] : "",
                ),
              ),
              toJson: (value) => {
                "fromEnv": CliValueType.string().encode(value.fromEnv),
              },
            ).constrained({
              "properties": {
                "fromEnv": {
                  "type": "string",
                  "description": "Name of the variable supplying this runtime value. Read from the shell\nor .env unless --no-env-file is set; shell values take precedence. The value\nis never written to the shared manifest.",
                  "default": "",
                },
              },
            }),
          ).encode(value.secrets),
        },
      ).constrained({
        "properties": {
          "branch": {
            "type": "string",
            "description": "Git branch Coolify deploys for this environment.",
            "default": "main",
          },
          "configMode": {
            "anyOf": [
              {"type": "string"},
              {"type": "null"},
            ],
            "description": "Serverpod configuration mode. Defaults to production for the production\nenvironment and staging otherwise; the runtime mode remains production.",
            "default": null,
          },
          "database": {
            "type": "object",
            "properties": {
              "name": {
                "anyOf": [
                  {"type": "string"},
                  {"type": "null"},
                ],
                "description": "Initial PostgreSQL database name. Defaults to the project name with hyphens\nreplaced by underscores; does not rename an existing database.",
                "default": null,
              },
              "user": {
                "anyOf": [
                  {"type": "string"},
                  {"type": "null"},
                ],
                "description": "Initial PostgreSQL username. Defaults to the database name; does not rename\nan existing database user.",
                "default": null,
              },
            },
            "additionalProperties": false,
            "description": "Initial database name and user overrides for this environment.",
            "default": {"name": null, "user": null},
          },
          "env": {
            "type": "object",
            "additionalProperties": {
              "oneOf": [
                {"type": "string"},
                {
                  "type": "object",
                  "additionalProperties": false,
                  "required": ["fromEnv"],
                  "properties": {
                    "fromEnv": {
                      "type": "string",
                      "pattern": "^[A-Za-z_][A-Za-z0-9_]*\$",
                    },
                  },
                },
              ],
            },
            "description": "Runtime environment variables: literal strings or {fromEnv: VARIABLE}\nreferences read from the shell or .env. Tug-managed connection, port and\ncredential settings cannot be overridden. Use secrets for Serverpod passwords.",
            "default": {},
          },
          "redis": {
            "anyOf": [
              {
                "type": "object",
                "properties": {
                  "enabled": {
                    "type": "boolean",
                    "description": "Create and manage a private Redis instance for each enabled environment.",
                    "default": false,
                  },
                },
                "additionalProperties": false,
              },
              {"type": "null"},
            ],
            "description": "Override the project Redis setting for this environment. When omitted,\nthe project-level redis configuration applies.",
            "default": null,
          },
          "resourceName": {
            "anyOf": [
              {"type": "string"},
              {"type": "null"},
            ],
            "description": "Coolify application resource name, preserving capitalization. Defaults to\n`<project>-<environment>-app`. Changes rename the existing managed application;\nproject identity and PostgreSQL/Redis resource names are unchanged.",
            "default": null,
          },
          "secrets": {
            "type": "object",
            "additionalProperties": {
              "type": "object",
              "properties": {
                "fromEnv": {
                  "type": "string",
                  "description": "Name of the variable supplying this runtime value. Read from the shell\nor .env unless --no-env-file is set; shell values take precedence. The value\nis never written to the shared manifest.",
                  "default": "",
                },
              },
              "additionalProperties": false,
            },
            "description": "Serverpod password names mapped to local environment-variable references.\nEach value is sent as `SERVERPOD_PASSWORD_<name>`; keep secret values out of this file.",
            "default": {},
          },
        },
      }),
    ).decode({}),
    examples: [],
    hasDefault: true,
    deprecated: false,
  );

  /// Stable project name used to identify managed resources.
  final name = ConfigSetting<String?>(
    "name",
    type: CliValueType.string().nullable(),
    description: "Stable project name used to identify managed resources.",
    defaultValue: CliValueType.string().nullable().decode(null),
    examples: [],
    hasDefault: true,
    deprecated: false,
  );

  /// Default Redis setting for all environments; individual environments can override it.
  final redis = ConfigSetting<_c5.RedisConfig>(
    "redis",
    type:
        CliValueType.object<_c5.RedisConfig>(
          properties: {"enabled": CliValueType.boolean()},
          fromJson: (json) => _c5.RedisConfig(
            enabled: CliValueType.boolean().decode(
              json.containsKey("enabled") ? json["enabled"] : false,
            ),
          ),
          toJson: (value) => {
            "enabled": CliValueType.boolean().encode(value.enabled),
          },
        ).constrained({
          "properties": {
            "enabled": {
              "type": "boolean",
              "description": "Create and manage a private Redis instance for each enabled environment.",
              "default": false,
            },
          },
        }),
    description: "Default Redis setting for all environments; individual environments can override it.",
    defaultValue:
        CliValueType.object<_c5.RedisConfig>(
              properties: {"enabled": CliValueType.boolean()},
              fromJson: (json) => _c5.RedisConfig(
                enabled: CliValueType.boolean().decode(
                  json.containsKey("enabled") ? json["enabled"] : false,
                ),
              ),
              toJson: (value) => {
                "enabled": CliValueType.boolean().encode(value.enabled),
              },
            )
            .constrained({
              "properties": {
                "enabled": {
                  "type": "boolean",
                  "description": "Create and manage a private Redis instance for each enabled environment.",
                  "default": false,
                },
              },
            })
            .decode({"enabled": false}),
    examples: [],
    hasDefault: true,
    deprecated: false,
  );

  /// Serverpod and Flutter package paths and build options. Omit to discover
  /// the packages automatically and use the default build options.
  final serverpod = ConfigSetting<_c8.ServerpodConfig?>(
    "serverpod",
    type:
        CliValueType.object<_c8.ServerpodConfig>(
          properties: {
            "flutter": CliValueType.string(),
            "flutterBaseHref": CliValueType.string(),
            "migrations": CliValueType.boolean(),
            "server": CliValueType.string(),
          },
          fromJson: (json) => _c8.ServerpodConfig(
            flutter: CliValueType.string().decode(
              json.containsKey("flutter") ? json["flutter"] : "",
            ),
            flutterBaseHref: CliValueType.string().decode(
              json.containsKey("flutterBaseHref")
                  ? json["flutterBaseHref"]
                  : "/app/",
            ),
            migrations: CliValueType.boolean().decode(
              json.containsKey("migrations") ? json["migrations"] : true,
            ),
            server: CliValueType.string().decode(
              json.containsKey("server") ? json["server"] : "",
            ),
          ),
          toJson: (value) => {
            "flutter": CliValueType.string().encode(value.flutter),
            "flutterBaseHref": CliValueType.string().encode(
              value.flutterBaseHref,
            ),
            "migrations": CliValueType.boolean().encode(value.migrations),
            "server": CliValueType.string().encode(value.server),
          },
        ).constrained({
          "properties": {
            "flutter": {
              "type": "string",
              "description": "Path to the Flutter web package, relative to the repository root.\nAn empty path enables automatic package discovery.",
              "default": "",
            },
            "flutterBaseHref": {
              "type": "string",
              "description":
                  "URL prefix used by the application's FlutterRoute.",
              "default": "/app/",
            },
            "migrations": {
              "type": "boolean",
              "description": "Apply Serverpod database migrations when the deployed application starts.",
              "default": true,
            },
            "server": {
              "type": "string",
              "description": "Path to the Serverpod server package, relative to the repository root.\nAn empty path enables automatic package discovery.",
              "default": "",
            },
          },
        }).nullable(),
    description: "Serverpod and Flutter package paths and build options. Omit to discover\nthe packages automatically and use the default build options.",
    defaultValue:
        CliValueType.object<_c8.ServerpodConfig>(
              properties: {
                "flutter": CliValueType.string(),
                "flutterBaseHref": CliValueType.string(),
                "migrations": CliValueType.boolean(),
                "server": CliValueType.string(),
              },
              fromJson: (json) => _c8.ServerpodConfig(
                flutter: CliValueType.string().decode(
                  json.containsKey("flutter") ? json["flutter"] : "",
                ),
                flutterBaseHref: CliValueType.string().decode(
                  json.containsKey("flutterBaseHref")
                      ? json["flutterBaseHref"]
                      : "/app/",
                ),
                migrations: CliValueType.boolean().decode(
                  json.containsKey("migrations") ? json["migrations"] : true,
                ),
                server: CliValueType.string().decode(
                  json.containsKey("server") ? json["server"] : "",
                ),
              ),
              toJson: (value) => {
                "flutter": CliValueType.string().encode(value.flutter),
                "flutterBaseHref": CliValueType.string().encode(
                  value.flutterBaseHref,
                ),
                "migrations": CliValueType.boolean().encode(value.migrations),
                "server": CliValueType.string().encode(value.server),
              },
            )
            .constrained({
              "properties": {
                "flutter": {
                  "type": "string",
                  "description": "Path to the Flutter web package, relative to the repository root.\nAn empty path enables automatic package discovery.",
                  "default": "",
                },
                "flutterBaseHref": {
                  "type": "string",
                  "description":
                      "URL prefix used by the application's FlutterRoute.",
                  "default": "/app/",
                },
                "migrations": {
                  "type": "boolean",
                  "description": "Apply Serverpod database migrations when the deployed application starts.",
                  "default": true,
                },
                "server": {
                  "type": "string",
                  "description": "Path to the Serverpod server package, relative to the repository root.\nAn empty path enables automatic package discovery.",
                  "default": "",
                },
              },
            })
            .nullable()
            .decode(null),
    examples: [],
    hasDefault: true,
    deprecated: false,
  );

  /// Git repository shared by all deployment environments.
  final source = ConfigSetting<_c9.SourceConfig>(
    "source",
    type:
        CliValueType.object<_c9.SourceConfig>(
          properties: {"repository": CliValueType.string()},
          fromJson: (json) => _c9.SourceConfig(
            repository: CliValueType.string().decode(
              json.containsKey("repository") ? json["repository"] : "auto",
            ),
          ),
          toJson: (value) => {
            "repository": CliValueType.string().encode(value.repository),
          },
        ).constrained({
          "properties": {
            "repository": {
              "type": "string",
              "description": "GitHub repository URL shared by all environments. auto reads the origin\nGit remote; an explicit URL must identify the same repository as origin.",
              "default": "auto",
            },
          },
        }),
    description: "Git repository shared by all deployment environments.",
    defaultValue:
        CliValueType.object<_c9.SourceConfig>(
              properties: {"repository": CliValueType.string()},
              fromJson: (json) => _c9.SourceConfig(
                repository: CliValueType.string().decode(
                  json.containsKey("repository") ? json["repository"] : "auto",
                ),
              ),
              toJson: (value) => {
                "repository": CliValueType.string().encode(value.repository),
              },
            )
            .constrained({
              "properties": {
                "repository": {
                  "type": "string",
                  "description": "GitHub repository URL shared by all environments. auto reads the origin\nGit remote; an explicit URL must identify the same repository as origin.",
                  "default": "auto",
                },
              },
            })
            .decode({"repository": "auto"}),
    examples: [],
    hasDefault: true,
    deprecated: false,
  );

  /// Manifest format version.
  final version = ConfigSetting<int>(
    "version",
    type: CliValueType.integer().constrained({
      "enum": [1],
    }),
    description: "Manifest format version.",
    defaultValue: CliValueType.integer()
        .constrained({
          "enum": [1],
        })
        .decode(1),
    examples: [],
    hasDefault: true,
    deprecated: false,
  );
}
