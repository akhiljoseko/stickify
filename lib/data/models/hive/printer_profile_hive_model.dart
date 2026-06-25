import 'package:hive_ce/hive.dart';
import 'package:stickify/domain/domain.dart';

/// Hive local persistence model for PrinterProfile.
class PrinterProfileHiveModel extends HiveObject {
  PrinterProfileHiveModel({
    required this.id,
    required this.displayName,
    required this.status,
    required this.printerIdentity,
    required this.capabilities,
    required this.optimizationPreferences,
    required this.trays,
    required this.createdAt,
    required this.updatedAt,
    this.lastValidatedAt,
  });

  factory PrinterProfileHiveModel.fromDomain(PrinterProfile p) {
    return PrinterProfileHiveModel(
      id: p.id,
      displayName: p.displayName,
      status: p.status.name,
      printerIdentity: PrinterIdentityHiveModel.fromDomain(p.printerIdentity),
      capabilities: PrinterCapabilitiesHiveModel.fromDomain(p.capabilities),
      optimizationPreferences: OptimizationPreferencesHiveModel.fromDomain(p.optimizationPreferences),
      trays: p.trays.map(PrinterTrayProfileHiveModel.fromDomain).toList(),
      createdAt: p.createdAt,
      updatedAt: p.updatedAt,
      lastValidatedAt: p.lastValidatedAt,
    );
  }

  final String id;
  final String displayName;
  final String status;
  final PrinterIdentityHiveModel printerIdentity;
  final PrinterCapabilitiesHiveModel capabilities;
  final OptimizationPreferencesHiveModel optimizationPreferences;
  final List<PrinterTrayProfileHiveModel> trays;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastValidatedAt;

  PrinterProfile toDomain() {
    final statusVal = PrinterProfileStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => PrinterProfileStatus.needsValidation,
    );

    return PrinterProfile(
      id: id,
      displayName: displayName,
      status: statusVal,
      printerIdentity: printerIdentity.toDomain(),
      capabilities: capabilities.toDomain(),
      optimizationPreferences: optimizationPreferences.toDomain(),
      trays: trays.map((t) => t.toDomain()).toList(),
      createdAt: createdAt,
      updatedAt: updatedAt,
      lastValidatedAt: lastValidatedAt,
    );
  }
}

class PrinterIdentityHiveModel extends HiveObject {
  PrinterIdentityHiveModel({
    required this.systemPrinterName,
    required this.manufacturer,
    required this.model,
    required this.driverName,
    required this.driverVersion,
  });

  factory PrinterIdentityHiveModel.fromDomain(PrinterIdentity id) {
    return PrinterIdentityHiveModel(
      systemPrinterName: id.systemPrinterName,
      manufacturer: id.manufacturer,
      model: id.model,
      driverName: id.driverName,
      driverVersion: id.driverVersion,
    );
  }

  final String systemPrinterName;
  final String manufacturer;
  final String model;
  final String driverName;
  final String driverVersion;

  PrinterIdentity toDomain() {
    return PrinterIdentity(
      systemPrinterName: systemPrinterName,
      manufacturer: manufacturer,
      model: model,
      driverName: driverName,
      driverVersion: driverVersion,
    );
  }
}

class PrinterCapabilitiesHiveModel extends HiveObject {
  PrinterCapabilitiesHiveModel({
    required this.supportsCustomPaperSize,
    required this.supportsPortraitCustomPaper,
    required this.supportsLandscapeCustomPaper,
    required this.supportsManualFeed,
    required this.supportsBorderlessPrinting,
    required this.supportsTraySelection,
    this.nonPrintableMarginLeft = 0.0,
    this.nonPrintableMarginRight = 0.0,
    this.nonPrintableMarginTop = 0.0,
    this.nonPrintableMarginBottom = 0.0,
  });

