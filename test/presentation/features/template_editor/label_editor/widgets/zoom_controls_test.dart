import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stickify/presentation/features/template_editor/label_editor/widgets/zoom_controls.dart';

void main() {
  group('ZoomControls', () {
    testWidgets('renders slider with current zoom level', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ZoomControls(
              zoomLevel: 1,
              onZoomChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(Slider), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
    });

    testWidgets('calls onZoomChanged when slider is dragged', (tester) async {
      double? zoomValue;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ZoomControls(
              zoomLevel: 1,
              onZoomChanged: (val) {
                zoomValue = val;
              },
            ),
          ),
        ),
      );

      final slider = find.byType(Slider);
      // Drag slider thumb right (increase zoom)
      final sliderRect = tester.getRect(slider);
      final start = Offset(sliderRect.center.dx, sliderRect.center.dy);
      final end = Offset(sliderRect.right - 4, sliderRect.center.dy);
      final gesture = await tester.startGesture(start);
      await gesture.moveTo(end);
      await gesture.up();
      await tester.pumpAndSettle();

      expect(zoomValue, isNotNull);
      expect(zoomValue, greaterThan(1.0));
    });

    testWidgets('shows zoom-to-fit button when onZoomToFit is provided', (tester) async {
      var zoomToFitCalled = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ZoomControls(
              zoomLevel: 1,
              onZoomChanged: (_) {},
              onZoomToFit: () {
                zoomToFitCalled = true;
              },
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.fit_screen_outlined), findsOneWidget);
      await tester.tap(find.byIcon(Icons.fit_screen_outlined));
      await tester.pumpAndSettle();
      expect(zoomToFitCalled, isTrue);
    });

    testWidgets('hides zoom-to-fit button when onZoomToFit is null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ZoomControls(
              zoomLevel: 1,
              onZoomChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.fit_screen_outlined), findsNothing);
    });

    testWidgets('displays zoom percentage correctly at boundaries', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ZoomControls(
              zoomLevel: 0.5,
              onZoomChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('50%'), findsOneWidget);
    });
  });
}
