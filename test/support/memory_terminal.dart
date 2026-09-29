import 'package:grumpy_cli/grumpy_cli.dart';

class MemoryTerminal extends TerminalService {
  MemoryTerminal() : super.internal();
  final output = StringBuffer(), errors = StringBuffer();
  @override
  bool get interactive => false;
  @override
  bool get supportsAnsi => false;
  @override
  void write(String text) => output.write(text);
  @override
  void writeError(String text) => errors.write(text);
  @override
  Future<String?> readLine({required CancellationToken cancellation}) async =>
      null;
  @override
  Future<TerminalKey?> readKey({
    required CancellationToken cancellation,
  }) async => null;
  @override
  void beginPrompt({bool raw = false, bool secret = false}) {}
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
