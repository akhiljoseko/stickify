import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/printer_management/cubit/printer_management_state.dart';

/// Cubit responsible for managing the state, discovery, and compatibility matching
/// of system printers.
class PrinterManagementCubit extends Cubit<PrinterManagementState> {
  /// Creates a [PrinterManagementCubit] with its required dependencies.
  PrinterManagementCubit({
    required this.printerDiscoveryService,
    required this.printerProfileRepository,
    required this.printerProfileMatcher,
    required this.printerProfileCompatibilityAnalyzer,
  }) : super(const PrinterManagementState.initial());

  /// The printer discovery service.
  final PrinterDiscoveryService printerDiscoveryService;

  /// The printer profile repository.
  final PrinterProfileRepository printerProfileRepository;

  /// The printer profile matcher.
  final PrinterProfileMatcher printerProfileMatcher;

  /// The printer profile compatibility analyzer.
  final PrinterProfileCompatibilityAnalyzer printerProfileCompatibilityAnalyzer;

  /// Loads available system printers and saved profiles, matches them, and performs
  /// compatibility validation checks.
  Future<void> loadPrintersAndProfiles() async {
    emit(state.copyWith(status: PrinterManagementStatus.loading));

    try {
      // Step 1: Load Runtime OS Printers
      final discoveredPrinters = await printerDiscoveryService.getDiscoveredPrinters();

      // Step 2: Load Saved Profiles
      final profilesResult = await printerProfileRepository.getAllProfiles();
      switch (profilesResult) {
        case Failure(:final error):
          emit(
            state.copyWith(
              status: PrinterManagementStatus.failure,
              errorMessage: () => error.message,
            ),
          );
          return;

        case Success(value: final profiles):
          // Step 3: Match Profiles
          final matches = printerProfileMatcher.matchProfiles(
            profiles: profiles,
            discoveredPrinters: discoveredPrinters,
          );

          // Steps 4 & 5: Run Compatibility checks for matched/compatible profiles
          final compatibilityMap = <String, PrinterProfileCompatibility>{};
          for (final match in matches) {
            if (match.status == PrinterProfileMatchStatus.matched ||
                match.status == PrinterProfileMatchStatus.compatible) {
              final printer = match.discoveredPrinter;
              if (printer != null) {
                final compatibility = printerProfileCompatibilityAnalyzer.analyze(
                  profile: match.profile,
                  printer: printer,
                );
                compatibilityMap[match.profile.id] = compatibility;
              }
            }
          }

          emit(
            state.copyWith(
              status: PrinterManagementStatus.loaded,
              matches: matches,
              compatibilityResults: compatibilityMap,
              discoveredPrinterCount: discoveredPrinters.length,
              errorMessage: () => null,
            ),
          );
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: PrinterManagementStatus.failure,
          errorMessage: e.toString,
        ),
      );
    }
  }
}
