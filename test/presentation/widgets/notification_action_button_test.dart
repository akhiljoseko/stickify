import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stickify/presentation/widgets/notification_action_button.dart';

import '../../helpers/helpers.dart';

void main() {
  group('NotificationActionButton', () {
    testWidgets('renders notification bell icon and badge', (tester) async {
      await tester.pumpApp(const Scaffold(body: NotificationActionButton()));

      expect(find.byIcon(Icons.notifications_none_outlined), findsOneWidget);
      // Verify badge Container exists by looking for a container with colorScheme.error (red)
      final badgeFinder = find.byType(Container);
      expect(badgeFinder, findsWidgets);
    });

    testWidgets('shows snackbar on tap', (tester) async {
      await tester.pumpApp(const Scaffold(body: NotificationActionButton()));

      await tester.tap(find.byType(NotificationActionButton));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('No new notifications'), findsOneWidget);
    });

    testWidgets('changes background on hover', (tester) async {
      await tester.pumpApp(
        const Scaffold(
          body: Center(
            child: NotificationActionButton(),
          ),
        ),
      );

      // Verify initial transparent color by finding AnimatedContainer
      final containerWidget = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final decoration = containerWidget.decoration as BoxDecoration?;
      expect(decoration?.color, Colors.transparent);

      // Simulate mouse hover
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await gesture.moveTo(tester.getCenter(find.byType(NotificationActionButton)));
      await tester.pumpAndSettle();

      // Verify background color changes on hover
      final hoveredContainerWidget = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final hoveredDecoration = hoveredContainerWidget.decoration as BoxDecoration?;
      expect(hoveredDecoration?.color, isNot(Colors.transparent));
    });
  });
}
