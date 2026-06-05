import 'package:stickify/app/app.dart';
import 'package:stickify/bootstrap.dart';

Future<void> main() async {
  await bootstrap(() => const App());
}
