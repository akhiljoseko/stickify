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

  void setNonPrintableMarginLeft(double value) {
    emit(state.copyWith(nonPrintableMarginLeft: value));
  }

  void setNonPrintableMarginRight(double value) {
    emit(state.copyWith(nonPrintableMarginRight: value));
  }

  void setNonPrintableMarginTop(double value) {
    emit(state.copyWith(nonPrintableMarginTop: value));
  }

  void setNonPrintableMarginBottom(double value) {
    emit(state.copyWith(nonPrintableMarginBottom: value));
  }

  void setAllowScaling(bool value) {
    emit(state.copyWith(allowScaling: value));
  }

  void setAllowTranslation(bool value) {
    emit(state.copyWith(allowTranslation: value));
  }

  void setPreferShrinkOverShift(bool value) {
    emit(state.copyWith(preferShrinkOverShift: value));
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
        nonPrintableMarginLeft: profile.capabilities.nonPrintableMarginLeft,
        nonPrintableMarginRight: profile.capabilities.nonPrintableMarginRight,
        nonPrintableMarginTop: profile.capabilities.nonPrintableMarginTop,
        nonPrintableMarginBottom: profile.capabilities.nonPrintableMarginBottom,
        allowScaling: profile.optimizationPreferences.allowScaling,
        allowTranslation: profile.optimizationPreferences.allowTranslation,
        preferShrinkOverShift:
            profile.optimizationPreferences.preferShrinkOverShift,
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
    emit(state.copyWith(status: PrinterConfigurationStatus.saving));

    final profile = _buildProfile();
    final result = await printerProfileRepository.saveProfile(profile);
    switch (result) {
      case Failure(:final error):
        emit(
          state.copyWith(
            status: PrinterConfigurationStatus.error,
            errorMessage: () => 'Failed to save: ${error.message}',
          ),
        );
        return Result.failure(error);
      case Success():
        emit(state.copyWith(status: PrinterConfigurationStatus.saved));
        return Result.success(profile);
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
        nonPrintableMarginLeft: state.nonPrintableMarginLeft,
        nonPrintableMarginRight: state.nonPrintableMarginRight,
        nonPrintableMarginTop: state.nonPrintableMarginTop,
        nonPrintableMarginBottom: state.nonPrintableMarginBottom,
      ),
      optimizationPreferences: OptimizationPreferences(
        allowScaling: state.allowScaling,
        allowTranslation: state.allowTranslation,
        preferShrinkOverShift: state.preferShrinkOverShift,
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
