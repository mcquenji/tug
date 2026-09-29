import 'package:grumpy_cli/grumpy_cli.dart';

/// Public origins, or templates containing {name} and {environment}.
class DomainConfig extends Model {
  const DomainConfig({this.web = 'auto', this.api = 'auto'});
  final String web;
  final String api;
}
