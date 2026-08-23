import 'package:stickify/domain/entities/app_settings.dart';

/// Abstract repository interface for application settings persistence.
abstract interface class SettingsRepository {
  /// Stream emitting setting updates whenever settings are changed.
  Stream<AppSettings> get watchSettings;

  /// Retrieves the current application settings.
  Future<AppSettings> getSettings();

  /// Saves the updated application settings.
  Future<void> saveSettings(AppSettings settings);
}
