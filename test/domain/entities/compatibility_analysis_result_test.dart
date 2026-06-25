import 'package:flutter_test/flutter_test.dart';
import 'package:stickify/domain/domain.dart';

void main() {
  group('CompatibilityAnalysisResult', () {
    test('supports Equatable value equality', () {
      final conflict = PrintRegionConflict(
        affectedEdge: EdgeGroup.left,
        overlapMm: 2.5,
        affectedStickerIndices: const [0],
      );

      final result1 = CompatibilityAnalysisResult(
        conflicts: [conflict],
        recommendedOptimizationLevel: OptimizationLevel.edgeGroupTranslation,
      );

      final result2 = CompatibilityAnalysisResult(
        conflicts: [conflict],
        recommendedOptimizationLevel: OptimizationLevel.edgeGroupTranslation,
      );

      final result3 = CompatibilityAnalysisResult(
        conflicts: const [],
        recommendedOptimizationLevel: OptimizationLevel.noModification,
      );

      expect(result1, equals(result2));
      expect(result1, isNot(equals(result3)));
    });

    test('stores conflicts list as unmodifiable', () {
      final conflict = PrintRegionConflict(
        affectedEdge: EdgeGroup.left,
        overlapMm: 2.5,
        affectedStickerIndices: const [0],
      );

      final result = CompatibilityAnalysisResult(
        conflicts: [conflict],
        recommendedOptimizationLevel: OptimizationLevel.edgeGroupTranslation,
      );

      expect(() => result.conflicts.add(conflict), throwsUnsupportedError);
    });

    test('computes hasConflicts correctly', () {
      final resultWithConflicts = CompatibilityAnalysisResult(
        conflicts: [
          PrintRegionConflict(
            affectedEdge: EdgeGroup.left,
            overlapMm: 2.5,
            affectedStickerIndices: const [0],
          ),
        ],
        recommendedOptimizationLevel: OptimizationLevel.edgeGroupTranslation,
      );

      final resultNoConflicts = CompatibilityAnalysisResult(
        conflicts: const [],
        recommendedOptimizationLevel: OptimizationLevel.noModification,
      );

      expect(resultWithConflicts.hasConflicts, isTrue);
      expect(resultNoConflicts.hasConflicts, isFalse);
    });
  });
}
