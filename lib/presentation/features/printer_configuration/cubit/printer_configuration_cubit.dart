import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/printer_configuration/cubit/printer_configuration_state.dart';
import 'package:uuid/uuid.dart';

class PrinterConfigurationCubit extends Cubit<PrinterConfigurationState> {
  PrinterConfigurationCubit({
    required this.printerProfileRepository,
  })  : super(const PrinterConfigurationState.initial());

  final PrinterProfileRepository printerProfileRepository;
  static const _uuid = Uuid();

  Future<void> loadProfile(String id) async {
    final result = await printerProfileRepository.getProfileById(id);
    switch (result) {
      case Success(value: final profile):
        if (profile != null) {
          loadFromProfile(profile);
        }
      case Failure():
        break;
    }
  }

  void setDisplayName(String value) {
    emit(state.copyWith(displayName: value));
  }

  void setSystemPrinterName(String value) {
    emit(state.copyWith(systemPrinterName: value));
  }

  void setManufacturer(String value) {
    emit(state.copyWith(manufacturer: value));
  }

  void setModel(String value) {
    emit(state.copyWith(model: value));
  }

  void setDriverName(String value) {
    emit(state.copyWith(driverName: value));
  }

  void setDriverVersion(String value) {
    emit(state.copyWith(driverVersion: value));
  }

  void setSupportsCustomPaperSize(bool value) {
    emit(state.copyWith(supportsCustomPaperSize: value));
  }

  void setSupportsPortraitCustomPaper(bool value) {
    emit(state.copyWith(supportsPortraitCustomPaper: value));
  }

  void setSupportsLandscapeCustomPaper(bool value) {
    emit(state.copyWith(supportsLandscapeCustomPaper: value));
  }

  void setSupportsManualFeed(bool value) {
    emit(state.copyWith(supportsManualFeed: value));
  }

  void setSupportsBorderlessPrinting(bool value) {
    emit(state.copyWith(supportsBorderlessPrinting: value));
  }

  void setSupportsTraySelection(bool value) {
    emit(state.copyWith(supportsTraySelection: value));
  }

  void setAllowScaling(bool value) {
    emit(state.copyWith(allowScaling: value));
  }

  void setAllowTranslation(bool value) {
    emit(state.copyWith(allowTranslation: value));
  }

  void setAllowStickerSpecificAdjustment(bool value) {
    emit(state.copyWith(allowStickerSpecificAdjustment: value));
  }

  void setMinimumAcceptableScale(double value) {
    emit(state.copyWith(minimumAcceptableScale: value));
  }

  void addTray(PrinterTrayProfile tray) {
    final updated = List<PrinterTrayProfile>.from(state.trays)..add(tray);
    emit(state.copyWith(trays: updated));
  }

  void updateTray(int index, PrinterTrayProfile tray) {
    if (index < 0 || index >= state.trays.length) return;
    final updated = List<PrinterTrayProfile>.from(state.trays)
      ..[index] = tray;
    emit(state.copyWith(trays: updated));
  }

  void removeTray(int index) {
    if (index < 0 || index >= state.trays.length) return;
    final updated = List<PrinterTrayProfile>.from(state.trays)..removeAt(index);
    emit(state.copyWith(trays: updated));
  }

  void loadFromProfile(PrinterProfile profile) {
    emit(
      state.copyWith(
        displayName: profile.displayName,
        systemPrinterName: profile.printerIdentity.systemPrinterName,
        manufacturer: profile.printerIdentity.manufacturer,
        model: profile.printerIdentity.model,
        driverName: profile.printerIdentity.driverName,
        driverVersion: profile.printerIdentity.driverVersion,
        supportsCustomPaperSize: profile.capabilities.supportsCustomPaperSize,
        supportsPortraitCustomPaper:
            profile.capabilities.supportsPortraitCustomPaper,
        supportsLandscapeCustomPaper:
            profile.capabilities.supportsLandscapeCustomPaper,
        supportsManualFeed: profile.capabilities.supportsManualFeed,
        supportsBorderlessPrinting:
            profile.capabilities.supportsBorderlessPrinting,
        supportsTraySelection: profile.capabilities.supportsTraySelection,
        allowScaling: profile.optimizationPreferences.allowScaling,
        allowTranslation: profile.optimizationPreferences.allowTranslation,
        allowStickerSpecificAdjustment:
            profile.optimizationPreferences.allowStickerSpecificAdjustment,
        minimumAcceptableScale:
            profile.optimizationPreferences.minimumAcceptableScale,
        trays: profile.trays,
        existingProfile: profile,
      ),
    );
  }

