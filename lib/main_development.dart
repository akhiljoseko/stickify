import 'package:stickify/app/app.dart';
import 'package:stickify/bootstrap.dart';
import 'package:stickify/core/services/logging/logger_service.dart';

/// Development entry point of the Stickify application.
Future<void> main() async {
  await bootstrap(
    (locator) => App(locator: locator),
    minLevel: LogLevel.debug,
    enableFileLogging: false,
  );
}
