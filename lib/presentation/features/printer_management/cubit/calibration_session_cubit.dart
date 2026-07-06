import 'package:collection/collection.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/core/services/printing/calibration_sheet_pdf_generator.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/printer_management/cubit/calibration_session_state.dart';

/// Cubit responsible for managing the calibration session wizard state machine.
class CalibrationSessionCubit extends Cubit<CalibrationSessionState> {
  /// Creates a [CalibrationSessionCubit] instance with dependencies.
  CalibrationSessionCubit({
    required this.profileId,
    required this.trayId,
    required this.paperConfigurationId,
    required this.ruleGenerator,
    required this.pdfGenerator,
    required this.profileRepository,
    required this.printService,
    required this._templateRepository,
  }) : super(const CalibrationSessionState.initial());

  /// ID of the printer profile being calibrated.
  final String profileId;

  /// ID of the tray being calibrated.
  final String trayId;

  /// ID of the paper configuration.
  final String paperConfigurationId;

  /// The calibration rule generator service.
  final CalibrationRuleGenerator ruleGenerator;

  /// The calibration sheet PDF generator service.
  final CalibrationSheetPdfGenerator pdfGenerator;

  /// The printer profile repository.
  final PrinterProfileRepository profileRepository;

  /// The printing service.
  final PrintService printService;

  /// The template repository (for fetching available templates).
  final TemplateRepository _templateRepository;

  /// Loads the printer profile and tray, setting up the initial calibration template.
  /// If the tray is new, transitions to tray details input. Otherwise skips to print.
  Future<void> loadSession() async {
    Log.info(
      'Calibration session started for profile "$profileId", tray "$trayId", '
      'paper config "$paperConfigurationId".',
      tag: 'Calibration',
    );
    emit(state.copyWith(status: CalibrationSessionStatus.initial));

    final result = await profileRepository.getProfileById(profileId);
    switch (result) {
      case Failure(:final error):
        Log.error(
          'Failed to load printer profile "$profileId" for calibration: ${error.message}',
          tag: 'Calibration',
        );
        emit(
          state.copyWith(
            status: CalibrationSessionStatus.error,
            errorMessage: () =>
                'Failed to load printer profile: ${error.message}',
          ),
        );
        return;
      case Success(value: final profile):
        if (profile == null) {
          Log.error(
            'Calibration aborted: printer profile "$profileId" not found.',
            tag: 'Calibration',
          );
          emit(
            state.copyWith(
              status: CalibrationSessionStatus.error,
              errorMessage: () => 'Printer profile not found.',
            ),
          );
          return;
        }

        PrinterTrayProfile tray;
        try {
          tray = profile.trays.firstWhere(
            (t) => t.trayIdentifier == trayId,
          );
        } catch (_) {
          Log.error(
            'Calibration aborted: tray "$trayId" not found in profile '
            '"${profile.displayName}". Available trays: '
            '${profile.trays.map((t) => t.trayIdentifier).join(', ')}',
            tag: 'Calibration',
          );
          emit(
            state.copyWith(
              status: CalibrationSessionStatus.error,
              errorMessage: () =>
                  'Selected tray "$trayId" not found in profile.',
            ),
          );
          return;
        }

        // Fetch available templates for tray details step
        final templatesResult = await _templateRepository.fetchTemplates();
        var templates = const <LabelTemplate>[];
        if (templatesResult is Success<List<LabelTemplate>, AppError>) {
          templates = templatesResult.value;
        }

        Log.info(
          'Profile "${profile.displayName}" loaded with ${profile.trays.length} '
          'tray(s). Tray "${tray.displayName}" selected for calibration.',
          tag: 'Calibration',
        );

        // Standard default calibration sheet template with 4 corners
        final sheetTemplate = CalibrationSheetTemplate(
          id: 'standard_calibration',
          name: 'Standard Calibration Sheet',
          points: [
            CalibrationMeasurementPoint(
              id: 'p1',
              label: 'Top-Left (TL)',
              expectedX: 20,
              expectedY: 20,
            ),
            CalibrationMeasurementPoint(
              id: 'p2',
              label: 'Top-Right (TR)',
              expectedX: 190,
              expectedY: 20,
            ),
            CalibrationMeasurementPoint(
              id: 'p3',
              label: 'Bottom-Left (BL)',
              expectedX: 20,
              expectedY: 270,
            ),
            CalibrationMeasurementPoint(
              id: 'p4',
              label: 'Bottom-Right (BR)',
              expectedX: 190,
              expectedY: 270,
            ),
          ],
        );

        // Build selected template IDs from tray's existing configs
        final selectedIds = tray.supportedPaperConfigurations
            .map((ref) => ref.id)
            .toSet();

        emit(
          state.copyWith(
            status: CalibrationSessionStatus.templateSelected,
            selectedTemplate: sheetTemplate,
            measurements: const [],
            generatedRules: const [],
            errorMessage: () => null,
            printerProfile: profile,
            trayProfile: tray,
            trayDisplayName: tray.displayName,
            trayIdentifier: tray.trayIdentifier,
            availableTemplates: templates,
            selectedTemplateIds: selectedIds,
            nonPrintableMarginLeft: tray.nonPrintableMarginLeft,
            nonPrintableMarginRight: tray.nonPrintableMarginRight,
            nonPrintableMarginTop: tray.nonPrintableMarginTop,
            nonPrintableMarginBottom: tray.nonPrintableMarginBottom,
            isExistingTray: true,
          ),
        );
    }
  }

