import 'dart:math' as math;
import 'package:collection/collection.dart';
import 'package:stickify/domain/domain.dart';

/// Pure domain service that generates sticker layout optimization strategies
/// to resolve printer compatibility and margin conflicts.
class IntelligentTransformGenerator {
  /// Creates an [IntelligentTransformGenerator] instance.
  const IntelligentTransformGenerator();

  /// Generates the minimum correction strategy for a printer/template combination.
  OptimizationStrategy generate({
    required CompatibilityAnalysisResult analysisResult,
    required LabelTemplate template,
    required PrinterProfile printer,
    required OptimizationPreferences preferences,
  }) {
    final sheetConfig = template.sheetConfig;
    final stickerConfig = template.stickerConfig;

    if (sheetConfig == null || stickerConfig == null) {
      return OptimizationStrategy(
        level: OptimizationLevel.noModification,
        description: 'No template configuration. Identity transformations applied.',
        transforms: const {},
      );
    }

    final totalColumns = sheetConfig.columns;
    final totalRows = sheetConfig.rows;
    final totalStickers = totalColumns * totalRows;

    // 1. Level 1 — No Modification
    if (!analysisResult.hasConflicts) {
      return OptimizationStrategy(
        level: OptimizationLevel.noModification,
        description: 'No conflicts detected. Identity transformations applied.',
        transforms: const {},
      );
    }

    // Determine coordinate rotation
    final templateIsPortrait = sheetConfig.pageWidth < sheetConfig.pageHeight;
    final printerSupportsPortrait = printer.capabilities.supportsPortraitCustomPaper;
    final printerSupportsLandscape = printer.capabilities.supportsLandscapeCustomPaper;
    final isRotated90 = templateIsPortrait && !printerSupportsPortrait && printerSupportsLandscape;

    // Page dimensions in printer coordinate space
    final double printerWidth = isRotated90 ? sheetConfig.pageHeight : sheetConfig.pageWidth;
    final double printerHeight = isRotated90 ? sheetConfig.pageWidth : sheetConfig.pageHeight;

    // Printer margins
    final printerMarginLeft = printer.capabilities.nonPrintableMarginLeft;
    final printerMarginRight = printer.capabilities.nonPrintableMarginRight;
    final printerMarginTop = printer.capabilities.nonPrintableMarginTop;
    final printerMarginBottom = printer.capabilities.nonPrintableMarginBottom;

    // Bounding box of relative printable region
    final double stickerMinX;
    final double stickerMaxX;
    final double stickerMinY;
    final double stickerMaxY;

    if (stickerConfig.printableArea.isNotEmpty) {
      stickerMinX = stickerConfig.printableArea.map((p) => p.x).reduce(math.min);
      stickerMaxX = stickerConfig.printableArea.map((p) => p.x).reduce(math.max);
      stickerMinY = stickerConfig.printableArea.map((p) => p.y).reduce(math.min);
      stickerMaxY = stickerConfig.printableArea.map((p) => p.y).reduce(math.max);
    } else {
      stickerMinX = 0.0;
      stickerMaxX = stickerConfig.widthMm;
      stickerMinY = 0.0;
      stickerMaxY = stickerConfig.heightMm;
    }

    final printableWidth = stickerMaxX - stickerMinX;
    final double printableHeight = stickerMaxY - stickerMinY;

    // Helper to project a slot index to its boundaries
    Map<String, double> getBounds(int r, int c) {
      final double stickerX = sheetConfig.marginLeft + c * (stickerConfig.widthMm + sheetConfig.columnGap);
      final double stickerY = sheetConfig.marginTop + r * (stickerConfig.heightMm + sheetConfig.rowGap);

      final double left = stickerX + stickerMinX;
      final double right = stickerX + stickerMaxX;
      final double top = stickerY + stickerMinY;
      final double bottom = stickerY + stickerMaxY;

      if (isRotated90) {
        return {
          'left': sheetConfig.pageHeight - bottom,
          'right': sheetConfig.pageHeight - top,
          'top': left,
          'bottom': right,
        };
      } else {
        return {
          'left': left,
          'right': right,
          'top': top,
          'bottom': bottom,
        };
      }
    }

    // Identify conflicts from the analysis result
    final leftConflict = analysisResult.conflicts.firstWhereOrNull((c) => c.affectedEdge == EdgeGroup.left);
    final rightConflict = analysisResult.conflicts.firstWhereOrNull((c) => c.affectedEdge == EdgeGroup.right);
    final topConflict = analysisResult.conflicts.firstWhereOrNull((c) => c.affectedEdge == EdgeGroup.top);
    final bottomConflict = analysisResult.conflicts.firstWhereOrNull((c) => c.affectedEdge == EdgeGroup.bottom);

    // 2. Level 2 — Global Translation
    if (preferences.allowTranslation) {
      final bool hasLeftAndRight = leftConflict != null && rightConflict != null;
      final bool hasTopAndBottom = topConflict != null && bottomConflict != null;

      if (!hasLeftAndRight && !hasTopAndBottom) {
        final double candidateOffsetX = leftConflict != null
            ? leftConflict.overlapMm
            : (rightConflict != null ? -rightConflict.overlapMm : 0.0);

        final double candidateOffsetY = topConflict != null
            ? topConflict.overlapMm
            : (bottomConflict != null ? -bottomConflict.overlapMm : 0.0);

        var globalShiftSucceeds = true;

        for (var r = 0; r < totalRows; r++) {
          for (var c = 0; c < totalColumns; c++) {
            final bounds = getBounds(r, c);
            final simLeft = bounds['left']! + candidateOffsetX;
            final simRight = bounds['right']! + candidateOffsetX;
            final simTop = bounds['top']! + candidateOffsetY;
            final simBottom = bounds['bottom']! + candidateOffsetY;

            if (simLeft < printerMarginLeft ||
                simRight > (printerWidth - printerMarginRight) ||
                simTop < printerMarginTop ||
                simBottom > (printerHeight - printerMarginBottom)) {
              globalShiftSucceeds = false;
              break;
            }
          }
          if (!globalShiftSucceeds) break;
        }

        if (globalShiftSucceeds) {
          final transforms = <int, PrintStickerTransform>{};
          for (var i = 0; i < totalStickers; i++) {
            transforms[i] = PrintStickerTransform(
              offsetX: candidateOffsetX,
              offsetY: candidateOffsetY,
              scaleX: 1.0,
              scaleY: 1.0,
              anchorX: 0.5,
              anchorY: 0.5,
            );
          }
          return OptimizationStrategy(
            level: OptimizationLevel.globalTransform,
            description: 'Global translation applied: dx = ${candidateOffsetX.toStringAsFixed(2)} mm, dy = ${candidateOffsetY.toStringAsFixed(2)} mm.',
            transforms: transforms,
          );
        }
      }
    }

    // 3. Level 3 — Edge Group Translation
    final transforms = <int, PrintStickerTransform>{};

    final hasLeft = leftConflict != null;
    final hasRight = rightConflict != null;
    final hasTop = topConflict != null;
    final hasBottom = bottomConflict != null;

    var unresolvedLeft = hasLeft;
    var unresolvedRight = hasRight;
    var unresolvedTop = hasTop;
    var unresolvedBottom = hasBottom;

    final double leftGroupShift = hasLeft ? leftConflict.overlapMm : 0.0;
    final double rightGroupShift = hasRight ? -rightConflict.overlapMm : 0.0;
    final double topGroupShift = hasTop ? topConflict.overlapMm : 0.0;
    final double bottomGroupShift = hasBottom ? -bottomConflict.overlapMm : 0.0;

    if (preferences.allowTranslation) {
      // Simulate left group translation
      if (hasLeft) {
        var leftSafe = true;
        for (final absIndex in leftConflict.affectedStickerIndices) {
          final r = absIndex ~/ totalColumns;
          final c = absIndex % totalColumns;
          final bounds = getBounds(r, c);
          if (bounds['right']! + leftGroupShift > printerWidth - printerMarginRight) {
            leftSafe = false;
            break;
          }
        }
        if (leftSafe) unresolvedLeft = false;
      }

      // Simulate right group translation
      if (hasRight) {
        var rightSafe = true;
        for (final absIndex in rightConflict.affectedStickerIndices) {
          final r = absIndex ~/ totalColumns;
          final c = absIndex % totalColumns;
          final bounds = getBounds(r, c);
          if (bounds['left']! + rightGroupShift < printerMarginLeft) {
            rightSafe = false;
            break;
          }
        }
        if (rightSafe) unresolvedRight = false;
      }

      // Simulate top group translation
      if (hasTop) {
        var topSafe = true;
        for (final absIndex in topConflict.affectedStickerIndices) {
          final r = absIndex ~/ totalColumns;
          final c = absIndex % totalColumns;
          final bounds = getBounds(r, c);
          if (bounds['bottom']! + topGroupShift > printerHeight - printerMarginBottom) {
            topSafe = false;
            break;
          }
        }
        if (topSafe) unresolvedTop = false;
      }

      // Simulate bottom group translation
      if (hasBottom) {
        var bottomSafe = true;
        for (final absIndex in bottomConflict.affectedStickerIndices) {
          final r = absIndex ~/ totalColumns;
          final c = absIndex % totalColumns;
          final bounds = getBounds(r, c);
          if (bounds['top']! + bottomGroupShift < printerMarginTop) {
            bottomSafe = false;
            break;
          }
        }
        if (bottomSafe) unresolvedBottom = false;
      }

      // Apply Level 3 translations for resolved groups
      for (var r = 0; r < totalRows; r++) {
        for (var c = 0; c < totalColumns; c++) {
          final absIndex = r * totalColumns + c;

          final inLeft = leftConflict?.affectedStickerIndices.contains(absIndex) ?? false;
          final inRight = rightConflict?.affectedStickerIndices.contains(absIndex) ?? false;
          final inTop = topConflict?.affectedStickerIndices.contains(absIndex) ?? false;
          final inBottom = bottomConflict?.affectedStickerIndices.contains(absIndex) ?? false;

          final double dx = (inLeft && !unresolvedLeft)
              ? leftGroupShift
              : ((inRight && !unresolvedRight) ? rightGroupShift : 0.0);

          final double dy = (inTop && !unresolvedTop)
              ? topGroupShift
              : ((inBottom && !unresolvedBottom) ? bottomGroupShift : 0.0);

          if (dx != 0.0 || dy != 0.0) {
            transforms[absIndex] = PrintStickerTransform(
              offsetX: dx,
              offsetY: dy,
              scaleX: 1.0,
              scaleY: 1.0,
              anchorX: 0.0,
              anchorY: 0.0,
            );
          }
        }
      }

      // If all conflicting groups were resolved by translation
      if (!unresolvedLeft && !unresolvedRight && !unresolvedTop && !unresolvedBottom) {
        return OptimizationStrategy(
          level: OptimizationLevel.edgeGroupTranslation,
          description: 'Edge group translation applied to resolve conflicts.',
          transforms: transforms,
        );
      }
    }

    // 4. Level 4 — Edge Group Scaling
    if (!preferences.allowScaling) {
      return OptimizationStrategy(
        level: OptimizationLevel.unsupported,
        description: 'Scaling is disabled by preferences. Cannot resolve conflicts.',
        transforms: const {},
      );
    }

    // 4a — Compute available space (guard: escalate to Level 6 if <= 0)
    final double availablePrinterWidth = printerWidth - printerMarginLeft - printerMarginRight;
    final double availablePrinterHeight = printerHeight - printerMarginTop - printerMarginBottom;

    if (availablePrinterWidth <= 0 || availablePrinterHeight <= 0) {
      return OptimizationStrategy(
        level: OptimizationLevel.unsupported,
        description: 'Available print region width or height is zero or negative due to margins.',
        transforms: const {},
      );
    }

    // 4b — Compute scale values
    final bool requiresScaleX = unresolvedLeft || unresolvedRight;
    final bool requiresScaleY = unresolvedTop || unresolvedBottom;

    final double scaleX = requiresScaleX ? availablePrinterWidth / printableWidth : 1.0;
    final double scaleY = requiresScaleY ? availablePrinterHeight / printableHeight : 1.0;

    // 4c — Compute scaling anchor
    final double anchorX = (printerMarginLeft + availablePrinterWidth / 2) / printerWidth;
    final double anchorY = (printerMarginTop + availablePrinterHeight / 2) / printerHeight;

    // 4f — Gate check: scale vs minimumAcceptableScale
    if (requiresScaleX && scaleX < preferences.minimumAcceptableScale) {
      return OptimizationStrategy(
        level: OptimizationLevel.unsupported,
        description: 'Template/printer combination unsupported: required X-axis compression '
            '(scaleX = ${scaleX.toStringAsFixed(2)}) falls below the minimum '
            'acceptable scale (${preferences.minimumAcceptableScale}). Sticker '
            'printable region width ${printableWidth.toStringAsFixed(1)} mm cannot be adequately '
            'reproduced in available printer width ${availablePrinterWidth.toStringAsFixed(1)} mm.',
        transforms: const {},
      );
    }

    if (requiresScaleY && scaleY < preferences.minimumAcceptableScale) {
      return OptimizationStrategy(
        level: OptimizationLevel.unsupported,
        description: 'Template/printer combination unsupported: required Y-axis compression '
            '(scaleY = ${scaleY.toStringAsFixed(2)}) falls below the minimum '
            'acceptable scale (${preferences.minimumAcceptableScale}). Sticker '
            'printable region height ${printableHeight.toStringAsFixed(1)} mm cannot be adequately '
            'reproduced in available printer height ${availablePrinterHeight.toStringAsFixed(1)} mm.',
        transforms: const {},
      );
    }

    // 4d — Build per-sticker transforms
    final composer = const CalibrationTransformComposer();
    final finalTransforms = <int, PrintStickerTransform>{};

    for (var r = 0; r < totalRows; r++) {
      for (var c = 0; c < totalColumns; c++) {
        final absIndex = r * totalColumns + c;

        final inLeft = leftConflict?.affectedStickerIndices.contains(absIndex) ?? false;
        final inRight = rightConflict?.affectedStickerIndices.contains(absIndex) ?? false;
        final inTop = topConflict?.affectedStickerIndices.contains(absIndex) ?? false;
        final inBottom = bottomConflict?.affectedStickerIndices.contains(absIndex) ?? false;

        final double sX = (inLeft && unresolvedLeft) || (inRight && unresolvedRight) ? scaleX : 1.0;
        final double sY = (inTop && unresolvedTop) || (inBottom && unresolvedBottom) ? scaleY : 1.0;

        final double aX = sX != 1.0 ? anchorX : 0.5;
        final double aY = sY != 1.0 ? anchorY : 0.5;

        final level4Transform = PrintStickerTransform(
          offsetX: 0.0,
          offsetY: 0.0,
          scaleX: sX,
          scaleY: sY,
          anchorX: aX,
          anchorY: aY,
        );

        final level3Transform = transforms[absIndex];

        if (level3Transform != null) {
          // 4e — Compose Level 3 + Level 4 transforms
          finalTransforms[absIndex] = composer.composeTwo(level3Transform, level4Transform);
        } else if (!level4Transform.isIdentity) {
          finalTransforms[absIndex] = level4Transform;
        }
      }
    }

    return OptimizationStrategy(
      level: OptimizationLevel.edgeGroupScaling,
      description: 'Edge group scaling applied to resolve conflicts.',
      transforms: finalTransforms,
    );
  }
}
