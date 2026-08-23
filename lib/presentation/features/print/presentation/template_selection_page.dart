import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:stickify/app/routing/router.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/widgets/widgets.dart';

/// A screen allowing users to pick which finalized [LabelTemplate] to use for the selected product and variant.
class TemplateSelectionPage extends StatefulWidget {
  /// Creates a [TemplateSelectionPage] instance.
  const TemplateSelectionPage({
    required this.productId,
    required this.variantSku,
    super.key,
  });

  /// The active product ID.
  final String productId;

  /// The active product variant SKU.
  final String variantSku;

  @override
  State<TemplateSelectionPage> createState() => _TemplateSelectionPageState();
}

class _TemplateSelectionPageState extends State<TemplateSelectionPage> {
  late Product _product;
  late ProductVariant _variant;
  List<LabelTemplate> _templates = [];
  String? _selectedTemplateId;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final productRepo = context.read<ProductRepository>();
      final templateRepo = context.read<TemplateRepository>();
      final settingsRepo = context.read<SettingsRepository>();

      final productResult = await productRepo.getProductById(widget.productId);
      switch (productResult) {
        case Failure(error: final err):
          setState(() {
            _errorMessage = err.message;
            _isLoading = false;
          });
          return;
        case Success(value: final product):
          if (product == null) {
            setState(() {
              _errorMessage = 'Product not found.';
              _isLoading = false;
            });
            return;
          }

          final variant = product.variants.firstWhere(
            (v) => v.sku == widget.variantSku,
            orElse: () => throw Exception('Variant SKU ${widget.variantSku} not found.'),
          );

          final templatesResult = await templateRepo.fetchTemplates();
          final List<LabelTemplate> finalized;
          switch (templatesResult) {
            case Failure(error: final err):
              setState(() {
                _errorMessage = err.message;
                _isLoading = false;
              });
              return;
            case Success(value: final templates):
              finalized = templates.where((t) => t.isFinalized).toList();
          }

          final settings = await settingsRepo.getSettings();

          final hasDefaultTemplate = variant.defaultTemplateId != null &&
              finalized.any((t) => t.id == variant.defaultTemplateId);

          if (hasDefaultTemplate && settings.enableDefaultTemplateUsage) {
            if (!mounted) return;
            PrintSetupRoute(
              productId: widget.productId,
              variantSku: widget.variantSku,
              templateId: variant.defaultTemplateId!,
            ).pushReplacement(context);
            return;
          }

          setState(() {
            _product = product;
            _variant = variant;
            _templates = finalized;
            if (hasDefaultTemplate) {
              _selectedTemplateId = variant.defaultTemplateId;
            } else if (finalized.isNotEmpty) {
              _selectedTemplateId = finalized.first.id;
            }
            _isLoading = false;
          });
      }
    } on Object catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: ErrorView(
          message: _errorMessage!,
          onBack: () => Navigator.of(context).pop(),
        ),
      );
    }

    final product = _product;
    final variant = _variant;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Select Template'),
      ),
      body: Column(
        children: [
          Expanded(
            child: AdaptiveScrollWrapper(
              builder: (context, controller) {
                return CustomScrollView(
                  controller: controller,
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.all(24),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          Text(
                            '${product.name} - ${variant.name}',
                            style: textTheme.displayLarge?.copyWith(
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Select the printing template layout for this product variant. Your choice will be applied to the current print queue.',
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Bento Grid of Templates
                          if (_templates.isEmpty) ...[
                            Card(
                              color: colorScheme.surfaceContainerLow,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
                                child: Column(
                                  children: [
                                    Icon(Icons.layers_clear_outlined, size: 64, color: colorScheme.outline),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No finalized templates found',
                                      style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'You must create and finalize at least one template in the Template Designer first.',
                                      style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 24),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        const TemplateManagementRoute().go(context);
                                      },
                                      icon: const Icon(Icons.design_services),
                                      label: const Text('Go to Template Designer'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ] else ...[
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 260,
                                mainAxisExtent: 280,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                              itemCount: _templates.length,
                              itemBuilder: (context, i) {
                                final t = _templates[i];
                                final isSelected = _selectedTemplateId == t.id;

                                return TemplateGridCard(
                                  template: t,
                                  isSelected: isSelected,
                                  onTap: () {
                                    setState(() {
                                      _selectedTemplateId = t.id;
                                    });
                                  },
                                  onDoubleTap: () {
                                    setState(() {
                                      _selectedTemplateId = t.id;
                                    });
                                    PrintSetupRoute(
                                      productId: product.id,
                                      variantSku: variant.sku,
                                      templateId: t.id,
                                    ).pushReplacement(context);
                                  },
                                );
                              },
                            ),
                          ],
                        ]),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          // Sticky Bottom Continue Bar
          if (_selectedTemplateId != null)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    ),
                    onPressed: () {
                      PrintSetupRoute(
                        productId: product.id,
                        variantSku: variant.sku,
                        templateId: _selectedTemplateId!,
                      ).pushReplacement(context);
                    },
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Continue to Print Configuration'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
