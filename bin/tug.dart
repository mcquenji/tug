import 'dart:io';

import 'package:tug/src/app/app.dart';

Future<void> main(List<String> arguments) async {
  exitCode = await App().run(arguments);
}
