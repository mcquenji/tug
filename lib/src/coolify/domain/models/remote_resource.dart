import 'package:grumpy_cli/grumpy_cli.dart';

/// Normalized remote resource. Only adapter-parsed managed fields are exposed.
class RemoteResource extends Model {
  const RemoteResource({
    required this.uuid,
    required this.name,
    required this.kind,
    this.description = '',
    this.status = '',
    this.tags = const [],
    this.destination,
    this.server,
    this.repository,
    this.branch,
    this.domains,
    this.image,
    this.databaseName,
    this.databaseUser,
    this.isPublic = false,
    this.buildPack,
    this.dockerfile,
    this.ports,
    this.environment,
    this.forceHttps,
    this.baseDirectory,
    this.previewEnabled,
  });
  final String uuid, name, kind, description, status;
  final List<String> tags;
  final String? destination, server, repository, branch, domains, image;
  final String? databaseName,
      databaseUser,
      buildPack,
      dockerfile,
      ports,
      environment;
  final String? baseDirectory;
  final bool isPublic;
  final bool? forceHttps, previewEnabled;
  bool get running =>
      status.startsWith('running') && !status.contains('unhealthy');
}
