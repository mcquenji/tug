import 'package:grumpy_cli/grumpy_cli.dart';

class MemoryTerminal extends TerminalService {
  MemoryTerminal({List<String>? input})
    : _input = input?.iterator,
      super.internal();
  final Iterator<String>? _input;
  final promptSecrets = <bool>[];
  final output = StringBuffer(), errors = StringBuffer();
  @override
  bool get interactive => _input != null;
  @override
  bool get supportsAnsi => false;
  @override
  void write(String text) => output.write(text);
  @override
  void writeError(String text) => errors.write(text);
  @override
  Future<String?> readLine({required CancellationToken cancellation}) async =>
      _input?.moveNext() == true ? _input!.current : null;
  @override
  Future<TerminalKey?> readKey({
    required CancellationToken cancellation,
  }) async => null;
  @override
  void beginPrompt({bool raw = false, bool secret = false}) =>
      promptSecrets.add(secret);
  @override
  void endPrompt() {}
  @override
  void pauseProgress() {}
  @override
  void resumeProgress() {}
  @override
  void progress(String message) => errors.writeln(message);
  @override
  Future<void> flush() async {}
  @override
  Future<void> destroy() async {}
  @override
  String get logTag => 'MemoryTerminal';
}
