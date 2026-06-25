import 'package:equatable/equatable.dart';
import 'package:stickify/domain/domain.dart';

/// Represents the step/status in the calibration wizard.
enum CalibrationSessionStatus {
  initial,
  templateSelected,
  printingSheet,
  sheetPrinted,
  measurementsInProgress,
  measurementsComplete,
  rulesGenerated,
  saving,
  saved,
  error,
}

/// State for the calibration wizard flow.
class CalibrationSessionState extends Equatable {
  /// Creates a [CalibrationSessionState] instance.
  const CalibrationSessionState({
    required this.status,
    this.selectedTemplate,
    this.measurements = const [],
    this.generatedRules = const [],
    this.errorMessage,
    this.printerProfile,
    this.trayProfile,
  });

  /// Initial state.
  const CalibrationSessionState.initial()
      : this(status: CalibrationSessionStatus.initial);

  /// Current wizard status.
  final CalibrationSessionStatus status;

  /// The selected calibration sheet template, if any.
  final CalibrationSheetTemplate? selectedTemplate;

  /// The list of measurements completed so far.
  final List<CalibrationMeasurement> measurements;

  /// The calibration rules generated from the session.
  final List<CalibrationRule> generatedRules;

  /// The user-facing error message, if status is [CalibrationSessionStatus.error].
  final String? errorMessage;

  /// The printer profile being calibrated.
  final PrinterProfile? printerProfile;

  /// The tray being calibrated.
  final PrinterTrayProfile? trayProfile;

  /// Creates a copy of this state with optional overrides.
  CalibrationSessionState copyWith({
    CalibrationSessionStatus? status,
    CalibrationSheetTemplate? selectedTemplate,
    List<CalibrationMeasurement>? measurements,
    List<CalibrationRule>? generatedRules,
    String? Function()? errorMessage,
    PrinterProfile? printerProfile,
    PrinterTrayProfile? trayProfile,
  }) {
    return CalibrationSessionState(
      status: status ?? this.status,
      selectedTemplate: selectedTemplate ?? this.selectedTemplate,
      measurements: measurements ?? this.measurements,
      generatedRules: generatedRules ?? this.generatedRules,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      printerProfile: printerProfile ?? this.printerProfile,
      trayProfile: trayProfile ?? this.trayProfile,
    );
  }

  @override
  List<Object?> get props => [
        status,
        selectedTemplate,
        measurements,
        generatedRules,
        errorMessage,
        printerProfile,
        trayProfile,
      ];
}
