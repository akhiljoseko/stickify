import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:stickify/domain/entities/printer_profile.dart';

/// Represents the availability state of a discovered OS printer.
enum DiscoveredPrinterStatus {
  /// The printer is reachable and ready for printing.
  online,

  /// The printer exists on the OS but is currently unreachable (e.g. disconnected or sleeping).
  offline,

  /// The OS reports that the printer exists but cannot be used (e.g. driver corruption).
  unavailable,

  /// The OS could not determine the printer state.
  unknown,
}

/// Represents a physical printer discovered from the host operating system.
///
/// Unlike [PrinterProfile] (which represents expected, technician-configured settings),
/// [DiscoveredPrinter] represents the dynamic, actual state of the printer as returned by the OS.
@immutable
class DiscoveredPrinter extends Equatable {
  /// Creates a [DiscoveredPrinter] instance.
  ///
  /// Enforces that [systemPrinterName] must not be empty.
  const DiscoveredPrinter({
    required this.systemPrinterName,
    required this.status,
    this.manufacturer = '',
    this.model = '',
    this.driverName = '',
    this.driverVersion = '',
  }) : assert(
          systemPrinterName.length > 0,
          'systemPrinterName must not be empty',
        );

  /// The exact printer name returned by the operating system.
  final String systemPrinterName;

  /// The manufacturer metadata reported by the driver. Defaults to an empty string.
  final String manufacturer;

  /// The printer model metadata reported by the driver. Defaults to an empty string.
  final String model;

  /// The name of the driver registered for the printer. Defaults to an empty string.
  final String driverName;

  /// The version of the driver registered for the printer. Defaults to an empty string.
  final String driverVersion;

  /// The runtime status of the printer.
  final DiscoveredPrinterStatus status;

  @override
  List<Object?> get props => [
        systemPrinterName,
        manufacturer,
        model,
        driverName,
        driverVersion,
        status,
      ];

  @override
  String toString() =>
      'DiscoveredPrinter(systemPrinterName: $systemPrinterName, status: $status)';
}
