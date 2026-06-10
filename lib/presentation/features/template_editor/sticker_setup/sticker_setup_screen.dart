import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stickify/app/routing/router.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/template_editor/sticker_setup/bloc/sticker_setup_cubit.dart';
import 'package:stickify/presentation/features/template_editor/sticker_setup/bloc/sticker_setup_state.dart';
import 'package:stickify/presentation/features/template_editor/sticker_setup/widgets/polygon_painter.dart';
import 'package:stickify/presentation/features/template_editor/widgets/setup_fields.dart';
import 'package:stickify/presentation/features/template_editor/widgets/wizard_step_indicator.dart';
import 'package:stickify/presentation/widgets/adaptive_layout_switcher.dart';
import 'package:stickify/presentation/widgets/adaptive_scroll_wrapper.dart';

class StickerSetupScreen extends StatelessWidget {
  const StickerSetupScreen({required this.templateId, super.key});

  final String templateId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => StickerSetupCubit(
        context.read<TemplateRepository>(),
        templateId,
      )..load(),
      child: const _StickerSetupView(),
    );
  }
}

class _StickerSetupView extends StatefulWidget {
  const _StickerSetupView();

  @override
  State<_StickerSetupView> createState() => _StickerSetupViewState();
}

class _StickerSetupViewState extends State<_StickerSetupView> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return BlocConsumer<StickerSetupCubit, StickerSetupState>(
      listener: (context, state) {
        if (state is StickerSetupSaved) {
          LabelEditorRoute(templateId: state.templateId).go(context);
        }
        if (state is StickerSetupError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: colorScheme.error,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is StickerSetupLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is StickerSetupEditing) {
          final formPane = Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sticker Dimensions', style: textTheme.titleMedium),
                const SizedBox(height: 16),
                
                // Width & Height
                Row(
                  children: [
                    Expanded(
                      child: SetupNumberField(
                        value: state.widthMm,
                        labelText: 'Width (mm)',
                        onChanged: (val) {
                          context.read<StickerSetupCubit>().updateFields(widthMm: val);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SetupNumberField(
                        value: state.heightMm,
                        labelText: 'Height (mm)',
                        onChanged: (val) {
                          context.read<StickerSetupCubit>().updateFields(heightMm: val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Corner Radius
                SetupNumberField(
                  value: state.cornerRadiusMm,
                  labelText: 'Corner Radius (mm)',
                  onChanged: (val) {
                    context.read<StickerSetupCubit>().updateFields(cornerRadiusMm: val);
                  },
                ),
                const SizedBox(height: 24),

                Text('Printable Area Padding / Margins (mm)', style: textTheme.titleSmall),
                const SizedBox(height: 12),
                
                // Padding inputs
                Row(
                  children: [
                    Expanded(
                      child: SetupNumberField(
                        value: state.paddingTop,
                        labelText: 'Top',
                        onChanged: (val) {
                          context.read<StickerSetupCubit>().updateFields(paddingTop: val);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SetupNumberField(
                        value: state.paddingBottom,
                        labelText: 'Bottom',
                        onChanged: (val) {
                          context.read<StickerSetupCubit>().updateFields(paddingBottom: val);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SetupNumberField(
                        value: state.paddingLeft,
                        labelText: 'Left',
                        onChanged: (val) {
                          context.read<StickerSetupCubit>().updateFields(paddingLeft: val);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SetupNumberField(
                        value: state.paddingRight,
                        labelText: 'Right',
                        onChanged: (val) {
                          context.read<StickerSetupCubit>().updateFields(paddingRight: val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),

                // Custom Polygon Toggle
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Use Custom Polygon Printable Area'),
                  subtitle: const Text('Define an arbitrary safe design shape via coordinate points'),
                  value: state.isCustomPolygon,
                  onChanged: (val) {
                    context.read<StickerSetupCubit>().toggleCustomPolygon(enabled: val);
                  },
                ),
                
                if (state.isCustomPolygon) ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Polygon Edge Points (mm)', style: textTheme.titleSmall),
                      TextButton.icon(
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Point'),
                        onPressed: () {
                          context.read<StickerSetupCubit>().addPolygonPoint();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.polygonPoints.length,
                    // onReorder is deprecated in newer Flutter versions but is kept here
                    // to support older versions in the build environment.
                    // ignore: deprecated_member_use
                    onReorder: (oldIdx, newIdx) {
                      context.read<StickerSetupCubit>().reorderPolygonPoints(oldIdx, newIdx);
                    },
                    itemBuilder: (context, index) {
                      final point = state.polygonPoints[index];
                      final pointId = state.polygonPointIds[index];
                      return Padding(
                        key: ValueKey(pointId),
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            ReorderableDragStartListener(
                              index: index,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Icon(
                                  Icons.drag_handle,
                                  size: 20,
                                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              width: 24,
                              alignment: Alignment.center,
                              child: Text(
                                '${index + 1}',
                                style: textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SetupNumberField(
                                keyString: 'pt_${pointId}_x',
                                value: point.x,
                                labelText: 'X (mm)',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                onChanged: (val) {
                                  context.read<StickerSetupCubit>().updatePolygonPoint(index, val, point.y);
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SetupNumberField(
                                keyString: 'pt_${pointId}_y',
                                value: point.y,
                                labelText: 'Y (mm)',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                onChanged: (val) {
                                  context.read<StickerSetupCubit>().updatePolygonPoint(index, point.x, val);
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: Icon(Icons.delete_outline, color: colorScheme.error),
                              onPressed: state.polygonPoints.length > 3
                                  ? () => context.read<StickerSetupCubit>().removePolygonPoint(index)
                                  : null,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          );

          final previewPane = Container(
            color: colorScheme.surfaceContainerLow,
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text('Live Sticker Layout Preview', style: textTheme.titleSmall),
                const SizedBox(height: 16),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Draw the sticker scaled dynamically
                      final aspect = state.widthMm / state.heightMm;
                      final maxW = constraints.maxWidth - 40;
                      final maxH = constraints.maxHeight - 40;

                      var drawW = maxW;
                      var drawH = maxW / aspect;

                      if (drawH > maxH) {
                        drawH = maxH;
                        drawW = maxH * aspect;
                      }

                      // Convert mm radius to pixels
                      final scale = drawW / state.widthMm;
                      final radiusPx = state.cornerRadiusMm * scale;
                      
                      return Center(
                        child: Container(
                          width: drawW,
                          height: drawH,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(radiusPx),
                            border: Border.all(color: colorScheme.outlineVariant, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              // Safe printable area polygon representation
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: PolygonPainter(
                                    points: state.toConfig().printableArea,
                                    scale: scale,
                                    color: Colors.red.shade300,
                                    showMarkers: true,
                                    markerColor: colorScheme.primary,
                                  ),
                                ),
                              ),
                              Center(
                                child: IgnorePointer(
                                  child: Text(
                                    'Printable Safe Area',
                                    style: TextStyle(
                                      color: Colors.red.shade300.withValues(alpha: 0.8),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );

          return Scaffold(
            backgroundColor: colorScheme.surface,
            appBar: AppBar(
              title: const Text('Sticker Layout Configuration'),
              bottom: const PreferredSize(
                preferredSize: Size.fromHeight(60),
                child: WizardStepIndicator(currentStep: 2),
              ),
            ),
            body: Column(
              children: [
                Expanded(
                  child: AdaptiveLayoutSwitcher(
                    mobile: AdaptiveScrollWrapper(
                      builder: (context, controller) => SingleChildScrollView(
                        controller: controller,
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            formPane,
                            const SizedBox(height: 32),
                            SizedBox(height: 350, child: previewPane),
                          ],
                        ),
                      ),
                    ),
                    desktop: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 4,
                          child: AdaptiveScrollWrapper(
                            builder: (context, controller) => SingleChildScrollView(
                              controller: controller,
                              padding: const EdgeInsets.all(32),
                              child: formPane,
                            ),
                          ),
                        ),
                        const VerticalDivider(width: 1, thickness: 1),
                        Expanded(
                          flex: 6,
                          child: previewPane,
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Footer
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    border: Border(
                      top: BorderSide(color: colorScheme.outlineVariant),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OutlinedButton(
                        onPressed: () => SheetConfigRoute(
                          templateId: context.read<StickerSetupCubit>().templateId,
                        ).go(context),
                        child: const Text('Back'),
                      ),
                      ElevatedButton(
                        onPressed: () => context.read<StickerSetupCubit>().saveAndContinue(),
                        child: const Text('Next: Label Designer'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
