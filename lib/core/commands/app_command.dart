import 'package:flutter/widgets.dart';
import 'package:stickify/core/environment/app_environment.dart';

/// Centralized execution contract for user interface commands.
///
/// Encapsulates permission availability, enable states, metadata, and
/// platform-dependent routing/execution logic.
abstract class AppCommand {
  /// Unique identifier of the command.
  String get id;

  /// Human-readable label for visual representation.
  String get label;

  /// Resolves whether the command should be visible/offered in the current experience form factor.
  bool isVisible(AppEnvironment environment);

  /// Resolves whether the command is enabled based on current state and environment capabilities.
  bool isEnabled(Object state, AppEnvironment environment);

  /// Executes the action wrapped by the command.
  Future<void> execute(BuildContext context);
}