  /// Sets tray display name (Step 1).
  void setTrayDisplayName(String value) {
    emit(state.copyWith(trayDisplayName: value));
  }

  /// Sets tray identifier (Step 1).
  void setTrayIdentifier(String value) {
    emit(state.copyWith(trayIdentifier: value));
  }

  /// Sets media type (Step 1).
  void setMediaType(String value) {
    emit(state.copyWith(mediaType: value));
  }

  /// Toggles a template selection (Step 1).
  void toggleTemplate(String templateId) {
    final updated = Set<String>.from(state.selectedTemplateIds);
    if (updated.contains(templateId)) {
      updated.remove(templateId);
    } else {
      updated.add(templateId);
    }
    emit(state.copyWith(selectedTemplateIds: updated));
  }

  /// Saves tray details and moves to print step (Step 1 → Step 2).
  void saveTrayDetails() {
    emit(state.copyWith(status: CalibrationSessionStatus.templateSelected));
  }

  /// Sets the left non-printable margin (Step 3).
  void setMarginLeft(double value) {
    emit(state.copyWith(nonPrintableMarginLeft: value));
  }

  /// Sets the right non-printable margin (Step 3).
  void setMarginRight(double value) {
    emit(state.copyWith(nonPrintableMarginRight: value));
  }

  /// Sets the top non-printable margin (Step 3).
  void setMarginTop(double value) {
    emit(state.copyWith(nonPrintableMarginTop: value));
  }

  /// Sets the bottom non-printable margin (Step 3).
  void setMarginBottom(double value) {
    emit(state.copyWith(nonPrintableMarginBottom: value));
  }

  /// Generates the calibration sheet PDF and prints it.
  Future<void> printCalibrationSheet() async {
    final template = state.selectedTemplate;
    final profile = state.printerProfile;
    final tray = state.trayProfile;

    if (template == null || profile == null || tray == null) {
      Log.error(
        'Cannot print calibration sheet: wizard not fully initialized '
        '(template=${template != null}, profile=${profile != null}, tray=${tray != null}).',
        tag: 'Calibration',
      );
      emit(
        state.copyWith(
          status: CalibrationSessionStatus.error,
          errorMessage: () => 'Calibration wizard is not fully initialized.',
        ),
      );
      return;
    }

    Log.info(
      'Generating calibration sheet PDF for profile "${profile.displayName}", '
      'tray "${tray.displayName}", template "${template.name}" '
      '(${template.pageWidth}x${template.pageHeight}mm).',
      tag: 'Calibration',
    );

    emit(state.copyWith(status: CalibrationSessionStatus.printingSheet));

    try {
      final pdfBytes = await pdfGenerator.generatePdfBytes(
        template: template,
        printerName: profile.displayName,
        trayName: tray.displayName,
      );

      Log.info(
        'Calibration sheet PDF generated (${pdfBytes.length} bytes). '
        'Sending to printer "${profile.printerIdentity.systemPrinterName}".',
        tag: 'Calibration',
      );

      final printResult = await printService.printRawPdf(
        pdfBytes: pdfBytes,
        printer: PrinterDevice(
          name: profile.printerIdentity.systemPrinterName,
          url: '',
        ),
        widthMm: template.pageWidth,
        heightMm: template.pageHeight,
        docName: 'calibration_sheet_${template.name}',
      );

      switch (printResult) {
        case Failure(:final error):
          Log.error(
            'Failed to print calibration sheet: ${error.message}',
            tag: 'Calibration',
          );
          emit(
            state.copyWith(
              status: CalibrationSessionStatus.error,
              errorMessage: () => 'Failed to spool print job: ${error.message}',
            ),
          );
        case Success():
          Log.info(
            'Calibration sheet printed successfully. '
            'Waiting for technician to measure margins.',
            tag: 'Calibration',
          );
          emit(state.copyWith(status: CalibrationSessionStatus.sheetPrinted));
      }
    } catch (e) {
      Log.error(
        'Unexpected error while printing calibration sheet: $e',
        tag: 'Calibration',
      );
      emit(
        state.copyWith(
          status: CalibrationSessionStatus.error,
          errorMessage: () => 'Spooling failed with unexpected error: $e',
        ),
      );
    }
  }

