import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:stickify/app/routing/router.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/template_editor/core/element_renderer_registry.dart';
import 'package:stickify/presentation/features/template_editor/preview/bloc/preview_cubit.dart';
import 'package:stickify/presentation/features/template_editor/preview/bloc/preview_state.dart';
import 'package:stickify/presentation/features/template_editor/sticker_setup/widgets/polygon_painter.dart';
import 'package:stickify/presentation/features/template_editor/widgets/wizard_step_indicator.dart';
import 'package:stickify/presentation/widgets/adaptive_layout_switcher.dart';
import 'package:stickify/presentation/widgets/adaptive_scroll_wrapper.dart';

/// Screen that displays the finalized visual template sticker layout before saving.
///
/// Features dynamic sample data mapping to preview the layout.
class PreviewScreen extends StatelessWidget {
  /// Creates a [PreviewScreen] instance.
  const PreviewScreen({required this.templateId, super.key});

  /// The unique identifier of the template to preview and finalize.
  final String templateId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final cubit = PreviewCubit(
          context.read<TemplateRepository>(),
          templateId,
        );
        unawaited(cubit.loadPreview());
        return cubit;
      },
      child: const _PreviewView(),
    );
  }
}

class _PreviewView extends StatefulWidget {
  const _PreviewView();

  @override
  State<_PreviewView> createState() => _PreviewViewState();
}

class _PreviewViewState extends State<_PreviewView> {
  Product? _sampleProduct;

