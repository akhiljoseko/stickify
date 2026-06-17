import 'dart:math' show pi;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stickify/core/constants/dimensions.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/template_editor/core/element_renderer_registry.dart';
import 'package:stickify/presentation/features/template_editor/label_editor/bloc/editor_cubit.dart';

/// Represents a single positioned component inside the designer canvas grid.
///
/// Wraps blueprint elements in gesture detectors for dragging and selection, and handles
/// rendering and layout outline highlights.
class CanvasElementWidget extends StatelessWidget {
  /// Creates a [CanvasElementWidget] instance.
  const CanvasElementWidget({
    required this.blueprint,
    required this.isSelected,
    required this.onTap,
    required this.zoomLevel,
    this.product,
    super.key,
  });

  /// The blueprint describing position, dimension, rotation and type.
  final ElementBlueprint blueprint;

  /// Whether this specific element is currently selected on the canvas.
  final bool isSelected;

  /// Callback when user taps/clicks on this element.
  final VoidCallback onTap;

  /// Viewport zoom scaling factor.
  final double zoomLevel;

  /// Optional product entity to populate dynamic token references.
  final Product? product;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Apply zoom scaling to dimensions (1mm = 4 logical pixels)
    final width = blueprint.width * AppDimensions.mmToPx * zoomLevel;
    final height = blueprint.height * AppDimensions.mmToPx * zoomLevel;
    final left = blueprint.x * AppDimensions.mmToPx * zoomLevel;
    final top = blueprint.y * AppDimensions.mmToPx * zoomLevel;

    final renderedChild = ElementRendererRegistry.forBlueprint(blueprint)
        .render(context, blueprint, product: product);

    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: Transform.rotate(
        angle: blueprint.rotation * (pi / 180),
        child: MouseRegion(
          cursor: SystemMouseCursors.move,
          child: GestureDetector(
            onTapDown: (_) => onTap(),
            onPanUpdate: (details) {
              // Factor in zoom level and mm-to-pixel ratio when calculating position update
              final dx = details.delta.dx / zoomLevel / AppDimensions.mmToPx;
              final dy = details.delta.dy / zoomLevel / AppDimensions.mmToPx;
              context.read<EditorCubit>().dragElement(blueprint.id, dx, dy);
            },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Main content scaled by the zoom level using FittedBox
              SizedBox(
                width: width,
                height: height,
                child: FittedBox(
                  fit: BoxFit.fill,
                  child: SizedBox(
                    width: blueprint.width * AppDimensions.mmToPx,
                    height: blueprint.height * AppDimensions.mmToPx,
                    child: renderedChild,
                  ),
                ),
              ),
              
              // Selection outline & Grab handles
              if (isSelected) ...[
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: colorScheme.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
                // Corner handle top-left
                _buildGrabHandle(
                  left: -4,
                  top: -4,
                  color: colorScheme.primary,
                  cursor: SystemMouseCursors.resizeUpLeftDownRight,
                  onDrag: (details) {
                    final dx = details.delta.dx / zoomLevel / AppDimensions.mmToPx;
                    final dy = details.delta.dy / zoomLevel / AppDimensions.mmToPx;
                    final newX = (blueprint.x + dx).clamp(0.0, blueprint.x + blueprint.width - 2.0);
                    final newY = (blueprint.y + dy).clamp(0.0, blueprint.y + blueprint.height - 2.0);
                    final newWidth = (blueprint.width - dx).clamp(2.0, 500.0);
                    final newHeight = (blueprint.height - dy).clamp(2.0, 500.0);
                    context.read<EditorCubit>().updateElementProperty(
                      blueprint.id,
                      blueprint.copyWith(x: newX, y: newY, width: newWidth, height: newHeight),
                    );
                  },
                ),
                // Corner handle top-right
                _buildGrabHandle(
                  right: -4,
                  top: -4,
                  color: colorScheme.primary,
                  cursor: SystemMouseCursors.resizeUpRightDownLeft,
                  onDrag: (details) {
                    final dx = details.delta.dx / zoomLevel / AppDimensions.mmToPx;
                    final dy = details.delta.dy / zoomLevel / AppDimensions.mmToPx;
                    final newY = (blueprint.y + dy).clamp(0.0, blueprint.y + blueprint.height - 2.0);
                    final newWidth = (blueprint.width + dx).clamp(2.0, 500.0);
                    final newHeight = (blueprint.height - dy).clamp(2.0, 500.0);
                    context.read<EditorCubit>().updateElementProperty(
                      blueprint.id,
                      blueprint.copyWith(y: newY, width: newWidth, height: newHeight),
                    );
                  },
                ),
                // Corner handle bottom-left
                _buildGrabHandle(
                  left: -4,
                  bottom: -4,
                  color: colorScheme.primary,
                  cursor: SystemMouseCursors.resizeUpRightDownLeft,
                  onDrag: (details) {
                    final dx = details.delta.dx / zoomLevel / AppDimensions.mmToPx;
                    final dy = details.delta.dy / zoomLevel / AppDimensions.mmToPx;
                    final newX = (blueprint.x + dx).clamp(0.0, blueprint.x + blueprint.width - 2.0);
                    final newWidth = (blueprint.width - dx).clamp(2.0, 500.0);
                    final newHeight = (blueprint.height + dy).clamp(2.0, 500.0);
                    context.read<EditorCubit>().updateElementProperty(
                      blueprint.id,
                      blueprint.copyWith(x: newX, width: newWidth, height: newHeight),
                    );
                  },
                ),
                // Corner handle bottom-right
                _buildGrabHandle(
                  right: -4,
                  bottom: -4,
                  color: colorScheme.primary,
                  cursor: SystemMouseCursors.resizeUpLeftDownRight,
                  onDrag: (details) {
                    final dx = details.delta.dx / zoomLevel / AppDimensions.mmToPx;
                    final dy = details.delta.dy / zoomLevel / AppDimensions.mmToPx;
                    final newWidth = (blueprint.width + dx).clamp(2.0, 500.0);
                    final newHeight = (blueprint.height + dy).clamp(2.0, 500.0);
                    context.read<EditorCubit>().updateElementProperty(
                      blueprint.id,
                      blueprint.copyWith(width: newWidth, height: newHeight),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildGrabHandle({
    required Color color,
    required MouseCursor cursor,
    required void Function(DragUpdateDetails details) onDrag,
    double? left,
    double? top,
    double? right,
    double? bottom,
  }) {
    return Positioned(
      left: left != null ? left - 8 : null,
      top: top != null ? top - 8 : null,
      right: right != null ? right - 8 : null,
      bottom: bottom != null ? bottom - 8 : null,
      child: MouseRegion(
        cursor: cursor,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanUpdate: onDrag,
          child: Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: color, width: 2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
