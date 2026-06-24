import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:stickify/domain/entities/optimization_preferences.dart';
import 'package:stickify/domain/entities/printer_capabilities.dart';
import 'package:stickify/domain/entities/printer_identity.dart';
import 'package:stickify/domain/entities/printer_tray_profile.dart';

/// The administrative status of a printer profile.
enum PrinterProfileStatus {
  /// The profile is active and can be used for print jobs.
  active,

  /// The profile configuration has changed and needs technician validation.
  needsValidation,

  /// The profile is flagged as unsupported by the application client.
  unsupported,

  /// The profile is explicitly disabled by the technician.
  disabled,
}

/// Represents a technician-configured printer profile, mapping layout parameters,
/// capabilities, tray setups, and optimization constraints for a printer.
@immutable
class PrinterProfile extends Equatable {
  PrinterProfile({
    required this.id,
    required this.displayName,
    required this.status,
    required this.printerIdentity,
    required this.capabilities,
    required this.optimizationPreferences,
    required List<PrinterTrayProfile> trays,
    required this.createdAt,
    required this.updatedAt,
    this.lastValidatedAt,
  })  : trays = List.unmodifiable(trays),
        assert(
          id.isNotEmpty,
          'id cannot be empty',
        ),
        assert(
          displayName.isNotEmpty,
          'displayName cannot be empty',
        ),
        assert(
          trays.isNotEmpty,
          'At least one printer tray profile must be configured',
        );

  /// The unique identifier of the printer profile. Required.
  final String id;

  /// Human-readable label for this profile. Required.
  final String displayName;

  /// The status of this profile. Required.
  final PrinterProfileStatus status;

  /// The hardware printer information. Required.
  final PrinterIdentity printerIdentity;

  /// The hardware capabilities and constraints. Required.
  final PrinterCapabilities capabilities;

  /// Layout engine optimization preference overrides. Required.
  final OptimizationPreferences optimizationPreferences;

  /// The tray configurations configured for this profile. Required.
  final List<PrinterTrayProfile> trays;

  /// The creation timestamp. Required.
  final DateTime createdAt;

  /// The last update timestamp. Required.
  final DateTime updatedAt;

  /// The timestamp of the last technician validation check.
  final DateTime? lastValidatedAt;

  @override
  List<Object?> get props => [
        id,
        displayName,
        status,
        printerIdentity,
        capabilities,
        optimizationPreferences,
        trays,
        createdAt,
        updatedAt,
        lastValidatedAt,
      ];

  @override
  String toString() =>
      'PrinterProfile(id: $id, displayName: $displayName, status: $status, '
      'traysCount: ${trays.length})';
}
