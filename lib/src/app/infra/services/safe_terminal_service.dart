import 'dart:async';
import 'dart:io';

import 'package:grumpy_cli/grumpy_cli.dart';

import '../../utils/security_utils.dart';

/// Redacts before applying trusted styling; progress never contaminates stdout.
class SafeTerminalService extends StdioTerminalService {
  SafeTerminalService({
    super.output,
    super.diagnostics,
    super.interactive,
    super.ansi,
  });
  final Set<String> secrets = {};
  bool colorEnabled = true, verboseEnabled = false;
  Timer? _timer;
  final _tasks = <Object, String>{};
  int _frame = 0, _paused = 0;
  bool _rendered = false;
  static const _frames = ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'];
  bool get _color =>
      supportsAnsi &&
      colorEnabled &&
      !Platform.environment.containsKey('NO_COLOR');
  String _style(String text, String code) =>
      _color ? '\x1b[${code}m$text\x1b[0m' : text;

  String _safe(String text) => redact(text, secrets);
  void _clear() {
    if (_rendered) super.writeError('\r\x1b[2K');
    _rendered = false;
  }

  void _render() {
    if (!supportsAnsi || _paused > 0 || _tasks.isEmpty) return;
    final label = _safe(_tasks.values.last).replaceAll(RegExp(r'[\r\n]'), ' ');
    final width = stderr.hasTerminal ? stderr.terminalColumns : 80;
    final visible = label.length > width - 5
        ? '${label.substring(0, width > 8 ? width - 8 : 0)}...'
        : label;
    super.writeError(
      '\r\x1b[2K${_style(_frames[_frame++ % _frames.length], '36')} $visible',
    );
    _rendered = true;
  }

  Object startTask(String label) {
    final id = Object();
    _tasks[id] = label;
    if (supportsAnsi) {
      _timer ??= Timer.periodic(
        const Duration(milliseconds: 80),
        (_) => _render(),
      );
      _render();
    } else {
      super.writeError('… ${_safe(label)}\n');
    }
    return id;
  }

  void finishTask(Object id, {required bool success}) {
    final label = _tasks.remove(id);
    if (label == null) return;
    _clear();
    message(success ? 'success' : 'error', label);
    if (_tasks.isEmpty) {
      _timer?.cancel();
      _timer = null;
    } else {
      _render();
    }
  }

  void message(String level, String text) {
    if (level == 'verbose' && !verboseEnabled) return;
    final (icon, color) = switch (level) {
      'success' => ('✓', '32'),
      'warning' => ('⚠', '33'),
      'error' => ('✗', '31'),
      'verbose' => ('·', '2'),
      _ => ('›', '36'),
    };
    _clear();
    super.writeError('${_style('$icon ${_safe(text)}', color)}\n');
    _render();
  }

  @override
  void writeError(String text) {
    // Preserve Grumpy's own cursor controls while a prompt owns the terminal.
    if (_paused > 0 && text.startsWith('\x1b[')) {
      super.writeError(text);
      return;
    }
    final safe =
        text.contains('Error on line') ||
            text.contains('YamlException') ||
            text.contains('FormatException:')
        ? 'Invalid configuration syntax (source excerpts hidden).\n'
        : _safe(text);
    _clear();
    super.writeError(
      _paused > 0
          ? safe
          : _style(safe, safe.toLowerCase().contains('warning') ? '33' : '31'),
    );
    if (text.endsWith('\n')) _render();
  }

  @override
  void write(String text) {
    _clear();
    super.write(_safe(text));
    if (text.endsWith('\n')) _render();
  }

  @override
  void pauseProgress() {
    _paused++;
    _clear();
  }

  @override
  void resumeProgress() {
    if (_paused > 0) _paused--;
    _render();
  }

  @override
  void progress(String message) {
    if (_tasks.isNotEmpty) {
      _tasks[_tasks.keys.last] = message;
      _render();
    } else {
      detail(message);
    }
  }

  void detail(String text) => message('verbose', text);
  @override
  Future<void> destroy() async {
    _timer?.cancel();
    _timer = null;
    _tasks.clear();
    _clear();
    await super.destroy();
  }

  @override
  String get logTag => 'SafeTerminalService';
}
