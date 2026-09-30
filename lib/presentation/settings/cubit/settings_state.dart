import 'package:equatable/equatable.dart';
import 'package:stickify/domain/domain.dart';

/// Describes the lifecycle of a product brochure export operation.
enum BrochureExportStatus {
  /// No export has been initiated.
  idle,

  /// PDF generation and file save / share is in progress.
  loading,

  /// The brochure was generated and saved/shared successfully.
  success,

  /// The export failed; see [SettingsState.brochureExportError].
  failure,
}

/// State for managing settings UI and persistence updates.
class SettingsState extends Equatable {
  /// Creates a [SettingsState] instance.
  const SettingsState({
    this.isLoading = true,
    this.settings = AppSettings.defaults,
    this.brochureExportStatus = BrochureExportStatus.idle,
    this.brochureExportError,
    this.brochureSavedPath,
  });

  /// Whether settings are currently loading from storage.
  final bool isLoading;

  /// Active application settings instance.
  final AppSettings settings;

  /// Status of the current (or most recent) brochure export operation.
  final BrochureExportStatus brochureExportStatus;

  /// Human-readable error message when [brochureExportStatus] is [BrochureExportStatus.failure].
  final String? brochureExportError;

  /// Absolute path where the brochure was saved on desktop platforms.
  ///
  /// Empty on mobile (share sheet is used instead).
  final String? brochureSavedPath;

  @override
  List<Object?> get props => [
        isLoading,
        settings,
        brochureExportStatus,
        brochureExportError,
        brochureSavedPath,
      ];

  /// Creates a copy of this state with updated values.
  SettingsState copyWith({
    bool? isLoading,
    AppSettings? settings,
    BrochureExportStatus? brochureExportStatus,
    String? brochureExportError,
    String? brochureSavedPath,
  }) {
    return SettingsState(
      isLoading: isLoading ?? this.isLoading,
      settings: settings ?? this.settings,
      brochureExportStatus:
          brochureExportStatus ?? this.brochureExportStatus,
      brochureExportError: brochureExportError ?? this.brochureExportError,
      brochureSavedPath: brochureSavedPath ?? this.brochureSavedPath,
    );
  }
}
