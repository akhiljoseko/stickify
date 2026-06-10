import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:stickify/domain/domain.dart';

class SheetPreviewGrid extends StatelessWidget {
  const SheetPreviewGrid({required this.config, super.key});

  final SheetConfig config;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Parse paper dimensions in mm
        final paperWidth = config.pageWidth;
        final paperHeight = config.pageHeight;

        // Fit page aspect ratio into container
        final containerW = constraints.maxWidth - 32;
        final containerH = constraints.maxHeight - 32;

        final scaleW = containerW / paperWidth;
        final scaleH = containerH / paperHeight;
        final scale = math.min(scaleW, scaleH);

        final drawW = paperWidth * scale;
        final drawH = paperHeight * scale;

        return Center(
          child: Container(
            width: drawW,
            height: drawH,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: CustomPaint(
              painter: _SheetPainter(
                config: config,
                paperWidth: paperWidth,
                paperHeight: paperHeight,
                scale: scale,
                gridColor: colorScheme.primary.withValues(alpha: 0.6),
                marginColor: colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SheetPainter extends CustomPainter {
  const _SheetPainter({
    required this.config,
    required this.paperWidth,
    required this.paperHeight,
    required this.scale,
    required this.gridColor,
    required this.marginColor,
  });

  final SheetConfig config;
  final double paperWidth;
  final double paperHeight;
  final double scale;
  final Color gridColor;
  final Color marginColor;

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Page Margins Guidelines
    final marginPaint = Paint()
      ..color = marginColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final marginRect = Rect.fromLTRB(
      config.marginLeft * scale,
      config.marginTop * scale,
      (paperWidth - config.marginRight) * scale,
      (paperHeight - config.marginBottom) * scale,
    );

    canvas.drawRect(marginRect, marginPaint);

    // 2. Draw Grid cells
    final columns = math.max(1, config.columns);
    final rows = math.max(1, config.rows);

    final printableW = paperWidth - config.marginLeft - config.marginRight;
    final printableH = paperHeight - config.marginTop - config.marginBottom;

    final cellW = (printableW - (columns - 1) * config.columnGap) / columns;
    final cellH = (printableH - (rows - 1) * config.rowGap) / rows;

    if (cellW <= 0 || cellH <= 0) return; // Prevent painting negative/invalid cells

    final cellPaint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (var col = 0; col < columns; col++) {
      for (var row = 0; row < rows; row++) {
        final x = (config.marginLeft + col * (cellW + config.columnGap)) * scale;
        final y = (config.marginTop + row * (cellH + config.rowGap)) * scale;

        final cellRect = Rect.fromLTWH(x, y, cellW * scale, cellH * scale);
        canvas.drawRRect(
          RRect.fromRectAndRadius(cellRect, const Radius.circular(2)),
          cellPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SheetPainter oldDelegate) {
    return oldDelegate.config != config ||
        oldDelegate.paperWidth != paperWidth ||
        oldDelegate.paperHeight != paperHeight ||
        oldDelegate.scale != scale;
  }
}
