import 'package:stickify/app/app.dart';
import 'package:stickify/bootstrap.dart';

/// Production entry point of the Stickify application.
Future<void> main() async {
  await bootstrap(() => const App());
}
