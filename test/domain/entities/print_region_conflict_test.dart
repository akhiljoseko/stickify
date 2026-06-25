import 'package:flutter_test/flutter_test.dart';
import 'package:stickify/domain/domain.dart';

void main() {
  group('PrintRegionConflict', () {
    test('supports Equatable value equality', () {
      final conflict1 = PrintRegionConflict(
        affectedEdge: EdgeGroup.left,
        overlapMm: 2.5,
        affectedStickerIndices: const [0, 1],
      );

      final conflict2 = PrintRegionConflict(
        affectedEdge: EdgeGroup.left,
        overlapMm: 2.5,
        affectedStickerIndices: const [0, 1],
      );

      final conflict3 = PrintRegionConflict(
        affectedEdge: EdgeGroup.right,
        overlapMm: 1.0,
        affectedStickerIndices: const [2],
      );

      expect(conflict1, equals(conflict2));
      expect(conflict1, isNot(equals(conflict3)));
    });

    test('enforces overlapMm > 0', () {
      expect(
        () => PrintRegionConflict(
          affectedEdge: EdgeGroup.left,
          overlapMm: 0,
          affectedStickerIndices: const [0],
        ),
        throwsAssertionError,
      );

      expect(
        () => PrintRegionConflict(
          affectedEdge: EdgeGroup.left,
          overlapMm: -1.0,
          affectedStickerIndices: const [0],
        ),
        throwsAssertionError,
      );
    });
  });
}
