import 'package:flutter/material.dart';
import 'package:stickify/core/environment/app_environment.dart';
import 'package:stickify/core/environment/app_experience.dart';

/// Helper to dynamically resolve capability parameters based on the current context viewport and platform.
abstract final class AppEnvironmentResolver {
  AppEnvironmentResolver._();

  /// Resolves the current [AppEnvironment] from [BuildContext] dimensions and host platform.
  static AppEnvironment resolve(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final platform = Theme.of(context).platform;

    final isDesktopPlatform = platform == TargetPlatform.macOS ||
        platform == TargetPlatform.windows ||
        platform == TargetPlatform.linux;

    final AppExperience experience;
    if (size.width <= 450) {
      experience = AppExperience.mobile;
    } else if (size.width <= 800) {
      experience = AppExperience.tablet;
    } else {
      experience = AppExperience.desktop;
    }

    final hasMouse = isDesktopPlatform;
    final hasKeyboard = isDesktopPlatform;

    return AppEnvironment(
      experience: experience,
      platform: platform,
      hasMouse: hasMouse,
      hasKeyboard: hasKeyboard,
      supportsFileSystem: true,
      // User requirements resolved in griller interview:
      // Bulk operations and advanced printing setups are fully supported across all platforms (including mobile print setups).
      // Advanced editor/canvas creation is desktop/tablet only.
      supportsBulkOperations: true,
      supportsAdvancedPrintSetup: true,
      supportsAdvancedEditor: experience != AppExperience.mobile,
      supportsDragAndDrop: experience != AppExperience.mobile,
      supportsKeyboardShortcuts: isDesktopPlatform,
    );
  }
}