  /// Skips printing and moves to margin measurement step.
  /// Margins keep existing values (if tray existed) or stay at 0 (new tray).
  void skipPrint() {
    Log.info(
      'User skipped printing. Moving to margin measurement step.',
      tag: 'Calibration',
    );
    emit(
      state.copyWith(
        status: CalibrationSessionStatus.measuringMargins,
      ),
    );
  }

  /// Moves from print step to margin measurement step after printing.
  void proceedToMargins() {
    emit(
      state.copyWith(
        status: CalibrationSessionStatus.measuringMargins,
      ),
    );
  }

  /// Saves margin measurements and moves to crosshair measurement.
  void saveMargins() {
    emit(
      state.copyWith(
        status: CalibrationSessionStatus.marginMeasurementDone,
      ),
    );
  }

  /// Clears the current error state.
  void retry() {
    Log.info(
      'User retry: clearing error state and returning to template selection.',
      tag: 'Calibration',
    );
    emit(
      state.copyWith(
        status: CalibrationSessionStatus.templateSelected,
        errorMessage: () => null,
      ),
    );
  }

  /// Adds a measurement entered by the technician.
  void addMeasurement(CalibrationMeasurement measurement) {
    final template = state.selectedTemplate;
    if (template == null) return;

    final updated = List<CalibrationMeasurement>.from(state.measurements)
      ..removeWhere((m) => m.point.id == measurement.point.id)
      ..add(measurement);

    final measuredPointIds = updated.map((m) => m.point.id).toSet();
    final isComplete =
        updated.length == template.points.length &&
        measuredPointIds.length == template.points.length;

    Log.info(
      'Measurement for point "${measurement.point.label}" entered: '
      'actualX=${measurement.actualX.toStringAsFixed(2)}mm, '
      'actualY=${measurement.actualY.toStringAsFixed(2)}mm '
      '(expectedX=${measurement.point.expectedX}mm, '
      'expectedY=${measurement.point.expectedY}mm). '
      'Delta: X=${measurement.deltaX.toStringAsFixed(2)}mm, '
      'Y=${measurement.deltaY.toStringAsFixed(2)}mm. '
      'Progress: ${updated.length}/${template.points.length} measurements complete.',
      tag: 'Calibration',
    );

    emit(
      state.copyWith(
        status: isComplete
            ? CalibrationSessionStatus.measurementsComplete
            : CalibrationSessionStatus.measurementsInProgress,
        measurements: updated,
      ),
    );
  }

