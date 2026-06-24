import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// Represents an application-defined sheet/template configuration that a printer
/// tray has been configured, calibrated, and validated to print.
///
/// The [id] field maps to the application's internal template or sheet configuration
/// identifier (e.g. "shipping_label_100x150"). It is independent from and must not
/// represent Windows printer paper forms or driver-specific paper IDs.
@immutable
class PaperConfigurationReference extends Equatable {
  /// Creates a [PaperConfigurationReference] value object.
  const PaperConfigurationReference({
    required this.id,
    required this.displayName,
  })  : assert(
          id.length > 0,
          'id cannot be empty',
        ),
        assert(
          displayName.length > 0,
          'displayName cannot be empty',
        );

  /// The internal application sheet configuration identifier. Required.
  final String id;

  /// Human-readable label for this paper configuration. Required.
  final String displayName;

  @override
  List<Object?> get props => [id, displayName];

  @override
  String toString() =>
      'PaperConfigurationReference(id: $id, displayName: $displayName)';
}
