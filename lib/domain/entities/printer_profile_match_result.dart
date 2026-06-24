import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:stickify/domain/entities/discovered_printer.dart';
import 'package:stickify/domain/entities/printer_profile.dart';

/// Represents the classification of how a discovered OS printer matches a stored
/// technician-configured [PrinterProfile].
enum PrinterProfileMatchStatus {
  /// The discovered printer exactly matches the saved profile (e.g. same name/address).
  matched,

  /// The saved profile could not be found on the host system.
  missing,

  /// The discovered printer has minor name/driver changes but is compatible.
  compatible,

  /// The discovered printer is incompatible with the saved profile (e.g. driver mismatch).
  incompatible,
}

/// Represents the reconciliation outcome between a stored [PrinterProfile] and a
/// dynamically [DiscoveredPrinter].
@immutable
class PrinterProfileMatchResult extends Equatable {
  /// Creates a [PrinterProfileMatchResult] instance.
  ///
  /// Enforces that [discoveredPrinter] is present for matched, compatible, and
  /// incompatible statuses, and absent for missing status.
  const PrinterProfileMatchResult({
    required this.profile,
    required this.status,
    this.discoveredPrinter,
  })  : assert(
          status != PrinterProfileMatchStatus.matched ||
              discoveredPrinter != null,
          'matched status requires a discovered printer',
        ),
        assert(
          status != PrinterProfileMatchStatus.compatible ||
              discoveredPrinter != null,
          'compatible status requires a discovered printer',
        ),
        assert(
          status != PrinterProfileMatchStatus.incompatible ||
              discoveredPrinter != null,
          'incompatible status requires a discovered printer',
        ),
        assert(
          status != PrinterProfileMatchStatus.missing ||
              discoveredPrinter == null,
          'missing status cannot contain a discovered printer',
        );

  /// The technician-configured printer profile.
  final PrinterProfile profile;

  /// The dynamic OS printer discovered at runtime, if present.
  final DiscoveredPrinter? discoveredPrinter;

  /// The status outcome of the match comparison.
  final PrinterProfileMatchStatus status;

  @override
  List<Object?> get props => [
        profile,
        discoveredPrinter,
        status,
      ];

  @override
  String toString() =>
      'PrinterProfileMatchResult(profileId: ${profile.id}, status: $status, '
      'hasDiscoveredPrinter: ${discoveredPrinter != null})';
}
