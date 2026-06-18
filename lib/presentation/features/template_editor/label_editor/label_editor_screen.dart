import 'dart:math' show min;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stickify/app/routing/router.dart';
import 'package:stickify/core/constants/dimensions.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/template_editor/label_editor/bloc/editor_cubit.dart';
import 'package:stickify/presentation/features/template_editor/label_editor/bloc/editor_state.dart';
import 'package:stickify/presentation/features/template_editor/label_editor/widgets/editor_canvas.dart';
import 'package:stickify/presentation/features/template_editor/label_editor/widgets/element_palette.dart';
import 'package:stickify/presentation/features/template_editor/label_editor/widgets/properties_panel.dart';
import 'package:stickify/presentation/features/template_editor/label_editor/widgets/zoom_controls.dart';
import 'package:stickify/presentation/features/template_editor/widgets/wizard_step_indicator.dart';
import 'package:stickify/presentation/widgets/adaptive_layout_switcher.dart';

/// Screen presenting the drag-and-drop label designer canvas.
///
/// Integrates the [ElementPalette] to select components, a live canvas for positioning,
/// and the [PropertiesPanel] for detail modifications.
class LabelEditorScreen extends StatelessWidget {
  /// Creates a [LabelEditorScreen] instance.
  const LabelEditorScreen({required this.templateId, super.key});

  /// The unique identifier of the template being designed.
  final String templateId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => EditorCubit(
        context.read<TemplateRepository>(),
        templateId,
      )..load(),
      child: const _LabelEditorView(),
    );
  }
}

class _LabelEditorView extends StatefulWidget {
  const _LabelEditorView();

  @override
  State<_LabelEditorView> createState() => _LabelEditorViewState();
}

class _LabelEditorViewState extends State<_LabelEditorView> {
  Product? _sampleProduct;
  bool _showHorizontalPalette = false;
  bool _hasUnsavedChanges = false;
  bool _initialLoadDone = false;

  Future<bool> _confirmBack() async {
    if (!_hasUnsavedChanges) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('You have unsaved changes in the label design. Do you want to discard them?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Discard')),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  void initState() {
    super.initState();
    _loadSampleProduct();
  }

  Future<void> _loadSampleProduct() async {
    try {
      final productRepository = context.read<ProductRepository>();
      final result = await productRepository.getAllProducts();
      if (mounted) {
        switch (result) {
          case Success(value: final products):
            if (products.isNotEmpty) {
              setState(() {
                _sampleProduct = products.first;
              });
            }
          case Failure():
            break;
        }
      }
    } on Exception catch (_) {
      // Fallback sample product if repository loading fails
      if (mounted) {
        setState(() {
          _sampleProduct = Product(
            id: 'prod-001',
            name: 'Organic Cold Brew 12oz',
            sku: 'BEV-CB-ORG-12',
            category: 'Beverages',
            shelfLifeDays: 90,
            storageConditions: 'Keep refrigerated below 5°C',
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final cubit = context.read<EditorCubit>();

    return BlocConsumer<EditorCubit, EditorState>(
      listener: (context, state) {
        if (state is EditorSaved) {
          _hasUnsavedChanges = false;
          PreviewRoute(templateId: state.templateId).go(context);
        }
        if (state is EditorError) {
          context.read<NotificationService>().showError(state.message);
        }
      },
      builder: (context, state) {
        if (state is EditorLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is EditorLoaded) {
          if (_initialLoadDone) {
            _hasUnsavedChanges = true;
          } else {
            _initialLoadDone = true;
          }
          final canvasWidget = EditorCanvas(
            stickerConfig: state.stickerConfig,
            elements: state.elements,
            selectedElementId: state.selectedElementId,
            zoomLevel: state.zoomLevel,
            product: _sampleProduct,
          );

          final propertiesPanelWidget = PropertiesPanel(
            selectedElement: state.selectedElement,
            onBack: () async {
              if (await _confirmBack()) {
                StickerSetupRoute(templateId: cubit.templateId).go(context);
              }
            },
            onNext: cubit.saveAndContinue,
          );

          final mobilePropertiesPanelWidget = PropertiesPanel(
            selectedElement: state.selectedElement,
            onBack: () {},
            onNext: () {},
            showNavigation: false,
          );

          double computeZoomToFit(BuildContext context) {
            final viewport = MediaQuery.sizeOf(context);
            final availW = viewport.width - 256 - 320 - 48;
            final availH = viewport.height - kToolbarHeight - 60 - 48;
            final stickerW = state.stickerConfig.widthMm * AppDimensions.mmToPx;
            final stickerH = state.stickerConfig.heightMm * AppDimensions.mmToPx;
            final fitW = availW / stickerW;
            final fitH = availH / stickerH;
            return min(fitW, fitH).clamp(0.5, 2.0).floorToDouble();
          }

          final zoomControlsWidget = ZoomControls(
            zoomLevel: state.zoomLevel,
            onZoomChanged: cubit.setZoom,
            onZoomToFit: () => cubit.setZoom(computeZoomToFit(context)),
          );

          // Auto-hide horizontal palette if an element is selected
          if (state.selectedElementId != null && _showHorizontalPalette) {
            _showHorizontalPalette = false;
          }

          return Scaffold(
            backgroundColor: colorScheme.surface,
            appBar: AppBar(
              title: const Text('Label Designer'),
              bottom: const PreferredSize(
                preferredSize: Size.fromHeight(60),
                child: WizardStepIndicator(currentStep: 3),
              ),
            ),
            body: AdaptiveLayoutSwitcher(
              mobile: Column(
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        canvasWidget,
                        Positioned(
                          right: 16,
                          bottom: 16,
                          child: zoomControlsWidget,
                        ),
                      ],
                    ),
                  ),
                  if (state.selectedElementId != null)
                    Container(
                      height: 250,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerLow,
                        border: Border(
                          top: BorderSide(color: colorScheme.outlineVariant),
                        ),
                      ),
                      child: mobilePropertiesPanelWidget,
                    )
                  else if (_showHorizontalPalette)
                    const ElementPalette(isHorizontal: true),
                  BottomAppBar(
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          tooltip: 'Back',
                          onPressed: () => StickerSetupRoute(
                            templateId: cubit.templateId,
                          ).go(context),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          icon: Icon(
                            _showHorizontalPalette ? Icons.close : Icons.add_circle_outline,
                            color: _showHorizontalPalette ? colorScheme.error : colorScheme.primary,
                          ),
                          label: Text(
                            _showHorizontalPalette ? 'Close' : 'Add',
                            style: TextStyle(
                              color: _showHorizontalPalette ? colorScheme.error : colorScheme.primary,
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              _showHorizontalPalette = !_showHorizontalPalette;
                              if (_showHorizontalPalette) {
                                cubit.deselectAll();
                              }
                            });
                          },
                        ),
                        if (state.selectedElementId != null) ...[
                          const SizedBox(width: 16),
                          TextButton.icon(
                            icon: const Icon(Icons.deselect, color: Colors.grey),
                            label: const Text('Deselect', style: TextStyle(color: Colors.grey)),
                            onPressed: cubit.deselectAll,
                          ),
                        ],
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward),
                          tooltip: 'Next: Preview',
                          onPressed: cubit.saveAndContinue,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              desktop: Row(
                children: [
                  const ElementPalette(),
                  Expanded(
                    child: Stack(
                      children: [
                        Positioned.fill(child: canvasWidget),
                        Positioned(
                          right: 24,
                          bottom: 24,
                          child: zoomControlsWidget,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 320,
                    child: propertiesPanelWidget,
                  ),
                ],
              ),
            ),
          );
        }

        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
