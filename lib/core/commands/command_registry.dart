import 'package:stickify/core/commands/app_command.dart';

/// Centralized registry for all available [AppCommand] items.
class CommandRegistry {
  CommandRegistry._();

  static final Map<String, AppCommand> _commands = {};

  /// Registers a [command] under its id.
  static void register(AppCommand command) {
    _commands[command.id] = command;
  }

  /// Locates and returns a command by [id], or null if not registered.
  static AppCommand? get(String id) => _commands[id];

  /// Clears the registry. Useful for testing isolation.
  static void clear() => _commands.clear();
}
