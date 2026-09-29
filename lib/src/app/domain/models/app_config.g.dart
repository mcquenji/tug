// GENERATED CODE - DO NOT MODIFY BY HAND.

import 'package:grumpy_cli/grumpy_cli.dart';
import "package:tug/src/app/domain/models/domain_config.dart" as _c0;
import "package:tug/src/app/domain/models/coolify_context.dart" as _c1;
import "package:tug/src/app/domain/models/database_config.dart" as _c2;
import "package:tug/src/app/domain/models/database_override.dart" as _c3;
import "package:tug/src/app/domain/models/redis_config.dart" as _c4;
import "package:tug/src/app/domain/models/secret_reference.dart" as _c5;
import "package:tug/src/app/domain/models/environment_config.dart" as _c6;
import "package:tug/src/app/domain/models/serverpod_config.dart" as _c7;
import "package:tug/src/app/domain/models/source_config.dart" as _c8;
import "package:tug/src/app/domain/models/global_config.dart" as _c9;
import "package:tug/src/app/domain/models/local_config.dart" as _c10;

/// Immutable configuration resolved for the current application invocation.
final class AppConfig extends CliConfig<AppConfig>
    implements _c9.GlobalConfig, _c10.LocalConfig {
  AppConfig._({
    required this.context,
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
    context: settings.context.defaultValue as String?,
    contexts: settings.contexts.defaultValue as Map<String, _c1.CoolifyContext>,
    currentContext: settings.currentContext.defaultValue as String?,
    database: settings.database.defaultValue as _c2.DatabaseConfig,
    environments:
        settings.environments.defaultValue
            as Map<String, _c6.EnvironmentConfig>,
    name: settings.name.defaultValue as String?,
    redis: settings.redis.defaultValue as _c4.RedisConfig,
    serverpod: settings.serverpod.defaultValue as _c7.ServerpodConfig?,
    source: settings.source.defaultValue as _c8.SourceConfig,
    version: settings.version.defaultValue as int,
  );

  /// Typed handles for explicit scope writes, provenance and shared value types.
  static final settings = AppConfigSettings();

  /// Optional reference to a globally configured context.
  @override
  final String? context;

  /// Named Coolify connections. Tokens are sensitive, including local overrides.
  @override
  final Map<String, _c1.CoolifyContext> contexts;

  /// Default connection profile when no project or command selects one.
  @override
  final String? currentContext;

  ///
  @override
  final _c2.DatabaseConfig database;

  ///
  @override
  final Map<String, _c6.EnvironmentConfig> environments;

  /// Stable project name used to identify managed resources.
  @override
  final String? name;

  ///
  @override
  final _c4.RedisConfig redis;

  ///
  @override
  final _c7.ServerpodConfig? serverpod;

  ///
  @override
  final _c8.SourceConfig source;

  /// Manifest format version.
  @override
  final int version;
  @override
  ConfigSchema get configSchema => _schema;
  static final _schema = ConfigSchema(
    global: [settings.contexts, settings.currentContext],
    local: [
      settings.context,
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
    context: service.get(settings.context) as String?,
    contexts: service.get(settings.contexts) as Map<String, _c1.CoolifyContext>,
    currentContext: service.get(settings.currentContext) as String?,
    database: service.get(settings.database) as _c2.DatabaseConfig,
    environments: service.get(
      settings.environments,
    ) as Map<String, _c6.EnvironmentConfig>,
    name: service.get(settings.name) as String?,
    redis: service.get(settings.redis) as _c4.RedisConfig,
    serverpod: service.get(settings.serverpod) as _c7.ServerpodConfig?,
    source: service.get(settings.source) as _c8.SourceConfig,
    version: service.get(settings.version) as int,
  );
}

/// Generated typed setting declarations; use AppConfig.settings.
final class AppConfigSettings extends Model {
  /// Creates the generated settings collection.
  AppConfigSettings();

  /// Optional reference to a globally configured context.
  final context = ConfigSetting<String?>(
    "context",
    type: CliValueType.string().nullable(),
    description: "Optional reference to a globally configured context.",
    defaultValue: CliValueType.string().nullable().decode(null),
    examples: [],
    hasDefault: true,
    deprecated: false,
  );

  /// Named Coolify connections. Tokens are sensitive, including local overrides.
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
                "api": {"type": "string", "description": "", "default": "auto"},
                "web": {"type": "string", "description": "", "default": "auto"},
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
                "api": {"type": "string", "description": "", "default": "auto"},
                "web": {"type": "string", "description": "", "default": "auto"},
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
                "api": {"type": "string", "description": "", "default": "auto"},
                "web": {"type": "string", "description": "", "default": "auto"},
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
          "destination": {"type": "string", "description": "", "default": ""},
          "domains": {
            "type": "object",
            "additionalProperties": {
              "type": "object",
              "properties": {
                "api": {"type": "string", "description": "", "default": "auto"},
                "web": {"type": "string", "description": "", "default": "auto"},
              },
              "additionalProperties": false,
            },
            "description": "",
            "default": {},
          },
          "githubApp": {"type": "string", "description": "", "default": ""},
          "server": {"type": "string", "description": "", "default": ""},
          "token": {
            "anyOf": [
              {"type": "string"},
              {"type": "null"},
            ],
            "description": "",
            "default": null,
          },
          "tokenEnv": {
            "anyOf": [
              {"type": "string"},
              {"type": "null"},
            ],
            "description": "",
            "default": null,
          },
          "url": {"type": "string", "description": "", "default": ""},
        },
      }),
    ),
    description: "Named Coolify connections. Tokens are sensitive, including local overrides.",
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
                "api": {"type": "string", "description": "", "default": "auto"},
                "web": {"type": "string", "description": "", "default": "auto"},
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
                "api": {"type": "string", "description": "", "default": "auto"},
                "web": {"type": "string", "description": "", "default": "auto"},
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
                "api": {"type": "string", "description": "", "default": "auto"},
                "web": {"type": "string", "description": "", "default": "auto"},
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
          "destination": {"type": "string", "description": "", "default": ""},
          "domains": {
            "type": "object",
            "additionalProperties": {
              "type": "object",
              "properties": {
                "api": {"type": "string", "description": "", "default": "auto"},
                "web": {"type": "string", "description": "", "default": "auto"},
              },
              "additionalProperties": false,
            },
            "description": "",
            "default": {},
          },
          "githubApp": {"type": "string", "description": "", "default": ""},
          "server": {"type": "string", "description": "", "default": ""},
          "token": {
            "anyOf": [
              {"type": "string"},
              {"type": "null"},
            ],
            "description": "",
            "default": null,
          },
          "tokenEnv": {
            "anyOf": [
              {"type": "string"},
              {"type": "null"},
            ],
            "description": "",
            "default": null,
          },
          "url": {"type": "string", "description": "", "default": ""},
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

  ///
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
              "description": "",
              "default": "postgres",
            },
            "version": {"type": "integer", "description": "", "default": 18},
          },
        }),
    description: "",
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
                  "description": "",
                  "default": "postgres",
                },
                "version": {
                  "type": "integer",
                  "description": "",
                  "default": 18,
                },
              },
            })
            .decode({"type": "postgres", "version": 18}),
    examples: [],
    hasDefault: true,
    deprecated: false,
  );

  ///
  final environments = ConfigSetting<Map<String, _c6.EnvironmentConfig>>(
    "environments",
    type: CliValueType.map(
      CliValueType.object<_c6.EnvironmentConfig>(
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
                    "description": "",
                    "default": null,
                  },
                  "user": {
                    "anyOf": [
                      {"type": "string"},
                      {"type": "null"},
                    ],
                    "description": "",
                    "default": null,
                  },
                },
              }),
          "domains":
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
                    "description": "",
                    "default": "auto",
                  },
                  "web": {
                    "type": "string",
                    "description": "",
                    "default": "auto",
                  },
                },
              }),
          "env": CliValueType.map(CliValueType.string()),
          "redis":
              CliValueType.object<_c4.RedisConfig>(
                properties: {"enabled": CliValueType.boolean()},
                fromJson: (json) => _c4.RedisConfig(
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
                    "description": "",
                    "default": false,
                  },
                },
              }).nullable(),
          "secrets": CliValueType.map(
            CliValueType.object<_c5.SecretReference>(
              properties: {"fromEnv": CliValueType.string()},
              fromJson: (json) => _c5.SecretReference(
                fromEnv: CliValueType.string().decode(
                  json.containsKey("fromEnv") ? json["fromEnv"] : "",
                ),
              ),
              toJson: (value) => {
                "fromEnv": CliValueType.string().encode(value.fromEnv),
              },
            ).constrained({
              "properties": {
                "fromEnv": {"type": "string", "description": "", "default": ""},
              },
            }),
          ),
        },
        fromJson: (json) => _c6.EnvironmentConfig(
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
                        "description": "",
                        "default": null,
                      },
                      "user": {
                        "anyOf": [
                          {"type": "string"},
                          {"type": "null"},
                        ],
                        "description": "",
                        "default": null,
                      },
                    },
                  })
                  .decode(
                    json.containsKey("database")
                        ? json["database"]
                        : {"name": null, "user": null},
                  ),
          domains:
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
                  )
                  .constrained({
                    "properties": {
                      "api": {
                        "type": "string",
                        "description": "",
                        "default": "auto",
                      },
                      "web": {
                        "type": "string",
                        "description": "",
                        "default": "auto",
                      },
                    },
                  })
                  .decode(
                    json.containsKey("domains")
                        ? json["domains"]
                        : {"web": "auto", "api": "auto"},
                  ),
          env: CliValueType.map(CliValueType.string())
              .decode(json.containsKey("env") ? json["env"] : {}),
          redis:
              CliValueType.object<_c4.RedisConfig>(
                    properties: {"enabled": CliValueType.boolean()},
                    fromJson: (json) => _c4.RedisConfig(
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
                        "description": "",
                        "default": false,
                      },
                    },
                  })
                  .nullable()
                  .decode(json.containsKey("redis") ? json["redis"] : null),
          secrets: CliValueType.map(
            CliValueType.object<_c5.SecretReference>(
              properties: {"fromEnv": CliValueType.string()},
              fromJson: (json) => _c5.SecretReference(
                fromEnv: CliValueType.string().decode(
                  json.containsKey("fromEnv") ? json["fromEnv"] : "",
                ),
              ),
              toJson: (value) => {
                "fromEnv": CliValueType.string().encode(value.fromEnv),
              },
            ).constrained({
              "properties": {
                "fromEnv": {"type": "string", "description": "", "default": ""},
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
                        "description": "",
                        "default": null,
                      },
                      "user": {
                        "anyOf": [
                          {"type": "string"},
                          {"type": "null"},
                        ],
                        "description": "",
                        "default": null,
                      },
                    },
                  })
                  .encode(value.database),
          "domains":
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
                  )
                  .constrained({
                    "properties": {
                      "api": {
                        "type": "string",
                        "description": "",
                        "default": "auto",
                      },
                      "web": {
                        "type": "string",
                        "description": "",
                        "default": "auto",
                      },
                    },
                  })
                  .encode(value.domains),
          "env": CliValueType.map(CliValueType.string()).encode(value.env),
          "redis":
              CliValueType.object<_c4.RedisConfig>(
                    properties: {"enabled": CliValueType.boolean()},
                    fromJson: (json) => _c4.RedisConfig(
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
                        "description": "",
                        "default": false,
                      },
                    },
                  })
                  .nullable()
                  .encode(value.redis),
          "secrets": CliValueType.map(
            CliValueType.object<_c5.SecretReference>(
              properties: {"fromEnv": CliValueType.string()},
              fromJson: (json) => _c5.SecretReference(
                fromEnv: CliValueType.string().decode(
                  json.containsKey("fromEnv") ? json["fromEnv"] : "",
                ),
              ),
              toJson: (value) => {
                "fromEnv": CliValueType.string().encode(value.fromEnv),
              },
            ).constrained({
              "properties": {
                "fromEnv": {"type": "string", "description": "", "default": ""},
              },
            }),
          ).encode(value.secrets),
        },
      ).constrained({
        "properties": {
          "branch": {"type": "string", "description": "", "default": "main"},
          "configMode": {
            "anyOf": [
              {"type": "string"},
              {"type": "null"},
            ],
            "description": "",
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
                "description": "",
                "default": null,
              },
              "user": {
                "anyOf": [
                  {"type": "string"},
                  {"type": "null"},
                ],
                "description": "",
                "default": null,
              },
            },
            "additionalProperties": false,
            "description": "",
            "default": {"name": null, "user": null},
          },
          "domains": {
            "type": "object",
            "properties": {
              "api": {"type": "string", "description": "", "default": "auto"},
              "web": {"type": "string", "description": "", "default": "auto"},
            },
            "additionalProperties": false,
            "description": "",
            "default": {"web": "auto", "api": "auto"},
          },
          "env": {
            "type": "object",
            "additionalProperties": {"type": "string"},
            "description": "",
            "default": {},
          },
          "redis": {
            "anyOf": [
              {
                "type": "object",
                "properties": {
                  "enabled": {
                    "type": "boolean",
                    "description": "",
                    "default": false,
                  },
                },
                "additionalProperties": false,
              },
              {"type": "null"},
            ],
            "description": "",
            "default": null,
          },
          "secrets": {
            "type": "object",
            "additionalProperties": {
              "type": "object",
              "properties": {
                "fromEnv": {"type": "string", "description": "", "default": ""},
              },
              "additionalProperties": false,
            },
            "description": "",
            "default": {},
          },
        },
      }),
    ),
    description: "",
    defaultValue: CliValueType.map(
      CliValueType.object<_c6.EnvironmentConfig>(
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
                    "description": "",
                    "default": null,
                  },
                  "user": {
                    "anyOf": [
                      {"type": "string"},
                      {"type": "null"},
                    ],
                    "description": "",
                    "default": null,
                  },
                },
              }),
          "domains":
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
                    "description": "",
                    "default": "auto",
                  },
                  "web": {
                    "type": "string",
                    "description": "",
                    "default": "auto",
                  },
                },
              }),
          "env": CliValueType.map(CliValueType.string()),
          "redis":
              CliValueType.object<_c4.RedisConfig>(
                properties: {"enabled": CliValueType.boolean()},
                fromJson: (json) => _c4.RedisConfig(
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
                    "description": "",
                    "default": false,
                  },
                },
              }).nullable(),
          "secrets": CliValueType.map(
            CliValueType.object<_c5.SecretReference>(
              properties: {"fromEnv": CliValueType.string()},
              fromJson: (json) => _c5.SecretReference(
                fromEnv: CliValueType.string().decode(
                  json.containsKey("fromEnv") ? json["fromEnv"] : "",
                ),
              ),
              toJson: (value) => {
                "fromEnv": CliValueType.string().encode(value.fromEnv),
              },
            ).constrained({
              "properties": {
                "fromEnv": {"type": "string", "description": "", "default": ""},
              },
            }),
          ),
        },
        fromJson: (json) => _c6.EnvironmentConfig(
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
                        "description": "",
                        "default": null,
                      },
                      "user": {
                        "anyOf": [
                          {"type": "string"},
                          {"type": "null"},
                        ],
                        "description": "",
                        "default": null,
                      },
                    },
                  })
                  .decode(
                    json.containsKey("database")
                        ? json["database"]
                        : {"name": null, "user": null},
                  ),
          domains:
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
                  )
                  .constrained({
                    "properties": {
                      "api": {
                        "type": "string",
                        "description": "",
                        "default": "auto",
                      },
                      "web": {
                        "type": "string",
                        "description": "",
                        "default": "auto",
                      },
                    },
                  })
                  .decode(
                    json.containsKey("domains")
                        ? json["domains"]
                        : {"web": "auto", "api": "auto"},
                  ),
          env: CliValueType.map(CliValueType.string())
              .decode(json.containsKey("env") ? json["env"] : {}),
          redis:
              CliValueType.object<_c4.RedisConfig>(
                    properties: {"enabled": CliValueType.boolean()},
                    fromJson: (json) => _c4.RedisConfig(
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
                        "description": "",
                        "default": false,
                      },
                    },
                  })
                  .nullable()
                  .decode(json.containsKey("redis") ? json["redis"] : null),
          secrets: CliValueType.map(
            CliValueType.object<_c5.SecretReference>(
              properties: {"fromEnv": CliValueType.string()},
              fromJson: (json) => _c5.SecretReference(
                fromEnv: CliValueType.string().decode(
                  json.containsKey("fromEnv") ? json["fromEnv"] : "",
                ),
              ),
              toJson: (value) => {
                "fromEnv": CliValueType.string().encode(value.fromEnv),
              },
            ).constrained({
              "properties": {
                "fromEnv": {"type": "string", "description": "", "default": ""},
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
                        "description": "",
                        "default": null,
                      },
                      "user": {
                        "anyOf": [
                          {"type": "string"},
                          {"type": "null"},
                        ],
                        "description": "",
                        "default": null,
                      },
                    },
                  })
                  .encode(value.database),
          "domains":
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
                  )
                  .constrained({
                    "properties": {
                      "api": {
                        "type": "string",
                        "description": "",
                        "default": "auto",
                      },
                      "web": {
                        "type": "string",
                        "description": "",
                        "default": "auto",
                      },
                    },
                  })
                  .encode(value.domains),
          "env": CliValueType.map(CliValueType.string()).encode(value.env),
          "redis":
              CliValueType.object<_c4.RedisConfig>(
                    properties: {"enabled": CliValueType.boolean()},
                    fromJson: (json) => _c4.RedisConfig(
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
                        "description": "",
                        "default": false,
                      },
                    },
                  })
                  .nullable()
                  .encode(value.redis),
          "secrets": CliValueType.map(
            CliValueType.object<_c5.SecretReference>(
              properties: {"fromEnv": CliValueType.string()},
              fromJson: (json) => _c5.SecretReference(
                fromEnv: CliValueType.string().decode(
                  json.containsKey("fromEnv") ? json["fromEnv"] : "",
                ),
              ),
              toJson: (value) => {
                "fromEnv": CliValueType.string().encode(value.fromEnv),
              },
            ).constrained({
              "properties": {
                "fromEnv": {"type": "string", "description": "", "default": ""},
              },
            }),
          ).encode(value.secrets),
        },
      ).constrained({
        "properties": {
          "branch": {"type": "string", "description": "", "default": "main"},
          "configMode": {
            "anyOf": [
              {"type": "string"},
              {"type": "null"},
            ],
            "description": "",
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
                "description": "",
                "default": null,
              },
              "user": {
                "anyOf": [
                  {"type": "string"},
                  {"type": "null"},
                ],
                "description": "",
                "default": null,
              },
            },
            "additionalProperties": false,
            "description": "",
            "default": {"name": null, "user": null},
          },
          "domains": {
            "type": "object",
            "properties": {
              "api": {"type": "string", "description": "", "default": "auto"},
              "web": {"type": "string", "description": "", "default": "auto"},
            },
            "additionalProperties": false,
            "description": "",
            "default": {"web": "auto", "api": "auto"},
          },
          "env": {
            "type": "object",
            "additionalProperties": {"type": "string"},
            "description": "",
            "default": {},
          },
          "redis": {
            "anyOf": [
              {
                "type": "object",
                "properties": {
                  "enabled": {
                    "type": "boolean",
                    "description": "",
                    "default": false,
                  },
                },
                "additionalProperties": false,
              },
              {"type": "null"},
            ],
            "description": "",
            "default": null,
          },
          "secrets": {
            "type": "object",
            "additionalProperties": {
              "type": "object",
              "properties": {
                "fromEnv": {"type": "string", "description": "", "default": ""},
              },
              "additionalProperties": false,
            },
            "description": "",
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

  ///
  final redis = ConfigSetting<_c4.RedisConfig>(
    "redis",
    type:
        CliValueType.object<_c4.RedisConfig>(
          properties: {"enabled": CliValueType.boolean()},
          fromJson: (json) => _c4.RedisConfig(
            enabled: CliValueType.boolean().decode(
              json.containsKey("enabled") ? json["enabled"] : false,
            ),
          ),
          toJson: (value) => {
            "enabled": CliValueType.boolean().encode(value.enabled),
          },
        ).constrained({
          "properties": {
            "enabled": {"type": "boolean", "description": "", "default": false},
          },
        }),
    description: "",
    defaultValue:
        CliValueType.object<_c4.RedisConfig>(
              properties: {"enabled": CliValueType.boolean()},
              fromJson: (json) => _c4.RedisConfig(
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
                  "description": "",
                  "default": false,
                },
              },
            })
            .decode({"enabled": false}),
    examples: [],
    hasDefault: true,
    deprecated: false,
  );

  ///
  final serverpod = ConfigSetting<_c7.ServerpodConfig?>(
    "serverpod",
    type:
        CliValueType.object<_c7.ServerpodConfig>(
          properties: {
            "flutter": CliValueType.string(),
            "flutterBaseHref": CliValueType.string(),
            "migrations": CliValueType.boolean(),
            "server": CliValueType.string(),
          },
          fromJson: (json) => _c7.ServerpodConfig(
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
            "flutter": {"type": "string", "description": "", "default": ""},
            "flutterBaseHref": {
              "type": "string",
              "description":
                  "URL prefix used by the application's FlutterRoute.",
              "default": "/app/",
            },
            "migrations": {
              "type": "boolean",
              "description": "",
              "default": true,
            },
            "server": {"type": "string", "description": "", "default": ""},
          },
        }).nullable(),
    description: "",
    defaultValue:
        CliValueType.object<_c7.ServerpodConfig>(
              properties: {
                "flutter": CliValueType.string(),
                "flutterBaseHref": CliValueType.string(),
                "migrations": CliValueType.boolean(),
                "server": CliValueType.string(),
              },
              fromJson: (json) => _c7.ServerpodConfig(
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
                "flutter": {"type": "string", "description": "", "default": ""},
                "flutterBaseHref": {
                  "type": "string",
                  "description":
                      "URL prefix used by the application's FlutterRoute.",
                  "default": "/app/",
                },
                "migrations": {
                  "type": "boolean",
                  "description": "",
                  "default": true,
                },
                "server": {"type": "string", "description": "", "default": ""},
              },
            })
            .nullable()
            .decode(null),
    examples: [],
    hasDefault: true,
    deprecated: false,
  );

  ///
  final source = ConfigSetting<_c8.SourceConfig>(
    "source",
    type:
        CliValueType.object<_c8.SourceConfig>(
          properties: {"repository": CliValueType.string()},
          fromJson: (json) => _c8.SourceConfig(
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
              "description": "",
              "default": "auto",
            },
          },
        }),
    description: "",
    defaultValue:
        CliValueType.object<_c8.SourceConfig>(
              properties: {"repository": CliValueType.string()},
              fromJson: (json) => _c8.SourceConfig(
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
                  "description": "",
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
