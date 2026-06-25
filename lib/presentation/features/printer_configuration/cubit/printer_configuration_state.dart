import 'package:equatable/equatable.dart';
import 'package:stickify/domain/domain.dart';

enum PrinterConfigurationStatus {
  idle,
  saving,
  saved,
  error,
}

class PrinterConfigurationState extends Equatable {
  const PrinterConfigurationState({
    required this.status,
    this.displayName = '',
    this.systemPrinterName = '',
    this.manufacturer = '',
    this.model = '',
    this.driverName = '',
    this.driverVersion = '',
    this.supportsCustomPaperSize = true,
    this.supportsPortraitCustomPaper = true,
    this.supportsLandscapeCustomPaper = true,
    this.supportsManualFeed = true,
    this.supportsBorderlessPrinting = false,
    this.supportsTraySelection = true,
    this.allowScaling = true,
    this.allowTranslation = true,
    this.preferShrinkOverShift = true,
    this.allowStickerSpecificAdjustment = true,
    this.minimumAcceptableScale = 0.7,
    this.trays = const [],
    this.errorMessage,
    this.existingProfile,
  });

  const PrinterConfigurationState.initial()
      : this(status: PrinterConfigurationStatus.idle);

  final PrinterConfigurationStatus status;
  final String displayName;
  final String systemPrinterName;
  final String manufacturer;
  final String model;
  final String driverName;
  final String driverVersion;
  final bool supportsCustomPaperSize;
  final bool supportsPortraitCustomPaper;
  final bool supportsLandscapeCustomPaper;
  final bool supportsManualFeed;
  final bool supportsBorderlessPrinting;
  final bool supportsTraySelection;
  final bool allowScaling;
  final bool allowTranslation;
  final bool preferShrinkOverShift;
  final bool allowStickerSpecificAdjustment;
  final double minimumAcceptableScale;
  final List<PrinterTrayProfile> trays;
  final String? errorMessage;
  final PrinterProfile? existingProfile;

  bool get isEditing => existingProfile != null;

  PrinterConfigurationState copyWith({
    PrinterConfigurationStatus? status,
    String? displayName,
    String? systemPrinterName,
    String? manufacturer,
    String? model,
    String? driverName,
    String? driverVersion,
    bool? supportsCustomPaperSize,
    bool? supportsPortraitCustomPaper,
    bool? supportsLandscapeCustomPaper,
    bool? supportsManualFeed,
    bool? supportsBorderlessPrinting,
    bool? supportsTraySelection,
    bool? allowScaling,
    bool? allowTranslation,
    bool? preferShrinkOverShift,
    bool? allowStickerSpecificAdjustment,
    double? minimumAcceptableScale,
    List<PrinterTrayProfile>? trays,
    String? Function()? errorMessage,
    PrinterProfile? existingProfile,
  }) {
    return PrinterConfigurationState(
      status: status ?? this.status,
      displayName: displayName ?? this.displayName,
      systemPrinterName: systemPrinterName ?? this.systemPrinterName,
      manufacturer: manufacturer ?? this.manufacturer,
      model: model ?? this.model,
      driverName: driverName ?? this.driverName,
      driverVersion: driverVersion ?? this.driverVersion,
      supportsCustomPaperSize:
          supportsCustomPaperSize ?? this.supportsCustomPaperSize,
      supportsPortraitCustomPaper:
          supportsPortraitCustomPaper ?? this.supportsPortraitCustomPaper,
      supportsLandscapeCustomPaper:
          supportsLandscapeCustomPaper ?? this.supportsLandscapeCustomPaper,
      supportsManualFeed: supportsManualFeed ?? this.supportsManualFeed,
      supportsBorderlessPrinting:
          supportsBorderlessPrinting ?? this.supportsBorderlessPrinting,
      supportsTraySelection:
          supportsTraySelection ?? this.supportsTraySelection,
      allowScaling: allowScaling ?? this.allowScaling,
      allowTranslation: allowTranslation ?? this.allowTranslation,
      preferShrinkOverShift:
          preferShrinkOverShift ?? this.preferShrinkOverShift,
      allowStickerSpecificAdjustment:
          allowStickerSpecificAdjustment ?? this.allowStickerSpecificAdjustment,
      minimumAcceptableScale:
          minimumAcceptableScale ?? this.minimumAcceptableScale,
      trays: trays ?? this.trays,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      existingProfile: existingProfile ?? this.existingProfile,
    );
  }

  @override
  List<Object?> get props => [
        status,
        displayName,
        systemPrinterName,
        manufacturer,
        model,
        driverName,
        driverVersion,
        supportsCustomPaperSize,
        supportsPortraitCustomPaper,
        supportsLandscapeCustomPaper,
        supportsManualFeed,
        supportsBorderlessPrinting,
        supportsTraySelection,
        allowScaling,
        allowTranslation,
        preferShrinkOverShift,
        allowStickerSpecificAdjustment,
        minimumAcceptableScale,
        trays,
        errorMessage,
        existingProfile,
      ];
}
