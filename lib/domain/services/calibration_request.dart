import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:stickify/domain/entities/printer_tray_profile.dart';
import 'package:stickify/domain/entities/sheet_config.dart';

/// Represents the request parameters for running the calibration resolution engine.
///
/// Encapsulates the selected printer tray, target paper configuration template,
/// and the sheet configuration to calibrate.
@immutable
class CalibrationRequest extends Equatable {
  /// Creates a [CalibrationRequest].
  const CalibrationRequest({
    required this.tray,
    required this.paperConfigId,
    required this.sheetConfig,
  });

  /// The printer tray profile containing calibration rules.
  final PrinterTrayProfile tray;

  /// The unique identifier representing the paper template configuration.
  final String paperConfigId;

  /// The physical grid layout parameters of the sheet.
  final SheetConfig sheetConfig;

  @override
  List<Object?> get props => [tray, paperConfigId, sheetConfig];

  @override
  String toString() =>
      'CalibrationRequest(tray: ${tray.trayIdentifier}, '
      'paperConfigId: $paperConfigId, '
      'sheetConfig: ${sheetConfig.columns}x${sheetConfig.rows})';
}
