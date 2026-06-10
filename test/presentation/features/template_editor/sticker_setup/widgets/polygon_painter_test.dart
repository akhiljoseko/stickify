import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/template_editor/sticker_setup/widgets/polygon_painter.dart';

void main() {
  group('PolygonPainter Tests', () {
    final points = [
      const StickerPoint(4, 4),
      const StickerPoint(96, 4),
      const StickerPoint(96, 56),
      const StickerPoint(4, 56),
    ];

    testWidgets('paints correctly without markers', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomPaint(
              painter: PolygonPainter(
                points: points,
                scale: 2,
                color: Colors.red,
              ),
            ),
          ),
        ),
      );

      // Verify that no exceptions are thrown during build/paint
      expect(tester.takeException(), isNull);
    });

    testWidgets('paints correctly with markers enabled', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 200,
              child: CustomPaint(
                painter: PolygonPainter(
                  points: [
                    StickerPoint(4, 4),
                    StickerPoint(96, 4),
                    StickerPoint(96, 56),
                    StickerPoint(4, 56),
                  ],
                  scale: 2,
                  color: Colors.red,
                  showMarkers: true,
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    test('shouldRepaint returns correct values', () {
      final painter1 = PolygonPainter(
        points: points,
        scale: 2,
        color: Colors.red,
      );

      final painter2 = PolygonPainter(
        points: points,
        scale: 2,
        color: Colors.red,
      );

      const painter3 = PolygonPainter(
        points: [StickerPoint(0, 0)],
        scale: 2,
        color: Colors.red,
      );

      final painter4 = PolygonPainter(
        points: points,
        scale: 3,
        color: Colors.red,
      );

      final painter5 = PolygonPainter(
        points: points,
        scale: 2,
        color: Colors.blue,
      );

      final painter6 = PolygonPainter(
        points: points,
        scale: 2,
        color: Colors.red,
        showMarkers: true,
      );

      expect(painter1.shouldRepaint(painter2), isFalse);
      expect(painter1.shouldRepaint(painter3), isTrue);
      expect(painter1.shouldRepaint(painter4), isTrue);
      expect(painter1.shouldRepaint(painter5), isTrue);
      expect(painter1.shouldRepaint(painter6), isTrue);
    });
  });
}
