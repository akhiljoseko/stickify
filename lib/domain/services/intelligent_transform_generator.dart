import 'dart:math' as math;
import 'package:collection/collection.dart';
import 'package:stickify/core/core.dart';
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
    required PrinterTrayProfile tray,
    required OptimizationPreferences preferences,
    PrintCoordinateContext? calibrationContext,
  }) {
    final sheetConfig = template.sheetConfig;
    final stickerConfig = template.stickerConfig;

    if (sheetConfig == null || stickerConfig == null) {
      return OptimizationStrategy(
        level: OptimizationLevel.noModification,
        description:
            'No template configuration. Identity transformations applied.',
        transforms: const {},
      );
    }

    final totalColumns = sheetConfig.columns;
    final totalRows = sheetConfig.rows;
    final totalStickers = totalColumns * totalRows;

    Log.debug(
      'TransformGenerator: input template="${template.name}", '
      'conflicts=${analysisResult.conflicts.length}, '
      'sheet=${sheetConfig.pageWidth}×${sheetConfig.pageHeight}mm, '
      'grid=$totalColumns×$totalRows, '
      'sticker=${stickerConfig.widthMm}×${stickerConfig.heightMm}mm, '
      'margins sheet=(${sheetConfig.marginLeft},${sheetConfig.marginTop},${sheetConfig.marginRight},${sheetConfig.marginBottom})',
      tag: 'PrintPipeline',
    );

    // 1. Level 1 — No Modification
    if (!analysisResult.hasConflicts) {
      Log.debug(
        'TransformGenerator: Level 1 — no conflicts, identity transform.',
        tag: 'PrintPipeline',
      );
      return OptimizationStrategy(
        level: OptimizationLevel.noModification,
        description: 'No conflicts detected. Identity transformations applied.',
        transforms: const {},
      );
    }

    // Determine coordinate rotation
    final templateIsPortrait = sheetConfig.pageWidth < sheetConfig.pageHeight;
    final printerSupportsPortrait =
        printer.capabilities.supportsPortraitCustomPaper;
    final printerSupportsLandscape =
        printer.capabilities.supportsLandscapeCustomPaper;
    final bool isRotated90;
    if (templateIsPortrait) {
      isRotated90 = !printerSupportsPortrait && printerSupportsLandscape;
    } else {
      isRotated90 = !printerSupportsLandscape && printerSupportsPortrait;
    }

    // Page dimensions in printer coordinate space
    final printerWidth = isRotated90
        ? sheetConfig.pageHeight
        : sheetConfig.pageWidth;
    final printerHeight = isRotated90
        ? sheetConfig.pageWidth
        : sheetConfig.pageHeight;

    // Printer margins
    final printerMarginLeft = tray.nonPrintableMarginLeft;
    final printerMarginRight = tray.nonPrintableMarginRight;
    final printerMarginTop = tray.nonPrintableMarginTop;
    final printerMarginBottom = tray.nonPrintableMarginBottom;

    // Bounding box of relative printable region
    final double stickerMinX;
    final double stickerMaxX;
    final double stickerMinY;
    final double stickerMaxY;

    if (stickerConfig.printableArea.isNotEmpty) {
      stickerMinX = stickerConfig.printableArea
          .map((p) => p.x)
          .reduce(math.min);
      stickerMaxX = stickerConfig.printableArea
          .map((p) => p.x)
          .reduce(math.max);
      stickerMinY = stickerConfig.printableArea
          .map((p) => p.y)
          .reduce(math.min);
      stickerMaxY = stickerConfig.printableArea
          .map((p) => p.y)
          .reduce(math.max);
    } else {
      stickerMinX = 0.0;
      stickerMaxX = stickerConfig.widthMm;
      stickerMinY = 0.0;
      stickerMaxY = stickerConfig.heightMm;
    }

    final printableWidth = stickerMaxX - stickerMinX;
    final printableHeight = stickerMaxY - stickerMinY;

    // Returns the calibration transform for a slot, with X/Y components
    // swapped when the sheet is rotated 90°.
    PrintStickerTransform calForSlot(int r, int c, int absIndex) {
      final raw = calibrationContext?.resolveFor(
            row: r,
            column: c,
            absoluteSlotIndex: absIndex,
          ) ??
          const PrintStickerTransform.identity();
      if (!isRotated90) return raw;
      final swapped = PrintStickerTransform(
        offsetX: raw.offsetY,
        offsetY: raw.offsetX,
        scaleX: raw.scaleY,
        scaleY: raw.scaleX,
        anchorX: raw.anchorY,
        anchorY: raw.anchorX,
      );
      Log.debug(
        'calForSlot[rotated]: slot=$absIndex '
        'raw=(${raw.offsetX.toStringAsFixed(3)},${raw.offsetY.toStringAsFixed(3)},'
        '${raw.scaleX.toStringAsFixed(5)},${raw.scaleY.toStringAsFixed(5)}) → '
        'swapped=(${swapped.offsetX.toStringAsFixed(3)},${swapped.offsetY.toStringAsFixed(3)},'
        '${swapped.scaleX.toStringAsFixed(5)},${swapped.scaleY.toStringAsFixed(5)})',
        tag: 'PrintPipeline',
      );
      return swapped;
    }

    // Helper to project a slot index to its boundaries
    Map<String, double> getBounds(int r, int c) {
      final stickerX =
          sheetConfig.marginLeft +
          c * (stickerConfig.widthMm + sheetConfig.columnGap);
      final stickerY =
          sheetConfig.marginTop +
          r * (stickerConfig.heightMm + sheetConfig.rowGap);

      final transform = calForSlot(r, c, r * totalColumns + c);

      final calStickerX =
          stickerX +
          (stickerConfig.widthMm *
              transform.anchorX *
              (1.0 - transform.scaleX)) +
          transform.offsetX;
      final calStickerY =
          stickerY +
          (stickerConfig.heightMm *
              transform.anchorY *
              (1.0 - transform.scaleY)) +
          transform.offsetY;

      final left = calStickerX + (stickerMinX * transform.scaleX);
      final right = calStickerX + (stickerMaxX * transform.scaleX);
      final top = calStickerY + (stickerMinY * transform.scaleY);
      final bottom = calStickerY + (stickerMaxY * transform.scaleY);

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
    final leftConflict = analysisResult.conflicts.firstWhereOrNull(
      (c) => c.affectedEdge == EdgeGroup.left,
    );
    final rightConflict = analysisResult.conflicts.firstWhereOrNull(
      (c) => c.affectedEdge == EdgeGroup.right,
    );
    final topConflict = analysisResult.conflicts.firstWhereOrNull(
      (c) => c.affectedEdge == EdgeGroup.top,
    );
    final bottomConflict = analysisResult.conflicts.firstWhereOrNull(
      (c) => c.affectedEdge == EdgeGroup.bottom,
    );

    Log.debug(
      'TransformGenerator: conflicts — left=${leftConflict?.overlapMm}mm, '
      'right=${rightConflict?.overlapMm}mm, '
      'top=${topConflict?.overlapMm}mm, '
      'bottom=${bottomConflict?.overlapMm}mm. '
      'Printer margins: L=$printerMarginLeft R=$printerMarginRight T=$printerMarginTop B=$printerMarginBottom. '
      'Printer space: $printerWidth×${printerHeight}mm. '
      'Rotation: ${isRotated90 ? "90°" : "none"}. '
      'Sticker printable area: $printableWidth×${printableHeight}mm '
      '(min=($stickerMinX,$stickerMinY), max=($stickerMaxX,$stickerMaxY)).',
      tag: 'PrintPipeline',
    );

    // Returns the four adjacent sticker positions (if they exist)
    List<({int r, int c})> getNeighbors(int row, int col) {
      final neighbors = <({int r, int c})>[];
      if (col > 0) neighbors.add((r: row, c: col - 1));
      if (col < totalColumns - 1) neighbors.add((r: row, c: col + 1));
      if (row > 0) neighbors.add((r: row - 1, c: col));
      if (row < totalRows - 1) neighbors.add((r: row + 1, c: col));
      return neighbors;
    }

    // 2. Level 2 — Global Translation
    if (preferences.allowTranslation) {
      final hasLeftAndRight = leftConflict != null && rightConflict != null;
      final hasTopAndBottom = topConflict != null && bottomConflict != null;

      if (!hasLeftAndRight && !hasTopAndBottom) {
        // When rotated 90°, printer Left/Right map to template Y (dy)
        // and printer Top/Bottom map to template X (dx).
        final candidateOffsetX = isRotated90
            ? (topConflict != null
                ? topConflict.overlapMm
                : (bottomConflict != null ? -bottomConflict.overlapMm : 0.0))
            : (leftConflict != null
                ? leftConflict.overlapMm
                : (rightConflict != null ? -rightConflict.overlapMm : 0.0));

        final candidateOffsetY = isRotated90
            ? (leftConflict != null
                ? leftConflict.overlapMm
                : (rightConflict != null ? -rightConflict.overlapMm : 0.0))
            : (topConflict != null
                ? topConflict.overlapMm
                : (bottomConflict != null ? -bottomConflict.overlapMm : 0.0));

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
            );
          }
          return OptimizationStrategy(
            level: OptimizationLevel.globalTransform,
            description:
                'Global translation applied: dx = ${candidateOffsetX.toStringAsFixed(2)} mm, dy = ${candidateOffsetY.toStringAsFixed(2)} mm.',
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

    final leftGroupShift = hasLeft ? leftConflict.overlapMm : 0.0;
    final rightGroupShift = hasRight ? -rightConflict.overlapMm : 0.0;
    final topGroupShift = hasTop ? topConflict.overlapMm : 0.0;
    final bottomGroupShift = hasBottom ? -bottomConflict.overlapMm : 0.0;

    if (preferences.allowTranslation) {
      // Simulate left group translation
      if (hasLeft) {
        var leftSafe = true;
        for (final absIndex in leftConflict.affectedStickerIndices) {
          final r = absIndex ~/ totalColumns;
          final c = absIndex % totalColumns;
          final bounds = getBounds(r, c);
          if (bounds['right']! + leftGroupShift >
              printerWidth - printerMarginRight) {
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
          if (bounds['bottom']! + topGroupShift >
              printerHeight - printerMarginBottom) {
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

          final inLeft =
              leftConflict?.affectedStickerIndices.contains(absIndex) ?? false;
          final inRight =
              rightConflict?.affectedStickerIndices.contains(absIndex) ?? false;
          final inTop =
              topConflict?.affectedStickerIndices.contains(absIndex) ?? false;
          final inBottom =
              bottomConflict?.affectedStickerIndices.contains(absIndex) ??
              false;

          // When rotated 90°, printer Left/Right map to template Y (dy)
          // and printer Top/Bottom map to template X (dx).
          final dx = isRotated90
              ? ((inTop && !unresolvedTop)
                  ? topGroupShift
                  : ((inBottom && !unresolvedBottom) ? bottomGroupShift : 0.0))
              : ((inLeft && !unresolvedLeft)
                  ? leftGroupShift
                  : ((inRight && !unresolvedRight) ? rightGroupShift : 0.0));

          final dy = isRotated90
              ? ((inLeft && !unresolvedLeft)
                  ? leftGroupShift
                  : ((inRight && !unresolvedRight) ? rightGroupShift : 0.0))
              : ((inTop && !unresolvedTop)
                  ? topGroupShift
                  : ((inBottom && !unresolvedBottom) ? bottomGroupShift : 0.0));

          if (dx != 0.0 || dy != 0.0) {
            transforms[absIndex] = PrintStickerTransform(
              offsetX: dx,
              offsetY: dy,
              anchorX: 0,
              anchorY: 0,
            );
          }
        }
      }

      // If all conflicting groups were resolved by translation
      if (!unresolvedLeft &&
          !unresolvedRight &&
          !unresolvedTop &&
          !unresolvedBottom) {
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
        description:
            'Scaling is disabled by preferences. Cannot resolve conflicts.',
        transforms: const {},
      );
    }

    // 4a — Compute available space (guard: escalate to Level 6 if <= 0)
    final availablePrinterWidth =
        printerWidth - printerMarginLeft - printerMarginRight;
    final availablePrinterHeight =
        printerHeight - printerMarginTop - printerMarginBottom;

    if (availablePrinterWidth <= 0 || availablePrinterHeight <= 0) {
      return OptimizationStrategy(
        level: OptimizationLevel.unsupported,
        description:
            'Available print region width or height is zero or negative due to margins.',
        transforms: const {},
      );
    }

    // 4b — Compute scale values
    final requiresScaleX = unresolvedLeft || unresolvedRight;
    final requiresScaleY = unresolvedTop || unresolvedBottom;

    Log.debug(
      'TransformGenerator: Level 4 — unresolved: left=$unresolvedLeft right=$unresolvedRight '
      'top=$unresolvedTop bottom=$unresolvedBottom. '
      'requiresScaleX=$requiresScaleX requiresScaleY=$requiresScaleY.',
      tag: 'PrintPipeline',
    );

    final calForSlot0 = calForSlot(0, 0, 0);
    final calScaleX = calForSlot0.scaleX;
    final calScaleY = calForSlot0.scaleY;

    final totalContentWidth =
        sheetConfig.marginLeft +
        totalColumns * stickerConfig.widthMm +
        (totalColumns - 1) * sheetConfig.columnGap +
        sheetConfig.marginRight;
    final totalContentHeight =
        sheetConfig.marginTop +
        totalRows * stickerConfig.heightMm +
        (totalRows - 1) * sheetConfig.rowGap +
        sheetConfig.marginBottom;

    final scaleX = requiresScaleX
        ? (availablePrinterWidth / totalContentWidth) / calScaleX
        : 1.0;
    final scaleY = requiresScaleY
        ? (availablePrinterHeight / totalContentHeight) / calScaleY
        : 1.0;

    Log.debug(
      'TransformGenerator: Level 4 scale calculation — '
      'totalContentWidth=${totalContentWidth.toStringAsFixed(1)}mm, '
      'totalContentHeight=${totalContentHeight.toStringAsFixed(1)}mm, '
      'availablePrinterWidth=${availablePrinterWidth.toStringAsFixed(1)}mm, '
      'availablePrinterHeight=${availablePrinterHeight.toStringAsFixed(1)}mm, '
      'calScaleX=${calScaleX.toStringAsFixed(5)}, calScaleY=${calScaleY.toStringAsFixed(5)}, '
      'computedScaleX=${scaleX.toStringAsFixed(5)}, computedScaleY=${scaleY.toStringAsFixed(5)}.',
      tag: 'PrintPipeline',
    );
    final anchorX =
        (printerMarginLeft + availablePrinterWidth / 2) / printerWidth;
    final anchorY =
        (printerMarginTop + availablePrinterHeight / 2) / printerHeight;

    // 4f — Gate check: scale vs minimumAcceptableScale
    final composedScaleX = availablePrinterWidth / totalContentWidth;
    if (requiresScaleX && composedScaleX < preferences.minimumAcceptableScale) {
      Log.warning(
        'TransformGenerator: Level 6 — X-axis unsupported. '
        'composedScaleX=$composedScaleX < minAcceptable=${preferences.minimumAcceptableScale}. '
        'availWidth=$availablePrinterWidth / totalContentWidth=$totalContentWidth.',
        tag: 'PrintPipeline',
      );
      return OptimizationStrategy(
        level: OptimizationLevel.unsupported,
        description:
            'Template/printer combination unsupported: required X-axis compression '
            '(scaleX = ${composedScaleX.toStringAsFixed(2)}) falls below the minimum '
            'acceptable scale (${preferences.minimumAcceptableScale}). Sticker '
            'printable region width ${printableWidth.toStringAsFixed(1)} mm cannot be adequately '
            'reproduced in available printer width ${availablePrinterWidth.toStringAsFixed(1)} mm.',
        transforms: const {},
      );
    }

    final composedScaleY = availablePrinterHeight / totalContentHeight;
    if (requiresScaleY && composedScaleY < preferences.minimumAcceptableScale) {
      Log.warning(
        'TransformGenerator: Level 6 — Y-axis unsupported. '
        'composedScaleY=$composedScaleY < minAcceptable=${preferences.minimumAcceptableScale}. '
        'availHeight=$availablePrinterHeight / totalContentHeight=$totalContentHeight.',
        tag: 'PrintPipeline',
      );
      return OptimizationStrategy(
        level: OptimizationLevel.unsupported,
        description:
            'Template/printer combination unsupported: required Y-axis compression '
            '(scaleY = ${composedScaleY.toStringAsFixed(2)}) falls below the minimum '
            'acceptable scale (${preferences.minimumAcceptableScale}). Sticker '
            'printable region height ${printableHeight.toStringAsFixed(1)} mm cannot be adequately '
            'reproduced in available printer height ${availablePrinterHeight.toStringAsFixed(1)} mm.',
        transforms: const {},
      );
    }

    // 4d — Build per-sticker transforms
    const composer = CalibrationTransformComposer();
    final finalTransforms = <int, PrintStickerTransform>{};

    for (var r = 0; r < totalRows; r++) {
      for (var c = 0; c < totalColumns; c++) {
        final absIndex = r * totalColumns + c;

        final inLeft =
            leftConflict?.affectedStickerIndices.contains(absIndex) ?? false;
        final inRight =
            rightConflict?.affectedStickerIndices.contains(absIndex) ?? false;
        final inTop =
            topConflict?.affectedStickerIndices.contains(absIndex) ?? false;
        final inBottom =
            bottomConflict?.affectedStickerIndices.contains(absIndex) ?? false;

        final sX = (inLeft && unresolvedLeft) || (inRight && unresolvedRight)
            ? scaleX
            : 1.0;
        final sY = (inTop && unresolvedTop) || (inBottom && unresolvedBottom)
            ? scaleY
            : 1.0;

        final aX = sX != 1.0 ? anchorX : 0.5;
        final aY = sY != 1.0 ? anchorY : 0.5;

        final level4Transform = PrintStickerTransform(
          scaleX: sX,
          scaleY: sY,
          anchorX: aX,
          anchorY: aY,
        );

        final level3Transform = transforms[absIndex];

        if (level3Transform != null) {
          finalTransforms[absIndex] = composer.composeTwo(
            level3Transform,
            level4Transform,
          );
        } else if (!level4Transform.isIdentity) {
          finalTransforms[absIndex] = level4Transform;
        }
      }
    }

    // 5. Level 5 — Individual Sticker Optimization
    // Check each sticker after Level 3+4 composition for remaining margin conflicts.
    // Only stickers whose composed transform still leaves them outside margins
    // are individually corrected (not all stickers).
    final stillConflicting = <int>{};

    Map<String, double> projectBounds(
      int r,
      int c,
      PrintStickerTransform transform,
    ) {
      final stickerX =
          sheetConfig.marginLeft +
          c * (stickerConfig.widthMm + sheetConfig.columnGap);
      final stickerY =
          sheetConfig.marginTop +
          r * (stickerConfig.heightMm + sheetConfig.rowGap);

      final calStickerX =
          stickerX +
          (stickerConfig.widthMm *
              transform.anchorX *
              (1.0 - transform.scaleX)) +
          transform.offsetX;
      final calStickerY =
          stickerY +
          (stickerConfig.heightMm *
              transform.anchorY *
              (1.0 - transform.scaleY)) +
          transform.offsetY;

      final left = calStickerX + (stickerMinX * transform.scaleX);
      final right = calStickerX + (stickerMaxX * transform.scaleX);
      final top = calStickerY + (stickerMinY * transform.scaleY);
      final bottom = calStickerY + (stickerMaxY * transform.scaleY);

      if (isRotated90) {
        return {
          'left': sheetConfig.pageHeight - bottom,
          'right': sheetConfig.pageHeight - top,
          'top': left,
          'bottom': right,
        };
      }
      return {'left': left, 'right': right, 'top': top, 'bottom': bottom};
    }

    for (var r = 0; r < totalRows; r++) {
      for (var c = 0; c < totalColumns; c++) {
        final absIndex = r * totalColumns + c;
        final ct = calForSlot(r, c, absIndex);
        final optimizationTransform =
            finalTransforms[absIndex] ?? const PrintStickerTransform.identity();
        final fullTransform = composer.composeTwo(
          ct,
          optimizationTransform,
        );
        final bounds = projectBounds(r, c, fullTransform);

        if (bounds['left']! < printerMarginLeft ||
            bounds['right']! > (printerWidth - printerMarginRight) ||
            bounds['top']! < printerMarginTop ||
            bounds['bottom']! > (printerHeight - printerMarginBottom)) {
          stillConflicting.add(absIndex);
        }
      }
    }

    if (stillConflicting.isNotEmpty) {
      Log.debug(
        'TransformGenerator: Level 5 — ${stillConflicting.length} sticker(s) still '
        'conflict after Level 4. Applying individual corrections...',
        tag: 'PrintPipeline',
      );

      var level6Escalation = false;
      final level5Transforms = Map<int, PrintStickerTransform>.from(
        finalTransforms,
      );

      Map<String, double> getFullBounds(int r, int c) {
        final ct = calForSlot(r, c, r * totalColumns + c);
        final ot =
            finalTransforms[r * totalColumns + c] ??
            const PrintStickerTransform.identity();
        return projectBounds(r, c, composer.composeTwo(ct, ot));
      }

      for (final absIndex in stillConflicting) {
        final r = absIndex ~/ totalColumns;
        final c = absIndex % totalColumns;
        final ct = calForSlot(r, c, absIndex);
        final existingOptimization =
            finalTransforms[absIndex] ?? const PrintStickerTransform.identity();
        final existingFull = composer.composeTwo(
          ct,
          existingOptimization,
        );
        final bounds = projectBounds(r, c, existingFull);

        // 5a — Try per-sticker translation
        double dx = 0;
        double dy = 0;
        if (bounds['left']! < printerMarginLeft) {
          dx = printerMarginLeft - bounds['left']!;
        } else if (bounds['right']! > (printerWidth - printerMarginRight)) {
          dx = (printerWidth - printerMarginRight) - bounds['right']!;
        }
        if (bounds['top']! < printerMarginTop) {
          dy = printerMarginTop - bounds['top']!;
        } else if (bounds['bottom']! > (printerHeight - printerMarginBottom)) {
          dy = (printerHeight - printerMarginBottom) - bounds['bottom']!;
        }

        final offsetTransform = PrintStickerTransform(offsetX: dx, offsetY: dy);
        final withOffset = composer.composeTwo(existingFull, offsetTransform);
        final offsetBounds = projectBounds(r, c, withOffset);

        // Check that offset doesn't cause overlap with adjacent stickers
        var offsetCausesOverlap = false;
        if (dx != 0 || dy != 0) {
          for (final neighbor in getNeighbors(r, c)) {
            final nb = getFullBounds(neighbor.r, neighbor.c);
            final hOverlap =
                offsetBounds['left']! < nb['right']! &&
                offsetBounds['right']! > nb['left']!;
            final vOverlap =
                offsetBounds['top']! < nb['bottom']! &&
                offsetBounds['bottom']! > nb['top']!;
            if (hOverlap && vOverlap) {
              offsetCausesOverlap = true;
              Log.debug(
                '  Sticker $absIndex: offset (dx=$dx, dy=$dy) would overlap '
                'neighbor (${neighbor.r},${neighbor.c}). Falling back to scaling.',
                tag: 'PrintPipeline',
              );
              break;
            }
          }
        }

        if (!offsetCausesOverlap &&
            offsetBounds['left']! >= printerMarginLeft &&
            offsetBounds['right']! <= (printerWidth - printerMarginRight) &&
            offsetBounds['top']! >= printerMarginTop &&
            offsetBounds['bottom']! <= (printerHeight - printerMarginBottom)) {
          final correctionTransform = composer.composeTwo(
            existingOptimization,
            offsetTransform,
          );
          final optimizationTransformWithCorrection =
              correctionTransform.isIdentity ? null : correctionTransform;
          if (optimizationTransformWithCorrection != null) {
            level5Transforms[absIndex] = correctionTransform;
          }
          Log.debug(
            '  Sticker $absIndex: individual offset (dx=${dx.toStringAsFixed(2)}, '
            'dy=${dy.toStringAsFixed(2)}) resolved remaining conflict.',
            tag: 'PrintPipeline',
          );
          continue;
        }

        // 5b — Offset didn't work, try per-sticker scaling
        final currentPrintWidth = bounds['right']! - bounds['left']!;
        final currentPrintHeight = bounds['bottom']! - bounds['top']!;
        final availableW =
            printerWidth - printerMarginRight - printerMarginLeft;
        final availableH =
            printerHeight - printerMarginBottom - printerMarginTop;

        final sX = currentPrintWidth > 0 ? availableW / currentPrintWidth : 1.0;
        final sY = currentPrintHeight > 0
            ? availableH / currentPrintHeight
            : 1.0;

        final appliedSX =
            (bounds['left']! < printerMarginLeft ||
                bounds['right']! > (printerWidth - printerMarginRight))
            ? sX
            : 1.0;
        final appliedSY =
            (bounds['top']! < printerMarginTop ||
                bounds['bottom']! > (printerHeight - printerMarginBottom))
            ? sY
            : 1.0;

        if (appliedSX < preferences.minimumAcceptableScale ||
            appliedSY < preferences.minimumAcceptableScale) {
          Log.warning(
            '  Sticker $absIndex: individual scale (sx=${appliedSX.toStringAsFixed(3)}, '
            'sy=${appliedSY.toStringAsFixed(3)}) below minimum '
            '${preferences.minimumAcceptableScale}. Escalating to Level 6.',
            tag: 'PrintPipeline',
          );
          level6Escalation = true;
          break;
        }

        final scaleTransform = PrintStickerTransform(
          scaleX: appliedSX,
          scaleY: appliedSY,
          anchorX: (printerMarginLeft + availableW / 2) / printerWidth,
          anchorY: (printerMarginTop + availableH / 2) / printerHeight,
        );
        final withScale = composer.composeTwo(existingFull, scaleTransform);
        final scaleBounds = projectBounds(r, c, withScale);

        if (scaleBounds['left']! >= printerMarginLeft &&
            scaleBounds['right']! <= (printerWidth - printerMarginRight) &&
            scaleBounds['top']! >= printerMarginTop &&
            scaleBounds['bottom']! <= (printerHeight - printerMarginBottom)) {
          final correction = composer.composeTwo(
            existingOptimization,
            scaleTransform,
          );
          level5Transforms[absIndex] = correction;
          Log.debug(
            '  Sticker $absIndex: individual scale (sx=${appliedSX.toStringAsFixed(3)}, '
            'sy=${appliedSY.toStringAsFixed(3)}) resolved remaining conflict.',
            tag: 'PrintPipeline',
          );
        } else {
          Log.warning(
            '  Sticker $absIndex: individual scale (sx=${appliedSX.toStringAsFixed(3)}, '
            'sy=${appliedSY.toStringAsFixed(3)}) still leaves conflicts. Escalating to Level 6.',
            tag: 'PrintPipeline',
          );
          level6Escalation = true;
          break;
        }
      }

      if (level6Escalation) {
        return OptimizationStrategy(
          level: OptimizationLevel.unsupported,
          description:
              'Individual sticker optimization failed: '
              'required correction below minimum acceptable threshold.',
          transforms: const {},
        );
      }

      Log.info(
        'TransformGenerator: Level 5 — individual corrections applied for '
        '${stillConflicting.length} sticker(s).',
        tag: 'PrintPipeline',
      );

      return OptimizationStrategy(
        level: OptimizationLevel.individualSticker,
        description:
            'Individual sticker optimization applied for ${stillConflicting.length} unresolved sticker(s).',
        transforms: level5Transforms,
      );
    }

    return OptimizationStrategy(
      level: OptimizationLevel.edgeGroupScaling,
      description: 'Edge group scaling applied to resolve conflicts.',
      transforms: finalTransforms,
    );
  }
}
