import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:stickify/domain/entities/paper_configuration_reference.dart';
import 'package:stickify/domain/entities/printer_calibration.dart';

/// Represents a single paper input tray configuration for a printer.
@immutable
class PrinterTrayProfile extends Equatable {
  PrinterTrayProfile({
    required this.trayIdentifier,
    required this.displayName,
    required List<PaperConfigurationReference> supportedPaperConfigurations,
    required this.calibration,
    this.nonPrintableMarginLeft = 0.0,
    this.nonPrintableMarginRight = 0.0,
    this.nonPrintableMarginTop = 0.0,
    this.nonPrintableMarginBottom = 0.0,
  })  : supportedPaperConfigurations = List.unmodifiable(supportedPaperConfigurations),
        assert(
          trayIdentifier.isNotEmpty,
          'trayIdentifier cannot be empty',
        ),
        assert(
          displayName.isNotEmpty,
          'displayName cannot be empty',
        );

  /// The physical tray identifier string (e.g. "tray_1", "manual_feed"). Required.
  final String trayIdentifier;

  /// Human-readable label for this tray configuration. Required.
  final String displayName;

  /// The list of application-defined sheet template formats this tray supports.
  final List<PaperConfigurationReference> supportedPaperConfigurations;

  /// The tray-specific calibration rules.
  final PrinterCalibration calibration;

  /// The left non-printable margin for this tray in millimeters.
  final double nonPrintableMarginLeft;

  /// The right non-printable margin for this tray in millimeters.
  final double nonPrintableMarginRight;

  /// The top non-printable margin for this tray in millimeters.
  final double nonPrintableMarginTop;

  /// The bottom non-printable margin for this tray in millimeters.
  final double nonPrintableMarginBottom;

  @override
  List<Object?> get props => [
        trayIdentifier,
        displayName,
        supportedPaperConfigurations,
        calibration,
        nonPrintableMarginLeft,
        nonPrintableMarginRight,
        nonPrintableMarginTop,
        nonPrintableMarginBottom,
      ];

  @override
  String toString() =>
      'PrinterTrayProfile(trayIdentifier: $trayIdentifier, displayName: $displayName, '
      'supportedPaperCount: ${supportedPaperConfigurations.length}, '
      'calibration: $calibration, '
      'margins: L=$nonPrintableMarginLeft R=$nonPrintableMarginRight '
      'T=$nonPrintableMarginTop B=$nonPrintableMarginBottom)';
}
