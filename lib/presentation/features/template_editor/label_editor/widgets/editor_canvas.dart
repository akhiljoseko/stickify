import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/template_editor/label_editor/bloc/editor_cubit.dart';
import 'package:stickify/presentation/features/template_editor/label_editor/widgets/canvas_element_widget.dart';
import 'package:stickify/presentation/features/template_editor/sticker_setup/widgets/polygon_painter.dart';

class EditorCanvas extends StatefulWidget {
  const EditorCanvas({
    required this.stickerConfig,
    required this.elements,
    required this.selectedElementId,
    required this.zoomLevel,
    this.product,
    super.key,
  });

  final StickerConfig stickerConfig;
  final List<ElementBlueprint> elements;
  final String? selectedElementId;
  final double zoomLevel;
  final Product? product;

  @override
  State<EditorCanvas> createState() => _EditorCanvasState();
}

class _EditorCanvasState extends State<EditorCanvas> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Convert sticker dimensions in mm to canvas logical pixels
    // Let's use 1mm = 4 logical pixels as a conversion factor
    const mmToPx = 4;
    final stickerWidth = widget.stickerConfig.widthMm * mmToPx;
    final stickerHeight = widget.stickerConfig.heightMm * mmToPx;

    final scaledWidth = stickerWidth * widget.zoomLevel;
    final scaledHeight = stickerHeight * widget.zoomLevel;

    // Deconstruct printable area to draw safe limits
    final tl = widget.stickerConfig.printableArea.isNotEmpty
        ? widget.stickerConfig.printableArea[0]
        : const StickerPoint(4, 4);
    final br = widget.stickerConfig.printableArea.length > 2
        ? widget.stickerConfig.printableArea[2]
        : StickerPoint(
            widget.stickerConfig.widthMm - 4.0,
            widget.stickerConfig.heightMm - 4.0,
          );

    final safeLeft = tl.x * mmToPx;
    final safeTop = tl.y * mmToPx;
    final safeRight = br.x * mmToPx;
    final safeBottom = br.y * mmToPx;

    // Compute alignment guide lines
    final guidelines = <Guideline>[];
    if (widget.selectedElementId != null) {
      final selectedIndex = widget.elements.indexWhere(
        (e) => e.id == widget.selectedElementId,
      );
      if (selectedIndex != -1) {
        final D = widget.elements[selectedIndex];
        final tolerance =
            3.0 /
            widget.zoomLevel; // tolerance in canvas pixels (3.0 screen pixels)

        final dl = D.x;
        final dc = D.x + D.width / 2;
        final dr = D.x + D.width;
        final dt = D.y;
        final dcenter = D.y + D.height / 2;
        final db = D.y + D.height;

        for (final E in widget.elements) {
          if (E.id == D.id) continue;

          final el = E.x;
          final ec = E.x + E.width / 2;
          final er = E.x + E.width;
          final et = E.y;
          final ecenter = E.y + E.height / 2;
          final eb = E.y + E.height;

          // Vertical alignments (matching X)
          final xMatches = [
            (dl, el, dl),
            (dl, ec, dl),
            (dl, er, dl),
            (dc, el, dc),
            (dc, ec, dc),
            (dc, er, dc),
            (dr, el, dr),
            (dr, ec, dr),
            (dr, er, dr),
          ];

          for (final match in xMatches) {
            if ((match.$1 - match.$2).abs() < tolerance) {
              final xVal = match.$3;
              final startY = D.y < E.y ? D.y : E.y;
              final endY = (D.y + D.height) > (E.y + E.height)
                  ? (D.y + D.height)
                  : (E.y + E.height);
              guidelines.add(
                Guideline(Offset(xVal, startY), Offset(xVal, endY)),
              );
            }
          }

          // Horizontal alignments (matching Y)
          final yMatches = [
            (dt, et, dt),
            (dt, ecenter, dt),
            (dt, eb, dt),
            (dcenter, et, dcenter),
            (dcenter, ecenter, dcenter),
            (dcenter, eb, dcenter),
            (db, et, db),
            (db, ecenter, db),
            (db, eb, db),
          ];

          for (final match in yMatches) {
            if ((match.$1 - match.$2).abs() < tolerance) {
              final yVal = match.$3;
              final startX = D.x < E.x ? D.x : E.x;
              final endX = (D.x + D.width) > (E.x + E.width)
                  ? (D.x + D.width)
                  : (E.x + E.width);
              guidelines.add(
                Guideline(Offset(startX, yVal), Offset(endX, yVal)),
              );
            }
          }
        }

        // Align with safe area margins
        if ((dl - safeLeft).abs() < tolerance) {
          guidelines.add(
            Guideline(Offset(dl, safeTop), Offset(dl, safeBottom)),
          );
        }
        if ((dr - safeRight).abs() < tolerance) {
          guidelines.add(
            Guideline(Offset(dr, safeTop), Offset(dr, safeBottom)),
          );
        }
        if ((dt - safeTop).abs() < tolerance) {
          guidelines.add(
            Guideline(Offset(safeLeft, dt), Offset(safeRight, dt)),
          );
        }
        if ((db - safeBottom).abs() < tolerance) {
          guidelines.add(
            Guideline(Offset(safeLeft, db), Offset(safeRight, db)),
          );
        }
      }
    }

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent || event is KeyRepeatEvent) {
          final key = event.logicalKey;
          double dx = 0;
          double dy = 0;
          if (key == LogicalKeyboardKey.arrowLeft) dx = -1.0;
          if (key == LogicalKeyboardKey.arrowRight) dx = 1.0;
          if (key == LogicalKeyboardKey.arrowUp) dy = -1.0;
          if (key == LogicalKeyboardKey.arrowDown) dy = 1.0;

          if ((dx != 0 || dy != 0) && widget.selectedElementId != null) {
            context.read<EditorCubit>().nudgeElement(
              widget.selectedElementId!,
              dx,
              dy,
            );
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: () {
          _focusNode.requestFocus();
          context.read<EditorCubit>().deselectAll();
        },
        child: ColoredBox(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          child: Stack(
            children: [
              // Grid background dots
              Positioned.fill(
                child: CustomPaint(
                  painter: _DotPatternPainter(
                    dotColor: colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.12,
                    ),
                  ),
                ),
              ),

              // Centered Canvas Board
              Center(
                child: DragTarget<ElementBlueprint>(
                  onAcceptWithDetails: (details) {
                    final renderBox = context.findRenderObject()! as RenderBox;
                    final localOffset = renderBox.globalToLocal(details.offset);

                    // Compute center of the Canvas in local coords
                    final canvasCenterOffset = Offset(
                      renderBox.size.width / 2,
                      renderBox.size.height / 2,
                    );

                    // Offset relative to the sticker board center
                    final dx = localOffset.dx - canvasCenterOffset.dx;
                    final dy = localOffset.dy - canvasCenterOffset.dy;

                    // Compute position relative to top-left of sticker board
                    final dropX =
                        (stickerWidth / 2) +
                        (dx / widget.zoomLevel) -
                        (details.data.width / 2);
                    final dropY =
                        (stickerHeight / 2) +
                        (dy / widget.zoomLevel) -
                        (details.data.height / 2);

                    // Clamp to sticker bounds
                    final finalX = dropX.clamp(
                      0.0,
                      stickerWidth - details.data.width,
                    );
                    final finalY = dropY.clamp(
                      0.0,
                      stickerHeight - details.data.height,
                    );

                    final element = details.data.copyWith(
                      x: finalX,
                      y: finalY,
                    );
                    context.read<EditorCubit>().addElement(element);
                    _focusNode.requestFocus();
                  },
                  builder: (context, candidateData, rejectedData) {
                    return Container(
                      width: scaledWidth,
                      height: scaledHeight,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                          widget.stickerConfig.cornerRadiusMm *
                              mmToPx *
                              widget.zoomLevel,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 16,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Safe Area Polygon Border
                          Positioned.fill(
                            child: CustomPaint(
                              painter: PolygonPainter(
                                points: widget.stickerConfig.printableArea,
                                scale: mmToPx * widget.zoomLevel,
                                color: Colors.red.shade300.withValues(
                                  alpha: 0.45,
                                ),
                              ),
                            ),
                          ),

                          // Canvas Elements
                          ...widget.elements.map((bp) {
                            return CanvasElementWidget(
                              blueprint: bp,
                              isSelected: bp.id == widget.selectedElementId,
                              zoomLevel: widget.zoomLevel,
                              product: widget.product,
                              onTap: () {
                                _focusNode.requestFocus();
                                context.read<EditorCubit>().selectElement(
                                  bp.id,
                                );
                              },
                            );
                          }),

                          // Alignment guides overlay
                          if (guidelines.isNotEmpty)
                            Positioned.fill(
                              child: CustomPaint(
                                painter: AlignmentGuidesPainter(
                                  guidelines: guidelines,
                                  zoomLevel: widget.zoomLevel,
                                  color: const Color(
                                    0xFFFF00FF,
                                  ), // Dashed magenta
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Guideline {
  const Guideline(this.start, this.end);
  final Offset start;
  final Offset end;
}

class AlignmentGuidesPainter extends CustomPainter {
  AlignmentGuidesPainter({
    required this.guidelines,
    required this.zoomLevel,
    required this.color,
  });
  final List<Guideline> guidelines;
  final double zoomLevel;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    for (final guide in guidelines) {
      final p1 = Offset(guide.start.dx * zoomLevel, guide.start.dy * zoomLevel);
      final p2 = Offset(guide.end.dx * zoomLevel, guide.end.dy * zoomLevel);
      _drawDashedLine(canvas, p1, p2, paint);
    }
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const dashLimit = 4.0;
    const gapLimit = 4.0;

    if (p1.dx == p2.dx) {
      // Vertical line
      final startY = p1.dy < p2.dy ? p1.dy : p2.dy;
      final endY = p1.dy < p2.dy ? p2.dy : p1.dy;
      double y = startY;
      while (y < endY) {
        final nextY = (y + dashLimit).clamp(startY, endY);
        canvas.drawLine(Offset(p1.dx, y), Offset(p1.dx, nextY), paint);
        y += dashLimit + gapLimit;
      }
    } else if (p1.dy == p2.dy) {
      // Horizontal line
      final startX = p1.dx < p2.dx ? p1.dx : p2.dx;
      final endX = p1.dx < p2.dx ? p2.dx : p1.dx;
      var x = startX;
      while (x < endX) {
        final nextX = (x + dashLimit).clamp(startX, endX);
        canvas.drawLine(Offset(x, p1.dy), Offset(nextX, p1.dy), paint);
        x += dashLimit + gapLimit;
      }
    }
  }

  @override
  bool shouldRepaint(covariant AlignmentGuidesPainter oldDelegate) {
    return oldDelegate.zoomLevel != zoomLevel ||
        oldDelegate.guidelines != guidelines;
  }
}

class _DotPatternPainter extends CustomPainter {
  const _DotPatternPainter({required this.dotColor});

  final Color dotColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    const spacing = 20.0;
    for (double x = 10; x < size.width; x += spacing) {
      for (double y = 10; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotPatternPainter oldDelegate) => false;
}
