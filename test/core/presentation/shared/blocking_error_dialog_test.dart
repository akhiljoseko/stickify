import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stickify/core/core.dart';

import '../../../helpers/helpers.dart';

Widget wrapWithScaffold(Widget widget) => Builder(
  builder: (context) => Scaffold(body: widget),
);

void main() {
  group('BlockingErrorDialog', () {
    testWidgets('shows message text', (tester) async {
      await tester.pumpApp(
        wrapWithScaffold(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => BlockingErrorDialog.show(
                context,
                message: 'Something failed',
              ),
              child: const Text('Show'),
            ),
          ),
        ),
        size: const Size(400, 800),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Something failed'), findsOneWidget);
      expect(find.text('Dismiss'), findsOneWidget);
    });

    testWidgets('shows custom title when provided', (tester) async {
      await tester.pumpApp(
        wrapWithScaffold(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => BlockingErrorDialog.show(
                context,
                message: 'msg',
                title: 'Custom Error Title',
              ),
              child: const Text('Show'),
            ),
          ),
        ),
        size: const Size(400, 800),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.text('Custom Error Title'), findsOneWidget);
    });

    testWidgets('shows Try Again button when onRetry is provided', (tester) async {
      var retried = false;
      await tester.pumpApp(
        wrapWithScaffold(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => BlockingErrorDialog.show(
                context,
                message: 'msg',
                onRetry: () => retried = true,
              ),
              child: const Text('Show'),
            ),
          ),
        ),
        size: const Size(400, 800),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.text('Try Again'), findsOneWidget);
      await tester.tap(find.text('Try Again'));
      await tester.pumpAndSettle();
      expect(retried, isTrue);
    });

    testWidgets('shows Close button when onClose is provided', (tester) async {
      var closed = false;
      await tester.pumpApp(
        wrapWithScaffold(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => BlockingErrorDialog.show(
                context,
                message: 'msg',
                onClose: () => closed = true,
              ),
              child: const Text('Show'),
            ),
          ),
        ),
        size: const Size(400, 800),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.text('Close'), findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(closed, isTrue);
    });

    testWidgets('shows error icon', (tester) async {
      await tester.pumpApp(
        wrapWithScaffold(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => BlockingErrorDialog.show(
                context,
                message: 'msg',
              ),
              child: const Text('Show'),
            ),
          ),
        ),
        size: const Size(400, 800),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    });

    testWidgets('barrier is not dismissible', (tester) async {
      await tester.pumpApp(
        wrapWithScaffold(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => BlockingErrorDialog.show(
                context,
                message: 'msg',
              ),
              child: const Text('Show'),
            ),
          ),
        ),
        size: const Size(400, 800),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      // Tap on the barrier — dialog should still be visible
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.text('Something went wrong'), findsOneWidget);
    });
  });
}
