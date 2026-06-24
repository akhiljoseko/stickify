import 'package:stickify/domain/entities/discovered_printer.dart';
import 'package:stickify/domain/entities/printer_profile.dart';
import 'package:stickify/domain/entities/printer_profile_match_result.dart';

/// Domain service responsible for reconciling persisted technician printer profiles
/// against operating-system-discovered printers.
class PrinterProfileMatcher {
  /// Reconciles the given [profiles] list against the [discoveredPrinters] list.
  ///
  /// Returns an immutable list of [PrinterProfileMatchResult] mapping each input
  /// profile in the exact order received.
  ///
  /// Reconciles based on:
  /// 1. Exact system printer name match (highest priority).
  /// 2. Manufacturer and model compatibility match (fallback, only if exact fails).
  /// 3. Missing profile (when no exact or compatibility match is resolved).
  ///
  /// Input lists are not modified or sorted.
  List<PrinterProfileMatchResult> matchProfiles({
    required List<PrinterProfile> profiles,
    required List<DiscoveredPrinter> discoveredPrinters,
  }) {
    final results = <PrinterProfileMatchResult>[];

    for (final profile in profiles) {
      // 1. Attempt exact match
      DiscoveredPrinter? exactMatch;
      for (final printer in discoveredPrinters) {
        if (profile.printerIdentity.systemPrinterName == printer.systemPrinterName) {
          exactMatch = printer;
          break; // First match in discovery list order wins
        }
      }

      if (exactMatch != null) {
        results.add(
          PrinterProfileMatchResult(
            profile: profile,
            status: PrinterProfileMatchStatus.matched,
            discoveredPrinter: exactMatch,
          ),
        );
        continue;
      }

      // 2. Attempt compatibility match
      DiscoveredPrinter? compatibleMatch;
      final profileMfg = profile.printerIdentity.manufacturer;
      final profileModel = profile.printerIdentity.model;

      if (profileMfg.isNotEmpty && profileModel.isNotEmpty) {
        for (final printer in discoveredPrinters) {
          if (printer.manufacturer.isNotEmpty && printer.model.isNotEmpty) {
            if (profileMfg == printer.manufacturer && profileModel == printer.model) {
              compatibleMatch = printer;
              break; // First match in discovery list order wins
            }
          }
        }
      }

      if (compatibleMatch != null) {
        results.add(
          PrinterProfileMatchResult(
            profile: profile,
            status: PrinterProfileMatchStatus.compatible,
            discoveredPrinter: compatibleMatch,
          ),
        );
        continue;
      }

      // 3. Fallback: missing
      results.add(
        PrinterProfileMatchResult(
          profile: profile,
          status: PrinterProfileMatchStatus.missing,
        ),
      );
    }

    return List.unmodifiable(results);
  }
}
