import 'package:equatable/equatable.dart';
import 'package:stickify/domain/domain.dart';

/// Represents the loading/reconciliation status of the printer management screen.
enum PrinterManagementStatus {
  /// The initial uninitialized state.
  initial,

  /// Currently executing OS discovery and repository load.
  loading,

  /// Printers and profiles loaded and matched successfully.
  loaded,

  /// A failure occurred during loading.
  failure,
}

/// Represents the complete state of the Printer Selection & Management UI.
class PrinterManagementState extends Equatable {
  /// Creates a [PrinterManagementState] instance.
  const PrinterManagementState({
    required this.status,
    this.matches = const [],
    this.compatibilityResults = const {},
    this.discoveredPrinterCount = 0,
    this.errorMessage,
  });

  /// The initial state helper.
  const PrinterManagementState.initial()
      : this(status: PrinterManagementStatus.initial);

  /// The status of the screen logic.
  final PrinterManagementStatus status;

  /// The list of profiles matched against discovered system printers.
  final List<PrinterProfileMatchResult> matches;

  /// Map of resolved compatibility information, keyed by printer profile ID.
  final Map<String, PrinterProfileCompatibility> compatibilityResults;

  /// The number of physical printers discovered from the host system.
  ///
  /// Helps the UI distinguish between "No Configured Profiles" and "No Runtime Printers Discovered".
  final int discoveredPrinterCount;

  /// The user-facing error message, if status is [PrinterManagementStatus.failure].
  final String? errorMessage;

  /// Copies the state with optional overrides.
  PrinterManagementState copyWith({
    PrinterManagementStatus? status,
    List<PrinterProfileMatchResult>? matches,
    Map<String, PrinterProfileCompatibility>? compatibilityResults,
    int? discoveredPrinterCount,
    String? Function()? errorMessage,
  }) {
    return PrinterManagementState(
      status: status ?? this.status,
      matches: matches ?? this.matches,
      compatibilityResults: compatibilityResults ?? this.compatibilityResults,
      discoveredPrinterCount:
          discoveredPrinterCount ?? this.discoveredPrinterCount,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        matches,
        compatibilityResults,
        discoveredPrinterCount,
        errorMessage,
      ];
}