  Future<Result<PrinterProfile, AppError>> save() async {
    Log.info(
      'Saving printer profile "${state.displayName}" (${state.isEditing ? "edit" : "new"}).',
      tag: 'PrinterConfig',
    );
    emit(state.copyWith(status: PrinterConfigurationStatus.saving));

    // Validate: at least one tray required
    if (state.trays.isEmpty) {
      emit(
        state.copyWith(
          status: PrinterConfigurationStatus.error,
          errorMessage: () => 'Add at least one tray before saving.',
        ),
      );
      return const Result.failure(
        ValidationError(message: 'At least one tray is required.'),
      );
    }

    try {
      final profile = _buildProfile();
      final result = await printerProfileRepository.saveProfile(profile);
      switch (result) {
        case Failure(:final error):
          Log.error(
            'Failed to save printer profile "${profile.displayName}": ${error.message}',
            tag: 'PrinterConfig',
          );
          emit(
            state.copyWith(
              status: PrinterConfigurationStatus.error,
              errorMessage: () => 'Failed to save: ${error.message}',
            ),
          );
          return Result.failure(error);
        case Success():
          Log.info(
            'Printer profile "${profile.displayName}" (id: ${profile.id}) '
            'saved successfully. ${profile.trays.length} tray(s) configured.',
            tag: 'PrinterConfig',
          );
          emit(state.copyWith(status: PrinterConfigurationStatus.saved));
          return Result.success(profile);
      }
    } catch (e, stackTrace) {
      Log.error(
        'Unexpected error saving profile: $e',
        tag: 'PrinterConfig',
        error: e,
        stackTrace: stackTrace,
      );
      emit(
        state.copyWith(
          status: PrinterConfigurationStatus.error,
          errorMessage: () => 'Unexpected error: $e',
        ),
      );
      return Result.failure(
        UnexpectedError(
          message: 'Unexpected error saving profile.',
          originalError: e,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  /// Saves the profile without emitting `saved`
  /// status, so the page does not pop. Instead transitions back to `idle`.
  /// Used when saving is needed before navigating to calibration.
  Future<Result<PrinterProfile, AppError>> saveQuietly() async {
    Log.info(
      'Quietly saving printer profile "${state.displayName}" before calibration.',
      tag: 'PrinterConfig',
    );

    // Validate: at least one tray required
    if (state.trays.isEmpty) {
      return const Result.failure(
        ValidationError(message: 'At least one tray is required.'),
      );
    }

    try {
      final profile = _buildProfile();
      final result = await printerProfileRepository.saveProfile(profile);
      switch (result) {
        case Failure(:final error):
          Log.error(
            'Quiet save failed for "${profile.displayName}": ${error.message}',
            tag: 'PrinterConfig',
          );
          return Result.failure(error);
        case Success():
          Log.info(
            'Quiet save succeeded for "${profile.displayName}" (id: ${profile.id}). '
            'Proceeding to calibration.',
            tag: 'PrinterConfig',
          );
          emit(
            state.copyWith(
              status: PrinterConfigurationStatus.idle,
              existingProfile: profile,
            ),
          );
          return Result.success(profile);
      }
    } catch (e, stackTrace) {
      Log.error(
        'Unexpected error during quiet save: $e',
        tag: 'PrinterConfig',
        error: e,
        stackTrace: stackTrace,
      );
      return Result.failure(
        UnexpectedError(
          message: 'Unexpected error saving profile.',
          originalError: e,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  PrinterProfile _buildProfile() {
    final now = DateTime.now();
    final existing = state.existingProfile;
    final id = existing?.id ?? _uuid.v4();

    return PrinterProfile(
      id: id,
      displayName: state.displayName.isNotEmpty
          ? state.displayName
          : state.systemPrinterName,
      status: existing?.status ?? PrinterProfileStatus.active,
      printerIdentity: PrinterIdentity(
        systemPrinterName: state.systemPrinterName,
        manufacturer: state.manufacturer,
        model: state.model,
        driverName: state.driverName,
        driverVersion: state.driverVersion,
      ),
      capabilities: PrinterCapabilities(
        supportsCustomPaperSize: state.supportsCustomPaperSize,
        supportsPortraitCustomPaper: state.supportsPortraitCustomPaper,
        supportsLandscapeCustomPaper: state.supportsLandscapeCustomPaper,
        supportsManualFeed: state.supportsManualFeed,
        supportsBorderlessPrinting: state.supportsBorderlessPrinting,
        supportsTraySelection: state.supportsTraySelection,
      ),
      optimizationPreferences: OptimizationPreferences(
        allowScaling: state.allowScaling,
        allowTranslation: state.allowTranslation,
        allowStickerSpecificAdjustment: state.allowStickerSpecificAdjustment,
        minimumAcceptableScale: state.minimumAcceptableScale,
      ),
      trays: state.trays,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
      lastValidatedAt: existing?.lastValidatedAt,
    );
  }
}
