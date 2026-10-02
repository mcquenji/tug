import 'package:grumpy_cli/grumpy_cli.dart';

import '../infra/services/safe_terminal_service.dart';

extension TugTerminal on TerminalService {
  void success(String message) => _message('success', message);
  void warning(String message) => _message('warning', message);
  void failure(String message) => _message('error', message);
  void detail(String message) => _message('verbose', message);
  void _message(String level, String text) {
    if (this case SafeTerminalService terminal) {
      terminal.message(level, text);
    } else if (level == 'warning' || level == 'error') {
      errorln(text);
    } else if (level != 'verbose') {
      writeln(text);
    }
  }

  Future<T> task<T>(String label, Future<T> Function() action) async {
    final terminal = this;
    final task = terminal is SafeTerminalService
        ? terminal.startTask(label)
        : null;
    if (task == null) progress(label);
    try {
      final result = await action();
      if (terminal is SafeTerminalService) {
        terminal.finishTask(task!, success: true);
      }
      return result;
    } catch (_) {
      if (terminal is SafeTerminalService) {
        terminal.finishTask(task!, success: false);
      }
      rethrow;
    }
  }
}
