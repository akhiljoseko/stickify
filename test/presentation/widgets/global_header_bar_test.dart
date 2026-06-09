import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stickify/presentation/widgets/global_header_bar.dart';
import 'package:stickify/presentation/widgets/notification_action_button.dart';
import 'package:stickify/presentation/widgets/profile_action_button.dart';
import 'package:stickify/presentation/widgets/search_bar_widget.dart';

import '../../helpers/helpers.dart';

void main() {
  group('GlobalHeaderBar', () {
    testWidgets('renders search, notifications, and profile on desktop', (tester) async {
      await tester.pumpApp(
        const Scaffold(body: GlobalHeaderBar()),
        size: const Size(1200, 800),
      );

      // Verify sub-components are present
      expect(find.byType(SearchBarWidget), findsOneWidget);
      expect(find.byType(NotificationActionButton), findsOneWidget);
      expect(find.byType(ProfileActionButton), findsOneWidget);

      // Verify help button is present on desktop
      expect(find.byIcon(Icons.help_outline), findsOneWidget);
    });

    testWidgets('hides help button on mobile viewports', (tester) async {
      await tester.pumpApp(
        const Scaffold(body: GlobalHeaderBar()),
        size: const Size(400, 800),
      );

      expect(find.byType(SearchBarWidget), findsOneWidget);
      expect(find.byType(NotificationActionButton), findsOneWidget);
      expect(find.byType(ProfileActionButton), findsOneWidget);

      // Verify help button is hidden on mobile
      expect(find.byIcon(Icons.help_outline), findsNothing);
    });
  });
}
