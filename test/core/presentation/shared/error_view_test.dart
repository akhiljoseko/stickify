import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stickify/core/core.dart';

import '../../../helpers/helpers.dart';

Widget wrapWithApp(Widget widget, {Size? size}) => Builder(
  builder: (context) => Scaffold(body: widget),
);

void main() {
  group('ErrorView', () {
    testWidgets('renders message text', (tester) async {
      await tester.pumpApp(
        wrapWithApp(const ErrorView(message: 'Test error message')),
        size: const Size(400, 800),
      );

      expect(find.text('An error occurred'), findsOneWidget);
      expect(find.text('Test error message'), findsOneWidget);
    });

    testWidgets('renders Try Again button when onRetry is provided', (tester) async {
      var retried = false;
      await tester.pumpApp(
        wrapWithApp(ErrorView(message: 'msg', onRetry: () => retried = true)),
        size: const Size(400, 800),
      );

      await tester.tap(find.text('Try Again'));
      expect(retried, isTrue);
    });

    testWidgets('renders Go Back button when onBack is provided', (tester) async {
      var backed = false;
      await tester.pumpApp(
        wrapWithApp(ErrorView(message: 'msg', onBack: () => backed = true)),
        size: const Size(400, 800),
      );

      await tester.tap(find.text('Go Back'));
      expect(backed, isTrue);
    });

    testWidgets('renders both buttons when both callbacks provided', (tester) async {
      await tester.pumpApp(
        wrapWithApp(ErrorView(message: 'msg', onRetry: () {}, onBack: () {})),
        size: const Size(400, 800),
      );

      expect(find.text('Try Again'), findsOneWidget);
      expect(find.text('Go Back'), findsOneWidget);
    });

    testWidgets('renders error icon', (tester) async {
      await tester.pumpApp(
        wrapWithApp(const ErrorView(message: 'msg')),
        size: const Size(400, 800),
      );

      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    });

    testWidgets('desktop layout renders Card wrapper', (tester) async {
      await tester.pumpApp(
        wrapWithApp(const ErrorView(message: 'msg')),
        size: const Size(1200, 800),
      );

      // On desktop the content is inside a Card
      expect(find.byType(Card), findsAtLeast(1));
    });
  });
}
