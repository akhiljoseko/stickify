import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stickify/app/app_service_locator.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/printer_management/cubit/calibration_session_cubit.dart';
import 'package:stickify/presentation/features/printer_management/cubit/calibration_session_state.dart';
import 'package:stickify/presentation/features/printer_management/views/calibration_wizard_page.dart';

import '../../../../helpers/pump_app.dart';

class MockAppServiceLocator extends Mock implements AppServiceLocator {}
class MockCalibrationSessionCubit extends MockCubit<CalibrationSessionState>
    implements CalibrationSessionCubit {}

void main() {
  group('CalibrationWizardPage & View Tests', () {
    late AppServiceLocator locator;
    late CalibrationSessionCubit cubit;
    late CalibrationSheetTemplate template;
    late CalibrationMeasurementPoint point1;

    setUp(() {
      locator = MockAppServiceLocator();
      cubit = MockCalibrationSessionCubit();

      point1 = CalibrationMeasurementPoint(id: 'p1', label: 'TL', expectedX: 10, expectedY: 10);
      template = CalibrationSheetTemplate(
        id: 'standard_calibration',
        name: 'Standard Template',
        points: [point1],
      );

      when(() => locator.createCalibrationSessionCubit(
            profileId: any(named: 'profileId'),
            trayId: any(named: 'trayId'),
            paperConfigurationId: any(named: 'paperConfigurationId'),
          )).thenReturn(cubit);

      when(() => cubit.loadSession()).thenAnswer((_) async {});
      when(() => cubit.printCalibrationSheet()).thenAnswer((_) async {});
      when(() => cubit.retry()).thenAnswer((_) => {});
    });

    Widget buildTestWidget() {
      return RepositoryProvider<AppServiceLocator>.value(
        value: locator,
        child: const CalibrationWizardPage(
          profileId: 'p-1',
          trayId: 't-1',
          paperConfigurationId: 'pc-1',
        ),
      );
    }

    testWidgets('renders loading state', (tester) async {
      when(() => cubit.state).thenReturn(
        const CalibrationSessionState(status: CalibrationSessionStatus.initial),
      );

      await tester.pumpApp(buildTestWidget());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders step 1 (print sheet) content', (tester) async {
      when(() => cubit.state).thenReturn(
        CalibrationSessionState(
          status: CalibrationSessionStatus.templateSelected,
          selectedTemplate: template,
        ),
      );

      await tester.pumpApp(buildTestWidget());

      expect(find.text('Print Calibration Sheet'), findsNWidgets(2)); // Title and Button
      expect(find.byIcon(Icons.print_outlined), findsOneWidget);
    });

    testWidgets('shows loading and disables buttons when printing', (tester) async {
      when(() => cubit.state).thenReturn(
        CalibrationSessionState(
          status: CalibrationSessionStatus.printingSheet,
          selectedTemplate: template,
        ),
      );

      await tester.pumpApp(buildTestWidget());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Sending job to printer...'), findsOneWidget);

      final nextButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Next'),
      );
      expect(nextButton.onPressed, isNull); // disabled
    });

    testWidgets('renders error page at step 0', (tester) async {
      when(() => cubit.state).thenReturn(
        CalibrationSessionState(
          status: CalibrationSessionStatus.error,
          selectedTemplate: template,
          errorMessage: 'Print spooler failed',
        ),
      );

      await tester.pumpApp(buildTestWidget());

      expect(find.text('An Error Occurred'), findsOneWidget);
      expect(find.text('Print spooler failed'), findsOneWidget);
      expect(find.text('Retry Loading Session'), findsOneWidget);
    });
  });
}
