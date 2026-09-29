import 'package:grumpy_cli/grumpy_cli.dart';

class ProjectLayout extends Model {
  const ProjectLayout({
    required this.root,
    required this.server,
    required this.flutter,
    required this.repository,
    required this.branch,
    required this.name,
    required this.workspace,
    this.flutterBaseHref = '/app/',
  });
  final String root, server, flutter, repository, branch, name;
  final bool workspace;
  final String flutterBaseHref;
}
