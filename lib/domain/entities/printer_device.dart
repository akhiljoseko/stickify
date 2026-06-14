import 'package:equatable/equatable.dart';

/// Represents a physical or network printer available on the host system.
class PrinterDevice extends Equatable {
  /// Constructor for creating a printer representation.
  const PrinterDevice({
    required this.name,
    required this.url,
    this.isDefault = false,
  });

  /// The human-readable name of the printer (e.g. "Zebra ZT411-A").
  final String name;

  /// The system-specific identifier or URL of the printer.
  final String url;

  /// Whether this printer is the system default printer.
  final bool isDefault;

  @override
  List<Object?> get props => [name, url, isDefault];
}
