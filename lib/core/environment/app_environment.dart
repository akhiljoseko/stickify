import 'package:flutter/foundation.dart';
import 'package:stickify/core/environment/app_experience.dart';

/// Central state configuration holding capability flags resolved for the current environment.
class AppEnvironment {
  /// Instantiates a new [AppEnvironment].
  const AppEnvironment({
    required this.experience,
    required this.platform,
    required this.hasMouse,
    required this.hasKeyboard,
    required this.supportsFileSystem,
    required this.supportsBulkOperations,
    required this.supportsAdvancedPrintSetup,
    required this.supportsAdvancedEditor,
    required this.supportsDragAndDrop,
    required this.supportsKeyboardShortcuts,
  });

  /// The active form factor UI style category.
  final AppExperience experience;

  /// The host operating system platform.
  final TargetPlatform platform;

  /// Whether the host has pointer-based input.
  final bool hasMouse;

  /// Whether the host has typing keyboard accessory.
  final bool hasKeyboard;

  /// Whether reading and writing to custom files is supported.
  final bool supportsFileSystem;

  /// Whether heavy processing (CSV/Excel) is allowed.
  final bool supportsBulkOperations;

  /// Whether multi-slot advanced layout setup pages are available.
  final bool supportsAdvancedPrintSetup;

  /// Whether layout element coordinates design editing is supported.
  final bool supportsAdvancedEditor;

  /// Whether visual canvas elements drag interactions are supported.
  final bool supportsDragAndDrop;

  /// Whether keyboard shortcut handlers should be registered.
  final bool supportsKeyboardShortcuts;
}
