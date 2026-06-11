import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stickify/app/routing/router.dart';
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

  @override
  void initState() {
    super.initState();
    _loadSampleProduct();
  }

  Future<void> _loadSampleProduct() async {
    try {
      final productRepository = context.read<ProductRepository>();
      final products = await productRepository.getAllProducts();
      if (products.isNotEmpty && mounted) {
        setState(() {
          _sampleProduct = products.first;
        });
      }
    } on Exception catch (_) {
      // Fallback sample product if repository loading fails
      if (mounted) {
        setState(() {
          _sampleProduct = Product(
            id: 'prod-001',
            name: 'Organic Cold Brew 12oz',
            sku: 'BEV-CB-ORG-12',
            totalPrints: 1240,
            lastPrintedAt: DateTime.now(),
            assignedStation: 'Station #02',
            stationStatus: StationStatus.online,
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
          PreviewRoute(templateId: state.templateId).go(context);
        }
        if (state is EditorError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: colorScheme.error,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is EditorLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is EditorLoaded) {
          final canvasWidget = EditorCanvas(
            stickerConfig: state.stickerConfig,
            elements: state.elements,
            selectedElementId: state.selectedElementId,
            zoomLevel: state.zoomLevel,
            product: _sampleProduct,
          );

          final propertiesPanelWidget = PropertiesPanel(
            selectedElement: state.selectedElement,
            onBack: () =>
                StickerSetupRoute(templateId: cubit.templateId).go(context),
            onNext: cubit.saveAndContinue,
          );

          final mobilePropertiesPanelWidget = PropertiesPanel(
            selectedElement: state.selectedElement,
            onBack: () {},
            onNext: () {},
            showNavigation: false,
          );

          final zoomControlsWidget = ZoomControls(
            zoomLevel: state.zoomLevel,
            onZoomChanged: cubit.setZoom,
          );

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
              mobile: Scaffold(
                body: Stack(
                  children: [
                    canvasWidget,
                    Positioned(
                      right: 16,
                      bottom: 76,
                      child: zoomControlsWidget,
                    ),
                  ],
                ),
                bottomNavigationBar: BottomAppBar(
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
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('Add'),
                        onPressed: () {
                          final _ = showModalBottomSheet<void>(
                            context: context,
                            builder: (dialogContext) => BlocProvider.value(
                              value: cubit,
                              child: const ElementPalette(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        icon: const Icon(Icons.edit_note),
                        label: const Text('Properties'),
                        onPressed: state.selectedElementId == null
                            ? null
                            : () {
                                showModalBottomSheet<void>(
                                  context: context,
                                  isScrollControlled: true,
                                  builder: (dialogContext) {
                                    return Padding(
                                      padding: EdgeInsets.only(
                                        bottom: MediaQuery.of(dialogContext).viewInsets.bottom,
                                      ),
                                      child: Container(
                                        constraints: BoxConstraints(
                                          maxHeight: MediaQuery.of(dialogContext).size.height * 0.7,
                                        ),
                                        child: BlocProvider.value(
                                          value: cubit,
                                          child: mobilePropertiesPanelWidget,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward),
                        tooltip: 'Next: Preview',
                        onPressed: cubit.saveAndContinue,
                      ),
                    ],
                  ),
                ),
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

        return const SizedBox.shrink();
      },
    );
  }
}
