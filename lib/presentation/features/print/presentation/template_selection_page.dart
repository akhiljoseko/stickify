import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stickify/app/routing/router.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/widgets/adaptive_scroll_wrapper.dart';

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

      final product = await productRepo.getProductById(widget.productId);
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

      final templates = await templateRepo.fetchTemplates();
      final finalized = templates.where((t) => t.isFinalized).toList();

      setState(() {
        _product = product;
        _variant = variant;
        _templates = finalized;
        if (finalized.isNotEmpty) {
          _selectedTemplateId = finalized.first.id;
        }
        _isLoading = false;
      });
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
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: colorScheme.error),
              const SizedBox(height: 16),
              Text(_errorMessage!, style: textTheme.titleMedium),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    final product = _product;
    final variant = _variant;

    return Scaffold(
      backgroundColor: colorScheme.surface,
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
                          // Breadcrumbs & Header
                          Row(
                            children: [
                              Text(
                                'Products',
                                style: textTheme.bodySmall?.copyWith(
                                  fontFamily: 'JetBrains Mono',
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              Icon(Icons.chevron_right, size: 14, color: colorScheme.onSurfaceVariant),
                              Text(
                                'Inventory',
                                style: textTheme.bodySmall?.copyWith(
                                  fontFamily: 'JetBrains Mono',
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              Icon(Icons.chevron_right, size: 14, color: colorScheme.onSurfaceVariant),
                              Text(
                                'Template Selection',
                                style: textTheme.bodySmall?.copyWith(
                                  fontFamily: 'JetBrains Mono',
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
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
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final isCompact = constraints.maxWidth < 600;
                                final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 1000;
                                final crossAxisCount = isCompact ? 1 : (isTablet ? 2 : 3);

                                return GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                    childAspectRatio: 0.95,
                                  ),
                                  itemCount: _templates.length,
                                  itemBuilder: (context, i) {
                                    final t = _templates[i];
                                    final isSelected = _selectedTemplateId == t.id;
                                    final sticker = t.stickerConfig;
                                    final dimensions = sticker != null
                                        ? '${sticker.widthMm.toStringAsFixed(1)} x ${sticker.heightMm.toStringAsFixed(1)} mm'
                                        : 'N/A';

                                    return Card(
                                      clipBehavior: Clip.antiAlias,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: BorderSide(
                                          color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
                                          width: isSelected ? 2 : 1,
                                        ),
                                      ),
                                      child: InkWell(
                                        onTap: () {
                                          setState(() {
                                            _selectedTemplateId = t.id;
                                          });
                                        },
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: [
                                            // Mock Label Preview Box
                                            Expanded(
                                              child: Container(
                                                color: colorScheme.surfaceContainerLow,
                                                padding: const EdgeInsets.all(24),
                                                child: Center(
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      border: Border.all(color: colorScheme.outlineVariant),
                                                      boxShadow: const [
                                                        BoxShadow(
                                                          color: Colors.black12,
                                                          blurRadius: 4,
                                                          offset: Offset(0, 2),
                                                        )
                                                      ],
                                                    ),
                                                    child: AspectRatio(
                                                      aspectRatio: sticker != null
                                                          ? (sticker.widthMm / sticker.heightMm)
                                                          : 1.5,
                                                      child: Padding(
                                                        padding: const EdgeInsets.all(8),
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Container(width: double.infinity, height: 4, color: Colors.grey.shade300),
                                                            const SizedBox(height: 4),
                                                            Container(width: 30, height: 4, color: Colors.grey.shade300),
                                                            const Spacer(),
                                                            Row(
                                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                              children: [
                                                                Container(width: 20, height: 20, color: Colors.grey.shade300),
                                                                Container(width: 30, height: 8, color: Colors.grey.shade300),
                                                              ],
                                                            )
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            // Template details
                                            Padding(
                                              padding: const EdgeInsets.all(16),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    t.name,
                                                    style: textTheme.titleSmall?.copyWith(
                                                      color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Text(
                                                        dimensions,
                                                        style: textTheme.bodySmall?.copyWith(
                                                          fontFamily: 'JetBrains Mono',
                                                          color: colorScheme.onSurfaceVariant,
                                                        ),
                                                      ),
                                                      if (isSelected)
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                          decoration: BoxDecoration(
                                                            color: colorScheme.primaryContainer,
                                                            borderRadius: BorderRadius.circular(4),
                                                          ),
                                                          child: Text(
                                                            'SELECTED',
                                                            style: textTheme.labelSmall?.copyWith(
                                                              color: colorScheme.primary,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
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
                      ).go(context);
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
