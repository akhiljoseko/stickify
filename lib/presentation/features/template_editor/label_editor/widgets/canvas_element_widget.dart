import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/template_editor/core/element_renderer_registry.dart';
import 'package:stickify/presentation/features/template_editor/label_editor/bloc/editor_cubit.dart';

class CanvasElementWidget extends StatelessWidget {
  const CanvasElementWidget({
    required this.blueprint,
    required this.isSelected,
    required this.onTap,
    required this.zoomLevel,
    this.product,
    super.key,
  });

  final ElementBlueprint blueprint;
  final bool isSelected;
  final VoidCallback onTap;
  final double zoomLevel;
  final Product? product;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Apply zoom scaling to dimensions
    final width = blueprint.width * zoomLevel;
    final height = blueprint.height * zoomLevel;
    final left = blueprint.x * zoomLevel;
    final top = blueprint.y * zoomLevel;

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
            // Factor in zoom level when calculating position update
            final dx = details.delta.dx / zoomLevel;
            final dy = details.delta.dy / zoomLevel;
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
                    width: blueprint.width,
                    height: blueprint.height,
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
