import 'package:equatable/equatable.dart';
import 'package:stickify/domain/domain.dart';

/// State for managing settings UI and persistence updates.
class SettingsState extends Equatable {
  /// Creates a [SettingsState] instance.
  const SettingsState({
    this.isLoading = true,
    this.settings = AppSettings.defaults,
  });

  /// Whether settings are currently loading from storage.
  final bool isLoading;

  /// Active application settings instance.
  final AppSettings settings;

  @override
  List<Object?> get props => [isLoading, settings];

  /// Creates a copy of this state with updated values.
  SettingsState copyWith({
    bool? isLoading,
    AppSettings? settings,
  }) {
    return SettingsState(
      isLoading: isLoading ?? this.isLoading,
      settings: settings ?? this.settings,
    );
  }
}
