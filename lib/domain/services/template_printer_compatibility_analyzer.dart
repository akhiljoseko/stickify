import 'dart:math' as math;
import 'package:stickify/domain/entities/calibration_rule.dart';
import 'package:stickify/domain/entities/compatibility_analysis_result.dart';
import 'package:stickify/domain/entities/label_template.dart';
import 'package:stickify/domain/entities/optimization_level.dart';
import 'package:stickify/domain/entities/print_region_conflict.dart';
import 'package:stickify/domain/entities/printer_profile.dart';
import 'package:stickify/domain/entities/printer_tray_profile.dart';
import 'package:stickify/domain/entities/sheet_config.dart';
import 'package:stickify/domain/entities/sticker_config.dart';

/// Service responsible for analyzing a label template against a printer profile
/// to detect physical printable region conflicts and recommend optimization strategies.
class TemplatePrinterCompatibilityAnalyzer {
  /// Creates a [TemplatePrinterCompatibilityAnalyzer] instance.
  const TemplatePrinterCompatibilityAnalyzer();

  /// Analyzes the given template, printer profile, and tray to identify print conflicts.
  CompatibilityAnalysisResult analyze({
    required LabelTemplate template,
    required PrinterProfile printer,
    required PrinterTrayProfile tray,
  }) {
    final sheetConfig = template.sheetConfig;
    final stickerConfig = template.stickerConfig;

    if (sheetConfig == null || stickerConfig == null) {
      return CompatibilityAnalysisResult(
        conflicts: const [],
        recommendedOptimizationLevel: OptimizationLevel.noModification,
      );
    }

    // Step 1 — Resolve media orientation mapping.
    final templateIsPortrait = sheetConfig.pageWidth < sheetConfig.pageHeight;
    final printerSupportsPortrait = printer.capabilities.supportsPortraitCustomPaper;
    final printerSupportsLandscape = printer.capabilities.supportsLandscapeCustomPaper;

    final bool isRotated90;
    if (templateIsPortrait) {
      if (printerSupportsPortrait) {
        isRotated90 = false;
      } else if (printerSupportsLandscape) {
        isRotated90 = true;
      } else {
        // Fallback to identity but report unsupported if capabilities are completely empty
        isRotated90 = false;
      }
    } else {
      if (printerSupportsLandscape) {
        isRotated90 = false;
      } else {
        // Landscape template on a portrait-only printer is unsupported
        return CompatibilityAnalysisResult(
          conflicts: [
            PrintRegionConflict(
              affectedEdge: EdgeGroup.left,
              overlapMm: 999.0, // arbitrary indicator of failure
              affectedStickerIndices: List.generate(
                sheetConfig.columns * sheetConfig.rows,
                (i) => i,
              ),
            ),
          ],
          recommendedOptimizationLevel: OptimizationLevel.unsupported,
        );
      }
    }

    // Page dimensions in printer coordinate space
    final double printerWidth = isRotated90 ? sheetConfig.pageHeight : sheetConfig.pageWidth;
    final double printerHeight = isRotated90 ? sheetConfig.pageWidth : sheetConfig.pageHeight;

    // Step 3 — Retrieve printer non-printable margins
    final printerMarginLeft = printer.capabilities.nonPrintableMarginLeft;
    final printerMarginRight = printer.capabilities.nonPrintableMarginRight;
    final printerMarginTop = printer.capabilities.nonPrintableMarginTop;
    final printerMarginBottom = printer.capabilities.nonPrintableMarginBottom;

    // Step 2 & 4 — Project sticker printable regions and detect conflicts
    final leftStickers = <int>[];
    final rightStickers = <int>[];
    final topStickers = <int>[];
    final bottomStickers = <int>[];

    double maxLeftOverlap = 0.0;
    double maxRightOverlap = 0.0;
    double maxTopOverlap = 0.0;
    double maxBottomOverlap = 0.0;

    final totalColumns = sheetConfig.columns;
    final totalRows = sheetConfig.rows;

    // Determine the bounding box of the sticker printable region relative to the sticker itself.
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

    final double printableWidth = stickerMaxX - stickerMinX;
    final double printableHeight = stickerMaxY - stickerMinY;

    for (var r = 0; r < totalRows; r++) {
      for (var c = 0; c < totalColumns; c++) {
        final absIndex = r * totalColumns + c;

        // Position of the sticker on the sheet in template coordinate space
        final double stickerX = sheetConfig.marginLeft + c * (stickerConfig.widthMm + sheetConfig.columnGap);
        final double stickerY = sheetConfig.marginTop + r * (stickerConfig.heightMm + sheetConfig.rowGap);

        final double left = stickerX + stickerMinX;
        final double right = stickerX + stickerMaxX;
        final double top = stickerY + stickerMinY;
        final double bottom = stickerY + stickerMaxY;

        // Project to printer coordinate space
        final double pLeft;
        final double pRight;
        final double pTop;
        final double pBottom;

        if (isRotated90) {
          pLeft = sheetConfig.pageHeight - bottom;
          pRight = sheetConfig.pageHeight - top;
          pTop = left;
          pBottom = right;
        } else {
          pLeft = left;
          pRight = right;
          pTop = top;
          pBottom = bottom;
        }

        // Detect conflicts against printer margins
        if (pLeft < printerMarginLeft) {
          leftStickers.add(absIndex);
          maxLeftOverlap = math.max(maxLeftOverlap, printerMarginLeft - pLeft);
        }
        if (pRight > (printerWidth - printerMarginRight)) {
          rightStickers.add(absIndex);
          maxRightOverlap = math.max(maxRightOverlap, pRight - (printerWidth - printerMarginRight));
        }
        if (pTop < printerMarginTop) {
          topStickers.add(absIndex);
          maxTopOverlap = math.max(maxTopOverlap, printerMarginTop - pTop);
        }
        if (pBottom > (printerHeight - printerMarginBottom)) {
          bottomStickers.add(absIndex);
          maxBottomOverlap = math.max(maxBottomOverlap, pBottom - (printerHeight - printerMarginBottom));
        }
      }
    }

    final conflicts = <PrintRegionConflict>[];
    if (leftStickers.isNotEmpty) {
      conflicts.add(PrintRegionConflict(
        affectedEdge: EdgeGroup.left,
        overlapMm: maxLeftOverlap,
        affectedStickerIndices: leftStickers,
      ));
    }
    if (rightStickers.isNotEmpty) {
      conflicts.add(PrintRegionConflict(
        affectedEdge: EdgeGroup.right,
        overlapMm: maxRightOverlap,
        affectedStickerIndices: rightStickers,
      ));
    }
    if (topStickers.isNotEmpty) {
      conflicts.add(PrintRegionConflict(
        affectedEdge: EdgeGroup.top,
        overlapMm: maxTopOverlap,
        affectedStickerIndices: topStickers,
      ));
    }
    if (bottomStickers.isNotEmpty) {
      conflicts.add(PrintRegionConflict(
        affectedEdge: EdgeGroup.bottom,
        overlapMm: maxBottomOverlap,
        affectedStickerIndices: bottomStickers,
      ));
    }

    if (conflicts.isEmpty) {
      return CompatibilityAnalysisResult(
        conflicts: const [],
        recommendedOptimizationLevel: OptimizationLevel.noModification,
      );
    }

    // Step 5 — Determine recommendedOptimizationLevel.
    // Level 2: Try global translation
    final bool hasLeft = leftStickers.isNotEmpty;
    final bool hasRight = rightStickers.isNotEmpty;
    final bool hasTop = topStickers.isNotEmpty;
    final bool hasBottom = bottomStickers.isNotEmpty;

    if (!(hasLeft && hasRight) && !(hasTop && hasBottom)) {
      // Simulate global shift
      final double shiftX = hasLeft ? maxLeftOverlap : (hasRight ? -maxRightOverlap : 0.0);
      final double shiftY = hasTop ? maxTopOverlap : (hasBottom ? -maxBottomOverlap : 0.0);

      var globalShiftSucceeds = true;

      for (var r = 0; r < totalRows; r++) {
        for (var c = 0; c < totalColumns; c++) {
          final double stickerX = sheetConfig.marginLeft + c * (stickerConfig.widthMm + sheetConfig.columnGap);
          final double stickerY = sheetConfig.marginTop + r * (stickerConfig.heightMm + sheetConfig.rowGap);

          final double left = stickerX + stickerMinX;
          final double right = stickerX + stickerMaxX;
          final double top = stickerY + stickerMinY;
          final double bottom = stickerY + stickerMaxY;

          final double pLeft = isRotated90 ? sheetConfig.pageHeight - bottom : left;
          final double pRight = isRotated90 ? sheetConfig.pageHeight - top : right;
          final double pTop = isRotated90 ? left : top;
          final double pBottom = isRotated90 ? right : bottom;

          final simLeft = pLeft + shiftX;
          final simRight = pRight + shiftX;
          final simTop = pTop + shiftY;
          final simBottom = pBottom + shiftY;

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
        return CompatibilityAnalysisResult(
          conflicts: conflicts,
          recommendedOptimizationLevel: OptimizationLevel.globalTransform,
        );
      }
    }

    // Level 3: Edge Group Translation
    // Since columns/rows are shifted independently, check if shifting resolved groups succeeds.
    // A group fails Level 3 translation if a sticker belongs to a conflicting edge and the translation required
    // would push it into the opposite margin. Since the opposite edge of the same sticker is within the same column/row,
    // this is equivalent to checking if the sticker's own width (or height) is greater than the available width (or height) between the left and right (or top and bottom) margins.
    final availableWidth = printerWidth - printerMarginLeft - printerMarginRight;
    final availableHeight = printerHeight - printerMarginTop - printerMarginBottom;

    if (availableWidth <= 0 || availableHeight <= 0) {
      return CompatibilityAnalysisResult(
        conflicts: conflicts,
        recommendedOptimizationLevel: OptimizationLevel.unsupported,
      );
    }

    // Check if any sticker's printable region width/height exceeds available space.
    if (printableWidth > availableWidth || printableHeight > availableHeight) {
      return CompatibilityAnalysisResult(
        conflicts: conflicts,
        recommendedOptimizationLevel: OptimizationLevel.unsupported,
      );
    }

    // Level 3 translation checks:
    // For a group to fail Level 3 translation, translating it must create a conflict on the opposite edge.
    // For example, if a sticker is in the left group (conflicts left), and shifting it right by (leftMargin - pLeft)
    // causes its right edge (pRight + shift) to exceed (printerWidth - rightMargin).
    // This is mathematically: (leftMargin - pLeft) + pRight > printerWidth - rightMargin
    // which simplifies to: pRight - pLeft > printerWidth - leftMargin - rightMargin
    // which is: printableWidth > availableWidth.
    // Since we already checked `printableWidth > availableWidth` and `printableHeight > availableHeight`,
    // is it possible that Level 3 succeeds?
    // Wait! Let's check: if we shift only a single group, does it cause conflicts for other stickers?
    // Since each group is shifted independently, group members are shifted by the worst-offending overlap.
    // For the Left Group, all stickers with `pLeft < leftMargin` are shifted right by `requiredShiftX = max(leftMargin - pLeft)`.
    // If we shift them, we must check if any shifted sticker now conflicts on the right:
    // `pRight + requiredShiftX > printerWidth - rightMargin`.
    // Since `requiredShiftX = leftMargin - min(pLeft)`, the condition becomes:
    // `pRight + leftMargin - min(pLeft) > printerWidth - rightMargin`, or:
    // `pRight - min(pLeft) > printerWidth - leftMargin - rightMargin`.
    // This is possible if different stickers in the same column have different left/right margins, but since all stickers have the same width/layout,
    // normally it's identical.
    // Let's implement the exact simulation of Level 3 translation:
    // 1. Identify left, right, top, bottom group stickers.
    // 2. Compute group shifts.
    // 3. For each group, check if its translation is safe.
    // If all conflicting groups are safe under Level 3, then recommend `edgeGroupTranslation`.
    // Else, proceed to Level 4 (scaling).

    var leftGroupSafe = true;
    if (hasLeft) {
      final requiredShiftX = maxLeftOverlap;
      for (final absIndex in leftStickers) {
        final r = absIndex ~/ totalColumns;
        final c = absIndex % totalColumns;
        final double stickerX = sheetConfig.marginLeft + c * (stickerConfig.widthMm + sheetConfig.columnGap);
        final double right = stickerX + stickerMaxX;
        final double pRight = isRotated90 ? sheetConfig.pageHeight - (stickerYFor(r, sheetConfig, stickerConfig) + stickerMinY) : right;
        if (pRight + requiredShiftX > printerWidth - printerMarginRight) {
          leftGroupSafe = false;
          break;
        }
      }
    }

    var rightGroupSafe = true;
    if (hasRight) {
      final requiredShiftX = -maxRightOverlap;
      for (final absIndex in rightStickers) {
        final r = absIndex ~/ totalColumns;
        final c = absIndex % totalColumns;
        final double stickerX = sheetConfig.marginLeft + c * (stickerConfig.widthMm + sheetConfig.columnGap);
        final double left = stickerX + stickerMinX;
        final double pLeft = isRotated90 ? sheetConfig.pageHeight - (stickerYFor(r, sheetConfig, stickerConfig) + stickerMaxY) : left;
        if (pLeft + requiredShiftX < printerMarginLeft) {
          rightGroupSafe = false;
          break;
        }
      }
    }

    var topGroupSafe = true;
    if (hasTop) {
      final requiredShiftY = maxTopOverlap;
      for (final absIndex in topStickers) {
        final r = absIndex ~/ totalColumns;
        final c = absIndex % totalColumns;
        final double stickerY = sheetConfig.marginTop + r * (stickerConfig.heightMm + sheetConfig.rowGap);
        final double bottom = stickerY + stickerMaxY;
        final double pBottom = isRotated90 ? (stickerXFor(c, sheetConfig, stickerConfig) + stickerMaxX) : bottom;
        if (pBottom + requiredShiftY > printerHeight - printerMarginBottom) {
          topGroupSafe = false;
          break;
        }
      }
    }

    var bottomGroupSafe = true;
    if (hasBottom) {
      final requiredShiftY = -maxBottomOverlap;
      for (final absIndex in bottomStickers) {
        final r = absIndex ~/ totalColumns;
        final c = absIndex % totalColumns;
        final double stickerY = sheetConfig.marginTop + r * (stickerConfig.heightMm + sheetConfig.rowGap);
        final double top = stickerY + stickerMinY;
        final double pTop = isRotated90 ? (stickerXFor(c, sheetConfig, stickerConfig) + stickerMinX) : top;
        if (pTop + requiredShiftY < printerMarginTop) {
          bottomGroupSafe = false;
          break;
        }
      }
    }

    if (leftGroupSafe && rightGroupSafe && topGroupSafe && bottomGroupSafe) {
      return CompatibilityAnalysisResult(
        conflicts: conflicts,
        recommendedOptimizationLevel: OptimizationLevel.edgeGroupTranslation,
      );
    }

    // Level 4: Edge Group Scaling
    // Calculate required scales:
    var scaleX = 1.0;
    if (!leftGroupSafe || !rightGroupSafe) {
      scaleX = availableWidth / printableWidth;
    }
    var scaleY = 1.0;
    if (!topGroupSafe || !bottomGroupSafe) {
      scaleY = availableHeight / printableHeight;
    }

    final minScale = printer.optimizationPreferences.minimumAcceptableScale;
    if (scaleX >= minScale && scaleY >= minScale) {
      return CompatibilityAnalysisResult(
        conflicts: conflicts,
        recommendedOptimizationLevel: OptimizationLevel.edgeGroupScaling,
      );
    }

    return CompatibilityAnalysisResult(
      conflicts: conflicts,
      recommendedOptimizationLevel: OptimizationLevel.unsupported,
    );
  }

  // Helpers to get coordinate parts for cross-axis calculations in rotated coordinates
  double stickerXFor(int c, SheetConfig sheetConfig, StickerConfig stickerConfig) {
    return sheetConfig.marginLeft + c * (stickerConfig.widthMm + sheetConfig.columnGap);
  }

  double stickerYFor(int r, SheetConfig sheetConfig, StickerConfig stickerConfig) {
    return sheetConfig.marginTop + r * (stickerConfig.heightMm + sheetConfig.rowGap);
  }
}