  @override
  void initState() {
    super.initState();
    unawaited(_loadSampleProduct());
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
    } on Object catch (_) {
      // Fallback sample product
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
    final textTheme = Theme.of(context).textTheme;

    return BlocConsumer<PreviewCubit, PreviewState>(
      listener: (context, state) {
        if (state is PreviewFinalized) {
          // Success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Template saved and finalized!'),
              backgroundColor: Colors.green,
            ),
          );
          // Return to home management list
          const TemplateManagementRoute().go(context);
        }
        if (state is PreviewError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: colorScheme.error,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is PreviewLoading || state is PreviewFinalizing) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is PreviewLoaded) {
          final template = state.template;
          final sticker = template.stickerConfig ??
              const StickerConfig(widthMm: 100, heightMm: 60, cornerRadiusMm: 4, printableArea: []);
          final sheets = template.sheetConfig ??
              const SheetConfig(pageWidth: 210, pageHeight: 297, marginTop: 10, marginBottom: 10, marginLeft: 10, marginRight: 10, columns: 2, rows: 4, columnGap: 5, rowGap: 5);

          // Convert sticker dimensions to pixels (1mm = 4px)
          const mmToPx = 4;
          final boardWidth = sticker.widthMm * mmToPx;
          final boardHeight = sticker.heightMm * mmToPx;



          final previewBoard = Center(
            child: Container(
              width: boardWidth,
              height: boardHeight,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(sticker.cornerRadiusMm * mmToPx),
                border: Border.all(color: colorScheme.outlineVariant, width: 1.5),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  )
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Safe Area Polygon Border
                  Positioned.fill(
                    child: CustomPaint(
                      painter: PolygonPainter(
                        points: sticker.printableArea,
                        scale: mmToPx.toDouble(),
                        color: Colors.red.shade300.withValues(alpha: 0.35),
                      ),
                    ),
                  ),
                  
                  // Rendered elements
                  ...template.elements.map((bp) {
                    final width = bp.width * mmToPx;
                    final height = bp.height * mmToPx;
                    final left = bp.x * mmToPx;
                    final top = bp.y * mmToPx;

                    final renderedChild = ElementRendererRegistry.forBlueprint(bp)
                        .render(context, bp, product: _sampleProduct);

                    return Positioned(
                      left: left,
                      top: top,
                      width: width,
                      height: height,
                      child: Transform.rotate(
                        angle: bp.rotation * (3.141592653589793 / 180),
                        child: SizedBox(
                          width: width,
                          height: height,
                          child: renderedChild,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          );

          final desktopSidebar = Container(
            width: 320,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              border: Border(
                left: BorderSide(color: colorScheme.outlineVariant),
              ),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Template Summary',
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                
                _buildSummaryItem(textTheme, colorScheme, 'Name', template.name),
                _buildSummaryItem(
                  textTheme,
                  colorScheme,
                  'Page Layout',
                  '${sheets.pageWidth.toStringAsFixed(1)} × ${sheets.pageHeight.toStringAsFixed(1)} mm (${sheets.columns} × ${sheets.rows} grid)',
                ),
                _buildSummaryItem(
                  textTheme,
                  colorScheme,
                  'Sticker Dimensions',
                  '${sticker.widthMm.toStringAsFixed(1)} × ${sticker.heightMm.toStringAsFixed(1)} mm',
                ),
                _buildSummaryItem(
                  textTheme,
                  colorScheme,
                  'Elements Count',
                  '${template.elements.length} placed objects',
                ),
                
                const Spacer(),
                const Divider(),
                const SizedBox(height: 16),
                
                // Finalize Action
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () => context.read<PreviewCubit>().finalizeAndSave(),
                    child: const Text('Save & Finalize'),
                  ),
                ),
              ],
            ),
          );

          final bp = ResponsiveBreakpoints.of(context);
          final isMobileOrTablet = bp.breakpoint.name == AppBreakpoints.mobile ||
              bp.breakpoint.name == AppBreakpoints.tablet;

          return Scaffold(
            backgroundColor: colorScheme.surface,
            appBar: AppBar(
              title: const Text('Final Label Preview'),
              bottom: const PreferredSize(
                preferredSize: Size.fromHeight(60),
                child: WizardStepIndicator(currentStep: 4),
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
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Label Preview',
                              style: textTheme.titleSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 240,
                              child: Center(
                                child: FittedBox(
                                  child: previewBoard,
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            Text(
                              'Template Summary',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildSummaryItem(textTheme, colorScheme, 'Name', template.name),
                            _buildSummaryItem(
                              textTheme,
                              colorScheme,
                              'Page Layout',
                              '${sheets.pageWidth.toStringAsFixed(1)} × ${sheets.pageHeight.toStringAsFixed(1)} mm (${sheets.columns} × ${sheets.rows} grid)',
                            ),
                            _buildSummaryItem(
                              textTheme,
                              colorScheme,
                              'Sticker Dimensions',
                              '${sticker.widthMm.toStringAsFixed(1)} × ${sticker.heightMm.toStringAsFixed(1)} mm',
                            ),
                            _buildSummaryItem(
                              textTheme,
                              colorScheme,
                              'Elements Count',
                              '${template.elements.length} placed objects',
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                    desktop: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 7,
                          child: ColoredBox(
                            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
                            child: Center(
                              child: FittedBox(
                                child: previewBoard,
                              ),
                            ),
                          ),
                        ),
                        const VerticalDivider(width: 1, thickness: 1),
                        desktopSidebar,
                      ],
                    ),
                  ),
                ),
                if (isMobileOrTablet)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      border: Border(
                        top: BorderSide(color: colorScheme.outlineVariant),
                      ),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final useVerticalLayout = constraints.maxWidth < 340;
                        if (useVerticalLayout) {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ElevatedButton(
                                onPressed: () => context.read<PreviewCubit>().finalizeAndSave(),
                                child: const Text('Save & Finalize'),
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton(
                                onPressed: () => LabelEditorRoute(templateId: template.id).go(context),
                                child: const Text('Back to Editor'),
                              ),
                            ],
                          );
                        } else {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              OutlinedButton(
                                onPressed: () => LabelEditorRoute(templateId: template.id).go(context),
                                child: const Text('Back to Editor'),
                              ),
                              ElevatedButton(
                                onPressed: () => context.read<PreviewCubit>().finalizeAndSave(),
                                child: const Text('Save & Finalize'),
                              ),
                            ],
                          );
                        }
                      },
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

  Widget _buildSummaryItem(
    TextTheme textTheme,
    ColorScheme colorScheme,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
