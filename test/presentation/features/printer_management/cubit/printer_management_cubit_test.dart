import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/printer_management/cubit/printer_management_cubit.dart';
import 'package:stickify/presentation/features/printer_management/cubit/printer_management_state.dart';

class MockPrinterDiscoveryService extends Mock implements PrinterDiscoveryService {}

class MockPrinterProfileRepository extends Mock implements PrinterProfileRepository {}

class MockPrinterProfileMatcher extends Mock implements PrinterProfileMatcher {}

class MockPrinterProfileCompatibilityAnalyzer extends Mock
    implements PrinterProfileCompatibilityAnalyzer {}

class FakePrinterProfile extends Fake implements PrinterProfile {}
class FakeDiscoveredPrinter extends Fake implements DiscoveredPrinter {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakePrinterProfile());
    registerFallbackValue(FakeDiscoveredPrinter());
  });

  group('PrinterManagementCubit', () {
    late PrinterDiscoveryService printerDiscoveryService;
    late PrinterProfileRepository printerProfileRepository;
    late PrinterProfileMatcher printerProfileMatcher;
    late PrinterProfileCompatibilityAnalyzer printerProfileCompatibilityAnalyzer;

    setUp(() {
      printerDiscoveryService = MockPrinterDiscoveryService();
      printerProfileRepository = MockPrinterProfileRepository();
      printerProfileMatcher = MockPrinterProfileMatcher();
      printerProfileCompatibilityAnalyzer = MockPrinterProfileCompatibilityAnalyzer();
    });

    PrinterProfile createProfile({
      required String id,
      required String systemPrinterName,
    }) {
      return PrinterProfile(
        id: id,
        displayName: 'Profile $id',
        status: PrinterProfileStatus.active,
        printerIdentity: PrinterIdentity(systemPrinterName: systemPrinterName),
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
            trayIdentifier: 'tray_1',
            displayName: 'Tray 1',
            supportedPaperConfigurations: const [],
            calibration: PrinterCalibration(
              enabled: false,
              calibrationRules: const [],
            ),
          ),
        ],
        createdAt: DateTime(2026, 6, 24),
        updatedAt: DateTime(2026, 6, 24),
      );
    }

    test('initial state has correct defaults', () {
      final cubit = PrinterManagementCubit(
        printerDiscoveryService: printerDiscoveryService,
        printerProfileRepository: printerProfileRepository,
        printerProfileMatcher: printerProfileMatcher,
        printerProfileCompatibilityAnalyzer: printerProfileCompatibilityAnalyzer,
      );
      expect(cubit.state.status, PrinterManagementStatus.initial);
      expect(cubit.state.matches, isEmpty);
      expect(cubit.state.compatibilityResults, isEmpty);
      expect(cubit.state.discoveredPrinterCount, 0);
      expect(cubit.state.errorMessage, isNull);
    });

    blocTest<PrinterManagementCubit, PrinterManagementState>(
      'loadPrintersAndProfiles emits loading then loaded on success',
      build: () {
        final profile = createProfile(id: '1', systemPrinterName: 'Zebra ZT411');
        const printer = DiscoveredPrinter(
          systemPrinterName: 'Zebra ZT411',
          status: DiscoveredPrinterStatus.online,
        );
        final match = PrinterProfileMatchResult(
          profile: profile,
          status: PrinterProfileMatchStatus.matched,
          discoveredPrinter: printer,
        );
        final compatibility = PrinterProfileCompatibility(
          profile: profile,
          printer: printer,
          status: PrinterCompatibilityStatus.compatible,
          issues: const [],
        );

        when(() => printerDiscoveryService.getDiscoveredPrinters())
            .thenAnswer((_) async => [printer]);
        when(() => printerProfileRepository.getAllProfiles())
            .thenAnswer((_) async => Result.success([profile]));
        when(() => printerProfileMatcher.matchProfiles(
              profiles: any(named: 'profiles'),
              discoveredPrinters: any(named: 'discoveredPrinters'),
            )).thenReturn([match]);
        when(() => printerProfileCompatibilityAnalyzer.analyze(
              profile: any(named: 'profile'),
              printer: any(named: 'printer'),
            )).thenReturn(compatibility);

        return PrinterManagementCubit(
          printerDiscoveryService: printerDiscoveryService,
          printerProfileRepository: printerProfileRepository,
          printerProfileMatcher: printerProfileMatcher,
          printerProfileCompatibilityAnalyzer: printerProfileCompatibilityAnalyzer,
        );
      },
      act: (cubit) => cubit.loadPrintersAndProfiles(),
      expect: () => [
        const PrinterManagementState(status: PrinterManagementStatus.loading),
        isA<PrinterManagementState>()
            .having((s) => s.status, 'status', PrinterManagementStatus.loaded)
            .having((s) => s.discoveredPrinterCount, 'discoveredPrinterCount', 1)
            .having((s) => s.matches.length, 'matches.length', 1)
            .having((s) => s.compatibilityResults.length, 'compatibilityResults.length', 1),
      ],
    );

    blocTest<PrinterManagementCubit, PrinterManagementState>(
      'loadPrintersAndProfiles emits loaded with empty discovered count when discovery is empty',
      build: () {
        final profile = createProfile(id: '1', systemPrinterName: 'Zebra ZT411');
        final match = PrinterProfileMatchResult(
          profile: profile,
          status: PrinterProfileMatchStatus.missing,
        );

        when(() => printerDiscoveryService.getDiscoveredPrinters())
            .thenAnswer((_) async => []);
        when(() => printerProfileRepository.getAllProfiles())
            .thenAnswer((_) async => Result.success([profile]));
        when(() => printerProfileMatcher.matchProfiles(
              profiles: any(named: 'profiles'),
              discoveredPrinters: any(named: 'discoveredPrinters'),
            )).thenReturn([match]);

        return PrinterManagementCubit(
          printerDiscoveryService: printerDiscoveryService,
          printerProfileRepository: printerProfileRepository,
          printerProfileMatcher: printerProfileMatcher,
          printerProfileCompatibilityAnalyzer: printerProfileCompatibilityAnalyzer,
        );
      },
      act: (cubit) => cubit.loadPrintersAndProfiles(),
      expect: () => [
        const PrinterManagementState(status: PrinterManagementStatus.loading),
        isA<PrinterManagementState>()
            .having((s) => s.status, 'status', PrinterManagementStatus.loaded)
            .having((s) => s.discoveredPrinterCount, 'discoveredPrinterCount', 0)
            .having((s) => s.matches.length, 'matches.length', 1)
            .having((s) => s.compatibilityResults, 'compatibilityResults', isEmpty),
      ],
      verify: (_) {
        verifyNever(() => printerProfileCompatibilityAnalyzer.analyze(
              profile: any(named: 'profile'),
              printer: any(named: 'printer'),
            ));
      },
    );

    blocTest<PrinterManagementCubit, PrinterManagementState>(
      'loadPrintersAndProfiles emits failure when repository fails',
      build: () {
        when(() => printerDiscoveryService.getDiscoveredPrinters())
            .thenAnswer((_) async => []);
        when(() => printerProfileRepository.getAllProfiles()).thenAnswer(
          (_) async => const Result.failure(
            UnexpectedError(message: 'Repository unavailable'),
          ),
        );

        return PrinterManagementCubit(
          printerDiscoveryService: printerDiscoveryService,
          printerProfileRepository: printerProfileRepository,
          printerProfileMatcher: printerProfileMatcher,
          printerProfileCompatibilityAnalyzer: printerProfileCompatibilityAnalyzer,
        );
      },
      act: (cubit) => cubit.loadPrintersAndProfiles(),
      expect: () => [
        const PrinterManagementState(status: PrinterManagementStatus.loading),
        isA<PrinterManagementState>()
            .having((s) => s.status, 'status', PrinterManagementStatus.failure)
            .having((s) => s.errorMessage, 'errorMessage', 'Repository unavailable'),
      ],
    );

    blocTest<PrinterManagementCubit, PrinterManagementState>(
      'loadPrintersAndProfiles emits failure when discovery service throws',
      build: () {
        when(() => printerDiscoveryService.getDiscoveredPrinters())
            .thenThrow(Exception('OS error'));

        return PrinterManagementCubit(
          printerDiscoveryService: printerDiscoveryService,
          printerProfileRepository: printerProfileRepository,
          printerProfileMatcher: printerProfileMatcher,
          printerProfileCompatibilityAnalyzer: printerProfileCompatibilityAnalyzer,
        );
      },
      act: (cubit) => cubit.loadPrintersAndProfiles(),
      expect: () => [
        const PrinterManagementState(status: PrinterManagementStatus.loading),
        isA<PrinterManagementState>()
            .having((s) => s.status, 'status', PrinterManagementStatus.failure)
            .having((s) => s.errorMessage, 'errorMessage', contains('OS error')),
      ],
    );
  });
}
