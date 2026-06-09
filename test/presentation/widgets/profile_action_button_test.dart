import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stickify/presentation/widgets/profile_action_button.dart';

import '../../helpers/helpers.dart';

void main() {
  group('ProfileActionButton', () {
    testWidgets('renders name and role on desktop viewports', (tester) async {
      // Set desktop viewport size
      await tester.pumpApp(
        const Scaffold(body: ProfileActionButton()),
        size: const Size(1200, 800),
      );

      // Verify profile components
      expect(find.byType(Image), findsOneWidget);
      expect(find.text('Alex Miller'), findsOneWidget);
      expect(find.text('ADMIN LEVEL 4'), findsOneWidget);
    });

    testWidgets('hides name and role on mobile viewports', (tester) async {
      // Set mobile viewport size
      await tester.pumpApp(
        const Scaffold(body: ProfileActionButton()),
        size: const Size(400, 800),
      );

      expect(find.byType(Image), findsOneWidget);
      expect(find.text('Alex Miller'), findsNothing);
      expect(find.text('ADMIN LEVEL 4'), findsNothing);
    });

    testWidgets('shows snackbar on tap', (tester) async {
      await tester.pumpApp(
        const Scaffold(body: ProfileActionButton()),
        size: const Size(1200, 800),
      );

      await tester.tap(find.byType(ProfileActionButton));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Profile settings clicked'), findsOneWidget);
    });

    testWidgets('changes background on hover', (tester) async {
      await tester.pumpApp(
        const Scaffold(
          body: Center(
            child: ProfileActionButton(),
          ),
        ),
        size: const Size(1200, 800),
      );

      final containerWidget = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final decoration = containerWidget.decoration as BoxDecoration?;
      expect(decoration?.color, Colors.transparent);

      // Simulate hover
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await gesture.moveTo(tester.getCenter(find.byType(ProfileActionButton)));
      await tester.pumpAndSettle();

      final hoveredContainerWidget = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final hoveredDecoration = hoveredContainerWidget.decoration as BoxDecoration?;
      expect(hoveredDecoration?.color, isNot(Colors.transparent));
    });
  });
}
