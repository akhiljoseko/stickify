import 'package:flutter_test/flutter_test.dart';
import 'package:stickify/domain/domain.dart';

void main() {
  group('CalibrationGenerationResult', () {
    const rule1 = CalibrationRule(
      target: CalibrationTarget.sheet(),
      transformation: PrintStickerTransform(scaleX: 1.01),
    );
    const rule2 = CalibrationRule(
      target: CalibrationTarget.row(0),
      transformation: PrintStickerTransform(offsetX: 0.5),
    );

    test('succeeds on valid construction', () {
      final result = CalibrationGenerationResult(
        generatedRules: const [rule1, rule2],
      );
      expect(result.generatedRules, const [rule1, rule2]);
    });

    test('verifies defensive copying and immutability', () {
      final originalList = [rule1];
      final result = CalibrationGenerationResult(
        generatedRules: originalList,
      );

      // Verify defensive copy: modifying original does not affect constructed result
      originalList.add(rule2);
      expect(result.generatedRules.length, 1);
      expect(result.generatedRules, contains(rule1));

      // Verify unmodifiable: attempting to modify result rules list throws UnsupportedError
      expect(
        () => result.generatedRules.add(rule2),
        throwsUnsupportedError,
      );
      expect(
        result.generatedRules.clear,
        throwsUnsupportedError,
      );
    });

    test('supports Equatable equality', () {
      final resultA = CalibrationGenerationResult(
        generatedRules: const [rule1, rule2],
      );
      final resultB = CalibrationGenerationResult(
        generatedRules: const [rule1, rule2],
      );
      final resultC = CalibrationGenerationResult(
        generatedRules: const [rule1],
      );

      expect(resultA, resultB);
      expect(resultA, isNot(resultC));
    });
  });
}