  factory PrinterCapabilitiesHiveModel.fromDomain(PrinterCapabilities cap) {
    return PrinterCapabilitiesHiveModel(
      supportsCustomPaperSize: cap.supportsCustomPaperSize,
      supportsPortraitCustomPaper: cap.supportsPortraitCustomPaper,
      supportsLandscapeCustomPaper: cap.supportsLandscapeCustomPaper,
      supportsManualFeed: cap.supportsManualFeed,
      supportsBorderlessPrinting: cap.supportsBorderlessPrinting,
      supportsTraySelection: cap.supportsTraySelection,
      nonPrintableMarginLeft: cap.nonPrintableMarginLeft,
      nonPrintableMarginRight: cap.nonPrintableMarginRight,
      nonPrintableMarginTop: cap.nonPrintableMarginTop,
      nonPrintableMarginBottom: cap.nonPrintableMarginBottom,
    );
  }

  final bool supportsCustomPaperSize;
  final bool supportsPortraitCustomPaper;
  final bool supportsLandscapeCustomPaper;
  final bool supportsManualFeed;
  final bool supportsBorderlessPrinting;
  final bool supportsTraySelection;
  final double nonPrintableMarginLeft;
  final double nonPrintableMarginRight;
  final double nonPrintableMarginTop;
  final double nonPrintableMarginBottom;

  PrinterCapabilities toDomain() {
    return PrinterCapabilities(
      supportsCustomPaperSize: supportsCustomPaperSize,
      supportsPortraitCustomPaper: supportsPortraitCustomPaper,
      supportsLandscapeCustomPaper: supportsLandscapeCustomPaper,
      supportsManualFeed: supportsManualFeed,
      supportsBorderlessPrinting: supportsBorderlessPrinting,
      supportsTraySelection: supportsTraySelection,
      nonPrintableMarginLeft: nonPrintableMarginLeft,
      nonPrintableMarginRight: nonPrintableMarginRight,
      nonPrintableMarginTop: nonPrintableMarginTop,
      nonPrintableMarginBottom: nonPrintableMarginBottom,
    );
  }
}

class OptimizationPreferencesHiveModel extends HiveObject {
  OptimizationPreferencesHiveModel({
    required this.allowScaling,
    required this.allowTranslation,
    required this.preferShrinkOverShift,
    required this.allowStickerSpecificAdjustment,
    this.minimumAcceptableScale = 0.7,
  });

  factory OptimizationPreferencesHiveModel.fromDomain(OptimizationPreferences pref) {
    return OptimizationPreferencesHiveModel(
      allowScaling: pref.allowScaling,
      allowTranslation: pref.allowTranslation,
      preferShrinkOverShift: pref.preferShrinkOverShift,
      allowStickerSpecificAdjustment: pref.allowStickerSpecificAdjustment,
      minimumAcceptableScale: pref.minimumAcceptableScale,
    );
  }

  final bool allowScaling;
  final bool allowTranslation;
  final bool preferShrinkOverShift;
  final bool allowStickerSpecificAdjustment;
  final double minimumAcceptableScale;

  OptimizationPreferences toDomain() {
    return OptimizationPreferences(
      allowScaling: allowScaling,
      allowTranslation: allowTranslation,
      preferShrinkOverShift: preferShrinkOverShift,
      allowStickerSpecificAdjustment: allowStickerSpecificAdjustment,
      minimumAcceptableScale: minimumAcceptableScale,
    );
  }
}

class PrinterTrayProfileHiveModel extends HiveObject {
  PrinterTrayProfileHiveModel({
    required this.trayIdentifier,
    required this.displayName,
    required this.supportedPaperConfigurations,
    required this.calibration,
  });

  factory PrinterTrayProfileHiveModel.fromDomain(PrinterTrayProfile t) {
    return PrinterTrayProfileHiveModel(
      trayIdentifier: t.trayIdentifier,
      displayName: t.displayName,
      supportedPaperConfigurations:
          t.supportedPaperConfigurations.map(PaperConfigurationReferenceHiveModel.fromDomain).toList(),
      calibration: PrinterCalibrationHiveModel.fromDomain(t.calibration),
    );
  }

  final String trayIdentifier;
  final String displayName;
  final List<PaperConfigurationReferenceHiveModel> supportedPaperConfigurations;
  final PrinterCalibrationHiveModel calibration;

  PrinterTrayProfile toDomain() {
    return PrinterTrayProfile(
      trayIdentifier: trayIdentifier,
      displayName: displayName,
      supportedPaperConfigurations: supportedPaperConfigurations.map((p) => p.toDomain()).toList(),
      calibration: calibration.toDomain(),
    );
  }
}

