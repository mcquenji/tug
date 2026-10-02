import 'dart:io';

import 'package:test/test.dart';
import 'package:tug/src/app/app.dart';
import 'package:tug/src/app/infra/infra.dart';

void main() {
  for (final ansi in [false, true]) {
    test(
      'progress completes, fails, pauses and redacts (ANSI $ansi)',
      () async {
        final root = await Directory.systemTemp.createTemp('tug-terminal-');
        addTearDown(() => root.delete(recursive: true));
        final out = File('${root.path}/out');
        final err = File('${root.path}/err');
        final output = out.openWrite(), diagnostics = err.openWrite();
        final terminal = SafeTerminalService(
          output: output,
          diagnostics: diagnostics,
          interactive: ansi,
          ansi: ansi,
        )..secrets.add('sensitive-value');
        await terminal.task('Build sensitive-value', () async {
          terminal.pauseProgress();
          terminal.writeError('Prompt\n');
          await Future<void>.delayed(const Duration(milliseconds: 100));
          terminal.resumeProgress();
        });
        await expectLater(
          terminal.task('Deploy', () async => throw StateError('failed')),
          throwsStateError,
        );
        terminal.warning('Warning detail');
        terminal.detail('hidden debug');
        terminal.verboseEnabled = true;
        terminal.detail('visible debug');
        terminal.writeln('public output');
        await terminal.destroy();
        await output.close();
        await diagnostics.close();
        final text = await err.readAsString();
        expect(text, contains('✓ Build [REDACTED]'));
        expect(text, contains('✗ Deploy'));
        expect(text, contains('⚠ Warning detail'));
        expect(text, contains('visible debug'));
        expect(text, isNot(contains('hidden debug')));
        expect(text, isNot(contains('sensitive-value')));
        if (!ansi) expect(text, isNot(contains('\x1b')));
        expect(await out.readAsString(), 'public output\n');
      },
    );
  }
}
