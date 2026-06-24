import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// Represents a physical printer's metadata and system identifier.
///
/// Under real-world Windows environments, driver-provided metadata is often
/// inconsistent or incomplete. Therefore, only [systemPrinterName] (the primary
/// identifier used to resolve physical connections) is strictly enforced as non-empty.
/// The remaining fields are allowed to be empty strings.
@immutable
class PrinterIdentity extends Equatable {
  /// Creates a [PrinterIdentity] with the given printer metadata.
  const PrinterIdentity({
    required this.systemPrinterName,
    this.manufacturer = '',
    this.model = '',
    this.driverName = '',
    this.driverVersion = '',
  }) : assert(
          systemPrinterName.length > 0,
          'systemPrinterName cannot be empty',
        );

  /// The physical printer manufacturer (e.g. "Zebra", "HP"). Can be empty.
  final String manufacturer;

  /// The printer hardware model (e.g. "ZT411", "LaserJet M404"). Can be empty.
  final String model;

  /// The active Windows printer driver name. Can be empty.
  final String driverName;

  /// The active Windows printer driver version string. Can be empty.
  final String driverVersion;

  /// The local OS printer name used to locate and stream print jobs. Required.
  final String systemPrinterName;

  @override
  List<Object?> get props => [
    manufacturer,
    model,
    driverName,
    driverVersion,
    systemPrinterName,
  ];

  @override
  String toString() =>
      'PrinterIdentity(manufacturer: $manufacturer, model: $model, '
      'driverName: $driverName, driverVersion: $driverVersion, '
      'systemPrinterName: $systemPrinterName)';
}
