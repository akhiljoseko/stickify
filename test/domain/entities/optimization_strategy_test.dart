import 'package:flutter_test/flutter_test.dart';
import 'package:stickify/domain/domain.dart';

void main() {
  group('OptimizationStrategy', () {
    test('supports Equatable value equality', () {
      const transform = PrintStickerTransform(offsetX: 1);
      final strategy1 = OptimizationStrategy(
        level: OptimizationLevel.globalTransform,
        description: 'Global translation',
        transforms: const {0: transform},
      );

      final strategy2 = OptimizationStrategy(
        level: OptimizationLevel.globalTransform,
        description: 'Global translation',
        transforms: const {0: transform},
      );

      final strategy3 = OptimizationStrategy(
        level: OptimizationLevel.noModification,
        description: 'No modification',
        transforms: const {},
      );

      expect(strategy1, equals(strategy2));
      expect(strategy1, isNot(equals(strategy3)));
    });

    test('stores transforms map as unmodifiable', () {
      const transform = PrintStickerTransform(offsetX: 1);
      final strategy = OptimizationStrategy(
        level: OptimizationLevel.globalTransform,
        description: 'Global translation',
        transforms: const {0: transform},
      );

      expect(() => strategy.transforms[1] = transform, throwsUnsupportedError);
    });
  });
}
