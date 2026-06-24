import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stickify/domain/domain.dart';

/// Firestore persistence model for PrinterProfile aggregates.
class PrinterProfileFirestoreModel {
  PrinterProfileFirestoreModel({
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

  factory PrinterProfileFirestoreModel.fromDomain(PrinterProfile p) {
    return PrinterProfileFirestoreModel(
      id: p.id,
      displayName: p.displayName,
      status: p.status.name,
      printerIdentity: PrinterIdentityFirestoreModel.fromDomain(p.printerIdentity),
      capabilities: PrinterCapabilitiesFirestoreModel.fromDomain(p.capabilities),
      optimizationPreferences: OptimizationPreferencesFirestoreModel.fromDomain(p.optimizationPreferences),
      trays: p.trays.map(PrinterTrayProfileFirestoreModel.fromDomain).toList(),
      createdAt: p.createdAt,
      updatedAt: p.updatedAt,
      lastValidatedAt: p.lastValidatedAt,
    );
  }

  factory PrinterProfileFirestoreModel.fromMap(String id, Map<String, dynamic> json) {
    return PrinterProfileFirestoreModel(
      id: id,
      displayName: json['displayName'] as String? ?? '',
      status: json['status'] as String? ?? PrinterProfileStatus.needsValidation.name,
      printerIdentity: PrinterIdentityFirestoreModel.fromMap(
        json['printerIdentity'] as Map<String, dynamic>? ?? const {},
      ),
      capabilities: PrinterCapabilitiesFirestoreModel.fromMap(
        json['capabilities'] as Map<String, dynamic>? ?? const {},
      ),
      optimizationPreferences: OptimizationPreferencesFirestoreModel.fromMap(
        json['optimizationPreferences'] as Map<String, dynamic>? ?? const {},
      ),
      trays: (json['trays'] as List? ?? [])
          .map((item) => PrinterTrayProfileFirestoreModel.fromMap(item as Map<String, dynamic>))
          .toList(),
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastValidatedAt: (json['lastValidatedAt'] as Timestamp?)?.toDate(),
    );
  }

  final String id;
  final String displayName;
  final String status;
  final PrinterIdentityFirestoreModel printerIdentity;
  final PrinterCapabilitiesFirestoreModel capabilities;
  final OptimizationPreferencesFirestoreModel optimizationPreferences;
  final List<PrinterTrayProfileFirestoreModel> trays;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastValidatedAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'displayName': displayName,
      'status': status,
      'printerIdentity': printerIdentity.toMap(),
      'capabilities': capabilities.toMap(),
      'optimizationPreferences': optimizationPreferences.toMap(),
      'trays': trays.map((t) => t.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'lastValidatedAt': lastValidatedAt != null ? Timestamp.fromDate(lastValidatedAt!) : null,
    };
  }

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

class PrinterIdentityFirestoreModel {
  PrinterIdentityFirestoreModel({
    required this.systemPrinterName,
    required this.manufacturer,
    required this.model,
    required this.driverName,
    required this.driverVersion,
  });

  factory PrinterIdentityFirestoreModel.fromDomain(PrinterIdentity id) {
    return PrinterIdentityFirestoreModel(
      systemPrinterName: id.systemPrinterName,
      manufacturer: id.manufacturer,
      model: id.model,
      driverName: id.driverName,
      driverVersion: id.driverVersion,
    );
  }

  factory PrinterIdentityFirestoreModel.fromMap(Map<String, dynamic> m) {
    return PrinterIdentityFirestoreModel(
      systemPrinterName: m['systemPrinterName'] as String? ?? '',
      manufacturer: m['manufacturer'] as String? ?? '',
      model: m['model'] as String? ?? '',
      driverName: m['driverName'] as String? ?? '',
      driverVersion: m['driverVersion'] as String? ?? '',
    );
  }

  final String systemPrinterName;
  final String manufacturer;
  final String model;
  final String driverName;
  final String driverVersion;

  Map<String, dynamic> toMap() {
    return {
      'systemPrinterName': systemPrinterName,
      'manufacturer': manufacturer,
      'model': model,
      'driverName': driverName,
      'driverVersion': driverVersion,
    };
  }

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

class PrinterCapabilitiesFirestoreModel {
  PrinterCapabilitiesFirestoreModel({
    required this.supportsCustomPaperSize,
    required this.supportsPortraitCustomPaper,
    required this.supportsLandscapeCustomPaper,
    required this.supportsManualFeed,
    required this.supportsBorderlessPrinting,
    required this.supportsTraySelection,
  });

  factory PrinterCapabilitiesFirestoreModel.fromDomain(PrinterCapabilities cap) {
    return PrinterCapabilitiesFirestoreModel(
      supportsCustomPaperSize: cap.supportsCustomPaperSize,
      supportsPortraitCustomPaper: cap.supportsPortraitCustomPaper,
      supportsLandscapeCustomPaper: cap.supportsLandscapeCustomPaper,
      supportsManualFeed: cap.supportsManualFeed,
      supportsBorderlessPrinting: cap.supportsBorderlessPrinting,
      supportsTraySelection: cap.supportsTraySelection,
    );
  }

  factory PrinterCapabilitiesFirestoreModel.fromMap(Map<String, dynamic> m) {
    return PrinterCapabilitiesFirestoreModel(
      supportsCustomPaperSize: m['supportsCustomPaperSize'] as bool? ?? false,
      supportsPortraitCustomPaper: m['supportsPortraitCustomPaper'] as bool? ?? false,
      supportsLandscapeCustomPaper: m['supportsLandscapeCustomPaper'] as bool? ?? false,
      supportsManualFeed: m['supportsManualFeed'] as bool? ?? false,
      supportsBorderlessPrinting: m['supportsBorderlessPrinting'] as bool? ?? false,
      supportsTraySelection: m['supportsTraySelection'] as bool? ?? false,
    );
  }

  final bool supportsCustomPaperSize;
  final bool supportsPortraitCustomPaper;
  final bool supportsLandscapeCustomPaper;
  final bool supportsManualFeed;
  final bool supportsBorderlessPrinting;
  final bool supportsTraySelection;

  Map<String, dynamic> toMap() {
    return {
      'supportsCustomPaperSize': supportsCustomPaperSize,
      'supportsPortraitCustomPaper': supportsPortraitCustomPaper,
      'supportsLandscapeCustomPaper': supportsLandscapeCustomPaper,
      'supportsManualFeed': supportsManualFeed,
      'supportsBorderlessPrinting': supportsBorderlessPrinting,
      'supportsTraySelection': supportsTraySelection,
    };
  }

  PrinterCapabilities toDomain() {
    return PrinterCapabilities(
      supportsCustomPaperSize: supportsCustomPaperSize,
      supportsPortraitCustomPaper: supportsPortraitCustomPaper,
      supportsLandscapeCustomPaper: supportsLandscapeCustomPaper,
      supportsManualFeed: supportsManualFeed,
      supportsBorderlessPrinting: supportsBorderlessPrinting,
      supportsTraySelection: supportsTraySelection,
    );
  }
}

class OptimizationPreferencesFirestoreModel {
  OptimizationPreferencesFirestoreModel({
    required this.allowScaling,
    required this.allowTranslation,
    required this.preferShrinkOverShift,
    required this.allowStickerSpecificAdjustment,
  });

  factory OptimizationPreferencesFirestoreModel.fromDomain(OptimizationPreferences pref) {
    return OptimizationPreferencesFirestoreModel(
      allowScaling: pref.allowScaling,
      allowTranslation: pref.allowTranslation,
      preferShrinkOverShift: pref.preferShrinkOverShift,
      allowStickerSpecificAdjustment: pref.allowStickerSpecificAdjustment,
    );
  }

  factory OptimizationPreferencesFirestoreModel.fromMap(Map<String, dynamic> m) {
    return OptimizationPreferencesFirestoreModel(
      allowScaling: m['allowScaling'] as bool? ?? true,
      allowTranslation: m['allowTranslation'] as bool? ?? true,
      preferShrinkOverShift: m['preferShrinkOverShift'] as bool? ?? false,
      allowStickerSpecificAdjustment: m['allowStickerSpecificAdjustment'] as bool? ?? true,
    );
  }

  final bool allowScaling;
  final bool allowTranslation;
  final bool preferShrinkOverShift;
  final bool allowStickerSpecificAdjustment;

  Map<String, dynamic> toMap() {
    return {
      'allowScaling': allowScaling,
      'allowTranslation': allowTranslation,
      'preferShrinkOverShift': preferShrinkOverShift,
      'allowStickerSpecificAdjustment': allowStickerSpecificAdjustment,
    };
  }

  OptimizationPreferences toDomain() {
    return OptimizationPreferences(
      allowScaling: allowScaling,
      allowTranslation: allowTranslation,
      preferShrinkOverShift: preferShrinkOverShift,
      allowStickerSpecificAdjustment: allowStickerSpecificAdjustment,
    );
  }
}

class PrinterTrayProfileFirestoreModel {
  PrinterTrayProfileFirestoreModel({
    required this.trayIdentifier,
    required this.displayName,
    required this.supportedPaperConfigurations,
    required this.calibration,
  });

  factory PrinterTrayProfileFirestoreModel.fromDomain(PrinterTrayProfile t) {
    return PrinterTrayProfileFirestoreModel(
      trayIdentifier: t.trayIdentifier,
      displayName: t.displayName,
      supportedPaperConfigurations:
          t.supportedPaperConfigurations.map(PaperConfigurationReferenceFirestoreModel.fromDomain).toList(),
      calibration: PrinterCalibrationFirestoreModel.fromDomain(t.calibration),
    );
  }

  factory PrinterTrayProfileFirestoreModel.fromMap(Map<String, dynamic> m) {
    return PrinterTrayProfileFirestoreModel(
      trayIdentifier: m['trayIdentifier'] as String? ?? '',
      displayName: m['displayName'] as String? ?? '',
      supportedPaperConfigurations: (m['supportedPaperConfigurations'] as List? ?? [])
          .map((item) => PaperConfigurationReferenceFirestoreModel.fromMap(item as Map<String, dynamic>))
          .toList(),
      calibration: PrinterCalibrationFirestoreModel.fromMap(
        m['calibration'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }

  final String trayIdentifier;
  final String displayName;
  final List<PaperConfigurationReferenceFirestoreModel> supportedPaperConfigurations;
  final PrinterCalibrationFirestoreModel calibration;

  Map<String, dynamic> toMap() {
    return {
      'trayIdentifier': trayIdentifier,
      'displayName': displayName,
      'supportedPaperConfigurations': supportedPaperConfigurations.map((p) => p.toMap()).toList(),
      'calibration': calibration.toMap(),
    };
  }

  PrinterTrayProfile toDomain() {
    return PrinterTrayProfile(
      trayIdentifier: trayIdentifier,
      displayName: displayName,
      supportedPaperConfigurations: supportedPaperConfigurations.map((p) => p.toDomain()).toList(),
      calibration: calibration.toDomain(),
    );
  }
}

class PaperConfigurationReferenceFirestoreModel {
  PaperConfigurationReferenceFirestoreModel({
    required this.id,
    required this.displayName,
  });

  factory PaperConfigurationReferenceFirestoreModel.fromDomain(PaperConfigurationReference ref) {
    return PaperConfigurationReferenceFirestoreModel(
      id: ref.id,
      displayName: ref.displayName,
    );
  }

  factory PaperConfigurationReferenceFirestoreModel.fromMap(Map<String, dynamic> m) {
    return PaperConfigurationReferenceFirestoreModel(
      id: m['id'] as String? ?? '',
      displayName: m['displayName'] as String? ?? '',
    );
  }

  final String id;
  final String displayName;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'displayName': displayName,
    };
  }

  PaperConfigurationReference toDomain() {
    return PaperConfigurationReference(
      id: id,
      displayName: displayName,
    );
  }
}

class PrinterCalibrationFirestoreModel {
  PrinterCalibrationFirestoreModel({
    required this.enabled,
    required this.calibrationRules,
    this.lastCalibratedAt,
  });

  factory PrinterCalibrationFirestoreModel.fromDomain(PrinterCalibration cal) {
    return PrinterCalibrationFirestoreModel(
      enabled: cal.enabled,
      calibrationRules: cal.calibrationRules.map(CalibrationRuleFirestoreModel.fromDomain).toList(),
      lastCalibratedAt: cal.lastCalibratedAt,
    );
  }

  factory PrinterCalibrationFirestoreModel.fromMap(Map<String, dynamic> m) {
    return PrinterCalibrationFirestoreModel(
      enabled: m['enabled'] as bool? ?? false,
      calibrationRules: (m['calibrationRules'] as List? ?? [])
          .map((item) => CalibrationRuleFirestoreModel.fromMap(item as Map<String, dynamic>))
          .toList(),
      lastCalibratedAt: (m['lastCalibratedAt'] as Timestamp?)?.toDate(),
    );
  }

  final bool enabled;
  final List<CalibrationRuleFirestoreModel> calibrationRules;
  final DateTime? lastCalibratedAt;

  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled,
      'calibrationRules': calibrationRules.map((r) => r.toMap()).toList(),
      'lastCalibratedAt': lastCalibratedAt != null ? Timestamp.fromDate(lastCalibratedAt!) : null,
    };
  }

  PrinterCalibration toDomain() {
    return PrinterCalibration(
      enabled: enabled,
      calibrationRules: calibrationRules.map((r) => r.toDomain()).toList(),
      lastCalibratedAt: lastCalibratedAt,
    );
  }
}

class CalibrationRuleFirestoreModel {
  CalibrationRuleFirestoreModel({
    required this.target,
    required this.transformation,
  });

  factory CalibrationRuleFirestoreModel.fromDomain(CalibrationRule r) {
    return CalibrationRuleFirestoreModel(
      target: CalibrationTargetFirestoreModel.fromDomain(r.target),
      transformation: PrintStickerTransformFirestoreModel.fromDomain(r.transformation),
    );
  }

  factory CalibrationRuleFirestoreModel.fromMap(Map<String, dynamic> m) {
    return CalibrationRuleFirestoreModel(
      target: CalibrationTargetFirestoreModel.fromMap(
        m['target'] as Map<String, dynamic>? ?? const {},
      ),
      transformation: PrintStickerTransformFirestoreModel.fromMap(
        m['transformation'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }

  final CalibrationTargetFirestoreModel target;
  final PrintStickerTransformFirestoreModel transformation;

  Map<String, dynamic> toMap() {
    return {
      'target': target.toMap(),
      'transformation': transformation.toMap(),
    };
  }

  CalibrationRule toDomain() {
    return CalibrationRule(
      target: target.toDomain(),
      transformation: transformation.toDomain(),
    );
  }
}

class CalibrationTargetFirestoreModel {
  CalibrationTargetFirestoreModel({
    required this.type,
    this.index,
    this.edgeGroup,
  });

  factory CalibrationTargetFirestoreModel.fromDomain(CalibrationTarget target) {
    return CalibrationTargetFirestoreModel(
      type: target.type.name,
      index: target.index,
      edgeGroup: target.edgeGroup?.name,
    );
  }

  factory CalibrationTargetFirestoreModel.fromMap(Map<String, dynamic> m) {
    return CalibrationTargetFirestoreModel(
      type: m['type'] as String? ?? TargetType.sheet.name,
      index: m['index'] as int?,
      edgeGroup: m['edgeGroup'] as String?,
    );
  }

  final String type;
  final int? index;
  final String? edgeGroup;

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'index': index,
      'edgeGroup': edgeGroup,
    };
  }

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

class PrintStickerTransformFirestoreModel {
  PrintStickerTransformFirestoreModel({
    required this.offsetX,
    required this.offsetY,
    required this.scaleX,
    required this.scaleY,
    required this.anchorX,
    required this.anchorY,
  });

  factory PrintStickerTransformFirestoreModel.fromDomain(PrintStickerTransform trans) {
    return PrintStickerTransformFirestoreModel(
      offsetX: trans.offsetX,
      offsetY: trans.offsetY,
      scaleX: trans.scaleX,
      scaleY: trans.scaleY,
      anchorX: trans.anchorX,
      anchorY: trans.anchorY,
    );
  }

  factory PrintStickerTransformFirestoreModel.fromMap(Map<String, dynamic> m) {
    return PrintStickerTransformFirestoreModel(
      offsetX: (m['offsetX'] as num? ?? 0.0).toDouble(),
      offsetY: (m['offsetY'] as num? ?? 0.0).toDouble(),
      scaleX: (m['scaleX'] as num? ?? 1.0).toDouble(),
      scaleY: (m['scaleY'] as num? ?? 1.0).toDouble(),
      anchorX: (m['anchorX'] as num? ?? 0.5).toDouble(),
      anchorY: (m['anchorY'] as num? ?? 0.5).toDouble(),
    );
  }

  final double offsetX;
  final double offsetY;
  final double scaleX;
  final double scaleY;
  final double anchorX;
  final double anchorY;

  Map<String, dynamic> toMap() {
    return {
      'offsetX': offsetX,
      'offsetY': offsetY,
      'scaleX': scaleX,
      'scaleY': scaleY,
      'anchorX': anchorX,
      'anchorY': anchorY,
    };
  }

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
