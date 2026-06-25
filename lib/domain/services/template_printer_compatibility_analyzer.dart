import 'dart:math' as math;
import 'package:stickify/domain/entities/calibration_rule.dart';
import 'package:stickify/domain/entities/compatibility_analysis_result.dart';
import 'package:stickify/domain/entities/label_template.dart';
import 'package:stickify/domain/entities/optimization_level.dart';
import 'package:stickify/domain/entities/print_coordinate_context.dart';
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
    PrintCoordinateContext? calibrationContext,
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
    final printerSupportsPortrait =
        printer.capabilities.supportsPortraitCustomPaper;
    final printerSupportsLandscape =
        printer.capabilities.supportsLandscapeCustomPaper;

    final bool isRotated90;
    if (templateIsPortrait) {
      if (printerSupportsPortrait) {
        isRotated90 = false;
      } else if (printerSupportsLandscape) {
        // Portrait template must be rotated 90° to print on landscape-only printer
        isRotated90 = true;
      } else {
        isRotated90 = false;
      }
    } else {
      if (printerSupportsLandscape) {
        isRotated90 = false;
      } else if (printerSupportsPortrait) {
        // Landscape template must be rotated -90° to print on portrait-only printer.
        // The axis swap and mirroring is identical to the portrait→landscape case.
        isRotated90 = true;
      } else {
        isRotated90 = false;
      }
    }

    // Page dimensions in printer coordinate space
    final printerWidth = isRotated90
        ? sheetConfig.pageHeight
        : sheetConfig.pageWidth;
    final printerHeight = isRotated90
        ? sheetConfig.pageWidth
        : sheetConfig.pageHeight;

    // Step 3 — Retrieve printer non-printable margins
    final printerMarginLeft = tray.nonPrintableMarginLeft;
    final printerMarginRight = tray.nonPrintableMarginRight;
    final printerMarginTop = tray.nonPrintableMarginTop;
    final printerMarginBottom = tray.nonPrintableMarginBottom;

    // Step 2 & 4 — Project sticker printable regions and detect conflicts
    final leftStickers = <int>[];
    final rightStickers = <int>[];
    final topStickers = <int>[];
    final bottomStickers = <int>[];

    double maxLeftOverlap = 0;
    double maxRightOverlap = 0;
    double maxTopOverlap = 0;
    double maxBottomOverlap = 0;

    final totalColumns = sheetConfig.columns;
    final totalRows = sheetConfig.rows;

    // Determine the bounding box of the sticker printable region relative to the sticker itself.
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

    for (var r = 0; r < totalRows; r++) {
      for (var c = 0; c < totalColumns; c++) {
        final absIndex = r * totalColumns + c;

        final borders = _getStickerBorders(
          r: r,
          c: c,
          sheetConfig: sheetConfig,
          stickerConfig: stickerConfig,
          stickerMinX: stickerMinX,
          stickerMaxX: stickerMaxX,
          stickerMinY: stickerMinY,
          stickerMaxY: stickerMaxY,
          isRotated90: isRotated90,
          calibrationContext: calibrationContext,
        );

        final pLeft = borders.left;
        final pRight = borders.right;
        final pTop = borders.top;
        final pBottom = borders.bottom;

        // Detect conflicts against printer margins
        if (pLeft < printerMarginLeft) {
          leftStickers.add(absIndex);
          maxLeftOverlap = math.max(maxLeftOverlap, printerMarginLeft - pLeft);
        }
        if (pRight > (printerWidth - printerMarginRight)) {
          rightStickers.add(absIndex);
          maxRightOverlap = math.max(
            maxRightOverlap,
            pRight - (printerWidth - printerMarginRight),
          );
        }
        if (pTop < printerMarginTop) {
          topStickers.add(absIndex);
          maxTopOverlap = math.max(maxTopOverlap, printerMarginTop - pTop);
        }
        if (pBottom > (printerHeight - printerMarginBottom)) {
          bottomStickers.add(absIndex);
          maxBottomOverlap = math.max(
            maxBottomOverlap,
            pBottom - (printerHeight - printerMarginBottom),
          );
        }
      }
    }

    final conflicts = <PrintRegionConflict>[];
    if (leftStickers.isNotEmpty) {
      conflicts.add(
        PrintRegionConflict(
          affectedEdge: EdgeGroup.left,
          overlapMm: maxLeftOverlap,
          affectedStickerIndices: leftStickers,
        ),
      );
    }
    if (rightStickers.isNotEmpty) {
      conflicts.add(
        PrintRegionConflict(
          affectedEdge: EdgeGroup.right,
          overlapMm: maxRightOverlap,
          affectedStickerIndices: rightStickers,
        ),
      );
    }
    if (topStickers.isNotEmpty) {
      conflicts.add(
        PrintRegionConflict(
          affectedEdge: EdgeGroup.top,
          overlapMm: maxTopOverlap,
          affectedStickerIndices: topStickers,
        ),
      );
    }
    if (bottomStickers.isNotEmpty) {
      conflicts.add(
        PrintRegionConflict(
          affectedEdge: EdgeGroup.bottom,
          overlapMm: maxBottomOverlap,
          affectedStickerIndices: bottomStickers,
        ),
      );
    }

    if (conflicts.isEmpty) {
      return CompatibilityAnalysisResult(
        conflicts: const [],
        recommendedOptimizationLevel: OptimizationLevel.noModification,
      );
    }

    // Step 5 — Determine recommendedOptimizationLevel.
    // Level 2: Try global translation
    final hasLeft = leftStickers.isNotEmpty;
    final hasRight = rightStickers.isNotEmpty;
    final hasTop = topStickers.isNotEmpty;
    final hasBottom = bottomStickers.isNotEmpty;

    if (!(hasLeft && hasRight) && !(hasTop && hasBottom)) {
      // Simulate global shift
      final shiftX = hasLeft
          ? maxLeftOverlap
          : (hasRight ? -maxRightOverlap : 0.0);
      final shiftY = hasTop
          ? maxTopOverlap
          : (hasBottom ? -maxBottomOverlap : 0.0);

      var globalShiftSucceeds = true;

      for (var r = 0; r < totalRows; r++) {
        for (var c = 0; c < totalColumns; c++) {
          final borders = _getStickerBorders(
            r: r,
            c: c,
            sheetConfig: sheetConfig,
            stickerConfig: stickerConfig,
            stickerMinX: stickerMinX,
            stickerMaxX: stickerMaxX,
            stickerMinY: stickerMinY,
            stickerMaxY: stickerMaxY,
            isRotated90: isRotated90,
            calibrationContext: calibrationContext,
          );

          final simLeft = borders.left + shiftX;
          final simRight = borders.right + shiftX;
          final simTop = borders.top + shiftY;
          final simBottom = borders.bottom + shiftY;

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
    final availableWidth =
        printerWidth - printerMarginLeft - printerMarginRight;
    final availableHeight =
        printerHeight - printerMarginTop - printerMarginBottom;

    if (availableWidth <= 0 || availableHeight <= 0) {
      return CompatibilityAnalysisResult(
        conflicts: conflicts,
        recommendedOptimizationLevel: OptimizationLevel.unsupported,
      );
    }

    // Check if any sticker's printable region width/height (post-calibration) exceeds available space.
    for (var r = 0; r < totalRows; r++) {
      for (var c = 0; c < totalColumns; c++) {
        final absIndex = r * totalColumns + c;
        final transform =
            calibrationContext?.resolveFor(
              row: r,
              column: c,
              absoluteSlotIndex: absIndex,
            ) ??
            const PrintStickerTransform.identity();
        final calPrintableWidth = printableWidth * transform.scaleX;
        final calPrintableHeight = printableHeight * transform.scaleY;
        if (calPrintableWidth > availableWidth ||
            calPrintableHeight > availableHeight) {
          return CompatibilityAnalysisResult(
            conflicts: conflicts,
            recommendedOptimizationLevel: OptimizationLevel.unsupported,
          );
        }
      }
    }

    var leftGroupSafe = true;
    if (hasLeft) {
      final requiredShiftX = maxLeftOverlap;
      for (final absIndex in leftStickers) {
        final r = absIndex ~/ totalColumns;
        final c = absIndex % totalColumns;
        final borders = _getStickerBorders(
          r: r,
          c: c,
          sheetConfig: sheetConfig,
          stickerConfig: stickerConfig,
          stickerMinX: stickerMinX,
          stickerMaxX: stickerMaxX,
          stickerMinY: stickerMinY,
          stickerMaxY: stickerMaxY,
          isRotated90: isRotated90,
          calibrationContext: calibrationContext,
        );
        if (borders.right + requiredShiftX >
            printerWidth - printerMarginRight) {
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
        final borders = _getStickerBorders(
          r: r,
          c: c,
          sheetConfig: sheetConfig,
          stickerConfig: stickerConfig,
          stickerMinX: stickerMinX,
          stickerMaxX: stickerMaxX,
          stickerMinY: stickerMinY,
          stickerMaxY: stickerMaxY,
          isRotated90: isRotated90,
          calibrationContext: calibrationContext,
        );
        if (borders.left + requiredShiftX < printerMarginLeft) {
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
        final borders = _getStickerBorders(
          r: r,
          c: c,
          sheetConfig: sheetConfig,
          stickerConfig: stickerConfig,
          stickerMinX: stickerMinX,
          stickerMaxX: stickerMaxX,
          stickerMinY: stickerMinY,
          stickerMaxY: stickerMaxY,
          isRotated90: isRotated90,
          calibrationContext: calibrationContext,
        );
        if (borders.bottom + requiredShiftY >
            printerHeight - printerMarginBottom) {
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
        final borders = _getStickerBorders(
          r: r,
          c: c,
          sheetConfig: sheetConfig,
          stickerConfig: stickerConfig,
          stickerMinX: stickerMinX,
          stickerMaxX: stickerMaxX,
          stickerMinY: stickerMinY,
          stickerMaxY: stickerMaxY,
          isRotated90: isRotated90,
          calibrationContext: calibrationContext,
        );
        if (borders.top + requiredShiftY < printerMarginTop) {
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

  _StickerBorders _getStickerBorders({
    required int r,
    required int c,
    required SheetConfig sheetConfig,
    required StickerConfig stickerConfig,
    required double stickerMinX,
    required double stickerMaxX,
    required double stickerMinY,
    required double stickerMaxY,
    required bool isRotated90,
    PrintCoordinateContext? calibrationContext,
  }) {
    final stickerX =
        sheetConfig.marginLeft +
        c * (stickerConfig.widthMm + sheetConfig.columnGap);
    final stickerY =
        sheetConfig.marginTop +
        r * (stickerConfig.heightMm + sheetConfig.rowGap);

    final transform =
        calibrationContext?.resolveFor(
          row: r,
          column: c,
          absoluteSlotIndex: r * sheetConfig.columns + c,
        ) ??
        const PrintStickerTransform.identity();

    final calStickerX =
        stickerX +
        (stickerConfig.widthMm * transform.anchorX * (1.0 - transform.scaleX)) +
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
      return _StickerBorders(
        left: sheetConfig.pageHeight - bottom,
        right: sheetConfig.pageHeight - top,
        top: left,
        bottom: right,
      );
    } else {
      return _StickerBorders(
        left: left,
        right: right,
        top: top,
        bottom: bottom,
      );
    }
  }
}

class _StickerBorders {
  const _StickerBorders({
    required this.left,
    required this.right,
    required this.top,
    required this.bottom,
  });

  final double left;
  final double right;
  final double top;
  final double bottom;
}
