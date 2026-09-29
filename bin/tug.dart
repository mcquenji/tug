import 'dart:io';

import 'package:tug/src/cli/tug_app.dart';

Future<void> main(List<String> arguments) async {
  exitCode = await TugApp().run(arguments);
}
