import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stickify/app/app_service_locator.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/printer_management/cubit/printer_management_cubit.dart';
import 'package:stickify/presentation/features/printer_management/cubit/printer_management_state.dart';
import 'package:stickify/presentation/features/printer_management/views/printer_management_page.dart';
import 'package:stickify/presentation/features/printer_management/widgets/empty_printer_state.dart';
import 'package:stickify/presentation/features/printer_management/widgets/printer_card.dart';

import '../../../../helpers/pump_app.dart';

class MockAppServiceLocator extends Mock implements AppServiceLocator {}

class MockPrinterManagementCubit extends MockCubit<PrinterManagementState>
    implements PrinterManagementCubit {}

void main() {
  group('PrinterManagementPage & Views', () {
    late AppServiceLocator locator;
    late PrinterManagementCubit cubit;

    setUp(() {
      locator = MockAppServiceLocator();
      cubit = MockPrinterManagementCubit();

      when(() => locator.createPrinterManagementCubit()).thenReturn(cubit);
      when(() => cubit.loadPrintersAndProfiles()).thenAnswer((_) async {});
    });

    PrinterProfile createProfile({
      required String id,
      required String displayName,
      required String systemPrinterName,
    }) {
      return PrinterProfile(
        id: id,
        displayName: displayName,
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
          preferShrinkOverShift: false,
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

    Widget buildTestWidget() {
      return RepositoryProvider<AppServiceLocator>.value(
        value: locator,
        child: const PrinterManagementPage(),
      );
    }

    testWidgets('renders loading state', (tester) async {
      when(() => cubit.state).thenReturn(
        const PrinterManagementState(status: PrinterManagementStatus.loading),
      );

      await tester.pumpApp(buildTestWidget());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders error state with Try Again button', (tester) async {
      when(() => cubit.state).thenReturn(
        const PrinterManagementState(
          status: PrinterManagementStatus.failure,
          errorMessage: 'Unable to connect to service',
        ),
      );

      await tester.pumpApp(buildTestWidget());

      expect(find.text('Failed to load printers'), findsOneWidget);
      expect(find.text('Unable to connect to service'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);

      await tester.tap(find.text('Try Again'));
      verify(() => cubit.loadPrintersAndProfiles()).called(2);
    });

    testWidgets('renders Empty State A (No Profiles)', (tester) async {
      when(() => cubit.state).thenReturn(
        const PrinterManagementState(
          status: PrinterManagementStatus.loaded,
        ),
      );

      await tester.pumpApp(buildTestWidget());

      expect(find.byType(EmptyPrinterState), findsOneWidget);
      expect(find.text('No printer profiles configured'), findsOneWidget);
      expect(find.text('Add Printer Profile'), findsOneWidget);
    });

    testWidgets('renders Empty State B (No Printers but Profiles Exist)', (tester) async {
      final profile = createProfile(
        id: '1',
        displayName: 'Office Zebra',
        systemPrinterName: 'Zebra_ZT411',
      );
      final match = PrinterProfileMatchResult(
        profile: profile,
        status: PrinterProfileMatchStatus.missing,
      );

      when(() => cubit.state).thenReturn(
        PrinterManagementState(
          status: PrinterManagementStatus.loaded,
          matches: [match],
        ),
      );

      await tester.pumpApp(buildTestWidget());

      expect(find.byType(EmptyPrinterState), findsOneWidget);
      expect(find.text('Printers Unavailable'), findsOneWidget);
      expect(find.text('Scan for Printers'), findsOneWidget);
    });

    testWidgets('renders list of matched printers with cards', (tester) async {
      final profile1 = createProfile(
        id: 'p1',
        displayName: 'ZT411 Labeler',
        systemPrinterName: 'Zebra_ZT411',
      );
      final profile2 = createProfile(
        id: 'p2',
        displayName: 'Office HP',
        systemPrinterName: 'HP_LaserJet',
      );

      const printer1 = DiscoveredPrinter(
        systemPrinterName: 'Zebra_ZT411',
        status: DiscoveredPrinterStatus.online,
        manufacturer: 'Zebra',
        model: 'ZT411',
      );
      const printer2 = DiscoveredPrinter(
        systemPrinterName: 'HP_LaserJet',
        status: DiscoveredPrinterStatus.online,
      );

      final match1 = PrinterProfileMatchResult(
        profile: profile1,
        status: PrinterProfileMatchStatus.matched,
        discoveredPrinter: printer1,
      );
      final match2 = PrinterProfileMatchResult(
        profile: profile2,
        status: PrinterProfileMatchStatus.compatible,
        discoveredPrinter: printer2,
      );

      final compatibility1 = PrinterProfileCompatibility(
        profile: profile1,
        printer: printer1,
        status: PrinterCompatibilityStatus.compatible,
        issues: const [],
      );

      when(() => cubit.state).thenReturn(
        PrinterManagementState(
          status: PrinterManagementStatus.loaded,
          matches: [match1, match2],
          compatibilityResults: {
            'p1': compatibility1,
          },
          discoveredPrinterCount: 2,
        ),
      );

      await tester.pumpApp(buildTestWidget());

      expect(find.byType(PrinterCard), findsNWidgets(2));
      expect(find.text('ZT411 Labeler'), findsOneWidget);
      expect(find.text('Office HP'), findsOneWidget);
      expect(find.text('Exact Match'), findsOneWidget);
      expect(find.text('Compatible Model'), findsOneWidget);

      // Verify that compatibility1 (Exact Match/Compatible indicator) is rendered
      expect(find.text('Compatible'), findsOneWidget);
    });

    testWidgets('clicking refresh action calls loadPrintersAndProfiles', (tester) async {
      when(() => cubit.state).thenReturn(
        const PrinterManagementState(
          status: PrinterManagementStatus.loaded,
        ),
      );

      await tester.pumpApp(buildTestWidget());

      final refreshBtn = find.byTooltip('Refresh');
      expect(refreshBtn, findsOneWidget);

      await tester.tap(refreshBtn);
      verify(() => cubit.loadPrintersAndProfiles()).called(2);
    });
  });
}
