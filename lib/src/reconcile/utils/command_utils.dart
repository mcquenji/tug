import 'package:grumpy_cli/grumpy_cli.dart';
import 'package:tug/src/app/app.dart';

/// Confirmation is evaluated by reconciliation only after every destruction guard.
Future<bool> confirmDestruction(CommandContext context) async =>
    context.args.require(CommandOptions.yes) ||
    await context.prompts.confirm(
      'Destroy the listed resources?',
      defaultValue: false,
    );