class PaperConfigurationReferenceHiveModel extends HiveObject {
  PaperConfigurationReferenceHiveModel({
    required this.id,
    required this.displayName,
  });

  factory PaperConfigurationReferenceHiveModel.fromDomain(PaperConfigurationReference ref) {
    return PaperConfigurationReferenceHiveModel(
      id: ref.id,
      displayName: ref.displayName,
    );
  }

  final String id;
  final String displayName;

  PaperConfigurationReference toDomain() {
    return PaperConfigurationReference(
      id: id,
      displayName: displayName,
    );
  }
}

class PrinterCalibrationHiveModel extends HiveObject {
  PrinterCalibrationHiveModel({
    required this.enabled,
    required this.calibrationRules,
    this.lastCalibratedAt,
  });

  factory PrinterCalibrationHiveModel.fromDomain(PrinterCalibration cal) {
    return PrinterCalibrationHiveModel(
      enabled: cal.enabled,
      calibrationRules: cal.calibrationRules.map(CalibrationRuleHiveModel.fromDomain).toList(),
      lastCalibratedAt: cal.lastCalibratedAt,
    );
  }

  final bool enabled;
  final List<CalibrationRuleHiveModel> calibrationRules;
  final DateTime? lastCalibratedAt;

  PrinterCalibration toDomain() {
    return PrinterCalibration(
      enabled: enabled,
      calibrationRules: calibrationRules.map((r) => r.toDomain()).toList(),
      lastCalibratedAt: lastCalibratedAt,
    );
  }
}

class CalibrationRuleHiveModel extends HiveObject {
  CalibrationRuleHiveModel({
    required this.target,
    required this.transformation,
  });

  factory CalibrationRuleHiveModel.fromDomain(CalibrationRule r) {
    return CalibrationRuleHiveModel(
      target: CalibrationTargetHiveModel.fromDomain(r.target),
      transformation: PrintStickerTransformHiveModel.fromDomain(r.transformation),
    );
  }

  final CalibrationTargetHiveModel target;
  final PrintStickerTransformHiveModel transformation;

  CalibrationRule toDomain() {
    return CalibrationRule(
      target: target.toDomain(),
      transformation: transformation.toDomain(),
    );
  }
}

class CalibrationTargetHiveModel extends HiveObject {
  CalibrationTargetHiveModel({
    required this.type,
    this.index,
    this.edgeGroup,
  });

  factory CalibrationTargetHiveModel.fromDomain(CalibrationTarget target) {
    return CalibrationTargetHiveModel(
      type: target.type.name,
      index: target.index,
      edgeGroup: target.edgeGroup?.name,
    );
  }

  final String type;
  final int? index;
  final String? edgeGroup;

  CalibrationTarget toDomain() {
    final typeVal = TargetType.values.firstWhere(
      (e) => e.name == type,
      orElse: () => TargetType.sheet,
    );
    final edgeGroupVal = edgeGroup != null
        ? EdgeGroup.values.firstWhere(
            (e) => e.name == edgeGroup,
            orElse: () => EdgeGroup.left,
          )
        : null;

    return CalibrationTarget.raw(
      type: typeVal,
      index: index,
      edgeGroup: edgeGroupVal,
    );
  }
}

class PrintStickerTransformHiveModel extends HiveObject {
  PrintStickerTransformHiveModel({
    required this.offsetX,
    required this.offsetY,
    required this.scaleX,
    required this.scaleY,
    required this.anchorX,
    required this.anchorY,
  });

  factory PrintStickerTransformHiveModel.fromDomain(PrintStickerTransform trans) {
    return PrintStickerTransformHiveModel(
      offsetX: trans.offsetX,
      offsetY: trans.offsetY,
      scaleX: trans.scaleX,
      scaleY: trans.scaleY,
      anchorX: trans.anchorX,
      anchorY: trans.anchorY,
    );
  }

  final double offsetX;
  final double offsetY;
  final double scaleX;
  final double scaleY;
  final double anchorX;
  final double anchorY;

  PrintStickerTransform toDomain() {
    return PrintStickerTransform(
      offsetX: offsetX,
      offsetY: offsetY,
      scaleX: scaleX,
      scaleY: scaleY,
      anchorX: anchorX,
      anchorY: anchorY,
    );
  }
}
