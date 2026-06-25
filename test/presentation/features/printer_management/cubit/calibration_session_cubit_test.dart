import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/core/services/printing/calibration_sheet_pdf_generator.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/printer_management/cubit/calibration_session_cubit.dart';
import 'package:stickify/presentation/features/printer_management/cubit/calibration_session_state.dart';

class MockPrinterProfileRepository extends Mock
    implements PrinterProfileRepository {}

class MockPrintService extends Mock implements PrintService {}

class MockCalibrationSheetPdfGenerator extends Mock
    implements CalibrationSheetPdfGenerator {}

void main() {
  group('CalibrationSessionCubit', () {
    late PrinterProfileRepository repository;
    late PrintService printService;
    late CalibrationSheetPdfGenerator pdfGenerator;
    late CalibrationRuleGenerator ruleGenerator;
    late CalibrationSessionCubit cubit;

    late PrinterProfile profile;
    late PrinterTrayProfile tray;
    final now = DateTime(2026);

    setUpAll(() {
      registerFallbackValue(Uint8List(0));
      registerFallbackValue(
        const PrinterDevice(name: 'Test Printer', url: ''),
      );
      registerFallbackValue(
        CalibrationSheetTemplate(
          id: 't',
          name: 't',
          points: [
            CalibrationMeasurementPoint(
              id: 'p1',
              label: 'p1',
              expectedX: 1,
              expectedY: 1,
            ),
          ],
        ),
      );
      registerFallbackValue(
        PrinterProfile(
          id: '1',
          displayName: 'd',
          status: PrinterProfileStatus.active,
          printerIdentity: const PrinterIdentity(systemPrinterName: 's'),
          capabilities: const PrinterCapabilities(
            supportsCustomPaperSize: true,
            supportsPortraitCustomPaper: true,
            supportsLandscapeCustomPaper: false,
            supportsManualFeed: false,
            supportsBorderlessPrinting: false,
            supportsTraySelection: true,
          ),
          optimizationPreferences: const OptimizationPreferences(
            allowScaling: true,
            allowTranslation: true,
            allowStickerSpecificAdjustment: true,
          ),
          trays: [
            PrinterTrayProfile(
              trayIdentifier: 'fallback_tray',
              displayName: 'Fallback Tray',
              supportedPaperConfigurations: const [],
              calibration: PrinterCalibration(
                enabled: false,
                calibrationRules: const [],
              ),
            ),
          ],
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
      );
    });

    setUp(() {
      repository = MockPrinterProfileRepository();
      printService = MockPrintService();
      pdfGenerator = MockCalibrationSheetPdfGenerator();
      ruleGenerator = const CalibrationRuleGenerator();

      tray = PrinterTrayProfile(
        trayIdentifier: 'tray_1',
        displayName: 'Tray 1',
        supportedPaperConfigurations: const [],
        calibration: PrinterCalibration(
          enabled: false,
          calibrationRules: const [],
        ),
      );

      profile = PrinterProfile(
        id: 'profile_1',
        displayName: 'Zebra ZD421',
        status: PrinterProfileStatus.active,
        printerIdentity: const PrinterIdentity(
          systemPrinterName: 'Zebra ZD421',
        ),
        capabilities: const PrinterCapabilities(
          supportsCustomPaperSize: true,
          supportsPortraitCustomPaper: true,
          supportsLandscapeCustomPaper: false,
          supportsManualFeed: false,
          supportsBorderlessPrinting: false,
          supportsTraySelection: true,
        ),
        optimizationPreferences: const OptimizationPreferences(
          allowScaling: true,
          allowTranslation: true,
          allowStickerSpecificAdjustment: true,
        ),
        trays: [tray],
        createdAt: now,
        updatedAt: now,
      );

      cubit = CalibrationSessionCubit(
        profileId: 'profile_1',
        trayId: 'tray_1',
        paperConfigurationId: 'paper_1',
        ruleGenerator: ruleGenerator,
        pdfGenerator: pdfGenerator,
        profileRepository: repository,
        printService: printService,
      );
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state is correct', () {
      expect(cubit.state, const CalibrationSessionState.initial());
    });

    blocTest<CalibrationSessionCubit, CalibrationSessionState>(
      'loadSession emits error when repository fails',
      build: () {
        when(() => repository.getProfileById('profile_1')).thenAnswer(
          (_) async =>
              const Result.failure(UnexpectedError(message: 'Database error')),
        );
        return cubit;
      },
      act: (cubit) => cubit.loadSession(),
      expect: () => [
        const CalibrationSessionState(status: CalibrationSessionStatus.initial),
        const CalibrationSessionState(
          status: CalibrationSessionStatus.error,
          errorMessage: 'Failed to load printer profile: Database error',
        ),
      ],
    );

    blocTest<CalibrationSessionCubit, CalibrationSessionState>(
      'loadSession emits error when profile is not found',
      build: () {
        when(
          () => repository.getProfileById('profile_1'),
        ).thenAnswer((_) async => const Result.success(null));
        return cubit;
      },
      act: (cubit) => cubit.loadSession(),
      expect: () => [
        const CalibrationSessionState(status: CalibrationSessionStatus.initial),
        const CalibrationSessionState(
          status: CalibrationSessionStatus.error,
          errorMessage: 'Printer profile not found.',
        ),
      ],
    );

    blocTest<CalibrationSessionCubit, CalibrationSessionState>(
      'loadSession succeeds and selects default template',
      build: () {
        when(
          () => repository.getProfileById('profile_1'),
        ).thenAnswer((_) async => Result.success(profile));
        return cubit;
      },
      act: (cubit) => cubit.loadSession(),
      expect: () => [
        const CalibrationSessionState(status: CalibrationSessionStatus.initial),
        isA<CalibrationSessionState>()
            .having(
              (s) => s.status,
              'status',
              CalibrationSessionStatus.templateSelected,
            )
            .having((s) => s.selectedTemplate, 'selectedTemplate', isNotNull)
            .having(
              (s) => s.selectedTemplate!.points.length,
              'points count',
              4,
            ),
      ],
    );

    group('with loaded session', () {
      late CalibrationSheetTemplate template;
      late CalibrationMeasurementPoint point1;
      late CalibrationMeasurementPoint point2;

      setUp(() {
        point1 = CalibrationMeasurementPoint(
          id: 'p1',
          label: 'TL',
          expectedX: 10,
          expectedY: 10,
        );
        point2 = CalibrationMeasurementPoint(
          id: 'p2',
          label: 'TR',
          expectedX: 100,
          expectedY: 10,
        );
        template = CalibrationSheetTemplate(
          id: 't1',
          name: 'T1',
          points: [point1, point2],
        );

        when(
          () => repository.getProfileById('profile_1'),
        ).thenAnswer((_) async => Result.success(profile));
      });

      blocTest<CalibrationSessionCubit, CalibrationSessionState>(
        'printCalibrationSheet fails and emits error',
        build: () {
          when(
            () => pdfGenerator.generatePdfBytes(
              template: any(named: 'template'),
              printerName: any(named: 'printerName'),
              trayName: any(named: 'trayName'),
            ),
          ).thenAnswer((_) async => Uint8List(0));
          when(
            () => printService.printRawPdf(
              pdfBytes: any(named: 'pdfBytes'),
              printer: any(named: 'printer'),
              widthMm: any(named: 'widthMm'),
              heightMm: any(named: 'heightMm'),
              docName: any(named: 'docName'),
            ),
          ).thenAnswer(
            (_) async =>
                const Result.failure(UnexpectedError(message: 'Driver error')),
          );
          return cubit;
        },
        seed: () => CalibrationSessionState(
          status: CalibrationSessionStatus.templateSelected,
          selectedTemplate: template,
          printerProfile: profile,
          trayProfile: tray,
        ),
        act: (cubit) => cubit.printCalibrationSheet(),
        expect: () => [
          isA<CalibrationSessionState>().having(
            (s) => s.status,
            'status',
            CalibrationSessionStatus.printingSheet,
          ),
          isA<CalibrationSessionState>()
              .having((s) => s.status, 'status', CalibrationSessionStatus.error)
              .having(
                (s) => s.errorMessage,
                'errorMessage',
                'Failed to spool print job: Driver error',
              ),
        ],
      );

      blocTest<CalibrationSessionCubit, CalibrationSessionState>(
        'printCalibrationSheet succeeds and transitions to sheetPrinted',
        build: () {
          when(
            () => pdfGenerator.generatePdfBytes(
              template: any(named: 'template'),
              printerName: any(named: 'printerName'),
              trayName: any(named: 'trayName'),
            ),
          ).thenAnswer((_) async => Uint8List(0));
          when(
            () => printService.printRawPdf(
              pdfBytes: any(named: 'pdfBytes'),
              printer: any(named: 'printer'),
              widthMm: any(named: 'widthMm'),
              heightMm: any(named: 'heightMm'),
              docName: any(named: 'docName'),
            ),
          ).thenAnswer((_) async => const Result.success(null));
          return cubit;
        },
        seed: () => CalibrationSessionState(
          status: CalibrationSessionStatus.templateSelected,
          selectedTemplate: template,
          printerProfile: profile,
          trayProfile: tray,
        ),
        act: (cubit) => cubit.printCalibrationSheet(),
        expect: () => [
          isA<CalibrationSessionState>().having(
            (s) => s.status,
            'status',
            CalibrationSessionStatus.printingSheet,
          ),
          isA<CalibrationSessionState>().having(
            (s) => s.status,
            'status',
            CalibrationSessionStatus.sheetPrinted,
          ),
        ],
      );

      blocTest<CalibrationSessionCubit, CalibrationSessionState>(
        'retry clears error state',
        build: () => cubit,
        seed: () => const CalibrationSessionState(
          status: CalibrationSessionStatus.error,
          errorMessage: 'Error',
        ),
        act: (cubit) => cubit.retry(),
        expect: () => [
          const CalibrationSessionState(
            status: CalibrationSessionStatus.templateSelected,
          ),
        ],
      );

      blocTest<CalibrationSessionCubit, CalibrationSessionState>(
        'measurements update progress and complete correctly',
        build: () => cubit,
        seed: () => CalibrationSessionState(
          status: CalibrationSessionStatus.templateSelected,
          selectedTemplate: template,
          printerProfile: profile,
          trayProfile: tray,
        ),
        act: (cubit) {
          cubit
            ..addMeasurement(
              CalibrationMeasurement(point: point1, actualX: 11, actualY: 10),
            )
            ..addMeasurement(
              CalibrationMeasurement(point: point2, actualX: 99, actualY: 11),
            );
        },
        expect: () => [
          isA<CalibrationSessionState>()
              .having(
                (s) => s.status,
                'status',
                CalibrationSessionStatus.measurementsInProgress,
              )
              .having((s) => s.measurements.length, 'length', 1),
          isA<CalibrationSessionState>()
              .having(
                (s) => s.status,
                'status',
                CalibrationSessionStatus.measurementsComplete,
              )
              .having((s) => s.measurements.length, 'length', 2),
        ],
      );

      blocTest<CalibrationSessionCubit, CalibrationSessionState>(
        'generateRules creates calibration sheet rule',
        build: () => cubit,
        seed: () => CalibrationSessionState(
          status: CalibrationSessionStatus.measurementsComplete,
          selectedTemplate: template,
          printerProfile: profile,
          trayProfile: tray,
          measurements: [
            CalibrationMeasurement(point: point1, actualX: 11, actualY: 10),
            CalibrationMeasurement(point: point2, actualX: 99, actualY: 10),
          ],
        ),
        act: (cubit) => cubit.generateRules(),
        expect: () => [
          isA<CalibrationSessionState>()
              .having(
                (s) => s.status,
                'status',
                CalibrationSessionStatus.rulesGenerated,
              )
              .having((s) => s.generatedRules.length, 'rules length', 1)
              .having(
                (s) => s.generatedRules.first.target.type,
                'target type',
                TargetType.sheet,
              )
              .having(
                (s) => s.generatedRules.first.transformation.offsetX,
                'offsetX',
                0.0,
              ), // mean of 1 and -1 is 0
        ],
      );

      blocTest<CalibrationSessionCubit, CalibrationSessionState>(
        'saveCalibration persists updated profile tray calibration rules',
        build: () {
          when(
            () => repository.saveProfile(any()),
          ).thenAnswer((_) async => const Result.success(null));
          return cubit;
        },
        seed: () => CalibrationSessionState(
          status: CalibrationSessionStatus.rulesGenerated,
          selectedTemplate: template,
          printerProfile: profile,
          trayProfile: tray,
          measurements: [
            CalibrationMeasurement(point: point1, actualX: 11, actualY: 10),
            CalibrationMeasurement(point: point2, actualX: 99, actualY: 10),
          ],
          generatedRules: const [
            CalibrationRule(
              target: CalibrationTarget.sheet(),
              transformation: PrintStickerTransform(scaleX: 0.977),
            ),
          ],
        ),
        act: (cubit) => cubit.saveCalibration(),
        expect: () => [
          isA<CalibrationSessionState>().having(
            (s) => s.status,
            'status',
            CalibrationSessionStatus.saving,
          ),
          isA<CalibrationSessionState>().having(
            (s) => s.status,
            'status',
            CalibrationSessionStatus.saved,
          ),
        ],
        verify: (_) {
          final captured = verify(
            () => repository.saveProfile(captureAny()),
          ).captured;
          expect(captured.length, 1);
          final savedProfile = captured.first as PrinterProfile;
          expect(savedProfile.trays.first.calibration.enabled, isTrue);
          expect(
            savedProfile.trays.first.calibration.calibrationRules.length,
            1,
          );
        },
      );
    });
  });
}
