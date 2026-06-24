import 'package:stickify/domain/entities/discovered_printer.dart';
import 'package:stickify/domain/entities/printer_profile.dart';
import 'package:stickify/domain/entities/printer_profile_compatibility.dart';

/// Pure stateless domain service that analyzes compatibility between a saved [PrinterProfile]
/// configuration and a runtime OS [DiscoveredPrinter].
class PrinterProfileCompatibilityAnalyzer {
  /// Analyzes the suitability of [printer] to execute layout jobs configured by [profile].
  ///
  /// Evaluates metadata matching rules and missing metadata states in order, compiles a list
  /// of findings, and derives the overall [PrinterCompatibilityStatus].
  PrinterProfileCompatibility analyze({
    required PrinterProfile profile,
    required DiscoveredPrinter printer,
  }) {
    final issues = <PrinterCompatibilityIssue>[];

    final profileMfg = profile.printerIdentity.manufacturer;
    final printerMfg = printer.manufacturer;

    // 1. Manufacturer mismatch
    if (profileMfg.isNotEmpty && printerMfg.isNotEmpty) {
      if (profileMfg != printerMfg) {
        issues.add(
          PrinterCompatibilityIssue(
            severity: PrinterCompatibilityStatus.incompatible,
            code: 'manufacturer_mismatch',
            message: 'Manufacturer mismatch: expected "$profileMfg" but found "$printerMfg".',
          ),
        );
      }
    }

    // 2. Model mismatch
    final profileModel = profile.printerIdentity.model;
    final printerModel = printer.model;
    if (profileModel.isNotEmpty && printerModel.isNotEmpty) {
      if (profileModel != printerModel) {
        issues.add(
          PrinterCompatibilityIssue(
            severity: PrinterCompatibilityStatus.incompatible,
            code: 'model_mismatch',
            message: 'Model mismatch: expected "$profileModel" but found "$printerModel".',
          ),
        );
      }
    }

    // 3. Driver mismatch
    final profileDriver = profile.printerIdentity.driverName;
    final printerDriver = printer.driverName;
    if (profileDriver.isNotEmpty && printerDriver.isNotEmpty) {
      if (profileDriver != printerDriver) {
        issues.add(
          PrinterCompatibilityIssue(
            severity: PrinterCompatibilityStatus.warning,
            code: 'driver_mismatch',
            message: 'Driver mismatch: profile uses "$profileDriver" but printer is running "$printerDriver".',
          ),
        );
      }
    }

    // 4. Missing runtime metadata
    if (printerMfg.isEmpty) {
      issues.add(
        const PrinterCompatibilityIssue(
          severity: PrinterCompatibilityStatus.warning,
          code: 'missing_manufacturer',
          message: 'Discovered printer metadata does not specify a manufacturer.',
        ),
      );
    }
    if (printerModel.isEmpty) {
      issues.add(
        const PrinterCompatibilityIssue(
          severity: PrinterCompatibilityStatus.warning,
          code: 'missing_model',
          message: 'Discovered printer metadata does not specify a model.',
        ),
      );
    }
    if (printerDriver.isEmpty) {
      issues.add(
        const PrinterCompatibilityIssue(
          severity: PrinterCompatibilityStatus.warning,
          code: 'missing_driver',
          message: 'Discovered printer metadata does not specify a driver name.',
        ),
      );
    }

    // Resolve overall status
    PrinterCompatibilityStatus status;
    if (issues.any((issue) => issue.severity == PrinterCompatibilityStatus.incompatible)) {
      status = PrinterCompatibilityStatus.incompatible;
    } else if (issues.any((issue) => issue.severity == PrinterCompatibilityStatus.warning)) {
      status = PrinterCompatibilityStatus.warning;
    } else {
      status = PrinterCompatibilityStatus.compatible;
    }

    return PrinterProfileCompatibility(
      profile: profile,
      printer: printer,
      status: status,
      issues: issues,
    );
  }
}
