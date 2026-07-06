import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:stickify/domain/entities/discovered_printer.dart';
import 'package:stickify/domain/entities/printer_profile.dart';

/// The status level of compatibility between a saved profile and a discovered printer.
enum PrinterCompatibilityStatus {
  /// The profile and discovered printer satisfy all checked requirements.
  compatible,

  /// Printing might work, but there are minor or unresolvable warnings.
  warning,

  /// A critical mismatch exists; printing should not proceed automatically.
  incompatible,
}

/// Represents a single validation finding about printer profile compatibility.
@immutable
class PrinterCompatibilityIssue extends Equatable {
  /// Creates a [PrinterCompatibilityIssue].
  ///
  /// Enforces that [code] and [message] must be non-empty.
  const PrinterCompatibilityIssue({
    required this.severity,
    required this.code,
    required this.message,
  })  : assert(code.length > 0, 'code cannot be empty'),
        assert(message.length > 0, 'message cannot be empty');

  /// The severity of the compatibility issue.
  final PrinterCompatibilityStatus severity;

  /// The unique programmatic code identifying the issue.
  final String code;

  /// The human-readable description of the issue.
  final String message;

  @override
  List<Object?> get props => [severity, code, message];

  @override
  String toString() =>
      'PrinterCompatibilityIssue(severity: $severity, code: $code, message: $message)';
}

/// Represents the overall compatibility outcome between a stored printer profile
/// and a discovered runtime printer.
@immutable
class PrinterProfileCompatibility extends Equatable {
  /// Creates a [PrinterProfileCompatibility] instance.
  ///
  /// Enforces that the overall [status] matches the severities of the provided [issues].
  PrinterProfileCompatibility({
    required this.profile,
    required this.printer,
    required this.status,
    required List<PrinterCompatibilityIssue> issues,
  })  : issues = List.unmodifiable(issues),
        assert(
          switch (status) {
            PrinterCompatibilityStatus.compatible => issues.isEmpty,
            PrinterCompatibilityStatus.warning =>
              issues.isNotEmpty &&
              issues.every(
                (issue) => issue.severity == PrinterCompatibilityStatus.warning,
              ),
            PrinterCompatibilityStatus.incompatible =>
              issues.any(
                (issue) => issue.severity == PrinterCompatibilityStatus.incompatible,
              ),
          },
          'PrinterProfileCompatibility status does not match issue severities',
        );

  /// The technician-configured printer profile.
  final PrinterProfile profile;

  /// The dynamically discovered OS printer.
  final DiscoveredPrinter printer;

  /// The resolved compatibility status.
  final PrinterCompatibilityStatus status;

  /// The list of compatibility findings, stored as an unmodifiable list.
  final List<PrinterCompatibilityIssue> issues;

  @override
  List<Object?> get props => [profile, printer, status, issues];

  @override
  String toString() =>
      'PrinterProfileCompatibility(profileId: ${profile.id}, '
      'printerName: ${printer.systemPrinterName}, status: $status, '
      'issuesCount: ${issues.length})';
}
