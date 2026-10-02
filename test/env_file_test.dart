import 'dart:io';

import 'package:test/test.dart';
import 'package:tug/src/app/app.dart';

void main() {
  test(
    'dotenv supports quotes, comments, export, multiline and literal dollars',
    () {
      expect(
        parseEnvFile('''# comment
export TOKEN = abc # comment
EMPTY=
SINGLE='has # and \$literal'
DOUBLE="line\\nnext\\tvalue"
MULTI="first
second"
HASH=value#part
COMMAND=\$(touch /tmp/never-run)
'''),
        {
          'TOKEN': 'abc',
          'EMPTY': '',
          'SINGLE': 'has # and \$literal',
          'DOUBLE': 'line\nnext\tvalue',
          'MULTI': 'first\nsecond',
          'HASH': 'value#part',
          'COMMAND': '\$(touch /tmp/never-run)',
        },
      );
    },
  );
  test('invalid dotenv reports only a line number', () {
    for (final source in [
      'TOKEN="never-print',
      'never-print',
      'TOKEN="never-print" trailing',
    ]) {
      expect(
        () => parseEnvFile(source),
        throwsA(
          predicate(
            (e) =>
                e is TugException &&
                e.message.contains('line 1') &&
                !e.message.contains('never-print'),
          ),
        ),
      );
    }
  });
  test(
    'process values override dotenv and disabling skips parsing entirely',
    () async {
      final root = await Directory.systemTemp.createTemp('tug-dotenv-');
      addTearDown(() => root.delete(recursive: true));
      final file = File('${root.path}/.env');
      await file.writeAsString('TOKEN=file\nFILE_ONLY=loaded\nEMPTY=file');
      expect(
        await loadEnvironment(
          root.path,
          processEnvironment: {'TOKEN': 'shell', 'EMPTY': ''},
        ),
        {'TOKEN': 'shell', 'FILE_ONLY': 'loaded', 'EMPTY': ''},
      );
      await file.writeAsString('broken secret syntax');
      expect(
        await loadEnvironment(
          root.path,
          enabled: false,
          processEnvironment: {'TOKEN': 'shell'},
        ),
        {'TOKEN': 'shell'},
      );
    },
  );
}
