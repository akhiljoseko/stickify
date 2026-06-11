import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stickify/core/core.dart';

class _TestCommand extends AppCommand {
  _TestCommand({
    required this.id,
    required this.label,
    this.visible = true,
    this.enabled = true,
  });

  @override
  final String id;

  @override
  final String label;

  final bool visible;
  final bool enabled;

  bool executed = false;

  @override
  bool isVisible(AppEnvironment environment) => visible;

  @override
  bool isEnabled(Object state, AppEnvironment environment) => enabled;

  @override
  Future<void> execute(BuildContext context) async {
    executed = true;
  }
}

void main() {
  group('CommandRegistry Tests', () {
    setUp(() {
      CommandRegistry.clear();
    });

    test('can register and look up commands', () {
      final cmd = _TestCommand(id: 'test_cmd', label: 'Test Command');
      CommandRegistry.register(cmd);

      expect(CommandRegistry.get('test_cmd'), same(cmd));
      expect(CommandRegistry.get('non_existent'), isNull);
    });

    test('clear removes all registered commands', () {
      final cmd = _TestCommand(id: 'test_cmd', label: 'Test Command');
      CommandRegistry.register(cmd);

      CommandRegistry.clear();
      expect(CommandRegistry.get('test_cmd'), isNull);
    });
  });
}
