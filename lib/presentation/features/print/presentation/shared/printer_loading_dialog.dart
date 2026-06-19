import 'dart:math' show cos, pi, sin;
import 'package:flutter/material.dart';

/// A blocking dialog indicating that the print job is in progress.
///
/// Features a custom-painted animated printer that vibrates while printing,
/// feeds out a label sheet with barcode/lines, blinks a Teal status LED,
/// and performs a "cut and drop" animation of the label in a looping sequence.
class PrinterLoadingDialog extends StatefulWidget {
  /// Creates a [PrinterLoadingDialog] instance.
  const PrinterLoadingDialog({super.key});

  @override
  State<PrinterLoadingDialog> createState() => _PrinterLoadingDialogState();
}

class _PrinterLoadingDialogState extends State<PrinterLoadingDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return PopScope(
      canPop: false,
      child: Center(
        child: Container(
          width: 300,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLowest.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return CustomPaint(
                    size: const Size(160, 160),
                    painter: PrinterPainter(
                      animationValue: _controller.value,
                      primaryColor: colorScheme.primary,
                      secondaryColor: colorScheme.secondary,
                      tertiaryColor: colorScheme.tertiary,
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Sending to Printer...',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Your label sheets are being compiled and sent. Please do not close the app.',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom painter that renders a detailed, animated printer.
class PrinterPainter extends CustomPainter {
  /// Creates a [PrinterPainter].
  PrinterPainter({
    required this.animationValue,
    required this.primaryColor,
    required this.secondaryColor,
    required this.tertiaryColor,
  });

  /// The current loop animation progress (0.0 to 1.0).
  final double animationValue;

  /// Brand colors.
  final Color primaryColor;
  final Color secondaryColor;
  final Color tertiaryColor;

  @override
  void paint(Canvas canvas, Size size) {
    final t = animationValue;
    
    // Phase boundaries: 
    // 0.0 to 0.8 => printing (vibration, paper emerging)
    // 0.8 to 1.0 => cutting/dropping (vibration stops, paper slides down and fades)
    final isPrinting = t <= 0.8;
    final printProgress = isPrinting ? (t / 0.8) : 1.0;
    final cutProgress = isPrinting ? 0.0 : ((t - 0.8) / 0.2);

    // Vibration/shake translation space (only during printing phase)
    canvas.save();
    if (isPrinting && t > 0) {
      final dx = sin(t * 2 * pi * 18) * 1.5;
      final dy = cos(t * 2 * pi * 18) * 0.5;
      canvas.translate(dx, dy);
    }

    // Paint configs
    final bodyPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;

    final lidPaint = Paint()
      ..color = secondaryColor
      ..style = PaintingStyle.fill;

    final slotPaint = Paint()
      ..color = const Color(0xFF1E262F)
      ..style = PaintingStyle.fill;

    // 1. Draw Printer Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final shadowRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.15, size.height * 0.35, size.width * 0.7, size.height * 0.4),
      const Radius.circular(16),
    );

    // 2. Draw Printer Main Body
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.15, size.height * 0.35, size.width * 0.7, size.height * 0.4),
      const Radius.circular(16),
    );

    // 3. Draw Printer Lid (Top slot accent)
    final lidRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.22, size.height * 0.27, size.width * 0.56, size.height * 0.08),
      const Radius.circular(8),
    );

    // 4. Draw Printer Exit Slot
    final slotRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.25, size.height * 0.48, size.width * 0.5, size.height * 0.04),
      const Radius.circular(2),
    );

    canvas
      ..drawRRect(shadowRect, shadowPaint)
      ..drawRRect(bodyRect, bodyPaint)
      ..drawRRect(lidRect, lidPaint)
      ..drawRRect(slotRect, slotPaint);

    // 5. Draw LED Status Light
    // Pulsing frequency based on printing vs standby
    final pulseVal = (sin(t * 2 * pi * (isPrinting ? 5 : 2)) + 1) / 2;
    final ledColor = Color.lerp(
      tertiaryColor.withValues(alpha: 0.3),
      tertiaryColor,
      pulseVal,
    )!;

    final ledPaint = Paint()
      ..color = ledColor
      ..style = PaintingStyle.fill;
    
    final ledGlowPaint = Paint()
      ..color = ledColor.withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final ledCenter = Offset(size.width * 0.32, size.height * 0.42);

    // 6. Control Panel Details (Small buttons next to LED)
    final btnPaint = Paint()
      ..color = secondaryColor.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    canvas
      ..drawCircle(ledCenter, 6, ledGlowPaint)
      ..drawCircle(ledCenter, 3.5, ledPaint)
      ..drawCircle(Offset(size.width * 0.39, size.height * 0.42), 2.5, btnPaint)
      ..drawCircle(Offset(size.width * 0.44, size.height * 0.42), 2.5, btnPaint)
      ..restore(); // Restore vibration transform

    // 7. Draw Paper Emerging/Dropping
    // We clip the paper to only appear below the slot.
    final clipRect = Rect.fromLTWH(
      size.width * 0.2,
      size.height * 0.5,
      size.width * 0.6,
      size.height * 0.45,
    );

    canvas
      ..save()
      ..clipRect(clipRect);

    final paperWidth = size.width * 0.4;
    final paperX = size.width * 0.3;
    const barcodeTop = 22.0;
    const barcodeHeight = 16.0;
    final paperMaxHeight = size.height * 0.28;

    double paperY;
    double paperHeight;
    double paperOpacity;

    if (isPrinting) {
      paperY = size.height * 0.5;
      paperHeight = paperMaxHeight * printProgress;
      paperOpacity = 1.0;
    } else {
      // Cut and drop phase: paper slides down and fades out
      paperY = size.height * 0.5 + (cutProgress * size.height * 0.22);
      paperHeight = paperMaxHeight;
      paperOpacity = (1.0 - cutProgress).clamp(0.0, 1.0);
    }

    if (paperHeight > 0) {
      // Paper base
      final paperBasePaint = Paint()
        ..color = Colors.white.withValues(alpha: paperOpacity)
        ..style = PaintingStyle.fill;

      final paperShadow = Paint()
        ..color = Colors.black.withValues(alpha: 0.08 * paperOpacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      canvas
        ..drawRect(
          Rect.fromLTWH(paperX - 1.5, paperY, paperWidth + 3, paperHeight),
          paperShadow,
        )
        ..drawRect(
          Rect.fromLTWH(paperX, paperY, paperWidth, paperHeight),
          paperBasePaint,
        );

      // Draw printed mock content
      final contentCanvasY = paperY;

      // 1. Header (bold line)
      _drawPaperElement(
        canvas,
        rect: Rect.fromLTWH(paperX + 6, contentCanvasY + 6, paperWidth * 0.4, 4),
        opacity: paperOpacity,
        color: secondaryColor.withValues(alpha: 0.8),
        paperHeight: paperHeight,
        elementRelativeY: 6,
      );

      // 2. Sub-header/details (thin line)
      _drawPaperElement(
        canvas,
        rect: Rect.fromLTWH(paperX + 6, contentCanvasY + 14, paperWidth - 12, 2),
        opacity: paperOpacity,
        color: secondaryColor.withValues(alpha: 0.5),
        paperHeight: paperHeight,
        elementRelativeY: 14,
      );

      // 3. Barcode lines
      final barcodeX = paperX + 8.0;
      final barcodeW = paperWidth - 16.0;

      if (paperHeight > barcodeTop) {
        final visibleHeight = (paperHeight - barcodeTop).clamp(0.0, barcodeHeight);
        if (visibleHeight > 0) {
          final barPaint = Paint()
            ..color = Colors.black87.withValues(alpha: paperOpacity)
            ..style = PaintingStyle.fill;

          final patterns = [2.0, 1.0, 3.0, 1.0, 2.0, 4.0, 1.0, 2.5, 1.0, 3.0];
          var currentBarX = barcodeX;
          for (var i = 0; i < patterns.length; i++) {
            final w = patterns[i];
            if (currentBarX + w <= barcodeX + barcodeW) {
              if (i.isEven) {
                canvas.drawRect(
                  Rect.fromLTWH(currentBarX, contentCanvasY + barcodeTop, w, visibleHeight),
                  barPaint,
                );
              }
            }
            currentBarX += w + 1.5;
          }
        }
      }

      // 4. Footer line
      _drawPaperElement(
        canvas,
        rect: Rect.fromLTWH(paperX + 6, contentCanvasY + 44, paperWidth * 0.6, 2),
        opacity: paperOpacity,
        color: secondaryColor.withValues(alpha: 0.5),
        paperHeight: paperHeight,
        elementRelativeY: 44,
      );
    }

    canvas.restore();
  }

  void _drawPaperElement(
    Canvas canvas, {
    required Rect rect,
    required double opacity,
    required Color color,
    required double paperHeight,
    required double elementRelativeY,
  }) {
    if (paperHeight > elementRelativeY) {
      final elementPaint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;
      final drawHeight = (paperHeight - elementRelativeY).clamp(0.0, rect.height);
      if (drawHeight > 0) {
        canvas.drawRect(
          Rect.fromLTWH(rect.left, rect.top, rect.width, drawHeight),
          elementPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant PrinterPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor ||
        oldDelegate.tertiaryColor != tertiaryColor;
  }
}
