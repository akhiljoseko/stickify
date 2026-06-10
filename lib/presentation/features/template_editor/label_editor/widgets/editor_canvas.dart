import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/template_editor/label_editor/bloc/editor_cubit.dart';
import 'package:stickify/presentation/features/template_editor/label_editor/widgets/canvas_element_widget.dart';

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

    final safeLeft = tl.x * mmToPx * widget.zoomLevel;
    final safeTop = tl.y * mmToPx * widget.zoomLevel;
    final safeWidth = (br.x - tl.x) * mmToPx * widget.zoomLevel;
    final safeHeight = (br.y - tl.y) * mmToPx * widget.zoomLevel;

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
                    dotColor: colorScheme.onSurfaceVariant.withValues(alpha: 0.12),
                  ),
                ),
              ),

              // Rulers (horizontal & vertical)
              _buildHorizontalRuler(colorScheme),
              _buildVerticalRuler(colorScheme),

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
                          // Safe Area Red Border
                          if (safeWidth > 0 && safeHeight > 0)
                            Positioned(
                              left: safeLeft,
                              top: safeTop,
                              width: safeWidth,
                              height: safeHeight,
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.red.shade300.withValues(alpha: 0.4),
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

  Widget _buildHorizontalRuler(ColorScheme colorScheme) {
    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      height: 20,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
        ),
        child: Row(
          children: List.generate(30, (i) {
            return Container(
              width: 50,
              alignment: Alignment.bottomLeft,
              padding: const EdgeInsets.only(left: 4, bottom: 2),
              child: Text(
                '${i * 50}',
                style: TextStyle(
                  fontSize: 8,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildVerticalRuler(ColorScheme colorScheme) {
    return Positioned(
      left: 0,
      top: 20,
      bottom: 0,
      width: 20,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          border: Border(right: BorderSide(color: colorScheme.outlineVariant)),
        ),
        child: Column(
          children: List.generate(20, (i) {
            return Container(
              height: 50,
              alignment: Alignment.topLeft,
              padding: const EdgeInsets.only(left: 2, top: 4),
              child: Text(
                '${i * 50}',
                style: TextStyle(
                  fontSize: 8,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            );
          }),
        ),
      ),
    );
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
