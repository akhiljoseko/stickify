import 'package:flutter_test/flutter_test.dart';
import 'package:stickify/domain/entities/print_coordinate_context.dart';

void main() {
  group('PrintCoordinateContext resolveFor Tests', () {
    test('resolves direct absolute slot override when available', () {
      const transformSlot5 = PrintStickerTransform(offsetX: 2.5, offsetY: 1.5);
      const context = PrintCoordinateContext(
        stickerTransforms: {
          5: transformSlot5,
        },
      );

      final result = context.resolveFor(row: 1, column: 1, absoluteSlotIndex: 5);
      expect(result, equals(transformSlot5));
    });

    test('resolves per-sheet grid slot using modulo when slotsPerSheet is provided', () {
      const transformSlot5 = PrintStickerTransform(offsetX: 3, offsetY: 2);
      const context = PrintCoordinateContext(
        stickerTransforms: {
          5: transformSlot5,
        },
      );

      // Slot 25 on a 20-slot template (Sheet 1, cellIndex 5)
      final resultSheet1 = context.resolveFor(
        row: 1,
        column: 1,
        absoluteSlotIndex: 25,
        slotsPerSheet: 20,
      );
      expect(resultSheet1, equals(transformSlot5));

      // Slot 45 on a 20-slot template (Sheet 2, cellIndex 5)
      final resultSheet2 = context.resolveFor(
        row: 1,
        column: 1,
        absoluteSlotIndex: 45,
        slotsPerSheet: 20,
      );
      expect(resultSheet2, equals(transformSlot5));
    });

    test('falls back to column, row, or global transform when slot override is missing', () {
      const colTransform = PrintStickerTransform(offsetX: 1);
      const context = PrintCoordinateContext(
        columnTransforms: {
          2: colTransform,
        },
      );

      final result = context.resolveFor(
        row: 0,
        column: 2,
        absoluteSlotIndex: 42,
        slotsPerSheet: 20,
      );
      expect(result, equals(colTransform));
    });
  });
}
