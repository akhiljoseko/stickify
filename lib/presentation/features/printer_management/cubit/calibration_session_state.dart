import 'package:equatable/equatable.dart';
import 'package:stickify/domain/domain.dart';

/// Represents the step/status in the calibration wizard.
enum CalibrationSessionStatus {
  initial,
  trayDetailsInput,
  templateSelected,
  printingSheet,
  sheetPrinted,
  measuringMargins,
  marginMeasurementDone,
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
    this.trayDisplayName = '',
    this.trayIdentifier = '',
    this.mediaType = 'A4 Product Labels',
    this.availableTemplates = const [],
    this.selectedTemplateIds = const {},
    this.nonPrintableMarginLeft = 0.0,
    this.nonPrintableMarginRight = 0.0,
    this.nonPrintableMarginTop = 0.0,
    this.nonPrintableMarginBottom = 0.0,
    this.isExistingTray = false,
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

  /// Tray display name entered in Step 1.
  final String trayDisplayName;

  /// Tray identifier entered in Step 1.
  final String trayIdentifier;

  /// Media type selected in Step 1.
  final String mediaType;

  /// Available templates for the user to assign to this tray.
  final List<LabelTemplate> availableTemplates;

  /// IDs of templates the user selected for this tray.
  final Set<String> selectedTemplateIds;

  /// Left non-printable margin measured in Step 3.
  final double nonPrintableMarginLeft;

  /// Right non-printable margin measured in Step 3.
  final double nonPrintableMarginRight;

  /// Top non-printable margin measured in Step 3.
  final double nonPrintableMarginTop;

  /// Bottom non-printable margin measured in Step 3.
  final double nonPrintableMarginBottom;

  /// Whether this is an existing tray (skip Step 1).
  final bool isExistingTray;

  /// Creates a copy of this state with optional overrides.
  CalibrationSessionState copyWith({
    CalibrationSessionStatus? status,
    CalibrationSheetTemplate? selectedTemplate,
    List<CalibrationMeasurement>? measurements,
    List<CalibrationRule>? generatedRules,
    String? Function()? errorMessage,
    PrinterProfile? printerProfile,
    PrinterTrayProfile? trayProfile,
    String? trayDisplayName,
    String? trayIdentifier,
    String? mediaType,
    List<LabelTemplate>? availableTemplates,
    Set<String>? selectedTemplateIds,
    double? nonPrintableMarginLeft,
    double? nonPrintableMarginRight,
    double? nonPrintableMarginTop,
    double? nonPrintableMarginBottom,
    bool? isExistingTray,
  }) {
    return CalibrationSessionState(
      status: status ?? this.status,
      selectedTemplate: selectedTemplate ?? this.selectedTemplate,
      measurements: measurements ?? this.measurements,
      generatedRules: generatedRules ?? this.generatedRules,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      printerProfile: printerProfile ?? this.printerProfile,
      trayProfile: trayProfile ?? this.trayProfile,
      trayDisplayName: trayDisplayName ?? this.trayDisplayName,
      trayIdentifier: trayIdentifier ?? this.trayIdentifier,
      mediaType: mediaType ?? this.mediaType,
      availableTemplates: availableTemplates ?? this.availableTemplates,
      selectedTemplateIds: selectedTemplateIds ?? this.selectedTemplateIds,
      nonPrintableMarginLeft:
          nonPrintableMarginLeft ?? this.nonPrintableMarginLeft,
      nonPrintableMarginRight:
          nonPrintableMarginRight ?? this.nonPrintableMarginRight,
      nonPrintableMarginTop:
          nonPrintableMarginTop ?? this.nonPrintableMarginTop,
      nonPrintableMarginBottom:
          nonPrintableMarginBottom ?? this.nonPrintableMarginBottom,
      isExistingTray: isExistingTray ?? this.isExistingTray,
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
        trayDisplayName,
        trayIdentifier,
        mediaType,
        availableTemplates,
        selectedTemplateIds,
        nonPrintableMarginLeft,
        nonPrintableMarginRight,
        nonPrintableMarginTop,
        nonPrintableMarginBottom,
        isExistingTray,
      ];
}