  /// Generates the offset and scale correction rules.
  void generateRules() {
    final template = state.selectedTemplate;
    final profile = state.printerProfile;
    final tray = state.trayProfile;

    if (template == null || profile == null || tray == null) {
      Log.warning(
        'Cannot generate calibration rules: session state is incomplete.',
        tag: 'Calibration',
      );
      return;
    }

    Log.info(
      'All ${state.measurements.length} measurements collected. '
      'Generating calibration correction rules...',
      tag: 'Calibration',
    );

    final session = CalibrationSession(
      id: 'sess_${DateTime.now().millisecondsSinceEpoch}',
      printerProfile: profile,
      trayProfile: tray,
      paperConfigurationId: paperConfigurationId,
      sheetTemplate: template,
      measurements: state.measurements,
    );

    final request = CalibrationGenerationRequest(session: session);
    final result = ruleGenerator.generate(request);

    final rule = result.generatedRules.firstOrNull;
    if (rule != null) {
      Log.info(
        'Calibration rule generated for sheet: '
        'offsetX=${rule.transformation.offsetX.toStringAsFixed(3)}mm, '
        'offsetY=${rule.transformation.offsetY.toStringAsFixed(3)}mm, '
        'scaleX=${rule.transformation.scaleX.toStringAsFixed(5)}, '
        'scaleY=${rule.transformation.scaleY.toStringAsFixed(5)}.',
        tag: 'Calibration',
      );
    } else {
      Log.info(
        'No calibration rules generated (no measurements provided).',
        tag: 'Calibration',
      );
    }

    emit(
      state.copyWith(
        status: CalibrationSessionStatus.rulesGenerated,
        generatedRules: result.generatedRules,
      ),
    );
  }

  /// Persists the generated calibration rules to the printer profile repository.
  Future<void> saveCalibration() async {
    final profile = state.printerProfile;
    final tray = state.trayProfile;

    if (profile == null || tray == null) {
      Log.warning(
        'Cannot save calibration: profile or tray is missing from state.',
        tag: 'Calibration',
      );
      return;
    }

    Log.info(
      'Saving calibration for profile "${profile.displayName}", '
      'tray "${tray.displayName}". '
      '${state.generatedRules.length} calibration rule(s) will be persisted.',
      tag: 'Calibration',
    );

    emit(state.copyWith(status: CalibrationSessionStatus.saving));

    final supportedConfigs = state.availableTemplates
        .where((t) => state.selectedTemplateIds.contains(t.id))
        .map(
          (t) => PaperConfigurationReference(id: t.id, displayName: t.name),
        )
        .toList();

    final updatedTray = PrinterTrayProfile(
      trayIdentifier: state.trayIdentifier.isNotEmpty
          ? state.trayIdentifier
          : tray.trayIdentifier,
      displayName: state.trayDisplayName.isNotEmpty
          ? state.trayDisplayName
          : tray.displayName,
      supportedPaperConfigurations: supportedConfigs.isNotEmpty
          ? supportedConfigs
          : tray.supportedPaperConfigurations,
      calibration: PrinterCalibration(
        enabled: state.generatedRules.isNotEmpty,
        calibrationRules: state.generatedRules,
      ),
      nonPrintableMarginLeft: state.nonPrintableMarginLeft,
      nonPrintableMarginRight: state.nonPrintableMarginRight,
      nonPrintableMarginTop: state.nonPrintableMarginTop,
      nonPrintableMarginBottom: state.nonPrintableMarginBottom,
    );

    final updatedTrays = profile.trays.map((t) {
      return t.trayIdentifier == tray.trayIdentifier ? updatedTray : t;
    }).toList();

    final updatedProfile = PrinterProfile(
      id: profile.id,
      displayName: profile.displayName,
      status: profile.status,
      printerIdentity: profile.printerIdentity,
      capabilities: profile.capabilities,
      optimizationPreferences: profile.optimizationPreferences,
      trays: updatedTrays,
      createdAt: profile.createdAt,
      updatedAt: DateTime.now(),
    );

    final result = await profileRepository.saveProfile(updatedProfile);
    switch (result) {
      case Failure(:final error):
        Log.error(
          'Failed to save calibrated profile: ${error.message}',
          tag: 'Calibration',
        );
        emit(
          state.copyWith(
            status: CalibrationSessionStatus.error,
            errorMessage: () =>
                'Failed to save calibration profile: ${error.message}',
          ),
        );
      case Success():
        Log.info(
          'Calibration successfully saved for profile "${profile.displayName}", '
          'tray "${tray.displayName}". '
          'Corrections will be applied automatically on next print job.',
          tag: 'Calibration',
        );
        emit(
          state.copyWith(
            status: CalibrationSessionStatus.saved,
            printerProfile: updatedProfile,
          ),
        );
    }
  }
}
