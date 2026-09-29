import 'package:grumpy_cli/grumpy_cli.dart';

import '../../utils/utils.dart';

/// Keeps Grumpy's configuration adapters intact while suppressing YAML excerpts.
class SafeTerminalService extends StdioTerminalService {
  SafeTerminalService();
  final Set<String> secrets = {};
  @override
  void writeError(String text) {
    // YAML syntax errors may include the complete source line before config loads.
    if (text.contains('Error on line') ||
        text.contains('YamlException') ||
        text.contains('FormatException:')) {
      super.writeError(
        'Invalid configuration syntax. Check config.yaml and coolify.yaml; source excerpts are hidden.\n',
      );
    } else {
      super.writeError(redact(text, secrets));
    }
  }

  @override
  void write(String text) => super.write(redact(text, secrets));
  @override
  String get logTag => 'SafeTerminalService';
}
