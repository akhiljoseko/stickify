import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
    final width = blueprint.width * 4.0 * zoomLevel;
    final height = blueprint.height * 4.0 * zoomLevel;
    final left = blueprint.x * 4.0 * zoomLevel;
    final top = blueprint.y * 4.0 * zoomLevel;

    final renderedChild = ElementRendererRegistry.forBlueprint(blueprint)
        .render(context, blueprint, product: product);

    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: Transform.rotate(
        angle: blueprint.rotation * (3.141592653589793 / 180),
        child: GestureDetector(
          onTapDown: (_) => onTap(),
          onPanUpdate: (details) {
            // Factor in zoom level and mm-to-pixel ratio when calculating position update
            final dx = details.delta.dx / zoomLevel / 4.0;
            final dy = details.delta.dy / zoomLevel / 4.0;
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
                    width: blueprint.width * 4.0,
                    height: blueprint.height * 4.0,
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
                _buildGrabHandle(left: -4, top: -4, color: colorScheme.primary),
                // Corner handle top-right
                _buildGrabHandle(right: -4, top: -4, color: colorScheme.primary),
                // Corner handle bottom-left
                _buildGrabHandle(left: -4, bottom: -4, color: colorScheme.primary),
                // Corner handle bottom-right
                _buildGrabHandle(right: -4, bottom: -4, color: colorScheme.primary),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGrabHandle({
    required Color color, double? left,
    double? top,
    double? right,
    double? bottom,
  }) {
    return Positioned(
      left: left,
      top: top,
      right: right,
      bottom: bottom,
      child: IgnorePointer(
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: color, width: 2),
          ),
        ),
      ),
    );
  }
}
