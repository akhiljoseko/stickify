import 'package:stickify/app/app.dart';
import 'package:stickify/bootstrap.dart';

/// Production entry point of the Label Grid application.
Future<void> main() async {
  await bootstrap((locator) => App(locator: locator));
}
